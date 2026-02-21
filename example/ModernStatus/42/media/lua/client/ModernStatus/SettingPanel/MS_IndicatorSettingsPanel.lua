require "ISUI/ISPanel"
require "ISUI/ISButton"


MS_IndicatorSettingsPanel = ISPanel:derive("MS_IndicatorSettingsPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

MS_IndicatorSettingsPanel.IndicatorNames = {
    ["MS_ThirstIndicator"] = "IGUI_ModernStatus_Thirst",
    ["MS_HungerIndicator"] = "IGUI_ModernStatus_Hunger",
    ["MS_EnduranceIndicator"] = "IGUI_ModernStatus_Endurance",
    ["MS_FatigueIndicator"] = "IGUI_ModernStatus_Fatigue",
    ["MS_StressIndicator"] = "IGUI_ModernStatus_Stress",
    ["MS_PanicIndicator"] = "IGUI_ModernStatus_Panic",
    ["MS_TemperatureIndicator"] = "IGUI_ModernStatus_Temperature",
    ["MS_HealthIndicator"] = "IGUI_ModernStatus_Health",
    ["MS_BoredomIndicator"] = "IGUI_ModernStatus_Boredom",
    ["MS_UnhappynessIndicator"] = "IGUI_ModernStatus_Unhappyness",
    ["MS_DiscomfortIndicator"] = "IGUI_ModernStatus_Discomfort",
    ["MS_SicknessIndicator"] = "IGUI_ModernStatus_Sickness",
    ["MS_PainIndicator"] = "IGUI_ModernStatus_Pain",
    ["MS_CarryWeightIndicator"] = "IGUI_ModernStatus_CarryWeight",
    ["MS_CalorieIndicator"] = "IGUI_ModernStatus_Calorie",
    ["MS_ProteinsIndicator"] = "IGUI_ModernStatus_Proteins",
    ["MS_CarbohydratesIndicator"] = "IGUI_ModernStatus_Carbohydrates",
    ["MS_LipidsIndicator"] = "IGUI_ModernStatus_Lipids",
    ["MS_WeightIndicator"] = "IGUI_ModernStatus_Weight",
    ["MS_MedicineIndicator"] = "IGUI_ModernStatus_Medicine",
    ["MS_AngerIndicator"] = "IGUI_ModernStatus_Anger",
    ["MS_DirtinessIndicator"] = "IGUI_ModernStatus_Dirtiness",
    ["MS_WetnessIndicator"] = "IGUI_ModernStatus_Wetness",
    ["MS_DrunkennessIndicator"] = "IGUI_ModernStatus_Drunkenness",
    ["MS_StiffnessIndicator"] = "IGUI_ModernStatus_Stiffness",

}

function MS_IndicatorSettingsPanel.calculateRequiredSize()
    local textManager = getTextManager()
    local widthText = getText("IGUI_SetSettingPanelWide")
    local baseWidth = textManager:MeasureStringX(UIFont.Small, widthText) * 2
    
    local minWidth = 300
    local maxWidth = 500
    local panelW = math.max(minWidth, math.min(baseWidth, maxWidth))

    local rowheight = math.floor(FONT_HGT_SMALL*1.5)
    local numBarStyleItems = 15

    local titleBarHeight = math.floor(FONT_HGT_SMALL*1.2)
    local buttonHeight = math.floor(FONT_HGT_SMALL*1.5)
    local padding = math.floor(FONT_HGT_SMALL*0.2)

    local contentHeight = numBarStyleItems * rowheight

    local panelH = titleBarHeight + padding + buttonHeight + padding + contentHeight + padding + buttonHeight + padding
    
    local minHeight = 380
    panelH = math.max(minHeight, panelH)
    
    return {width = panelW, height = panelH}
end

function MS_IndicatorSettingsPanel:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:initialise()
    ISPanel.initialise(self)
end

function MS_IndicatorSettingsPanel:new(x, y, width, height, indicator)
    if not width or not height then
        local size = MS_IndicatorSettingsPanel.calculateRequiredSize()
        width = size.width
        height = size.height
    end
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.indicator = indicator
    o.padding = math.floor(FONT_HGT_SMALL*0.2)
    o.moveWithMouse = false
    o.activeTab = self.TAB_CIRCULAR
    o.titleBarHeight = math.floor(FONT_HGT_SMALL*1.2)
    o.buttonHeight = math.floor(FONT_HGT_SMALL*1.5)
    o.moving = false

    o.TAB_CIRCULAR = 1
    o.TAB_Bar = 2

    o.titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/TitleBarBG.png")
    o.contentbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/ContentBackground.png")
    
    return o
end

-- ---------------------------------------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:createChildren()
    self:createTitleBar()
    
    local y = self.titleBarHeight + self.padding
    
    self:createTabs(y)
    
    self:createBottomButtons()
    
    if self.indicator then
        if self.indicator.isBarStyle then
            self:switchToTab(self.TAB_Bar)
        else
            self:switchToTab(self.TAB_CIRCULAR)
        end
    else
        self:switchToTab(self.TAB_CIRCULAR)
    end
end

function MS_IndicatorSettingsPanel:createTitleBar()
    -- titleLabel
    self.titleLabel = ISLabel:new(self.padding, (self.titleBarHeight - FONT_HGT_SMALL) / 2, self.titleBarHeight, "", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabel:initialise()
    self.titleLabel.render = function()
        local indicatorType = self.indicator:getType()
        local titleKey = MS_IndicatorSettingsPanel.IndicatorNames[indicatorType]

        if titleKey then
            self.titleLabel:setName(getText(titleKey))
        end
    end
    self:addChild(self.titleLabel)
    
    -- closeButton
    local closeSize = FONT_HGT_SMALL
    self.closeButton = MS_SquareButton:new(self:getWidth() - closeSize - self.padding, (self.titleBarHeight - FONT_HGT_SMALL) / 2, closeSize, getTexture("media/ui/ModernStatus/SettingPanel/Icon_Close.png"), self, MS_IndicatorSettingsPanel.close)
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self:addChild(self.closeButton)
end

function MS_IndicatorSettingsPanel:createTabs(y)
    local tabWidth = math.floor(self:getWidth() - self.padding*3)/2
    -- circularTabBtn
    self.circularTabBtn = MS_LongButton:new(self.padding, y, tabWidth, self.buttonHeight, getText("IGUI_ModernStatus_Circular"), self, MS_IndicatorSettingsPanel.onCircularTabClick)
    self.circularTabBtn:initialise()
    self.circularTabBtn.tabID = self.TAB_CIRCULAR
    self:addChild(self.circularTabBtn)
    
    -- BarTabBtn
    self.BarTabBtn = MS_LongButton:new(tabWidth + self.padding*2, y, tabWidth, self.buttonHeight, getText("IGUI_ModernStatus_Bar"), self, MS_IndicatorSettingsPanel.onBarTabClick)
    self.BarTabBtn:initialise()
    self.BarTabBtn.tabID = self.TAB_Bar
    self:addChild(self.BarTabBtn)
    
    self.tabButtons = {
        self.circularTabBtn,
        self.BarTabBtn
    }
end

function MS_IndicatorSettingsPanel:createBottomButtons()
    if not self.indicator then return end

    local buttonWidth = math.floor(self:getWidth()- self.padding*3) / 2
    local buttonY = self:getHeight() - self.buttonHeight - self.padding
    
    -- hide/show Button
    self.hideButton = MS_LongButton:new(5, buttonY, buttonWidth, self.buttonHeight, getText("IGUI_ModernStatus_Hide"), self, MS_IndicatorSettingsPanel.onHideButtonClick)
    self.hideButton:initialise()
    self:addChild(self.hideButton)
    
    -- lock/unlock Button
    self.lockButton = MS_LongButton:new(self:getWidth() - buttonWidth - 5, buttonY, buttonWidth, self.buttonHeight, "", self, MS_IndicatorSettingsPanel.onLockButtonClick)
    self.lockButton:initialise()
    self.lockButton.prerender = function()
        local text = self.indicator.locked and getText("IGUI_ModernStatus_Lock") or getText("IGUI_ModernStatus_Unlock")
        self.lockButton:setTitle(text)
        self.lockButton:setActive(self.indicator.locked)
    end
    self:addChild(self.lockButton)
end

-- ---------------------------------------------------------------------------------------- --
-- switch Tab
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:switchToTab(tabID)
    if not tabID then return end
    
    self.activeTab = tabID
    
    if self.tabButtons then
        for i, button in ipairs(self.tabButtons) do
            button:setActive(button.tabID == tabID)
        end
    end
    
    self:refreshTabContent(tabID)
end

function MS_IndicatorSettingsPanel:refreshTabContent(tabID)
    if self.contentPanel then
        self:removeChild(self.contentPanel)
        self.contentPanel:removeFromUIManager()
    end
    
    local y = self.titleBarHeight + self.padding + self.buttonHeight + self.padding
    local contentHeight = self:getHeight() - y - self.buttonHeight - self.padding * 2
    
    self.contentPanel = ISPanel:new(0, y, self:getWidth(), contentHeight)
    self.contentPanel.background = false
    self.contentPanel:initialise()
    self:addChild(self.contentPanel)
    
    if tabID == self.TAB_CIRCULAR then
        if self.indicator then
            local stylePanel = MS_CircularStylePanel:new(
                0, 0, 
                self.contentPanel:getWidth(), 
                self.contentPanel:getHeight(),
                self.indicator
            )
            stylePanel:initialise()
            stylePanel:instantiate()
            self.contentPanel:addChild(stylePanel)
            self.currentStylePanel = stylePanel
        end
    elseif tabID == self.TAB_Bar then
        if self.indicator then
            local stylePanel = MS_BarStylePanel:new(
                0, 0, 
                self.contentPanel:getWidth(), 
                self.contentPanel:getHeight(),
                self.indicator
            )
            stylePanel:initialise()
            stylePanel:instantiate()
            self.contentPanel:addChild(stylePanel)
            self.currentStylePanel = stylePanel
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Button Function
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:onCircularTabClick()
    if not self.indicator then return end
    
    self.indicator:switchStyle(false)
    self:switchToTab(self.TAB_CIRCULAR)
end

function MS_IndicatorSettingsPanel:onBarTabClick()
    if not self.indicator then return end
    
    self.indicator:switchStyle(true)
    self:switchToTab(self.TAB_Bar)
end

function MS_IndicatorSettingsPanel:onHideButtonClick()
    if not self.indicator then return end
    
    self.indicator.hidden = not self.indicator.hidden
    
    self.indicator:setVisible(not self.indicator.hidden)
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "hidden",
        self.indicator.hidden
    )
    
    self:close()
end

function MS_IndicatorSettingsPanel:onLockButtonClick()
    if not self.indicator then return end
    
    self.indicator.locked = not self.indicator.locked
    
    self.indicator.moveWithMouse = not self.indicator.locked
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "locked",
        self.indicator.locked
    )
end

-- ---------------------------------------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:onMouseDown(x, y)
    if y <= self.titleBarHeight then
        self.moving = true
        self:setCapture(true)
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function MS_IndicatorSettingsPanel:onMouseUp(x, y)
    if self.moving then
        self.moving = false
        self:setCapture(false)
    end
    return ISPanel.onMouseUp(self, x, y)
end

function MS_IndicatorSettingsPanel:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
    return ISPanel.onMouseMove(self, dx, dy)
end

function MS_IndicatorSettingsPanel:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function MS_IndicatorSettingsPanel:onMouseUpOutside(x, y)
    self.moving = false
    self:setCapture(false)
    return ISPanel.onMouseUpOutside(self, x, y)
end

-- ---------------------------------------------------------------------------------------- --
-- render
-- ---------------------------------------------------------------------------------------- --
function MS_IndicatorSettingsPanel:prerender()
    local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/TitleBarBG.png")
    titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), self.titleBarHeight, 0.5, 0.5, 0.5, 0.95)
    
    local contentbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/ContentBackground.png")
    contentbkg:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleBarHeight, self:getWidth(), self:getHeight() - self.titleBarHeight, 0.1, 0.1, 0.1, 0.8)
end