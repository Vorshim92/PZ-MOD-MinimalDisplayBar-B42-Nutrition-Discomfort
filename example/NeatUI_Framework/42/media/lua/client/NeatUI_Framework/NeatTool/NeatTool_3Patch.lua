NeatTool = NeatTool or {}
NeatTool.ThreePatch = {}

--[[ ----------------------------------------------------------------------------------------------------- --
Note:Although the 9-patch method in B42.9 includes the 1x3 and 3x1 approaches
the left and right textures are drawn according to their original dimensions
which limits their range of application
-- ----------------------------------------------------------------------------------------------------- ]]--

-- ----------------------------------------------------------------------------------------------------- --
-- Horizontal ThreePatch (Left and Right will keep Original ratio)
-- ----------------------------------------------------------------------------------------------------- --
function NeatTool.ThreePatch.drawHorizontal(panel, x, y, width, height, leftTexture, middleTexture, rightTexture, alpha, r, g, b)

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    local leftOriginalWidth = leftTexture:getWidth()
    local leftOriginalHeight = leftTexture:getHeight()
    local rightOriginalWidth = rightTexture:getWidth()
    local rightOriginalHeight = rightTexture:getHeight()
    
    -- calculate Left and Right
    local heightRatio = height / leftOriginalHeight
    local leftActualWidth = math.floor(leftOriginalWidth * heightRatio)
    
    heightRatio = height / rightOriginalHeight
    local rightActualWidth = math.floor(rightOriginalWidth * heightRatio)
    
    local minSidesWidth = leftActualWidth + rightActualWidth
    
    -- If ActualWidth < minSidesWidth ,things will be fucked up
    if width <= minSidesWidth then
        local leftRatio = leftActualWidth / minSidesWidth
        leftActualWidth = math.floor(width * leftRatio)
        rightActualWidth = width - leftActualWidth
        
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        panel:drawTextureScaled(rightTexture, x + leftActualWidth, y, rightActualWidth, height, alpha, r, g, b)
    else
        local middleWidth = width - leftActualWidth - rightActualWidth
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        panel:drawTextureScaled(middleTexture, x + leftActualWidth, y, middleWidth, height, alpha, r, g, b)
        panel:drawTextureScaled(rightTexture, x + leftActualWidth + middleWidth, y, rightActualWidth, height, alpha, r, g, b)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Vertical ThreePatch (Top and Bottom will keep Original ratio)
-- ----------------------------------------------------------------------------------------------------- --
function NeatTool.ThreePatch.drawVertical(panel, x, y, width, height, topTexture, middleTexture, bottomTexture, alpha, r, g, b)

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0

    local topOriginalWidth = topTexture:getWidth()
    local topOriginalHeight = topTexture:getHeight()
    local bottomOriginalWidth = bottomTexture:getWidth()
    local bottomOriginalHeight = bottomTexture:getHeight()
    
    -- calculate Top and Bottom
    local widthRatio = width / topOriginalWidth
    local topActualHeight = math.floor(topOriginalHeight * widthRatio)
    
    widthRatio = width / bottomOriginalWidth
    local bottomActualHeight = math.floor(bottomOriginalHeight * widthRatio)
    
    local minSidesHeight = topActualHeight + bottomActualHeight
    
    -- If ActualHeight < minSidesHeight ,things will be fucked up
    if height <= minSidesHeight then
        local topRatio = topActualHeight / minSidesHeight
        topActualHeight = math.floor(height * topRatio)
        bottomActualHeight = height - topActualHeight
        
        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight, width, bottomActualHeight, alpha, r, g, b)
    else
        local middleHeight = height - topActualHeight - bottomActualHeight

        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        panel:drawTextureScaled(middleTexture, x, y + topActualHeight, width, middleHeight, alpha, r, g, b)
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight + middleHeight, width, bottomActualHeight, alpha, r, g, b)
    end
end

return NeatTool.ThreePatch