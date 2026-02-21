--============================================================
-- MDB_Presets.lua
-- Preset loading, importing, exporting, and legacy conversion
-- for MinimalDisplayBars (v42.14).
--
-- Built-in presets are shipped as Lua files in the mod's
-- presets/ directory (legacy format from v42.13).
-- Users can also export their current config as a preset
-- file (MDB_Preset.lua) and re-import it later.
--
-- Dependencies:
--   MDB_Config        - Configuration cache and persistence
--   MDB_StatDefs      - Stat definitions (for default config)
--   MDB_ModalRichText - Modal dialog UI component
--============================================================

require "MDB/MDB_Config"

MDB_Presets = {}

-- ---------------------------------------------------------------------------
-- Built-in presets
--
-- Each entry maps an internal name to a display name and the require path
-- used to load the preset Lua file.  The preset files live under the mod's
-- media/lua/client/ directory, so PZ's require() can resolve them.
-- ---------------------------------------------------------------------------

MDB_Presets.builtIn = {
    ["MrX"]   = { displayName = "Horizon",      requirePath = "presets/mdb_preset_mrx" },
    ["Ann"]   = { displayName = "Minimal",       requirePath = "presets/mdb_preset_ann" },
    ["Kughi"] = { displayName = "Concentrated",  requirePath = "presets/mdb_preset_kughi" },
    ["Sebo"]  = { displayName = "Bottom",        requirePath = "presets/mdb_preset_sebo" },
}

--- Deterministic iteration order for the preset list.
--- This controls the order presets appear in the context menu.
MDB_Presets.builtInOrder = { "MrX", "Ann", "Kughi", "Sebo" }

-- ---------------------------------------------------------------------------
-- Internal: deep copy utility
-- ---------------------------------------------------------------------------

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
-- Internal: merge defaults into target (fills missing keys only)
-- ---------------------------------------------------------------------------

--- Recursively merge missing keys from defaults into target.
--- Existing values in target are preserved; only missing keys are filled in.
--- @param target   table
--- @param defaults table
--- @return table  target (modified in place, also returned for convenience)
local function mergeDefaults(target, defaults)
    for k, defaultVal in pairs(defaults) do
        if target[k] == nil then
            target[k] = deepCopy(defaultVal)
        elseif type(target[k]) == "table" and type(defaultVal) == "table" then
            mergeDefaults(target[k], defaultVal)
        end
    end
    return target
end

-- ---------------------------------------------------------------------------
-- Legacy keys that belong in globalSettings rather than indicators.
--
-- The old v42.13 format stored these as top-level keys alongside the
-- per-stat entries.  During conversion they are moved into globalSettings.
-- ---------------------------------------------------------------------------

local GLOBAL_KEYS = {
    moveBarsTogether         = true,
    movableAll               = true,
    alwaysBringToTop         = true,
    showMoodletThresholdLines = true,
    showIconAll              = true,
}

-- ---------------------------------------------------------------------------
-- Load a built-in preset by internal name
-- ---------------------------------------------------------------------------

--- Load a built-in preset and return its raw data table.
--- The raw table is in the legacy format (flat keys per stat).
---
--- @param presetName string  Internal name (e.g. "MrX", "Ann")
--- @return table|nil  The preset data table, or nil on failure
function MDB_Presets.loadBuiltIn(presetName)
    local entry = MDB_Presets.builtIn[presetName]
    if not entry then
        print("[MDB_Presets] WARNING: Unknown built-in preset: " .. tostring(presetName))
        return nil
    end

    local ok, data = pcall(require, entry.requirePath)
    if not ok or type(data) ~= "table" then
        print("[MDB_Presets] ERROR: Failed to load built-in preset '" .. presetName .. "': " .. tostring(data))
        return nil
    end

    -- Return a deep copy so that the cached require() result is never mutated
    return deepCopy(data)
end

-- ---------------------------------------------------------------------------
-- Load user preset from file (MDB_Preset.lua in the PZ user directory)
-- ---------------------------------------------------------------------------

--- Load a user-exported preset file (MDB_Preset.lua) from the PZ user
--- directory.  Uses getFileReader to read the file, then loadstring to
--- evaluate it.
---
--- @return table|nil  The preset data table, or nil on failure
function MDB_Presets.loadUserPreset()
    local filePath = "MDB_Preset.lua"
    local reader = getFileReader(filePath, true)
    if not reader then
        print("[MDB_Presets] User preset file not found: " .. filePath)
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
        print("[MDB_Presets] User preset file is empty: " .. filePath)
        return nil
    end

    local func = loadstring(contents)
    if not func then
        print("[MDB_Presets] ERROR: loadstring failed for user preset. File may be corrupt.")
        return nil
    end

    local success, result = pcall(func)
    if not success then
        print("[MDB_Presets] ERROR: pcall failed loading user preset: " .. tostring(result))
        return nil
    end

    if type(result) ~= "table" then
        print("[MDB_Presets] WARNING: user preset is not a table. Ignoring.")
        return nil
    end

    return result
end

-- ---------------------------------------------------------------------------
-- Export current config as a user preset
-- ---------------------------------------------------------------------------

--- Export the current player config to MDB_Preset.lua in the PZ user
--- directory.  The exported file is a self-contained Lua script that
--- returns the config table when loaded via loadstring or require.
---
--- @param playerNum number  1-based player number
function MDB_Presets.exportUserPreset(playerNum)
    local config = MDB_Config.getRawCache(playerNum)
    if not config then
        print("[MDB_Presets] ERROR: No config cache for player " .. tostring(playerNum) .. ". Cannot export.")
        if getPlayer() then
            getPlayer():Say("Export failed: no config available!")
        end
        return
    end

    local serialized = "-- MDB User Preset (exported)\n"
    serialized = serialized .. "return " .. MDB_Config.serializeTable(config, nil, 0) .. "\n"

    local writer = getFileWriter("MDB_Preset.lua", true, false)
    if not writer then
        print("[MDB_Presets] ERROR: could not open MDB_Preset.lua for writing.")
        if getPlayer() then
            getPlayer():Say("Export failed: cannot write file!")
        end
        return
    end

    writer:write(serialized)
    writer:close()

    print("[MDB_Presets] Preset exported successfully to MDB_Preset.lua")
    if getPlayer() then
        getPlayer():Say("Preset exported successfully!")
    end
end

-- ---------------------------------------------------------------------------
-- Legacy format detection and conversion
-- ---------------------------------------------------------------------------

--- Detect whether a table is in the legacy v42.13 format.
--- Legacy format has flat stat keys (e.g. "hp", "hunger") at the top level
--- rather than a nested "indicators" sub-table.
---
--- @param data table
--- @return boolean
function MDB_Presets.isLegacyFormat(data)
    -- New format always has an "indicators" key
    if data.indicators ~= nil then
        return false
    end
    -- Legacy format has stat IDs directly at the top level
    -- Check for a few known stat keys
    if data.hp or data.hunger or data.menu then
        return true
    end
    return false
end

--- Convert a legacy v42.13 preset table to the new v42.14 format.
---
--- Legacy format (flat):
---   { moveBarsTogether = true, hp = {...}, hunger = {...}, ... }
---
--- New format (structured):
---   {
---     globalSettings = { moveBarsTogether = true, ... },
---     indicators = { hp = {...}, hunger = {...}, ... }
---   }
---
--- @param oldPreset table  The legacy format table
--- @return table  New format table with globalSettings and indicators
function MDB_Presets.convertLegacyPreset(oldPreset)
    local newConfig = {
        globalSettings = {},
        indicators = {},
    }

    for key, value in pairs(oldPreset) do
        if GLOBAL_KEYS[key] then
            -- This is a global setting, move it to globalSettings
            newConfig.globalSettings[key] = deepCopy(value)
        elseif type(value) == "table" then
            -- This is a per-indicator config table
            newConfig.indicators[key] = deepCopy(value)
        else
            -- Unknown scalar at top level -- treat as global setting
            -- (future-proofing for any new top-level booleans/numbers)
            newConfig.globalSettings[key] = deepCopy(value)
        end
    end

    return newConfig
end

-- ---------------------------------------------------------------------------
-- Apply a preset to the current player
-- ---------------------------------------------------------------------------

--- Apply a preset's configuration to a player.
---
--- Steps:
---   1. Detect legacy format and convert if needed
---   2. Merge with current defaults (so new keys from updates are present)
---   3. Replace the player's current config via MDB_Config.setFullConfig
---   4. Force-save to disk immediately
---
--- The caller (typically MDB_ContextMenu or onConfirmLoad) is responsible
--- for refreshing the UI bars after this call.
---
--- @param playerNum  number  1-based player number
--- @param presetData table   Preset data (legacy or new format)
function MDB_Presets.applyPreset(playerNum, presetData)
    if not presetData then
        print("[MDB_Presets] ERROR: applyPreset called with nil presetData.")
        return
    end

    -- Step 1: Convert legacy format if necessary
    local config
    if MDB_Presets.isLegacyFormat(presetData) then
        config = MDB_Presets.convertLegacyPreset(presetData)
    else
        config = deepCopy(presetData)
    end

    -- Step 2: Merge with defaults to ensure all keys exist
    -- (covers new stats or config keys added in updates)
    local defaults = MDB_Config.createDefaultConfig(playerNum)
    mergeDefaults(config, defaults)

    -- Also ensure globalSettings is fully populated
    if config.globalSettings then
        mergeDefaults(config.globalSettings, defaults.globalSettings or {})
    end

    -- Also ensure each indicator has all default keys
    if config.indicators and defaults.indicators then
        for statId, defaultIndicator in pairs(defaults.indicators) do
            if config.indicators[statId] then
                mergeDefaults(config.indicators[statId], defaultIndicator)
            else
                -- Preset does not include this stat (possibly added after
                -- the preset was created). Use defaults.
                config.indicators[statId] = deepCopy(defaultIndicator)
            end
        end
    end

    -- Step 3: Replace the full config
    MDB_Config.setFullConfig(playerNum, config)

    -- Step 4: Force save to disk
    MDB_Config.forceSave(playerNum)

    print("[MDB_Presets] Preset applied for player " .. tostring(playerNum))
end

-- ---------------------------------------------------------------------------
-- Modal dialog callbacks
-- ---------------------------------------------------------------------------

--- Callback invoked when the user clicks YES/NO on a preset confirmation
--- dialog.
---
--- param1 = indicator (bar reference, used to get playerIndex / coopNum)
--- param2 = built-in preset name, or nil for user preset
---
--- @param target   any       The modal's target (unused here)
--- @param button   table     The clicked button (button.internal = "YES"/"NO")
--- @param param1   table     The indicator / bar reference
--- @param param2   string|nil  Built-in preset name, or nil for user preset
function MDB_Presets.onConfirmLoad(target, button, param1, param2)
    if button.internal ~= "YES" then
        return
    end

    local indicator = param1
    if not indicator then
        print("[MDB_Presets] ERROR: onConfirmLoad called without indicator reference.")
        return
    end

    -- Determine playerNum from the indicator
    -- In v42.14 bars, the indicator should expose playerNum or coopNum.
    -- Support both naming conventions for robustness.
    local playerNum = indicator.playerNum or indicator.coopNum or 0

    local presetData

    if not param2 then
        -- Load user preset (MDB_Preset.lua)
        if getPlayer() then
            getPlayer():Say("Loading MDB_Preset.lua")
        end

        presetData = MDB_Presets.loadUserPreset()
        if not presetData then
            if getPlayer() then
                getPlayer():Say("Can't find MDB_Preset.lua!")
            end
            return
        end
    else
        -- Load built-in preset
        if getPlayer() then
            getPlayer():Say("Loading " .. tostring(param2) .. " Preset")
        end

        presetData = MDB_Presets.loadBuiltIn(param2)
        if not presetData then
            if getPlayer() then
                getPlayer():Say("Can't find " .. tostring(param2) .. " preset!")
            end
            return
        end
    end

    -- Apply the preset
    MDB_Presets.applyPreset(playerNum, presetData)

    if getPlayer() then
        getPlayer():Say("Preset loaded successfully!")
    end
end

-- ---------------------------------------------------------------------------
-- Modal dialog display
-- ---------------------------------------------------------------------------

--- Show the "Load User Preset" modal dialog.
--- Displays instructions on how to load a custom user preset file
--- (MDB_Preset.lua from the PZ user directory).
---
--- @param indicator table  The indicator / bar reference (passed to callback)
function MDB_Presets.showLoadModal(indicator)
    local texture = getTexture("media/ui/mdbPresetFolder.png")
    local windowSize = 600 + (getCore():getOptionFontSizeReal() * 100)
    if texture then
        windowSize = texture:getWidth()
        windowSize = windowSize + (getCore():getOptionFontSizeReal() * 100)
    end

    -- Determine player index for the modal (needed for joypad support)
    local playerIndex = indicator.playerIndex or indicator.playerNum or 0

    local modal = MDB_ModalRichText:new(
        (getCore():getScreenWidth() - windowSize) / 2,
        getCore():getScreenHeight() / 2 - 300,
        windowSize,
        200,
        "",         -- text (set below via chatText)
        true,       -- yesno buttons
        nil,        -- target
        MDB_Presets.onConfirmLoad,
        playerIndex,
        indicator,  -- param1: the indicator reference
        nil         -- param2: nil = user preset
    )
    modal:initialise()
    modal.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    modal.alwaysOnTop = true

    modal.chatText.text = getText("UI_LoadPreset_Info")
    modal.chatText:paginate()
    modal:setHeightToContents()
    modal:ignoreHeightChange()
    modal:setY(getCore():getScreenHeight() / 2 - (modal:getHeight() / 2))
    modal:setVisible(true)
    modal:addToUIManager()
end

--- Show the "Import Built-in Preset" confirmation modal.
--- Displays a preview / confirmation for a specific built-in preset.
---
--- @param indicator  table   The indicator / bar reference (passed to callback)
--- @param presetName string  Internal preset name (e.g. "MrX", "Ann")
function MDB_Presets.showImportModal(indicator, presetName)
    local texture = getTexture("media/ui/mdbImport" .. presetName .. ".png")
    local windowSize = 600 + (getCore():getOptionFontSizeReal() * 100)
    if texture then
        windowSize = texture:getWidth()
        windowSize = windowSize + (getCore():getOptionFontSizeReal() * 100)
    end

    -- Determine player index for the modal
    local playerIndex = indicator.playerIndex or indicator.playerNum or 0

    local modal = MDB_ModalRichText:new(
        (getCore():getScreenWidth() - windowSize) / 2,
        getCore():getScreenHeight() / 2 - 300,
        windowSize,
        200,
        "",          -- text (set below via chatText)
        true,        -- yesno buttons
        nil,         -- target
        MDB_Presets.onConfirmLoad,
        playerIndex,
        indicator,   -- param1: the indicator reference
        presetName   -- param2: built-in preset name
    )
    modal:initialise()
    modal.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    modal.alwaysOnTop = true

    modal.chatText.text = getText("UI_ImportPreset_Info", presetName)
    modal.chatText:paginate()
    modal:setHeightToContents()
    modal:ignoreHeightChange()
    modal:setY(getCore():getScreenHeight() / 2 - (modal:getHeight() / 2))
    modal:setVisible(true)
    modal:addToUIManager()
end

return MDB_Presets
