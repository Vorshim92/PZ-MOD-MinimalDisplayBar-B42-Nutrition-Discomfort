--[[ ----------------------------------------- --
Grid Virtual ScrollView for Project Zomboid
[Input] dataSource, itemWidth, itemHeight, axisCount, padding, onCreateItem, onUpdateItem
[Optional]
2. showScrollBars (boolean)
3. setSpacing (horizontal and vertical spacing between items)
-- ----------------------------------------- ]]--

require "ISUI/ISUIElement"

NIGridVirtualScrollView = ISUIElement:derive("NIGridVirtualScrollView")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- instantiate
-- ----------------------------------------- --
function NIGridVirtualScrollView:new(x, y, w, h)
    local o = ISUIElement:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    -- Main Config
    o.dataSource = {}
    o.itemWidth = 10
    o.itemHeight = 10
    o.axisCount = 3
    o.HSpacing = 5
    o.VSpacing = 5
    o.scrollDirection = "vertical"
    
    -- Pool
    o.itemPool = {}
    o.poolSize = 0
    o.visibleStartAxis = 1
    o.visibleEndAxis = 1
    
    -- Scroll
    o.scrollOffset = 0
    o.totalScrollSize = 0
    o.maxScrollOffset = 0
    o.showScrollBars = true
    o.smoothScroll = nil
    o.smoothScrollTarget = nil
    
    -- Grid calculations
    o.totalAxis = 0
    o.axisDimension = 0
    
    -- Callback
    o.onCreateItem = nil        -- Create UIElement: function(index) return itemObject end
    o.onUpdateItem = nil        -- Update when index change: function(itemObject, data, row, col) end
    
    return o
end

function NIGridVirtualScrollView:createChildren()
    self:addScrollBar()
    self:calculateGridMetrics()
    self:initializePool()
end

function NIGridVirtualScrollView:addScrollBar()
    local isVertical = (self.scrollDirection == "vertical")
    self.vscroll = NIScrollBar:new(self, isVertical)
    self.vscroll:initialise()
    self:addChild(self.vscroll)
end

-- ----------------------------------------- --
-- Grid Configuration
-- ----------------------------------------- --
function NIGridVirtualScrollView:setConfig(itemWidth, itemHeight, axisCount)
    self.itemWidth = itemWidth
    self.itemHeight = itemHeight
    self.axisCount = axisCount
    
    self:calculateGridMetrics()
    
    self.poolSize = self:calculatePoolSize()
    self:initializePool()
    
    self:updateScrollMetrics()
end

function NIGridVirtualScrollView:setSpacing(horizontal, vertical)
    self.HSpacing = horizontal
    self.VSpacing = vertical
    
    self:calculateGridMetrics()
    self:updateScrollMetrics()
end

function NIGridVirtualScrollView:calculateGridMetrics()
    if self.scrollDirection == "horizontal" then
        self.axisDimension = self.itemWidth + self.HSpacing
    else
        self.axisDimension = self.itemHeight + self.VSpacing
    end
    
    local dataCount = #self.dataSource
    self.totalAxis = math.ceil(dataCount / self.axisCount)
end

function NIGridVirtualScrollView:setScrollDirection(direction)
    if direction ~= "vertical" and direction ~= "horizontal" then
        return
    end
    
    self.scrollDirection = direction

    self:calculateGridMetrics()
    self:updateScrollMetrics()

    self.scrollOffset = 0
    self.smoothScrollTarget = nil
    self.smoothScroll = nil

    self:refreshItems()
end

-- ----------------------------------------- --
-- Data Management
-- ----------------------------------------- --
function NIGridVirtualScrollView:setDataSource(dataSource, forceRefresh)
    self.dataSource = dataSource or {}
    self:calculateGridMetrics()
    self:updateScrollMetrics()

    if forceRefresh then
        self.visibleStartAxis = -1
        self.visibleEndAxis = -1
    end
    
    self:refreshItems()
end

function NIGridVirtualScrollView:setOnCreateItem(callback)
    self.onCreateItem = callback
    self:initializePool()
end

function NIGridVirtualScrollView:setOnUpdateItem(callback)
    self.onUpdateItem = callback
end

function NIGridVirtualScrollView:setShowScrollBars(show)
    self.showScrollBars = show
    if self.vscroll then
        self.vscroll:setVisible(show and (self.maxScrollOffset > 0))
    end
end

-- ----------------------------------------- --
-- Pool management
-- ----------------------------------------- --

function NIGridVirtualScrollView:calculatePoolSize()
    if self.axisDimension <= 0 or self.axisCount <= 0 then
        return math.max(10, self.axisCount * 2)
    end

    local availableSpace, visibleCount
    if self.scrollDirection == "horizontal" then
        availableSpace = self.width - self.HSpacing * 2
        visibleCount = math.ceil(availableSpace / self.axisDimension)
    else
        availableSpace = self.height - self.VSpacing * 2
        visibleCount = math.ceil(availableSpace / self.axisDimension)
    end
    
    visibleCount = math.max(1, visibleCount)
    
    local bufferRows = 2
    local totalAxis = visibleCount + bufferRows
    local poolSize = totalAxis * self.axisCount
    local minPoolSize = self.axisCount * 3
    
    return math.max(minPoolSize, poolSize)
end

function NIGridVirtualScrollView:initializePool()
    -- Clear existing pool
    for _, item in ipairs(self.itemPool) do
        if item and item.removeFromUIManager then
            self:removeChild(item)
        end
    end
    
    self.itemPool = {}
    
    if not self.onCreateItem then return end
    
    if self.poolSize == 0 then
    self.poolSize = self:calculatePoolSize()
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
-- Scroll Calculations
-- ----------------------------------------- --
function NIGridVirtualScrollView:updateScrollMetrics()
    local contentSize = self:getContentSize()
    local containerSize = self:getContainerSize()
    
    self.totalScrollSize = math.max(contentSize, containerSize)

    if self.totalAxis == 0 or contentSize <= containerSize then
        self.maxScrollOffset = 0
    else
        self.maxScrollOffset = contentSize - containerSize
    end
    
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScrollOffset))
end

function NIGridVirtualScrollView:calculateVisibleRowRange()
    if #self.dataSource == 0 or self.totalAxis == 0 then return 1, 0 end
    
    local startPos, endPos, containerSize
    if self.scrollDirection == "horizontal" then
        startPos = self.scrollOffset + self.HSpacing
        endPos = self.scrollOffset + self.width - self.HSpacing
        containerSize = self.width
    else
        startPos = self.scrollOffset + self.VSpacing
        endPos = self.scrollOffset + self.height - self.VSpacing
        containerSize = self.height
    end

    local startRow = math.max(1, math.ceil((startPos - self.HSpacing) / self.axisDimension))
    local endRow = math.min(self.totalAxis, math.floor((endPos - self.HSpacing) / self.axisDimension))

    local buffersize = 1
    startRow = math.max(1, startRow - buffersize)
    endRow = math.min(self.totalAxis, endRow + buffersize)
    
    return startRow, endRow
end

function NIGridVirtualScrollView:getItemPosition(dataIndex)
    local row = math.ceil(dataIndex / self.axisCount)
    local col = ((dataIndex - 1) % self.axisCount) + 1

    local x, y
    if self.scrollDirection == "horizontal" then
        x = self.HSpacing + (row - 1) * self.axisDimension - self.scrollOffset
        y = self.VSpacing + (col - 1) * (self.itemHeight + self.VSpacing)
    else
        x = self.HSpacing + (col - 1) * (self.itemWidth + self.HSpacing)
        y = self.VSpacing + (row - 1) * self.axisDimension - self.scrollOffset
    end
    
    return x, y, row, col
end

-- ----------------------------------------- --
-- Update items
-- ----------------------------------------- --
function NIGridVirtualScrollView:refreshItems()
    if not self.onUpdateItem or #self.itemPool == 0 then
        return
    end
    
    local startRow, endRow = self:calculateVisibleRowRange()
    
    self.visibleStartAxis = startRow
    self.visibleEndAxis = endRow

    for _, item in ipairs(self.itemPool) do
        item:setVisible(false)
    end
    
    local poolIndex = 1
    local dataCount = #self.dataSource

    for row = startRow, endRow do
        for col = 1, self.axisCount do
            if poolIndex > #self.itemPool then
                break
            end
            
            local dataIndex = (row - 1) * self.axisCount + col
            
            if dataIndex <= dataCount then
                local item = self.itemPool[poolIndex]
                local data = self.dataSource[dataIndex]

                self.onUpdateItem(item, data, row, col)
                item:setVisible(true)

                local x, y = self:getItemPosition(dataIndex)
                item:setX(x)
                item:setY(y)
                item:setWidth(self.itemWidth)
                item:setHeight(self.itemHeight)
                
                poolIndex = poolIndex + 1
            end
        end
        
        if poolIndex > #self.itemPool then
            break
        end
    end
    
    print("Refreshed items - Rows:", startRow, "to", endRow, "Pool used:", poolIndex - 1, "/", #self.itemPool)
end

-- ----------------------------------------- --
-- Smooth Scrolling
-- ----------------------------------------- --
function NIGridVirtualScrollView:updateSmoothScrolling()
    if not self.smoothScrollTarget then return end
    
    if not self.smoothScroll then 
        self.smoothScroll = -self.scrollOffset
    end
    
    local dy = self.smoothScrollTarget - self.smoothScroll
    local maxScroll = self.maxScrollOffset
    
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    local axisDimensionFrac = 160 / self.axisDimension
    local moveAmount = dy * math.min(0.5, 0.25 * frameRateFrac * axisDimensionFrac)
    
    if frameRateFrac > 1 then
        moveAmount = dy * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac * axisDimensionFrac) * frameRateFrac)
    end
    
    local target = self.smoothScroll + moveAmount
    if target > 0 then target = 0 end
    if target < -maxScroll then target = -maxScroll end
    
    if math.abs(target - self.smoothScroll) > 0.1 then
        self:setScrollOffsetDirect(-target)
        self.smoothScroll = target
    else
        self:setScrollOffsetDirect(-self.smoothScrollTarget)
        self.smoothScrollTarget = nil
        self.smoothScroll = nil
    end
end

function NIGridVirtualScrollView:setScrollOffsetDirect(offset)
    local oldOffset = self.scrollOffset
    self.scrollOffset = math.max(0, math.min(offset, self.maxScrollOffset))
    
    if oldOffset ~= self.scrollOffset then
        self:refreshItems()
        self:updateScrollBar()
    end
end

function NIGridVirtualScrollView:updateScrollBar()
    if not self.vscroll then return end
    local margin = FONT_HGT_SMALL * 0.2

    if self.scrollDirection == "horizontal" then
        self.vscroll:setWidth(self.width - margin * 2)
        self.vscroll:setX(margin)
        self.vscroll:setY(self.height - self.vscroll.height)
    else
        self.vscroll:setHeight(self.height - margin * 2)
        self.vscroll:setX(self.width - self.vscroll.width)
        self.vscroll:setY(margin)
    end
    
    if self.maxScrollOffset <= 0 then
        self.vscroll.pos = 0
        self.vscroll:setVisible(false)
    else
        self.vscroll.pos = self.scrollOffset / self.maxScrollOffset
        self.vscroll:setVisible(self.showScrollBars)
    end
end

-- ----------------------------------------- --
-- Mouse Wheel - Scroll by rows
-- ----------------------------------------- --
function NIGridVirtualScrollView:onMouseWheel(del)
    local maxScroll = self.maxScrollOffset

    local currentScroll = (self.smoothScrollTarget and -self.smoothScrollTarget) or self.scrollOffset

    local scrollStep = self.axisDimension
    local targetScroll = currentScroll + (del * scrollStep)

    targetScroll = math.max(0, math.min(targetScroll, maxScroll))
    
    self.smoothScrollTarget = -targetScroll
    if not self.smoothScroll then
        self.smoothScroll = -self.scrollOffset
    end
    
    return true
end

-- ----------------------------------------- --
-- Render
-- ----------------------------------------- --
function NIGridVirtualScrollView:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    self:updateSmoothScrolling()
    self:updateScrollBar()
end

function NIGridVirtualScrollView:render()
    self:clearStencilRect()
end

function NIGridVirtualScrollView:update()
    ISUIElement.update(self)
end

-- ----------------------------------------- --
-- Scroll Methods 
-- ----------------------------------------- --
function NIGridVirtualScrollView:getContainerSize()
    if self.scrollDirection == "horizontal" then
        return self.width
    else
        return self.height
    end
end

function NIGridVirtualScrollView:getContentSize()
    if self.scrollDirection == "horizontal" then
        return self.HSpacing + self.totalAxis * self.axisDimension
    else
        return self.VSpacing + self.totalAxis * self.axisDimension
    end
end

function NIGridVirtualScrollView:getScrollHeight()
    if self.scrollDirection == "vertical" then
        return self:getContentSize()
    else
        return self:getContainerSize()
    end
end

function NIGridVirtualScrollView:getScrollWidth()
    if self.scrollDirection == "horizontal" then
        return self:getContentSize()
    else
        return self:getContainerSize()
    end
end

function NIGridVirtualScrollView:getScroll()
    return -self.scrollOffset
end

function NIGridVirtualScrollView:setScroll(scrollValue)
    self.smoothScrollTarget = nil
    self.smoothScroll = nil
    self:setScrollOffsetDirect(-scrollValue)
end

function NIGridVirtualScrollView:getYScroll()
    return self:getScroll()
end

function NIGridVirtualScrollView:getXScroll()
    return self:getScroll()
end

function NIGridVirtualScrollView:setYScroll(yScroll)
    if self.scrollDirection == "vertical" then
        self:setScroll(yScroll)
    end
end

function NIGridVirtualScrollView:setXScroll(xScroll)
    if self.scrollDirection == "horizontal" then
        self:setScroll(xScroll)
    end
end

function NIGridVirtualScrollView:getScrollAreaHeight()
    return self:getContainerSize()
end

function NIGridVirtualScrollView:getScrollAreaWidth()
    return self:getContainerSize()
end

return NIGridVirtualScrollView