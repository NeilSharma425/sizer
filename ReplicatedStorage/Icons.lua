--[[
	Icons.lua
	ModuleScript: ReplicatedStorage.Icons

	Bright cartoon icons in the Roblox simulator style, packed into one
	1024x1024 image, assets/IconSheet.png, in 170-pixel cells (6 per row).

	A second sheet, assets/IconSheet2.png, holds the UI button pictures and
	a third, assets/IconSheet3.png, the shop items.
	To turn a sheet on, upload it once (Studio: View > Asset Manager > Bulk
	Import, then right-click the image > Copy Asset ID) and paste the number
	into SHEETS below. Until then its icons show as emoji (or drawn shapes).
	Icons.has(key) says whether key's picture is ready.

	Icons.image(parent, key, props) -> an ImageLabel showing that icon (or a
	TextLabel with the emoji while there is no sheet). props are applied to
	it (Size, Position, AnchorPoint, ...).
	Icons.set(icon, key) changes which icon an Icons.image shows.
	Icons.emoji(key) -> the emoji for key.
	Icons.fade(icon, value) -> a property table for tweening its transparency.
]]

local Icons = {}

-- Uploaded asset IDs of the sheets (0 = not uploaded yet; its icons then
-- show their emoji, or the menu's drawn shape, instead).
local SHEETS = {
	72109873353372, -- assets/IconSheet.png
	102148871559476, -- assets/IconSheet2.png (UI buttons)
	109211451649395, -- assets/IconSheet3.png (shop items)
}
local CELL = 170

-- key = { x, y, emoji, sheet } (pixel offset of the icon's cell on its
-- sheet; sheet 1 when left out)
local CELLS = {
	sprout = { 0, 0, "🌱" },
	eyes = { 170, 0, "👀" },
	target = { 340, 0, "🎯" },
	ruler = { 510, 0, "📏" },
	triangle_ruler = { 680, 0, "📐" },
	scales = { 850, 0, "⚖" },
	brain = { 0, 170, "🧠" },
	medal = { 170, 170, "🏅" },
	crown = { 340, 170, "👑" },
	glowing_star = { 510, 170, "🌟" },
	elephant = { 680, 170, "🐘" },
	statue = { 850, 170, "🗽" },
	mind_blown = { 0, 340, "🤯" },
	planet = { 170, 340, "🪐" },
	stopwatch = { 340, 340, "⏱" },
	dice = { 510, 340, "🎲" },
	globe = { 680, 340, "🌍" },
	swords = { 850, 340, "⚔" },
	fire = { 0, 510, "🔥" },
	paw = { 170, 510, "🐾" },
	trophy = { 340, 510, "🏆" },
	calendar = { 510, 510, "📅" },
	star = { 680, 510, "⭐" },
	sparkles = { 850, 510, "✨" },
	party = { 0, 680, "🎉" },
	confetti = { 170, 680, "🎊" },
	check = { 340, 680, "✅" },
	grad_cap = { 510, 680, "🎓" },
	arrow_down = { 680, 680, "⬇" },
	point_up = { 850, 680, "👆" },
	point_down = { 0, 850, "👇" },
	-- sheet 3: shop items
	double = { 0, 0, "✖", 3 },
	vip = { 170, 0, "💎", 3 },
	diamondfox = { 340, 0, "🦊", 3 },
	streakshield = { 510, 0, "🛡", 3 },
	basicegg = { 680, 0, "🥚", 3 },
	goldenegg = { 850, 0, "🌕", 3 },
	shopbag = { 0, 170, "🛍", 3 },
	-- sheet 2: UI buttons
	help = { 0, 0, "❓", 2 },
	playtime = { 170, 0, "🎁", 2 },
	coin = { 340, 0, "🪙", 2 },
	close = { 510, 0, "❌", 2 },
	play = { 680, 0, "▶", 2 },
	bolt = { 850, 0, "⚡", 2 },
}

-- Emoji -> key, so data that still stores an emoji (rank icons, station
-- icons) can look up its picture.
local byEmoji = {}
for key, cell in pairs(CELLS) do
	byEmoji[cell[3]] = key
	byEmoji[cell[3] .. "\u{FE0F}"] = key
end

function Icons.enabled()
	return SHEETS[1] ~= 0
end

-- Accepts a key ("fire") or an emoji ("🔥").
local function resolve(key)
	if CELLS[key] then
		return key
	end
	return byEmoji[key]
end
Icons.resolve = resolve

local function sheetOf(k)
	return SHEETS[CELLS[k][4] or 1] or 0
end

-- True when key has a picture ready (its sheet is uploaded).
function Icons.has(key)
	local k = resolve(key)
	return k ~= nil and sheetOf(k) ~= 0
end

function Icons.emoji(key)
	local k = resolve(key)
	return k and CELLS[k][3] or key or ""
end

function Icons.set(icon, key)
	local k = resolve(key)
	icon:SetAttribute("Icon", k) -- which icon it shows (handy when debugging)
	if icon:IsA("ImageLabel") then
		if k and sheetOf(k) ~= 0 then
			icon.Image = "rbxassetid://" .. sheetOf(k)
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
	if Icons.has(key) then
		icon = Instance.new("ImageLabel")
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
