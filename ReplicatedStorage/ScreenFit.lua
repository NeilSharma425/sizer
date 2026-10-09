--[[
	ScreenFit.lua
	ModuleScript: ReplicatedStorage.ScreenFit

	Keeps pop-ups, banners and menus a sensible size on every screen,
	especially phones. fit(guiObject, w, h, opts) adds a UIScale so a box
	designed at w x h pixels takes up at most opts.fx of the screen's width
	and opts.fy of its height (clamped between opts.min and opts.max), and
	keeps it updated as the screen changes. isCompact() is true on phone-
	sized screens, where the HUD switches to its phone layout.
]]

local ScreenFit = {}

-- Phone-sized: a touch screen that is short (landscape) or narrow. A small
-- window on a computer (e.g. Studio with panels open) keeps the desktop layout.
function ScreenFit.isCompact(viewport)
	viewport = viewport or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
	if not viewport then
		return false
	end
	local UserInputService = game:GetService("UserInputService")
	if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
		return false
	end
	return viewport.Y < 540 or viewport.X < 700
end

-- The scale for a w x h box under the limits in opts.
function ScreenFit.scaleFor(viewport, w, h, opts)
	opts = opts or {}
	local fx, fy = opts.fx or 0.9, opts.fy or 0.9
	local value = math.min(viewport.X * fx / w, viewport.Y * fy / h)
	return math.clamp(value, opts.min or 0.4, opts.max or 1)
end

local fitted = {} -- { scale, w, h, opts }
local watching = false

local function refresh()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	for i = #fitted, 1, -1 do
		local entry = fitted[i]
		if entry.scale.Parent then
			entry.scale.Scale = ScreenFit.scaleFor(viewport, entry.w, entry.h, entry.opts) * (entry.opts.mul or 1)
		else
			table.remove(fitted, i)
		end
	end
end

local function watch()
	if watching then
		return
	end
	watching = true
	local function hook()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
		refresh()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hook)
	hook()
end

-- Adds (or reuses) a UIScale on guiObject that keeps it within the screen
-- limits. Returns the UIScale.
function ScreenFit.fit(guiObject, w, h, opts)
	local scale = guiObject:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = guiObject
	end
	table.insert(fitted, { scale = scale, w = w, h = h, opts = opts or {} })
	watch()
	refresh()
	return scale
end

return ScreenFit
