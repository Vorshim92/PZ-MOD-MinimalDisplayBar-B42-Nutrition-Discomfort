--============================================================
-- MDB_NanFix.lua
-- Fixes for vanilla PZ bugs where stats become NaN.
-- Extracted from minimaldisplaybars(a).lua lines 1050-1113.
--
-- NaN values crash math operations and corrupt save data.
-- These functions detect and reset NaN stats to safe defaults.
--============================================================

MDB_NanFix = {}

--- Check if a value is NaN (Not a Number).
-- Handles both number and numeric string inputs.
-- @param value  number or string to check
-- @return boolean true if NaN, false if valid number, nil if not a number type
function MDB_NanFix.isNaN(value)
    if type(value) == "string" then
        value = tonumber(value)
        if value == nil then return nil end
    elseif type(value) ~= "number" then
        return nil
    end
    -- NaN is the only value that is not equal to itself
    return value ~= value
end

--- Reset wetness NaN on all worn clothing items.
-- Vanilla bug: clothing wetness can become NaN, which propagates
-- to temperature calculations and corrupts the player's stats.
-- @param isoPlayer  the IsoPlayer whose worn items to fix
function MDB_NanFix.fixWornItems(isoPlayer)
    local wornItems = isoPlayer:getWornItems()
    if not wornItems then return end

    local size = wornItems:size()
    for i = 0, size - 1 do
        local item = wornItems:get(i):getItem()
        if item and instanceof(item, "Clothing") and MDB_NanFix.isNaN(item:getWetness()) then
            item:setWetness(0.0)
        end
    end
end

--- Fix NaN body temperature by resetting worn items and stat.
-- Calls fixWornItems first (root cause), then resets body temp to 37.0 C.
-- @param isoPlayer  the IsoPlayer to fix
function MDB_NanFix.fixTemperature(isoPlayer)
    if not isoPlayer then return end

    -- Fix bugged clothing items (root cause of NaN temperature)
    MDB_NanFix.fixWornItems(isoPlayer)

    -- Reset body temperature to normal 37.0 C via CharacterStat
    local stats = isoPlayer:getStats()
    if stats then
        stats:set(CharacterStat.TEMPERATURE, 37.0)
    end
end

--- Fix NaN thirst by resetting to 0.0 (not thirsty).
-- @param isoStats  the Stats object from isoPlayer:getStats()
function MDB_NanFix.fixThirst(isoStats)
    if not isoStats then return end
    isoStats:set(CharacterStat.THIRST, 0.0)
end

--- Fix NaN calories by resetting to 800.0 (moderate level).
-- @param nutrition  the Nutrition object from isoPlayer:getNutrition()
function MDB_NanFix.fixCalories(nutrition)
    if not nutrition then return end
    nutrition:setCalories(800.0)
end

--- Fix NaN lipids by resetting to 0.0.
-- @param nutrition  the Nutrition object from isoPlayer:getNutrition()
function MDB_NanFix.fixLipids(nutrition)
    if not nutrition then return end
    nutrition:setLipids(0.0)
end

--- Fix NaN proteins by resetting to 0.0.
-- @param nutrition  the Nutrition object from isoPlayer:getNutrition()
function MDB_NanFix.fixProteins(nutrition)
    if not nutrition then return end
    nutrition:setProteins(0.0)
end

--- Fix NaN carbohydrates by resetting to 0.0.
-- @param nutrition  the Nutrition object from isoPlayer:getNutrition()
function MDB_NanFix.fixCarbohydrates(nutrition)
    if not nutrition then return end
    nutrition:setCarbohydrates(0.0)
end

return MDB_NanFix
