--[[ ----------------------------------------- --
Note: It only support Vertical ScrollView for now.
[Input]dataSource,itemHeight,padding,onCreateItem,onUpdateItem
[Optional]
1.setPoolSize(if not ,the poolsize will autocalculate according to itemHeight,padding...)
2.showScrollBars(boolean)
-- ----------------------------------------- ]]--

require "ISUI/ISUIElement"

NIVirtualScrollView = ISUIElement:derive("NIVirtualScrollView")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- instantiate
-- ----------------------------------------- --
function NIVirtualScrollView:new(x, y, w, h)
    local o = ISUIElement:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.x = x
    o.y = y
    o.width = w
    o.height = h

    -- Main Config
    o.dataSource = {}
    o.itemHeight = 50
    o.padding = 5
    
    -- Pool
    o.itemPool = {}
    o.poolSize = 0
    o.autoPoolSize = true
    o.poolSizeBuffer = 1.5
    o.visibleStartIndex = 1
    o.visibleEndIndex = 1
    
    -- Scroll
    o.scrollOffset = 0
    o.totalHeight = 0
    o.maxScrollOffset = 0
    o.showScrollBars = true;
    o.smoothScrollY = nil
    o.smoothScrollTargetY = nil
    
    -- Callback
    o.onCreateItem = nil        -- Create UIElement: function(index) return itemObject end
    o.onUpdateItem = nil        -- Update when index change: function(itemObject, data) end
    
    return o
end

function NIVirtualScrollView:createChildren()
    self:addScrollBar()
    self:initializePool()
end

function NIVirtualScrollView:addScrollBar()
    self.vscroll = NIScrollBar:new(self, true)
    self.vscroll:initialise()
    self:addChild(self.vscroll)
end

-- ----------------------------------------- --
-- Setting Config
-- ----------------------------------------- --
function NIVirtualScrollView:setDataSource(dataSource, forceRefresh)
    self.dataSource = dataSource or {}
    self:updateScrollMetrics()

    if forceRefresh then
        self.visibleStartIndex = -1
        self.visibleEndIndex = -1
    end
    
    self:refreshItems()
end

function NIVirtualScrollView:setConfig(itemHeight, padding)
    self.itemHeight = itemHeight
    self.padding = padding

    if self.autoPoolSize then
        self.poolSize = self:calculateAutoPoolSize()
        self:initializePool()
    end
    self:updateScrollMetrics()
end

function NIVirtualScrollView:setOnCreateItem(callback)
    self.onCreateItem = callback
    self:initializePool()
end

function NIVirtualScrollView:setOnUpdateItem(callback)
    self.onUpdateItem = callback
end

function NIVirtualScrollView:setShowScrollBars(show)
    self.showScrollBars = show;
    if self.vscroll then
        self.vscroll:setVisible(show and (self.maxScrollOffset > 0));
    end
end

-- ----------------------------------------- --
-- Pool management
-- ----------------------------------------- --
function NIVirtualScrollView:setPoolSize(size)
    if size and size > 0 then
        self.poolSize = size
        self.autoPoolSize = false
    else
        self.autoPoolSize = true
        self.poolSize = self:calculateAutoPoolSize()
    end
    self:initializePool()
end

function NIVirtualScrollView:setPoolSizeBuffer(buffer)
    self.poolSizeBuffer = buffer or 1.5
    if self.autoPoolSize then
        self.poolSize = self:calculateAutoPoolSize()
        self:initializePool()
    end
end

function NIVirtualScrollView:calculateAutoPoolSize()
    if self.itemHeight <= 0 or self.height <= 0 then
        return 10
    end

    local visibleItemCount = math.ceil(self.height / self.itemHeight)

    local poolSize = math.ceil(visibleItemCount * self.poolSizeBuffer)
    print("Calculated pool size:", poolSize)

    local minPoolSize = 3
    return math.max(minPoolSize, poolSize)
end

function NIVirtualScrollView:initializePool()
    for _, item in ipairs(self.itemPool) do
        if item and item.removeFromUIManager then
            self:removeChild(item)
        end
    end
    
    self.itemPool = {}
    
    if not self.onCreateItem then return end
    
    if self.autoPoolSize and self.poolSize == 0 then
        self.poolSize = self:calculateAutoPoolSize()
    end

    for i = 1, self.poolSize do
        local item = self.onCreateItem(i)
        if item then
            item:initialise()
            item:setVisible(false)
            self:addChild(item)
            table.insert(self.itemPool, item)
        end
    end
end

-- ----------------------------------------- --
-- calculate Scroll
-- ----------------------------------------- --
function NIVirtualScrollView:updateScrollMetrics()
    local dataCount = #self.dataSource

    local contentHeight = dataCount * (self.itemHeight + self.padding) + self.padding
    self.totalHeight = math.max(contentHeight, self.height)

    if dataCount == 0 or contentHeight <= self.height then
        self.maxScrollOffset = 0
    else
        self.maxScrollOffset = contentHeight - self.height
    end
    
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScrollOffset))
end

function NIVirtualScrollView:calculateVisibleRange()
    if #self.dataSource == 0 then
        return 1, 0
    end
    
    local startY = self.scrollOffset
    local endY = startY + self.height

    local itemSpacing = self.itemHeight + self.padding
    local startIndex = math.max(1, math.floor((startY - self.padding) / itemSpacing) + 1)
    local endIndex = math.min(#self.dataSource, math.ceil((endY - self.padding) / itemSpacing))

    startIndex = math.max(1, startIndex)
    endIndex = math.max(startIndex, endIndex)
    endIndex = math.min(#self.dataSource, endIndex)
    
    local bufferSize = 1
    startIndex = math.max(1, startIndex - bufferSize)
    endIndex = math.min(#self.dataSource, endIndex + bufferSize)
    --print("startIndex: "..startIndex.." endIndex: ".. endIndex)
    
    return startIndex, endIndex
end

-- ----------------------------------------- --
-- Update items
-- ----------------------------------------- --
function NIVirtualScrollView:refreshItems()
    if not self.onUpdateItem or #self.itemPool == 0 then
        return
    end
    
    local startIndex, endIndex = self:calculateVisibleRange()
    local needReassignData = startIndex ~= self.visibleStartIndex or endIndex ~= self.visibleEndIndex
    
    self.visibleStartIndex = startIndex
    self.visibleEndIndex = endIndex
    
    if needReassignData then
        for _, item in ipairs(self.itemPool) do
            item:setVisible(false)
        end
    end
    
    local poolIndex = 1
    for dataIndex = startIndex, endIndex do
        if poolIndex > #self.itemPool then
            break
        end
        
        if dataIndex <= #self.dataSource then
            local item = self.itemPool[poolIndex]
            local data = self.dataSource[dataIndex]
            
            if needReassignData then
                self.onUpdateItem(item, data)
                item:setVisible(true)
            end
            
            local itemY = self.padding + (dataIndex - 1) * (self.itemHeight + self.padding) - self.scrollOffset
            item:setY(itemY)
            
            poolIndex = poolIndex + 1
        end
    end
end

-- ----------------------------------------- --
-- Update 
-- ----------------------------------------- --
function NIVirtualScrollView:updateSmoothScrolling()
    if not self.smoothScrollTargetY then return end
    
    if not self.smoothScrollY then 
        self.smoothScrollY = -self.scrollOffset
    end
    
    local dy = self.smoothScrollTargetY - self.smoothScrollY
    local maxYScroll = self.maxScrollOffset
    
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    local itemHeightFrac = 160 / self.itemHeight
    local moveAmount = dy * math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac)
    
    if frameRateFrac > 1 then
        moveAmount = dy * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac) * frameRateFrac)
    end
    
    local targetY = self.smoothScrollY + moveAmount
    if targetY > 0 then targetY = 0 end
    if targetY < -maxYScroll then targetY = -maxYScroll end
    
    if math.abs(targetY - self.smoothScrollY) > 0.1 then
        self:setScrollOffsetDirect(-targetY)
        self.smoothScrollY = targetY
    else
        self:setScrollOffsetDirect(-self.smoothScrollTargetY)
        self.smoothScrollTargetY = nil
        self.smoothScrollY = nil
    end
end


function NIVirtualScrollView:setScrollOffsetDirect(offset)
    local oldOffset = self.scrollOffset
    self.scrollOffset = math.max(0, math.min(offset, self.maxScrollOffset))
    
    if oldOffset ~= self.scrollOffset then
        self:refreshItems()
        self:updateScrollBar()
    end
end

function NIVirtualScrollView:updateScrollBar()
    if not self.vscroll then return end
    local margin = FONT_HGT_SMALL*0.2

    self.vscroll:setHeight(self.height - margin * 2)
    self.vscroll:setX(self.width - self.vscroll.width)
    self.vscroll:setY(margin)
    
    if self.maxScrollOffset <= 0 then
        self.vscroll.pos = 0
        self.vscroll:setVisible(false)
    else
        self.vscroll.pos = self.scrollOffset / self.maxScrollOffset
        self.vscroll:setVisible(self.showScrollBars)
    end
end

-- ----------------------------------------- --
-- MouseWheel -- force Scroll to next item
-- ----------------------------------------- --
function NIVirtualScrollView:onMouseWheel(del)
    local maxScroll = self.maxScrollOffset

    local baseScroll = (self.smoothScrollTargetY and -self.smoothScrollTargetY) or self.scrollOffset
    local itemSpacing = self.itemHeight + self.padding
    local currentItemIndex = (baseScroll - self.padding) / itemSpacing
    
    local targetItemIndex
    if del < 0 then
        targetItemIndex = math.floor(currentItemIndex)
        if math.abs(currentItemIndex - targetItemIndex) < 0.01 then
            targetItemIndex = targetItemIndex - 1
        end
    else
        targetItemIndex = math.ceil(currentItemIndex)
        if math.abs(currentItemIndex - targetItemIndex) < 0.01 then
            targetItemIndex = targetItemIndex + 1
        end
    end

    targetItemIndex = math.max(0, targetItemIndex)
    local targetScroll = math.min(self.padding + targetItemIndex * itemSpacing, maxScroll)
    
    self.smoothScrollTargetY = -targetScroll
    if not self.smoothScrollY then
        self.smoothScrollY = -self.scrollOffset
    end
    return true
end

-- ----------------------------------------- --
-- Render
-- ----------------------------------------- --
function NIVirtualScrollView:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    self:updateSmoothScrolling()
    self:updateScrollBar()
end

function NIVirtualScrollView:render()
    self:clearStencilRect()
end

function NIVirtualScrollView:update()
    ISUIElement.update(self)
end

-- ----------------------------------------- --
-- ScrollBar 
-- ----------------------------------------- --
function NIVirtualScrollView:getScrollHeight()
    return self.totalHeight
end

function NIVirtualScrollView:getYScroll()
    return -self.scrollOffset
end

function NIVirtualScrollView:setYScroll(yScroll)
    self.smoothScrollTargetY = nil
    self.smoothScrollY = nil
    self:setScrollOffsetDirect(-yScroll)
end

return NIVirtualScrollView