--============================================================
-- MDB_MoveBarsTogether.lua
-- Groups all indicator bars into a single invisible ISPanel
-- so they can be moved as a unit (v42.14).
--
-- When "Move Bars Together" is enabled, this module:
--   1. Calculates the bounding box of all visible indicators
--   2. Creates an ISPanel covering that bounding box
--   3. Reparents every indicator into the panel (coordinates
--      become relative to the panel origin)
--
-- When disabled, the indicators are detached from the panel
-- and returned to UIManager at their absolute positions.
--
-- Ported from the v42.13 createMoveBarsTogetherPanel() function
-- (lines 1731-1783 of minimaldisplaybars(a).lua).
--
-- Dependencies:
--   MDB_Config  - For reading the moveBarsTogether global setting
--   ISPanel     - PZ vanilla UI panel (used as the grouping container)
--============================================================

require "MDB/MDB_Config"
require "ISUI/ISPanel"

MDB_MoveBarsTogether = {}

--- Storage for the grouping panels per player.
-- panels[playerNum] = ISPanel instance (1-based player number)
MDB_MoveBarsTogether.panels = {}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Create or recreate the move-together panel for a player.
--
-- This mirrors the old createMoveBarsTogetherPanel(playerIndex) logic:
--   - If moveBarsTogether is enabled in the player's config, a new ISPanel
--     is created that encompasses all visible indicators. Each indicator is
--     removed from direct UIManager control and reparented as a child of
--     the panel, with its coordinates converted to panel-relative offsets.
--   - If moveBarsTogether is disabled, any existing panel is destroyed and
--     indicators are returned to UIManager at their current absolute positions.
--
-- @param playerNum   number  1-based player number
-- @param indicators  table   Array/map of indicator UI objects (ISUIElement-based).
--                            Each must support :getX(), :getY(), :getWidth(),
--                            :getHeight(), :isVisible(), and the .parent field.
function MDB_MoveBarsTogether.recreatePanel(playerNum, indicators)
    if not indicators then return end

    -- Read the current config to determine whether grouping is enabled
    local globalCfg = MDB_Config.getGlobalConfig(playerNum)
    local enabled = globalCfg and globalCfg.moveBarsTogether == true

    -- ------------------------------------------------------------------
    -- Step 1: Destroy any existing panel so we start clean.
    --         This also detaches children back to absolute positions.
    -- ------------------------------------------------------------------
    MDB_MoveBarsTogether.destroyPanel(playerNum, indicators)

    -- ------------------------------------------------------------------
    -- Step 2: If grouping is disabled, we are done. Indicators are
    --         already standalone UI elements managed by UIManager.
    -- ------------------------------------------------------------------
    if not enabled then
        return
    end

    -- ------------------------------------------------------------------
    -- Step 3: Calculate the bounding box of all visible indicators.
    --         This is the same min/max sweep from the v42.13 code.
    -- ------------------------------------------------------------------
    local minX =  1000000
    local maxX =  0
    local minY =  1000000
    local maxY =  0
    local hasVisibleBar = false

    for statId, indicator in pairs(indicators) do
        if indicator and indicator:isVisible() and statId ~= "menu" then
            -- Clear stale parent tracking fields (v42.13 compatibility)
            indicator.parentOldX = nil
            indicator.parentOldY = nil

            local ix = indicator:getX()
            local iy = indicator:getY()
            local iw = indicator:getWidth()
            local ih = indicator:getHeight()

            if ix < minX then minX = ix end
            if ix + iw > maxX then maxX = ix + iw end
            if iy < minY then minY = iy end
            if iy + ih > maxY then maxY = iy + ih end

            hasVisibleBar = true
        end
    end

    -- Nothing visible -- no panel to create
    if not hasVisibleBar then
        return
    end

    -- ------------------------------------------------------------------
    -- Step 4: Create the grouping ISPanel.
    --         The panel covers the bounding box but is invisible itself
    --         (no background, no border). Its sole purpose is to act as
    --         a movable parent container.
    -- ------------------------------------------------------------------
    local panelW = maxX - minX
    local panelH = maxY - minY
    local panel = ISPanel:new(minX, minY, panelW, panelH)
    panel:instantiate()
    panel:addToUIManager()
    panel:setVisible(false)

    MDB_MoveBarsTogether.panels[playerNum] = panel

    -- ------------------------------------------------------------------
    -- Step 5: Reparent each indicator into the panel.
    --         Setting bar.parent = panel causes PZ's ISUIElement system
    --         to treat the bar as a child whose (x, y) are relative to
    --         the parent's top-left corner. We do NOT need to manually
    --         adjust x/y here because the PZ engine handles the
    --         coordinate transform internally when .parent is set.
    -- ------------------------------------------------------------------
    for statId, indicator in pairs(indicators) do
        if indicator and statId ~= "menu" then
            indicator.parent = panel
        end
    end
end

--- Destroy the panel for a player, clearing .parent on all indicators.
-- When indicators are provided, their .parent and tracking fields are
-- cleaned up so they become standalone UIManager elements again.
--
-- @param playerNum  number     1-based player number
-- @param indicators table|nil  Map of indicator UI objects (keyed by statId).
--                              If nil, only the panel container is removed.
function MDB_MoveBarsTogether.destroyPanel(playerNum, indicators)
    local panel = MDB_MoveBarsTogether.panels[playerNum]
    if not panel then return end

    -- Clear .parent on every indicator that references our panel
    if indicators then
        for _, indicator in pairs(indicators) do
            if indicator and indicator.parent == panel then
                indicator.parent = nil
                indicator.parentOldX = nil
                indicator.parentOldY = nil
            end
        end
    end

    panel:removeFromUIManager()
    MDB_MoveBarsTogether.panels[playerNum] = nil
end

--- Alias for destroyPanel (backward compatibility).
-- @param playerNum  number     1-based player number
-- @param indicators table|nil  Map of indicator UI objects
function MDB_MoveBarsTogether.detachAndDestroy(playerNum, indicators)
    MDB_MoveBarsTogether.destroyPanel(playerNum, indicators)
end

--- Check if move-together is currently active for a player.
-- "Active" means a grouping panel exists and is managed by this module.
--
-- @param playerNum  number  1-based player number
-- @return boolean
function MDB_MoveBarsTogether.isActive(playerNum)
    return MDB_MoveBarsTogether.panels[playerNum] ~= nil
end

--- Destroy panels for ALL players. Convenience for disconnect/cleanup.
-- Only removes the panel containers; does not touch indicator .parent refs.
-- Callers that also need to clear .parent should use detachAndDestroy()
-- per player, or clear .parent themselves before calling this.
function MDB_MoveBarsTogether.destroyAll()
    for playerNum, panel in pairs(MDB_MoveBarsTogether.panels) do
        if panel then
            panel:removeFromUIManager()
        end
    end
    MDB_MoveBarsTogether.panels = {}
end

return MDB_MoveBarsTogether
