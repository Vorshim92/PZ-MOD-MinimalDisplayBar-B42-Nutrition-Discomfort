require "ISUI/ISUIElement"

MS_StatusIndicator = ISUIElement:derive("MS_StatusIndicator")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:initialise()
    ISUIElement.initialise(self)
    
    -- Icon Scale
    self.iconAnimActive = false
    self.iconAnimTime = 0
    self.iconAnimDir = 1
    self.iconAnimScale = 1.0
    self.lastAnimTriggerTime = 0
    
    -- Icon Sway
    self.iconSwayActive = false
    self.iconSwayTime = 0
    self.iconSwayOffset = 0
    
    -- Bar Blink
    self.barAnimActive = false
    self.barAnimTime = 0
    self.barAnimTransition = 0

    self:loadConfig()
end

function MS_StatusIndicator:new(x, y, width, height, player)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:setOnMouseDoubleClick(o, MS_IndicatorActions.onDoubleClick)
    o.player = player
    o.playerIndex = player:getPlayerNum()
    o.moveWithMouse = true
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.iconPath = nil
    o.indicatorColor = {r=1, g=1, b=1}
    o.opacity = 1.0
    o.useGradient = false
    o.defaultX = x
    o.defaultY = y
    o.isHovered = false
    o.showIcon = true
    o.useMonoIcon = false
    o.isBarStyle = false
    o.isVertical = false
    o.autoHide = false 

    o.segmentTextures = {}
    for i=1, 12 do
        local texturePath = "media/ui/ModernStatus/CircularStatus/segment_" .. i .. ".png"
        o.segmentTextures[i] = getTexture(texturePath)
    end
    
    o.circularBgTexture = getTexture("media/ui/ModernStatus/CircularStatus/background.png")
    o.circularLineTexture = getTexture("media/ui/ModernStatus/CircularStatus/background_Line.png")
    o.circularBgShader = getTexture("media/ui/ModernStatus/CircularStatus/background_Shader.png")
    o.iconbackground = getTexture("media/ui/ModernStatus/BarStatus/BarStatus_iconBG.png")

    o.barBackgroundLeft = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_Left_64.png")
    o.barBackgroundMiddle = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_Middle_64.png")
    o.barBackgroundRight = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_Right_64.png")
    
    o.barFillLeft = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_FLeft_64.png")
    o.barFillMiddle = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_FMiddle_64.png")
    o.barFillRight = getTexture("media/ui/ModernStatus/HorizontalBar/ModernStatus_Horizontal_FRight_64.png")

    o.barBackgroundTop = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_Top_64.png")
    o.barBackgroundMiddleVertical = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_Middle_64.png")
    o.barBackgroundBottom = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_Bottom_64.png")
    
    o.barFillTop = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_FTop_64.png")
    o.barFillMiddleVertical = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_FMiddle_64.png")
    o.barFillBottom = getTexture("media/ui/ModernStatus/VerticalBar/ModernStatus_Vertical_FBottom_64.png")
    
    return o
end

function MS_StatusIndicator:updateIconPath()
    if not self.baseIconName then return end
    
    if self.useMonoIcon then
        self.iconPath = "media/ui/ModernStatus/MonoIcon/" .. self.baseIconName .. ".png"
    else
        local moddlePath = "media/ui/Moodles/128/" .. self.baseIconName .. ".png"
        local moddleTexture = getTexture(moddlePath)
        
        if moddleTexture then
            self.iconPath = moddlePath
        else
            self.iconPath = "media/ui/ModernStatus/ColorIcon/" .. self.baseIconName .. ".png"
        end
    end
    
    if self.iconPath and self.iconPath ~= "" then
        self.iconTexture = getTexture(self.iconPath)
    end
end

-- ---------------------------------------------------------------------------------------- --
-- loadConfig
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:loadConfig()
    if not self.playerIndex then return end
    
    local config = MSConfig.getIndicatorConfig(self.playerIndex, self:getType())
    
    self.isBarStyle = config.style == "bar"
    
    if config.position then
        self:setX(config.position.x)
        self:setY(config.position.y)
    end
    
    if self.isBarStyle then
        if config.barSize then
            self:setWidth(config.barSize.width)
            self:setHeight(config.barSize.height)
        end
    else
        if config.circularSize then
            local size = config.circularSize
            self:setWidth(size)
            self:setHeight(size)
        end
    end

    if config.color then
        self.indicatorColor = {
            r = config.color.r,
            g = config.color.g,
            b = config.color.b
        }
    end
    
    if config.opacity ~= nil then
        self.opacity = config.opacity
    end

    if config.iconOpacity ~= nil then
        self.iconOpacity = config.iconOpacity
    end
    
    if config.useGradient ~= nil then
        self.useGradient = config.useGradient
    end
    
    if config.showIcon ~= nil then
        self.showIcon = config.showIcon
    end
    
    if config.useMonoIcon ~= nil then
        self.useMonoIcon = config.useMonoIcon
    end
    
    if config.isVertical ~= nil and self.isBarStyle then
        self.isVertical = config.isVertical
    end
    
    if config.locked ~= nil then
        self.locked = config.locked
        self.moveWithMouse = not self.locked
    end

    if config.alwaysShowValue ~= nil then
        self.alwaysShowValue = config.alwaysShowValue
    end
    
    if config.hidden ~= nil then
        self.hidden = config.hidden
        self:setVisible(not self.hidden)
    end

    if config.animationThreshold ~= nil then
        self.animationThreshold = config.animationThreshold
    end
    
    if config.showName ~= nil then
        self.showName = config.showName
    end
    
    if config.textScale ~= nil then
        self.textScale = config.textScale
    end

    if config.autoHide ~= nil then
        self.autoHide = config.autoHide
    end

    self:updateIconPath()
end

-- ---------------------------------------------------------------------------------------- --
-- Animation
-- ---------------------------------------------------------------------------------------- --

function MS_StatusIndicator:updateIconAnimation(delta)
    if not self.iconAnimActive then return end
    self.iconAnimTime = self.iconAnimTime + delta

    if self.iconAnimDir == 1 and self.iconAnimTime < 0.5 then
        self.iconAnimScale = 1.0 - (self.iconAnimTime / 0.5) * 0.3
    elseif self.iconAnimDir == 1 and self.iconAnimTime < 1.0 then
        self.iconAnimScale = 0.7 + ((self.iconAnimTime - 0.5) / 0.5) * 0.3
    else
        if self.iconAnimTime >= 1.0 then
            self.iconAnimActive = false
            self.iconAnimScale = 1.0
        end
    end
end

function MS_StatusIndicator:updateBarAnimation(delta)
    if not self.barAnimActive then return end
    self.barAnimTime = self.barAnimTime + delta
    local cycle = self.barAnimTime / 3.0
    local transitionFactor = (math.sin(cycle * math.pi * 2) + 1) / 2
    self.barAnimTransition = transitionFactor
    
    if self.barAnimTime >= 6.0 then
        self.barAnimTime = 0
        local value = self:getValue()
        if not self:checkThresholdExceeded(value) then
            self.barAnimActive = false
        end
    end
end

function MS_StatusIndicator:updateIconSwayAnimation(delta)
    if not self.iconSwayActive then return end
    
    self.iconSwayTime = self.iconSwayTime + delta
    
    local frequency = 1.0  -- shake frequency
    local amplitude = 3.0  -- shake amplitude
    
    self.iconSwayOffset = math.sin(self.iconSwayTime * frequency * math.pi) * amplitude
    
    if self.iconSwayTime >= 6.0 then
        self.iconSwayTime = 0
        local value = self:getValue()
        if not self:checkThresholdExceeded(value) then
            self.iconSwayActive = false
        end
    end
end

function MS_StatusIndicator:checkTriggerAnimation(value)
    local currentTime = getTimestampMs()
    if currentTime - self.lastAnimTriggerTime < 1000 then
        return
    end
    local triggerAnim = self:checkThresholdExceeded(value)
    
    if triggerAnim then
        if self.isBarStyle then
            if not self.barAnimActive then
                self.barAnimActive = true
                self.barAnimTime = 0
                self.barAnimColor = 1
                self.lastAnimTriggerTime = currentTime
                StatusWidget.hasActiveAnimations = true
            end

            if self.showIcon and not self.iconSwayActive then
                self.iconSwayActive = true
                self.iconSwayTime = 0
                StatusWidget.hasActiveAnimations = true
            end
        else
            if not self.iconAnimActive then
                self.iconAnimActive = true
                self.iconAnimTime = 0
                self.iconAnimDir = 1
                self.lastAnimTriggerTime = currentTime
                StatusWidget.hasActiveAnimations = true
            end
        end
    end
end

function MS_StatusIndicator:checkThresholdExceeded(value)
    local indicatorType = self:getType()
    
    -- we dont need this to be in Threshold system
    if indicatorType == "MS_TemperatureIndicator" or  -- Temperature
       indicatorType == "MS_WeightIndicator" or       -- Weight
       indicatorType == "MS_MedicineIndicator"  then  -- Medicine
        return false
    end
    
    local config = MSConfig.getIndicatorConfig(self.playerIndex, indicatorType)
    local userThreshold = config.animationThreshold or self.animationThreshold
    local threshold = userThreshold / 100

    if MS_PlayerStatus.isHigherBetter(indicatorType) then
        return value < threshold
    else
        return value > (1 - threshold)
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------------------------------------- -

function MS_StatusIndicator:render()
    
    local value = self:getValue()
    
    -- AutoHide only work for circle 
    if not self.isBarStyle and self.autoHide and not self:checkThresholdExceeded(value) then
        return
    end
    
    if self.isBarStyle then
        self:renderBarStyle(value)
    else
        self:renderCircularStyle(value)
    end

    local textScale = self.textScale or 1.0
    
    if (self:isMouseOver() or self.alwaysShowValue) and value >= 0 then
        local hoverText = self:getHoverText(value)
        local textX, textY
        
        local fontHeight = getTextManager():getFontHeight(UIFont.Small)
        local scaledFontHeight = fontHeight * textScale
        
        if self.isBarStyle then
            if self.isVertical then
                textX = math.ceil(self.width / 2 - (getTextManager():MeasureStringX(UIFont.Small, hoverText) * textScale) / 2)
                textY = math.ceil(-scaledFontHeight)
            else
                local textWidth = getTextManager():MeasureStringX(UIFont.Small, hoverText) * textScale
                textX = math.ceil(self.width - textWidth - self.padding)
                textY = math.ceil((self.height - scaledFontHeight) / 2 )
            end
        else
            textX = math.ceil(self.width / 2 - (getTextManager():MeasureStringX(UIFont.Small, hoverText) * textScale) / 2 )
            textY = math.ceil((self.height - scaledFontHeight) / 2)
        end
        
        -- Outline
        self:drawTextZoomed(hoverText, textX-1, textY, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX+1, textY, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX-1, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX+1, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX-1, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(hoverText, textX+1, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        -- Text
        self:drawTextZoomed(hoverText, textX, textY, textScale, 1, 1, 1, 1, UIFont.Small)
    end
end

function MS_StatusIndicator:getHoverText(value)
    return tostring(round(value * 100 ))
end

function MS_StatusIndicator:renderCircularStyle(value)
    self:drawTextureScaled(self.circularBgTexture, 0, 0, self.width, self.height, 0.6, 0.1, 0.1, 0.1)
    self:drawTextureScaled(self.circularLineTexture, 0, 0, self.width, self.height, 0.6, 0.2, 0.2, 0.2)
    self:drawTextureScaled(self.circularBgShader, 0, 0, self.width, self.height, 1, 1, 1, 1)
    local fullSegments = math.floor(value * 12)

    local partialSegment = fullSegments + 1
    local partialAlpha = (value * 12) - fullSegments
    
    local baseAlpha = self.opacity or 0.8
    local r = self.indicatorColor.r
    local g = self.indicatorColor.g
    local b = self.indicatorColor.b
    
    -- Color
    if self.useGradient then
        local gradColor = self:getGradientColor(value)
        r = gradColor.r
        g = gradColor.g
        b = gradColor.b
    end
    
    -- Draw segment Percentage
    for i=1, fullSegments do
        if self.segmentTextures[i] then
            self:drawTextureScaled(self.segmentTextures[i], 0, 0, self.width, self.height, baseAlpha, r, g, b)
        end
    end

    if partialSegment <= 12 and partialAlpha > 0 and self.segmentTextures[partialSegment] then
        self:drawTextureScaled(self.segmentTextures[partialSegment], 0, 0, self.width, self.height, baseAlpha * partialAlpha, r, g, b)
    end
    
    -- Draw Icon
    if self.showIcon and self.iconTexture then
        local iconSize = self.width* 0.95 * self.iconAnimScale 
        local x = math.floor((self.width - iconSize) / 2)
        local y = math.floor((self.height - iconSize) / 2)
        local iconAlpha = self.iconOpacity or 1.0

        if self.alwaysShowValue or self:isMouseOver() then
            iconAlpha = iconAlpha * 0.5
        end
        
        self:drawTextureScaled(self.iconTexture, x, y, iconSize, iconSize, iconAlpha, 1, 1, 1)
    end

    self:checkTriggerAnimation(value)
end

function MS_StatusIndicator:renderBarStyle(value)
    -- og color
    local r = self.indicatorColor and self.indicatorColor.r or 1.0
    local g = self.indicatorColor and self.indicatorColor.g or 1.0
    local b = self.indicatorColor and self.indicatorColor.b or 1.0

    -- if we use Gradient
    if self.useGradient and not self.barAnimActive then
        local gradColor = self:getGradientColor(value)
        r = gradColor.r
        g = gradColor.g
        b = gradColor.b
    end
    
    -- apply Animation
    if self.barAnimActive and self.barAnimTransition then
        local r1 = 0.9
        local g1 = 0.3
        local b1 = 0.1

        local r2 = 1.0
        local g2 = 0.9
        local b2 = 0.5

        r = r1 * self.barAnimTransition + r2 * (1 - self.barAnimTransition)
        g = g1 * self.barAnimTransition + g2 * (1 - self.barAnimTransition)
        b = b1 * self.barAnimTransition + b2 * (1 - self.barAnimTransition)
    end
    
    local opacity = self.opacity or 1.0
    
    if self.isVertical then
        self:renderVerticalBar(value, opacity, r, g, b)
    else
        self:renderHorizontalBar(value, opacity, r, g, b)
    end

    self:checkTriggerAnimation(value)
end

function MS_StatusIndicator:renderVerticalBar(value, opacity, r, g, b)
    local bgWidth = self.width
    local bgAlpha = opacity * 0.8
    
    NeatTool.ThreePatch.drawVertical(self, 0, 0, bgWidth, self.height,self.barBackgroundTop,self.barBackgroundMiddleVertical,self.barBackgroundBottom,bgAlpha, 0.6, 0.6, 0.6)

    local fillHeight = (self.height * value)

    if fillHeight > 0 then
        local fillWidth = bgWidth
        local fillY = self.height - fillHeight

        self:setStencilRect(0, fillY, fillWidth, fillHeight)
        NeatTool.ThreePatch.drawVertical(self, 0, 0, fillWidth, self.height,self.barFillTop,self.barFillMiddleVertical,self.barFillBottom,opacity, r, g, b)
        self:clearStencilRect()
    end
    
    -- Bottom Icon
    if self.showIcon and self.iconTexture then
        local iconSize = self.width * 1.4
        local iconX = (self.width - iconSize) / 2
        
        if self.iconSwayActive then
            iconX = iconX + self.iconSwayOffset
        end
        
        local iconY = self.height
        self:drawTextureScaled(self.iconTexture, iconX, iconY, iconSize, iconSize, self.iconOpacity or 1.0, 1, 1, 1)
    end
end

function MS_StatusIndicator:renderHorizontalBar(value, opacity, r, g, b)
    local bgAlpha = opacity * 0.8
    
    NeatTool.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height,self.barBackgroundLeft,self.barBackgroundMiddle,self.barBackgroundRight,bgAlpha, 0.6, 0.6, 0.6)
    
    local fillWidth = math.floor(self.width * value)
    
    if fillWidth > 0 then
        self:setStencilRect(0, 0, fillWidth, self.height)
        NeatTool.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height,self.barFillLeft,self.barFillMiddle,self.barFillRight,opacity, r, g, b)
        self:clearStencilRect()
    end
    
    -- Left Icon
    if self.showIcon and self.iconTexture then
        local iconSize = self.height * 1.4
        local iconX = - iconSize - self.padding/2
        
        if self.iconSwayActive then
            iconX = iconX + self.iconSwayOffset
        end
        
        local iconY = (self.height - iconSize) / 2
        self:drawTextureScaled(self.iconTexture, iconX, iconY, iconSize, iconSize, self.iconOpacity or 1.0, 1, 1, 1)
    end
    
    -- Show Name
    if self.showName ~= false then
        local indicatorType = self:getType()
        local titleKey = MS_IndicatorSettingsPanel.IndicatorNames[indicatorType]
        local titleText = titleKey and getText(titleKey) or indicatorType
        local textScale = self.textScale or 1.0

        local scaledFontHeight = FONT_HGT_SMALL * textScale
        local textX = self.padding
        local textY = math.floor((self.height - scaledFontHeight) / 2 )
        
        -- Outline
        self:drawTextZoomed(titleText, textX-1, textY, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX+1, textY, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX-1, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX+1, textY-1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX-1, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        self:drawTextZoomed(titleText, textX+1, textY+1, textScale, 0, 0, 0, 1, UIFont.Small)
        -- Text
        self:drawTextZoomed(titleText, textX, textY, textScale, 1, 1, 1, 1, UIFont.Small)
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Gradient Color
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:getGradientColor(value)
    local indicatorType = self:getType()
    
    if not MS_PlayerStatus.isHigherBetter(indicatorType) then
        value = 1 - value
    end

    local h = (120 * value) / 360
    local s = 0.6
    local v = 0.9
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local r, g, b
    if i % 6 == 0 then r, g, b = v, t, p
    elseif i % 6 == 1 then r, g, b = q, v, p 
    elseif i % 6 == 2 then r, g, b = p, v, t
    elseif i % 6 == 3 then r, g, b = p, q, v
    elseif i % 6 == 4 then r, g, b = t, p, v
    elseif i % 6 == 5 then r, g, b = v, p, q
    end
    
    return {r=r, g=g, b=b}
end

-- ---------------------------------------------------------------------------------------- --
-- Get Config
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:getValue()
    return 1.0
end

function MS_StatusIndicator:getType()
    return self.__type or "MS_StatusIndicator"
end

-- ---------------------------------------------------------------------------------------- --
-- Style Manager
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:switchStyle(useBarStyle)
    if self.isBarStyle == useBarStyle then return end
    
    self.isBarStyle = useBarStyle
    
    MSConfig.updateIndicatorConfig(
        self.playerIndex,
        self:getType(),
        "style",
        useBarStyle and "bar" or "circular"
    )
    
    local config = MSConfig.getIndicatorConfig(self.playerIndex, self:getType())
    
    if useBarStyle then
        local barSize = config.barSize or {width = 160, height = 24}
        self:setWidth(barSize.width)
        self:setHeight(barSize.height)
    else
        local circularSize = config.circularSize or 48
        self:setWidth(circularSize)
        self:setHeight(circularSize)
    end
    
    self:setVisible(true)
end

-- ---------------------------------------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:onMouseMove(dx, dy)
    if self.moving then
        local config = MSConfig.getGlobalConfig(self.playerIndex)
        
        if config and config.multiDragMode then
            local indicators = StatusWidget.indicators[self.playerIndex]
            if indicators then
                for _, indicator in pairs(indicators) do
                    if not indicator.locked and indicator ~= self then
                        indicator:setX(indicator.x + dx)
                        indicator:setY(indicator.y + dy)
                    end
                end
            end
        end

        local newX = self.x + dx
        local newY = self.y + dy
        
        self:setX(newX)
        self:setY(newY)
    end
    
    return ISUIElement.onMouseMove(self, 0, 0)
end

function MS_StatusIndicator:onMouseMoveOutside(dx, dy)
    if self.moving then
        local config = MSConfig.getGlobalConfig(self.playerIndex)
        
        if config and config.multiDragMode then
            local indicators = StatusWidget.indicators[self.playerIndex]
            if indicators then
                for _, indicator in pairs(indicators) do
                    if not indicator.locked and indicator ~= self then
                        indicator:setX(indicator.x + dx)
                        indicator:setY(indicator.y + dy)
                    end
                end
            end
        end

        local newX = self.x + dx
        local newY = self.y + dy
        
        self:setX(newX)
        self:setY(newY)
    end
    
    return true
end

function MS_StatusIndicator:onRightMouseDown(x, y)
    self:showSettingsPanel()
    return ISUIElement.onRightMouseDown(self, x, y)
end

function MS_StatusIndicator:onMouseDown(x, y)
    if self.locked then return false end
    
    self.dragStartX = x
    self.dragStartY = y
    self.moving = true
    self:setCapture(true)
    return true
end

function MS_StatusIndicator:onMouseUp(x, y)

    if self.moving then
        self.moving = false
        self:setCapture(false)
        
        MSConfig.updateIndicatorConfig(
            self.playerIndex,
            self:getType(),
            "position",
            {x = self:getX(), y = self:getY()}
        )
        
        local config = MSConfig.getGlobalConfig(self.playerIndex)
        
        if config and config.multiDragMode then
            local indicators = StatusWidget.indicators[self.playerIndex]
            if indicators then
                for _, indicator in pairs(indicators) do
                    if not indicator.locked and indicator ~= self then
                        MSConfig.updateIndicatorConfig(
                            indicator.playerIndex,
                            indicator:getType(),
                            "position",
                            {x = indicator:getX(), y = indicator:getY()}
                        )
                    end
                end
            end
        end
    end
    return true
end

-- ---------------------------------------------------------------------------------------- --
-- show SettingsPanel
-- ---------------------------------------------------------------------------------------- --
function MS_StatusIndicator:showSettingsPanel()

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    
    local panelX = self:getX() + self:getWidth() + 10
    local panelY = self:getY()

    local panel = MS_IndicatorSettingsPanel:new(panelX, panelY, nil, nil, self)
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    
    if panelX + panel:getWidth() > screenW then
        panelX = self:getX() - panel:getWidth() - 10
    end
    
    if panelY + panel:getHeight() > screenH then
        panelY = screenH - panel:getHeight() - 10
    end
    
    if panelX < 0 then
        panelX = self:getX() + self:getWidth() + 10
    end
    
    if panelY < 0 then
        panelY = 10
    end
    
    panel:setX(panelX)
    panel:setY(panelY)
end