--[[
	ShopClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ShopClient

	The SHOP window (opened from the SHOP tile on the side menu):
	  - PET EGGS: bought with Sense. Buying hands over to the PETS window
	    (PetMenuClient) through the bus attribute ShopHatch, which hatches
	    the egg there and takes the Sense.
	  - ROBUX: the game passes and developer products in ReplicatedStorage
	    .Shop. Items whose ID is still 0 show "SOON".
	Also offers "Save my streak" once, right after a login where a streak
	of 2+ days ended (server attribute StreakSavable).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage:WaitForChild("Shop"))
local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))
local ScreenFit = require(ReplicatedStorage:WaitForChild("ScreenFit"))

local SoundFX = select(2, pcall(function()
	return require(ReplicatedStorage:WaitForChild("SoundFX", 10))
end))
local function sfx(name)
	if type(SoundFX) == "table" then
		pcall(SoundFX.play, name)
	end
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local bus = playerGui:WaitForChild("SizerBus", 20)

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local PANEL = Color3.fromRGB(40, 45, 75)
local CARD = Color3.fromRGB(58, 64, 104)
local GREEN = Color3.fromRGB(80, 210, 70)
local GRAY = Color3.fromRGB(95, 105, 140)
local MUTED = Color3.fromRGB(190, 195, 225)
local SHOP_COLOR = Color3.fromRGB(80, 200, 120)

--==========================================================================
-- UI helpers
--==========================================================================

local function corner(target, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 12)
	c.Parent = target
end

local function stroke(target, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = target
	return s
end

local function textStroke(target, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = target
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for key, value in pairs(props) do
		f[key] = value
	end
	f.Parent = parent
	return f
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = WHITE
	for key, value in pairs(props) do
		l[key] = value
	end
	l.Parent = parent
	textStroke(l, 2)
	return l
end

local function textButton(parent, text, color, props)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.Text = text
	for key, value in pairs(props) do
		b[key] = value
	end
	b.Parent = parent
	corner(b, UDim.new(0, 10))
	stroke(b, 3)
	textStroke(b, 2)
	return b
end

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function spendable()
	return math.max(0, math.floor((player:GetAttribute("Sense") or 0) - (player:GetAttribute("SenseSpent") or 0)))
end

--==========================================================================
-- Window
--==========================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SizerShop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local TOP_BAR = 80 -- more than Roblox's top bar inset on any device
local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Text = ""
dim.AutoButtonColor = false
dim.BorderSizePixel = 0
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Position = UDim2.fromOffset(0, -TOP_BAR)
dim.Size = UDim2.new(1, 0, 1, TOP_BAR)
dim.Parent = gui

local WIDTH, HEIGHT = 640, 540
local window = frame(gui, {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, WIDTH, 0, HEIGHT),
	BackgroundColor3 = PANEL,
	ZIndex = 2,
})
corner(window, UDim.new(0, 22))
stroke(window, 5, SHOP_COLOR)
ScreenFit.fit(window, WIDTH + 40, HEIGHT + 40, { fx = 1, fy = 1, min = 0.45, max = 1 })

Icons.image(window, Icons.has("shopbag") and "shopbag" or "coin", {
	Position = UDim2.new(0, 14, 0, 6),
	Size = UDim2.fromOffset(58, 58),
	Rotation = -10,
	ZIndex = 4,
})
label(window, {
	Position = UDim2.new(0, 80, 0, 12),
	Size = UDim2.new(0, 200, 0, 46),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "SHOP",
	TextColor3 = SHOP_COLOR:Lerp(WHITE, 0.3),
	ZIndex = 3,
})
local balanceLabel = label(window, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -76, 0, 20),
	Size = UDim2.new(0, 260, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "0 SENSE",
	TextColor3 = GOLD,
	ZIndex = 3,
})

local closeButton = textButton(window, "X", Color3.fromRGB(235, 80, 80), {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 14),
	Size = UDim2.new(0, 44, 0, 44),
	ZIndex = 4,
})
if Icons.has("close") then
	closeButton.Text = ""
	closeButton.BackgroundTransparency = 1
	for _, child in ipairs(closeButton:GetChildren()) do
		if child:IsA("UIStroke") or child:IsA("UICorner") then
			child:Destroy()
		end
	end
	Icons.image(closeButton, "close", {
		Position = UDim2.fromScale(-0.1, -0.1),
		Size = UDim2.fromScale(1.2, 1.2),
		ZIndex = 5,
	})
end

local list = Instance.new("ScrollingFrame")
list.Name = "Items"
list.Position = UDim2.new(0, 16, 0, 72)
list.Size = UDim2.new(1, -32, 1, -88)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ZIndex = 3
list.Parent = window
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = list

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function heading(text, color)
	label(list, {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -12, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		TextColor3 = color,
		ZIndex = 3,
	})
end

-- One row: picture, name, a line of detail, and a button on the right.
local function card(name, detail, icon)
	local row = frame(list, {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -12, 0, 92),
		BackgroundColor3 = CARD,
		ZIndex = 3,
	})
	corner(row, UDim.new(0, 14))
	stroke(row, 3)
	local picture
	if type(icon) == "string" then
		picture = Icons.image(row, icon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(76, 76),
			ZIndex = 4,
		})
	else
		-- An egg: a colored oval.
		picture = frame(row, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 22, 0.5, 0),
			Size = UDim2.fromOffset(52, 66),
			BackgroundColor3 = icon,
			ZIndex = 4,
		})
		corner(picture, UDim.new(0.5, 0))
		stroke(picture, 3)
	end
	label(row, {
		Position = UDim2.new(0, 96, 0, 8),
		Size = UDim2.new(1, -260, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
		ZIndex = 4,
	})
	local detailLabel = label(row, {
		Position = UDim2.new(0, 96, 0, 40),
		Size = UDim2.new(1, -260, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = MUTED,
		Text = detail,
		ZIndex = 4,
	})
	local button = textButton(row, "", GREEN, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 54),
		ZIndex = 4,
	})
	return row, button, detailLabel
end

--==========================================================================
-- Pet eggs (Sense)
--==========================================================================

heading("PET EGGS - PAY WITH SENSE", GOLD)

local function oddsText(egg)
	local parts = {}
	for _, rarity in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }) do
		if egg.odds[rarity] then
			table.insert(parts, string.format("%d%% %s", egg.odds[rarity], rarity))
		end
	end
	return table.concat(parts, "  ")
end

local eggButtons = {}
for _, egg in ipairs(Pets.Eggs) do
	local eggArt = egg.id .. "egg"
	local _, button = card(string.upper(egg.name), oddsText(egg), Icons.has(eggArt) and eggArt or egg.color)
	button.Name = "Buy_" .. egg.id
	eggButtons[egg.id] = { button = button, egg = egg }
	button.MouseButton1Click:Connect(function()
		if spendable() < egg.price then
			sfx("bad")
			return
		end
		sfx("click")
		gui.Enabled = false
		if bus then
			bus:SetAttribute("ShopHatch", egg.id .. "|" .. tostring(os.clock()))
		end
	end)
end

local function refreshEggs()
	local balance = spendable()
	balanceLabel.Text = string.format("YOU HAVE %s SENSE", commas(balance))
	for _, entry in pairs(eggButtons) do
		local affordable = balance >= entry.egg.price
		entry.button.Text = string.format("%s SENSE", commas(entry.egg.price))
		entry.button.BackgroundColor3 = affordable and GREEN or GRAY
		entry.button.AutoButtonColor = affordable
	end
end

--==========================================================================
-- Robux items
--==========================================================================

heading("ROBUX", Color3.fromRGB(120, 230, 140))

local prices = {} -- [id] = Robux price read from Roblox
local passButtons = {}
local productButtons = {}

for _, pass in ipairs(Shop.Passes) do
	local _, button = card(pass.name, pass.blurb, Shop.iconFor(pass, Icons))
	button.Name = "Pass_" .. pass.key
	passButtons[pass.key] = { button = button, pass = pass }
	button.MouseButton1Click:Connect(function()
		if pass.id == 0 or player:GetAttribute(Shop.attribute(pass.key)) then
			return
		end
		sfx("click")
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	end)
end

for _, product in ipairs(Shop.Products) do
	local _, button, detail = card(product.name, product.blurb, Shop.iconFor(product, Icons))
	button.Name = "Product_" .. product.key
	productButtons[product.key] = { button = button, product = product, detail = detail }
	button.MouseButton1Click:Connect(function()
		if product.id == 0 then
			return
		end
		if product.key == "saveStreak" and (player:GetAttribute("StreakSavable") or 0) < 2 then
			return
		end
		sfx("click")
		MarketplaceService:PromptProductPurchase(player, product.id)
	end)
end

local function priceText(item)
	return string.format("R$ %d", prices[item.id] or item.price)
end

local function refreshRobux()
	for key, entry in pairs(passButtons) do
		local button = entry.button
		if player:GetAttribute(Shop.attribute(key)) then
			button.Text = "OWNED"
			button.BackgroundColor3 = GRAY
		elseif entry.pass.id == 0 then
			button.Text = "SOON"
			button.BackgroundColor3 = GRAY
		else
			button.Text = priceText(entry.pass)
			button.BackgroundColor3 = GREEN
		end
	end
	local streak = productButtons.saveStreak
	if streak then
		local lost = player:GetAttribute("StreakSavable") or 0
		if streak.product.id == 0 then
			streak.button.Text = "SOON"
			streak.button.BackgroundColor3 = GRAY
		elseif lost >= 2 then
			streak.button.Text = priceText(streak.product)
			streak.button.BackgroundColor3 = GREEN
			streak.detail.Text = string.format("Your %d-day streak ended today. Get it back before midnight!", lost)
		else
			streak.button.Text = "NOT NEEDED"
			streak.button.BackgroundColor3 = GRAY
			streak.detail.Text = streak.product.blurb .. " (Only when you miss a day.)"
		end
	end
end

-- Reads the real Robux prices once (the Creator Hub may differ from the
-- fallback labels).
local pricesLoaded = false
local function loadPrices()
	if pricesLoaded then
		return
	end
	pricesLoaded = true
	task.spawn(function()
		for _, pass in ipairs(Shop.Passes) do
			if pass.id ~= 0 then
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, pass.id, Enum.InfoType.GamePass)
				if ok and type(info) == "table" and info.PriceInRobux then
					prices[pass.id] = info.PriceInRobux
				end
			end
		end
		for _, product in ipairs(Shop.Products) do
			if product.id ~= 0 then
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, product.id, Enum.InfoType.Product)
				if ok and type(info) == "table" and info.PriceInRobux then
					prices[product.id] = info.PriceInRobux
				end
			end
		end
		refreshRobux()
	end)
end

local function refresh()
	refreshEggs()
	refreshRobux()
end

local function open()
	refresh()
	loadPrices()
	sfx("window")
	gui.Enabled = true
end

local function close()
	gui.Enabled = false
end
closeButton.MouseButton1Click:Connect(close)
dim.MouseButton1Click:Connect(close)

for _, attribute in ipairs({ "Sense", "SenseSpent", "StreakSavable" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
end
for _, pass in ipairs(Shop.Passes) do
	player:GetAttributeChangedSignal(Shop.attribute(pass.key)):Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
end

-- The SHOP tile on the side menu (built by ScaleGuesserClient).
task.spawn(function()
	local hud = playerGui:WaitForChild("SizerHUD", 30)
	local menu = hud and hud:WaitForChild("SideMenu", 10)
	local tile = menu and menu:WaitForChild("ShopButton", 10)
	if tile then
		tile.MouseButton1Click:Connect(open)
	end
end)

--==========================================================================
-- "Save my streak" offer, once per session after a streak ends
--==========================================================================

local offerGui = Instance.new("ScreenGui")
offerGui.Name = "SizerStreakOffer"
offerGui.ResetOnSpawn = false
offerGui.DisplayOrder = 8
offerGui.Enabled = false
offerGui.Parent = playerGui

local offer = frame(offerGui, {
	Name = "Offer",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 420, 0, 240),
	BackgroundColor3 = PANEL,
})
corner(offer, UDim.new(0, 20))
stroke(offer, 5, Color3.fromRGB(255, 140, 40))
ScreenFit.fit(offer, 460, 280, { fx = 0.9, fy = 0.8, max = 1 })
Icons.image(offer, Icons.has("streakshield") and "streakshield" or "fire", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.fromOffset(80, 80),
	ZIndex = 2,
})
local offerTitle = label(offer, {
	Position = UDim2.new(0, 20, 0, 40),
	Size = UDim2.new(1, -40, 0, 40),
	Text = "YOUR STREAK ENDED!",
	TextColor3 = Color3.fromRGB(255, 170, 70),
})
local offerText = label(offer, {
	Position = UDim2.new(0, 24, 0, 84),
	Size = UDim2.new(1, -48, 0, 56),
	Font = Enum.Font.GothamBold,
	TextColor3 = MUTED,
	TextWrapped = true,
	Text = "",
})
local offerBuy = textButton(offer, "SAVE IT", GREEN, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(0.5, -8, 1, -18),
	Size = UDim2.new(0, 170, 0, 56),
})
local offerSkip = textButton(offer, "NO THANKS", GRAY, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 8, 1, -18),
	Size = UDim2.new(0, 150, 0, 56),
})
offerSkip.MouseButton1Click:Connect(function()
	offerGui.Enabled = false
end)
offerBuy.MouseButton1Click:Connect(function()
	offerGui.Enabled = false
	local product = Shop.getProduct("saveStreak")
	if product and product.id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, product.id)
	end
end)

local function inLobby()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local panel = hud and hud:FindFirstChild("GamePanel")
	return not (panel and panel.Visible)
end

task.spawn(function()
	local product = Shop.getProduct("saveStreak")
	if not product or product.id == 0 then
		return
	end
	local waited = 0
	while not player:GetAttribute("DataLoaded") and waited < 30 do
		task.wait(0.5)
		waited += 0.5
	end
	-- Let the login streak window and toasts go first.
	task.wait(8)
	local lost = player:GetAttribute("StreakSavable") or 0
	if lost < 2 then
		return
	end
	while not inLobby() or (playerGui:FindFirstChild("SizerStreak") and playerGui.SizerStreak.Enabled) do
		task.wait(1)
	end
	lost = player:GetAttribute("StreakSavable") or 0
	if lost < 2 then
		return
	end
	offerTitle.Text = string.format("YOUR %d-DAY STREAK ENDED!", lost)
	offerText.Text = string.format("Get it back for R$ %d and carry on from day %d.", prices[product.id] or product.price, lost + 1)
	offerGui.Enabled = true
end)
