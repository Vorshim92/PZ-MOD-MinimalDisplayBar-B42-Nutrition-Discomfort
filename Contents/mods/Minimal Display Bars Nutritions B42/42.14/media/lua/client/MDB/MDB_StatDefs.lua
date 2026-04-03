--============================================================
-- MDB_StatDefs.lua
-- Declarative stat registry for MinimalDisplayBars (v42.14).
--
-- This file replaces the duplicated calc/get/getColor pattern
-- (~500 lines, 3 functions x 17 stats) from v42.13 with a
-- single registry table where each stat is defined once.
--
-- Dependencies:
--   MDB_NanFix      - NaN detection and safe-reset helpers
--   MDB_ColorUtils  - HSV/RGB conversion, temperature/health color
--   MDB_Thresholds  - Moodlet severity threshold tables
--   MDB_Config      - Configuration cache and persistence
--
-- Usage:
--   require "MDB/MDB_StatDefs"
--   MDB_StatDefs.init()
--   local def = MDB_StatDefs.byId["hp"]
--   local normalized = def.getValue(player)
--============================================================

require "MDB/MDB_NanFix"
require "MDB/MDB_ColorUtils"
require "MDB/MDB_Thresholds"
require "MDB/MDB_Config"

MDB_StatDefs = {}

-- ---------------------------------------------------------------------------
-- Clamp helper (used by normalize functions throughout)
-- ---------------------------------------------------------------------------
local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

-- ---------------------------------------------------------------------------
-- Nutrition range constants (from v42.13 source lines 1486-1610)
-- ---------------------------------------------------------------------------
local CALORIE_MIN = -2200
local CALORIE_MAX =  3700

local CARBS_MIN   = -500
local CARBS_MAX   =  1000

local PROTEIN_MIN = -500
local PROTEIN_MAX =  1000

local LIPID_MIN   = -500
local LIPID_MAX   =  1000

-- Temperature range constants (from v42.13 source lines 1420-1421)
local TEMP_MIN = 20   -- 20.0 C (hypothermia limit)
local TEMP_MAX = 40   -- 40.0 C (hyperthermia limit)

-- ---------------------------------------------------------------------------
-- Registry: all 17 stats defined declaratively
--
-- The order field determines creation/display order.
-- The getValue function returns a normalized 0-1 value for bar rendering.
-- The getRawValue function returns the raw PZ API value for tooltips.
-- The getColor function returns {r, g, b, a} for the bar color.
-- ---------------------------------------------------------------------------

MDB_StatDefs.registry = {

    -- ======================================================================
    -- 1. MENU (order 0) - Special: not a real stat, just a menu button
    -- ======================================================================
    {
        id              = "menu",
        translationKey  = "ContextMenu_MinimalDisplayBars_menu",
        order           = 0,
        isMenu          = true,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = nil,

        -- Menu button always shows full (1) when alive, empty (-1) when dead
        getValue = function(player)
            if player:isDead() then return -1 end
            return 1
        end,

        getRawValue = function(player)
            return nil
        end,

        formatTooltip = function(raw, player)
            return nil
        end,

        getColor = nil,

        defaultConfig = {
            x         = 55,
            y         = 10,
            width     = 32,
            height    = 32,
            l         = 0,
            t         = 0,
            r         = 0,
            b         = 0,
            color     = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = true,
            showMoodletThresholdLines = false,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 2. HP (order 1) - Health
    -- Dynamic color: red-to-green exponential gradient based on HP ratio.
    -- Source: lines 1121-1179
    -- ======================================================================
    {
        id              = "hp",
        translationKey  = "ContextMenu_MinimalDisplayBars_hp",
        order           = 1,
        highIsBetter    = true,
        useDynamicColor = true,
        moodleType      = nil,

        -- Normalized: overallBodyHealth / 100, clamped 0-1
        getValue = function(player)
            if player:isDead() then return -1 end
            local hp = player:getBodyDamage():getOverallBodyHealth()
            return clamp01(hp / 100)
        end,

        -- Raw: the actual overallBodyHealth value (0-100)
        getRawValue = function(player)
            return player:getBodyDamage():getOverallBodyHealth()
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw)
        end,

        -- Dynamic color: exponential curve from MDB_ColorUtils
        -- Requires the fallback color from user config (passed at render time)
        getColor = function(player, configColor)
            local hpRatio = 0
            if not player:isDead() then
                local hp = player:getBodyDamage():getOverallBodyHealth()
                hpRatio = clamp01(hp / 100)
            end
            return MDB_ColorUtils.getHealthColor(hpRatio, configColor)
        end,

        defaultConfig = {
            x         = 70,
            y         = 30,
            width     = 15,
            height    = 150,
            l         = 3,
            t         = 3,
            r         = 3,
            b         = 3,
            color     = { red = 0 / 255, green = 128 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 3. HUNGER (order 2) - Inverted: 0=starving, 1=full
    -- Source: lines 1182-1204
    -- ======================================================================
    {
        id              = "hunger",
        translationKey  = "ContextMenu_MinimalDisplayBars_hunger",
        order           = 2,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = "MoodleType.HUNGRY",

        -- Normalized: 1 - hunger (invert so full stomach = high bar)
        getValue = function(player)
            if player:isDead() then return -1 end
            local hunger = player:getStats():get(CharacterStat.HUNGER)
            return clamp01(1 - hunger)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.HUNGER)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", (1 - raw) * 100)
        end,

        getColor = nil,  -- Uses config color (non-dynamic)

        defaultConfig = {
            x         = 85,
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 255 / 255, green = 255 / 255, blue = 10 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Hungry.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 4. THIRST (order 3) - Inverted: 0=dehydrated, 1=hydrated
    -- NaN fix for thirst. Source: lines 1231-1259
    -- ======================================================================
    {
        id              = "thirst",
        translationKey  = "ContextMenu_MinimalDisplayBars_thirst",
        order           = 3,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = "MoodleType.THIRSTY",

        getValue = function(player)
            if player:isDead() then return -1 end
            local stats = player:getStats()
            local thirst = stats:get(CharacterStat.THIRST)
            -- NaN fix: reset thirst if corrupted
            if MDB_NanFix.isNaN(thirst) or thirst < 0 then
                MDB_NanFix.fixThirst(stats)
                thirst = stats:get(CharacterStat.THIRST)
            end
            return clamp01(1 - thirst)
        end,

        getRawValue = function(player)
            local stats = player:getStats()
            local thirst = stats:get(CharacterStat.THIRST)
            if MDB_NanFix.isNaN(thirst) or thirst < 0 then
                MDB_NanFix.fixThirst(stats)
                thirst = stats:get(CharacterStat.THIRST)
            end
            return thirst
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", (1 - raw) * 100)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 1),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 173 / 255, green = 216 / 255, blue = 230 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Thirsty.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 5. ENDURANCE (order 4) - Direct: high endurance = high bar
    -- Source: lines 1261-1284
    -- ======================================================================
    {
        id              = "endurance",
        translationKey  = "ContextMenu_MinimalDisplayBars_endurance",
        order           = 4,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = "MoodleType.ENDURANCE",

        getValue = function(player)
            if player:isDead() then return -1 end
            local endurance = player:getStats():get(CharacterStat.ENDURANCE)
            return clamp01(endurance)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.ENDURANCE)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw * 100)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 2),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 244 / 255, green = 244 / 255, blue = 244 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Endurance.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 6. FATIGUE (order 5) - Shows "wakefulness": 1 - fatigue
    -- High fatigue = low bar. Source: lines 1286-1309
    -- ======================================================================
    {
        id              = "fatigue",
        translationKey  = "ContextMenu_MinimalDisplayBars_fatigue",
        order           = 5,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = "MoodleType.TIRED",

        -- NOTE: The original v42.13 code does NOT invert fatigue in calcFatigue.
        -- calcFatigue(value) = value (identity). getFatigue returns the raw value.
        -- The bar rendering inverts display based on threshold logic.
        -- We preserve the original behavior: getValue returns the RAW fatigue
        -- value (0=awake, 1=exhausted), matching the threshold table.
        getValue = function(player)
            if player:isDead() then return -1 end
            local fatigue = player:getStats():get(CharacterStat.FATIGUE)
            return clamp01(fatigue)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.FATIGUE)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw * 100)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 3),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 240 / 255, green = 240 / 255, blue = 170 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Tired.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 7. BOREDOM LEVEL (order 6) - Boredom/100
    -- Source: lines 1311-1334
    -- ======================================================================
    {
        id              = "boredomlevel",
        translationKey  = "ContextMenu_MinimalDisplayBars_boredomlevel",
        order           = 6,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.BORED",

        -- Original: calcBoredomLevel(value) = value / 100
        -- getBoredomLevel uses CharacterStat.BOREDOM (0-100 range)
        getValue = function(player)
            if player:isDead() then return -1 end
            local boredom = player:getStats():get(CharacterStat.BOREDOM)
            return clamp01(boredom / 100)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.BOREDOM)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 4),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 170 / 255, green = 170 / 255, blue = 170 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Bored.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 8. STRESS (order 7) - SPECIAL: includes nicotine withdrawal
    -- Source: lines 1336-1364
    -- Base stress + nicotine stress combined via getNicotineStress()
    -- ======================================================================
    {
        id              = "stress",
        translationKey  = "ContextMenu_MinimalDisplayBars_stress",
        order           = 7,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.STRESSED",

        -- getNicotineStress() returns the combined stress already clamped 0-1 by the game
        getValue = function(player)
            if player:isDead() then return -1 end
            local totalStress = player:getStats():getNicotineStress()
            return clamp01(totalStress)
        end,

        -- Raw: returns TWO values (base stress, nicotine stress) for detailed tooltip
        getRawValue = function(player)
            local stats = player:getStats()
            local base = stats:get(CharacterStat.STRESS)
            local nico = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
            return base, nico
        end,

        formatTooltip = function(raw, player)
            -- raw here is the base stress; second return from getRawValue is lost
            -- For proper dual-value tooltip, callers should use getRawValue directly
            local stats = player:getStats()
            local base = stats:get(CharacterStat.STRESS)
            local nico = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
            local total = stats:getNicotineStress()
            if nico and nico > 0 then
                return string.format("%.0f%% (Base: %.0f%% + Nico: %.0f%%)",
                    total * 100, base * 100, nico * 100)
            else
                return string.format("%.0f%%", total * 100)
            end
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 6),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 255 / 255, green = 0 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodle_Icon_Stressed.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 9. UNHAPPINESS LEVEL (order 8) - Unhappiness/100
    -- Source: lines 1367-1391
    -- ======================================================================
    {
        id              = "unhappynesslevel",
        translationKey  = "ContextMenu_MinimalDisplayBars_unhappynesslevel",
        order           = 8,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.UNHAPPY",

        -- Original: calcUnhappynessLevel(value) = value / 100
        -- Uses CharacterStat.UNHAPPINESS (0-100 range)
        getValue = function(player)
            if player:isDead() then return -1 end
            local unhappiness = player:getStats():get(CharacterStat.UNHAPPINESS)
            return clamp01(unhappiness / 100)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.UNHAPPINESS)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 5),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 128 / 255, green = 128 / 255, blue = 255 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Unhappy.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 10. DISCOMFORT LEVEL (order 9) - Discomfort/100
    -- Source: lines 1393-1417
    -- ======================================================================
    {
        id              = "discomfortlevel",
        translationKey  = "ContextMenu_MinimalDisplayBars_discomfortlevel",
        order           = 9,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.UNCOMFORTABLE",

        -- Original: calcDiscomfortLevel(value) = value / 100
        -- Uses CharacterStat.DISCOMFORT (0-100 range)
        getValue = function(player)
            if player:isDead() then return -1 end
            local discomfort = player:getStats():get(CharacterStat.DISCOMFORT)
            return clamp01(discomfort / 100)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.DISCOMFORT)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 7),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 128 / 255, green = 128 / 255, blue = 255 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Mood_Discomfort.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 11. TEMPERATURE (order 10) - Dynamic color, two moodle types
    -- Source: lines 1419-1483
    -- Normalize: (temp - 20) / 20, where 20C=0, 40C=1, 36.6C~0.83
    -- ======================================================================
    {
        id              = "temperature",
        translationKey  = "ContextMenu_MinimalDisplayBars_temperature",
        order           = 10,
        highIsBetter    = nil,  -- Neither: temperature has an ideal middle range
        useDynamicColor = true,
        moodleType      = "MoodleType.HYPERTHERMIA",
        moodleTypeAlt   = "MoodleType.HYPOTHERMIA",

        getValue = function(player)
            if player:isDead() then return -1 end
            local stats = player:getStats()
            local temp = stats:get(CharacterStat.TEMPERATURE)
            -- NaN fix: reset temperature if corrupted
            if MDB_NanFix.isNaN(temp) then
                MDB_NanFix.fixTemperature(player)
                temp = stats:get(CharacterStat.TEMPERATURE)
            end
            return clamp01((temp - TEMP_MIN) / (TEMP_MAX - TEMP_MIN))
        end,

        getRawValue = function(player)
            local stats = player:getStats()
            local temp = stats:get(CharacterStat.TEMPERATURE)
            if MDB_NanFix.isNaN(temp) then
                MDB_NanFix.fixTemperature(player)
                temp = stats:get(CharacterStat.TEMPERATURE)
            end
            return temp
        end,

        formatTooltip = function(raw, player)
            -- Show in Celsius or Fahrenheit based on game setting
            if getCore():isCelsius() then
                return string.format("%.1f C", raw)
            else
                local fahrenheit = raw * 9 / 5 + 32
                return string.format("%.1f F", fahrenheit)
            end
        end,

        -- Dynamic color: gradient from cyan (cold) to green (normal) to red (hot)
        getColor = function(player, configColor)
            if player:isDead() then
                return { r = 1.0, g = 1.0, b = 1.0, a = 0.75 }
            end
            local stats = player:getStats()
            local temp = stats:get(CharacterStat.TEMPERATURE)
            if MDB_NanFix.isNaN(temp) then
                MDB_NanFix.fixTemperature(player)
                temp = stats:get(CharacterStat.TEMPERATURE)
            end
            local ratio = clamp01((temp - TEMP_MIN) / (TEMP_MAX - TEMP_MIN))
            return MDB_ColorUtils.getTemperatureColor(ratio)
        end,

        defaultConfig = {
            x         = 85 + (8 * 8),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 0 / 255, green = 255 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/MDBTemperature.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 12. CALORIES (order 11) - Nutrition: range [-2200, 3700]
    -- Source: lines 1485-1515. NaN fix for calories.
    -- ======================================================================
    {
        id              = "calorie",
        translationKey  = "ContextMenu_MinimalDisplayBars_calorie",
        order           = 11,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = nil,

        -- Normalize: maps [-2200, 3700] to [0, 1]
        -- 0 calories maps to approximately 0.373
        getValue = function(player)
            if player:isDead() then return -1 end
            local nutrition = player:getNutrition()
            local calories = nutrition:getCalories()
            if MDB_NanFix.isNaN(calories) then
                MDB_NanFix.fixCalories(nutrition)
                calories = nutrition:getCalories()
            end
            return clamp01((calories - CALORIE_MIN) / (CALORIE_MAX - CALORIE_MIN))
        end,

        getRawValue = function(player)
            local nutrition = player:getNutrition()
            local calories = nutrition:getCalories()
            if MDB_NanFix.isNaN(calories) then
                MDB_NanFix.fixCalories(nutrition)
                calories = nutrition:getCalories()
            end
            return calories
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f Calories", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 9),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 100 / 255, green = 255 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "media/ui/TraitNutritionist.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 13. CARBOHYDRATES (order 12) - Nutrition: range [-500, 1000]
    -- Source: lines 1542-1572. NaN fix for carbohydrates.
    -- ======================================================================
    {
        id              = "carbohydrates",
        translationKey  = "ContextMenu_MinimalDisplayBars_carbohydrates",
        order           = 12,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = nil,

        getValue = function(player)
            if player:isDead() then return -1 end
            local nutrition = player:getNutrition()
            local carbs = nutrition:getCarbohydrates()
            if MDB_NanFix.isNaN(carbs) then
                MDB_NanFix.fixCarbohydrates(nutrition)
                carbs = nutrition:getCarbohydrates()
            end
            return clamp01((carbs - CARBS_MIN) / (CARBS_MAX - CARBS_MIN))
        end,

        getRawValue = function(player)
            local nutrition = player:getNutrition()
            local carbs = nutrition:getCarbohydrates()
            if MDB_NanFix.isNaN(carbs) then
                MDB_NanFix.fixCarbohydrates(nutrition)
                carbs = nutrition:getCarbohydrates()
            end
            return carbs
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f Carbs", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 10),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 100 / 255, green = 255 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "media/ui/SpagettiRaw.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 14. PROTEINS (order 13) - Nutrition: range [-500, 1000]
    -- Source: lines 1574-1604. NaN fix for proteins.
    -- ======================================================================
    {
        id              = "proteins",
        translationKey  = "ContextMenu_MinimalDisplayBars_proteins",
        order           = 13,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = nil,

        getValue = function(player)
            if player:isDead() then return -1 end
            local nutrition = player:getNutrition()
            local proteins = nutrition:getProteins()
            if MDB_NanFix.isNaN(proteins) then
                MDB_NanFix.fixProteins(nutrition)
                proteins = nutrition:getProteins()
            end
            return clamp01((proteins - PROTEIN_MIN) / (PROTEIN_MAX - PROTEIN_MIN))
        end,

        getRawValue = function(player)
            local nutrition = player:getNutrition()
            local proteins = nutrition:getProteins()
            if MDB_NanFix.isNaN(proteins) then
                MDB_NanFix.fixProteins(nutrition)
                proteins = nutrition:getProteins()
            end
            return proteins
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f Proteins", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 11),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 100 / 255, green = 255 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "media/ui/Proteins.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 15. LIPIDS (order 14) - Nutrition: range [-500, 1000]
    -- Source: lines 1606-1636. NaN fix for lipids.
    -- ======================================================================
    {
        id              = "lipids",
        translationKey  = "ContextMenu_MinimalDisplayBars_lipids",
        order           = 14,
        highIsBetter    = true,
        useDynamicColor = false,
        moodleType      = nil,

        getValue = function(player)
            if player:isDead() then return -1 end
            local nutrition = player:getNutrition()
            local lipids = nutrition:getLipids()
            if MDB_NanFix.isNaN(lipids) then
                MDB_NanFix.fixLipids(nutrition)
                lipids = nutrition:getLipids()
            end
            return clamp01((lipids - LIPID_MIN) / (LIPID_MAX - LIPID_MIN))
        end,

        getRawValue = function(player)
            local nutrition = player:getNutrition()
            local lipids = nutrition:getLipids()
            if MDB_NanFix.isNaN(lipids) then
                MDB_NanFix.fixLipids(nutrition)
                lipids = nutrition:getLipids()
            end
            return lipids
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f Lipids", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 12),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 100 / 255, green = 255 / 255, blue = 0 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = false,
            imageName   = "media/ui/Butter.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 16. SICKNESS (order 15) - Food sickness level via CharacterStat
    -- Source: lines 1206-1229
    -- ======================================================================
    {
        id              = "sickness",
        translationKey  = "ContextMenu_MinimalDisplayBars_sickness",
        order           = 15,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.SICK",

        -- Vanilla SICK moodle formula: apparentInfectionLevel/100 + CharacterStat.SICKNESS
        -- apparentInfectionLevel = max(FOOD_SICKNESS, ZOMBIE_FEVER, ZOMBIE_INFECTION)
        getValue = function(player)
            if player:isDead() then return -1 end
            local apparent = player:getBodyDamage():getApparentInfectionLevel() / 100.0
            local baseSickness = player:getStats():get(CharacterStat.SICKNESS)
            return clamp01(apparent + baseSickness)
        end,

        getRawValue = function(player)
            local apparent = player:getBodyDamage():getApparentInfectionLevel() / 100.0
            local baseSickness = player:getStats():get(CharacterStat.SICKNESS)
            return apparent + baseSickness
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw * 100)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 12),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 150 / 255, green = 255 / 255, blue = 10 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Sick.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

    -- ======================================================================
    -- 17. WETNESS (order 16) - Wetness/100
    -- Source: lines 1517-1540
    -- ======================================================================
    {
        id              = "wetness",
        translationKey  = "ContextMenu_MinimalDisplayBars_wetness",
        order           = 16,
        highIsBetter    = false,
        useDynamicColor = false,
        moodleType      = "MoodleType.WET",

        -- Original: calcWetness(value) = value / 100
        -- Uses CharacterStat.WETNESS (0-100 range)
        getValue = function(player)
            if player:isDead() then return -1 end
            local wetness = player:getStats():get(CharacterStat.WETNESS)
            return clamp01(wetness / 100)
        end,

        getRawValue = function(player)
            return player:getStats():get(CharacterStat.WETNESS)
        end,

        formatTooltip = function(raw, player)
            return string.format("%.0f%%", raw)
        end,

        getColor = nil,

        defaultConfig = {
            x         = 85 + (8 * 13),
            y         = 30,
            width     = 8,
            height    = 150,
            l         = 2,
            t         = 3,
            r         = 2,
            b         = 3,
            color     = { red = 100 / 255, green = 150 / 255, blue = 255 / 255, alpha = 0.75 },
            isVisible = true,
            isVertical = true,
            isMovable  = true,
            isResizable = false,
            alwaysBringToTop = false,
            showMoodletThresholdLines = true,
            isCompact   = false,
            imageShowBack = true,
            imageName   = "media/ui/Moodles/Moodle_Icon_Wet.png",
            imageSize   = 22,
            showImage   = false,
            isIconRight = false,
        },
    },

}  -- End of MDB_StatDefs.registry

-- ---------------------------------------------------------------------------
-- Lookup tables (populated by init)
-- ---------------------------------------------------------------------------

--- Lookup by stat id: byId["hp"] -> registry entry
MDB_StatDefs.byId = {}

--- Ordered list of stat ids: {"menu", "hp", "hunger", ...}
MDB_StatDefs.orderedIds = {}

--- Count of registered stats
MDB_StatDefs.count = 0

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

--- Populate the lookup tables from the registry.
-- Also wires up MDB_Config.defaultConfigGenerator so that
-- MDB_Config.createDefaultConfig() can produce a full default
-- config table with all indicator defaults.
--
-- MUST be called once at mod startup (before any bar creation).
function MDB_StatDefs.init()
    MDB_StatDefs.byId = {}
    MDB_StatDefs.orderedIds = {}
    MDB_StatDefs.count = 0

    -- Sort registry by order field to guarantee deterministic iteration
    table.sort(MDB_StatDefs.registry, function(a, b)
        return a.order < b.order
    end)

    for i, entry in ipairs(MDB_StatDefs.registry) do
        local id = entry.id
        MDB_StatDefs.byId[id] = entry
        MDB_StatDefs.orderedIds[i] = id
        MDB_StatDefs.count = MDB_StatDefs.count + 1
    end

    -- Wire up the default config generator for MDB_Config
    MDB_Config.defaultConfigGenerator = MDB_StatDefs.buildDefaultConfig

    print("[MDB_StatDefs] Initialized " .. MDB_StatDefs.count .. " stat definitions.")
end

-- ---------------------------------------------------------------------------
-- Default config builder
-- ---------------------------------------------------------------------------

--- Build a complete default config table (globalSettings + indicators).
-- Used by MDB_Config.createDefaultConfig() via the defaultConfigGenerator hook.
-- @return table  { globalSettings = {...}, indicators = { [statId] = {...}, ... } }
function MDB_StatDefs.buildDefaultConfig()
    local config = {
        globalSettings = MDB_Config.getDefaultGlobalConfig(),
        indicators = {},
    }

    for _, entry in ipairs(MDB_StatDefs.registry) do
        if entry.defaultConfig then
            -- Deep copy to prevent shared references between players
            config.indicators[entry.id] = MDB_StatDefs._deepCopyTable(entry.defaultConfig)
        end
    end

    return config
end

-- ---------------------------------------------------------------------------
-- Utility: deep copy (local to this module)
-- ---------------------------------------------------------------------------

--- Recursively deep-copies a table.
-- @param orig  table to copy
-- @return table  new independent copy
function MDB_StatDefs._deepCopyTable(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = MDB_StatDefs._deepCopyTable(v)
    end
    return copy
end

-- ---------------------------------------------------------------------------
-- Convenience accessors
-- ---------------------------------------------------------------------------

--- Get the stat definition for a given id.
-- @param statId  string identifier (e.g. "hp", "hunger")
-- @return table  the registry entry, or nil if not found
function MDB_StatDefs.get(statId)
    return MDB_StatDefs.byId[statId]
end

--- Iterate over all stats in display order.
-- @return function  iterator yielding (index, entry) pairs
function MDB_StatDefs.iterOrdered()
    local i = 0
    return function()
        i = i + 1
        local id = MDB_StatDefs.orderedIds[i]
        if id then
            return i, MDB_StatDefs.byId[id]
        end
    end
end

--- Get the moodlet threshold table for a stat from MDB_Thresholds.
-- Convenience wrapper so callers do not need to require MDB_Thresholds separately.
-- @param statId  string identifier
-- @return table|nil  array of threshold values, or nil if stat has none
function MDB_StatDefs.getThresholds(statId)
    return MDB_Thresholds.get(statId)
end

--- Check if a stat uses dynamic (computed) color rather than config color.
-- @param statId  string identifier
-- @return boolean
function MDB_StatDefs.hasDynamicColor(statId)
    local entry = MDB_StatDefs.byId[statId]
    return entry ~= nil and entry.useDynamicColor == true
end

-- ---------------------------------------------------------------------------
-- Backward compatibility: build the old-format DEFAULT_SETTINGS table
-- ---------------------------------------------------------------------------

--- Generate a table in the v42.13 DEFAULT_SETTINGS format.
-- This is provided for backward compatibility with preset loading and
-- the compare_and_insert migration logic. New code should use
-- MDB_Config / MDB_StatDefs directly.
--
-- @return table  keyed by stat id, each value is the defaultConfig sub-table
--                plus a top-level "moveBarsTogether" = false entry
function MDB_StatDefs.buildLegacyDefaults()
    local defaults = {
        ["moveBarsTogether"] = false,
    }
    for _, entry in ipairs(MDB_StatDefs.registry) do
        if entry.defaultConfig then
            defaults[entry.id] = MDB_StatDefs._deepCopyTable(entry.defaultConfig)
        end
    end
    return defaults
end

return MDB_StatDefs
