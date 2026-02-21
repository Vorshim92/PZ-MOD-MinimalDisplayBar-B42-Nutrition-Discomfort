--
--============================================================
-- MDB_Main.lua
-- Entry point and event handler for MinimalDisplayBars (v42.14).
--
-- This file:
--   1. Requires all MDB modules in dependency order
--   2. Initialises the MDB global table and constants
--   3. Defines the indicator factory (createIndicatorsFor)
--   4. Handles PZ lifecycle events (boot, disconnect, death, tick)
--   5. Registers all events with the PZ engine
--
-- Replaces the monolithic minimaldisplaybars(a).lua from v42.13.
-- The old createUiFor() had 17 near-identical copy-pasted blocks;
-- the new version is a single data-driven loop over MDB_StatDefs.
--
-- Dependencies:
--   All MDB_* modules (loaded via require below)
--============================================================

-- ============================================================
-- Module requires (order matters: leaf dependencies first)
-- ============================================================

require "MDB/MDB_Config"
require "MDB/MDB_ColorUtils"
require "MDB/MDB_NanFix"
require "MDB/MDB_Thresholds"
require "MDB/MDB_StatDefs"
require "MDB/MDB_StatRegistry"
require "MDB/MDB_Presets"
require "MDB/MDB_MoveBarsTogether"
require "MDB/MDB_ContextMenu"
require "MDB/UI/MDB_IndicatorBase"
require "MDB/UI/MDB_BarIndicator"
require "MDB/UI/MDB_CircularIndicator"
require "MDB/UI/MDB_ColorPicker"
require "MDB/UI/MDB_PropertiesPanel"
require "MDB/UI/MDB_TextEntryBox"
require "MDB/UI/MDB_ModalRichText"
require "MDB/UI/MDB_ReleaseNotes"
require "MDB/NeatTool/NeatTool_3Patch"
require "MDB/NeatTool/NeatTool_DrawPercentage"

-- ============================================================
-- Global namespace
-- ============================================================

MDB = MDB or {}
MDB.MOD_ID      = "MinimalDisplayBarsNutritions"
MDB.MOD_VERSION = "42.14"

-- ---------------------------------------------------------------------------
-- Storage for indicator instances and active player tracking
-- ---------------------------------------------------------------------------

--- Per-player indicator map.
-- indicators[playerIndex][statId] = MDB_BarIndicator or MDB_CircularIndicator
MDB.indicators = {}

--- Set of active player indices.
-- playerIndices[playerIndex] = true when a player has been initialised.
MDB.playerIndices = {}

--- Global reference to the currently-open properties panel instance.
-- Used by the context menu and other UI code to prevent duplicate panels.
MDB.displayBarPropertiesPanel = nil

-- ============================================================
-- Factory: create all indicator instances for a local player
-- ============================================================

--- Create indicator UI elements for every stat defined in MDB_StatDefs.
-- Called by PZ's OnCreatePlayer event. Replaces the old createUiFor()
-- which had 17 manually-duplicated bar instantiation blocks.
--
-- @param playerIndex  number     0-based player index from PZ engine
-- @param isoPlayer    IsoPlayer  The player Java object
function MDB.createIndicatorsFor(playerIndex, isoPlayer)

    -- Only create UI for local players (critical in multiplayer)
    if not isoPlayer:isLocalPlayer() then return end

    -- Initialize the stat registry once (populates MDB_StatDefs lookup
    -- tables and wires up MDB_Config.defaultConfigGenerator)
    MDB_StatRegistry.init()

    -- Split-screen offsets: each local player's screen region has its
    -- own origin. All bar positions are relative to this origin.
    local xOffset = getPlayerScreenLeft(playerIndex)
    local yOffset = getPlayerScreenTop(playerIndex)

    -- coopNum is always 1-based (playerIndex 0 -> player 1, etc.)
    local coopNum = playerIndex + 1

    -- Ensure config is loaded into the cache for this player.
    -- If no saved config exists on disk, this creates defaults from
    -- MDB_StatDefs and marks dirty so they get persisted on next flush.
    MDB_Config.getRawCache(coopNum)

    -- Initialise indicator storage for this player
    MDB.indicators[playerIndex] = MDB.indicators[playerIndex] or {}
    MDB.playerIndices[playerIndex] = true

    -- -----------------------------------------------------------------
    -- Create one indicator per stat in the order defined by MDB_StatDefs
    -- -----------------------------------------------------------------
    for _, statId in ipairs(MDB_StatDefs.orderedIds) do
        local config = MDB_Config.getIndicatorConfig(coopNum, statId)
        local style  = config.style or "bar"

        local indicator
        if style == "circular" then
            indicator = MDB_CircularIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
        else
            indicator = MDB_BarIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
        end

        indicator:initialise()
        indicator:addToUIManager()

        MDB.indicators[playerIndex][statId] = indicator
    end

    -- -----------------------------------------------------------------
    -- Synchronise global toggle states across all indicators
    -- -----------------------------------------------------------------
    local globalConfig = MDB_Config.getGlobalConfig(coopNum)

    for statId, indicator in pairs(MDB.indicators[playerIndex]) do
        if globalConfig.alwaysBringToTop ~= nil then
            indicator.alwaysBringToTop = globalConfig.alwaysBringToTop
        end
    end

    -- Set the class-level flag used by handleBringToTop() in render
    MDB_IndicatorBase.globalAlwaysBringToTop = globalConfig.alwaysBringToTop ~= false

    -- -----------------------------------------------------------------
    -- Handle "Move Bars Together" grouping panel
    -- -----------------------------------------------------------------
    if globalConfig.moveBarsTogether then
        MDB_MoveBarsTogether.recreatePanel(coopNum, MDB.indicators[playerIndex])
    end

    print("[MDB] Created indicators for player " .. tostring(playerIndex))
end

-- ============================================================
-- Event handlers
-- ============================================================

--- OnGameBoot: Reset all state when PZ boots a new game session.
-- Mirrors the old OnBootGame handler (v42.13 line 2933).
function MDB.onBootGame()
    MDB.indicators    = {}
    MDB.playerIndices = {}
    MDB.displayBarPropertiesPanel = nil
end

--- OnDisconnect: Save configs, remove all indicators, and clean up.
-- Fires when disconnected from a server or when the game session ends
-- (all local players exit). Mirrors v42.13 OnLocalPlayerDisconnect
-- (lines 2940-2969).
function MDB.onDisconnect()
    -- Close the properties panel if open
    if MDB.displayBarPropertiesPanel then
        MDB.displayBarPropertiesPanel:close()
        MDB.displayBarPropertiesPanel = nil
    end

    for playerIndex, _ in pairs(MDB.playerIndices) do
        local coopNum = playerIndex + 1

        -- Force save any pending config changes to disk
        MDB_Config.forceSave(coopNum)

        -- Remove all indicator panels from the UI manager
        if MDB.indicators[playerIndex] then
            for statId, indicator in pairs(MDB.indicators[playerIndex]) do
                indicator:removeFromUIManager()
                indicator:setVisible(false)
            end
        end

        -- Destroy the move-together grouping panel (detaches children)
        MDB_MoveBarsTogether.detachAndDestroy(coopNum, MDB.indicators[playerIndex])

        -- Release config cache for this player
        MDB_Config.cleanup(coopNum)
    end

    -- Reset all state
    MDB.indicators    = {}
    MDB.playerIndices = {}
    MDB.displayBarPropertiesPanel = nil
end

--- OnPlayerDeath: Save config and hide indicators for the dead player.
-- Matches a dead isoPlayer to its playerIndex by scanning the indicator
-- map, then hides that player's bars. Config is NOT cleared so it can
-- be reused on respawn. Mirrors v42.13 OnLocalPlayerDeath (lines 2973-3003).
--
-- @param isoPlayer  IsoPlayer  The player who died
function MDB.onPlayerDeath(isoPlayer)
    if not isoPlayer or not isoPlayer:isLocalPlayer() then return end

    -- Find the playerIndex for the dead player by scanning indicators
    for playerIndex, indicators in pairs(MDB.indicators) do
        for statId, indicator in pairs(indicators) do
            if indicator.isoPlayer == isoPlayer then
                local coopNum = playerIndex + 1

                -- Force save any pending config changes
                MDB_Config.forceSave(coopNum)

                -- Hide all indicators for this player (do not remove/destroy:
                -- config tables and indicator instances are preserved so they
                -- can be reused or refreshed on respawn)
                for sid, ind in pairs(indicators) do
                    ind:setVisible(false)
                end

                -- Destroy the move-together panel for this player
                MDB_MoveBarsTogether.detachAndDestroy(coopNum, indicators)

                return  -- Found the matching player; stop scanning
            end
        end
    end
end

--- OnTick: Flush dirty config caches to disk using the deferred save system.
-- MDB_Config.flushIfDirty respects a tick-based throttle (SAVE_INTERVAL)
-- so file I/O only happens roughly once per second, not every frame.
function MDB.onTick()
    for playerIndex, _ in pairs(MDB.playerIndices) do
        local coopNum = playerIndex + 1
        MDB_Config.flushIfDirty(coopNum)
    end
end

-- ============================================================
-- Event registration
-- ============================================================

Events.OnGameBoot.Add(MDB.onBootGame)
Events.OnDisconnect.Add(MDB.onDisconnect)
Events.OnPlayerDeath.Add(MDB.onPlayerDeath)
Events.OnCreatePlayer.Add(MDB.createIndicatorsFor)
Events.OnTick.Add(MDB.onTick)

-- preventContextCoverup is registered on OnRenderTick because it needs
-- to run every render frame to manage the bringToTop suppression when
-- context menus / properties panels / color pickers are open.
if MDB_ContextMenu and MDB_ContextMenu.preventContextCoverup then
    Events.OnRenderTick.Add(MDB_ContextMenu.preventContextCoverup)
end

print("[MDB] MDB_Main.lua loaded (v" .. MDB.MOD_VERSION .. ")")
