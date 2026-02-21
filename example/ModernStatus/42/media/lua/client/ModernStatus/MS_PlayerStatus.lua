MS_PlayerStatus = {}
MS_PlayerStatus.Traits = {
    highIsBetter = {
        ["MS_EnduranceIndicator"] = true,      -- Endurance
        ["MS_HealthIndicator"] = true,         -- Health
        ["MS_HungerIndicator"] = true,         -- SHunger
        ["MS_CalorieIndicator"] = true,        -- Calorie
        ["MS_LipidsIndicator"] = true,         -- Lipids
        ["MS_ProteinsIndicator"] = true,       -- Proteins
        ["MS_ThirstIndicator"] = true,         -- Thirst
        ["MS_CarbohydratesIndicator"] = true,  -- Carbohydrates
        ["MS_MedicineIndicator"] = true,  -- Medicine
        ["MS_StiffnessIndicator"] = false,      -- Stiffness

    }
}
MS_PlayerStatus.isHigherBetter = function(indicatorType)
    return MS_PlayerStatus.Traits.highIsBetter[indicatorType] == true
end

-- ---------------------------------------------------------------------------------------- --
-- CalcStatus
-- ---------------------------------------------------------------------------------------- --
MS_PlayerStatus.Calc = {}

MS_PlayerStatus.Calc.Thirst = function(value)
    return 1 - value
end

MS_PlayerStatus.Calc.Hunger = function(value)
    return 1 - value
end

MS_PlayerStatus.Calc.Endurance = function(value)
    return value
end

MS_PlayerStatus.Calc.Fatigue = function(value)
    return value
end

MS_PlayerStatus.Calc.Temperature = function(value)
    local maxTempLim = 42
    local minTempLim = 20
    return (value - minTempLim) / (maxTempLim - minTempLim)
end

MS_PlayerStatus.Calc.Panic = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Stress = function(value)
    if value > 1 then value = 1 end
    return value
end

MS_PlayerStatus.Calc.BoredomLevel = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.UnhappynessLevel = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.DiscomfortLevel = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Health = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Sickness = function(value)
    return value
end

MS_PlayerStatus.Calc.ColdStrength = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Calorie = function(value)
    local maxCalorie = 3700
    local minCalorie = -2200
    return (value - minCalorie) / (maxCalorie - minCalorie)
end

MS_PlayerStatus.Calc.Pain = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.CarryWeight = function(value)
    local maxWeight = 50 
    return value / maxWeight
end

MS_PlayerStatus.Calc.Proteins = function(value)
    return (value + 500) / 1500
end

MS_PlayerStatus.Calc.Carbohydrates = function(value)
    return (value + 500) / 1500
end

MS_PlayerStatus.Calc.Lipids = function(value)
    return (value + 500) / 1500
end

MS_PlayerStatus.Calc.Weight = function(value)
    local maxWeight = 130
    local minWeight = 35
    return (value - minWeight) / (maxWeight - minWeight)
end

MS_PlayerStatus.Calc.Dirtiness = function(value)
    return value
end

MS_PlayerStatus.Calc.Anger = function(value)
    return value
end

MS_PlayerStatus.Calc.Wetness = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Drunkenness = function(value)
    return value / 100
end

MS_PlayerStatus.Calc.Stiffness = function(value)
    return value / 100
end

-- ---------------------------------------------------------------------------------------- --
-- GetStatus
-- ---------------------------------------------------------------------------------------- --
MS_PlayerStatus.Get = {}

MS_PlayerStatus.Get.Thirst = function(player)
    if player:isDead() then
        return -1
    else
        return math.max(0, math.min(1, MS_PlayerStatus.Calc.Thirst(player:getStats():get(CharacterStat.THIRST))))
    end
end

MS_PlayerStatus.Get.Hunger = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Hunger(player:getStats():get(CharacterStat.HUNGER))
    end
end

MS_PlayerStatus.Get.Endurance = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Endurance(player:getStats():get(CharacterStat.ENDURANCE))
    end
end

MS_PlayerStatus.Get.Fatigue = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Fatigue(player:getStats():get(CharacterStat.FATIGUE))
    end
end

MS_PlayerStatus.Get.Temperature = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Temperature(player:getStats():get(CharacterStat.TEMPERATURE))
    end
end

MS_PlayerStatus.Get.Panic = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Panic(player:getStats():get(CharacterStat.PANIC))
    end
end

MS_PlayerStatus.Get.Stress = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Stress(player:getStats():getNicotineStress())
    end
end

MS_PlayerStatus.Get.BoredomLevel = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.BoredomLevel(player:getStats():get(CharacterStat.BOREDOM))
    end
end

MS_PlayerStatus.Get.UnhappynessLevel = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.UnhappynessLevel(player:getStats():get(CharacterStat.UNHAPPINESS))
    end
end

MS_PlayerStatus.Get.DiscomfortLevel = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.DiscomfortLevel(player:getStats():get(CharacterStat.DISCOMFORT))
    end
end

MS_PlayerStatus.Get.Health = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Health(player:getBodyDamage():getHealth())
    end
end

MS_PlayerStatus.Get.Sickness = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Sickness(player:getBodyDamage():getApparentInfectionLevel()/100 + player:getStats():get(CharacterStat.SICKNESS))
    end
end

MS_PlayerStatus.Get.Calorie = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Calorie(player:getNutrition():getCalories())
    end
end

MS_PlayerStatus.Get.Pain = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Pain(player:getStats():get(CharacterStat.PAIN))
    end
end

MS_PlayerStatus.Get.CarryWeight = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.CarryWeight(player:getInventory():getCapacityWeight())
    end
end

MS_PlayerStatus.Get.Proteins = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Proteins(player:getNutrition():getProteins())
    end
end

MS_PlayerStatus.Get.Carbohydrates = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Carbohydrates(player:getNutrition():getCarbohydrates())
    end
end

MS_PlayerStatus.Get.Lipids = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Lipids(player:getNutrition():getLipids())
    end
end

MS_PlayerStatus.Get.Weight = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Weight(player:getNutrition():getWeight())
    end
end

MS_PlayerStatus.Get.Dirtiness = function(player)
    if player:isDead() then
        return -1
    else
        local visual = player:getHumanVisual()
        local v = 0
        for i = 1, BloodBodyPartType.MAX:index() do
            local part = BloodBodyPartType.FromIndex(i - 1)
            v = v + visual:getBlood(part) + visual:getDirt(part)
        end
        return v / (BloodBodyPartType.MAX:index() * 2)
    end
end

MS_PlayerStatus.Get.Anger = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Anger(player:getStats():get(CharacterStat.ANGER))
    end
end

MS_PlayerStatus.Get.Wetness = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Wetness(player:getStats():get(CharacterStat.WETNESS))
    end
end

MS_PlayerStatus.Get.Drunkenness = function(player)
    if player:isDead() then
        return -1
    else
        return MS_PlayerStatus.Calc.Drunkenness(player:getStats():get(CharacterStat.INTOXICATION))
    end
end

MS_PlayerStatus.Get.Stiffness = function(player)
    if player:isDead() then
        return -1
    else
        -- only cout the Stiffness part
        local bodyDamage = player:getBodyDamage()
        local bodyParts = bodyDamage:getBodyParts()
        local totalStiffness = 0
        local stiffPartsCount = 0
        
        for i=0, bodyParts:size()-1 do
            local bodyPart = bodyParts:get(i)
            local stiffness = bodyPart:getStiffness()
            if stiffness > 0 then
                totalStiffness = totalStiffness + stiffness
                stiffPartsCount = stiffPartsCount + 1
            end
        end
        
        local avgStiffness = 0
        if stiffPartsCount > 0 then
            avgStiffness = totalStiffness / stiffPartsCount
        end
        
        return MS_PlayerStatus.Calc.Stiffness(avgStiffness)
    end
end

return MS_PlayerStatus