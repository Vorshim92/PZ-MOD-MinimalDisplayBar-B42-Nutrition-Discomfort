NeatTool = NeatTool or {}

function NeatTool.truncateText(text, maxWidth, font, suffix)
    if not text or text == "" then
        return ""
    end

    font = font or UIFont.Small
    suffix = suffix or "..."
    
    local originalWidth = getTextManager():MeasureStringX(font, text)

    if originalWidth <= maxWidth then
        return text
    end

    local suffixWidth = getTextManager():MeasureStringX(font, suffix)

    if suffixWidth >= maxWidth then
        return ""
    end

    local textMaxWidth = maxWidth - suffixWidth

    local left = 1
    local right = string.len(text)
    local bestLength = 0
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        local truncatedText = string.sub(text, 1, mid)
        local truncatedWidth = getTextManager():MeasureStringX(font, truncatedText)
        
        if truncatedWidth <= textMaxWidth then
            bestLength = mid
            left = mid + 1
        else
            right = mid - 1
        end
    end

    if bestLength == 0 then
        return suffix
    end

    local finalText = string.sub(text, 1, bestLength)
    return finalText .. suffix
end