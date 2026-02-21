require "ISUI/ISButton"

NI_SquareButton = ISButton:derive("NI_SquareButton")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

function NI_SquareButton:initialise()
    ISButton.initialise(self)
end

function NI_SquareButton:new(x, y, size, iconTexture, target, onclick)
    local o = ISButton:new(x, y, size, size, "", target, onclick)
    setmetatable(o, self)
    self.__index = self
    o:setDisplayBackground(false)
    o.iconTexture = iconTexture
    o.iconSizeRatio = 0.8

    o.buttonBgTexture = getTexture("media/ui/NeatUI/Button/Background.png")
    o.buttonBorderTexture = getTexture("media/ui/NeatUI/Button/Boarder.png")

    o.isActive = false
    o.activeColor = {r=0.95, g=0.5, b=0.1}
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Config
-- ----------------------------------------------------------------------------------------------------- --

function NI_SquareButton:setIcon(iconTexture)
    self.iconTexture = iconTexture
end

function NI_SquareButton:setIconSizeRatio(ratio)
    self.iconSizeRatio = ratio
end

function NI_SquareButton:setActive(active)
    self.isActive = active
end

function NI_SquareButton:setActiveColor(r, g, b)
    self.activeColor = {r=r, g=g, b=b}
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function NI_SquareButton:render()
    if self.buttonBgTexture then
        if self.isActive then
            -- [Active]
            if self.pressed then
                -- Pressed
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r * 0.8, self.activeColor.g * 0.8, self.activeColor.b * 0.8)
            elseif self:isMouseOver() then
                -- Hover
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    math.min(self.activeColor.r * 1.2, 1), math.min(self.activeColor.g * 1.2, 1), math.min(self.activeColor.b * 1.2, 1))
            else
                -- Default
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r, self.activeColor.g, self.activeColor.b)
            end
        else
            -- [Normal]
            if self.pressed then
                -- Pressed
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.1, 0.1, 0.1)
            elseif self:isMouseOver() then
                -- Hover
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.3, 0.3, 0.3)
            else
                -- Default
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.2, 0.2, 0.2)
            end
        end
    end

    self:drawTextureScaled(self.buttonBorderTexture, 0, 0, self.width, self.height, 1, 0.4, 0.4, 0.4)

    local currentIconSize = math.floor(math.min(self.width, self.height) * self.iconSizeRatio)
    local iconX = math.floor((self.width - currentIconSize) / 2)
    local iconY = math.floor((self.height - currentIconSize) / 2)
    self:drawTextureScaled(self.iconTexture, iconX, iconY, currentIconSize, currentIconSize, 1, 0.9, 0.9, 0.9)
end

return NI_SquareButton