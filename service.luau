--!nonstrict
-- Cursor Size
--
-- Applies the configured cursor size at Noctalia startup and whenever the
-- "size" setting changes. The cursor theme is left untouched.
--
-- On niri the size lives in the compositor config
-- (cursor { xcursor-size 48 }); apply-niri.sh rewrites that line, validates the
-- result with `niri validate` and lets niri hot-reload the config. On Hyprland
-- and Sway it uses the runtime IPC commands. GTK apps get the same size through
-- gsettings.
--
-- Manual control:
--   noctalia msg plugin my-tools/cursor-size:service all set 64
--   noctalia msg plugin my-tools/cursor-size:service all apply

local DEFAULT_SIZE = 48
local MIN_SIZE = 16
local MAX_SIZE = 128

local function clampSize(value)
    local n = math.floor(value)
    if n < MIN_SIZE then
        return MIN_SIZE
    end
    if n > MAX_SIZE then
        return MAX_SIZE
    end
    return n
end

local function configuredSize()
    local value = noctalia.getConfig("size")
    if type(value) == "number" then
        return clampSize(value)
    end
    return DEFAULT_SIZE
end

local function applyGsettings(size)
    if not noctalia.commandExists("gsettings") then
        return
    end
    noctalia.runAsync({
        "gsettings", "set", "org.gnome.desktop.interface", "cursor-size", tostring(size),
    })
end

local function applyNiri(size)
    local dir = noctalia.pluginDir()
    if dir == nil then
        noctalia.log("cursor-size: pluginDir() unavailable")
        return false
    end

    local script = dir .. "/apply-niri.sh"
    if not noctalia.fileExists(script) then
        noctalia.log("cursor-size: helper not found: " .. script)
        return false
    end

    noctalia.runAsync({ "bash", script, tostring(size) }, function(result)
        if result.exitCode ~= 0 then
            noctalia.log("cursor-size: niri apply failed: " .. tostring(result.stderr))
        else
            noctalia.log("cursor-size: " .. tostring(result.stdout))
        end
    end)
    return true
end

local function applyHyprland(size)
    if not noctalia.commandExists("hyprctl") then
        return false
    end
    -- The theme is whatever the session already uses.
    local theme = noctalia.getenv("XCURSOR_THEME") or "Adwaita"
    noctalia.runAsync({ "hyprctl", "setcursor", theme, tostring(size) })
    noctalia.log("cursor-size: hyprctl setcursor " .. theme .. " " .. size)
    return true
end

local function applySway(size)
    if not noctalia.commandExists("swaymsg") then
        return false
    end
    local theme = noctalia.getenv("XCURSOR_THEME") or "Adwaita"
    noctalia.runAsync({ "swaymsg", "seat", "-", "xcursor_theme", theme, tostring(size) })
    noctalia.log("cursor-size: sway xcursor_theme " .. theme .. " " .. size)
    return true
end

local function apply(size)
    size = clampSize(size or configuredSize())
    applyGsettings(size)

    local desktop = string.lower(noctalia.getenv("XDG_CURRENT_DESKTOP") or "")

    if noctalia.getenv("NIRI_SOCKET") ~= nil or string.find(desktop, "niri", 1, true) then
        return applyNiri(size)
    elseif noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE") ~= nil then
        return applyHyprland(size)
    elseif noctalia.getenv("SWAYSOCK") ~= nil then
        return applySway(size)
    end

    noctalia.log("cursor-size: compositor not recognized; applied GTK cursor size " .. size)
    return true
end

apply(configuredSize())

function onConfigChanged()
    apply(configuredSize())
end

function onIpc(event, payload)
    if event == "set" then
        local size = tonumber(payload)
        if size == nil then
            noctalia.notifyError("Cursor Size", "Payload must be a number, e.g. 64")
            return
        end
        size = clampSize(size)
        apply(size)
        noctalia.notify("Cursor Size", "Cursor size set to " .. size .. " px")
    elseif event == "apply" then
        local size = configuredSize()
        apply(size)
        noctalia.notify("Cursor Size", "Cursor size applied: " .. size .. " px")
    end
end
