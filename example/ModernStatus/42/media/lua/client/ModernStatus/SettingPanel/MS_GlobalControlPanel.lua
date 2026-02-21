require "ISUI/ISPanel"
require "ISUI/ISContextMenu"

MS_GlobalControlPanel = ISPanel:derive("MS_GlobalControlPanel")

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function MS_GlobalControlPanel:initialise()
    ISPanel.initialise(self)
end

function MS_GlobalControlPanel:new(x, y, width, height, playerObj, playerIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.playerObj = playerObj
    o.playerIndex = playerIndex
    o.moveWithMouse = true
    o.locked = false
    o.moving = false

    o.controlTexture = getTexture("media/ui/ModernStatus/SettingPanel/SettingPanel_global.png")
    
    return o
end

-- ---------------------------------------------------------------------------------------- --
-- Context Menu
-- ---------------------------------------------------------------------------------------- --
function MS_GlobalControlPanel:onRightMouseDown(x, y)
    local context = ISContextMenu.get(self.playerIndex, getMouseX(), getMouseY())
    context:addOption(getText("IGUI_ModernStatus_OpenAllSettings"), self, MS_GlobalControlPanel.openAllSettings)
    
    local showHideText = getText("IGUI_ModernStatus_Show") .. "/" .. getText("IGUI_ModernStatus_Hide")
    local showHideOption = context:addOption(showHideText, nil)
    local showHideSubMenu = context:getNew(context)
    context:addSubMenu(showHideOption, showHideSubMenu)
    showHideSubMenu:addOption(getText("IGUI_ModernStatus_ShowAll"), self, MS_GlobalControlPanel.showAllIndicators)
    showHideSubMenu:addOption(getText("IGUI_ModernStatus_HideAll"), self, MS_GlobalControlPanel.hideAllIndicators)
    
    -- lock/Unlock
    local lockUnlockText = getText("IGUI_ModernStatus_Lock") .. "/" .. getText("IGUI_ModernStatus_Unlock")
    local lockUnlockOption = context:addOption(lockUnlockText, nil)
    local lockUnlockSubMenu = context:getNew(context)
    context:addSubMenu(lockUnlockOption, lockUnlockSubMenu)
    lockUnlockSubMenu:addOption(getText("IGUI_ModernStatus_LockAll"), self, MS_GlobalControlPanel.lockAllIndicators)
    lockUnlockSubMenu:addOption(getText("IGUI_ModernStatus_UnlockAll"), self, MS_GlobalControlPanel.unlockAllIndicators)
    
    -- multiDrag
    local config = MSConfig.getGlobalConfig(self.playerIndex)
    local multiDragText = getText("IGUI_ModernStatus_MultiDrag")
    if config.multiDragMode then
        multiDragText = multiDragText .. getText("IGUI_ModernStatus_on")
    else
        multiDragText = multiDragText .. getText("IGUI_ModernStatus_off")
    end
    context:addOption(multiDragText, self, MS_GlobalControlPanel.toggleMultiDragMode)
    
    -- hide/show Moodle
    local hideOriginalMoodlesText = getText("IGUI_ModernStatus_HideMoodles")
    if config.hideOriginalMoodles then
        hideOriginalMoodlesText = hideOriginalMoodlesText .. getText("IGUI_ModernStatus_on")
    else
        hideOriginalMoodlesText = hideOriginalMoodlesText .. getText("IGUI_ModernStatus_off")
    end
    context:addOption(hideOriginalMoodlesText, self, MS_GlobalControlPanel.toggleHideOriginalMoodles)
    return true
end

-- ---------------------------------------------------------------------------------------- --
-- Gobal Control
-- ---------------------------------------------------------------------------------------- --
function MS_GlobalControlPanel:openAllSettings()
    if not MS_AllIndicatorsPanel then
        require "MS_AllIndicatorsPanel"
    end
    
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local panel = MS_AllIndicatorsPanel:new(100, 100, nil, nil, self.playerIndex)
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)

    local x = (screenWidth - panel:getWidth()) / 2
    local y = (screenHeight - panel:getHeight()) / 2
    panel:setX(x)
    panel:setY(y)
end

function MS_GlobalControlPanel:showAllIndicators()
    local indicators = StatusWidget.indicators[self.playerIndex]
    if not indicators then return end
    
    for _, indicator in pairs(indicators) do
        indicator.hidden = false
        indicator:setVisible(true)
        
        MSConfig.updateIndicatorConfig(
            indicator.playerIndex,
            indicator:getType(),
            "hidden",
            false
        )
    end
end

function MS_GlobalControlPanel:hideAllIndicators()
    local indicators = StatusWidget.indicators[self.playerIndex]
    if not indicators then return end
    
    for _, indicator in pairs(indicators) do
        indicator.hidden = true
        indicator:setVisible(false)
        
        MSConfig.updateIndicatorConfig(
            indicator.playerIndex,
            indicator:getType(),
            "hidden",
            true
        )
    end
end

function MS_GlobalControlPanel:lockAllIndicators()
    local indicators = StatusWidget.indicators[self.playerIndex]
    if not indicators then return end
    
    for _, indicator in pairs(indicators) do
        indicator.locked = true
        indicator.moveWithMouse = false
        
        MSConfig.updateIndicatorConfig(
            indicator.playerIndex,
            indicator:getType(),
            "locked",
            true
        )
    end
end

function MS_GlobalControlPanel:unlockAllIndicators()
    local indicators = StatusWidget.indicators[self.playerIndex]
    if not indicators then return end
    
    for _, indicator in pairs(indicators) do
        indicator.locked = false
        indicator.moveWithMouse = true
        
        MSConfig.updateIndicatorConfig(
            indicator.playerIndex,
            indicator:getType(),
            "locked",
            false
        )
    end
end

function MS_GlobalControlPanel:toggleMultiDragMode()
    local config = MSConfig.getGlobalConfig(self.playerIndex)
    local newMode = not config.multiDragMode
    
    MSConfig.updateGlobalConfig(
        self.playerIndex,
        "multiDragMode",
        newMode
    )
end

function MS_GlobalControlPanel:toggleHideOriginalMoodles()
    local config = MSConfig.getGlobalConfig(self.playerIndex)
    local newValue = not config.hideOriginalMoodles
    
    MSConfig.updateGlobalConfig(
        self.playerIndex,
        "hideOriginalMoodles",
        newValue
    )
    
    self:applyHideOriginalMoodles(newValue)
end

function MS_GlobalControlPanel:applyHideOriginalMoodles(shouldHide)
    local moodlesUI = MoodlesUI.getInstance()
    if moodlesUI then
        if shouldHide then
            if not self.originalMoodlesWidth then
                self.originalMoodlesWidth = moodlesUI:getWidth()
            end
            moodlesUI:setWidth(-1000)
        else
            moodlesUI:setWidth(self.originalMoodlesWidth)
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------------------------------------- --
function MS_GlobalControlPanel:onMouseDown(x, y)
    if self.locked then return false end
    
    self.dragStartX = x
    self.dragStartY = y
    self.moving = true
    self:setCapture(true)
    return true
end

function MS_GlobalControlPanel:onMouseUp(x, y)
    if self.moving then
        self.moving = false
        self:setCapture(false)
        
        MSConfig.updateGlobalConfig(
            self.playerIndex,
            "controlPosition",
            {x = self:getX(), y = self:getY()}
        )
    end
    return true
end

function MS_GlobalControlPanel:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
    return true
end

function MS_GlobalControlPanel:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
    return true
end

function MS_GlobalControlPanel:prerender()
    self:drawTextureScaled(self.controlTexture, 0, 0, self.width, self.height, 1, 1, 1, 1)
end