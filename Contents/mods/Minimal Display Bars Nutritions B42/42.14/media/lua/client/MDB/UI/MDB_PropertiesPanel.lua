--
-- MDB_PropertiesPanel.lua
-- Refactored from ISDisplayBarPropertiesPanel (v42.13) for the new MDB_Config system.
--
-- This panel allows users to edit indicator properties (position, size, icon
-- size, vertical mode) and persists changes via MDB_Config's deferred-save
-- approach instead of calling io_persistence.store() directly.
--

require "ISUI/ISPanel"
require "MDB/MDB_Config"
require "MDB/UI/MDB_TextEntryBox"

MDB_PropertiesPanel = ISPanel:derive("MDB_PropertiesPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

-- ---------------------------------------------------------------------------
-- Local utility: deep copy (used for originalConfig snapshots)
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
-- Initialise / Visibility
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:initialise()
    ISPanel.initialise(self)
    self:create()
end

function MDB_PropertiesPanel:setVisible(visible)
    self.javaObject:setVisible(visible)
end

-- ---------------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:render()
    local y = 20

    local titleText =
        getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth")
            .. " ("
            .. getText("ContextMenu_MinimalDisplayBars_" .. self.barPanel.statId .. "")
            .. ")"
    self:drawText(
        titleText,
        self.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, titleText) / 2),
        y,
        1, 1, 1, 1, UIFont.Medium)

    y = y + 30

    self:updateButtons()
end

-- ---------------------------------------------------------------------------
-- Create (layout all child widgets)
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:create()
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)

    local xSpacing = 4
    local padBottom = 10

    local y = 10 + 50

    local labelXName = "x" .. ": "
    local labelYName = "y" .. ": "
    local labelWidthName = getText("ContextMenu_MinimalDisplayBars_Width") .. ": "
    if labelWidthName == "ContextMenu_MinimalDisplayBars_Width: " then
        labelWidthName = "Width: "
    end
    local labelHeightName = getText("ContextMenu_MinimalDisplayBars_Height") .. ": "
    if labelHeightName == "ContextMenu_MinimalDisplayBars_Height: " then
        labelHeightName = "Height: "
    end
    local labelImageSizeName = getText("ContextMenu_MinimalDisplayBars_IconSize") .. ": "
    if labelImageSizeName == "ContextMenu_MinimalDisplayBars_IconSize: " then
        labelImageSizeName = "Height: "
    end
    local labelSetVerticalName = getText("ContextMenu_MinimalDisplayBars_Set_Vertical")
    if labelSetVerticalName == "ContextMenu_MinimalDisplayBars_Set_Vertical" then
        labelSetVerticalName = "Set Vertical"
    end

    ------------------------------------
    -- X
    self.textEntryX =
        MDB_TextEntryBox:new(
            "x",
            tostring(self.barPanel:getX()),
            self:getWidth() / 2 + 32,
            y,
            self.width - 20,
            FONT_HGT_SMALL + 4,
            self.barPanel)
    self.textEntryX:initialise()
    self.textEntryX:instantiate()
    self.textEntryX:setOnlyNumbers(true)
    self:addChild(self.textEntryX)

    self.labelX =
        ISLabel:new(
            self.textEntryX:getX(),
            y,
            FONT_HGT_SMALL + 4,
            "",
            1, 1, 1, 1,
            UIFont.Small,
            true)
    self.labelX:setTranslation(labelXName)
    self.labelX:setX(self.labelX:getX() - self.labelX:getWidth())
    self.labelX:initialise()
    self.labelX:instantiate()
    self:addChild(self.labelX)
    y = y + self.textEntryX:getHeight()

    ------------------------------------
    -- Y
    self.textEntryY =
        MDB_TextEntryBox:new(
            "y",
            tostring(self.barPanel:getY()),
            self:getWidth() / 2 + 32,
            y,
            self.width - 20,
            FONT_HGT_SMALL + 4,
            self.barPanel)
    self.textEntryY:initialise()
    self.textEntryY:instantiate()
    self.textEntryY:setOnlyNumbers(true)
    self:addChild(self.textEntryY)

    self.labelY =
        ISLabel:new(
            self.textEntryY:getX(),
            y,
            FONT_HGT_SMALL + 4,
            "",
            1, 1, 1, 1,
            UIFont.Small,
            true)
    self.labelY:setTranslation(labelYName)
    self.labelY:setX(self.labelY:getX() - self.labelY:getWidth())
    self.labelY:initialise()
    self.labelY:instantiate()
    self:addChild(self.labelY)
    y = y + self.textEntryY:getHeight() + 10

    ------------------------------------
    -- Width
    self.textEntryWidth =
        MDB_TextEntryBox:new(
            "width",
            tostring(self.barPanel:getWidth()),
            self:getWidth() / 2 + 32,
            y,
            self.width - 20,
            FONT_HGT_SMALL + 4,
            self.barPanel)
    self.textEntryWidth:initialise()
    self.textEntryWidth:instantiate()
    self.textEntryWidth:setOnlyNumbers(true)
    self:addChild(self.textEntryWidth)

    self.labelWidth =
        ISLabel:new(
            self.textEntryWidth:getX(),
            y,
            FONT_HGT_SMALL + 4,
            "",
            1, 1, 1, 1,
            UIFont.Small,
            true)
    self.labelWidth:setTranslation(labelWidthName)
    self.labelWidth:setX(self.labelWidth:getX() - self.labelWidth:getWidth())
    self.labelWidth:initialise()
    self.labelWidth:instantiate()
    self:addChild(self.labelWidth)
    y = y + self.textEntryWidth:getHeight()

    ------------------------------------
    -- Height
    self.textEntryHeight =
        MDB_TextEntryBox:new(
            "height",
            tostring(self.barPanel:getHeight()),
            self:getWidth() / 2 + 32,
            y,
            self.width - 20,
            FONT_HGT_SMALL + 4,
            self.barPanel)
    self.textEntryHeight:initialise()
    self.textEntryHeight:instantiate()
    self.textEntryHeight:setOnlyNumbers(true)
    self:addChild(self.textEntryHeight)

    self.labelHeight =
        ISLabel:new(
            self.textEntryHeight:getX(),
            y,
            FONT_HGT_SMALL + 4,
            "",
            1, 1, 1, 1,
            UIFont.Small,
            true)
    self.labelHeight:setTranslation(labelHeightName)
    self.labelHeight:setX(self.labelHeight:getX() - self.labelHeight:getWidth())
    self.labelHeight:initialise()
    self.labelHeight:instantiate()
    self:addChild(self.labelHeight)
    y = y + self.textEntryHeight:getHeight() + 10

    ------------------------------------
    -- Image Size
    self.textEntryImageSize =
        MDB_TextEntryBox:new(
            "imageSize",
            tostring(self.barPanel.imageSize),
            self:getWidth() / 2 + 32,
            y,
            self.width - 20,
            FONT_HGT_SMALL + 4,
            self.barPanel)
    self.textEntryImageSize:initialise()
    self.textEntryImageSize:instantiate()
    self.textEntryImageSize:setOnlyNumbers(true)
    self:addChild(self.textEntryImageSize)

    self.labelImageSize =
        ISLabel:new(
            self.textEntryImageSize:getX(),
            y,
            FONT_HGT_SMALL + 4,
            "",
            1, 1, 1, 1,
            UIFont.Small,
            true)
    self.labelImageSize:setTranslation(labelImageSizeName)
    self.labelImageSize:setX(self.labelImageSize:getX() - self.labelImageSize:getWidth())
    self.labelImageSize:initialise()
    self.labelImageSize:instantiate()
    self:addChild(self.labelImageSize)
    y = y + self.textEntryHeight:getHeight() + 10

    ------------------------------------
    -- Is Vertical
    local changeOptionTarget = self.barPanel
    local changeOptionMethod = function(
            barPanel,
            mouseOverOption,
            selected,
            propertiesPanel,
            arg2)

        if barPanel then
            local playerNum = barPanel.coopNum
            local statId = barPanel.statId

            barPanel.isVertical = selected
            MDB_Config.updateIndicatorConfig(playerNum, statId, "isVertical", selected)

            local oldW = tonumber(barPanel.oldWidth)
            local oldH = tonumber(barPanel.oldHeight)
            barPanel:setWidth(oldH)
            barPanel:setHeight(oldW)

            -- Deferred save (replaces io_persistence.store)
            MDB_Config.markDirty(playerNum)

            -- Recreate MoveBarsTogether panel
            if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(barPanel.coopNum, MDB.indicators[barPanel.playerIndex]) end

            local width = barPanel:getWidth()
            local height = barPanel:getHeight()
            propertiesPanel.textEntryWidth:setText(tostring(width))
            propertiesPanel.textEntryHeight:setText(tostring(height))
        end

    end

    self.tickBoxIsVertical =
        ISTickBox:new(
            self:getWidth() / 2 + 32,
            y,
            200,
            FONT_HGT_SMALL + 4,
            labelSetVerticalName,
            changeOptionTarget,
            changeOptionMethod,
            self)
    self.tickBoxIsVertical:initialise()
    self.tickBoxIsVertical:instantiate()
    self.tickBoxIsVertical.selected[1] = self.barPanel.isVertical
    self.tickBoxIsVertical:addOption(labelSetVerticalName)
    self:addChild(self.tickBoxIsVertical)
    y = y + self.tickBoxIsVertical:getHeight() + 50

    ------------------------------------
    self:setHeight(y)
    ------------------------------------

    local x = 0

    self.cancelBtn =
        ISButton:new(
            padBottom + x,
            self:getHeight() - padBottom - btnHgt,
            btnWid,
            btnHgt,
            getText("UI_btn_cancel"),
            self,
            MDB_PropertiesPanel.onOptionMouseDown)
    self.cancelBtn.internal = "CANCEL"
    self.cancelBtn:initialise()
    self.cancelBtn:instantiate()
    self.cancelBtn.borderColor = self.buttonBorderColor
    self:addChild(self.cancelBtn)
    x = x + xSpacing + btnWid

    self.acceptBtn =
        ISButton:new(
            padBottom + x,
            self:getHeight() - padBottom - btnHgt,
            btnWid,
            btnHgt,
            getText("UI_btn_accept"),
            self,
            MDB_PropertiesPanel.onOptionMouseDown)
    self.acceptBtn.internal = "ACCEPT"
    self.acceptBtn:initialise()
    self.acceptBtn:instantiate()
    self.acceptBtn.borderColor = self.buttonBorderColor
    self:addChild(self.acceptBtn)
    x = x + xSpacing + btnWid

    local resetTextLen =
        getTextManager():MeasureStringX(
            UIFont.Small,
            getText("ContextMenu_MinimalDisplayBars_RestoreYourSettings"))
    self.resetBtn =
        ISButton:new(
            padBottom + x,
            self:getHeight() - padBottom - btnHgt,
            resetTextLen + 10,
            btnHgt,
            getText("ContextMenu_MinimalDisplayBars_RestoreYourSettings"),
            self,
            MDB_PropertiesPanel.onOptionMouseDown)
    self.resetBtn.internal = "RESET"
    self.resetBtn:initialise()
    self.resetBtn:instantiate()
    self.resetBtn.borderColor = self.buttonBorderColor
    self:addChild(self.resetBtn)

    self:setWidth(10 + x + self.resetBtn:getWidth() + 10)
    self:setHeight(y)

    -- Force center on screen
    local core = getCore()
    self:setX(core:getScreenWidth() / 2 - self:getWidth() / 2)
    self:setY(core:getScreenHeight() / 2 - self:getHeight() / 2)
end

-- ---------------------------------------------------------------------------
-- Update buttons (placeholder for future use)
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:updateButtons()

end

-- ---------------------------------------------------------------------------
-- Button handler
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:onOptionMouseDown(button, x, y)
    local playerNum = self.barPanel.coopNum
    local statId = self.barPanel.statId

    if button.internal == "ACCEPT" then
        if self.onApply then
            self.onApply()
        end

        -- Account for parent offset if the bar is parented to a group panel
        if self.barPanel.parent then
            if not self.parentOldX then
                self.parentOldX = self.barPanel.parent:getX()
                self.parentOldY = self.barPanel.parent:getY()
            end

            self.originalConfig[statId]["x"] =
                self.originalConfig[statId]["x"] + self.barPanel.parent:getX() - self.parentOldX
            self.originalConfig[statId]["y"] =
                self.originalConfig[statId]["y"] + self.barPanel.parent:getY() - self.parentOldY

            self.parentOldX = self.barPanel.parent:getX()
            self.parentOldY = self.barPanel.parent:getY()
        end

        -- Persist current dimensions and icon size via MDB_Config
        MDB_Config.updateIndicatorConfig(playerNum, statId, "width", self.barPanel:getWidth())
        MDB_Config.updateIndicatorConfig(playerNum, statId, "height", self.barPanel:getHeight())
        MDB_Config.updateIndicatorConfig(playerNum, statId, "imageSize", self.barPanel.imageSize)

        -- Deferred save (replaces io_persistence.store)
        MDB_Config.markDirty(playerNum)

        if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.barPanel.coopNum, MDB.indicators[self.barPanel.playerIndex]) end

        self:close()

    elseif button.internal == "RESET" then
        if self.onReset then
            self.onReset()
        end

        -- Account for parent offset before restoring original config
        if self.barPanel.parent then
            if not self.parentOldX then
                self.parentOldX = self.barPanel.parent:getX()
                self.parentOldY = self.barPanel.parent:getY()
            end

            self.originalConfig[statId]["x"] =
                self.originalConfig[statId]["x"] + self.barPanel.parent:getX() - self.parentOldX
            self.originalConfig[statId]["y"] =
                self.originalConfig[statId]["y"] + self.barPanel.parent:getY() - self.parentOldY

            self.parentOldX = self.barPanel.parent:getX()
            self.parentOldY = self.barPanel.parent:getY()
        end

        -- Restore all indicators from the snapshot taken when the panel opened
        local rawCache = MDB_Config.getRawCache(playerNum)
        if rawCache then
            rawCache.indicators = deepCopy(self.originalConfig)
        end

        self.barPanel:resetToConfigTable()

        -- Refresh text entries to match restored values
        self.textEntryX:setText(tostring(self.barPanel:getX()))
        self.textEntryY:setText(tostring(self.barPanel:getY()))
        self.textEntryHeight:setText(tostring(self.barPanel:getHeight()))
        self.textEntryWidth:setText(tostring(self.barPanel:getWidth()))
        self.textEntryImageSize:setText(tostring(self.barPanel.imageSize))
        self.tickBoxIsVertical.selected[1] = self.barPanel.isVertical

        -- Deferred save (replaces io_persistence.store)
        MDB_Config.markDirty(playerNum)

        if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.barPanel.coopNum, MDB.indicators[self.barPanel.playerIndex]) end

    elseif button.internal == "CANCEL" then
        if self.onCancel then
            self.onCancel()
        end

        -- Restore all indicators from the snapshot taken when the panel opened
        local rawCache = MDB_Config.getRawCache(playerNum)
        if rawCache then
            rawCache.indicators = deepCopy(self.originalConfig)
        end

        self.barPanel:resetToConfigTable()

        -- Deferred save (replaces io_persistence.store)
        MDB_Config.markDirty(playerNum)

        if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.barPanel.coopNum, MDB.indicators[self.barPanel.playerIndex]) end

        self:close()
    end
end

-- ---------------------------------------------------------------------------
-- Original config snapshot accessor
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:getOriginalConfig()
    return deepCopy(self.originalConfig)
end

-- ---------------------------------------------------------------------------
-- Close
-- ---------------------------------------------------------------------------

function MDB_PropertiesPanel:close()
    self:setVisible(false)

    -- Clear the editing flag so other interactions are re-enabled.
    MDB_IndicatorBase.isEditing = false

    self:removeFromUIManager()
end

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- @param x         number   Initial x position (will be overridden by center logic)
--- @param y         number   Initial y position (will be overridden by center logic)
--- @param barPanel  table    The indicator bar being edited. Must have .statId and .coopNum.
function MDB_PropertiesPanel:new(x, y, barPanel)
    local o = {}
    local width, height = 200, 200

    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.variableColor = { r = 0.9, g = 0.55, b = 0.1, a = 1 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    o.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    o.zOffsetSmallFont = 25
    o.moveWithMouse = true
    MDB_PropertiesPanel.instance = o

    -- Snapshot the full indicators table so we can cancel / reset changes.
    -- We deep-copy only the indicators sub-table (that is all this panel
    -- ever restores).
    local rawCache = MDB_Config.getRawCache(barPanel.coopNum)
    if rawCache and rawCache.indicators then
        o.originalConfig = deepCopy(rawCache.indicators)
    else
        o.originalConfig = {}
    end

    o.barPanel = barPanel

    if o.barPanel.parent then
        o.parentOldX = o.barPanel.parent:getX()
        o.parentOldY = o.barPanel.parent:getY()
    end

    -- Lock out other interactions while the properties panel is open
    MDB_IndicatorBase.isEditing = true

    return o
end
