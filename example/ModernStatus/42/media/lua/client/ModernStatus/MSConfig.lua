MSConfig = {}
MSConfig.configCache = {}
MSConfig.globalConfigCache = {}

-- ---------------------------------------------------------------------------------------- --
-- serializeTable
-- ---------------------------------------------------------------------------------------- --
function MSConfig.serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep("    ", depth)

    if name then 
        tmp = tmp .. name .. " = "
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. MSConfig.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep("    ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[" .. type(val) .. "]\""
    end

    return tmp
end

function MSConfig.saveConfig(config, playerNum)
    if playerNum == nil or playerNum == 0 then playerNum = "" end
    playerNum = tostring(playerNum)

    local file = getFileWriter("ModernStatusConfig"..playerNum..".lua", true, false)
    if file == nil then return nil end

    local contents = "return " .. MSConfig.serializeTable(config)
    file:write(contents)
    file:close()
end

function MSConfig.loadConfig(playerNum)
    if playerNum == nil or playerNum == 0 then playerNum = "" end
    playerNum = tostring(playerNum)

    local file = getFileReader("ModernStatusConfig"..playerNum..".lua", true)
    if file == nil then return nil end

    local content = ""
    local line = file:readLine()
    while line do
        content = content .. line .. "\n"
        line = file:readLine()
    end
    file:close()
    
    if content == "" then return nil end
    
    local fn, errorMsg = loadstring(content)
    if fn then
        local config = fn()
        return config
    else
        return nil
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Defaul Config
-- ---------------------------------------------------------------------------------------- --
function MSConfig.getDefaultIndicatorConfig(indicatorType)
    local defaultWidth = 168
    local defaultHeight = 18
    local defaultCircularSize = 48
    local defaultStyle = "circular"
    local defaultColor = {r=1, g=1, b=1}
    
    local posX = 64
    local posY = 64
    
    -- 第一列 (posX=64)
    if string.find(indicatorType, "Thirst") then
        defaultColor = {r=0.55, g=0.75, b=0.85}
        posX = 64
        posY = 64
    elseif string.find(indicatorType, "Hunger") then
        defaultColor = {r=0.95, g=0.95, b=0.45}
        posX = 64
        posY = 124
    elseif string.find(indicatorType, "Endurance") then
        defaultColor = {r=0.85, g=0.85, b=0.85}
        posX = 64
        posY = 184
    elseif string.find(indicatorType, "Fatigue") then
        defaultColor = {r=0.7, g=0.65, b=0.55}
        posX = 64
        posY = 244
    elseif string.find(indicatorType, "Stress") then
        defaultColor = {r=0.6, g=0.6, b=0.6}
        posX = 64
        posY = 304
    elseif string.find(indicatorType, "Panic") then
        defaultColor = {r=0.95, g=0.65, b=0.4}
        posX = 64
        posY = 364
    elseif string.find(indicatorType, "Proteins") then
        defaultColor = {r=0.7, g=0.8, b=0.4}
        posX = 64
        posY = 424
    
    -- 第二列 (posX=124)
    elseif string.find(indicatorType, "Temperature") then
        defaultColor = {r=1.0, g=0.6, b=0.4}
        posX = 124
        posY = 64
    elseif string.find(indicatorType, "Health") then
        defaultColor = {r=1.0, g=0.6, b=0.6}
        posX = 124
        posY = 124
    elseif string.find(indicatorType, "Boredom") then
        defaultColor = {r=0.75, g=0.75, b=0.75}
        posX = 124
        posY = 184
    elseif string.find(indicatorType, "Unhappyness") then
        defaultColor = {r=0.6, g=0.6, b=0.9}
        posX = 124
        posY = 244
    elseif string.find(indicatorType, "Discomfort") then
        defaultColor = {r=0.65, g=0.65, b=0.9}
        posX = 124
        posY = 304
    elseif string.find(indicatorType, "Sickness") then
        defaultColor = {r=0.65, g=0.75, b=0.5}
        posX = 124
        posY = 364
    elseif string.find(indicatorType, "Carbohydrates") then
        defaultColor = {r=0.8, g=0.6, b=0.3}
        posX = 124
        posY = 424
    
    -- 第三列 (posX=184)
    elseif string.find(indicatorType, "Calorie") then
        defaultColor = {r=0.85, g=0.65, b=0.4}
        posX = 184
        posY = 64
    elseif string.find(indicatorType, "Pain") then
        defaultColor = {r=0.95, g=0.5, b=0.5}
        posX = 184
        posY = 124
    elseif string.find(indicatorType, "CarryWeight") then
        defaultColor = {r=0.6, g=0.4, b=0.2}
        posX = 184
        posY = 184 
    elseif string.find(indicatorType, "Lipids") then
        defaultColor = {r=0.9, g=0.8, b=0.2}
        posX = 184
        posY = 244
    elseif string.find(indicatorType, "Weight") then
        defaultColor = {r=0.0, g=1.0, b=0.0}
        posX = 184
        posY = 304
    elseif string.find(indicatorType, "Medicine") then
        defaultColor = {r=0.3, g=0.9, b=0.4}
        posX = 184
        posY = 364
    elseif string.find(indicatorType, "Dirtiness") then
        defaultColor = {r=0.5, g=0.4, b=0.3}
        posX = 184
        posY = 424

    -- 第三列 (posX=244)
    elseif string.find(indicatorType, "Anger") then
        defaultColor = {r=1, g=0.1, b=0.1}
        posX = 244
        posY = 64
    elseif string.find(indicatorType, "Wetness") then
        defaultColor = {r=0.4, g=0.6, b=0.9}
        posX = 244
        posY = 124
    elseif string.find(indicatorType, "Drunkenness") then
        defaultColor = {r=0.8, g=0.4, b=0.6}
        posX = 244
        posY = 184
    elseif string.find(indicatorType, "Stiffness") then
        defaultColor = {r=0.8, g=0.6, b=0.0}
        posX = 244
        posY = 244
    end
    
    
    local config = {
        position = {x = posX, y = posY},
        circularSize = defaultCircularSize,
        barSize = {width = defaultWidth, height = defaultHeight},
        color = defaultColor,
        opacity = 1.0,
        iconOpacity = 1.0,
        style = defaultStyle,
        isVertical = false,
        showIcon = true,
        useGradient = false,
        useMonoIcon = false,
        locked = false,
        hidden = false,
        animationThreshold = 20,
        alwaysShowValue = false,
        showName = true,
        textScale = 1.0,
        autoHide = false
    }
    
    return config
end

function MSConfig.getDefaultGlobalConfig()
    return {
        controlPosition = {x = 64, y = 18},
        multiDragMode = false,
        hideOriginalMoodles = false
    }
end

function MSConfig.createDefaultConfig(playerNum)
    local config = {
        globalSettings = MSConfig.getDefaultGlobalConfig(),
        indicators = {}
    }
    
    local indicatorTypes = {
        "MS_ThirstIndicator",
        "MS_HungerIndicator",
        "MS_EnduranceIndicator", 
        "MS_FatigueIndicator",
        "MS_StressIndicator",
        "MS_PanicIndicator",
        "MS_TemperatureIndicator",
        "MS_HealthIndicator",
        "MS_BoredomIndicator",
        "MS_UnhappynessIndicator",
        "MS_DiscomfortIndicator",
        "MS_SicknessIndicator",
        "MS_PainIndicator",
        "MS_CarryWeightIndicator",
        "MS_CalorieIndicator",
        "MS_ProteinsIndicator",
        "MS_CarbohydratesIndicator",
        "MS_LipidsIndicator",
        "MS_WeightIndicator",
        "MS_MedicineIndicator",
        "MS_DirtinessIndicator",
        "MS_AngerIndicator",
        "MS_StiffnessIndicator",
    }
    
    for _, indicatorType in ipairs(indicatorTypes) do
        config.indicators[indicatorType] = MSConfig.getDefaultIndicatorConfig(indicatorType)
    end
    
    return config
end

-- ---------------------------------------------------------------------------------------- --
-- Config update &Access
-- ---------------------------------------------------------------------------------------- --
function MSConfig.getIndicatorConfig(playerNum, indicatorType)
    local cacheKey = tostring(playerNum) .. "_" .. indicatorType
    
    if MSConfig.configCache[cacheKey] then
        return MSConfig.configCache[cacheKey]
    end
    
    local config = MSConfig.loadConfig(playerNum)
    
    if not config then
        config = MSConfig.createDefaultConfig(playerNum)
        MSConfig.saveConfig(config, playerNum)
    end
    
    if not config.indicators[indicatorType] then
        config.indicators[indicatorType] = MSConfig.getDefaultIndicatorConfig(indicatorType)
        MSConfig.saveConfig(config, playerNum)
    end
    
    MSConfig.configCache[cacheKey] = config.indicators[indicatorType]
    
    return config.indicators[indicatorType]
end

function MSConfig.updateIndicatorConfig(playerNum, indicatorType, key, value)
    local cacheKey = tostring(playerNum) .. "_" .. indicatorType
    MSConfig.configCache[cacheKey] = nil

    local config = MSConfig.loadConfig(playerNum)
    
    if not config then
        config = MSConfig.createDefaultConfig(playerNum)
    end
    
    if not config.indicators[indicatorType] then
        config.indicators[indicatorType] = MSConfig.getDefaultIndicatorConfig(indicatorType)
    end
    
    config.indicators[indicatorType][key] = value
    MSConfig.saveConfig(config, playerNum)
end

function MSConfig.getGlobalConfig(playerNum)
    local cacheKey = tostring(playerNum) .. "_global"

    if MSConfig.globalConfigCache[cacheKey] then
        return MSConfig.globalConfigCache[cacheKey]
    end
    
    local config = MSConfig.loadConfig(playerNum)
    
    if not config or not config.globalSettings then
        config = MSConfig.createDefaultConfig(playerNum)
        MSConfig.saveConfig(config, playerNum)
    end

    MSConfig.globalConfigCache[cacheKey] = config.globalSettings
    
    return config.globalSettings
end

function MSConfig.updateGlobalConfig(playerNum, key, value)
    local cacheKey = tostring(playerNum) .. "_global"
    MSConfig.globalConfigCache[cacheKey] = nil
    
    local config = MSConfig.loadConfig(playerNum)
    
    if not config then
        config = MSConfig.createDefaultConfig(playerNum)
    end
    
    if not config.globalSettings then
        config.globalSettings = MSConfig.getDefaultGlobalConfig()
    end
    
    config.globalSettings[key] = value
    MSConfig.saveConfig(config, playerNum)
end

return MSConfig