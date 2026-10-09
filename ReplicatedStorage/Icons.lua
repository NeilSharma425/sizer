--[[
	Icons.lua
	ModuleScript: ReplicatedStorage.Icons

	Bright 3D cartoon icons (Microsoft Fluent Emoji 3D, MIT licence - see
	assets/IconSheet-LICENSE.txt) packed into one 1024x1024 image,
	assets/IconSheet.png, in 128-pixel cells.

	To turn them on, upload assets/IconSheet.png once (Studio: View > Asset
	Manager > Bulk Import, then right-click the image > Copy Asset ID) and
	paste the number into SHEET_ID below. Until then every icon shows as its
	emoji instead, in the same spot.

	Icons.image(parent, key, props) -> an ImageLabel showing that icon (or a
	TextLabel with the emoji while there is no sheet). props are applied to
	it (Size, Position, AnchorPoint, ...).
	Icons.set(icon, key) changes which icon an Icons.image shows.
	Icons.emoji(key) -> the emoji for key.
	Icons.fade(icon, value) -> a property table for tweening its transparency.
]]

local Icons = {}

local SHEET_ID = 0 -- paste the uploaded IconSheet.png's asset ID here
local CELL = 128

-- key = { x, y, emoji } (pixel offset of the icon's cell on the sheet)
local CELLS = {
	sprout = { 0, 0, "🌱" },
	eyes = { 128, 0, "👀" },
	target = { 256, 0, "🎯" },
	ruler = { 384, 0, "📏" },
	triangle_ruler = { 512, 0, "📐" },
	scales = { 640, 0, "⚖" },
	brain = { 768, 0, "🧠" },
	medal = { 896, 0, "🏅" },
	crown = { 0, 128, "👑" },
	glowing_star = { 128, 128, "🌟" },
	elephant = { 256, 128, "🐘" },
	statue = { 384, 128, "🗽" },
	mind_blown = { 512, 128, "🤯" },
	planet = { 640, 128, "🪐" },
	stopwatch = { 768, 128, "⏱" },
	dice = { 896, 128, "🎲" },
	globe = { 0, 256, "🌍" },
	swords = { 128, 256, "⚔" },
	fire = { 256, 256, "🔥" },
	paw = { 384, 256, "🐾" },
	trophy = { 512, 256, "🏆" },
	calendar = { 640, 256, "📅" },
	star = { 768, 256, "⭐" },
	sparkles = { 896, 256, "✨" },
	party = { 0, 384, "🎉" },
	confetti = { 128, 384, "🎊" },
	check = { 256, 384, "✅" },
	grad_cap = { 384, 384, "🎓" },
	arrow_down = { 512, 384, "⬇" },
	point_up = { 640, 384, "👆" },
	point_down = { 768, 384, "👇" },
	gift = { 896, 384, "🎁" },
	coffee = { 0, 512, "☕" },
}

-- Emoji -> key, so data that still stores an emoji (rank icons, station
-- icons) can look up its picture.
local byEmoji = {}
for key, cell in pairs(CELLS) do
	byEmoji[cell[3]] = key
	byEmoji[cell[3] .. "\u{FE0F}"] = key
end

function Icons.enabled()
	return SHEET_ID ~= 0
end

-- Accepts a key ("fire") or an emoji ("🔥").
local function resolve(key)
	if CELLS[key] then
		return key
	end
	return byEmoji[key]
end
Icons.resolve = resolve

function Icons.emoji(key)
	local k = resolve(key)
	return k and CELLS[k][3] or key or ""
end

function Icons.set(icon, key)
	local k = resolve(key)
	if icon:IsA("ImageLabel") then
		if k then
			icon.ImageRectOffset = Vector2.new(CELLS[k][1], CELLS[k][2])
			icon.ImageTransparency = 0
		else
			icon.ImageTransparency = 1
		end
	else
		icon.Text = k and CELLS[k][3] or (key or "")
	end
end

-- { ImageTransparency = value } or { TextTransparency = value }, for tweens.
function Icons.fade(icon, value)
	if icon:IsA("ImageLabel") then
		return { ImageTransparency = value }
	end
	return { TextTransparency = value }
end

function Icons.image(parent, key, props)
	local icon
	if Icons.enabled() then
		icon = Instance.new("ImageLabel")
		icon.Image = "rbxassetid://" .. SHEET_ID
		icon.ImageRectSize = Vector2.new(CELL, CELL)
		icon.ScaleType = Enum.ScaleType.Fit
	else
		icon = Instance.new("TextLabel")
		icon.TextScaled = true
		icon.Font = Enum.Font.GothamBlack
		icon.TextColor3 = Color3.new(1, 1, 1)
	end
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Size = UDim2.fromOffset(40, 40)
	for k, v in pairs(props or {}) do
		icon[k] = v
	end
	Icons.set(icon, key)
	icon.Parent = parent
	return icon
end

return Icons
