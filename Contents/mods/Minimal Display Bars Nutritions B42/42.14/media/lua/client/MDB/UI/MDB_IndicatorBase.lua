--============================================================
-- MDB_IndicatorBase.lua
-- Base class for all MinimalDisplayBars indicator types (v42.14).
--
-- Derives from ISUIElement and provides shared functionality:
--   - Constructor that reads from MDB_Config
--   - Mouse handling (move, right-click context menu, tooltip)
--   - Position persistence via MDB_Config (deferred save)
--   - Moodle background texture lookup
--   - Config reload (loadFromConfig)
--   - Parent panel tracking for moveBarsTogether mode
--
-- MDB_BarIndicator and MDB_CircularIndicator derive from this.
-- This class intentionally has NO render() method; subclasses
-- provide their own rendering logic.
--
-- Dependencies:
--   ISUI/ISUIElement - PZ built-in base UI element
--   MDB_Config       - Configuration cache and persistence
--   MDB_StatDefs     - Stat registry (getValue, getRawValue, thresholds)
--============================================================

require "ISUI/ISUIElement"
require "MDB/MDB_Config"
require "MDB/MDB_StatDefs"

MDB_IndicatorBase = ISUIElement:derive("MDB_IndicatorBase")

-- ---------------------------------------------------------------------------
-- Class-level state (shared across all instances)
-- ---------------------------------------------------------------------------

--- When true, all indicators with alwaysBringToTop will call bringToTop().
-- Mirrors the old ISGenericMiniDisplayBar.alwaysBringToTop.
MDB_IndicatorBase.globalAlwaysBringToTop = true

--- When true, suppresses position-change persistence (editing in properties panel).
MDB_IndicatorBase.isEditing = false

-- ---------------------------------------------------------------------------
-- Font height constants (cached once at load time, like the old code)
-- ---------------------------------------------------------------------------

local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE  = getTextManager():getFontHeight(UIFont.Large)

-- ---------------------------------------------------------------------------
-- setWidth / setHeight - Track old dimensions and recompute inner area
-- (preserved from old code lines 13-25)
-- ---------------------------------------------------------------------------

function MDB_IndicatorBase:setWidth(w, ...)
    local panel = ISUIElement.setWidth(self, w, ...)
    self.oldWidth = self.width
    self.innerWidth = (self.width - self.borderSizes.l - self.borderSizes.r)
    return panel
end

function MDB_IndicatorBase:setHeight(h, ...)
    local panel = ISUIElement.setHeight(self, h, ...)
    self.oldHeight = self.height
    self.innerHeight = (self.height - self.borderSizes.t - self.borderSizes.b)
    return panel
end

-- ---------------------------------------------------------------------------
-- Mouse handlers
-- (preserved from old code lines 27-133, updated references)
-- ---------------------------------------------------------------------------

--- Empty placeholder -- subclasses or Phase 2 may override.
function MDB_IndicatorBase:onMouseDoubleClick(x, y, ...)
    return
end

function MDB_IndicatorBase:onMouseDown(x, y)
    if not self.moveWithMouse then return true end
    if not self:getIsVisible() then return end
    if not self:isMouseOver() then return end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
    self.oldX = self.x
    self.oldY = self.y
end

function MDB_IndicatorBase:onMouseUp(x, y)
    if not self.moveWithMouse then return end
    if not self:getIsVisible() then return end
    self.moving = false
    ISMouseDrag.dragView = nil
end

function MDB_IndicatorBase:onMouseUpOutside(x, y)
    if not self.moveWithMouse then return end
    if not self:getIsVisible() then return end
    self.moving = false
    ISMouseDrag.dragView = nil
end

function MDB_IndicatorBase:onMouseMove(dx, dy)
    if not self.moveWithMouse then return end
    self.mouseOver = true
    self.showTooltip = true
    self:bringToTop()

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx)
            self.parent:setY(self.parent.y + dy)
        else
            self:setX(self.x + dx)
            self:setY(self.y + dy)
            self:bringToTop()
        end
        -- Update properties panel position readouts
        if MDB_PropertiesPanel and MDB_PropertiesPanel.instance then
            local pp = MDB_PropertiesPanel.instance
            if pp.displayBar and pp.displayBar == self then
                if pp.textEntryX then pp.textEntryX:setText(tostring(self:getX())) end
                if pp.textEntryY then pp.textEntryY:setText(tostring(self:getY())) end
            end
        end
    end
end

function MDB_IndicatorBase:onMouseMoveOutside(dx, dy)
    if not self.moveWithMouse then return end
    self.mouseOver = false
    self.showTooltip = false

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx)
            self.parent:setY(self.parent.y + dy)
        else
            self:setX(self.x + dx)
            self:setY(self.y + dy)
            self:bringToTop()
        end
        if MDB_PropertiesPanel and MDB_PropertiesPanel.instance then
            local pp = MDB_PropertiesPanel.instance
            if pp.textEntryX then pp.textEntryX:setText(tostring(self:getX())) end
            if pp.textEntryY then pp.textEntryY:setText(tostring(self:getY())) end
        end
    end
end

function MDB_IndicatorBase:onRightMouseDown(x, y)
    self.rightMouseDown = true
end

function MDB_IndicatorBase:onRightMouseUp(dx, dy)
    if self.rightMouseDown then
        if MDB_ContextMenu and MDB_ContextMenu.show then
            MDB_ContextMenu.show(self, dx, dy)
        end
    end
    self.rightMouseDown = false
end

function MDB_IndicatorBase:onRightMouseUpOutside(x, y)
    self.rightMouseDown = false
end

function MDB_IndicatorBase:setOnMouseDoubleClick(target, onmousedblclick, ...)
    return ISUIElement.setOnMouseDoubleClick(self, target, onmousedblclick, ...)
end

-- ---------------------------------------------------------------------------
-- getImageBG - Moodle background texture based on good/bad/neutral and level
-- (preserved exactly from old code lines 177-253)
-- ---------------------------------------------------------------------------

--- Returns the moodle background texture for the given player and moodle type.
-- The texture chosen depends on the good/bad/neutral classification and severity level.
-- @param isoPlayer  IsoPlayer object
-- @param moodleType MoodleType enum value
-- @return Texture or nil
function MDB_IndicatorBase:getImageBG(isoPlayer, moodleType)
    local moodles = isoPlayer:getMoodles()
    local goodBadNeutral = moodles:getGoodBadNeutral(moodleType)
    local moodleLevel = moodles:getMoodleLevel(moodleType)

    local switchA =
    {
        -- Neutral (0): always Good_4 background
        [0] = function()
            return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
        end,

        -- Good (1): severity-scaled good backgrounds
        [1] = function()
            local switchB =
            {
                [1] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_1.png")
                end,
                [2] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_2.png")
                end,
                [3] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_3.png")
                end,
                [4] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
                end,
            }

            local sFunc = switchB[moodleLevel]
            if (sFunc) then
                return sFunc()
            else
                return nil
            end
        end,

        -- Bad (2): severity-scaled bad backgrounds (level 0 = Good_4 neutral fallback)
        [2] = function()
            local switchB =
            {
                [0] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
                end,
                [1] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_1.png")
                end,
                [2] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_2.png")
                end,
                [3] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_3.png")
                end,
                [4] = function()
                    return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_4.png")
                end,
            }

            local sFunc = switchB[moodleLevel]
            if (sFunc) then
                return sFunc()
            else
                return nil
            end
        end,
    }

    local sFunc = switchA[goodBadNeutral]

    if (sFunc) then
        return sFunc()
    else
        return nil
    end
end

-- ---------------------------------------------------------------------------
-- loadFromConfig - Reload all properties from MDB_Config
-- Replaces the old resetToConfigTable() (lines 524-588)
-- ---------------------------------------------------------------------------

--- Reloads all visual/behavioral properties from the config cache.
-- Call this after external changes (properties panel, preset load, etc.)
function MDB_IndicatorBase:loadFromConfig()
    local config = MDB_Config.getIndicatorConfig(self.coopNum, self.statId)
    if not config then return end

    -- Position (offset-relative to support split-screen)
    self.x = config.x + self.xOffset
    self.y = config.y + self.yOffset
    self.oldX = self.x
    self.oldY = self.y

    -- Dimensions
    self:setWidth(config.width)
    self:setHeight(config.height)
    self.oldWidth = self.width
    self.oldHeight = self.height

    -- Interaction
    self.moveWithMouse = config.isMovable
    self.resizeWithMouse = config.isResizable

    -- Borders and inner dimensions
    self.borderSizes = {
        l = config.l,
        t = config.t,
        r = config.r,
        b = config.b,
    }
    self.innerWidth  = (self.width  - self.borderSizes.l - self.borderSizes.r)
    self.innerHeight = (self.height - self.borderSizes.t - self.borderSizes.b)

    -- Minimum sizes based on border
    self.minimumWidth  = (1 + self.borderSizes.l + self.borderSizes.r)
    self.minimumHeight = (1 + self.borderSizes.t + self.borderSizes.b)

    -- Color (static config color; dynamic color is applied per-frame by subclass)
    self.color = config.color

    -- Orientation
    self.isVertical = config.isVertical

    -- Threshold lines
    self.showMoodletThresholdLines = config.showMoodletThresholdLines

    -- Compact mode
    self.isCompact = config.isCompact

    -- Icon rendering
    self.imageName     = config.imageName
    self.imageSize     = config.imageSize
    self.imageShowBack = config.imageShowBack
    self.showImage     = config.showImage
    self.isIconRight   = config.isIconRight

    -- BringToTop preference
    self.alwaysBringToTop = config.alwaysBringToTop

    -- Reload ThreePatch textures if this indicator supports them
    if self.loadThreePatchTextures then
        self:loadThreePatchTextures()
    end

    -- Reload menu textures if this is the menu button
    if self.statId == "menu" and self.loadMenuTextures then
        self:loadMenuTextures()
    end

    -- Visibility
    self:setVisible(config.isVisible)

    -- Global setting: moveBarsTogether
    local globalConfig = MDB_Config.getGlobalConfig(self.coopNum)
    if globalConfig then
        self.moveBarsTogether = globalConfig.moveBarsTogether
    end
end

--- Alias for backward compatibility with code that calls resetToConfigTable().
MDB_IndicatorBase.resetToConfigTable = MDB_IndicatorBase.loadFromConfig

-- ---------------------------------------------------------------------------
-- onPositionChanged - Persist position to config (deferred I/O)
-- Replaces the old file I/O in render (lines 506-513)
-- ---------------------------------------------------------------------------

--- Persist the current position to the config cache.
-- MDB_Config.updateIndicatorConfig sets the dirty flag automatically;
-- actual file I/O happens on the next flushIfDirty tick.
function MDB_IndicatorBase:onPositionChanged()
    MDB_Config.updateIndicatorConfig(self.coopNum, self.statId, "x", self.x - self.xOffset)
    MDB_Config.updateIndicatorConfig(self.coopNum, self.statId, "y", self.y - self.yOffset)
end

-- ---------------------------------------------------------------------------
-- handleBringToTop - Conditional bringToTop based on config/global flags
-- ---------------------------------------------------------------------------

--- Bring this indicator to the top of the Z-order if configured to do so.
-- The menu indicator always respects its own flag regardless of the global toggle.
function MDB_IndicatorBase:handleBringToTop()
    if self.alwaysBringToTop and (MDB_IndicatorBase.globalAlwaysBringToTop or self.statId == "menu") then
        self:bringToTop()
    end
end

-- ---------------------------------------------------------------------------
-- handlePositionPersistence - Check and persist position changes
-- Called from subclass render() instead of duplicating the old inline code.
-- ---------------------------------------------------------------------------

--- Check if the indicator has moved since last frame and persist if so.
-- Skips persistence while the user is actively dragging or while the
-- properties panel is open for editing (isEditing flag).
function MDB_IndicatorBase:handlePositionPersistence()
    if not self.moving and not MDB_IndicatorBase.isEditing then
        if self.oldX ~= self.x or self.oldY ~= self.y then
            self.oldX = self.x
            self.oldY = self.y
            self:onPositionChanged()
        end
    end
end

-- ---------------------------------------------------------------------------
-- parentTracking - Follow parent panel movement (moveBarsTogether mode)
-- (preserved from old code lines 258-280)
-- ---------------------------------------------------------------------------

--- Track parent panel movement and adjust this indicator's position to follow.
-- When moveBarsTogether is active, indicators are children of a group panel.
-- This method keeps the indicator in sync with the parent's delta movement.
-- Call from the beginning of subclass render().
function MDB_IndicatorBase:parentTracking()
    if self.parent and self:isVisible() then
        -- Initialize tracking coordinates on first frame
        if not self.parentOldX or not self.parentOldY then
            self.parentOldX = self.parent.x
            self.parentOldY = self.parent.y
        end

        local pDX = self.parentOldX - self.parent.x
        local pDY = self.parentOldY - self.parent.y

        if pDX ~= 0 then
            self:setX(self.x - pDX)
            self.parentOldX = self.parent.x
        end
        if pDY ~= 0 then
            self:setY(self.y - pDY)
            self.parentOldY = self.parent.y
        end

        -- Update properties panel readout if this bar is being inspected
        if MDB_PropertiesPanel and MDB_PropertiesPanel.instance then
            local pp = MDB_PropertiesPanel.instance
            if pp.displayBar and pp.displayBar == self then
                if pp.textEntryX then
                    pp.textEntryX:setText(tostring(self:getX()))
                end
                if pp.textEntryY then
                    pp.textEntryY:setText(tostring(self:getY()))
                end
            end
        end
    else
        -- Reset tracking when not visible or no parent
        self.parentOldX = nil
        self.parentOldY = nil
    end
end

-- ---------------------------------------------------------------------------
-- renderTooltip - Draw hover/moving tooltip
-- Extracted from old code lines 421-503, adapted for MDB_StatDefs.
-- ---------------------------------------------------------------------------

--- Render the tooltip overlay when hovering or moving the indicator.
-- Shows stat name, ratio, raw value, tutorial text, and position while dragging.
-- @param value  number  The normalized 0-1 bar value (used for ratio display)
function MDB_IndicatorBase:renderTooltip(value)
    if not (self.moving or self.resizing or self.showTooltip) then
        return
    end

    local statDef = MDB_StatDefs.byId[self.statId]
    local core = getCore()

    -- Tooltip positioning: will be computed after boxWidth/boxHeight are finalized
    local gap = 4
    local absX = self:getX()
    local absY = self:getY()
    local screenW = core:getScreenWidth()
    local screenH = core:getScreenHeight()
    local boxWidth = 200
    local boxHeight = FONT_HGT_SMALL * 7

    -- Get the raw value for display
    local rawValue = 0
    local rawValueStr = ""
    local unit = ""

    if statDef and statDef.getRawValue then
        rawValue = statDef.getRawValue(self.isoPlayer)
    end

    -- Format the raw value display depending on stat type
    if self.statId == "temperature" then
        -- Handle Celsius/Fahrenheit conversion
        if core:isCelsius() or (core.getOptionDisplayAsCelsius and core:getOptionDisplayAsCelsius()) then
            rawValueStr = string.format("%.4g", rawValue)
            unit = "C"
        else
            rawValueStr = string.format("%.4g", (rawValue * 9 / 5) + 32)
            unit = "F"
        end
        rawValueStr = rawValueStr .. " " .. unit
    elseif self.statId == "calorie" then
        rawValueStr = string.format("%.4g", rawValue)
        unit = getText("ContextMenu_MinimalDisplayBars_calorie")
        rawValueStr = rawValueStr .. " " .. unit
    else
        rawValueStr = string.format("%.4g", rawValue or 0)
    end

    -- Tutorial text lines
    local tutorialLeftClick  = getText("ContextMenu_MinimalDisplayBars_Tutorial_LeftClick")
    local tutorialRightClick = getText("ContextMenu_MinimalDisplayBars_Tutorial_RightClick")

    -- Expand box width if tutorial text is wider
    local tutorialLeftClickLength  = getTextManager():MeasureStringX(UIFont.Small, tutorialLeftClick)
    local tutorialRightClickLength = getTextManager():MeasureStringX(UIFont.Small, tutorialRightClick)
    if tutorialLeftClickLength > boxWidth then
        boxWidth = tutorialLeftClickLength + 20
    end
    if tutorialRightClickLength > boxWidth then
        boxWidth = tutorialRightClickLength + 20
    end

    -- Build the tooltip text depending on stat type
    local tooltipTxt

    if self.statId == "menu" then
        -- Menu indicator: name + tutorial, no stat values
        tooltipTxt = getText("ContextMenu_MinimalDisplayBars_menu")
            .. "\r\n" .. tutorialLeftClick
            .. "\r\n" .. tutorialRightClick
            .. "\r\n"
        boxHeight = boxHeight - FONT_HGT_SMALL
        if self.moving then
            tooltipTxt = tooltipTxt .. "\r\nx: " .. self.x .. "\r\ny: " .. self.y
            boxHeight = boxHeight + FONT_HGT_SMALL * 3
        end
        boxHeight = boxHeight - FONT_HGT_SMALL * 2

    elseif self.statId == "stress" then
        -- Stress: special multi-value tooltip (base + nicotine + total)
        local rb, rc = 0, 0
        if statDef and statDef.getRawValue then
            rb, rc = statDef.getRawValue(self.isoPlayer)
        end
        local totalReal = (rb or 0) + (rc or 0)

        tooltipTxt = getText("ContextMenu_MinimalDisplayBars_stress")
            .. " \r\nBase Stress: " .. string.format("%.3f", rb or 0)
            .. " \r\nNicotine Withdrawal: " .. string.format("%.3f", rc or 0)
            .. " \r\nTotal: " .. string.format("%.3f", totalReal)
            .. " \r\n(clamped to 1.0 on bar)"
            .. "\r\n"
            .. "\r\n" .. tutorialLeftClick
            .. "\r\n" .. tutorialRightClick
            .. "\r\n"

        if self.moving then
            tooltipTxt = tooltipTxt .. "\r\nx: " .. self.x .. "\r\ny: " .. self.y
            boxHeight = boxHeight + FONT_HGT_SMALL * 3
        end

    else
        -- Standard tooltip: name, ratio, real value, tutorial
        local translationKey = (statDef and statDef.translationKey) or ("ContextMenu_MinimalDisplayBars_" .. self.statId)
        tooltipTxt = getText(translationKey)
            .. " \r\nratio: " .. string.format("%.4g", value)
            .. " \r\nreal value: " .. rawValueStr
            .. "\r\n"
            .. "\r\n" .. tutorialLeftClick
            .. "\r\n" .. tutorialRightClick
            .. "\r\n"

        if self.moving then
            tooltipTxt = tooltipTxt .. "\r\nx: " .. self.x .. "\r\ny: " .. self.y
            boxHeight = boxHeight + FONT_HGT_SMALL * 3
        end
    end

    -- Position tooltip OUTSIDE the indicator (default: to the right)
    local tooltipAbsX = absX + self.width + gap
    local tooltipAbsY = absY

    -- Flip to left if going off right edge
    if tooltipAbsX + boxWidth > screenW then
        tooltipAbsX = absX - boxWidth - gap
    end
    -- Clamp to screen edges
    if tooltipAbsX < 0 then
        tooltipAbsX = 0
    end
    if tooltipAbsY + boxHeight > screenH then
        tooltipAbsY = screenH - boxHeight
    end
    if tooltipAbsY < 0 then
        tooltipAbsY = 0
    end

    -- Convert back to element-relative coordinates
    local xOff = tooltipAbsX - absX
    local yOff = tooltipAbsY - absY

    -- Draw the tooltip box (dim overlay removed — hover feedback is per-subclass)
    self:drawRectStatic(xOff, yOff, boxWidth, boxHeight, 0.85, 0, 0, 0)
    self:drawRectBorderStatic(xOff, yOff, boxWidth, boxHeight, 0.85, 1, 1, 1)
    self:drawText(tooltipTxt, xOff + 2, yOff + 2, 1, 1, 1, 1, UIFont.Small)
end

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- Create a new MDB_IndicatorBase instance.
-- @param statId       string   Stat identifier (e.g. "hp", "hunger", "menu")
-- @param playerIndex  number   0-based player index (from PZ API)
-- @param isoPlayer    IsoPlayer  The player object
-- @param coopNum      number   1-based player number (playerIndex + 1)
-- @param xOffset      number   Horizontal offset (for split-screen positioning)
-- @param yOffset      number   Vertical offset (for split-screen positioning)
-- @return MDB_IndicatorBase instance
function MDB_IndicatorBase:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
    -- Read indicator config from the centralized config system
    local config = MDB_Config.getIndicatorConfig(coopNum, statId)

    -- Create the ISUIElement at the offset-adjusted position
    local panel = ISUIElement:new(
        config.x + xOffset,
        config.y + yOffset,
        config.width,
        config.height
    )
    setmetatable(panel, self)
    self.__index = self

    -- Identity
    panel.statId      = statId
    panel.playerIndex = playerIndex
    panel.isoPlayer   = isoPlayer
    panel.coopNum     = coopNum

    -- Offsets for split-screen support
    panel.xOffset = xOffset
    panel.yOffset = yOffset

    -- Position tracking (for detecting moves)
    panel.oldX = panel.x
    panel.oldY = panel.y
    panel.oldWidth  = panel.width
    panel.oldHeight = panel.height

    -- Interaction flags from config
    panel.moveWithMouse   = config.isMovable
    panel.resizeWithMouse = config.isResizable

    -- Border sizes and computed inner dimensions
    panel.borderSizes = {
        l = config.l,
        t = config.t,
        r = config.r,
        b = config.b,
    }
    panel.innerWidth  = (panel.width  - panel.borderSizes.l - panel.borderSizes.r)
    panel.innerHeight = (panel.height - panel.borderSizes.t - panel.borderSizes.b)

    -- Minimum sizes (at least 1px of inner area)
    panel.minimumWidth  = (1 + panel.borderSizes.l + panel.borderSizes.r)
    panel.minimumHeight = (1 + panel.borderSizes.t + panel.borderSizes.b)

    -- Color (static config color; dynamic-color stats override per-frame)
    panel.color = config.color

    -- Orientation
    panel.isVertical = config.isVertical

    -- Moodlet threshold lines
    panel.showMoodletThresholdLines = config.showMoodletThresholdLines
    panel.moodletThresholdTable     = MDB_StatDefs.getThresholds(statId)

    -- Compact mode
    panel.isCompact = config.isCompact

    -- Icon rendering
    panel.imageName     = config.imageName
    panel.imageSize     = config.imageSize
    panel.imageShowBack = config.imageShowBack
    panel.showImage     = config.showImage
    panel.isIconRight   = config.isIconRight

    -- BringToTop preference
    panel.alwaysBringToTop = config.alwaysBringToTop

    -- Visibility
    panel:setVisible(config.isVisible)

    -- Global settings
    local globalConfig = MDB_Config.getGlobalConfig(coopNum)
    if globalConfig then
        panel.moveBarsTogether = globalConfig.moveBarsTogether
    end

    -- Reset the editing flag on construction
    MDB_IndicatorBase.isEditing = false

    return panel
end

return MDB_IndicatorBase
