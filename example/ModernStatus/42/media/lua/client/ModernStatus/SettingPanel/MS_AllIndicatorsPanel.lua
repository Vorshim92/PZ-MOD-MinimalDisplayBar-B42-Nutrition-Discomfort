require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"

MS_AllIndicatorsPanel = ISPanel:derive("MS_AllIndicatorsPanel")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ---------------------------------------------------------------------------------------- --
-- calculate Required Height
-- ---------------------------------------------------------------------------------------- --
function MS_AllIndicatorsPanel.calculateNameColumnWidth()
    local widthText = getText("IGUI_SetSettingPanelWide")
    return getTextManager():MeasureStringX(UIFont.Small, widthText) * 1.5
end

function MS_AllIndicatorsPanel.calculateStyleButtonWidth(padding, buttonHeight)
    local buttonspacing = padding * 2
    local barText = getText("IGUI_ModernStatus_Bar")
    local circularText = getText("IGUI_ModernStatus_Circular")
    local barTextWidth = getTextManager():MeasureStringX(UIFont.Small, barText)
    local circularTextWidth = getTextManager():MeasureStringX(UIFont.Small, circularText)
    return math.max(math.max(barTextWidth, circularTextWidth) + buttonspacing*2, buttonHeight*2)
end

function MS_AllIndicatorsPanel.calculateVisibilityButtonWidth(padding, buttonHeight)
    local buttonspacing = padding * 2
    local showText = getText("IGUI_ModernStatus_Show")
    local hideText = getText("IGUI_ModernStatus_Hide")
    local showTextWidth = getTextManager():MeasureStringX(UIFont.Small, showText)
    local hideTextWidth = getTextManager():MeasureStringX(UIFont.Small, hideText)
    return math.max(math.max(showTextWidth, hideTextWidth) + buttonspacing*2, buttonHeight*2)
end

function MS_AllIndicatorsPanel.calculateLockButtonWidth(padding, buttonHeight)
    local buttonspacing = padding * 2
    local lockText = getText("IGUI_ModernStatus_Lock")
    local unlockText = getText("IGUI_ModernStatus_Unlock")
    local lockTextWidth = getTextManager():MeasureStringX(UIFont.Small, lockText)
    local unlockTextWidth = getTextManager():MeasureStringX(UIFont.Small, unlockText)
    return math.max(math.max(lockTextWidth, unlockTextWidth) + buttonspacing*2, buttonHeight*2)
end

function MS_AllIndicatorsPanel.calculateResetButtonWidth(padding, buttonHeight)
    local buttonspacing = padding * 2
    local resetText = getText("IGUI_ModernStatus_ResetColor")
    local resetTextWidth = getTextManager():MeasureStringX(UIFont.Small, resetText)
    return math.max(resetTextWidth + buttonspacing*2, buttonHeight*2)
end

function MS_AllIndicatorsPanel.calculateRowHeight(buttonHeight)
    return math.floor(buttonHeight * 1.2)
end


function MS_AllIndicatorsPanel.calculateRequiredHeight(playerIndex)
    local indicators = StatusWidget.indicators[playerIndex]
    if not indicators then return 600 end

    local indicatorCount = 0
    for _ in pairs(indicators) do
        indicatorCount = indicatorCount + 1
    end

    local titleBarHeight = math.floor(FONT_HGT_SMALL*1.2)
    local tempPadding = math.floor(FONT_HGT_SMALL * 0.2)
    local tempButtonHeight = math.floor(FONT_HGT_SMALL*1.2)
    local rowHeight = MS_AllIndicatorsPanel.calculateRowHeight(tempButtonHeight)
    
    local contentStartY = titleBarHeight + tempPadding
    local totalHeight = contentStartY + (rowHeight * indicatorCount) + tempPadding

    local minHeight = 400
    return math.max(minHeight, totalHeight)
end

function MS_AllIndicatorsPanel.calculateRequiredWidth()
    local tempPadding = math.floor(FONT_HGT_SMALL * 0.2)
    local tempButtonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    local nameColumnWidth = MS_AllIndicatorsPanel.calculateNameColumnWidth()
    local styleButtonWidth = MS_AllIndicatorsPanel.calculateStyleButtonWidth(tempPadding, tempButtonHeight)
    local visibilityButtonWidth = MS_AllIndicatorsPanel.calculateVisibilityButtonWidth(tempPadding, tempButtonHeight)
    local lockButtonWidth = MS_AllIndicatorsPanel.calculateLockButtonWidth(tempPadding, tempButtonHeight)
    local resetButtonWidth = MS_AllIndicatorsPanel.calculateResetButtonWidth(tempPadding, tempButtonHeight)

    local buttonsWidth = styleButtonWidth + visibilityButtonWidth + lockButtonWidth + resetButtonWidth + tempPadding * 3
    local totalWidth = nameColumnWidth + tempPadding + tempPadding + buttonsWidth + tempPadding

    local minWidth = 600
    return math.max(minWidth, totalWidth)
end

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function MS_AllIndicatorsPanel:initialise()
    ISPanel.initialise(self)

    local iconTextures = {}
    local indicators = StatusWidget.indicators[self.playerIndex]
    if indicators then
        for _, indicator in pairs(indicators) do
            if indicator.baseIconName then
                iconTextures[indicator.baseIconName] = true
            end
        end
    end

    for iconName in pairs(iconTextures) do
        local path = "media/ui/ModernStatus/ColorIcon/" .. iconName .. ".png"
        local texture = getTexture(path)
        if texture then
            self.iconTextures[iconName] = texture
        end
    end
end

function MS_AllIndicatorsPanel:new(x, y, width, height, playerIndex)
    if not height then
        height = MS_AllIndicatorsPanel.calculateRequiredHeight(playerIndex)
    end
    if not width then
        width = MS_AllIndicatorsPanel.calculateRequiredWidth()
    else
        local requiredWidth = MS_AllIndicatorsPanel.calculateRequiredWidth()
        if width < requiredWidth then
            width = requiredWidth
        end
    end
    
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.titleBarHeight = math.floor(FONT_HGT_SMALL*1.2)
    o.buttonHeight = math.floor(FONT_HGT_SMALL*1.2)
    o.moveWithMouse = false
    o.moving = false
    o.iconTextures = {}

    o.titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/TitleBarBG.png")
    o.contentBackground = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/ContentBackground.png")
    
    return o
end

-- ---------------------------------------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------------------------------------- --
function MS_AllIndicatorsPanel:createChildren()
    self:createTitleBar()
    self:createIndicatorList()
end

function MS_AllIndicatorsPanel:createTitleBar()
    self.titleLabel = ISLabel:new(self.padding, (self.titleBarHeight - FONT_HGT_SMALL) / 2, self.titleBarHeight, getText("ContextMenu_StoveSetting"), 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    local closeSize = FONT_HGT_SMALL
    self.closeButton = MS_SquareButton:new(self.width - closeSize - self.padding, (self.titleBarHeight - FONT_HGT_SMALL) / 2, closeSize, getTexture("media/ui/ModernStatus/SettingPanel/Icon_Close.png"), self, MS_AllIndicatorsPanel.close)
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self.closeButton:initialise()

    self:addChild(self.closeButton)
end

function MS_AllIndicatorsPanel:createIndicatorList()
    local contentY = self.titleBarHeight + self.padding
    
    local nameColumnWidth = self.calculateNameColumnWidth()
    local splitPosition = nameColumnWidth + self.padding
    
    local styleButtonWidth = self.calculateStyleButtonWidth(self.padding, self.buttonHeight)
    local visibilityButtonWidth = self.calculateVisibilityButtonWidth(self.padding, self.buttonHeight)
    local lockButtonWidth = self.calculateLockButtonWidth(self.padding, self.buttonHeight)
    local resetButtonWidth = self.calculateResetButtonWidth(self.padding, self.buttonHeight)
    local rowHeight = self.calculateRowHeight(self.buttonHeight)

    local startY = contentY
    local indicators = StatusWidget.indicators[self.playerIndex]
    if not indicators then return end
    
    local sortedIndicators = {}
    for name, indicator in pairs(indicators) do
        table.insert(sortedIndicators, {name = name, indicator = indicator})
    end
    
    table.sort(sortedIndicators, function(a, b)
        local nameA = MS_IndicatorSettingsPanel.IndicatorNames[a.indicator:getType()] or a.name
        local nameB = MS_IndicatorSettingsPanel.IndicatorNames[b.indicator:getType()] or b.name
        return getText(nameA) < getText(nameB)
    end)
    
    for i, item in ipairs(sortedIndicators) do
        local indicator = item.indicator
        local rowY = startY + (i-1) * rowHeight

        local indicatorType = indicator:getType()
        local titleKey = MS_IndicatorSettingsPanel.IndicatorNames[indicatorType]
        local titleText = titleKey and getText(titleKey) or indicatorType

        local iconTexture = nil
        if indicator.iconTexture then
            iconTexture = indicator.iconTexture
        end

        local iconSize = rowHeight * 1.2
        local iconX = self.padding

        -- nameButton
        local nameButton = ISButton:new(iconX, rowY, nameColumnWidth, rowHeight, "", self, MS_AllIndicatorsPanel.onNameButtonClick)
        nameButton:initialise()
        nameButton.displayBackground = false
        nameButton.indicator = indicator
        nameButton.indicatorTitle = titleText
        nameButton.prerender = function(button)
            if button:isMouseOver() then
                button:drawRect(0, 0, button:getWidth(), button:getHeight(), 0.3, 0.5, 0.5, 0.5)
            end
            button:drawTextureScaled(iconTexture, 0, (rowHeight - iconSize) / 2, iconSize, iconSize, 1, 1, 1, 1)
            local textX = iconSize + self.padding
            local textY = (rowHeight - FONT_HGT_SMALL) / 2
            button:drawText(button.indicatorTitle, textX, textY, 1, 1, 1, 1, UIFont.Small)
        end
        self:addChild(nameButton)
        
        -- styleButton
        local buttonY = rowY + (rowHeight - self.buttonHeight) / 2
        local buttonX = splitPosition + self.padding
        
        local styleButton = MS_LongButton:new(buttonX, buttonY, styleButtonWidth, self.buttonHeight, getText("IGUI_ModernStatus_Bar"), self, MS_AllIndicatorsPanel.onToggleStyle)
        styleButton.indicator = indicator
        styleButton:initialise()
        styleButton.prerender = function(button)
            local text = button.indicator.isBarStyle and getText("IGUI_ModernStatus_Bar") or getText("IGUI_ModernStatus_Circular")
            styleButton:setTitle(text)
            styleButton:setActive(not button.indicator.isBarStyle)
        end
        self:addChild(styleButton)
        indicator.styleButton = styleButton
        
        -- visibilityButton
        local visibilityButton = MS_LongButton:new(buttonX + styleButtonWidth + self.padding, buttonY, visibilityButtonWidth, self.buttonHeight, getText("IGUI_ModernStatus_Show"), self, MS_AllIndicatorsPanel.onToggleVisibility)
        visibilityButton.indicator = indicator
        visibilityButton:initialise()
        visibilityButton.prerender = function(button)
            local text = button.indicator.hidden and getText("IGUI_ModernStatus_Hide") or getText("IGUI_ModernStatus_Show")
            visibilityButton:setTitle(text)
            visibilityButton:setActive(not button.indicator.hidden)
        end
        self:addChild(visibilityButton)
        indicator.visibilityButton = visibilityButton
        
        -- lockButton
        local lockButtonX = buttonX + styleButtonWidth + self.padding + visibilityButtonWidth + self.padding
        local lockButton = MS_LongButton:new(lockButtonX, buttonY, lockButtonWidth, self.buttonHeight, getText("IGUI_ModernStatus_Unlock"), self, MS_AllIndicatorsPanel.onToggleLock)
        lockButton.indicator = indicator
        lockButton:initialise()
        lockButton.prerender = function(button)
            local text = button.indicator.locked and getText("IGUI_ModernStatus_Lock") or getText("IGUI_ModernStatus_Unlock")
            lockButton:setTitle(text)
            lockButton:setActive(button.indicator.locked)
        end
        self:addChild(lockButton)
        indicator.lockButton = lockButton
        
        -- resetButton
        local resetButtonX = lockButtonX + lockButtonWidth + self.padding
        local resetButton = MS_LongButton:new(resetButtonX, buttonY, resetButtonWidth, self.buttonHeight, getText("IGUI_ModernStatus_ResetColor"), self, MS_AllIndicatorsPanel.onResetIndicator)
        resetButton.indicator = indicator
        resetButton:initialise()
        resetButton.prerender = function(button)
        end
        self:addChild(resetButton)
        indicator.resetButton = resetButton
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Button Callback
-- ---------------------------------------------------------------------------------------- --

function MS_AllIndicatorsPanel:onNameButtonClick(button)
    local indicator = button.indicator
    if not indicator then return end

    local panel = MS_IndicatorSettingsPanel:new(0, 0, nil, nil, indicator)
    panel:initialise()
    panel:addToUIManager()

    local panelX = self:getAbsoluteX() - panel:getWidth() - 10
    local panelY = self:getAbsoluteY() + (self:getHeight() - panel:getHeight()) / 2

    if panelX < 0 then
        panelX = self:getAbsoluteX() + self:getWidth() + 10
    end
    
    if panelY < 0 then
        panelY = 10
    end
    
    if panelY + panel:getHeight() > getCore():getScreenHeight() then
        panelY = getCore():getScreenHeight() - panel:getHeight() - 10
    end
    
    panel:setX(panelX)
    panel:setY(panelY)
    panel:setVisible(true)
    
    if indicator.isBarStyle then
        panel:switchToTab(MS_IndicatorSettingsPanel.TAB_Bar)
    else
        panel:switchToTab(MS_IndicatorSettingsPanel.TAB_CIRCULAR)
    end
end

function MS_AllIndicatorsPanel:onToggleStyle(button)
    local indicator = button.indicator
    if not indicator then return end
    indicator:switchStyle(not indicator.isBarStyle)
end

function MS_AllIndicatorsPanel:onToggleVisibility(button)
    local indicator = button.indicator
    if not indicator then return end

    indicator.hidden = not indicator.hidden
    indicator:setVisible(not indicator.hidden)

    MSConfig.updateIndicatorConfig(
        indicator.playerIndex,
        indicator:getType(),
        "hidden",
        indicator.hidden
    )
end

function MS_AllIndicatorsPanel:onToggleLock(button)
    local indicator = button.indicator
    if not indicator then return end

    indicator.locked = not indicator.locked
    indicator.moveWithMouse = not indicator.locked

    MSConfig.updateIndicatorConfig(
        indicator.playerIndex,
        indicator:getType(),
        "locked",
        indicator.locked
    )
end

function MS_AllIndicatorsPanel:onResetIndicator(button)
    local indicator = button.indicator
    if not indicator then return end

    local indicatorType = indicator:getType()
    local defaultConfig = MSConfig.getDefaultIndicatorConfig(indicatorType)

    local style = defaultConfig.style or "circular"
    indicator:switchStyle(style == "bar")
    
    indicator:setX(defaultConfig.position.x)
    indicator:setY(defaultConfig.position.y)
    
    if style == "bar" then
        indicator:setWidth(defaultConfig.barSize.width)
        indicator:setHeight(defaultConfig.barSize.height)
    else
        indicator:setWidth(defaultConfig.circularSize)
        indicator:setHeight(defaultConfig.circularSize)
    end

    indicator.indicatorColor = {
        r = defaultConfig.color.r,
        g = defaultConfig.color.g,
        b = defaultConfig.color.b
    }
    
    indicator.opacity = defaultConfig.opacity
    indicator.iconOpacity = defaultConfig.iconOpacity
    indicator.useGradient = defaultConfig.useGradient
    indicator.showIcon = defaultConfig.showIcon
    indicator.useMonoIcon = defaultConfig.useMonoIcon
    
    if style == "bar" then
        indicator.isVertical = defaultConfig.isVertical
    end
    
    indicator.locked = defaultConfig.locked
    indicator.hidden = defaultConfig.hidden
    
    indicator:setVisible(not indicator.hidden)
    indicator.moveWithMouse = not indicator.locked

    for key, value in pairs(defaultConfig) do
        MSConfig.updateIndicatorConfig(
            indicator.playerIndex,
            indicator:getType(),
            key,
            value
        )
    end
    
    if indicator.styleButton then
        indicator.styleButton:setTitle(styleText)
    end
    
    if indicator.visibilityButton then
        indicator.visibilityButton:setTitle(visibilityText)
    end
    
    if indicator.lockButton then
        indicator.lockButton:setTitle(lockText)
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------------------------------------- --
function MS_AllIndicatorsPanel:onMouseDown(x, y)
    if y <= self.titleBarHeight then
        self.moving = true
        self:setCapture(true)
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function MS_AllIndicatorsPanel:onMouseUp(x, y)
    if self.moving then
        self.moving = false
        self:setCapture(false)
    end
    return ISPanel.onMouseUp(self, x, y)
end

function MS_AllIndicatorsPanel:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        return true
    end
    return ISPanel.onMouseMove(self, dx, dy)
end

function MS_AllIndicatorsPanel:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        return true
    end
    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function MS_AllIndicatorsPanel:onMouseUpOutside(x, y)
    if self.moving then
        self.moving = false
        self:setCapture(false)
    end
    return ISPanel.onMouseUpOutside(self, x, y)
end


-- ---------------------------------------------------------------------------------------- --
-- Panel Control
-- ---------------------------------------------------------------------------------------- --

function MS_AllIndicatorsPanel:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ---------------------------------------------------------------------------------------- --
-- render
-- ---------------------------------------------------------------------------------------- --

function MS_AllIndicatorsPanel:prerender()

    local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/TitleBarBG.png")
    titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), self.titleBarHeight, 0.5, 0.5, 0.5, 0.95)
    
    local contentbkg = NinePatchTexture.getSharedTexture("media/ui/ModernStatus/SettingPanel/ContentBackground.png")
    contentbkg:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleBarHeight, self:getWidth(), self:getHeight() - self.titleBarHeight, 0.1, 0.1, 0.1, 0.8)
    
end