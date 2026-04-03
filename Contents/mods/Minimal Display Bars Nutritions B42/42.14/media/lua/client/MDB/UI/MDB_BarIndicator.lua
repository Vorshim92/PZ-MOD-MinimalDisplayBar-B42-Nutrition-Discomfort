--============================================================
-- MDB_BarIndicator.lua
-- Classic rectangular bar-style indicator for MinimalDisplayBars (v42.14).
--
-- This is the original mod look: a filled rectangle whose height
-- (vertical) or width (horizontal) represents the stat's normalized
-- value. Derives from MDB_IndicatorBase which handles mouse input,
-- tooltip rendering, config loading, position persistence, and
-- parent tracking for MoveBarsTogether.
--
-- Ported from ISGenericMiniDisplayBar:render() (v42.13 lines 255-521)
-- using the new MDB_StatDefs / MDB_StatRegistry / MDB_Config APIs.
--
-- Dependencies:
--   MDB_IndicatorBase  - Base class (ISUIElement derivative)
--   MDB_StatDefs       - Declarative stat definitions
--   MDB_Thresholds     - Moodlet severity threshold tables
--============================================================

require "MDB/UI/MDB_IndicatorBase"
require "MDB/MDB_StatDefs"
require "MDB/NeatTool/NeatTool_3Patch"

MDB_BarIndicator = MDB_IndicatorBase:derive("MDB_BarIndicator")

-- ========================================================================
-- ThreePatch texture paths (loaded once per indicator in IndicatorBase)
-- ========================================================================

-- ========================================================================
-- Menu button texture paths
-- ========================================================================

MDB_BarIndicator.MENU_TEXTURES = {
    bg     = "media/ui/MDB/MenuButton/MDB_MenuBG.png",
    border = "media/ui/MDB/MenuButton/MDB_MenuBorder.png",
    icon   = "media/ui/MDB/MenuButton/MDB_MenuIcon.png",
}

MDB_BarIndicator.THREEPATCH_TEXTURES = {
    horizontal = {
        bgLeft   = "media/ui/MDB/HorizontalBar/MDB_Horizontal_Left.png",
        bgMiddle = "media/ui/MDB/HorizontalBar/MDB_Horizontal_Middle.png",
        bgRight  = "media/ui/MDB/HorizontalBar/MDB_Horizontal_Right.png",
        fgLeft   = "media/ui/MDB/HorizontalBar/MDB_Horizontal_FLeft.png",
        fgMiddle = "media/ui/MDB/HorizontalBar/MDB_Horizontal_FMiddle.png",
        fgRight  = "media/ui/MDB/HorizontalBar/MDB_Horizontal_FRight.png",
    },
    vertical = {
        bgTop    = "media/ui/MDB/VerticalBar/MDB_Vertical_Top.png",
        bgMiddle = "media/ui/MDB/VerticalBar/MDB_Vertical_Middle.png",
        bgBottom = "media/ui/MDB/VerticalBar/MDB_Vertical_Bottom.png",
        fgTop    = "media/ui/MDB/VerticalBar/MDB_Vertical_FTop.png",
        fgMiddle = "media/ui/MDB/VerticalBar/MDB_Vertical_FMiddle.png",
        fgBottom = "media/ui/MDB/VerticalBar/MDB_Vertical_FBottom.png",
    },
}

-- ========================================================================
-- Constructor
-- ========================================================================

--- Create a new bar indicator for a specific stat.
-- @param statId      string     Stat identifier (e.g. "hp", "hunger")
-- @param playerIndex number     0-based player index (PZ engine convention)
-- @param isoPlayer   IsoPlayer  The player object
-- @param coopNum     number     1-based player number (for config/co-op)
-- @param xOffset     number     Horizontal offset from config position
-- @param yOffset     number     Vertical offset from config position
-- @return MDB_BarIndicator
function MDB_BarIndicator:new(statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)
    local o = MDB_IndicatorBase.new(self, statId, playerIndex, isoPlayer, coopNum, xOffset, yOffset)

    -- Pre-load ThreePatch textures
    o:loadThreePatchTextures()

    -- Pre-load menu button textures (only for menu indicator)
    if statId == "menu" then
        o:loadMenuTextures()
    end

    return o
end

-- ========================================================================
-- Menu button texture loading
-- ========================================================================

--- Load menu button textures (background, border, gear icon).
function MDB_BarIndicator:loadMenuTextures()
    local paths = MDB_BarIndicator.MENU_TEXTURES
    self.menuBgTex       = getTexture(paths.bg)
    self.menuBorderTex   = getTexture(paths.border)
    self.menuIconTex     = getTexture(paths.icon)
    self.menuTexturesReady = self.menuBgTex ~= nil and self.menuBorderTex ~= nil and self.menuIconTex ~= nil
end

-- ========================================================================
-- ThreePatch texture loading
-- ========================================================================

--- Load all 12 ThreePatch textures into instance fields.
-- Uses getTexture (returns nil if file not found, enabling fallback).
function MDB_BarIndicator:loadThreePatchTextures()
    local paths = MDB_BarIndicator.THREEPATCH_TEXTURES

    -- Horizontal
    self.tpHBgLeft   = getTexture(paths.horizontal.bgLeft)
    self.tpHBgMiddle = getTexture(paths.horizontal.bgMiddle)
    self.tpHBgRight  = getTexture(paths.horizontal.bgRight)
    self.tpHFgLeft   = getTexture(paths.horizontal.fgLeft)
    self.tpHFgMiddle = getTexture(paths.horizontal.fgMiddle)
    self.tpHFgRight  = getTexture(paths.horizontal.fgRight)

    -- Vertical
    self.tpVBgTop    = getTexture(paths.vertical.bgTop)
    self.tpVBgMiddle = getTexture(paths.vertical.bgMiddle)
    self.tpVBgBottom = getTexture(paths.vertical.bgBottom)
    self.tpVFgTop    = getTexture(paths.vertical.fgTop)
    self.tpVFgMiddle = getTexture(paths.vertical.fgMiddle)
    self.tpVFgBottom = getTexture(paths.vertical.fgBottom)

    -- Quick check: are all textures available?
    self.threePatchReady =
        self.tpHBgLeft   ~= nil and self.tpHBgMiddle ~= nil and self.tpHBgRight  ~= nil and
        self.tpHFgLeft   ~= nil and self.tpHFgMiddle ~= nil and self.tpHFgRight  ~= nil and
        self.tpVBgTop    ~= nil and self.tpVBgMiddle ~= nil and self.tpVBgBottom ~= nil and
        self.tpVFgTop    ~= nil and self.tpVFgMiddle ~= nil and self.tpVFgBottom ~= nil
end

-- ========================================================================
-- Render (called every frame by the PZ UI engine)
-- ========================================================================

--- Main rendering entry point.
-- Follows the same flow as the old ISGenericMiniDisplayBar:render()
-- (v42.13 lines 255-521) but delegates to the new module APIs.
-- Menu button uses a dedicated textured render path.
function MDB_BarIndicator:render()
    local panel = ISUIElement.render(self)

    -- 1. Parent tracking: keep our position in sync when reparented
    --    under a MoveBarsTogether grouping panel.
    self:parentTracking()

    -- 2. Look up the stat definition from the declarative registry
    local def = MDB_StatDefs.byId[self.statId]
    if not def then return panel end

    -- MENU BUTTON: dedicated render path (textured square button)
    if self.statId == "menu" then
        return self:renderMenuButton()
    end

    -- 3. Update color if this stat uses dynamic (computed) color
    --    (e.g. HP exponential gradient, temperature cold-to-hot)
    if def.useDynamicColor and def.getColor then
        local c = def.getColor(self.isoPlayer, self.color)
        if c then
            -- Normalize short-key {r, g, b, a} to old format {red, green, blue, alpha}
            if c.red ~= nil then
                self.color = c
            else
                self.color = {
                    red   = c.r or 1.0,
                    green = c.g or 1.0,
                    blue  = c.b or 1.0,
                    alpha = c.a or (self.color and self.color.alpha or 0.75),
                }
            end
        end
    end

    -- 4. Get the normalized stat value (0-1, or -1 if dead)
    local value = def.getValue(self.isoPlayer)
    if self.isoPlayer:isDead() or value <= -1 then
        if self:isVisible() then self:setVisible(false) end
        return panel
    else
        if not self:isVisible() then self:setVisible(true) end
    end

    -- 5. Update the moodlet background icon texture based on current
    --    moodlet severity (good/bad/neutral and level 0-4).
    self:updateMoodletBackground()

    -- 6. Render the bar fill and icon
    if self.isVertical then
        self:renderVerticalBar(value)
    else
        self:renderHorizontalBar(value)
    end

    -- 7. Threshold lines (moodlet severity markers on the bar)
    self:renderThresholdLines(value)

    -- 7b. Hover highlight: subtle white border when mouse is over
    if self.showTooltip and not self.moving then
        self:drawRectBorderStatic(0, 0, self.width, self.height, 0.4, 1, 1, 1)
    end

    -- 8. Tooltip (shows stat name, value, and controls hint on hover/drag)
    self:renderTooltip(value)

    -- 9. Position change tracking (deferred save via dirty flag, NOT file I/O)
    self:checkPositionChanged()

    -- 10. Bring to top if configured
    self:handleBringToTop()

    return panel
end

-- ========================================================================
-- Menu button rendering
-- ========================================================================

--- Render the menu button as a textured gear icon with hover/press feedback.
-- Three layers: BG (rounded dark), Border (gray outline), Icon (gear).
-- If textures are not available, falls back to a simple colored rectangle.
function MDB_BarIndicator:renderMenuButton()
    local w = self.width
    local h = self.height
    local isHover = self.showTooltip or false
    local isPressed = self.moving or false

    if self.menuTexturesReady then
        -- Brightness multiplier for hover/press feedback
        local brightness = isPressed and 1.2 or (isHover and 1.0 or 0.7)

        -- Layer 1: BG (rounded dark, subtle tint)
        local bgAlpha = isPressed and 0.7 or (isHover and 0.5 or 0.3)
        self:drawTextureScaled(self.menuBgTex, 0, 0, w, h, bgAlpha, 0.15, 0.15, 0.15)

        -- Layer 2: Border (gray rounded outline)
        local borderBright = brightness * 0.6
        self:drawTextureScaled(self.menuBorderTex, 0, 0, w, h, 0.8, borderBright, borderBright, borderBright)

        -- Layer 3: Gear icon centered, 70% of button size
        local iconSize = math.floor(math.min(w, h) * 0.7)
        local iconX = math.floor((w - iconSize) / 2)
        local iconY = math.floor((h - iconSize) / 2)
        self:drawTextureScaled(self.menuIconTex, iconX, iconY, iconSize, iconSize, 1, brightness, brightness, brightness)
    else
        -- Fallback: simple colored rectangle on hover only
        if isHover then
            self:drawRectStatic(0, 0, w, h, 0.5, 0.6, 0.6, 0.6)
        end
    end

    -- Tooltip (simplified for menu: just the name and tutorial hints)
    self:renderTooltip(1)

    -- Position persistence and bringToTop
    self:checkPositionChanged()
    self:handleBringToTop()

    return ISUIElement.render(self)
end

-- ========================================================================
-- Vertical bar rendering (dispatch)
-- ========================================================================

--- Render a vertical bar using ThreePatch textures (with rect fallback).
-- @param value  number  Normalized stat value (0-1)
function MDB_BarIndicator:renderVerticalBar(value)
    -- Draw the icon above the bar
    self:renderIcon(true)

    if not self.threePatchReady then
        -- Fallback: simple filled rectangle when textures are missing
        local innerWidth = self.innerWidth
        local innerHeight = math.floor((self.innerHeight * value) + 0.5)
        local border_t = self.borderSizes.t + ((self.height - self.borderSizes.t - self.borderSizes.b) - innerHeight)
        self:drawRectStatic(
            self.borderSizes.l, border_t,
            innerWidth, innerHeight,
            self.color.alpha, self.color.red, self.color.green, self.color.blue
        )
        return
    end
    local w = self.width
    local h = self.height
    local bgAlpha = 0.6

    -- 1. Draw full-size background ThreePatch (dark gray tint)
    NeatTool.ThreePatch.drawVertical(
        self, 0, 0, w, h,
        self.tpVBgTop, self.tpVBgMiddle, self.tpVBgBottom,
        bgAlpha, 0.15, 0.15, 0.15
    )

    -- 2. Draw stencil-clipped fill ThreePatch (stat color)
    local fillHeight = math.floor(h * value + 0.5)
    if fillHeight > 0 then
        local fillY = h - fillHeight
        self:setStencilRect(0, fillY, w, fillHeight)
        NeatTool.ThreePatch.drawVertical(
            self, 0, 0, w, h,
            self.tpVFgTop, self.tpVFgMiddle, self.tpVFgBottom,
            self.color.alpha, self.color.red, self.color.green, self.color.blue
        )
        self:clearStencilRect()
    end
end

-- ========================================================================
-- Horizontal bar rendering (dispatch)
-- ========================================================================

--- Render a horizontal bar using ThreePatch textures (with rect fallback).
-- @param value  number  Normalized stat value (0-1)
function MDB_BarIndicator:renderHorizontalBar(value)
    -- Draw the icon to the side of the bar
    self:renderIcon(false)

    if not self.threePatchReady then
        -- Fallback: simple filled rectangle when textures are missing
        local innerWidth = math.floor((self.innerWidth * value) + 0.5)
        local innerHeight = self.innerHeight
        local border_t = self.borderSizes.t
        self:drawRectStatic(
            self.borderSizes.l, border_t,
            innerWidth, innerHeight,
            self.color.alpha, self.color.red, self.color.green, self.color.blue
        )
        return
    end
    local w = self.width
    local h = self.height
    local bgAlpha = 0.6

    -- 1. Draw full-size background ThreePatch (dark gray tint)
    NeatTool.ThreePatch.drawHorizontal(
        self, 0, 0, w, h,
        self.tpHBgLeft, self.tpHBgMiddle, self.tpHBgRight,
        bgAlpha, 0.15, 0.15, 0.15
    )

    -- 2. Draw stencil-clipped fill ThreePatch (stat color)
    local fillWidth = math.floor(w * value + 0.5)
    if fillWidth > 0 then
        self:setStencilRect(0, 0, fillWidth, h)
        NeatTool.ThreePatch.drawHorizontal(
            self, 0, 0, w, h,
            self.tpHFgLeft, self.tpHFgMiddle, self.tpHFgRight,
            self.color.alpha, self.color.red, self.color.green, self.color.blue
        )
        self:clearStencilRect()
    end
end

-- ========================================================================
-- Icon rendering
-- ========================================================================

--- Render the stat icon adjacent to the bar.
-- Vertical: icon is drawn above the bar, centered horizontally.
-- Horizontal: icon is drawn to the left (or right if isIconRight) of the bar.
-- Ported from v42.13 lines 334-390.
--
-- @param isVerticalLayout  boolean  true for vertical bar layout
function MDB_BarIndicator:renderIcon(isVerticalLayout)
    if not self.showImage or not self.imageName then return end

    local tex = getTexture(self.imageName)
    if not tex then return end

    local size = self.imageSize or 22
    local w = size
    local h = size
    local x, y

    if isVerticalLayout then
        -- Center the icon horizontally above the bar
        x = (-w * 0.5) + self:getWidth() * 0.5
        y = -w

        -- Moodlet background behind the icon (severity-colored frame)
        if self.imageShowBack and self.texBG and self.statId ~= "calorie" then
            self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
        end

        -- Slight offset for non-special stat icons to visually center them
        -- within the moodlet background frame
        if self.statId ~= "temperature" and self.statId ~= "calorie" then
            if w % 2 == 0 then
                x = x + 1
                y = y + 1
            else
                y = y + 1
            end
        end

        self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
    else
        -- Horizontal layout: icon to the left of the bar (default)
        x = -h
        if self.isIconRight then
            -- Or to the right if configured
            x = self:getWidth()
        end
        -- Center the icon vertically alongside the bar
        y = (-h * 0.5) + self:getHeight() * 0.5

        -- Moodlet background behind the icon
        if self.imageShowBack and self.texBG and self.statId ~= "calorie" then
            self:drawTextureScaled(self.texBG, x, y, w, h, 1, 1, 1, 1)
        end

        -- Slight offset for non-special stat icons
        if self.statId ~= "temperature" and self.statId ~= "calorie" then
            if h % 2 == 0 then
                x = x + 1
                y = y + 1
            else
                y = y + 1
            end
        end

        self:drawTextureScaledAspect(tex, x, y, w, h, 1, 1, 1, 1)
    end
end

-- ========================================================================
-- Moodlet background texture
-- ========================================================================

--- Update the moodlet background texture (the colored frame behind icons).
-- The texture depends on the moodlet severity for this stat: good/bad/neutral
-- and level 0-4 determine which Moodle_Bkg_*.png is selected.
-- Ported from v42.13 lines 301-323.
function MDB_BarIndicator:updateMoodletBackground()
    if not self.imageShowBack then return end

    local def = MDB_StatDefs.byId[self.statId]
    if not def or not def.moodleType then return end

    -- Resolve the moodleType string to the PZ MoodleType enum value
    local moodleType = MDB_BarIndicator.resolveMoodleType(def.moodleType)
    if moodleType then
        self.texBG = self:getImageBG(self.isoPlayer, moodleType)

        -- Temperature has two possible moodlet types (hyperthermia / hypothermia).
        -- If the primary type has no active moodlet, try the alternate.
        if self.statId == "temperature" and not self.texBG and def.moodleTypeAlt then
            local altMoodleType = MDB_BarIndicator.resolveMoodleType(def.moodleTypeAlt)
            if altMoodleType then
                self.texBG = self:getImageBG(self.isoPlayer, altMoodleType)
            end
        end
    end
end

--- Convert a moodleType definition string to the PZ MoodleType enum.
-- The stat definitions store moodleType as a string (e.g. "MoodleType.HUNGRY")
-- to keep MDB_StatDefs free of runtime-only globals. This function resolves
-- those strings to the actual Java enum values exposed to Lua.
--
-- @param moodleTypeStr  string  e.g. "MoodleType.HUNGRY"
-- @return userdata|nil  The MoodleType enum value, or nil if not found
function MDB_BarIndicator.resolveMoodleType(moodleTypeStr)
    if not moodleTypeStr then return nil end

    local moodleTypes = {
        ["MoodleType.HUNGRY"]        = MoodleType.HUNGRY,
        ["MoodleType.THIRSTY"]       = MoodleType.THIRSTY,
        ["MoodleType.THIRST"]        = MoodleType.THIRSTY,
        ["MoodleType.ENDURANCE"]     = MoodleType.ENDURANCE,
        ["MoodleType.TIRED"]         = MoodleType.TIRED,
        ["MoodleType.BORED"]         = MoodleType.BORED,
        ["MoodleType.UNHAPPY"]       = MoodleType.UNHAPPY,
        ["MoodleType.STRESSED"]      = MoodleType.STRESS,
        ["MoodleType.STRESS"]        = MoodleType.STRESS,
        ["MoodleType.FoodEaten"]     = MoodleType.FoodEaten,
        ["MoodleType.UNCOMFORTABLE"] = MoodleType.UNCOMFORTABLE,
        ["MoodleType.HYPERTHERMIA"]  = MoodleType.HYPERTHERMIA,
        ["MoodleType.HYPOTHERMIA"]   = MoodleType.HYPOTHERMIA,
        ["MoodleType.WET"]           = MoodleType.WET,
    }
    return moodleTypes[moodleTypeStr]
end

-- ========================================================================
-- Threshold lines
-- ========================================================================

--- Draw thin lines across the bar at moodlet severity thresholds.
-- These help the player see at a glance where each severity level starts.
-- Lines below the current value are drawn black; lines above are white.
--
-- @param value  number  Normalized stat value (0-1)
function MDB_BarIndicator:renderThresholdLines(value)
    if not self.showMoodletThresholdLines then return end

    local thresholds = self.moodletThresholdTable
    if not thresholds or type(thresholds) ~= "table" then return end

    for _, v in pairs(thresholds) do
        -- Line color: black if the bar fill reaches past this threshold,
        -- white if the bar has not filled to this level yet
        local tColor = { red = 0, green = 0, blue = 0, alpha = self.color.alpha }
        if value < v then
            tColor.red = 1
            tColor.green = 1
            tColor.blue = 1
        end

        if self.isVertical then
            if self.threePatchReady then
                local tY = self.height - math.floor((self.height * v) + 0.5)
                self:drawRectStatic(0, tY, self.width, 1,
                    self.color.alpha, tColor.red, tColor.green, tColor.blue)
            else
                local tX = self.borderSizes.l
                local tY = self.borderSizes.t
                         + ((self.height - self.borderSizes.t - self.borderSizes.b)
                         - math.floor((self.innerHeight * v) + 0.5))
                self:drawRectStatic(tX, tY, self.innerWidth, 1,
                    self.color.alpha, tColor.red, tColor.green, tColor.blue)
            end
        else
            if self.threePatchReady then
                local tX = math.floor((self.width * v) + 0.5)
                self:drawRectStatic(tX, 0, 1, self.height,
                    self.color.alpha, tColor.red, tColor.green, tColor.blue)
            else
                local tX = math.floor((self.innerWidth * v) + 0.5)
                local tY = self.borderSizes.t
                self:drawRectStatic(tX, tY, 1, self.innerHeight,
                    self.color.alpha, tColor.red, tColor.green, tColor.blue)
            end
        end
    end
end

-- ========================================================================
-- Position change tracking
-- ========================================================================

--- Detect when the bar has been repositioned (e.g. by the PZ move system
-- or MoveBarsTogether panel) and notify the base class so the new position
-- is persisted via MDB_Config's deferred-save approach.
-- Replaces the old inline io_persistence.store() call from v42.13 lines 506-513.
function MDB_BarIndicator:checkPositionChanged()
    if self.moving then return end
    if MDB_IndicatorBase.isEditing then return end

    if self.oldX ~= self.x or self.oldY ~= self.y then
        self.oldX = self.x
        self.oldY = self.y
        -- Inherited from MDB_IndicatorBase: marks the config dirty
        -- and updates the cached position. No file I/O happens here.
        self:onPositionChanged()
    end
end

return MDB_BarIndicator
