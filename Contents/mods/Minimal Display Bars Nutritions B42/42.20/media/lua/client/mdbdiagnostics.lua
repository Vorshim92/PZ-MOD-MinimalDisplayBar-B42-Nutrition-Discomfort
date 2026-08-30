--
-- MDB diagnostics -- temporary, read-only observer.
--
-- A hidden display bar stops rendering (UIElement.render skips invisible elements), so the
-- mod's own code never runs again on it and the moment it went missing leaves no trace. This
-- file only watches and prints: it never shows, hides, adds or removes anything.
--
-- What it is trying to tell apart. Once a bar is invisible while its config still says
-- visible, only two things can have done it:
--   1. the bar hid itself in ISGenericMiniDisplayBar:render() because its isoPlayer is nil or
--      reports isDead() -- with the calc constants matching vanilla's own clamps, that is the
--      only internal path left;
--   2. vanilla's ISUIHandler.setVisibleAllUI / CoopCharacterCreation.setVisibleAllUI hid it
--      around the escape menu and failed to restore it, which since ISGenericMiniDisplayBar
--      grew a unique tostring() can only happen when two elements answer the same string.
-- Duplicate strings in the UI list separate the two, so the snapshot counts them.
--
-- Lives in its own global (not under MinimalDisplayBars, which the main file resets to {} as
-- it loads) so nothing here depends on load order. Delete this file once the cause is known.
--

MDBDiagnostics = MDBDiagnostics or {}

local PREFIX = "[MDB-DIAG] "

local CHECK_EVERY_TICKS = 30
local SECONDS_BETWEEN_SNAPSHOTS = 60
local MAX_AUTO_SNAPSHOTS = 3

local tickCounter = 0
local autoSnapshots = 0
local lastSnapshotAt = nil
local notedVanillaHide = false
local notedPlayerDead = false

local function say(line)
    print(PREFIX .. line)
end

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback
end

-- Every bar the mod tracks. The menu box lives in its own table because displayBars
-- deliberately excludes it -- which is also why it is the one element nothing can reach.
local function eachTrackedBar(fn)
    local byPlayer = MinimalDisplayBars and MinimalDisplayBars.displayBars
    if byPlayer then
        for playerIndex, bars in pairs(byPlayer) do
            for idName, bar in pairs(bars) do
                if bar then fn(playerIndex, idName, bar) end
            end
        end
    end
    local menus = MinimalDisplayBars and MinimalDisplayBars.menuBars
    if menus then
        for playerIndex, bar in pairs(menus) do
            if bar then fn(playerIndex, "menu", bar) end
        end
    end
end

local function expectedVisible(bar)
    local tables = MinimalDisplayBars and MinimalDisplayBars.configTables
    local config = tables and tables[bar.coopNum]
    local entry = config and config[bar.idName]
    if not entry then return nil end
    return entry["isVisible"] == true
end

local function actualVisible(bar)
    if not bar.javaObject then return nil end
    return safe(function() return bar:isVisible() == true end, nil)
end

-- True when vanilla is legitimately holding the whole UI hidden (escape menu, Toggle UI
-- keybind, coop character creation). A bar being invisible then is expected, not a fault.
local function vanillaIsHidingEverything()
    if ISUIHandler and ISUIHandler.allUIVisible == false then return true end
    if MainScreen and MainScreen.instance then
        if safe(function() return MainScreen.instance:isVisible() end, false) then return true end
    end
    return false
end

local function scanUiList()
    local ui = UIManager.getUI()
    local rows = {}
    local counts = {}
    local order = {}
    local size = safe(function() return ui:size() end, 0)
    for i = 0, size - 1 do
        local element = ui:get(i)
        local str = safe(function() return tostring(element:toString()) end, "<toString error>")
        local visible = safe(function() return element:isVisible() end, "<error>")
        rows[#rows + 1] = { index = i, str = str, visible = visible }
        if counts[str] == nil then
            counts[str] = 0
            order[#order + 1] = str
        end
        counts[str] = counts[str] + 1
    end
    return rows, counts, order
end

local function describePlayer(bar)
    local player = bar.isoPlayer
    if player == nil then return "isoPlayer=nil" end
    local dead = safe(function() return tostring(player:isDead()) end, "<error>")
    local live = safe(function() return getSpecificPlayer(bar.playerIndex) end, nil)
    -- A stale reference -- the bar still pointing at a previous IsoPlayer -- shows up here and
    -- nowhere else, and would explain a bar hiding itself while the real player is fine.
    local stale = safe(function() return tostring(player ~= live) end, "<error>")
    return "isDead=" .. dead .. " stale=" .. stale
end

function MDBDiagnostics.snapshot(reason)
    local ok, err = pcall(function()
        say("================ snapshot: " .. tostring(reason) .. " ================")

        say("context: allUIVisible=" .. tostring(ISUIHandler and ISUIHandler.allUIVisible)
            .. " visibleUI=" .. tostring(ISUIHandler and ISUIHandler.visibleUI and #ISUIHandler.visibleUI)
            .. " coopVisibleUI=" .. tostring(CoopCharacterCreation and CoopCharacterCreation.visibleUI and #CoopCharacterCreation.visibleUI)
            .. " mainScreenVisible=" .. tostring(MainScreen and MainScreen.instance
                and safe(function() return MainScreen.instance:isVisible() end, "<error>")))

        -- What vanilla recorded on the way in and has not handed back yet.
        if ISUIHandler and ISUIHandler.visibleUI then
            for i, entry in ipairs(ISUIHandler.visibleUI) do
                say("  ISUIHandler.visibleUI[" .. i .. "] = " .. tostring(entry))
            end
        end

        local rows, counts, order = scanUiList()
        say("UIManager.getUI() size=" .. #rows)
        for _, row in ipairs(rows) do
            say(string.format("  [%3d] visible=%-5s %s", row.index, tostring(row.visible), row.str))
        end

        -- The decisive line. Duplicates mean two elements answer the same identity, which is
        -- the only way the restore pass can hand visibility back to the wrong one.
        local duplicates = 0
        for _, str in ipairs(order) do
            if counts[str] > 1 then
                duplicates = duplicates + 1
                say("  DUPLICATE x" .. counts[str] .. " -> " .. str)
            end
        end
        say("duplicate toString values: " .. duplicates)

        say("tracked bars:")
        eachTrackedBar(function(playerIndex, idName, bar)
            local want = expectedVisible(bar)
            local have = actualVisible(bar)
            local str = safe(function() return tostring(bar:tostring()) end, "<tostring error>")
            local inUiList = counts[str] ~= nil
            say(string.format(
                "  p%s %-18s want=%-5s have=%-5s inUiList=%-5s %s  %s",
                tostring(playerIndex), tostring(idName), tostring(want), tostring(have),
                tostring(inUiList), describePlayer(bar), str))
        end)

        say("================ end snapshot ================")
    end)
    if not ok then
        print(PREFIX .. "snapshot failed: " .. tostring(err))
    end
end

local function findDivergence()
    local offender, offendingBar = nil, nil
    eachTrackedBar(function(playerIndex, idName, bar)
        if offender then return end
        if expectedVisible(bar) == true and actualVisible(bar) == false then
            offender = "p" .. tostring(playerIndex) .. " " .. tostring(idName)
            offendingBar = bar
        end
    end)
    return offender, offendingBar
end

-- The player actually being dead hides every bar on purpose, so it is not a fault and must
-- not burn a snapshot slot. Note that this asks the *current* player, not the one the bar is
-- holding: a bar pointing at a stale, dead IsoPlayer while the real one is alive is precisely
-- the fault we are hunting, and has to get through.
local function livePlayerIsDeadOrGone(bar)
    local live = safe(function() return getSpecificPlayer(bar.playerIndex) end, nil)
    if live == nil then return true end
    return safe(function() return live:isDead() end, false) == true
end

local function onRenderTick()
    tickCounter = tickCounter + 1
    if tickCounter < CHECK_EVERY_TICKS then return end
    tickCounter = 0

    if autoSnapshots >= MAX_AUTO_SNAPSHOTS then return end

    local offender, offendingBar = findDivergence()
    if not offender then return end

    if livePlayerIsDeadOrGone(offendingBar) then
        if not notedPlayerDead then
            notedPlayerDead = true
            say("bars hidden while the player is dead or absent (" .. offender
                .. ") -- expected, not reported as a fault")
        end
        return
    end

    -- Don't spend a snapshot slot on vanilla's own deliberate hide; note it once so we can
    -- still tell from the log that it happened and when.
    if vanillaIsHidingEverything() then
        if not notedVanillaHide then
            notedVanillaHide = true
            say("bars hidden while vanilla holds the UI hidden (" .. offender
                .. ") -- expected, not reported as a fault")
        end
        return
    end

    local now = safe(function() return getTimestamp() end, nil)
    if now and lastSnapshotAt and (now - lastSnapshotAt) < SECONDS_BETWEEN_SNAPSHOTS then return end
    lastSnapshotAt = now

    autoSnapshots = autoSnapshots + 1
    MDBDiagnostics.snapshot("auto #" .. autoSnapshots .. " -- " .. offender .. " hidden but config says visible")
end

Events.OnRenderTick.Add(onRenderTick)
