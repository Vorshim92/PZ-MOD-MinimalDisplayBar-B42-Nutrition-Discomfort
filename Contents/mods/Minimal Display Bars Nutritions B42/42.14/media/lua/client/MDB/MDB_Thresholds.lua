--============================================================
-- MDB_Thresholds.lua
-- Moodlet severity threshold tables for MinimalDisplayBars.
-- Extracted from minimaldisplaybars(a).lua lines 1642-1724.
--
-- Each stat has an ordered array of thresholds (normalized 0-1)
-- that define where moodlet severity levels change.
-- Index 1 = first moodlet level, index 4 = most severe.
--
-- All values are PRE-COMPUTED from the original calc functions:
--   hunger:          calcHunger(x)          = 1 - x
--   thirst:          calcThirst(x)          = 1 - x
--   endurance:       calcEndurance(x)       = x
--   fatigue:         calcFatigue(x)         = x
--   boredomlevel:    calcBoredomLevel(x)    = x / 100
--   stress:          calcStress(x, 1)       = x
--   unhappynesslevel:calcUnhappynessLevel(x)= x / 100
--   sickness:        calcSickness(x)        = x
--   discomfortlevel: calcDiscomfortLevel(x) = x / 100
--   temperature:     calcTemperature(x)     = (x - 20) / 20
--   wetness:         calcWetness(x)         = x / 100
--============================================================

MDB_Thresholds = {}

MDB_Thresholds.data = {
    -- hunger: calcHunger(x) = 1 - x
    -- Raw values: 0.15, 0.25, 0.45, 0.70
    -- Normalized: 0.85, 0.75, 0.55, 0.30 (inverted: high = well-fed)
    ["hunger"] = { 0.85, 0.75, 0.55, 0.30 },

    -- thirst: calcThirst(x) = 1 - x
    -- Raw values: 0.12, 0.25, 0.70, 0.84
    -- Normalized: 0.88, 0.75, 0.30, 0.16 (inverted: high = hydrated)
    ["thirst"] = { 0.88, 0.75, 0.30, 0.16 },

    -- endurance: calcEndurance(x) = x (direct)
    -- Raw values: 0.10, 0.25, 0.50, 0.75
    ["endurance"] = { 0.10, 0.25, 0.50, 0.75 },

    -- fatigue: calcFatigue(x) = x (direct)
    -- Raw values: 0.60, 0.70, 0.80, 0.90
    ["fatigue"] = { 0.60, 0.70, 0.80, 0.90 },

    -- boredomlevel: calcBoredomLevel(x) = x / 100
    -- Raw values: 25, 50, 75, 90
    ["boredomlevel"] = { 0.25, 0.50, 0.75, 0.90 },

    -- stress: calcStress(x, 1) = x / 1 = x
    -- Raw values: 0.25, 0.50, 0.75, 0.90
    ["stress"] = { 0.25, 0.50, 0.75, 0.90 },

    -- unhappynesslevel: calcUnhappynessLevel(x) = x / 100
    -- Raw values: 20, 45, 60, 80
    ["unhappynesslevel"] = { 0.20, 0.45, 0.60, 0.80 },

    -- sickness: calcSickness(x) = x (direct, already 0-1)
    -- Raw values: 0.25, 0.50, 0.75, 0.90
    ["sickness"] = { 0.25, 0.50, 0.75, 0.90 },

    -- discomfortlevel: calcDiscomfortLevel(x) = x / 100
    -- Raw values: 20, 40, 60, 80
    ["discomfortlevel"] = { 0.20, 0.40, 0.60, 0.80 },

    -- temperature: calcTemperature(x) = (x - 20) / 20
    -- Raw values (Celsius): 30.0, 25.0, 36.5, 37.5, 39.0
    -- NOTE: 5 thresholds (not 4) - temperature has asymmetric cold/hot zones
    -- [1]=cold warning, [2]=cold severe, [3]=normal low, [4]=normal high, [5]=hot severe
    ["temperature"] = { 0.50, 0.25, 0.825, 0.875, 0.95 },

    -- wetness: calcWetness(x) = x / 100
    -- Raw values: 25, 50, 75, 90
    ["wetness"] = { 0.25, 0.50, 0.75, 0.90 },
}

--- Get the threshold table for a given stat.
-- @param statId  string identifier matching the keys in MDB_Thresholds.data
-- @return table of normalized threshold values (0-1), or nil if stat not found
function MDB_Thresholds.get(statId)
    return MDB_Thresholds.data[statId]
end

return MDB_Thresholds
