--============================================================
-- MDB_StatRegistry.lua
-- Unified access point for all stat operations (v42.14).
--
-- Instead of calling individual get/calc/getColor functions
-- with a 17-way if-elseif dispatch, all code goes through
-- this single registry:
--
--   local value = MDB_StatRegistry.getValue("hp", player)
--   local color = MDB_StatRegistry.getColor("hp", player, playerNum)
--   local text  = MDB_StatRegistry.getTooltipText("hp", player)
--
-- Dependencies:
--   MDB_StatDefs   - Declarative stat definitions
--   MDB_Config     - Configuration cache
--   MDB_Thresholds - Moodlet severity threshold tables
--============================================================

require "MDB/MDB_StatDefs"
require "MDB/MDB_Config"
require "MDB/MDB_Thresholds"

MDB_StatRegistry = {}

-- ---------------------------------------------------------------------------
-- Cached list of stat IDs excluding "menu" (built once in init)
-- ---------------------------------------------------------------------------
local cachedStatIds = nil
local cachedAllIds  = nil

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

--- Initialize the registry.
-- Delegates to MDB_StatDefs.init() to populate the declarative registry,
-- then pre-builds the filtered ID lists.
function MDB_StatRegistry.init()
    MDB_StatDefs.init()

    -- Pre-build the stat ID lists so getStatIds/getAllIds do not
    -- allocate a new table on every call.
    cachedAllIds  = {}
    cachedStatIds = {}

    for _, id in ipairs(MDB_StatDefs.orderedIds) do
        table.insert(cachedAllIds, id)
        if id ~= "menu" then
            table.insert(cachedStatIds, id)
        end
    end

    print("[MDB_StatRegistry] Initialized with " .. #cachedStatIds .. " stats (+" .. (#cachedAllIds - #cachedStatIds) .. " special).")
end

-- ---------------------------------------------------------------------------
-- Core value access
-- ---------------------------------------------------------------------------

--- Get the normalized value (0-1) for a stat.
-- Returns -1 if the player is dead (the stat def handles this internally).
-- Returns 0 if the stat definition is not found.
--
-- @param statId  string   Stat identifier (e.g. "hp", "hunger")
-- @param player  IsoPlayer
-- @return number  Normalized value in [0, 1], or -1 if dead
function MDB_StatRegistry.getValue(statId, player)
    local def = MDB_StatDefs.byId[statId]
    if not def or not def.getValue then
        return 0
    end
    return def.getValue(player)
end

--- Get the raw API value for a stat (used by tooltip display).
-- For most stats this returns a single number. For "stress" it returns
-- two values (base stress, nicotine stress).
--
-- @param statId  string
-- @param player  IsoPlayer
-- @return number (or multiple for stress)
function MDB_StatRegistry.getRawValue(statId, player)
    local def = MDB_StatDefs.byId[statId]
    if not def or not def.getRawValue then
        return 0
    end
    return def.getRawValue(player)
end

-- ---------------------------------------------------------------------------
-- Color access
-- ---------------------------------------------------------------------------

--- Get the color for a stat bar.
--
-- If the stat has useDynamicColor=true, calls the stat's getColor function
-- passing the player and the config color as fallback. The dynamic color
-- functions in MDB_StatDefs return short-key tables {r, g, b, a}; this
-- method normalizes them to the old format {red, green, blue, alpha} for
-- consistency with the rest of the codebase.
--
-- If the stat does NOT use dynamic color, returns the color straight from
-- the player's config (which already uses {red, green, blue, alpha}).
--
-- @param statId    string     Stat identifier
-- @param player    IsoPlayer
-- @param playerNum number     1-based player number (for config lookup)
-- @return table  {red=N, green=N, blue=N, alpha=N}
function MDB_StatRegistry.getColor(statId, player, playerNum)
    local def = MDB_StatDefs.byId[statId]

    -- Fetch the user's configured color for this indicator
    local indicatorConfig = MDB_Config.getIndicatorConfig(playerNum, statId)
    local configColor = indicatorConfig.color

    -- Fallback if config has no color entry
    if not configColor then
        configColor = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.75 }
    end

    -- Non-dynamic or missing def: return config color as-is
    if not def or not def.useDynamicColor or not def.getColor then
        return configColor
    end

    -- Dynamic color: call the stat's getColor function
    local dynamicColor = def.getColor(player, configColor)

    if not dynamicColor then
        return configColor
    end

    -- Normalize short-key format {r, g, b, a} to old format {red, green, blue, alpha}
    -- If the returned table already has the old keys, pass through unchanged.
    if dynamicColor.red ~= nil then
        -- Already in old format
        return dynamicColor
    end

    return {
        red   = dynamicColor.r or 1.0,
        green = dynamicColor.g or 1.0,
        blue  = dynamicColor.b or 1.0,
        alpha = dynamicColor.a or 0.75,
    }
end

-- ---------------------------------------------------------------------------
-- Tooltip
-- ---------------------------------------------------------------------------

--- Get formatted tooltip text for a stat.
-- Calls the stat def's getRawValue then formatTooltip. Returns nil if the
-- stat has no tooltip formatting (e.g. "menu").
--
-- @param statId  string
-- @param player  IsoPlayer
-- @return string|nil
function MDB_StatRegistry.getTooltipText(statId, player)
    local def = MDB_StatDefs.byId[statId]
    if not def then
        return nil
    end

    if not def.getRawValue or not def.formatTooltip then
        return nil
    end

    local raw = def.getRawValue(player)
    if raw == nil then
        return nil
    end

    return def.formatTooltip(raw, player)
end

-- ---------------------------------------------------------------------------
-- Threshold access
-- ---------------------------------------------------------------------------

--- Get the moodlet threshold table for a stat.
-- Delegates to MDB_Thresholds.get().
--
-- @param statId  string
-- @return table|nil  Array of normalized threshold values, or nil
function MDB_StatRegistry.getThresholds(statId)
    return MDB_Thresholds.get(statId)
end

-- ---------------------------------------------------------------------------
-- Stat metadata
-- ---------------------------------------------------------------------------

--- Check if a stat is "high is better" (e.g. hp, hunger where a full bar
-- means good health). Returns nil for stats with no clear polarity
-- (e.g. temperature).
--
-- @param statId  string
-- @return boolean|nil
function MDB_StatRegistry.isHighIsBetter(statId)
    local def = MDB_StatDefs.byId[statId]
    if not def then
        return nil
    end
    return def.highIsBetter
end

-- ---------------------------------------------------------------------------
-- ID lists
-- ---------------------------------------------------------------------------

--- Get the ordered list of stat IDs, excluding "menu".
-- This is the list used for iterating over actual stat bars.
--
-- @return table  Array of string IDs in display order
function MDB_StatRegistry.getStatIds()
    if not cachedStatIds then
        -- Fallback if init() has not been called yet
        return {}
    end
    return cachedStatIds
end

--- Get all IDs including "menu", in display order.
--
-- @return table  Array of string IDs
function MDB_StatRegistry.getAllIds()
    if not cachedAllIds then
        return {}
    end
    return cachedAllIds
end

-- ---------------------------------------------------------------------------
-- Definition access
-- ---------------------------------------------------------------------------

--- Get the full stat definition entry from MDB_StatDefs.
--
-- @param statId  string
-- @return table|nil  The registry entry, or nil if not found
function MDB_StatRegistry.getDef(statId)
    return MDB_StatDefs.byId[statId]
end

return MDB_StatRegistry
