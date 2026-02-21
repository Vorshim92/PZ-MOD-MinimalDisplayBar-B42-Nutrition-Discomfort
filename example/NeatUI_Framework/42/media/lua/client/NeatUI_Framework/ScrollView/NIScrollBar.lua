require "ISUI/ISScrollBar"

NIScrollBar = ISScrollBar:derive("NIScrollBar")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- instantiate
-- ----------------------------------------- --
function NIScrollBar:instantiate()
    self.javaObject = UIElement.new(self)
    
    if self.vertical then
        self.anchorTop = false
        self.anchorLeft = false
        self.anchorRight = true
        self.anchorBottom = true
    else
        self.anchorTop = false
        self.anchorLeft = false
        self.anchorRight = true
        self.anchorBottom = true
    end

    self.javaObject:setHeight(self.height)
    self.javaObject:setWidth(self.width)
    self.javaObject:setAnchorLeft(self.anchorLeft or false)
    self.javaObject:setAnchorRight(self.anchorRight or false)
    self.javaObject:setAnchorTop(self.anchorTop or false)
    self.javaObject:setAnchorBottom(self.anchorBottom or false)
    self.javaObject:setScrollWithParent(false)
end

function NIScrollBar:new(parent, vertical)
    local o = ISScrollBar:new(parent, vertical)
    setmetatable(o, self)
    self.__index = self

    o.alpha = 1.0
    if vertical then
        o.width = math.floor(FONT_HGT_SMALL*0.6)
    else
        o.height = math.floor(FONT_HGT_SMALL*0.6)
    end

    o.HorizontalThumb = NinePatchTexture.getSharedTexture("media/ui/NeatUI/ScrollView/ScrollBar_H.png")
    o.VerticalThumb = NinePatchTexture.getSharedTexture("media/ui/NeatUI/ScrollView/ScrollBar_V.png")
    return o
end

-- ----------------------------------------- --
-- Render
-- ----------------------------------------- --
function NIScrollBar:render()
    local mx = self:getMouseX()
    local my = self:getMouseY()
    local mouseOver = self.scrolling or (self:isMouseOver() and self:isPointOverThumb(mx, my))
    
    -- Vertical Mode
    if self.vertical then
        local sh = self.parent:getScrollHeight()
        
        if(sh > self:getHeight()) then
            local del = self:getHeight() / sh
            local boxheight = del * self:getHeight()
            boxheight = math.ceil(boxheight)
            boxheight = math.max(boxheight, 20)
            
            local dif = (self:getHeight() - boxheight) * self.pos
            dif = math.ceil(dif)
            
            self.barwidth = self.width*0.5
            self.barheight = boxheight
            self.barx = (self.width - self.barwidth)/2
            self.bary = dif
            
            -- Draw Vertical Thumb
            local brightness = mouseOver and 1.0 or 0.8
            local VerticalThumb = NinePatchTexture.getSharedTexture("media/ui/NeatUI/ScrollView/ScrollBar_V.png")
            VerticalThumb:render(self:getAbsoluteX() + self.barx, self:getAbsoluteY() + self.bary, self.barwidth, self.barheight, brightness, brightness, brightness, 0.8 * self.alpha)
        else
            self.barx = 0
            self.bary = 0
            self.barwidth = 0
            self.barheight = 0
        end
    else
        -- Horizontal Mode
        local sw = self.parent:getScrollWidth()
        
        if(sw > self:getWidth()) then
            local del = self:getWidth() / sw
            local boxwidth = del * self:getWidth()
            boxwidth = math.ceil(boxwidth)
            boxwidth = math.max(boxwidth, 20)
            
            local dif = (self:getWidth() - boxwidth) * self.pos
            dif = math.ceil(dif)
            
            self.barwidth = boxwidth
            self.barheight = self.height * 0.5
            self.barx = dif
            self.bary = (self.height - self.barheight)/2
            
            -- Draw Horizontal Thumb
            local brightness = mouseOver and 1.0 or 0.8
            local HorizontalThumb = NinePatchTexture.getSharedTexture("media/ui/NeatUI/ScrollView/ScrollBar_H.png")
            HorizontalThumb:render(self:getAbsoluteX() + self.barx, self:getAbsoluteY() + self.bary, self.barwidth, self.barheight, brightness, brightness, brightness, 0.8 * self.alpha)
        else
            self.barx = 0
            self.bary = 0
            self.barwidth = 0
            self.barheight = 0
        end
    end
end

-- ----------------------------------------- --
-- jump To Click Position
-- ----------------------------------------- --
function NIScrollBar:hitTest(x, y)
    if not self:isPointOver(self:getAbsoluteX() + x, self:getAbsoluteY() + y) then
        return nil
    end

    if self:isPointOverThumb(x, y) then
        return "thumb"
    end

    if not self.barx or (self.barwidth == 0) then
        return nil
    end

    if self.vertical then
        if y < self.bary then
            return "trackUp"
        end
        return "trackDown"
    else
        if x < self.barx then
            return "trackLeft"
        end
        return "trackRight"
    end
end

function NIScrollBar:onClickTrackUp(y)
    self:jumpToClickPosition(nil, y)
end

function NIScrollBar:onClickTrackDown(y)
    self:jumpToClickPosition(nil, y)
end

function NIScrollBar:onClickTrackLeft(x)
    self:jumpToClickPosition(x, nil)
end

function NIScrollBar:onClickTrackRight(x)
    self:jumpToClickPosition(x, nil)
end

function NIScrollBar:jumpToClickPosition(x, y)
    if self.vertical and y then
        local scrollHeight = self.parent:getScrollHeight()
        local parentHeight = self.parent:getHeight()
        if scrollHeight <= parentHeight then return end
        
        local relativePos = math.max(0, math.min(1, y / self:getHeight()))
        self.pos = relativePos
        self.parent:setYScroll(-relativePos * (scrollHeight - parentHeight))
        
    elseif not self.vertical and x then
        local scrollWidth = self.parent:getScrollWidth()
        local parentWidth = self.parent:getWidth()
        if scrollWidth <= parentWidth then return end
        
        local relativePos = math.max(0, math.min(1, x / self:getWidth()))
        self.pos = relativePos
        self.parent:setXScroll(-relativePos * (scrollWidth - parentWidth))
    end
end

return NIScrollBar