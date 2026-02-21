--============================================================
-- MDB_CircularIndicator.lua
-- Circular-style stat indicator for MinimalDisplayBars (v42.14).
--
-- Renders a circular gauge with 12 arc segments that fill
-- proportionally to the normalized stat value (0-1).
-- The rendering approach is inspired by ModernStatus's
-- renderCircularStyle() method, adapted to use MDB's own
-- stat definition registry and config system.
--
-- Derives from MDB_IndicatorBase, which provides:
--   - ISUIElement foundation (mouse handling, drag, visibility)
--   - Parent tracking (co-op HUD offset compensation)
--   - Tooltip rendering (renderTooltip)
--   - Position persistence (onPositionChanged)
--   - Bring-to-top logic (handleBringToTop)
--   - Edit-mode flag (MDB_IndicatorBase.isEditing)
--
-- Dependencies:
--   MDB_IndicatorBase  - Base class for all MDB indicators
--   MDB_StatDefs       - Stat registry (getValue, getColor, etc.)
--   MDB_Config         - Configuration cache
--
-- Texture assets (copied from ModernStatus CircularStatus):
--   media/ui/MDB/CircularStatus/background.png
--   media/ui/MDB/CircularStatus/background_Line.png
--   media/ui/MDB/CircularStatus/background_Shader.png
--   media/ui/MDB/CircularStatus/segment_1.png .. segment_12.png
--============================================================

require "MDB/UI/MDB_IndicatorBase"
require "MDB/MDB_StatDefs"
require "MDB/MDB_Config"

MDB_CircularIndicator = MDB_IndicatorBase:derive("MDB_CircularIndicator")

-- =========================================================================
-- Constructor
-- =========================================================================

--- Create a new circular indicator for a given stat.
-- @param statId      string   Stat identifier from MDB_StatDefs (e.g. "hp")
-- @param playerIndex number   0-based player index (from getPlayerNum)
-- @param isoPlayer   IsoPlayer  The player Java object
-- @param coopNum     number   1-based player number for config lookup
-- @param xOffset     number   Horizontal offset for co-op HUD positioning
-- @param yOffset     number   Vertical offset for co-op HUD positioning
-- @return MDB_CircularIndicator
function MDB_CircularIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
    local o = MDB_IndicatorBase.new(self, statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)

    -- -----------------------------------------------------------------
    -- Load circular background textures
    -- These three layers compose the ring background:
    --   1. Dark fill     (background.png)       - base dark circle
    --   2. Line overlay  (background_Line.png)   - subtle ring outline
    --   3. Shader overlay (background_Shader.png) - lighting/depth effect
    -- -----------------------------------------------------------------
    o.circularBgTexture   = getTexture("media/ui/MDB/CircularStatus/background.png")
    o.circularLineTexture = getTexture("media/ui/MDB/CircularStatus/background_Line.png")
    o.circularBgShader    = getTexture("media/ui/MDB/CircularStatus/background_Shader.png")

    -- -----------------------------------------------------------------
    -- Load the 12 arc segment textures
    -- Each segment covers 30 degrees (360 / 12). They are drawn
    -- cumulatively to represent the fill level.
    -- -----------------------------------------------------------------
    o.segmentTextures = {}
    for i = 1, 12 do
        o.segmentTextures[i] = getTexture("media/ui/MDB/CircularStatus/segment_" .. i .. ".png")
    end

    -- -----------------------------------------------------------------
    -- Set the indicator dimensions from config
    -- Circular indicators are always square (width == height).
    -- The config key "circularSize" determines the pixel size.
    -- -----------------------------------------------------------------
    local config = MDB_Config.getIndicatorConfig(coopNum, statId)
    local size = config.circularSize or 48
    o:setWidth(size)
    o:setHeight(size)

    return o
end

-- =========================================================================
-- Render
-- =========================================================================

--- Main render function, called every frame by the UI manager.
-- Draws the circular background, filled segments, center icon, and tooltip.
--
-- The rendering pipeline:
--   1. Update parent tracking (co-op HUD offset)
--   2. Fetch the stat definition and current value
--   3. Hide if dead or value invalid
--   4. Resolve color (static from config, or dynamic from stat def)
--   5. Draw the 3-layer circular background
--   6. Draw filled segments proportional to value
--   7. Draw the center icon (if enabled)
--   8. Draw tooltip on hover
--   9. Track position changes for config persistence
--  10. Handle bring-to-top logic
function MDB_CircularIndicator:render()
    local panel = ISUIElement.render(self)

    -- 1. Parent tracking: compensate for co-op HUD container movement
    self:parentTracking()

    -- 2. Look up the stat definition
    local def = MDB_StatDefs.byId[self.statId]
    if not def then return panel end

    -- 3. Get the normalized value (0-1) and handle dead/invalid states
    local value = def.getValue(self.isoPlayer)
    if self.isoPlayer:isDead() or value <= -1 then
        if self:isVisible() then self:setVisible(false) end
        return panel
    else
        if not self:isVisible() then self:setVisible(true) end
    end

    -- 4. Resolve the display color
    -- Start with the user-configured static color
    local r = self.color.red
    local g = self.color.green
    local b = self.color.blue

    -- Override with dynamic color if the stat definition provides one
    if def.useDynamicColor and def.getColor then
        local c = def.getColor(self.isoPlayer, self.color)
        if c then
            -- Handle both long keys (red/green/blue) and short keys (r/g/b)
            -- returned by different getColor implementations
            r = c.red   or c.r or r
            g = c.green  or c.g or g
            b = c.blue   or c.b or b
        end
    end

    -- 5. Draw the circular background layers
    -- Layer 1: Dark base circle (semi-transparent dark gray)
    self:drawTextureScaled(self.circularBgTexture, 0, 0, self.width, self.height, 0.6, 0.1, 0.1, 0.1)
    -- Layer 2: Ring outline (slightly lighter, adds definition)
    self:drawTextureScaled(self.circularLineTexture, 0, 0, self.width, self.height, 0.6, 0.2, 0.2, 0.2)
    -- Layer 3: Shader/lighting overlay (full white pass-through)
    self:drawTextureScaled(self.circularBgShader, 0, 0, self.width, self.height, 1, 1, 1, 1)

    -- 6. Draw filled segments
    -- The value (0-1) maps to 0-12 segments.
    -- Fully filled segments are drawn at full alpha.
    -- The partially filled segment uses interpolated alpha for smooth transition.
    local baseAlpha = self.color.alpha or 0.8

    local fullSegments  = math.floor(value * 12)
    local partialSegment = fullSegments + 1
    local partialAlpha   = (value * 12) - fullSegments

    -- Draw all fully filled segments
    for i = 1, fullSegments do
        if self.segmentTextures[i] then
            self:drawTextureScaled(self.segmentTextures[i], 0, 0, self.width, self.height, baseAlpha, r, g, b)
        end
    end

    -- Draw the partially filled segment with blended alpha
    if partialSegment <= 12 and partialAlpha > 0 and self.segmentTextures[partialSegment] then
        self:drawTextureScaled(self.segmentTextures[partialSegment], 0, 0, self.width, self.height, baseAlpha * partialAlpha, r, g, b)
    end

    -- 6b. Hover highlight: brighter ring outline when mouse is over
    if self.showTooltip and not self.moving then
        self:drawTextureScaled(self.circularLineTexture, 0, 0, self.width, self.height, 0.8, 0.5, 0.5, 0.5)
    end

    -- 7. Draw the center icon
    -- The icon is drawn at 55% of the indicator size, centered within the ring.
    -- This leaves the ring segments visible around the edges.
    if self.showImage and self.imageName then
        local tex = getTexture(self.imageName)
        if tex then
            local iconSize = self.width * 0.55
            local x = math.floor((self.width - iconSize) / 2)
            local y = math.floor((self.height - iconSize) / 2)
            self:drawTextureScaledAspect(tex, x, y, iconSize, iconSize, 1, 1, 1, 1)
        end
    end

    -- 8. Tooltip on hover/moving
    self:renderTooltip(value)

    -- 9. Position change tracking for config persistence
    self:checkPositionChanged()

    -- 10. Bring to top if configured
    self:handleBringToTop()

    return panel
end

-- =========================================================================
-- Position change detection
-- =========================================================================

--- Check if the indicator has been moved and persist the new position.
-- Only runs when the indicator is not actively being dragged and the
-- edit mode is not active (to avoid saving intermediate positions).
-- This mirrors the same logic used in MDB_BarIndicator.
function MDB_CircularIndicator:checkPositionChanged()
    if not self.moving and not MDB_IndicatorBase.isEditing then
        if self.oldX ~= self.x or self.oldY ~= self.y then
            self.oldX = self.x
            self.oldY = self.y
            self:onPositionChanged()
        end
    end
end

return MDB_CircularIndicator
