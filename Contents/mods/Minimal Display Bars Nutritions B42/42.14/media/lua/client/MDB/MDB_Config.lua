--
-- MDB_Config.lua
-- Configuration system with in-memory cache and deferred file I/O.
--
-- The old code (v42.13) called io_persistence.store() from inside the render
-- loop every time a bar was dragged or a setting was toggled. This file
-- replaces that pattern with a dirty-flag approach: all mutations go to
-- the in-memory cache immediately, and the cache is flushed to disk only
-- when the dirty flag is set AND enough ticks have elapsed.
--
-- File format: one Lua file per player that returns a table.
-- Loading uses PZ getFileReader + loadstring; saving uses getFileWriter.
--

MDB_Config = {}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

--- Per-player config cache. configCache[playerNum] = { globalSettings = {...}, indicators = {...} }
MDB_Config.configCache = {}

--- Dirty flags. dirty[playerNum] = true when the cache has unsaved changes.
MDB_Config.dirty = {}

--- Tick counter per player for throttling saves.
MDB_Config._tickCounters = {}

--- Minimum ticks between save flushes (roughly 1 second at 60 fps).
MDB_Config.SAVE_INTERVAL = 60

--- External hook: set by MDB_StatDefs.init() to provide default indicator configs.
--- Signature: function() -> table  (returns the full default config table)
MDB_Config.defaultConfigGenerator = nil

-- ---------------------------------------------------------------------------
-- Utility: deep copy
-- ---------------------------------------------------------------------------

--- Recursively deep-copies a table. Non-table values are returned as-is.
--- @param orig any
--- @return any
local function deepCopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in pairs(orig) do
        copy[deepCopy(k)] = deepCopy(v)
    end
    return copy
end

-- ---------------------------------------------------------------------------
-- Serialization
-- ---------------------------------------------------------------------------

--- Serialize a Lua value into a string that loadstring() can evaluate.
--- Handles tables (nested), strings, numbers, booleans. Skips nil values.
--- Does NOT handle circular references or multi-ref objects (not needed for
--- flat config tables).
---
--- @param val     any      The value to serialize
--- @param name    string|nil  Optional key name (used internally for recursion)
--- @param depth   number|nil  Current indentation depth (default 0)
--- @return string
function MDB_Config.serializeTable(val, name, depth)
    depth = depth or 0
    local indent = string.rep("    ", depth)
    local childIndent = string.rep("    ", depth + 1)
    local result = ""

    -- Build the key prefix if this is a named entry
    if name then
        if type(name) == "number" then
            result = indent .. "[" .. tostring(name) .. "] = "
        elseif type(name) == "string" then
            -- Use bracket notation for keys that are not simple identifiers
            if string.match(name, "^[%a_][%w_]*$") then
                result = indent .. name .. " = "
            else
                result = indent .. "[" .. string.format("%q", name) .. "] = "
            end
        end
    else
        result = indent
    end

    local valType = type(val)

    if valType == "table" then
        result = result .. "{\n"
        -- Sort keys for deterministic output (easier to diff config files)
        local sortedKeys = {}
        for k, _ in pairs(val) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys, function(a, b)
            -- Sort by type first (numbers before strings), then by value
            local ta, tb = type(a), type(b)
            if ta ~= tb then
                return ta < tb
            end
            if ta == "number" then return a < b end
            return tostring(a) < tostring(b)
        end)
        for _, k in ipairs(sortedKeys) do
            local v = val[k]
            if v ~= nil then
                result = result .. MDB_Config.serializeTable(v, k, depth + 1) .. ",\n"
            end
        end
        result = result .. indent .. "}"
    elseif valType == "string" then
        result = result .. string.format("%q", val)
    elseif valType == "number" then
        result = result .. tostring(val)
    elseif valType == "boolean" then
        if val then
            result = result .. "true"
        else
            result = result .. "false"
        end
    else
        -- Skip unsupported types (functions, userdata, threads)
        result = result .. "nil --[[unsupported type: " .. valType .. "]]"
    end

    return result
end

-- ---------------------------------------------------------------------------
-- File path
-- ---------------------------------------------------------------------------

--- Returns the config file name for a given player number.
--- PZ's getFileWriter/getFileReader resolve this relative to the Zomboid
--- user directory automatically.
---
--- @param playerNum number  1-based player number
--- @return string
function MDB_Config.getConfigFilePath(playerNum)
    return "MDB_Config_P" .. tostring(playerNum) .. ".lua"
end

-- ---------------------------------------------------------------------------
-- File I/O (NEVER called from render -- only from flushIfDirty or init)
-- ---------------------------------------------------------------------------

--- Save the config cache for a player to disk.
--- @param playerNum number  1-based player number
function MDB_Config.saveConfig(playerNum)
    local config = MDB_Config.configCache[playerNum]
    if not config then
        print("[MDB_Config] WARNING: saveConfig called for player " .. tostring(playerNum) .. " but no cache exists.")
        return
    end

    local filePath = MDB_Config.getConfigFilePath(playerNum)
    local serialized = "-- MDB Config for Player " .. tostring(playerNum) .. "\n"
    serialized = serialized .. "return " .. MDB_Config.serializeTable(config, nil, 0) .. "\n"

    local writer = getFileWriter(filePath, true, false)
    if not writer then
        print("[MDB_Config] ERROR: could not open file for writing: " .. filePath)
        return
    end

    writer:write(serialized)
    writer:close()
end

--- Load the config for a player from disk.
--- Returns the loaded table, or nil if the file does not exist or is corrupt.
--- @param playerNum number  1-based player number
--- @return table|nil
function MDB_Config.loadConfig(playerNum)
    local filePath = MDB_Config.getConfigFilePath(playerNum)
    local reader = getFileReader(filePath, true)
    if not reader then
        return nil
    end

    local contents = ""
    local line = reader:readLine()
    while line do
        contents = contents .. line .. "\n"
        line = reader:readLine()
        if not line then break end
    end
    reader:close()

    if contents == "" then
        return nil
    end

    local func = loadstring(contents)
    if not func then
        print("[MDB_Config] ERROR: loadstring failed for " .. filePath .. ". File may be corrupt.")
        return nil
    end

    local ok, result = pcall(func)
    if not ok then
        print("[MDB_Config] ERROR: pcall failed loading " .. filePath .. ": " .. tostring(result))
        return nil
    end

    if type(result) ~= "table" then
        print("[MDB_Config] WARNING: loaded config is not a table for " .. filePath .. ". Ignoring.")
        return nil
    end

    return result
end

-- ---------------------------------------------------------------------------
-- Default config generation
-- ---------------------------------------------------------------------------

--- Returns the default global settings table.
--- @return table
function MDB_Config.getDefaultGlobalConfig()
    return {
        moveBarsTogether = false,
        movableAll = true,
        alwaysBringToTop = false,
        showMoodletThresholdLines = true,
        showIconAll = false,
    }
end

--- Create a full default config for a player.
--- If defaultConfigGenerator has been set by MDB_StatDefs, it delegates to
--- that function. Otherwise it returns a minimal skeleton with just
--- globalSettings (indicators will be empty until StatDefs registers them).
---
--- @param playerNum number  1-based player number (reserved for future per-player defaults)
--- @return table
function MDB_Config.createDefaultConfig(playerNum)
    if MDB_Config.defaultConfigGenerator then
        return MDB_Config.defaultConfigGenerator()
    end

    -- Fallback: minimal config without indicator definitions.
    -- MDB_StatDefs.init() should set defaultConfigGenerator before this
    -- is needed in production, so hitting this path means StatDefs has not
    -- been loaded yet.
    return {
        globalSettings = MDB_Config.getDefaultGlobalConfig(),
        indicators = {},
    }
end

-- ---------------------------------------------------------------------------
-- Cache access: per-indicator
-- ---------------------------------------------------------------------------

--- Ensures the config cache for a player is populated.
--- Loads from disk, or creates defaults if no file exists.
--- @param playerNum number
local function ensureCache(playerNum)
    if MDB_Config.configCache[playerNum] then
        return
    end

    local loaded = MDB_Config.loadConfig(playerNum)
    if loaded then
        -- Merge with defaults so that any new keys added in updates are present
        local defaults = MDB_Config.createDefaultConfig(playerNum)
        MDB_Config.configCache[playerNum] = MDB_Config._mergeDefaults(loaded, defaults)
    else
        MDB_Config.configCache[playerNum] = MDB_Config.createDefaultConfig(playerNum)
        -- Mark dirty so defaults get persisted on next flush
        MDB_Config.dirty[playerNum] = true
    end

    -- Initialise tick counter
    if not MDB_Config._tickCounters[playerNum] then
        MDB_Config._tickCounters[playerNum] = 0
    end
end

--- Recursively merge missing keys from defaults into target.
--- Existing values in target are preserved; only missing keys are filled in.
--- @param target table
--- @param defaults table
--- @return table target (modified in place, also returned for convenience)
function MDB_Config._mergeDefaults(target, defaults)
    for k, defaultVal in pairs(defaults) do
        if target[k] == nil then
            target[k] = deepCopy(defaultVal)
        elseif type(target[k]) == "table" and type(defaultVal) == "table" then
            MDB_Config._mergeDefaults(target[k], defaultVal)
        end
    end
    return target
end

--- Get the config table for a single indicator.
--- Returns a DEEP COPY to prevent external code from mutating the cache
--- without going through updateIndicatorConfig (which sets the dirty flag).
---
--- @param playerNum number  1-based player number
--- @param statId    string  Indicator key, e.g. "hp", "hunger"
--- @return table   A copy of the indicator config, or empty table if missing
function MDB_Config.getIndicatorConfig(playerNum, statId)
    ensureCache(playerNum)
    local config = MDB_Config.configCache[playerNum]
    if config and config.indicators and config.indicators[statId] then
        return deepCopy(config.indicators[statId])
    end
    return {}
end

--- Update a single key in an indicator's config. Sets the dirty flag.
---
--- @param playerNum number
--- @param statId    string
--- @param key       string
--- @param value     any
function MDB_Config.updateIndicatorConfig(playerNum, statId, key, value)
    ensureCache(playerNum)
    local config = MDB_Config.configCache[playerNum]
    if not config.indicators then
        config.indicators = {}
    end
    if not config.indicators[statId] then
        config.indicators[statId] = {}
    end

    -- Deep copy table values to prevent shared references
    if type(value) == "table" then
        config.indicators[statId][key] = deepCopy(value)
    else
        config.indicators[statId][key] = value
    end

    MDB_Config.markDirty(playerNum)
end

-- ---------------------------------------------------------------------------
-- Cache access: global settings
-- ---------------------------------------------------------------------------

--- Get the global settings table (deep copy).
--- @param playerNum number
--- @return table
function MDB_Config.getGlobalConfig(playerNum)
    ensureCache(playerNum)
    local config = MDB_Config.configCache[playerNum]
    if config and config.globalSettings then
        return deepCopy(config.globalSettings)
    end
    return deepCopy(MDB_Config.getDefaultGlobalConfig())
end

--- Update a single key in the global settings. Sets the dirty flag.
--- @param playerNum number
--- @param key       string
--- @param value     any
function MDB_Config.updateGlobalConfig(playerNum, key, value)
    ensureCache(playerNum)
    local config = MDB_Config.configCache[playerNum]
    if not config.globalSettings then
        config.globalSettings = MDB_Config.getDefaultGlobalConfig()
    end

    if type(value) == "table" then
        config.globalSettings[key] = deepCopy(value)
    else
        config.globalSettings[key] = value
    end

    MDB_Config.markDirty(playerNum)
end

-- ---------------------------------------------------------------------------
-- Dirty flag and deferred save
-- ---------------------------------------------------------------------------

--- Mark a player's config as needing to be saved.
--- @param playerNum number
function MDB_Config.markDirty(playerNum)
    MDB_Config.dirty[playerNum] = true
end

--- Called from OnTick. Checks whether a save is needed and enough ticks
--- have elapsed since the last save. This is the ONLY path that triggers
--- file I/O during normal gameplay.
---
--- @param playerNum number
function MDB_Config.flushIfDirty(playerNum)
    if not MDB_Config.dirty[playerNum] then
        return
    end

    -- Throttle saves
    if not MDB_Config._tickCounters[playerNum] then
        MDB_Config._tickCounters[playerNum] = 0
    end
    MDB_Config._tickCounters[playerNum] = MDB_Config._tickCounters[playerNum] + 1

    if MDB_Config._tickCounters[playerNum] < MDB_Config.SAVE_INTERVAL then
        return
    end

    -- Enough time has passed -- flush to disk
    MDB_Config.saveConfig(playerNum)
    MDB_Config.dirty[playerNum] = false
    MDB_Config._tickCounters[playerNum] = 0
end

--- Force an immediate save, bypassing the tick throttle.
--- Use this on player disconnect / death / game exit to avoid data loss.
---
--- @param playerNum number
function MDB_Config.forceSave(playerNum)
    if MDB_Config.configCache[playerNum] then
        MDB_Config.saveConfig(playerNum)
        MDB_Config.dirty[playerNum] = false
        MDB_Config._tickCounters[playerNum] = 0
    end
end

-- ---------------------------------------------------------------------------
-- Cache invalidation
-- ---------------------------------------------------------------------------

--- Clears the in-memory cache for a player, forcing a reload from disk
--- on the next access. Useful after loading a preset.
---
--- @param playerNum number
function MDB_Config.invalidateCache(playerNum)
    MDB_Config.configCache[playerNum] = nil
    MDB_Config.dirty[playerNum] = false
    MDB_Config._tickCounters[playerNum] = 0
end

--- Replace the entire config for a player (e.g. after loading a preset).
--- The new config is stored in the cache and marked dirty for save.
---
--- @param playerNum number
--- @param newConfig table  Full config table with globalSettings + indicators
function MDB_Config.setFullConfig(playerNum, newConfig)
    MDB_Config.configCache[playerNum] = deepCopy(newConfig)
    MDB_Config.markDirty(playerNum)
end

--- Get a direct reference to the raw cache for a player.
--- WARNING: mutations to the returned table will NOT automatically set the
--- dirty flag. Use this only when performance is critical (e.g. reading
--- inside render) and call markDirty() manually after any changes.
---
--- @param playerNum number
--- @return table|nil
function MDB_Config.getRawCache(playerNum)
    ensureCache(playerNum)
    return MDB_Config.configCache[playerNum]
end

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------

--- Remove all cached data for a player. Call on player disconnect / death.
--- Forces a save of any pending changes before clearing.
---
--- @param playerNum number
function MDB_Config.cleanup(playerNum)
    if MDB_Config.dirty[playerNum] and MDB_Config.configCache[playerNum] then
        MDB_Config.saveConfig(playerNum)
    end
    MDB_Config.configCache[playerNum] = nil
    MDB_Config.dirty[playerNum] = nil
    MDB_Config._tickCounters[playerNum] = nil
end

return MDB_Config
