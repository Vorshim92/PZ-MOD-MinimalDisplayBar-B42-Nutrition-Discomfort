--============================================================
-- MDB_ColorUtils.lua
-- Color utility functions for MinimalDisplayBars.
-- Extracted from minimaldisplaybars(a).lua.
--
-- Provides HSV<->RGB conversion, and specialized color gradient
-- functions for temperature, health, and generic stat bars.
--============================================================

MDB_ColorUtils = {}

--============================================================
-- HSV <-> RGB Conversion
-- Source: lines 168-222
-- Input/output values are in [0, 1] range.
--============================================================

--- Convert RGB to HSV. All values in [0, 1] range.
-- @param r  red channel   (0-1)
-- @param g  green channel (0-1)
-- @param b  blue channel  (0-1)
-- @return h, s, v  hue (0-1), saturation (0-1), value (0-1)
function MDB_ColorUtils.rgbToHsv(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then s = 0 else s = d / max end

    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

--- Convert HSV to RGB. All values in [0, 1] range.
-- Adapted from http://en.wikipedia.org/wiki/HSV_color_space
-- @param h  hue        (0-1)
-- @param s  saturation (0-1)
-- @param v  value      (0-1)
-- @return r, g, b  red (0-1), green (0-1), blue (0-1)
function MDB_ColorUtils.hsvToRgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if     i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r, g, b
end

--============================================================
-- Temperature Color Gradient
-- Source: lines 1444-1483 (getColorTemperature)
--
-- Maps body temperature ratio to a color gradient:
--   Cold (0.0)  -> Cyan (hue 180)
--   Normal (0.825-0.875) -> Green (hue 120) -> Yellow-green
--   Hot (1.0)   -> Red (hue 0)
--
-- tempRatio is normalized 0-1 where:
--   0.0 = 20 C (hypothermia limit)
--   0.825 = 36.5 C (normal low)
--   0.875 = 37.5 C (normal high)
--   1.0 = 40 C (hyperthermia limit)
--============================================================

--- Get color for a body temperature ratio.
-- @param tempRatio  normalized temperature (0-1), where 0=20C, 1=40C
-- @return table {r, g, b, a} with values in [0, 1]
function MDB_ColorUtils.getTemperatureColor(tempRatio)
    -- Precomputed boundary ratios (from calcTemperature with min=20, max=40)
    local RATIO_20   = 0.0    -- (20 - 20) / 20
    local RATIO_36_5 = 0.825  -- (36.5 - 20) / 20
    local RATIO_37_5 = 0.875  -- (37.5 - 20) / 20
    local RATIO_40   = 1.0    -- (40 - 20) / 20

    local r, g, b

    if RATIO_20 <= tempRatio and tempRatio < RATIO_36_5 then
        -- Cold zone: Cyan (hue 260) -> Green (hue 180)
        -- Hue goes from 260 down to 180 as temperature rises toward normal
        local hue = (180 + (80 - 80 * ((tempRatio - RATIO_20) / (RATIO_36_5 - RATIO_20)))) / 360
        r, g, b = MDB_ColorUtils.hsvToRgb(hue, 1, 1)

    elseif RATIO_36_5 <= tempRatio and tempRatio <= RATIO_37_5 then
        -- Normal zone: Green (hue 180) -> Yellow-green (hue 60)
        -- Narrow band around normal body temperature
        local hue = (60 + (120 - 120 * ((tempRatio - RATIO_36_5) / (RATIO_37_5 - RATIO_36_5)))) / 360
        r, g, b = MDB_ColorUtils.hsvToRgb(hue, 1, 1)

    elseif RATIO_37_5 < tempRatio and tempRatio <= RATIO_40 then
        -- Hot zone: Yellow (hue 60) -> Red (hue 0)
        local hue = (0 + (60 - 60 * ((tempRatio - RATIO_37_5) / (RATIO_40 - RATIO_37_5)))) / 360
        r, g, b = MDB_ColorUtils.hsvToRgb(hue, 1, 1)

    else
        -- Out of range: white fallback
        r, g, b = 1.0, 1.0, 1.0
    end

    return { r = r, g = g, b = b, a = 0.75 }
end

--============================================================
-- Health Color
-- Source: lines 1136-1179 (getColorHealth)
--
-- Uses exponential curve for smooth red-to-green transition:
--   hpRatio = 0   -> pure red  (dead/critical)
--   hpRatio = 0.5 -> dark red-orange
--   hpRatio = 1   -> fallback color (user-configured bar color)
--
-- The exponential curve math.pow(0.1, 1 - ratio) makes green
-- appear only at high HP, giving a dramatic visual warning.
--============================================================

--- Get color for a health ratio.
-- @param hpRatio        normalized HP (0-1)
-- @param fallbackColor  table {r, g, b, a} user-configured color for full HP (values 0-1)
-- @return table {r, g, b, a} with values in [0, 1]
function MDB_ColorUtils.getHealthColor(hpRatio, fallbackColor)
    if hpRatio ~= nil and 0 <= hpRatio and hpRatio < 1 then
        -- Exponential curve: green fades rapidly below full HP
        return {
            r = 1.0,
            g = math.pow(0.1, 1 - hpRatio),
            b = (10 / 255) * (1 - hpRatio),
            a = 0.75
        }
    elseif hpRatio ~= nil and hpRatio < 0 then
        -- Below zero (should not happen normally): pure red
        return { r = 1.0, g = 0.0, b = 0.0, a = 0.75 }
    else
        -- Full HP or nil: use the user-configured bar color
        if fallbackColor then
            return {
                r = fallbackColor.r or fallbackColor.red or 1.0,
                g = fallbackColor.g or fallbackColor.green or 1.0,
                b = fallbackColor.b or fallbackColor.blue or 1.0,
                a = fallbackColor.a or fallbackColor.alpha or 0.75
            }
        else
            return { r = 1.0, g = 1.0, b = 1.0, a = 0.75 }
        end
    end
end

--============================================================
-- Generic Gradient Color
-- Simple Red -> Yellow -> Green gradient for any stat bar.
--============================================================

--- Get a red-yellow-green gradient color for a stat value.
-- @param value        normalized stat value (0-1)
-- @param highIsBetter if true, high value=green (good), low=red (bad);
--                     if false, high value=red (bad), low=green (good)
-- @return table {r, g, b} with values in [0, 1]
function MDB_ColorUtils.getGradientColor(value, highIsBetter)
    -- Clamp to 0-1
    value = math.max(0, math.min(1, value))

    -- If low is good, invert the value so the color math stays the same
    if not highIsBetter then
        value = 1 - value
    end

    -- Two-phase linear gradient:
    --   value 0.0 -> 0.5: Red (1,0,0) -> Yellow (1,1,0)
    --   value 0.5 -> 1.0: Yellow (1,1,0) -> Green (0,1,0)
    local r, g, b

    if value < 0.5 then
        -- Red to Yellow: green channel ramps up
        r = 1.0
        g = value * 2.0
        b = 0.0
    else
        -- Yellow to Green: red channel ramps down
        r = 1.0 - (value - 0.5) * 2.0
        g = 1.0
        b = 0.0
    end

    return { r = r, g = g, b = b }
end

return MDB_ColorUtils
