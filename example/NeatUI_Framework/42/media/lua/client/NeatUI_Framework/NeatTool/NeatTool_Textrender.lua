NeatTool = NeatTool or {}

--[[ ----------------------------------------- --
Note: I do this only because the number font in some languages messed up in PZ (Such as CN)
-- ----------------------------------------- ]]--

function NeatTool.getNumberTexture(char, useOutline)
    if char >= "0" and char <= "9" then
        if useOutline then
            return getTexture("media/ui/NeatUI/numbers_outline/" .. char .. ".png")
        else
            return getTexture("media/ui/NeatUI/numbers/" .. char .. ".png")
        end
    end
    
    if useOutline then
        if char == "M" then
            return getTexture("media/ui/NeatUI/numbers_outline/M.png")
        elseif char == "L" then
            return getTexture("media/ui/NeatUI/numbers_outline/L.png")
        elseif char == "/" then
            return getTexture("media/ui/NeatUI/numbers_outline/Slash.png")
        elseif char == "?" then
            return getTexture("media/ui/NeatUI/numbers_outline/Query.png")
        elseif char == ":" then
            return getTexture("media/ui/NeatUI/numbers_outline/Colon.png")
        elseif char == "." then
            return getTexture("media/ui/NeatUI/numbers_outline/dot.png")
        elseif char == "S" then
            return getTexture("media/ui/NeatUI/numbers_outline/S.png")
        elseif char == "M" then
            return getTexture("media/ui/NeatUI/numbers_outline/M.png")
        elseif char == "L" then
            return getTexture("media/ui/NeatUI/numbers_outline/L.png")
        end
    end
    
    return nil
end

function NeatTool.measureTextWidth(text, size, useOutline)
    local totalWidth = 0
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local texture = NeatTool.getNumberTexture(char, useOutline)
        
        if texture then
            local charWidth = texture:getWidth()
            local charHeight = texture:getHeight()
            local scale = size / charHeight
            totalWidth = totalWidth + (charWidth * scale)
        end
    end
    
    return totalWidth
end

function NeatTool.renderText(panel, text, x, y, size, alpha, r, g, b, useOutline)
    local currentX = x
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local texture = NeatTool.getNumberTexture(char, useOutline)
        
        if texture then
            local charWidth = texture:getWidth()
            local charHeight = texture:getHeight()

            local scale = size / charHeight
            local scaledWidth = charWidth * scale

            panel:drawTextureScaled(
                texture, 
                currentX, 
                y, 
                scaledWidth, 
                size,
                alpha, r, g, b
            )
            
            currentX = currentX + scaledWidth
        end
    end
    
    return currentX - x
end