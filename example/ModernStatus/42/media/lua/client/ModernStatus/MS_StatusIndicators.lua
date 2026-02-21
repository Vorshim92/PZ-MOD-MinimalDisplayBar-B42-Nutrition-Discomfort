require "ModernStatus/MS_StatusIndicator"

MS_ThirstIndicator = MS_StatusIndicator:derive("MS_ThirstIndicator")

function MS_ThirstIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_Thirst"
    o.__type = "MS_ThirstIndicator"
    return o
end

function MS_ThirstIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Thirst(self.player)
    end
    return 1
end

-- ---------------------------------------------------------------------------------------- --
-- Hunger Status
-- ---------------------------------------------------------------------------------------- --
MS_HungerIndicator = MS_StatusIndicator:derive("MS_HungerIndicator")

function MS_HungerIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_Hunger"
    o.__type = "MS_HungerIndicator"
    return o
end

function MS_HungerIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Hunger(self.player)
    end
    return 1
end

-- ---------------------------------------------------------------------------------------- --
-- Endurance Status
-- ---------------------------------------------------------------------------------------- --
MS_EnduranceIndicator = MS_StatusIndicator:derive("MS_EnduranceIndicator")

function MS_EnduranceIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_DifficultyBreathing"
    o.__type = "MS_EnduranceIndicator"
    return o
end

function MS_EnduranceIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Endurance(self.player)
    end
    return 1
end

-- ---------------------------------------------------------------------------------------- --
-- Fatigue Status
-- ---------------------------------------------------------------------------------------- --
MS_FatigueIndicator = MS_StatusIndicator:derive("MS_FatigueIndicator")

function MS_FatigueIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Sleepy"
    o.__type = "MS_FatigueIndicator"
    return o
end

function MS_FatigueIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Fatigue(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Stress Status
-- ---------------------------------------------------------------------------------------- --
MS_StressIndicator = MS_StatusIndicator:derive("MS_StressIndicator")

function MS_StressIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Stressed"
    o.__type = "MS_StressIndicator"
    return o
end

function MS_StressIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Stress(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Panic Status
-- ---------------------------------------------------------------------------------------- --
MS_PanicIndicator = MS_StatusIndicator:derive("MS_PanicIndicator")

function MS_PanicIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Panicked"
    o.__type = "MS_PanicIndicator"
    return o
end

function MS_PanicIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Panic(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Temperature Status
-- ---------------------------------------------------------------------------------------- --
MS_TemperatureIndicator = MS_StatusIndicator:derive("MS_TemperatureIndicator")

function MS_TemperatureIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "temperature_icon"
    o.useGradient = true
    o.__type = "MS_TemperatureIndicator"
    return o
end

function MS_TemperatureIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Temperature(self.player)
    end
    return 0.5
end

function MS_TemperatureIndicator:getHoverText(value)
    local actualTemp = self.player:getStats():get(CharacterStat.TEMPERATURE)
    return string.format("%.1f", actualTemp)
end

-- ---------------------------------------------------------------------------------------- --
-- Health Status
-- ---------------------------------------------------------------------------------------- --
MS_HealthIndicator = MS_StatusIndicator:derive("MS_HealthIndicator")

function MS_HealthIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "health_icon"
    o.__type = "MS_HealthIndicator"
    return o
end

function MS_HealthIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Health(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Boredom Status
-- ---------------------------------------------------------------------------------------- --
MS_BoredomIndicator = MS_StatusIndicator:derive("MS_BoredomIndicator")

function MS_BoredomIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Bored"
    o.__type = "MS_BoredomIndicator"
    return o
end

function MS_BoredomIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.BoredomLevel(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Unhappyness Status
-- ---------------------------------------------------------------------------------------- --
MS_UnhappynessIndicator = MS_StatusIndicator:derive("MS_UnhappynessIndicator")

function MS_UnhappynessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Sad"
    o.__type = "MS_UnhappynessIndicator"
    return o
end

function MS_UnhappynessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.UnhappynessLevel(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Discomfort Status
-- ---------------------------------------------------------------------------------------- --
MS_DiscomfortIndicator = MS_StatusIndicator:derive("MS_DiscomfortIndicator")

function MS_DiscomfortIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Discomfort"
    o.__type = "MS_DiscomfortIndicator"
    return o
end

function MS_DiscomfortIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.DiscomfortLevel(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Sickness Status
-- ---------------------------------------------------------------------------------------- --
MS_SicknessIndicator = MS_StatusIndicator:derive("MS_SicknessIndicator")

function MS_SicknessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Nauseous"
    o.__type = "MS_SicknessIndicator"
    return o
end

function MS_SicknessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Sickness(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Calorie Status
-- ---------------------------------------------------------------------------------------- --
MS_CalorieIndicator = MS_StatusIndicator:derive("MS_CalorieIndicator")

function MS_CalorieIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "calorie_icon"
    o.__type = "MS_CalorieIndicator"
    return o
end

function MS_CalorieIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Calorie(self.player)
    end
    return 1
end

function MS_CalorieIndicator:getHoverText(value)
    local actualCalories = self.player:getNutrition():getCalories()
    return string.format("%d", math.floor(actualCalories))
end

-- ---------------------------------------------------------------------------------------- --
-- Pain Status
-- ---------------------------------------------------------------------------------------- --
MS_PainIndicator = MS_StatusIndicator:derive("MS_PainIndicator")

function MS_PainIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Pained"
    o.__type = "MS_PainIndicator"
    return o
end

function MS_PainIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Pain(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- CarryWeight Status
-- ---------------------------------------------------------------------------------------- --
MS_CarryWeightIndicator = MS_StatusIndicator:derive("MS_CarryWeightIndicator")

function MS_CarryWeightIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_HeavyLoad"
    o.__type = "MS_CarryWeightIndicator"
    return o
end

function MS_CarryWeightIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.CarryWeight(self.player)
    end
    return 0
end

function MS_CarryWeightIndicator:getHoverText(value)
    local actualWeight = self.player:getInventory():getCapacityWeight()
    return string.format("%.1f", actualWeight)
end

-- ---------------------------------------------------------------------------------------- --
-- Proteins Status
-- ---------------------------------------------------------------------------------------- --
MS_ProteinsIndicator = MS_StatusIndicator:derive("MS_ProteinsIndicator")

function MS_ProteinsIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "proteins_icon"
    o.__type = "MS_ProteinsIndicator"
    o.indicatorColor = {r=0.7, g=0.8, b=0.4}
    return o
end

function MS_ProteinsIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Proteins(self.player)
    end
    return 0
end

function MS_ProteinsIndicator:getHoverText(value)
    local actualProteins = self.player:getNutrition():getProteins()
    return string.format("%.1f", actualProteins)
end

-- ---------------------------------------------------------------------------------------- --
-- Carbohydrates Status
-- ---------------------------------------------------------------------------------------- --
MS_CarbohydratesIndicator = MS_StatusIndicator:derive("MS_CarbohydratesIndicator")

function MS_CarbohydratesIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "carbs_icon"
    o.__type = "MS_CarbohydratesIndicator"
    o.indicatorColor = {r=0.8, g=0.6, b=0.3}
    return o
end

function MS_CarbohydratesIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Carbohydrates(self.player)
    end
    return 0
end

function MS_CarbohydratesIndicator:getHoverText(value)
    local actualCarbs = self.player:getNutrition():getCarbohydrates()
    return string.format("%.1f", actualCarbs)
end

-- ---------------------------------------------------------------------------------------- --
-- Lipids Status
-- ---------------------------------------------------------------------------------------- --
MS_LipidsIndicator = MS_StatusIndicator:derive("MS_LipidsIndicator")

function MS_LipidsIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "lipids_icon"
    o.__type = "MS_LipidsIndicator"
    o.indicatorColor = {r=0.9, g=0.8, b=0.2}
    return o
end

function MS_LipidsIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Lipids(self.player)
    end
    return 0
end

function MS_LipidsIndicator:getHoverText(value)
    local actualLipids = self.player:getNutrition():getLipids()
    return string.format("%.1f", actualLipids)
end

-- ---------------------------------------------------------------------------------------- --
-- Weight Status
-- ---------------------------------------------------------------------------------------- --
MS_WeightIndicator = MS_StatusIndicator:derive("MS_WeightIndicator")

function MS_WeightIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "weight_icon"
    o.__type = "MS_WeightIndicator"
    o.indicatorColor = {r=0.5, g=0.6, b=0.7}
    o.useGradient = true
    return o
end

function MS_WeightIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Weight(self.player)
    end
    return 0.5
end

function MS_WeightIndicator:getGradientColor(value)
    if not self.player then return {r=1, g=1, b=1} end
    
    local weight = self.player:getNutrition():getWeight()
    
    -- too heavy
    if weight > 100 then
        local factor = math.min((weight - 100) / 30, 1.0)
        return {
            r = 1.0,
            g = 0.5 - factor * 0.5,
            b = 0.0
        }
    -- a bit high
    elseif weight > 85 then
        local factor = (weight - 85) / 15
        return {
            r = 0.5 + factor * 0.5,
            g = 1.0 - factor * 0.5,
            b = 0.0
        }
    -- healty weight
    elseif weight > 75 then
        return {r=0.0, g=1.0, b=0.0}
    -- a bit low
    elseif weight > 50 then
        local factor = (weight - 50) / 25
        return {
            r = 0.0,
            g = factor,
            b = 1.0 - factor
        }
    -- too low
    else
        local factor = math.max((weight - 35) / 15, 0.0)
        return {
            r = 0.0,
            g = 0.0 + factor * 0.5,
            b = 0.5 + factor * 0.5
        }
    end
end

function MS_WeightIndicator:getHoverText(value)
    local actualWeight = self.player:getNutrition():getWeight()
    return string.format("%.1f", actualWeight)
end

-- ---------------------------------------------------------------------------------------- --
-- Dirtiness Status
-- ---------------------------------------------------------------------------------------- --
MS_DirtinessIndicator = MS_StatusIndicator:derive("MS_DirtinessIndicator")

function MS_DirtinessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_Dirty"
    o.__type = "MS_DirtinessIndicator"
    o.indicatorColor = {r=0.5, g=0.4, b=0.3}
    return o
end

function MS_DirtinessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Dirtiness(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Anger Status
-- ---------------------------------------------------------------------------------------- --
MS_AngerIndicator = MS_StatusIndicator:derive("MS_AngerIndicator")

function MS_AngerIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Angry"
    o.__type = "MS_AngerIndicator"
    o.indicatorColor = {r=1, g=0.1, b=0.1}
    return o
end

function MS_AngerIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Anger(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Wetness Status
-- ---------------------------------------------------------------------------------------- --
MS_WetnessIndicator = MS_StatusIndicator:derive("MS_WetnessIndicator")

function MS_WetnessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_Wet"
    o.__type = "MS_WetnessIndicator"
    o.indicatorColor = {r=0.4, g=0.6, b=0.9}
    return o
end

function MS_WetnessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Wetness(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Drunkenness Status
-- ---------------------------------------------------------------------------------------- --
MS_DrunkennessIndicator = MS_StatusIndicator:derive("MS_DrunkennessIndicator")

function MS_DrunkennessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Mood_Drunk"
    o.__type = "MS_DrunkennessIndicator"
    o.indicatorColor = {r=0.8, g=0.4, b=0.6}
    return o
end

function MS_DrunkennessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Drunkenness(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Stiffness Status
-- ---------------------------------------------------------------------------------------- --
MS_StiffnessIndicator = MS_StatusIndicator:derive("MS_StiffnessIndicator")

function MS_StiffnessIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Status_Stiffness"
    o.__type = "MS_StiffnessIndicator"
    o.indicatorColor = {r=0.8, g=0.6, b=0.0}
    return o
end

function MS_StiffnessIndicator:getValue()
    if self.player and not self.player:isDead() then
        return MS_PlayerStatus.Get.Stiffness(self.player)
    end
    return 0
end

-- ---------------------------------------------------------------------------------------- --
-- Medicine Status
-- ---------------------------------------------------------------------------------------- --
MS_MedicineIndicator = MS_StatusIndicator:derive("MS_MedicineIndicator")

MS_MedicineIndicator.MEDICINE_TYPES = {
    { name = "Painkillers", getText = "IGUI_ModernStatus_Painkillers", iconName = "Painkillers", getEffect = function(player) return player:getPainEffect() / 5400 end },
    { name = "Antibiotics", getText = "IGUI_ModernStatus_Antibiotics", iconName = "Antibiotics", getEffect = function(player) return player:getReduceInfectionPower() / 50 end },
    { name = "BetaBlockers", getText = "IGUI_ModernStatus_BetaBlockers", iconName = "BetaBlockers", getEffect = function(player) return player:getBetaEffect() / 6600 end },
    { name = "Antidepressants", getText = "IGUI_ModernStatus_Antidepressants", iconName = "Antidepressants", getEffect = function(player) return player:getDepressEffect() / 6600 end },
    { name = "SleepingTablets", getText = "IGUI_ModernStatus_SleepingTablets", iconName = "SleepingTablets", getEffect = function(player) return player:getSleepingTabletEffect() / 6600 end }
}

function MS_MedicineIndicator:new(x, y, width, height, player)
    local o = MS_StatusIndicator.new(self, x, y, width, height, player)
    o.baseIconName = "Painkillers"
    o.__type = "MS_MedicineIndicator"
    o.indicatorColor = {r=0.3, g=0.9, b=0.4}
    o.displayIndex = 1 -- Start from painkiller
    o.switchTimer = 0
    o.switchInterval = 20 -- time to change 
    return o
end

function MS_MedicineIndicator:update()
    self.switchTimer = self.switchTimer + (1/30)

    if self.switchTimer >= self.switchInterval then
        self.switchTimer = 0

        local hasAnyEffect = false
        local startIndex = self.displayIndex
        
        repeat
            self.displayIndex = self.displayIndex + 1
            if self.displayIndex > #self.MEDICINE_TYPES then
                self.displayIndex = 1
            end

            local effect = self.MEDICINE_TYPES[self.displayIndex].getEffect(self.player)
            if effect > 0 then
                hasAnyEffect = true
                break
            end
        until self.displayIndex == startIndex
        if not hasAnyEffect then
            self.displayIndex = 1
        end

        self:updateMedicineIcon()
    end
end

function MS_MedicineIndicator:updateMedicineIcon()
    local currentMedicine = self.MEDICINE_TYPES[self.displayIndex]
    self.baseIconName = currentMedicine.iconName
    self:updateIconPath()
end

function MS_MedicineIndicator:getValue()
    if not self.player or self.player:isDead() then return 0 end
    
    self:update()
    
    local currentMedicine = self.MEDICINE_TYPES[self.displayIndex]
    return currentMedicine.getEffect(self.player)
end

return MS_StatusIndicator