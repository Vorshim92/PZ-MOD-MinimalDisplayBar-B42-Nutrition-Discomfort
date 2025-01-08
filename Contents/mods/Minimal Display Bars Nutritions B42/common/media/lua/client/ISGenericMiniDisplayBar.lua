
-- ISGenericMiniDisplayBar
ISGenericMiniDisplayBar = ISPanel:derive("ISGenericMiniDisplayBar")

ISGenericMiniDisplayBar.alwaysBringToTop = true
ISGenericMiniDisplayBar.isEditing = false

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)


function ISGenericMiniDisplayBar:setWidth(w, ...)
    local panel = ISPanel.setWidth(self, w, ...)
    self.oldWidth = self.width
    self.innerWidth = (self.width - self.borderSizes.l - self.borderSizes.r)
    return panel
end

function ISGenericMiniDisplayBar:setHeight(h, ...)
    local panel = ISPanel.setHeight(self, h, ...)
    self.oldHeight = self.height
    self.innerHeight = (self.height - self.borderSizes.t - self.borderSizes.b)
    return panel
end

function ISGenericMiniDisplayBar:onMouseDoubleClick(x, y, ...)
    return
end

function ISGenericMiniDisplayBar:onRightMouseDown(x, y, ...)
    local result = ISPanel.onRightMouseDown(self, x, y, ...)
    self.rightMouseDown = true
    return result
end

function ISGenericMiniDisplayBar:onRightMouseUp(dx, dy, ...)
    local panel = ISPanel.onRightMouseUp(self, dx, dy, ...)
    if self.rightMouseDown == true then MinimalDisplayBars.showContextMenu(self, dx, dy) end
	self.rightMouseDown = false
    return panel
end

function ISGenericMiniDisplayBar:onRightMouseUpOutside(x, y, ...)
	local panel = ISPanel.onRightMouseUpOutside(self, x, y, ...)
	self.rightMouseDown = false
	return panel
end

function ISGenericMiniDisplayBar:onMouseDown(x, y, ...)
    local panel = ISPanel.onMouseDown(self, x, y, ...)
    self.oldX = self.x
    self.oldY = self.y
    return panel
end

function ISGenericMiniDisplayBar:onMouseUp(x, y, ...)
    local panel = ISPanel.onMouseUp(self, x, y, ...)
    self.moving = false
    return panel
end

function ISGenericMiniDisplayBar:setOnMouseDoubleClick(target, onmousedblclick, ...)
    local panel = ISPanel.setOnMouseDoubleClick(self, target, onmousedblclick, ...)
    return panel
end

function ISGenericMiniDisplayBar:onMouseUpOutside(x, y, ...)
    local panel = ISPanel.onMouseUpOutside(self, x, y, ...)
    self.moving = false
    return panel
end

local toolTip = nil
function ISGenericMiniDisplayBar:onMouseMoveOutside(dx, dy, ...)
    local panel = ISPanel.onMouseMove(self, dx, dy, ...)
    
    self.showTooltip = false
    
    if self.moving then 
        if MinimalDisplayBars.displayBarPropertiesPanel then
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryX:setText(tostring(self:getX()))
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryY:setText(tostring(self:getY()))
        end
    end
    
    --[[
    if not self.moveWithMouse then return; end
    self.mouseOver = false;

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx);
            self.parent:setY(self.parent.y + dy);
        else
            self:setX(self.x + dx);
            self:setY(self.y + dy);
            self:bringToTop();
        end
    end
    --]]
end

function ISGenericMiniDisplayBar:onMouseMove(dx, dy, ...)
    local panel = ISPanel.onMouseMove(self, dx, dy, ...)
    
    self.showTooltip = true
    self:bringToTop();
    
    if self.moving then 
        if MinimalDisplayBars.displayBarPropertiesPanel and self == MinimalDisplayBars.displayBarPropertiesPanel.displayBar then
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryX:setText(tostring(self:getX()))
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryY:setText(tostring(self:getY()))
        end
    end
    
    --[[
    if not self.moveWithMouse then return; end
    self.mouseOver = true;

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx);
            self.parent:setY(self.parent.y + dy);
        else
            self:setX(self.x + dx);
            self:setY(self.y + dy);
            self:bringToTop();
        end
        --ISMouseDrag.dragView = self;
    end
    --]]
end

--[[
ISGenericMiniDisplayBar.Back_Bad_1 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_1.png");
ISGenericMiniDisplayBar.Back_Bad_2 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_2.png");
ISGenericMiniDisplayBar.Back_Bad_3 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_3.png");
ISGenericMiniDisplayBar.Back_Bad_4 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_4.png");
ISGenericMiniDisplayBar.Back_Good_1 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_1.png");
ISGenericMiniDisplayBar.Back_Good_2 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_2.png");
ISGenericMiniDisplayBar.Back_Good_3 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_3.png");
ISGenericMiniDisplayBar.Back_Good_4 = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png");
ISGenericMiniDisplayBar.Back_Neutral = Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Bad_1.png");
ISGenericMiniDisplayBar.Endurance = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Endurance.png");
ISGenericMiniDisplayBar.Tired = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Tired.png");
ISGenericMiniDisplayBar.Hungry = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Hungry.png");
ISGenericMiniDisplayBar.Panic = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Panic.png");
ISGenericMiniDisplayBar.Sick = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Sick.png");
ISGenericMiniDisplayBar.Bored = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Bored.png");
ISGenericMiniDisplayBar.Unhappy = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Unhappy.png");
ISGenericMiniDisplayBar.Bleeding = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Bleeding.png");
ISGenericMiniDisplayBar.Wet = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Wet.png");
ISGenericMiniDisplayBar.HasACold = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Cold.png");
ISGenericMiniDisplayBar.Angry = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Angry.png");
ISGenericMiniDisplayBar.Stress = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Stressed.png");
ISGenericMiniDisplayBar.Thirst = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Thirsty.png");
ISGenericMiniDisplayBar.Injured = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Injured.png");
ISGenericMiniDisplayBar.Pain = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Pain.png");
ISGenericMiniDisplayBar.HeavyLoad = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_HeavyLoad.png");
ISGenericMiniDisplayBar.Drunk = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Drunk.png");
ISGenericMiniDisplayBar.Dead = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Dead.png");
ISGenericMiniDisplayBar.Zombie = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Zombie.png");
ISGenericMiniDisplayBar.FoodEaten = Texture.getSharedTexture("media/ui/Moodles/Moodle_Icon_Hungry.png");
ISGenericMiniDisplayBar.Hyperthermia = Texture.getSharedTexture("media/ui/weather/Moodle_Icon_TempHot.png");
ISGenericMiniDisplayBar.Hypothermia = Texture.getSharedTexture("media/ui/weather/Moodle_Icon_TempCold.png");
ISGenericMiniDisplayBar.Windchill = Texture.getSharedTexture("media/ui/Moodle_Icon_Windchill.png");
ISGenericMiniDisplayBar.plusRed = Texture.getSharedTexture("media/ui/Moodle_internal_plus_red.png");
ISGenericMiniDisplayBar.minusRed = Texture.getSharedTexture("media/ui/Moodle_internal_minus_red.png");
ISGenericMiniDisplayBar.plusGreen = Texture.getSharedTexture("media/ui/Moodle_internal_plus_green.png");
ISGenericMiniDisplayBar.minusGreen = Texture.getSharedTexture("media/ui/Moodle_internal_minus_green.png");
ISGenericMiniDisplayBar.chevronUp = Texture.getSharedTexture("media/ui/Moodle_chevron_up.png");
ISGenericMiniDisplayBar.chevronUpBorder = Texture.getSharedTexture("media/ui/Moodle_chevron_up_border.png");
ISGenericMiniDisplayBar.chevronDown = Texture.getSharedTexture("media/ui/Moodle_chevron_down.png");
ISGenericMiniDisplayBar.chevronDownBorder = Texture.getSharedTexture("media/ui/Moodle_chevron_down_border.png");
--]]
function ISGenericMiniDisplayBar:getImageBG(isoPlayer, index)
    
    local moodles = isoPlayer:getMoodles()
    local goodBadNeutral = moodles:getGoodBadNeutral(index)
    local moodleLevel = moodles:getMoodleLevel(index)
    
    local switchA = 
    {
        [0] = function()
            return Texture.getSharedTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
        end,
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

function ISGenericMiniDisplayBar:render()
    local panel = ISPanel.render(self)

    if self.parent and self:isVisible() then
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
        if MinimalDisplayBars.displayBarPropertiesPanel and self == MinimalDisplayBars.displayBarPropertiesPanel.displayBar then
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryX:setText(tostring(self:getX()))
            MinimalDisplayBars.displayBarPropertiesPanel.textEntryY:setText(tostring(self:getY()))
        end
    else
        self.parentOldX = nil
        self.parentOldY = nil
    end

    if self.colorFunction and self.colorFunction.getColor then
        local c = self.colorFunction.getColor(self.isoPlayer)
        if c and self.useColorFunction then
            self.color = c
        end
    end

    local baseValue, cigsValue = self.valueFunction.getValue(self.isoPlayer)
    if self.isoPlayer:isDead() or baseValue <= -1 then
        if self:isVisible() then
            self:setVisible(false)
        end
        return panel
    else
        if not self:isVisible() then
            self:setVisible(true)
        end
    end

    if self.imageShowBack then
        local switchMoodle = {
            ["hunger"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Hungry")))
            end,
            ["thirst"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Thirst")))
            end,
            ["endurance"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Endurance")))
            end,
            ["fatigue"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Tired")))
            end,
            ["boredomlevel"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Bored")))
            end,
            ["unhappynesslevel"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Unhappy")))
            end,
            ["stress"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Stress")))
            end,
            ["discomfortlevel"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Uncomfortable")))
            end,
            ["temperature"] = function()
                self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Hyperthermia")))
                if not self.texBG then
                    self.texBG = self:getImageBG(self.isoPlayer, MoodleType.ToIndex(MoodleType.FromString("Hypothermia")))
                end
            end
        }
        local switchFunc = switchMoodle[self.idName]
        if switchFunc then
            switchFunc()
        end
    end

    if self.idName == "stress" then
        if self.showImage and self.imageName then
            if self.isVertical then
                local w = self.imageSize or 22
                local tex = getTexture(self.imageName)
                if tex then
                    local texH = tex:getHeightOrig()
                    local texW = tex:getWidthOrig()
                    local texLargeVal = texH > texW and texH or texW
                    local texScale = w / texLargeVal
                    local h = w
                    local x = (-w * 0.5) + self:getWidth() * 0.5
                    local y = -w
                    if self.imageShowBack and self.texBG then
                        self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
                    end
                    if w % 2 == 0 then
                        x = x + 1
                        y = y + 1
                    else
                        y = y + 1
                    end
                    self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
                end
            else
                local h = self.imageSize or 22
                local tex = getTexture(self.imageName)
                if tex then
                    local texH = tex:getHeightOrig()
                    local texW = tex:getWidthOrig()
                    local texLargeVal = texH > texW and texH or texW
                    local texScale = h / texLargeVal
                    local w = h
                    local x = -h
                    local y = (-h * 0.5) + self:getHeight() * 0.5
                    if self.imageShowBack and self.texBG then
                        self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
                    end
                    if h % 2 == 0 then
                        x = x + 1
                        y = y + 1
                    else
                        y = y + 1
                    end
                    self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
                end
            end
        end
        local totalValue = baseValue + (cigsValue or 0)
        if totalValue > 1 then
            totalValue = 1
        end
        if self.isVertical then
            local totalHeight = math.floor(self.innerHeight * totalValue + 0.5)
            local baseTop = self.borderSizes.t + (self.innerHeight - totalHeight)
            
            -- 1) Disegno la "total bar" in colore base (0..totalValue)
            self:drawRectStatic(
                self.borderSizes.l,
                baseTop,
                self.innerWidth,
                totalHeight,
                self.color.alpha,
                self.color.red,
                self.color.green,
                self.color.blue
            )
            
            -- 2) Disegno la parte cigs “sopra” (0..cigsValue)
            local cigsHeight = math.floor(self.innerHeight * cigsValue + 0.5)
            local cigsTop = baseTop + (totalHeight - cigsHeight)  -- inizio dal top del total
            -- se vuoi che la parte cigs sia "sopra" in senso fisico, 
            -- potresti fare cigsTop = baseTop + (totalHeight - cigsHeight)
            -- dipende se consideri top = in alto o in basso.
            
            if cigsHeight > 0 and self.color.cigs then
                self:drawRectStatic(
                    self.borderSizes.l,
                    cigsTop,
                    self.innerWidth,
                    cigsHeight,
                    self.color.cigs.alpha,
                    self.color.cigs.red,
                    self.color.cigs.green,
                    self.color.cigs.blue
                )
            end
            
        else
            local totalWidth = math.floor(self.innerWidth * totalValue + 0.5)
            local baseLeft = self.borderSizes.l
            
            -- 1) Tutta la parte base
            self:drawRectStatic(
                baseLeft,
                self.borderSizes.t,
                totalWidth,
                self.innerHeight,
                self.color.alpha,
                self.color.red,
                self.color.green,
                self.color.blue
            )
            
            -- 2) Sovrappongo la parte cigs
            local cigsW = math.floor(self.innerWidth * cigsValue + 0.5)
            local cigsLeft = baseLeft
            -- se vuoi che appaia "alla destra" del base, puoi fare
            -- cigsLeft = baseLeft + (totalWidth - cigsW)
            
            if cigsW > 0 and self.color.cigs then
                self:drawRectStatic(
                    cigsLeft,
                    self.borderSizes.t,
                    cigsW,
                    self.innerHeight,
                    self.color.cigs.alpha,
                    self.color.cigs.red,
                    self.color.cigs.green,
                    self.color.cigs.blue
                )
            end
        end
        if self.showMoodletThresholdLines and self.moodletThresholdTable and type(self.moodletThresholdTable) == "table" then
            local tv = baseValue + (cigsValue or 0)
            if tv > 1 then
                tv = 1
            end
            for k, v in pairs(self.moodletThresholdTable) do
                local tColor = {red = 0, green = 0, blue = 0, alpha = self.color.alpha}
                if tv < v then
                    tColor.red = 1
                    tColor.green = 1
                    tColor.blue = 1
                end
                if self.isVertical then
                    local lineWidth = self.innerWidth
                    local lineHeight = 1
                    local tX = self.borderSizes.l
                    local tY = self.borderSizes.t + (self.innerHeight - math.floor((self.innerHeight * v) + 0.5))
                    self:drawRectStatic(tX, tY, lineWidth, lineHeight, tColor.alpha, tColor.red, tColor.green, tColor.blue)
                else
                    local lineWidth = 1
                    local lineHeight = self.innerHeight
                    local tX = math.floor((self.innerWidth * v) + 0.5)
                    local tY = self.borderSizes.t
                    self:drawRectStatic(tX, tY, lineWidth, lineHeight, tColor.alpha, tColor.red, tColor.green, tColor.blue)
                end
            end
        end
        if self.moving or self.resizing or self.showTooltip then
            local rb, rc = self.valueFunction.getValue(self.isoPlayer, true)
            local totalReal = 0
            if type(rb) == "number" and type(rc) == "number" then
                totalReal = rb + rc
            end
            local xOff = 4
            local yOff = 4
            local boxWidth = 200
            local boxHeight = getTextManager():getFontHeight(UIFont.Small) * 7
            local core = getCore()
            local tooltipTxt = getText("ContextMenu_MinimalDisplayBars_stress")
            .. "\r\nbase ratio: " .. string.format("%.3f", baseValue)
            .. "\r\ncigs ratio: " .. string.format("%.3f", cigsValue or 0)
            .. "\r\nTOTAL ratio: " .. string.format("%.3f", totalValue)
            .. "\r\nbase real: " .. string.format("%.3f", rb or 0)
            .. "\r\ncigs real: " .. string.format("%.3f", rc or 0)
            .. "\r\nTOTAL real: " .. string.format("%.3f", totalReal)
            if core:getScreenWidth() < self:getX() + boxWidth + xOff then
                xOff = xOff - xOff - boxWidth
            end
            if core:getScreenHeight() < self:getY() + boxHeight + yOff then
                yOff = yOff - yOff - boxHeight
            end
            self:drawRectStatic(self.borderSizes.l + xOff, self.borderSizes.t + yOff, boxWidth, boxHeight, 0.85, 0, 0, 0)
            self:drawRectBorderStatic(self.borderSizes.l + xOff, self.borderSizes.t + yOff, boxWidth, boxHeight, 0.85, 1, 1, 1)
            self:drawText(tooltipTxt, self.borderSizes.l + 2 + xOff, self.borderSizes.t + 2 + yOff, 1, 1, 1, 1, UIFont.Small)
        end
        if not self.moving and not ISGenericMiniDisplayBar.isEditing then
            if self.oldX ~= self.x or self.oldY ~= self.y then
                self.oldX = self.x
                self.oldY = self.y
                MinimalDisplayBars.configTables[self.coopNum][self.idName]["x"] = self.x - self.xOffset
                MinimalDisplayBars.configTables[self.coopNum][self.idName]["y"] = self.y - self.yOffset
                MinimalDisplayBars.io_persistence.store(self.fileSaveLocation, MinimalDisplayBars.MOD_ID, MinimalDisplayBars.configTables[self.coopNum])
            end
        end
        if self.alwaysBringToTop and (ISGenericMiniDisplayBar.alwaysBringToTop or self.idName == "menu") then
            self:bringToTop()
        end
        return panel
    end

    local value = baseValue
    local innerWidth = 0
    local innerHeight = 0
    local border_t = 0

    if self.isVertical then
        innerWidth = self.innerWidth
        innerHeight = math.floor((self.innerHeight * value) + 0.5)
        border_t = self.borderSizes.t + ((self.height - self.borderSizes.t - self.borderSizes.b) - innerHeight)
        if self.showImage and self.imageName then
            local w = self.imageSize or 22
            local tex = getTexture(self.imageName)
            if tex then
                local texH = tex:getHeightOrig()
                local texW = tex:getWidthOrig()
                local texLargeVal = texH > texW and texH or texW
                local texScale = w / texLargeVal
                local h = w
                local x = (-w * 0.5) + self:getWidth() * 0.5
                local y = -w
                if self.imageShowBack and self.texBG and self.idName ~= "calorie" then
                    self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
                end
                if self.idName ~= "temperature" and self.idName ~= "calorie" then
                    if w % 2 == 0 then
                        x = x + 1
                        y = y + 1
                    else
                        y = y + 1
                    end
                end
                self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
            end
        end
    else
        innerWidth = math.floor((self.innerWidth * value) + 0.5)
        innerHeight = self.innerHeight
        border_t = self.borderSizes.t
        if self.showImage and self.imageName then
            local h = self.imageSize or 22
            local tex = getTexture(self.imageName)
            if tex then
                local texH = tex:getHeightOrig()
                local texW = tex:getWidthOrig()
                local texLargeVal = texH > texW and texH or texW
                local texScale = h / texLargeVal
                local w = h
                local x = -h
                local y = (-h * 0.5) + self:getHeight() * 0.5
                if self.imageShowBack and self.texBG and self.idName ~= "calorie" then
                    self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
                end
                if self.idName ~= "temperature" and self.idName ~= "calorie" then
                    if h % 2 == 0 then
                        x = x + 1
                        y = y + 1
                    else
                        y = y + 1
                    end
                end
                self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
            end
        end
    end

    self:drawRectStatic(self.borderSizes.l, border_t, innerWidth, innerHeight, self.color.alpha, self.color.red, self.color.green, self.color.blue)

    if self.showMoodletThresholdLines and self.moodletThresholdTable and type(self.moodletThresholdTable) == "table" then
        for k, v in pairs(self.moodletThresholdTable) do
            local tX
            local tY
            local tColor = {red = 0, green = 0, blue = 0, alpha = self.color.alpha}
            if value < v then
                tColor.red = 1
                tColor.green = 1
                tColor.blue = 1
            end
            if self.isVertical then
                innerWidth = self.innerWidth
                innerHeight = 1
                tX = self.borderSizes.l
                tY = self.borderSizes.t + ((self.height - self.borderSizes.t - self.borderSizes.b) - math.floor((self.innerHeight * v) + 0.5))
                self:drawRectStatic(tX, tY, innerWidth, innerHeight, self.color.alpha, tColor.red, tColor.green, tColor.blue)
            else
                innerWidth = 1
                innerHeight = self.innerHeight
                tX = math.floor((self.innerWidth * v) + 0.5)
                tY = self.borderSizes.t
                self:drawRectStatic(tX, tY, innerWidth, innerHeight, self.color.alpha, tColor.red, tColor.green, tColor.blue)
            end
        end
    end

    if self.moving or self.resizing or self.showTooltip then
        local xOff = 4
        local yOff = self.idName == "menu" and 20 or 4
        local boxWidth = 200
        local boxHeight = getTextManager():getFontHeight(UIFont.Small) * 7
        local core = getCore()
        local unit = ""
        local rv = self.valueFunction.getValue(self.isoPlayer, true)
        local realValue = string.format("%.4g", rv)
        if self.idName == "temperature" then
            if core:isCelsius() or (core.getOptionDisplayAsCelsius and core:getOptionDisplayAsCelsius()) then
                unit = "°C"
            else
                realValue = string.format("%.4g", (rv * 9 / 5) + 32)
                unit = "°F"
            end
        elseif self.idName == "calorie" then
            unit = getText("ContextMenu_MinimalDisplayBars_" .. self.idName)
        end
        realValue = realValue .. " " .. unit
        local tutorialLeftClick = getText("ContextMenu_MinimalDisplayBars_Tutorial_LeftClick")
        local tutorialRightClick = getText("ContextMenu_MinimalDisplayBars_Tutorial_RightClick")
        local tutorialLeftClickLength = getTextManager():MeasureStringX(UIFont.Small, tutorialLeftClick)
        local tutorialRightClickLength = getTextManager():MeasureStringX(UIFont.Small, tutorialRightClick)
        if tutorialLeftClickLength > boxWidth then
            boxWidth = tutorialLeftClickLength + 20
        end
        if tutorialRightClickLength > boxWidth then
            boxWidth = tutorialRightClickLength + 20
        end
        local tooltipTxt
        if self.idName == "menu" then
            tooltipTxt = getText("ContextMenu_MinimalDisplayBars_" .. self.idName)
            .. "\r\n" .. tutorialLeftClick
            .. "\r\n" .. tutorialRightClick
            .. "\r\n"
            boxHeight = boxHeight - getTextManager():getFontHeight(UIFont.Small)
            if self.moving then
                tooltipTxt = tooltipTxt .. "\r\nx: " .. self.x .. "\r\ny: " .. self.y
                boxHeight = boxHeight + getTextManager():getFontHeight(UIFont.Small) * 3
            end
            boxHeight = boxHeight - getTextManager():getFontHeight(UIFont.Small) * 2
        else
            tooltipTxt = getText("ContextMenu_MinimalDisplayBars_" .. self.idName)
            .. " \r\nratio: " .. string.format("%.4g", value)
            .. " \r\nreal value: " .. realValue
            .. "\r\n"
            .. "\r\n" .. tutorialLeftClick
            .. "\r\n" .. tutorialRightClick
            .. "\r\n"
            if self.moving then
                tooltipTxt = tooltipTxt .. "\r\nx: " .. self.x .. "\r\ny: " .. self.y
                boxHeight = boxHeight + getTextManager():getFontHeight(UIFont.Small) * 3
            end
        end
        if core:getScreenWidth() < self:getX() + boxWidth + xOff then
            xOff = xOff - xOff - boxWidth
        end
        if core:getScreenHeight() < self:getY() + boxHeight + yOff then
            yOff = yOff - yOff - boxHeight
        end
        self:drawRectStatic(self.borderSizes.l, self.borderSizes.t, innerWidth, innerHeight, 0.5, 0, 0, 0)
        self:drawRectStatic(self.borderSizes.l + xOff, self.borderSizes.t + yOff, boxWidth, boxHeight, 0.85, 0, 0, 0)
        self:drawRectBorderStatic(self.borderSizes.l + xOff, self.borderSizes.t + yOff, boxWidth, boxHeight, 0.85, 1, 1, 1)
        self:drawText(tooltipTxt, self.borderSizes.l + 2 + xOff, self.borderSizes.t + 2 + yOff, 1, 1, 1, 1, UIFont.Small)
    end

    if not self.moving and not ISGenericMiniDisplayBar.isEditing then
        if self.oldX ~= self.x or self.oldY ~= self.y then
            self.oldX = self.x
            self.oldY = self.y
            MinimalDisplayBars.configTables[self.coopNum][self.idName]["x"] = self.x - self.xOffset
            MinimalDisplayBars.configTables[self.coopNum][self.idName]["y"] = self.y - self.yOffset
            MinimalDisplayBars.io_persistence.store(self.fileSaveLocation, MinimalDisplayBars.MOD_ID, MinimalDisplayBars.configTables[self.coopNum])
        end
    end

    if self.alwaysBringToTop and (ISGenericMiniDisplayBar.alwaysBringToTop or self.idName == "menu") then
        self:bringToTop()
    end

    return panel
end


function ISGenericMiniDisplayBar:resetToConfigTable(...)
    --local panel = ISPanel.resetToConfigTable(self, ...)
    
    self.x = ( MinimalDisplayBars.configTables[self.coopNum][self.idName]["x"] + self.xOffset )
    self.y = ( MinimalDisplayBars.configTables[self.coopNum][self.idName]["y"] + self.yOffset )
    self.oldX = self.x
    self.oldY = self.y
    
    self:setWidth(MinimalDisplayBars.configTables[self.coopNum][self.idName]["width"])
    self:setHeight(MinimalDisplayBars.configTables[self.coopNum][self.idName]["height"])
    
    self.oldWidth = self.width
    self.oldHeight = self.height
    
	self.moveWithMouse = MinimalDisplayBars.configTables[self.coopNum][self.idName]["isMovable"]
	self.resizeWithMouse = MinimalDisplayBars.configTables[self.coopNum][self.idName]["isResizable"]
    
	self.borderSizes = {l = MinimalDisplayBars.configTables[self.coopNum][self.idName]["l"], 
                        t = MinimalDisplayBars.configTables[self.coopNum][self.idName]["t"], 
                        r = MinimalDisplayBars.configTables[self.coopNum][self.idName]["r"], 
                        b = MinimalDisplayBars.configTables[self.coopNum][self.idName]["b"]}
	self.innerWidth = (self.width - self.borderSizes.l - self.borderSizes.r)
	self.innerHeight = (self.height - self.borderSizes.t - self.borderSizes.b)
	self.color = MinimalDisplayBars.configTables[self.coopNum][self.idName]["color"]
	self.minimumWidth = (1 + self.borderSizes.l + self.borderSizes.r)
	self.minimumHeight = (1 + self.borderSizes.t + self.borderSizes.b)
    
    self.isVertical = MinimalDisplayBars.configTables[self.coopNum][self.idName]["isVertical"]
    
    self.showMoodletThresholdLines = MinimalDisplayBars.configTables[self.coopNum][self.idName]["showMoodletThresholdLines"]
    --self.moodletThresholdTable = moodletThresholdTable
    
    self.isCompact = MinimalDisplayBars.configTables[self.coopNum][self.idName]["isCompact"]
    
    --[[
    if self.isVertical then
        if self.width > self.height then
            local oldW = tonumber(self.oldWidth)
            local oldH = tonumber(self.oldHeight)
            self:setWidth(oldH)
            self:setHeight(oldW)
        end
    else
        if self.width < self.height then
            local oldW = tonumber(self.oldWidth)
            local oldH = tonumber(self.oldHeight)
            self:setWidth(oldH)
            self:setHeight(oldW)
        end
    end
    --]]
    
    self.imageName = MinimalDisplayBars.configTables[self.coopNum][self.idName]["imageName"]
    self.imageSize = MinimalDisplayBars.configTables[self.coopNum][self.idName]["imageSize"]
    self.imageShowBack = MinimalDisplayBars.configTables[self.coopNum][self.idName]["imageShowBack"]
    self.showImage = MinimalDisplayBars.configTables[self.coopNum][self.idName]["showImage"]
    
    self.moveBarsTogether = MinimalDisplayBars.configTables[self.coopNum]["moveBarsTogether"]
    
	self:setVisible(MinimalDisplayBars.configTables[self.coopNum][self.idName]["isVisible"])
    
    self.alwaysBringToTop = MinimalDisplayBars.configTables[self.coopNum][self.idName]["alwaysBringToTop"]
    --self:setAlwaysOnTop(true)
    --return panel
end

function ISGenericMiniDisplayBar:new(
                                idName, fileSaveLocation,  
                                playerIndex, isoPlayer, coopNum, 
                                configTable, xOffset, yOffset, 
                                bChild, 
                                valueFunction, 
                                colorFunction, useColorFunction,
                                moodletThresholdTable)
                                
	local panel = ISPanel:new(  configTable[idName]["x"] + xOffset, 
                                configTable[idName]["y"] + yOffset, 
                                configTable[idName]["width"], 
                                configTable[idName]["height"])
	setmetatable(panel, self)
	self.__index = self
    
    panel.idName = idName
    
    panel.xOffset = xOffset
    panel.yOffset = yOffset
    
    panel.oldX = panel.x
    panel.oldY = panel.y
    panel.oldWidth = panel.width
    panel.oldHeight = panel.height
    
	panel.playerIndex = playerIndex
    panel.isoPlayer = isoPlayer
    panel.coopNum = coopNum
    
    panel.fileSaveLocation = fileSaveLocation
    panel.configTable = configTable
    
	panel.moveWithMouse = configTable[idName]["isMovable"]
	panel.resizeWithMouse = configTable[idName]["isResizable"]
    
	panel.borderSizes = {l = configTable[idName]["l"], 
                        t = configTable[idName]["t"], 
                        r = configTable[idName]["r"], 
                        b = configTable[idName]["b"]}
	panel.innerWidth = (panel.width - panel.borderSizes.l - panel.borderSizes.r)
	panel.innerHeight = (panel.height - panel.borderSizes.t - panel.borderSizes.b)
    
	panel.color = configTable[idName]["color"]
    
	panel.minimumWidth = (1 + panel.borderSizes.l + panel.borderSizes.r)
	panel.minimumHeight = (1 + panel.borderSizes.t + panel.borderSizes.b)
    
	panel.valueFunction = {getValue = valueFunction}
    panel.colorFunction = {getColor = colorFunction}
    panel.useColorFunction = useColorFunction
    panel.isVertical = configTable[idName]["isVertical"]
    
    panel.bChild = bChild
    
    panel.showMoodletThresholdLines = configTable[idName]["showMoodletThresholdLines"]
    panel.moodletThresholdTable = moodletThresholdTable
    
    --panel.lock = false
    
    panel.isCompact = configTable[idName]["isCompact"]
    
    --[[
    if panel.isVertical then
        if panel.width > panel.height then
            local oldW = tonumber(panel.oldWidth)
            local oldH = tonumber(panel.oldHeight)
            panel:setWidth(oldH)
            panel:setHeight(oldW)
        end
    else
        if panel.width < panel.height then
            local oldW = tonumber(panel.oldWidth)
            local oldH = tonumber(panel.oldHeight)
            panel:setWidth(oldH)
            panel:setHeight(oldW)
        end
    end
    --]]
    
	panel:setVisible(configTable[idName]["isVisible"])
    
    panel.alwaysBringToTop = configTable[idName]["alwaysBringToTop"]
    --panel:setAlwaysOnTop(true)
    
    panel.imageName = configTable[idName]["imageName"]
    panel.imageSize = configTable[idName]["imageSize"]
    panel.imageShowBack = configTable[idName]["imageShowBack"]
    panel.showImage = configTable[idName]["showImage"]
    
    panel.moveBarsTogether = configTable["moveBarsTogether"]
    
    ISGenericMiniDisplayBar.isEditing = false
    
	return panel
end

--references
-- this.Border = Texture.getSharedTexture("media/ui/Moodles/Border.png", var1);
-- this.Background = Texture.getSharedTexture("media/ui/Moodles/Background.png", var1);
-- this.Endurance = Texture.getSharedTexture("media/ui/Moodles/Status_DifficultyBreathing.png", var1);
-- this.Tired = Texture.getSharedTexture("media/ui/Moodles/Mood_Sleepy.png", var1);
-- this.Hungry = Texture.getSharedTexture("media/ui/Moodles/Status_Hunger.png", var1);
-- this.Panic = Texture.getSharedTexture("media/ui/Moodles/Mood_Panicked.png", var1);
-- this.Sick = Texture.getSharedTexture("media/ui/Moodles/Mood_Nauseous.png", var1);
-- this.Bored = Texture.getSharedTexture("media/ui/Moodles/Mood_Bored.png", var1);
-- this.Unhappy = Texture.getSharedTexture("media/ui/Moodles/Mood_Sad.png", var1);
-- this.Bleeding = Texture.getSharedTexture("media/ui/Moodles/Status_Bleeding.png", var1);
-- this.Wet = Texture.getSharedTexture("media/ui/Moodles/Status_Wet.png", var1);
-- this.HasACold = Texture.getSharedTexture("media/ui/Moodles/Mood_Ill.png", var1);
-- this.Angry = Texture.getSharedTexture("media/ui/Moodles/Mood_Angry.png", var1);
-- this.Stress = Texture.getSharedTexture("media/ui/Moodles/Mood_Stressed.png", var1);
-- this.Thirst = Texture.getSharedTexture("media/ui/Moodles/Status_Thirst.png", var1);
-- this.Injured = Texture.getSharedTexture("media/ui/Moodles/Status_InjuredMinor.png", var1);
-- this.Pain = Texture.getSharedTexture("media/ui/Moodles/Mood_Pained.png", var1);
-- this.HeavyLoad = Texture.getSharedTexture("media/ui/Moodles/Status_HeavyLoad.png", var1);
-- this.Drunk = Texture.getSharedTexture("media/ui/Moodles/Mood_Drunk.png", var1);
-- this.Dead = Texture.getSharedTexture("media/ui/Moodles/Mood_Dead.png", var1);
-- this.Zombie = Texture.getSharedTexture("media/ui/Moodles/Mood_Zombified.png", var1);
-- this.NoxiousSmell = Texture.getSharedTexture("media/ui/Moodles/Mood_NoxiousSmell.png", var1);
-- this.FoodEaten = Texture.getSharedTexture("media/ui/Moodles/Status_Hunger.png", var1);
-- this.Hyperthermia = Texture.getSharedTexture("media/ui/Moodles/Status_TemperatureHot.png", var1);
-- this.Hypothermia = Texture.getSharedTexture("media/ui/Moodles/Status_TemperatureLow.png", var1);
-- this.Windchill = Texture.getSharedTexture("media/ui/Moodles/Status_Windchill.png", var1);
-- this.CantSprint = Texture.getSharedTexture("media/ui/Moodles/Status_MovementRestricted.png", var1);
-- this.Uncomfortable = Texture.getSharedTexture("media/ui/Moodles/Mood_Discomfort.png", var1);
-- plusRed = Texture.getSharedTexture("media/ui/Moodle_internal_plus_red.png", var1);
-- minusRed = Texture.getSharedTexture("media/ui/Moodle_internal_minus_red.png", var1);
-- plusGreen = Texture.getSharedTexture("media/ui/Moodle_internal_plus_green.png", var1);
-- minusGreen = Texture.getSharedTexture("media/ui/Moodle_internal_minus_green.png", var1);