NeatTool = NeatTool or {}
NeatTool.NinePatch = {}

--[[ ----------------------------------------- --
Note: B42.9 Release a real 9-patch like android,better to use that way
Only if u need to use nine patch in a small element and the texture need to be a big size
-- ----------------------------------------- ]]--
function NeatTool.NinePatch.draw(panel, x, y, width, height, textures, alpha, r, g, b)
    
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- Get four Four Corner Size
    local cornerTopLeftWidth = textures.topLeft:getWidth()
    local cornerTopLeftHeight = textures.topLeft:getHeight()
    local cornerTopRightWidth = textures.topRight:getWidth()
    local cornerTopRightHeight = textures.topRight:getHeight()
    local cornerBottomLeftWidth = textures.bottomLeft:getWidth()
    local cornerBottomLeftHeight = textures.bottomLeft:getHeight()
    local cornerBottomRightWidth = textures.bottomRight:getWidth()
    local cornerBottomRightHeight = textures.bottomRight:getHeight()
    
    -- calculate minWidth and minHeight
    local minWidth = cornerTopLeftWidth + cornerTopRightWidth
    local minHeight = cornerTopLeftHeight + cornerBottomLeftHeight
    
    local scale = 1.0
    if width < minWidth then
        scale = width / minWidth
    end
    if height < minHeight and (height / minHeight) < scale then
        scale = height / minHeight
    end
    
    -- scale Four Corner
    local actualCornerTopLeftWidth = math.floor(cornerTopLeftWidth * scale)
    local actualCornerTopLeftHeight = math.floor(cornerTopLeftHeight * scale)
    local actualCornerTopRightWidth = math.floor(cornerTopRightWidth * scale)
    local actualCornerTopRightHeight = math.floor(cornerTopRightHeight * scale)
    local actualCornerBottomLeftWidth = math.floor(cornerBottomLeftWidth * scale)
    local actualCornerBottomLeftHeight = math.floor(cornerBottomLeftHeight * scale)
    local actualCornerBottomRightWidth = math.floor(cornerBottomRightWidth * scale)
    local actualCornerBottomRightHeight = math.floor(cornerBottomRightHeight * scale)
    
    -- calculate SideMid and Middle
    local middleWidth = width - actualCornerTopLeftWidth - actualCornerTopRightWidth
    local middleHeight = height - actualCornerTopLeftHeight - actualCornerBottomLeftHeight
    
    if middleWidth < 0 then
        local totalCornerWidth = actualCornerTopLeftWidth + actualCornerTopRightWidth
        actualCornerTopLeftWidth = math.floor(width * (actualCornerTopLeftWidth / totalCornerWidth))
        actualCornerTopRightWidth = width - actualCornerTopLeftWidth
        actualCornerBottomLeftWidth = actualCornerTopLeftWidth
        actualCornerBottomRightWidth = actualCornerTopRightWidth
        middleWidth = 0
    end
    
    if middleHeight < 0 then
        local totalCornerHeight = actualCornerTopLeftHeight + actualCornerBottomLeftHeight
        actualCornerTopLeftHeight = math.floor(height * (actualCornerTopLeftHeight / totalCornerHeight))
        actualCornerBottomLeftHeight = height - actualCornerTopLeftHeight
        actualCornerTopRightHeight = actualCornerTopLeftHeight
        actualCornerBottomRightHeight = actualCornerBottomLeftHeight
        middleHeight = 0
    end
    
    -- Four Corner
    panel:drawTextureScaled(textures.topLeft, x, y, 
                           actualCornerTopLeftWidth, actualCornerTopLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.topRight, 
                           x + width - actualCornerTopRightWidth, y, 
                           actualCornerTopRightWidth, actualCornerTopRightHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomLeft, 
                           x, y + height - actualCornerBottomLeftHeight, 
                           actualCornerBottomLeftWidth, actualCornerBottomLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomRight, 
                           x + width - actualCornerBottomRightWidth, y + height - actualCornerBottomRightHeight, 
                           actualCornerBottomRightWidth, actualCornerBottomRightHeight, 
                           alpha, r, g, b)
    
    if middleWidth > 0 then
        -- TOP MID
        panel:drawTextureScaled(textures.top, 
                               x + actualCornerTopLeftWidth, y, 
                               middleWidth, actualCornerTopLeftHeight, 
                               alpha, r, g, b)
        
        -- BOTTOM MID
        panel:drawTextureScaled(textures.bottom, 
                               x + actualCornerBottomLeftWidth, y + height - actualCornerBottomLeftHeight, 
                               middleWidth, actualCornerBottomLeftHeight, 
                               alpha, r, g, b)
    end
    
    if middleHeight > 0 then
        -- LEFT MID
        panel:drawTextureScaled(textures.left, 
                               x, y + actualCornerTopLeftHeight, 
                               actualCornerTopLeftWidth, middleHeight, 
                               alpha, r, g, b)
        
        -- RIGHT MID
        panel:drawTextureScaled(textures.right, 
                               x + width - actualCornerTopRightWidth, y + actualCornerTopRightHeight, 
                               actualCornerTopRightWidth, middleHeight, 
                               alpha, r, g, b)
    end
    
    -- MIDDLE
    if middleWidth > 0 and middleHeight > 0 then
        panel:drawTextureScaled(textures.middle, 
                               x + actualCornerTopLeftWidth, y + actualCornerTopLeftHeight, 
                               middleWidth, middleHeight, 
                               alpha, r, g, b)
    end
end

return NeatTool.NinePatch