require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTickBox"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

MS_CircularStylePanel = ISPanel:derive("MS_CircularStylePanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function MS_CircularStylePanel:initialise()
    ISPanel.initialise(self)
end

function MS_CircularStylePanel:new(x, y, width, height, indicator)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground(true)
    o.indicator = indicator
    o.rowHeight = math.floor(FONT_HGT_SMALL*1.5)
    o.padding = math.floor(FONT_HGT_SMALL*0.2)
    o.buttonSize = math.floor(FONT_HGT_SMALL*1.2)

    o.MinusButton = getTexture("media/ui/ModernStatus/SettingPanel/Icon_Minus.png")
    o.PlusButton = getTexture("media/ui/ModernStatus/SettingPanel/Icon_Plus.png")
    o.resetIcon = getTexture("media/ui/ModernStatus/SettingPanel/Icon_Reset.png")

    o.TextEntryLeft = getTexture("media/ui/ModernStatus/SettingPanel/TextEntry_Left.png")
    o.TextEntryMiddle = getTexture("media/ui/ModernStatus/SettingPanel/TextEntry_Middle.png")
    o.TextEntryRight = getTexture("media/ui/ModernStatus/SettingPanel/TextEntry_Right.png")
    
    return o
end

-- ---------------------------------------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------------------------------------- --

function MS_CircularStylePanel:createChildren()
    local config = MSConfig.getIndicatorConfig(self.indicator.playerIndex, self.indicator:getType())
    if config.circularSize then
        self.indicator:setWidth(config.circularSize)
        self.indicator:setHeight(config.circularSize)
    end

    local y = 0
    local middleX = self.width / 2
    local controlX = middleX + self.padding


    -- X Position
    self.xPositionControls = self:createStepperControl(controlX, y, "X",
        function() return self.indicator:getX() end,
        function(value) 
            self.indicator:setX(value)
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "position", 
                {x = value, y = self.indicator:getY()})
        end, 0, getCore():getScreenWidth(), 1, false)
    
    y = y + self.rowHeight
    
    -- y Position
    self.yPositionControls = self:createStepperControl(controlX, y, "Y",
        function() return self.indicator:getY() end,
        function(value) 
            self.indicator:setY(value)
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "position", 
                {x = self.indicator:getX(), y = value})
        end, 0, getCore():getScreenHeight(), 1, false)
    
    y = y + self.rowHeight
    
    -- size Controls
    local config = MSConfig.getIndicatorConfig(self.indicator.playerIndex, self.indicator:getType())
    self.sizeControls = self:createStepperControl(controlX, y, getText("IGUI_ModernStatus_Size"),
        function() return self.indicator:getWidth() end,
        function(value) 
            self.indicator:setWidth(value)
            self.indicator:setHeight(value)
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "circularSize", value)
        end, 1, 200, 4, false)
    
    y = y + self.rowHeight
    
    -- Color Picker
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_Color"), 1, 1, 1, 1, UIFont.Small)
    self.colorPreview = ISButton:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize * 2, self.buttonSize, "", self, MS_CircularStylePanel.openColorPicker)
    self.colorPreview:initialise()
    self.colorPreview:instantiate()
    
    local indicatorColor = {r=1, g=1, b=1}
    if self.indicator and self.indicator.indicatorColor then
        indicatorColor = self.indicator.indicatorColor
    end
    
    self.colorPreview.backgroundColor = {
        r = indicatorColor.r,
        g = indicatorColor.g,
        b = indicatorColor.b,
        a = 1
    }
    
    self.colorPreview.borderColor = {r=1, g=1, b=1, a=1}
    self:addChild(self.colorPreview)

    -- Reset Color
    self.resetColorBtn = MS_SquareButton:new(controlX + self.buttonSize * 2 + 10, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.resetIcon, self, MS_CircularStylePanel.onResetColor)
    self.resetColorBtn:initialise()
    self:addChild(self.resetColorBtn)

    y = y + self.rowHeight
    
    -- opacity Controls
    self.opacityControls = self:createStepperControl(controlX, y, getText("IGUI_ModernStatus_Opacity"),
        function() return self.indicator.opacity or 1.0 end,
        function(value) 
            self.indicator.opacity = value
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "opacity", value)
        end, 0.1, 1.0, 0.1, true)
    
    y = y + self.rowHeight
    
    -- use Gradient
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_UseGradient"), 1, 1, 1, 1, UIFont.Small)
    self.useGradientBox = ISTickBox:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.buttonSize, "", self, MS_CircularStylePanel.onUseGradientChange)
    self.useGradientBox:initialise()
    self.useGradientBox:addOption("")

    local useGradient = false
    if self.indicator and self.indicator.useGradient ~= nil then
        useGradient = self.indicator.useGradient
    end
    self.useGradientBox:setSelected(1, useGradient)
    self:addChild(self.useGradientBox)

    y = y + self.rowHeight
    
    -- Show Icon
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_ShowIcon"), 1, 1, 1, 1, UIFont.Small)
    self.showIconBox = ISTickBox:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.buttonSize, "", self, MS_CircularStylePanel.onShowIconChange)
    self.showIconBox:initialise()
    self.showIconBox:addOption("")
    
    local showIcon = true
    if self.indicator and self.indicator.showIcon ~= nil then
        showIcon = self.indicator.showIcon
    end
    self.showIconBox:setSelected(1, showIcon)
    self:addChild(self.showIconBox)

    y = y + self.rowHeight

    -- always Show Value
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_AlwaysShowValue"), 1, 1, 1, 1, UIFont.Small)
    self.alwaysShowValueBox = ISTickBox:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.buttonSize, "", self, MS_CircularStylePanel.onAlwaysShowValueChange)
    self.alwaysShowValueBox:initialise()
    self.alwaysShowValueBox:addOption("")
    
    local alwaysShowValue = false
    if self.indicator and self.indicator.alwaysShowValue ~= nil then
        alwaysShowValue = self.indicator.alwaysShowValue
    end
    self.alwaysShowValueBox:setSelected(1, alwaysShowValue)
    self:addChild(self.alwaysShowValueBox)
    
    y = y + self.rowHeight

    -- text Scale Controls
    self.textScaleControls = self:createStepperControl(controlX, y, getText("IGUI_ModernStatus_TextSize"),
        function() return self.indicator.textScale or 1.0 end,
        function(value) 
            self.indicator.textScale = value
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "textScale", value)
        end, 0.5, 2.0, 0.1, true)
    
    y = y + self.rowHeight

    -- use Mono Icon
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_MonoIcon"), 1, 1, 1, 1, UIFont.Small)
    self.useMonoIconBox = ISTickBox:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.buttonSize, "", self, MS_CircularStylePanel.onUseMonoIconChange)
    self.useMonoIconBox:initialise()
    self.useMonoIconBox:addOption("")
    
    local useMonoIcon = false
    if self.indicator and self.indicator.useMonoIcon ~= nil then
        useMonoIcon = self.indicator.useMonoIcon
    end
    self.useMonoIconBox:setSelected(1, useMonoIcon)
    self:addChild(self.useMonoIconBox)
    
    y = y + self.rowHeight

    -- icon Opacity Controls
    self.iconOpacityControls = self:createStepperControl(controlX, y, getText("IGUI_ModernStatus_IconOpacity"),
        function() return self.indicator.iconOpacity or 1.0 end,
        function(value) 
            self.indicator.iconOpacity = value
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "iconOpacity", value)
        end, 0.1, 1.0, 0.1, true)

    y = y + self.rowHeight

    -- threshold Controls
    self.thresholdControls = self:createStepperControl(controlX, y, getText("IGUI_ModernStatus_AnimThreshold"),
        function() return self.indicator.animationThreshold or 30 end,
        function(value) 
            self.indicator.animationThreshold = value
            MSConfig.updateIndicatorConfig(self.indicator.playerIndex, self.indicator:getType(), "animationThreshold", value)
        end, 0, 100, 5, false)

    y = y + self.rowHeight

    -- auto Hide
    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), getText("IGUI_ModernStatus_AutoHide"), 1, 1, 1, 1, UIFont.Small)
    self.autoHideBox = ISTickBox:new(controlX, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.buttonSize, "", self, MS_CircularStylePanel.onAutoHideChange)
    self.autoHideBox:initialise()
    self.autoHideBox:addOption("")
    
    local autoHide = false
    if self.indicator and self.indicator.autoHide ~= nil then
        autoHide = self.indicator.autoHide
    end
    self.autoHideBox:setSelected(1, autoHide)
    self:addChild(self.autoHideBox)
    
    y = y + self.rowHeight
end


function MS_CircularStylePanel:createStepperControl(x, y, labelText, getValue, setValue, minValue, maxValue, step, isPercentage)

    self:createLabel(self.padding, y + ((self.rowHeight-FONT_HGT_SMALL)/2), labelText, 1, 1, 1, 1, UIFont.Small)

    -- textBox
    local textBoxWidth = getTextManager():MeasureStringX(UIFont.Small, "9") * 4 + self.padding*2
    local currentValue = isPercentage and math.floor(getValue() * 100) or getValue()
    local textBox = ISTextEntryBox:new(tostring(currentValue), x + self.buttonSize + self.padding, y + ((self.rowHeight-self.buttonSize)/2), textBoxWidth, self.buttonSize)
    textBox:initialise()
    textBox:instantiate()
    textBox:setOnlyNumbers(true)
    
    local function updateFromText()
        local text = textBox:getText()
        if text == "" then return end
        local value = tonumber(text)
        if not value then return end
        
        if isPercentage then
            value = math.max(minValue * 100, math.min(maxValue * 100, value))
            textBox:setText(tostring(value))
            setValue(value / 100)
        else
            value = math.max(minValue, math.min(maxValue, value))
            textBox:setText(tostring(value))
            setValue(value)
        end
    end
    
    local function updateTextBox()
        local newValue = getValue()
        local displayValue = isPercentage and math.floor(newValue * 100) or newValue
        textBox:setText(tostring(displayValue))
    end
    
    textBox.onCommandEntered = updateFromText
    textBox.onOtherKey = function(key) if key == 28 then updateFromText() end end
    textBox.onMouseDownOutside = updateFromText
    textBox.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 0.0}
    textBox.backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.0}
    self:addChild(textBox)

    -- decBtn
    local decBtn = MS_SquareButton:new(x, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.MinusButton, self, 
        function() 
            setValue(math.max(minValue, getValue() - step))
            updateTextBox()
        end)
    decBtn:initialise()
    decBtn:instantiate()
    self:addChild(decBtn)
    
    -- incBtn
    local incBtn = MS_SquareButton:new(x + self.buttonSize + self.padding + textBoxWidth + self.padding, y + ((self.rowHeight-self.buttonSize)/2), self.buttonSize, self.PlusButton, self,
        function() 
            setValue(math.min(maxValue, getValue() + step))
            updateTextBox()
        end)
    incBtn:initialise()
    incBtn:instantiate()
    self:addChild(incBtn)
    
    return {decBtn = decBtn, textBox = textBox, incBtn = incBtn}
end

function MS_CircularStylePanel:createLabel(x, y, text, r, g, b, a, font)
    local label = ISLabel:new(x, y, 0, text, r, g, b, a, font, true)
    label:initialise()
    label:instantiate()
    self:addChild(label)
    return label
end

-- ---------------------------------------------------------------------------------------- --
-- ColorPicker
-- ---------------------------------------------------------------------------------------- --
function MS_CircularStylePanel:openColorPicker()
    if not self.indicator then return end
    
    local pickerX = self.colorPreview:getAbsoluteX() + self.colorPreview:getWidth() + 5
    local pickerY = self.colorPreview:getAbsoluteY()
    
    if not self.indicator.indicatorColor then
        self.indicator.indicatorColor = {r=1, g=1, b=1}
    end

    local initialColor = ColorInfo.new(
        self.indicator.indicatorColor.r,
        self.indicator.indicatorColor.g,
        self.indicator.indicatorColor.b,
        1
    )
    
    local colorPicker = ISColorPickerHSB:new(pickerX, pickerY, initialColor)
    colorPicker:setPickedFunc(function(target, colorRGB) 
        self:onColorSelected(colorRGB.r, colorRGB.g, colorRGB.b) 
    end)
    colorPicker:initialise()
    colorPicker:addToUIManager()
    colorPicker:setVisible(true)
end

function MS_CircularStylePanel:onColorSelected(r, g, b)
    if not self.indicator then return end
    
    if not self.indicator.indicatorColor then
        self.indicator.indicatorColor = {r=1, g=1, b=1}
    end
    
    self.indicator.indicatorColor.r = r
    self.indicator.indicatorColor.g = g
    self.indicator.indicatorColor.b = b
    
    self:updateColorPreview()
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "color",
        {r = r, g = g, b = b}
    )
end

-- ---------------------------------------------------------------------------------------- --
-- Button Callback
-- ---------------------------------------------------------------------------------------- --
function MS_CircularStylePanel:onUseGradientChange(index, selected)
    if not self.indicator then return end
    self.indicator.useGradient = selected
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "useGradient",
        selected
    )
end

function MS_CircularStylePanel:onShowIconChange(index, selected)
    if not self.indicator then return end
    self.indicator.showIcon = selected
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "showIcon",
        selected
    )
end

function MS_CircularStylePanel:onUseMonoIconChange(index, selected)
    if not self.indicator then return end
    self.indicator.useMonoIcon = selected
    
    self.indicator:updateIconPath()
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "useMonoIcon",
        selected
    )
end

function MS_CircularStylePanel:onResetColor()
    if not self.indicator then return end

    local indicatorType = self.indicator:getType()
    local defaultConfig = MSConfig.getDefaultIndicatorConfig(indicatorType)
    local defaultColor = defaultConfig.color

    self.indicator.indicatorColor = {
        r = defaultColor.r,
        g = defaultColor.g,
        b = defaultColor.b
    }

    self:updateColorPreview()

    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "color",
        {r = defaultColor.r, g = defaultColor.g, b = defaultColor.b}
    )
end

function MS_CircularStylePanel:onAlwaysShowValueChange(index, selected)
    if not self.indicator then return end
    self.indicator.alwaysShowValue = selected
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "alwaysShowValue",
        selected
    )
end

function MS_CircularStylePanel:onAutoHideChange(index, selected)
    if not self.indicator then return end
    self.indicator.autoHide = selected
    
    MSConfig.updateIndicatorConfig(
        self.indicator.playerIndex,
        self.indicator:getType(),
        "autoHide",
        selected
    )
end

function MS_CircularStylePanel:updateColorPreview()
    if not self.indicator or not self.indicator.indicatorColor or not self.colorPreview then return end
    
    self.colorPreview.backgroundColor = {
        r = self.indicator.indicatorColor.r,
        g = self.indicator.indicatorColor.g,
        b = self.indicator.indicatorColor.b,
        a = 1
    }
    self.colorPreview:setBackgroundRGBA(
        self.indicator.indicatorColor.r,
        self.indicator.indicatorColor.g,
        self.indicator.indicatorColor.b,
        1
    )
end