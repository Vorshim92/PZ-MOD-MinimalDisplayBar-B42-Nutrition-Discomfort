StatusWidget = {}
StatusWidget.indicators = {}
StatusWidget.globalControls = {}
StatusWidget.hasActiveAnimations = false

-- ---------------------------------------------------------------------------------------- --
-- Create UI
-- ---------------------------------------------------------------------------------------- --
function StatusWidget.createUI(playerIndex, player)
    if not player:isLocalPlayer() then
        return
    end
    
    if not StatusWidget.indicators[playerIndex] then
        StatusWidget.indicators[playerIndex] = {}
    end
    
    local function createIndicator(name, indicatorType)
        local config = MSConfig.getIndicatorConfig(playerIndex, indicatorType)
        
        local width, height
        if config.style == "bar" then
            width = config.barSize.width
            height = config.barSize.height
        else
            width = config.circularSize
            height = config.circularSize
        end
        
        local x = config.position.x
        local y = config.position.y
        
        local indicator = nil
        if indicatorType == "MS_ThirstIndicator" then
            indicator = MS_ThirstIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_HungerIndicator" then
            indicator = MS_HungerIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_EnduranceIndicator" then
            indicator = MS_EnduranceIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_FatigueIndicator" then
            indicator = MS_FatigueIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_StressIndicator" then
            indicator = MS_StressIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_PanicIndicator" then
            indicator = MS_PanicIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_TemperatureIndicator" then
            indicator = MS_TemperatureIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_HealthIndicator" then
            indicator = MS_HealthIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_BoredomIndicator" then
            indicator = MS_BoredomIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_UnhappynessIndicator" then
            indicator = MS_UnhappynessIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_DiscomfortIndicator" then
            indicator = MS_DiscomfortIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_SicknessIndicator" then
            indicator = MS_SicknessIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_CalorieIndicator" then
            indicator = MS_CalorieIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_PainIndicator" then
            indicator = MS_PainIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_CarryWeightIndicator" then
            indicator = MS_CarryWeightIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_ProteinsIndicator" then
            indicator = MS_ProteinsIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_CarbohydratesIndicator" then
            indicator = MS_CarbohydratesIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_LipidsIndicator" then
            indicator = MS_LipidsIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_WeightIndicator" then
            indicator = MS_WeightIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_MedicineIndicator" then
            indicator = MS_MedicineIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_DirtinessIndicator" then
            indicator = MS_DirtinessIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_AngerIndicator" then
            indicator = MS_AngerIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_WetnessIndicator" then
            indicator = MS_WetnessIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_DrunkennessIndicator" then
            indicator = MS_DrunkennessIndicator:new(x, y, width, height, player)
        elseif indicatorType == "MS_StiffnessIndicator" then
            indicator = MS_StiffnessIndicator:new(x, y, width, height, player)
        end
        
        if indicator then
            indicator:initialise()
            indicator:addToUIManager()
            StatusWidget.indicators[playerIndex][name] = indicator
        end
        
        return indicator
    end

    createIndicator("health", "MS_HealthIndicator")
    createIndicator("thirst", "MS_ThirstIndicator")
    createIndicator("hunger", "MS_HungerIndicator")
    createIndicator("endurance", "MS_EnduranceIndicator")
    createIndicator("fatigue", "MS_FatigueIndicator")
    createIndicator("panic", "MS_PanicIndicator")
    createIndicator("stress", "MS_StressIndicator")
    createIndicator("temperature", "MS_TemperatureIndicator")
    createIndicator("boredom", "MS_BoredomIndicator")
    createIndicator("unhappyness", "MS_UnhappynessIndicator")
    createIndicator("discomfort", "MS_DiscomfortIndicator")
    createIndicator("sickness", "MS_SicknessIndicator")
    createIndicator("calorie", "MS_CalorieIndicator")
    createIndicator("pain", "MS_PainIndicator")
    createIndicator("carryWeight", "MS_CarryWeightIndicator")
    createIndicator("proteins", "MS_ProteinsIndicator")
    createIndicator("carbohydrates", "MS_CarbohydratesIndicator")
    createIndicator("lipids", "MS_LipidsIndicator")
    createIndicator("weight", "MS_WeightIndicator")
    createIndicator("medicine", "MS_MedicineIndicator")
    createIndicator("dirtiness", "MS_DirtinessIndicator")
    createIndicator("anger", "MS_AngerIndicator")
    createIndicator("wetness", "MS_WetnessIndicator")
    createIndicator("drunkenness", "MS_DrunkennessIndicator")
    createIndicator("stiffness", "MS_StiffnessIndicator")

    local controlConfig = MSConfig.getGlobalConfig(playerIndex)
    local controlX = controlConfig.controlPosition and controlConfig.controlPosition.x or 10
    local controlY = controlConfig.controlPosition and controlConfig.controlPosition.y or 10
    local controlSize = 32

    local globalControl = MS_GlobalControlPanel:new(controlX, controlY, controlSize, controlSize, player, playerIndex)
    globalControl:initialise()
    globalControl:addToUIManager()
    StatusWidget.globalControls[playerIndex] = globalControl
end

-- ---------------------------------------------------------------------------------------- --
-- Animations
-- ---------------------------------------------------------------------------------------- --
local function updateAnimations()
    if not StatusWidget.hasActiveAnimations then return end
    
    StatusWidget.hasActiveAnimations = false
    for playerIndex, indicators in pairs(StatusWidget.indicators) do
        for _, indicator in pairs(indicators) do
            if not indicator.hidden and indicator:isVisible() then
                local delta = 1/30
                
                if indicator.iconAnimActive then
                    indicator:updateIconAnimation(delta)
                    StatusWidget.hasActiveAnimations = true
                end
                
                if indicator.barAnimActive then
                    indicator:updateBarAnimation(delta)
                    StatusWidget.hasActiveAnimations = true
                end

                if indicator.iconSwayActive then
                    indicator:updateIconSwayAnimation(delta)
                    StatusWidget.hasActiveAnimations = true
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- onPlayerDeath remove ui
-- ---------------------------------------------------------------------------------------- --
function StatusWidget.onPlayerDeath(player)
    if not player:isLocalPlayer() then return end
    
    local playerIndex = player:getPlayerNum()

    if not StatusWidget.indicators[playerIndex] then return end

    for name, indicator in pairs(StatusWidget.indicators[playerIndex]) do
        indicator:removeFromUIManager()
    end

    StatusWidget.indicators[playerIndex] = {}
 
    if StatusWidget.globalControls[playerIndex] then
        StatusWidget.globalControls[playerIndex]:removeFromUIManager()
        StatusWidget.globalControls[playerIndex] = nil
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Events
-- ---------------------------------------------------------------------------------------- --
Events.OnPlayerDeath.Add(StatusWidget.onPlayerDeath)
Events.OnTick.Add(updateAnimations)
Events.OnCreatePlayer.Add(function(playerIndex, player)
    StatusWidget.createUI(playerIndex, player)
end)
