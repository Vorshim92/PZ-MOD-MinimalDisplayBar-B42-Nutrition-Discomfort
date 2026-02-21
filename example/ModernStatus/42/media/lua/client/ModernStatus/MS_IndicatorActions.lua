MS_IndicatorActions = {}

MS_IndicatorActions.onDoubleClick = function(indicator)
    local player = indicator.player
    if not player or player:isDead() then return end
    
    local indicatorType = indicator:getType()
    local inventory = player:getInventory()
    local bodyDamage = player:getBodyDamage()
    local playerNum = indicator.playerIndex

    if indicatorType == "MS_ThirstIndicator" then
        MS_IndicatorActions.handleThirst(player, inventory)
    elseif indicatorType == "MS_HungerIndicator" then
        MS_IndicatorActions.handleHunger(player, inventory, playerNum)
    elseif indicatorType == "MS_EnduranceIndicator" then
        MS_IndicatorActions.handleEndurance(player)
    elseif indicatorType == "MS_FatigueIndicator" then
        MS_IndicatorActions.handleFatigue(player, inventory, playerNum)
    elseif indicatorType == "MS_PanicIndicator" then
        MS_IndicatorActions.handlePanic(player, inventory, playerNum)
    elseif indicatorType == "MS_HealthIndicator" then
        MS_IndicatorActions.handleHealth(player, inventory, bodyDamage, playerNum)
    elseif indicatorType == "MS_SicknessIndicator" then
        MS_IndicatorActions.handleSickness(player, inventory, playerNum)
    elseif indicatorType == "MS_PainIndicator" then
        MS_IndicatorActions.handlePain(player, inventory, playerNum)
    elseif indicatorType == "MS_CalorieIndicator" then
        MS_IndicatorActions.handleCalorie(player, inventory, playerNum)
    elseif indicatorType == "MS_ProteinsIndicator" then
        MS_IndicatorActions.handleProteins(player, inventory, playerNum)
    elseif indicatorType == "MS_LipidsIndicator" then
        MS_IndicatorActions.handleLipids(player, inventory, playerNum)
    elseif indicatorType == "MS_UnhappynessIndicator" then
        MS_IndicatorActions.handleUnhappyness(player, inventory, playerNum)
    end
end

-- ------------------------------------------- --
-- Thirst -- Drink Function
-- ------------------------------------------- --
MS_IndicatorActions.handleThirst = function(player, inventory)
    local thirst = player:getStats():get(CharacterStat.THIRST)
    if thirst <= 0 then return end
    
    local item = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalDrinkableItems)
    if item then
        local fluidContainer = item:getFluidContainer()
        local amountThirst = math.abs(fluidContainer:getProperties():getThirstChange())
        local drinkRatio = 1 
        if amountThirst > 0 then
            local ratioForThirst = thirst/amountThirst
            if ratioForThirst < 1 then
                drinkRatio = ratioForThirst
            end
        end
        local baseThirst = fluidContainer:getAmount()/fluidContainer:getCapacity()
        if drinkRatio == 1 and baseThirst >= 0.5 then
            if thirst < 0.3 then
                drinkRatio = 0.5
            elseif thirst < 0.15 and baseThirst >= 0.25 then
                drinkRatio = 0.25
            end
        end
        ISInventoryPaneContextMenu.onDrinkFluid(item, drinkRatio, player)
    end
end

MS_IndicatorActions.evalDrinkableItems = function(item)
    if not item:getFluidContainer() then return false end
    local fluidContainer = item:getFluidContainer()
    if fluidContainer:isEmpty() then return false end
    if not fluidContainer:canPlayerEmpty() then return false end
    if fluidContainer:isPoisonous() then return false end
    if fluidContainer:isCategory(FluidCategory.Alcoholic) then return false end
    if fluidContainer:getCapacity() > 3.0 then return false end
    local thirstChange = fluidContainer:getProperties():getThirstChange()
    if thirstChange >= 0 then return false end
    if fluidContainer:getAmount() <= 0 then return false end
    if item:isFavorite() then return false end
    
    return true
end

-- ------------------------------------------- --
-- Eat Function
-- ------------------------------------------- --
MS_IndicatorActions.handleEating = function(player, inventory, playerNum)
    local hunger = player:getStats():get(CharacterStat.HUNGER)
    if player:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 then 
        return 
    end
    
    local item = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalFoodItems)
    if item then
        local hungerChange = item:getHungerChange()
        local hungerReduction = math.abs(hungerChange)
        local eatRatio = 1
        
        if hungerReduction > 0 then
            eatRatio = hunger / hungerReduction

            if eatRatio > 1 then
                eatRatio = 1
            elseif eatRatio < 0.1 then
                eatRatio = 0.1
            end
        end
        ISInventoryPaneContextMenu.onEatItems({item}, eatRatio, playerNum)
    end
end

MS_IndicatorActions.evalFoodItems = function(item)
    if not item:IsFood() then return false end
    local scriptItem = item:getScriptItem()
    if scriptItem:isCantEat() then return false end
    if item:getHungerChange() >= 0 then return false end
    if item:isAlcoholic() then return false end
    if item:isSpice() then return false end
    if item:isTainted() then return false end
    if item:isRotten() then return false end
    if item:isCookable() and item:isbDangerousUncooked() and not item:isCooked() then return false end
    if item:isFrozen() then return false end
    if item:isBurnt() then return false end
    if item:isPoison() or item:getPoisonPower() > 0 then return false end
    if item:isFavorite() then return false end
    return true
end

-- ------------------------------------------- --
-- Calorie
-- ------------------------------------------- --
MS_IndicatorActions.handleCalorie = function(player, inventory, playerNum)
    MS_IndicatorActions.handleEating(player, inventory, playerNum)
end

-- ------------------------------------------- --
-- Proteins
-- ------------------------------------------- --
MS_IndicatorActions.handleProteins = function(player, inventory, playerNum)
    MS_IndicatorActions.handleEating(player, inventory, playerNum)
end

-- ------------------------------------------- --
-- Lipids
-- ------------------------------------------- --
MS_IndicatorActions.handleLipids = function(player, inventory, playerNum)
    MS_IndicatorActions.handleEating(player, inventory, playerNum)
end

-- ------------------------------------------- --
-- Hunger
-- ------------------------------------------- --
MS_IndicatorActions.handleHunger = function(player, inventory, playerNum)
    MS_IndicatorActions.handleEating(player, inventory, playerNum)
end

-- ------------------------------------------- --
-- Endurance -- sit down
-- ------------------------------------------- --
MS_IndicatorActions.handleEndurance = function(player)
    if not player:isSitOnGround() and not player:isSittingOnFurniture() then
        player:reportEvent("EventSitOnGround")
    end
end

-- ------------------------------------------- --
-- Fatigue
-- ------------------------------------------- --
MS_IndicatorActions.handleFatigue = function(player, inventory, playerNum)
    -- 1.Vitamins
    local item = inventory:getFirstTypeRecurse("Base.PillsVitamins")
    if item then
        ISInventoryPaneContextMenu.onPillsItems({item}, playerNum)
        return
    end

    -- 2.hotdrink
    local liquidItem = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalCoffeeOrTeaItems)
    if liquidItem then
        ISInventoryPaneContextMenu.onDrinkFluid(liquidItem, 1, player)
        return
    end

    -- 3.Teabag
    item = inventory:getFirstTypeRecurse("Base.Teabag2")
    if item then
        ISInventoryPaneContextMenu.onEatItems({item}, 1, playerNum)
        return
    end
    
    -- 4.Coffee
    item = inventory:getFirstTypeRecurse("Base.Coffee2")
    if item then
        ISInventoryPaneContextMenu.onEatItems({item}, 1, playerNum)
        return
    end
end

MS_IndicatorActions.evalCoffeeOrTeaItems = function(item)
    if not item:getFluidContainer() then return false end
    local fluidContainer = item:getFluidContainer()
    if fluidContainer:isEmpty() then return false end
    if not fluidContainer:canPlayerEmpty() then return false end
    if fluidContainer:getCapacity() > 3.0 then return false end
    if fluidContainer:getAmount() <= 0 then return false end
    if item:isFavorite() then return false end
    local primaryFluid = fluidContainer:getPrimaryFluid()
    if primaryFluid then
        local fluidType = primaryFluid:getFluidType()
        if fluidType == FluidType.Coffee or fluidType == FluidType.Tea then
            return true
        end
    end
    
    return false
end

-- ------------------------------------------- --
-- Panic
-- ------------------------------------------- --
MS_IndicatorActions.handlePanic = function(player, inventory, playerNum)
    -- 1.PillsBeta
    local item = inventory:getFirstTypeRecurse("Base.PillsBeta")
    if item then
        ISInventoryPaneContextMenu.onPillsItems({item}, playerNum)
        return
    end
    
    -- 2.Alcoholic
    local alcoholItem = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalAlcoholicItems)
    if alcoholItem then
        ISInventoryPaneContextMenu.onDrinkFluid(alcoholItem, 0.25, player)
    end
end

-- ------------------------------------------- --
-- Health -- use Bandage
-- ------------------------------------------- --
MS_IndicatorActions.handleHealth = function(player, inventory, bodyDamage, playerNum)
    local bandage = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalBandageItems)
    if bandage then
        local targetPart = nil
        for i=0, BodyPartType.MAX:index() - 1 do
            local bodyPartType = BodyPartType.FromIndex(i)
            local bodyPart = bodyDamage:getBodyPart(bodyPartType)
            if bodyPart:bleeding() or bodyPart:getDeepWoundTime() > 0 or bodyPart:haveBullet() then
                targetPart = bodyPart
                break
            end
        end
        
        if targetPart then
            ISInventoryPaneContextMenu.applyBandage(bandage, targetPart, playerNum)
        end
    end
end

MS_IndicatorActions.evalBandageItems = function(item)
    return item:getBandagePower() > 0
end

-- ------------------------------------------- --
-- Sickness
-- ------------------------------------------- --
MS_IndicatorActions.handleSickness = function(player, inventory, playerNum)
    -- Antibiotics
    local item = inventory:getFirstTypeRecurse("Base.Antibiotics")
    if item then
        ISInventoryPaneContextMenu.onEatItems({item}, 1, playerNum)
    end
end

-- ------------------------------------------- --
-- Unhappy
-- ------------------------------------------- --
MS_IndicatorActions.handleUnhappyness = function(player, inventory, playerNum)
    -- AntiDep
    local item = inventory:getFirstTypeRecurse("Base.PillsAntiDep")
    if item then
        ISInventoryPaneContextMenu.onPillsItems({item}, playerNum)
    end
end

-- ------------------------------------------- --
-- Pain
-- ------------------------------------------- --
MS_IndicatorActions.handlePain = function(player, inventory, playerNum)
    -- 1.Painkiller
    local item = inventory:getFirstTypeRecurse("Base.Pills")
    if item then
        ISInventoryPaneContextMenu.onPillsItems({item}, playerNum)
        return
    end
    
    -- 2.Alcoholic
    local alcoholItem = inventory:getFirstEvalRecurse(MS_IndicatorActions.evalAlcoholicItems)
    if alcoholItem then
        ISInventoryPaneContextMenu.onDrinkFluid(alcoholItem, 0.25, player)
    end
end

-- ------------------------------------------- --
-- Eval Alcoholic Items
-- ------------------------------------------- --
MS_IndicatorActions.evalAlcoholicItems = function(item)
    if not item:getFluidContainer() then return false end
    local fluidContainer = item:getFluidContainer()
    if fluidContainer:isEmpty() then return false end
    if not fluidContainer:canPlayerEmpty() then return false end
    if not fluidContainer:isCategory(FluidCategory.Alcoholic) then return false end
    if fluidContainer:getCapacity() > 3.0 then return false end
    if fluidContainer:getAmount() <= 0 then return false end
    if item:isFavorite() then return false end
    
    return true
end

return MS_IndicatorActions