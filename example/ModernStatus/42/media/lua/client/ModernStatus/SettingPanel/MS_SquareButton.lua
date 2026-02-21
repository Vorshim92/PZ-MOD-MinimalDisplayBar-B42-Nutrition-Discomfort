require "ISUI/ISButton"

MS_SquareButton = ISButton:derive("MS_SquareButton")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

function MS_SquareButton:initialise()
    ISButton.initialise(self)
end

function MS_SquareButton:new(x, y, size, iconTexture, target, onclick)
    local o = ISButton:new(x, y, size, size, "", target, onclick)
    setmetatable(o, self)
    self.__index = self
    o:setDisplayBackground(false)
    o.iconTexture = iconTexture
    o.iconSizeRatio = 0.8

    o.buttonBgTexture = getTexture("media/ui/ModernStatus/SettingPanel/SQBackground.png")
    o.buttonBorderTexture = getTexture("media/ui/ModernStatus/SettingPanel/SQBorder.png")

    o.isActive = false
    o.activeColor = {r=0.95, g=0.5, b=0.1}
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Setting
-- ----------------------------------------------------------------------------------------------------- --

function MS_SquareButton:setIcon(iconTexture)
    self.iconTexture = iconTexture
end

function MS_SquareButton:setIconSizeRatio(ratio)
    self.iconSizeRatio = ratio
end

function MS_SquareButton:setActive(active)
    self.isActive = active
end

function MS_SquareButton:setActiveColor(r, g, b)
    self.activeColor = {r=r, g=g, b=b}
end

function MS_SquareButton:setBorderTex(Texture)
    self.buttonBorderTexture = Texture
end

function MS_SquareButton:setBackgroundTex(Texture)
    self.buttonBgTexture = Texture
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function MS_SquareButton:render()
    if self.buttonBgTexture then
        if self.isActive then
            -- Active
            if self.pressed then
                -- Press
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r * 0.8, self.activeColor.g * 0.8, self.activeColor.b * 0.8)
            elseif self:isMouseOver() then
                -- Mouse Over
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    math.min(self.activeColor.r * 1.2, 1), math.min(self.activeColor.g * 1.2, 1), math.min(self.activeColor.b * 1.2, 1))
            else
                -- Default
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r, self.activeColor.g, self.activeColor.b)
            end
        else
            -- Un-Active
            if self.pressed then
                -- Press
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.05, 0.05, 0.05)
            elseif self:isMouseOver() then
                -- Mouse Over
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.2, 0.2, 0.2)
            else
                -- Default
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.1, 0.1, 0.1)
            end
        end
    end

    if self.buttonBorderTexture then
        self:drawTextureScaled(self.buttonBorderTexture, 0, 0, self.width, self.height, 1, 0.4, 0.4, 0.4)
    end

    if self.iconTexture then
        local currentIconSize = math.floor(math.min(self.width, self.height) * self.iconSizeRatio)
        local iconX = math.floor((self.width - currentIconSize) / 2)
        local iconY = math.floor((self.height - currentIconSize) / 2)
        self:drawTextureScaled(self.iconTexture, iconX, iconY, currentIconSize, currentIconSize, 1, 0.9, 0.9, 0.9)
    end
end

return MS_SquareButton