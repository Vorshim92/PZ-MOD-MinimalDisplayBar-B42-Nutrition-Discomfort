--============================================================
-- MDB_ContextMenu.lua
-- DRY context menu system for MinimalDisplayBars (v42.14).
--
-- Replaces ~700 lines of repetitive per-stat context menu code
-- from v42.13 with a single loop-driven implementation that
-- iterates over MDB_StatDefs.registry.
--
-- Dependencies:
--   MDB_Config          - Configuration cache and persistence
--   MDB_StatDefs        - Stat registry for iteration
--   MDB_Presets         - Preset loading, importing, exporting
--   MDB_MoveBarsTogether - Group panel management
--   MDB_IndicatorBase   - Base indicator class (globalAlwaysBringToTop)
--   MDB_ColorPicker     - Color picker UI (forward reference)
--   MDB_PropertiesPanel - Properties panel UI (forward reference)
--   ISContextMenu       - PZ vanilla context menu API
--============================================================

require "MDB/MDB_Config"
require "MDB/MDB_StatDefs"
require "MDB/MDB_Presets"
require "MDB/MDB_MoveBarsTogether"
require "MDB/UI/MDB_ColorPicker"

MDB_ContextMenu = {}

-- ---------------------------------------------------------------------------
-- Module-level state (mirrors old local variables)
-- ---------------------------------------------------------------------------

--- Reference to the currently open context menu (or nil).
local contextMenu = nil

--- Reference to the currently open color picker (or nil).
local colorPicker = nil

--- Tick counter for preventContextCoverup throttle.
local contextMenuTicks = 0

-- ---------------------------------------------------------------------------
-- Internal helper: ON/OFF label suffix
-- ---------------------------------------------------------------------------

--- Build a toggle label string with (ON) or (OFF) suffix.
-- @param baseTextKey  string  Translation key for the option name
-- @param isOn         boolean Current toggle state
-- @return string  Localized label with ON/OFF suffix
local function toggleLabel(baseTextKey, isOn)
    local suffix = isOn
        and getText("ContextMenu_MinimalDisplayBars_ON")
        or  getText("ContextMenu_MinimalDisplayBars_OFF")
    return getText(baseTextKey) .. " (" .. suffix .. ")"
end

-- ---------------------------------------------------------------------------
-- Internal helper: get the reference indicator for global toggles
--
-- The old code used the "hp" bar as the source of truth for global toggle
-- states. We replicate this by finding the first non-menu indicator for
-- the player, preferring "hp" if it exists.
-- ---------------------------------------------------------------------------

--- Get a reference indicator from the player's indicator set.
-- Used to read the current state of global toggles.
-- @param playerIndex  number  0-based player index
-- @return table|nil  An indicator instance, or nil if none exist
local function getReferenceIndicator(playerIndex)
    if not MDB or not MDB.indicators then return nil end
    local indicators = MDB.indicators[playerIndex]
    if not indicators then return nil end

    -- Prefer "hp" as reference (matches old behavior)
    if indicators["hp"] then
        return indicators["hp"]
    end

    -- Fallback: return the first non-menu indicator found
    for statId, indicator in pairs(indicators) do
        if statId ~= "menu" then
            return indicator
        end
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- Internal helper: iterate all indicators for a player
-- ---------------------------------------------------------------------------

--- Apply a function to every indicator belonging to a player.
-- @param playerIndex  number    0-based player index
-- @param fn           function  Called with (indicator) for each bar
function MDB_ContextMenu.applyToAllBars(playerIndex, fn)
    if not MDB or not MDB.indicators then return end
    local indicators = MDB.indicators[playerIndex]
    if not indicators then return end

    for _, indicator in pairs(indicators) do
        if indicator then
            fn(indicator)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Internal helper: recreate move-bars-together panel
-- ---------------------------------------------------------------------------

--- Recreate the MoveBarsTogether panel for the given player.
-- @param indicator  table  Any indicator (used to extract playerIndex/coopNum)
local function recreateMovePanel(indicator)
    if MDB and MDB.indicators then
        MDB_MoveBarsTogether.recreatePanel(
            indicator.coopNum,
            MDB.indicators[indicator.playerIndex])
    end
end

-- ===================================================================
-- TOGGLE FUNCTIONS
-- Each toggle reads the current value, flips it, updates the indicator
-- object and persists via MDB_Config.
-- ===================================================================

--- Reset a single bar to its default config values.
-- Preserves global toggle states (isMovable, alwaysBringToTop, etc.)
-- and only resets per-bar properties (position, size, color, etc.)
-- @param indicator  table  The indicator to reset
function MDB_ContextMenu.resetBar(indicator)
    if not indicator then return end

    local playerNum = indicator.coopNum
    local statId    = indicator.statId

    -- Load the defaults for this stat
    local defaults = MDB_Config.createDefaultConfig(playerNum)
    local defaultIndicator = defaults.indicators and defaults.indicators[statId]
    if not defaultIndicator then return end

    -- Keys to preserve (global toggles that should not be reset per-bar)
    local preserveKeys = {
        isMovable                = true,
        isResizable              = true,
        alwaysBringToTop         = true,
        showMoodletThresholdLines = true,
        isCompact                = true,
        showImage                = true,
    }

    -- Get the current config and selectively reset non-preserved keys
    local currentConfig = MDB_Config.getIndicatorConfig(playerNum, statId)
    for key, defaultVal in pairs(defaultIndicator) do
        if not preserveKeys[key] then
            MDB_Config.updateIndicatorConfig(playerNum, statId, key, defaultVal)
        end
    end

    -- Reload the indicator from config
    if indicator.loadFromConfig then
        indicator:loadFromConfig()
    elseif indicator.resetToConfigTable then
        indicator:resetToConfigTable()
    end

    recreateMovePanel(indicator)
end

--- Toggle the movable flag on a single indicator.
-- @param indicator  table  The indicator to toggle
function MDB_ContextMenu.toggleMovable(indicator)
    if not indicator then return end
    local newVal = not indicator.moveWithMouse
    indicator.moveWithMouse = newVal
    MDB_Config.updateIndicatorConfig(indicator.coopNum, indicator.statId, "isMovable", newVal)
end

--- Toggle the alwaysBringToTop flag on a single indicator.
-- BUG FIX: The old v42.13 code had a bug where the else branch set
-- config to false instead of true. This is now corrected.
-- @param indicator  table  The indicator to toggle
function MDB_ContextMenu.toggleAlwaysBringToTop(indicator)
    if not indicator then return end
    local newVal = not indicator.alwaysBringToTop
    indicator.alwaysBringToTop = newVal
    -- BUG FIX: old code set config to false in both branches
    MDB_Config.updateIndicatorConfig(indicator.coopNum, indicator.statId, "alwaysBringToTop", newVal)
end

--- Toggle the showMoodletThresholdLines flag on a single indicator.
-- @param indicator  table  The indicator to toggle
function MDB_ContextMenu.toggleMoodletThresholdLines(indicator)
    if not indicator then return end
    local newVal = not indicator.showMoodletThresholdLines
    indicator.showMoodletThresholdLines = newVal
    MDB_Config.updateIndicatorConfig(indicator.coopNum, indicator.statId, "showMoodletThresholdLines", newVal)
end

--- Toggle the moveBarsTogether flag on a single indicator.
-- Note: moveBarsTogether is a global setting stored per-indicator for
-- convenience, and also in globalSettings.
-- @param indicator  table  The indicator to toggle
function MDB_ContextMenu.toggleMoveBarsTogether(indicator)
    if not indicator then return end
    local newVal = not indicator.moveBarsTogether
    indicator.moveBarsTogether = newVal
    MDB_Config.updateGlobalConfig(indicator.coopNum, "moveBarsTogether", newVal)
end

--- Toggle the showImage flag on a single indicator.
-- @param indicator  table  The indicator to toggle
function MDB_ContextMenu.toggleShowImage(indicator)
    if not indicator then return end
    local newVal = not indicator.showImage
    indicator.showImage = newVal
    MDB_Config.updateIndicatorConfig(indicator.coopNum, indicator.statId, "showImage", newVal)
end

-- ===================================================================
-- STYLE SWITCH (bar <-> circular hot-swap)
-- ===================================================================

--- Switch an indicator between bar and circular style.
-- Destroys the current indicator and creates a new one of the opposite type
-- at the same position. This is a hot-swap: no game reload required.
-- @param indicator  table  The indicator to switch
function MDB_ContextMenu.switchStyle(indicator)
    if not indicator then return end
    if not MDB or not MDB.indicators then return end

    local playerIndex = indicator.playerIndex
    local coopNum     = indicator.coopNum
    local statId      = indicator.statId
    local isoPlayer   = indicator.isoPlayer
    local xOffset     = indicator.xOffset
    local yOffset     = indicator.yOffset

    -- Determine new style
    local config = MDB_Config.getIndicatorConfig(coopNum, statId)
    local currentStyle = config.style or "bar"
    local newStyle = (currentStyle == "circular") and "bar" or "circular"

    -- Persist the new style to config
    MDB_Config.updateIndicatorConfig(coopNum, statId, "style", newStyle)

    -- Remove old indicator from UI
    indicator:removeFromUIManager()
    indicator:setVisible(false)

    -- Create new indicator of the opposite type
    local newIndicator
    if newStyle == "circular" then
        newIndicator = MDB_CircularIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
    else
        newIndicator = MDB_BarIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
    end

    newIndicator:initialise()
    newIndicator:addToUIManager()

    -- Replace in the indicators table
    MDB.indicators[playerIndex][statId] = newIndicator

    -- Recreate the move-together panel if active
    recreateMovePanel(newIndicator)
end

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

--- Open the properties panel (height/width editor) for a bar.
-- @param indicator  table  The indicator to edit
function MDB_ContextMenu.openPropertiesPanel(indicator)
    if not indicator then return end

    -- Suppress bringToTop while the panel is open
    MDB_IndicatorBase.globalAlwaysBringToTop = false

    -- Close existing properties panel if open
    if MDB.displayBarPropertiesPanel and MDB.displayBarPropertiesPanel.close then
        MDB.displayBarPropertiesPanel:close()
    end

    MDB.displayBarPropertiesPanel =
        MDB_PropertiesPanel:new(
            indicator:getX(),
            indicator:getY(),
            indicator)

    indicator.displayBarPropertiesPanel = MDB.displayBarPropertiesPanel
    MDB.displayBarPropertiesPanel:initialise()
    MDB.displayBarPropertiesPanel:addToUIManager()

    -- Clamp panel to screen bounds
    local screenHeight = getCore():getScreenHeight()
    local bottom = MDB.displayBarPropertiesPanel.y + MDB.displayBarPropertiesPanel.height
    if bottom > screenHeight then
        MDB.displayBarPropertiesPanel:setY(
            MDB.displayBarPropertiesPanel.y - (bottom - screenHeight))
    end

    local screenWidth = getCore():getScreenWidth()
    local right = MDB.displayBarPropertiesPanel.x + MDB.displayBarPropertiesPanel.width
    if right > screenWidth then
        MDB.displayBarPropertiesPanel:setX(
            MDB.displayBarPropertiesPanel.x - (right - screenWidth))
    end
end

--- Open the color picker for a bar and wire up the callback.
-- @param indicator  table  The indicator whose color to change
function MDB_ContextMenu.openColorPicker(indicator)
    if not indicator then return end

    -- Suppress bringToTop while the picker is open
    MDB_IndicatorBase.globalAlwaysBringToTop = false

    -- Close existing color picker if open
    if colorPicker and colorPicker.close then
        colorPicker:close()
    end

    colorPicker = MDB_ColorPicker:new(indicator.x, indicator.y)
    indicator.colorPicker = colorPicker
    colorPicker:initialise()

    -- Set the initial color to match the bar's current color
    colorPicker:setInitialColor(
        ColorInfo.new(
            indicator.color.red,
            indicator.color.green,
            indicator.color.blue,
            indicator.color.alpha))

    -- Wire up the pick callback to update both indicator and config
    colorPicker.pickedTarget = indicator
    colorPicker.pickedFunc = function(target, color)
        target.color = {
            red   = color.r,
            green = color.g,
            blue  = color.b,
            alpha = target.color.alpha,
        }

        MDB_Config.updateIndicatorConfig(
            target.coopNum, target.statId, "color", target.color)

        colorPicker:close()
    end

    -- Clamp color picker to screen bounds
    local screenHeight = getCore():getScreenHeight()
    local bottom = colorPicker.y + colorPicker.height
    if bottom > screenHeight then
        colorPicker.y = colorPicker.y - (bottom - screenHeight)
    end

    local screenWidth = getCore():getScreenWidth()
    local right = colorPicker.x + colorPicker.width
    if right > screenWidth then
        colorPicker.x = colorPicker.x - (right - screenWidth)
    end

    colorPicker:addToUIManager()
end

-- ===================================================================
-- PREVENT CONTEXT COVERUP
-- Runs on OnRenderTick. Ensures bars do not cover the context menu,
-- color picker, or properties panel while they are open.
-- Preserves exact logic from old code lines 2178-2202.
-- ===================================================================

function MDB_ContextMenu.preventContextCoverup()
    contextMenuTicks = contextMenuTicks + 1

    if contextMenuTicks >= 16 then
        contextMenuTicks = 0

        -- Clean up stale references for closed UI elements
        if contextMenu and not contextMenu:isVisible() then
            contextMenu = nil
        elseif MDB.displayBarPropertiesPanel and not MDB.displayBarPropertiesPanel:isVisible() then
            MDB.displayBarPropertiesPanel = nil
        elseif colorPicker and not colorPicker:isVisible() then
            colorPicker = nil
        end

        -- Re-enable bringToTop when all overlay UIs are closed
        if not contextMenu
                and not colorPicker
                and not MDB.displayBarPropertiesPanel then
            MDB_IndicatorBase.globalAlwaysBringToTop = true
        end
    end
end

-- ===================================================================
-- ENTRY POINT
-- Called from MDB_IndicatorBase:onRightMouseUp
-- ===================================================================

--- Show the appropriate context menu for the given indicator.
-- Dispatches to showMenuContext or showBarContext based on statId.
-- @param indicator  table  The indicator that was right-clicked
-- @param dx         number Mouse x offset within the indicator
-- @param dy         number Mouse y offset within the indicator
function MDB_ContextMenu.show(indicator, dx, dy)
    -- Suppress bringToTop while context menu is open
    MDB_IndicatorBase.globalAlwaysBringToTop = false

    -- Create the context menu at the click position
    contextMenu = ISContextMenu.get(
        indicator.playerIndex,
        (indicator.x + dx), (indicator.y + dy),
        1, 1)

    -- Title header
    contextMenu:addOption("--- Minimal Display Bars ---")

    -- Display bar name header
    local statDef = MDB_StatDefs.byId[indicator.statId]
    local translationKey = statDef and statDef.translationKey
        or ("ContextMenu_MinimalDisplayBars_" .. indicator.statId)
    contextMenu:addOption("==/   " .. getText(translationKey) .. "   \\==")

    -- Dispatch to the appropriate context menu builder
    if indicator.statId == "menu" then
        MDB_ContextMenu.showMenuContext(indicator, dx, dy)
    else
        MDB_ContextMenu.showBarContext(indicator, dx, dy)
    end
end

-- ===================================================================
-- MENU CONTEXT MENU (right-click on the menu button)
-- ===================================================================

--- Build the context menu for the menu button indicator.
-- @param indicator  table  The menu indicator
-- @param dx         number Mouse x offset
-- @param dy         number Mouse y offset
function MDB_ContextMenu.showMenuContext(indicator, dx, dy)
    local playerIndex = indicator.playerIndex
    local playerNum   = indicator.coopNum
    local refBar      = getReferenceIndicator(playerIndex)

    -- ---------------------------------------------------------------
    -- 1. Reset All
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Reset"),
        indicator,
        function(ind)
            if not ind then return end

            -- Reset the full config to defaults
            local defaults = MDB_Config.createDefaultConfig(playerNum)
            MDB_Config.setFullConfig(playerNum, defaults)
            MDB_Config.forceSave(playerNum)

            -- Reload all indicators from config
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.loadFromConfig then
                    bar:loadFromConfig()
                elseif bar.resetToConfigTable then
                    bar:resetToConfigTable()
                end
            end)

            recreateMovePanel(ind)
        end)

    -- ---------------------------------------------------------------
    -- 2. Show Display Bar (submenu)
    -- ---------------------------------------------------------------
    local showSubMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(
        contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Show_Bar")),
        showSubMenu)

    -- Show All
    showSubMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Show_All_Display_Bars"),
        indicator,
        function(ind)
            if not ind then return end
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                MDB_Config.updateIndicatorConfig(bar.coopNum, bar.statId, "isVisible", true)
                bar:setVisible(true)
            end)
            recreateMovePanel(ind)
        end)

    -- Per-stat show options (loop over registry, skip menu)
    for _, entry in ipairs(MDB_StatDefs.registry) do
        if not entry.isMenu then
            local statId = entry.id
            showSubMenu:addOption(
                getText(entry.translationKey),
                nil,
                function()
                    local indicators = MDB.indicators[playerIndex]
                    local bar = indicators and indicators[statId]
                    if bar then
                        MDB_Config.updateIndicatorConfig(bar.coopNum, statId, "isVisible", true)
                        bar:setVisible(true)
                        recreateMovePanel(indicator)
                    end
                end)
        end
    end

    -- ---------------------------------------------------------------
    -- 3. Hide Display Bar (submenu)
    -- ---------------------------------------------------------------
    local hideSubMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(
        contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Hide_Bar")),
        hideSubMenu)

    -- Hide All
    hideSubMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Hide_All_Display_Bars"),
        indicator,
        function(ind)
            if not ind then return end
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                MDB_Config.updateIndicatorConfig(bar.coopNum, bar.statId, "isVisible", false)
                bar:setVisible(false)
            end)
            recreateMovePanel(ind)
        end)

    -- Per-stat hide options (loop over registry, skip menu)
    for _, entry in ipairs(MDB_StatDefs.registry) do
        if not entry.isMenu then
            local statId = entry.id
            hideSubMenu:addOption(
                getText(entry.translationKey),
                nil,
                function()
                    local indicators = MDB.indicators[playerIndex]
                    local bar = indicators and indicators[statId]
                    if bar then
                        MDB_Config.updateIndicatorConfig(bar.coopNum, statId, "isVisible", false)
                        bar:setVisible(false)
                        recreateMovePanel(indicator)
                    end
                end)
        end
    end

    -- ---------------------------------------------------------------
    -- 4. Set Height/Width (submenu)
    -- ---------------------------------------------------------------
    local hwSubMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(
        contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth")),
        hwSubMenu)

    for _, entry in ipairs(MDB_StatDefs.registry) do
        local statId = entry.id
        hwSubMenu:addOption(
            getText(entry.translationKey),
            nil,
            function()
                local indicators = MDB.indicators[playerIndex]
                local bar = indicators and indicators[statId]
                if bar then
                    MDB_ContextMenu.openPropertiesPanel(bar)
                end
            end)
    end

    -- ---------------------------------------------------------------
    -- 5. Set Color (submenu, skip temperature which has dynamic color)
    -- ---------------------------------------------------------------
    local colorSubMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(
        contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_Color")),
        colorSubMenu)

    for _, entry in ipairs(MDB_StatDefs.registry) do
        if entry.id ~= "temperature" then
            local statId = entry.id
            colorSubMenu:addOption(
                getText(entry.translationKey),
                nil,
                function()
                    local indicators = MDB.indicators[playerIndex]
                    local bar = indicators and indicators[statId]
                    if bar then
                        MDB_ContextMenu.openColorPicker(bar)
                    end
                end)
        end
    end

    -- ---------------------------------------------------------------
    -- 6. Toggle Movable All
    -- ---------------------------------------------------------------
    local movableState = refBar and refBar.moveWithMouse or false
    contextMenu:addOption(
        toggleLabel("ContextMenu_MinimalDisplayBars_Toggle_Movable_All", movableState),
        indicator,
        function(ind)
            if not ind then return end

            -- Toggle the reference bar first to establish the new state
            if refBar then
                MDB_ContextMenu.toggleMovable(refBar)
            end

            -- Also toggle the menu indicator itself
            MDB_ContextMenu.toggleMovable(ind)

            -- Synchronize all other bars to match the reference
            local newState = refBar and refBar.moveWithMouse
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.moveWithMouse ~= newState then
                    MDB_ContextMenu.toggleMovable(bar)
                end
            end)
        end)

    -- ---------------------------------------------------------------
    -- 7. Toggle Always Bring To Top (BUG FIX applied in toggleAlwaysBringToTop)
    -- ---------------------------------------------------------------
    local bringToTopState = refBar and refBar.alwaysBringToTop or false
    contextMenu:addOption(
        toggleLabel("ContextMenu_MinimalDisplayBars_Toggle_Always_Bring_Display_Bars_To_Top", bringToTopState),
        indicator,
        function(ind)
            if not ind then return end

            if refBar then
                MDB_ContextMenu.toggleAlwaysBringToTop(refBar)
            end

            local newState = refBar and refBar.alwaysBringToTop
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.alwaysBringToTop ~= newState then
                    MDB_ContextMenu.toggleAlwaysBringToTop(bar)
                end
            end)
        end)

    -- ---------------------------------------------------------------
    -- 8. Toggle Moodlet Threshold Lines
    -- ---------------------------------------------------------------
    local thresholdState = refBar and refBar.showMoodletThresholdLines or false
    contextMenu:addOption(
        toggleLabel("ContextMenu_MinimalDisplayBars_Toggle_Moodlet_Threshold_Lines", thresholdState),
        indicator,
        function(ind)
            if not ind then return end

            if refBar then
                MDB_ContextMenu.toggleMoodletThresholdLines(refBar)
            end

            local newState = refBar and refBar.showMoodletThresholdLines
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.showMoodletThresholdLines ~= newState then
                    MDB_ContextMenu.toggleMoodletThresholdLines(bar)
                end
            end)
        end)

    -- ---------------------------------------------------------------
    -- 9. Toggle Move Bars Together
    -- ---------------------------------------------------------------
    local moveTogether = refBar and refBar.moveBarsTogether or false
    contextMenu:addOption(
        toggleLabel("ContextMenu_MinimalDisplayBars_Toggle_Move_Bars_Together", moveTogether),
        indicator,
        function(ind)
            if not ind then return end

            if refBar then
                MDB_ContextMenu.toggleMoveBarsTogether(refBar)
            end

            local newState = refBar and refBar.moveBarsTogether
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.moveBarsTogether ~= newState then
                    MDB_ContextMenu.toggleMoveBarsTogether(bar)
                end
            end)

            recreateMovePanel(ind)
        end)

    -- ---------------------------------------------------------------
    -- 10. Toggle Show Image
    -- ---------------------------------------------------------------
    local showImageState = refBar and refBar.showImage or false
    contextMenu:addOption(
        toggleLabel("ContextMenu_MinimalDisplayBars_Toggle_Show_Image", showImageState),
        indicator,
        function(ind)
            if not ind then return end

            if refBar then
                MDB_ContextMenu.toggleShowImage(refBar)
            end

            local newState = refBar and refBar.showImage
            MDB_ContextMenu.applyToAllBars(playerIndex, function(bar)
                if bar.showImage ~= newState then
                    MDB_ContextMenu.toggleShowImage(bar)
                end
            end)
        end)

    -- ---------------------------------------------------------------
    -- 11. Load / Import / Export Preset (submenu)
    -- ---------------------------------------------------------------
    local presetSubMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(
        contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Toggle_Load_Preset")),
        presetSubMenu)

    -- Load User Preset (MDB_Preset.lua)
    presetSubMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Toggle_Load_Preset"),
        indicator,
        function(ind)
            if not ind then return end
            MDB_Presets.showLoadModal(ind)
        end)

    -- Built-in presets (deterministic order)
    for _, presetName in ipairs(MDB_Presets.builtInOrder) do
        local presetEntry = MDB_Presets.builtIn[presetName]
        if presetEntry then
            local displayLabel = getText("ContextMenu_MinimalDisplayBars_Toggle_Import_Preset")
                .. " " .. presetEntry.displayName
                .. " (" .. presetName .. ")"
            presetSubMenu:addOption(
                displayLabel,
                indicator,
                function(ind)
                    if not ind then return end
                    MDB_Presets.showImportModal(ind, presetName)
                end)
        end
    end

    -- Export Current Config
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Toggle_Export_Preset"),
        indicator,
        function(ind)
            if not ind then return end
            MDB_Presets.exportUserPreset(playerNum)
        end)
end

-- ===================================================================
-- BAR CONTEXT MENU (right-click on a stat bar)
-- ===================================================================

--- Build the context menu for a stat bar indicator.
-- @param indicator  table  The stat bar indicator
-- @param dx         number Mouse x offset
-- @param dy         number Mouse y offset
function MDB_ContextMenu.showBarContext(indicator, dx, dy)
    local playerIndex = indicator.playerIndex
    local playerNum   = indicator.coopNum
    local statId      = indicator.statId

    -- ---------------------------------------------------------------
    -- 1. Reset This Bar
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Reset_Display_Bar"),
        indicator,
        function(ind)
            MDB_ContextMenu.resetBar(ind)
        end)

    -- ---------------------------------------------------------------
    -- 2. Set Vertical
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Set_Vertical"),
        indicator,
        function(ind)
            if not ind then return end
            if ind.isVertical == false then
                ind.isVertical = true
                MDB_Config.updateIndicatorConfig(playerNum, statId, "isVertical", true)

                local oldW = tonumber(ind.oldWidth)
                local oldH = tonumber(ind.oldHeight)
                ind:setWidth(oldH)
                ind:setHeight(oldW)

                MDB_Config.updateIndicatorConfig(playerNum, statId, "width", ind:getWidth())
                MDB_Config.updateIndicatorConfig(playerNum, statId, "height", ind:getHeight())

                recreateMovePanel(ind)
            end
        end)

    -- ---------------------------------------------------------------
    -- 3. Set Horizontal
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Set_Horizontal"),
        indicator,
        function(ind)
            if not ind then return end
            if ind.isVertical == true then
                ind.isVertical = false
                MDB_Config.updateIndicatorConfig(playerNum, statId, "isVertical", false)

                local oldW = tonumber(ind.oldWidth)
                local oldH = tonumber(ind.oldHeight)
                ind:setWidth(oldH)
                ind:setHeight(oldW)

                MDB_Config.updateIndicatorConfig(playerNum, statId, "width", ind:getWidth())
                MDB_Config.updateIndicatorConfig(playerNum, statId, "height", ind:getHeight())

                recreateMovePanel(ind)
            end
        end)

    -- ---------------------------------------------------------------
    -- 4. Icon Position (Left/Right toggle, only meaningful for horizontal)
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        "Set Horizontal Icon (" .. (indicator.isIconRight and "Left" or "Right") .. ")",
        indicator,
        function(ind)
            if not ind then return end
            ind.isIconRight = not ind.isIconRight
            MDB_Config.updateIndicatorConfig(playerNum, statId, "isIconRight", ind.isIconRight)
            recreateMovePanel(ind)
        end)

    -- ---------------------------------------------------------------
    -- 5. Show/Hide Icon toggle
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        (indicator.showImage and "Hide" or "Show") .. " Icon",
        indicator,
        function(ind)
            if not ind then return end
            ind.showImage = not ind.showImage
            MDB_Config.updateIndicatorConfig(playerNum, statId, "showImage", ind.showImage)
            recreateMovePanel(ind)
        end)

    -- ---------------------------------------------------------------
    -- 6. Set Color (skip for temperature which uses dynamic color)
    -- ---------------------------------------------------------------
    if statId ~= "temperature" then
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_Color"),
            indicator,
            function(ind)
                MDB_ContextMenu.openColorPicker(ind)
            end)
    end

    -- ---------------------------------------------------------------
    -- 7. Set Height / Width (opens properties panel)
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth"),
        indicator,
        function(ind)
            MDB_ContextMenu.openPropertiesPanel(ind)
        end)

    -- ---------------------------------------------------------------
    -- 8. Switch Style (Bar <-> Circular)
    -- ---------------------------------------------------------------
    local currentStyle = MDB_Config.getIndicatorConfig(playerNum, statId).style or "bar"
    local styleLabel = (currentStyle == "circular")
        and "Switch to Bar"
        or  "Switch to Circular"
    contextMenu:addOption(
        styleLabel,
        indicator,
        function(ind)
            MDB_ContextMenu.switchStyle(ind)
        end)

    -- ---------------------------------------------------------------
    -- 9. Hide this bar
    -- ---------------------------------------------------------------
    contextMenu:addOption(
        getText("ContextMenu_MinimalDisplayBars_Hide"),
        indicator,
        function(ind)
            if not ind then return end
            ind:setVisible(false)
            MDB_Config.updateIndicatorConfig(playerNum, statId, "isVisible", false)
            recreateMovePanel(ind)
        end)
end

return MDB_ContextMenu
