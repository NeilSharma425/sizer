--[[
	PetMenuClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.PetMenuClient

	The PETS window (opened from the PETS tile in the side menu): every pet
	with a live 3D preview and its Sense perk, how to unlock the ones you
	don't have yet, and an EQUIP button for the ones you do. Tabs: MY PETS
	(earned), CRATES (airdrop-only) and EGGS (the egg shop plus egg pets).
	MY PETS opens with a banner for the next pet unlocked by Sense and a
	progress bar towards the total Sense it needs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundFX = select(2, pcall(function()
	return require(ReplicatedStorage:WaitForChild("SoundFX", 10))
end))
local function sfx(name, opts)
	if type(SoundFX) == "table" then
		pcall(SoundFX.play, name, opts)
	end
end

local RunService = game:GetService("RunService")

local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local GetProgress = remotes:WaitForChild("GetProgress")
local ProgressEvent = remotes:WaitForChild("ProgressEvent")
local EquipPet = remotes:WaitForChild("EquipPet")
local HatchEgg = remotes:WaitForChild("HatchEgg", 20)

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local PINK = Color3.fromRGB(255, 120, 190)
local PANEL = Color3.fromRGB(40, 45, 75)
local TILE = Color3.fromRGB(58, 64, 104)
local GREEN = Color3.fromRGB(80, 210, 70)
local MUTED = Color3.fromRGB(205, 210, 235)

local function corner(target, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 12)
	c.Parent = target
end

local function stroke(target, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or INK
	s.Parent = target
	return s
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
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
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
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = b
	return b
end

local function petPreview(parent, id, props)
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(180, 180, 200)
	viewport.LightColor = WHITE
	viewport.LightDirection = Vector3.new(-1, -1.2, -0.6)
	for key, value in pairs(props) do
		viewport[key] = value
	end
	viewport.Parent = parent
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(4.2, 2.4, -7), Vector3.new(0, 0.2, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local model, animate = Pets.build(id)
	if model then
		model.Parent = viewport
	end
	return viewport, animate
end

--==========================================================================
-- Window
--==========================================================================

local COLUMNS, CARD_W, CARD_H, GAP = 4, 152, 186, 10
-- One scrolling list: the pets you own at the top, then every pet you don't
-- have yet, grouped by how it's unlocked (in this order).
local CATEGORIES = {
	{ title = "EARNED BY PLAYING", color = Color3.fromRGB(255, 120, 190) }, -- every kind not listed below
	{ title = "SENSE MILESTONES", kinds = { sense = true }, color = Color3.fromRGB(255, 200, 50) },
	{ title = "EGG PETS  -  HATCH EGGS IN THE SHOP", kinds = { egg = true }, color = Color3.fromRGB(255, 190, 60) },
	{ title = "AIRDROP CRATE PETS", kinds = { crate = true }, color = Color3.fromRGB(190, 100, 255) },
	{ title = "SHOP EXCLUSIVE", kinds = { pass = true }, color = Color3.fromRGB(80, 200, 120) },
}
local RARITY_RANK = {}
for i, name in ipairs(Pets.AllRarities) do
	RARITY_RANK[name] = i
end
-- Pets of a category, rarest first (pets without a rarity keep list order).
local listedKinds = {}
for _, category in ipairs(CATEGORIES) do
	for kind in pairs(category.kinds or {}) do
		listedKinds[kind] = true
	end
end
local function categoryPets(category)
	local out, indexOf = {}, {}
	for i, pet in ipairs(Pets.List) do
		local kind = pet.rule.kind
		local fits = category.kinds and category.kinds[kind] or (not category.kinds and not listedKinds[kind])
		if fits then
			table.insert(out, pet)
			indexOf[pet.id] = i
		end
	end
	table.sort(out, function(a, b)
		local ra, rb = RARITY_RANK[a.rarity] or 0, RARITY_RANK[b.rarity] or 0
		if ra ~= rb then
			return ra > rb
		end
		return indexOf[a.id] < indexOf[b.id]
	end)
	return out
end
local ROWS = 3 -- rows visible at once; longer lists scroll
local WIDTH = COLUMNS * CARD_W + (COLUMNS - 1) * GAP + 40
local HEIGHT = 84 + ROWS * (CARD_H + GAP) + 14

local gui = Instance.new("ScreenGui")
gui.Name = "SizerPets"
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
-- Reach up over the top bar too, so the shade covers the whole screen.
dim.Position = UDim2.fromOffset(0, -TOP_BAR)
dim.Size = UDim2.new(1, 0, 1, TOP_BAR)
dim.Parent = gui

local window = frame(gui, {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, WIDTH, 0, HEIGHT),
	BackgroundColor3 = PANEL,
	ZIndex = 2,
})
corner(window, UDim.new(0, 22))
stroke(window, 5, PINK)
local windowScale = Instance.new("UIScale")
windowScale.Parent = window
local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		windowScale.Scale = math.clamp(math.min(camera.ViewportSize.Y / (HEIGHT + 30), camera.ViewportSize.X / (WIDTH + 30)), 0.4, 1)
	end
end
updateScale()

label(window, {
	Position = UDim2.new(0, 24, 0, 12),
	Size = UDim2.new(0, 190, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "PETS",
	TextColor3 = PINK,
	ZIndex = 3,
})
local countLabel = label(window, {
	Position = UDim2.new(0, 24, 0, 52),
	Size = UDim2.new(0, 360, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
	TextColor3 = MUTED,
	ZIndex = 3,
})
local closeButton = textButton(window, "X", Color3.fromRGB(235, 80, 80), {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.new(0, 44, 0, 44),
	ZIndex = 4,
})

-- Cartoon close button once the UI icon sheet is uploaded.
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
		ZIndex = closeButton.ZIndex + 1,
	})
end


local grid = Instance.new("ScrollingFrame")
grid.Name = "Pets"
grid.Position = UDim2.new(0, 20, 0, 84)
grid.Size = UDim2.new(1, -26, 1, -98)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 8
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.CanvasSize = UDim2.new(0, 0, 0, ROWS * (CARD_H + GAP))
grid.ZIndex = 3
grid.Parent = window
local animations = {}
local owned, equipped = {}, ""
local render -- defined below
local updateGoal -- refreshes the next pet banner's progress bar, if shown

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- MY PETS banner: the next pet unlocked by total Sense (shown in full colour as a teaser) and
-- a progress bar towards the total Sense it needs.
local function renderGoal(pet, y)
	local card = frame(grid, {
		Name = "NextSensePet",
		Position = UDim2.new(0, 0, 0, y),
		Size = UDim2.new(0, COLUMNS * CARD_W + (COLUMNS - 1) * GAP, 0, CARD_H),
		BackgroundColor3 = TILE,
		ZIndex = 3,
	})
	corner(card, UDim.new(0, 14))
	stroke(card, 4, pet.color)
	local _, animate = petPreview(card, pet.id, {
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 170, 1, -16),
		ZIndex = 4,
	})
	if animate then
		table.insert(animations, animate)
	end
	label(card, {
		Position = UDim2.new(0, 190, 0, 12),
		Size = UDim2.new(0, 300, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "NEXT PET UNLOCK",
		TextColor3 = GOLD,
		ZIndex = 4,
	})
	label(card, {
		Position = UDim2.new(0, 190, 0, 36),
		Size = UDim2.new(1, -210, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(pet.name),
		TextColor3 = pet.color:Lerp(WHITE, 0.25),
		ZIndex = 4,
	})
	label(card, {
		Position = UDim2.new(0, 190, 0, 80),
		Size = UDim2.new(1, -210, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format("+%d%% SENSE WHILE EQUIPPED", math.floor(Pets.perkFor(pet.id) * 100 + 0.5)),
		TextColor3 = Color3.fromRGB(120, 255, 130),
		ZIndex = 4,
	})
	local bar = frame(card, {
		Name = "Progress",
		Position = UDim2.new(0, 190, 0, 112),
		Size = UDim2.new(1, -210, 0, 32),
		BackgroundColor3 = Color3.fromRGB(30, 34, 58),
		ZIndex = 4,
	})
	corner(bar, UDim.new(0, 10))
	stroke(bar, 2, INK)
	local fill = frame(bar, {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = pet.color,
		ZIndex = 5,
	})
	corner(fill, UDim.new(0, 10))
	local amount = label(bar, {
		Name = "Amount",
		Position = UDim2.new(0, 8, 0, 3),
		Size = UDim2.new(1, -16, 1, -6),
		Text = "",
		ZIndex = 6,
	})
	label(card, {
		Position = UDim2.new(0, 190, 0, 150),
		Size = UDim2.new(1, -210, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Earn Sense from every guess, daily challenges and live rounds!",
		TextColor3 = MUTED,
		ZIndex = 4,
	})
	updateGoal = function()
		if not card.Parent then
			return
		end
		local sense = player:GetAttribute("Sense") or 0
		local need = pet.rule.sense
		fill.Size = UDim2.fromScale(math.clamp(sense / need, 0, 1), 1)
		amount.Text = string.format("%s / %s SENSE EARNED", commas(math.min(sense, need)), commas(need))
	end
	updateGoal()
end


--==========================================================================
-- Hatching: eggs are bought in the SHOP (ShopClient), which opens this window and hatches the egg here
--==========================================================================

local function spendable()
	return math.max(0, math.floor((player:GetAttribute("Sense") or 0) - (player:GetAttribute("SenseSpent") or 0)))
end

local hatching = false

local overlay = frame(window, {
	Name = "HatchOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(20, 22, 40),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 30,
})
corner(overlay, UDim.new(0, 22))
local hatchEgg = frame(overlay, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0, 130, 0, 165),
	BackgroundColor3 = WHITE,
	ZIndex = 31,
})
corner(hatchEgg, UDim.new(0.5, 0))
stroke(hatchEgg, 4)
local hatchEggArt = Icons.image(overlay, "basicegg", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0, 160, 0, 190),
	Visible = false,
	ZIndex = 31,
})
local hatchTitle = label(overlay, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.new(0.8, 0, 0, 46), Text = "", ZIndex = 32 })
local hatchSub = label(overlay, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -170), Size = UDim2.new(0.8, 0, 0, 30), Text = "", TextColor3 = MUTED, ZIndex = 32 })
local hatchViewport = nil
local hatchEquip = textButton(overlay, "EQUIP", GREEN, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -8, 1, -60), Size = UDim2.new(0, 170, 0, 50), ZIndex = 32, Visible = false })
local hatchOk = textButton(overlay, "OK", Color3.fromRGB(95, 105, 140), { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.5, 8, 1, -60), Size = UDim2.new(0, 170, 0, 50), ZIndex = 32, Visible = false })
local hatchedId = nil

local function closeOverlay()
	overlay.Visible = false
	if hatchViewport then
		hatchViewport:Destroy()
		hatchViewport = nil
	end
	hatching = false
	render()
end
hatchOk.MouseButton1Click:Connect(closeOverlay)
hatchEquip.MouseButton1Click:Connect(function()
	if hatchedId then
		equipped = hatchedId
		sfx("equip")
		EquipPet:FireServer(hatchedId)
	end
	closeOverlay()
end)

local function hatch(egg)
	if hatching or not HatchEgg or spendable() < egg.price then
		return
	end
	hatching = true
	overlay.Visible = true
	-- The egg's cartoon picture once the shop icon sheet is uploaded,
	-- otherwise a plain colored egg.
	local art = egg.id .. "egg"
	local eggShown = hatchEgg
	hatchEgg.Visible = false
	hatchEggArt.Visible = false
	if Icons.has(art) then
		Icons.set(hatchEggArt, art)
		eggShown = hatchEggArt
	end
	eggShown.Visible = true
	hatchEgg.BackgroundColor3 = egg.color
	eggShown.Rotation = 0
	hatchTitle.Text = string.upper(egg.name)
	hatchTitle.TextColor3 = WHITE
	hatchSub.Text = "Hatching..."
	hatchEquip.Visible = false
	hatchOk.Visible = false

	local ok, result = pcall(function()
		return HatchEgg:InvokeServer(egg.id)
	end)
	-- Wobble while it hatches.
	for i = 1, 8 do
		eggShown.Rotation = (i % 2 == 0 and 1 or -1) * (6 + i * 2)
		task.wait(0.12)
	end
	eggShown.Rotation = 0
	if not ok or type(result) ~= "table" or not result.ok then
		hatchSub.Text = (type(result) == "table" and result.error) or "Couldn't hatch right now."
		hatchOk.Visible = true
		return
	end

	eggShown.Visible = false
	local rarity = Pets.Rarities[result.rarity]
	local animate
	hatchViewport, animate = petPreview(overlay, result.petId, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0, 260, 0, 200),
		ZIndex = 31,
	})
	if animate then
		table.insert(animations, animate)
	end
	hatchTitle.Text = (result.new and "NEW! " or "") .. string.upper(result.name)
	hatchTitle.TextColor3 = rarity and rarity.color or WHITE
	if result.new then
		hatchSub.Text = string.format("%s  -  +%d%% SENSE WHEN EQUIPPED", string.upper(result.rarity), math.floor(Pets.perkFor(result.petId) * 100 + 0.5))
		owned[result.petId] = true
		hatchedId = result.petId
		hatchEquip.Visible = equipped ~= result.petId
	else
		hatchSub.Text = string.format("You already have it  -  %d Sense back", result.refund)
		hatchedId = nil
	end
	hatchOk.Visible = true
	sfx(result.new and "hatch" or "toast")
end

-- One pet card at (x, y) in the grid.
local function petCard(pet, x, y)
	local has = owned[pet.id] == true
	local isOn = has and equipped == pet.id
	local card = frame(grid, {
		Name = "Pet_" .. pet.id,
		Position = UDim2.new(0, x, 0, y),
		Size = UDim2.new(0, CARD_W, 0, CARD_H),
		BackgroundColor3 = TILE,
		ZIndex = 3,
	})
	corner(card, UDim.new(0, 14))
	local rarity = pet.rarity and Pets.Rarities[pet.rarity]
	stroke(card, isOn and 4 or 3, isOn and GOLD or (rarity and rarity.color) or (has and pet.color or INK))
	local perk = Pets.perkFor(pet.id)
	if perk > 0 then
		label(card, {
			Name = "Perk",
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(0, 90, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format("+%d%% SENSE", math.floor(perk * 100 + 0.5)),
			TextColor3 = Color3.fromRGB(120, 255, 130),
			ZIndex = 6,
		})
	end

	local viewport, animate = petPreview(card, pet.id, {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 0, 84),
		ZIndex = 4,
	})
	if has then
		if animate then
			table.insert(animations, animate)
		end
	else
		-- Locked pets show as a dark silhouette.
		viewport.ImageColor3 = Color3.new(0, 0, 0)
		viewport.Ambient = Color3.new(0, 0, 0)
		viewport.LightColor = Color3.new(0, 0, 0)
	end
	label(card, {
		Position = UDim2.new(0, 4, 0, 92),
		Size = UDim2.new(1, -8, 0, 22),
		Text = has and string.upper(pet.name) or (pet.rarity and (string.upper(pet.rarity) .. " ???") or "???"),
		TextColor3 = has and pet.color:Lerp(WHITE, 0.3) or (rarity and rarity.color) or Color3.fromRGB(150, 155, 185),
		ZIndex = 4,
	})
	if has then
		local button = textButton(card, isOn and "EQUIPPED" or "EQUIP", isOn and Color3.fromRGB(95, 105, 140) or GREEN, {
			Name = "EquipButton",
			Position = UDim2.new(0, 8, 1, -50),
			Size = UDim2.new(1, -16, 0, 40),
			ZIndex = 4,
		})
		button.MouseButton1Click:Connect(function()
			if equipped ~= pet.id then
				equipped = pet.id
				sfx("equip")
				EquipPet:FireServer(pet.id)
				render()
			end
		end)
	else
		label(card, {
			Position = UDim2.new(0, 6, 0, 118),
			Size = UDim2.new(1, -12, 0, 62),
			TextWrapped = true,
			Text = pet.how,
			TextColor3 = GOLD,
			ZIndex = 4,
		})
	end
end

render = function()
	for _, child in ipairs(grid:GetChildren()) do
		child:Destroy()
	end
	animations = {}
	updateGoal = nil
	local fullWidth = COLUMNS * CARD_W + (COLUMNS - 1) * GAP
	local y = 0
	local function header(text, color)
		label(grid, {
			Name = "Header",
			Position = UDim2.new(0, 2, 0, y),
			Size = UDim2.new(0, fullWidth, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = text,
			TextColor3 = color,
			ZIndex = 4,
		})
		y += 38
	end
	local function cards(list)
		for i, pet in ipairs(list) do
			local col = (i - 1) % COLUMNS
			local row = math.floor((i - 1) / COLUMNS)
			petCard(pet, col * (CARD_W + GAP), y + row * (CARD_H + GAP))
		end
		y += math.ceil(#list / COLUMNS) * (CARD_H + GAP)
	end

	-- Your pets first (newest kinds in category order, rarest first).
	local mine, total = {}, 0
	for _, category in ipairs(CATEGORIES) do
		for _, pet in ipairs(categoryPets(category)) do
			total += 1
			if owned[pet.id] then
				table.insert(mine, pet)
			end
		end
	end
	header(string.format("MY PETS  (%d)", #mine), PINK)
	if #mine == 0 then
		label(grid, {
			Position = UDim2.new(0, 2, 0, y),
			Size = UDim2.new(0, fullWidth, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			Text = "No pets yet - unlock them below!",
			TextColor3 = MUTED,
			ZIndex = 4,
		})
		y += 44
	else
		cards(mine)
	end

	-- The next pet unlocked by total Sense.
	local goal = Pets.nextSensePet(owned)
	if goal then
		renderGoal(goal, y)
		y += CARD_H + GAP
	end

	-- Then the pets still to get, by category.
	for _, category in ipairs(CATEGORIES) do
		local locked = {}
		for _, pet in ipairs(categoryPets(category)) do
			if not owned[pet.id] then
				table.insert(locked, pet)
			end
		end
		if #locked > 0 then
			header(category.title, category.color)
			cards(locked)
		end
	end

	grid.CanvasSize = UDim2.new(0, 0, 0, math.max(y, ROWS * (CARD_H + GAP)))
	countLabel.Text = string.format("%d / %d UNLOCKED   -   %s SENSE TO SPEND", #mine, total, commas(spendable()))
end

local loading = false
local function open()
	if loading then
		return
	end
	loading = true
	local ok, snapshot = pcall(function()
		return GetProgress:InvokeServer()
	end)
	loading = false
	if not ok or type(snapshot) ~= "table" then
		return
	end
	local pets = snapshot.pets or {}
	owned = pets.owned or {}
	equipped = pets.equipped or ""
	render()
	updateScale()
	sfx("window")
	gui.Enabled = true
end

closeButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)
dim.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

local function refreshBalance()
	if gui.Enabled and not hatching then
		render()
	end
end
player:GetAttributeChangedSignal("SenseSpent"):Connect(refreshBalance)
player:GetAttributeChangedSignal("Sense"):Connect(function()
	if gui.Enabled and updateGoal then
		updateGoal()
	end
end)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		local t = os.clock()
		for _, animate in ipairs(animations) do
			animate(t)
		end
	end
end)

-- A newly unlocked pet shows up straight away if the window is open.
ProgressEvent.OnClientEvent:Connect(function(kind)
	if kind == "pet" and gui.Enabled then
		task.delay(0.5, function()
			if gui.Enabled then
				local ok, snapshot = pcall(function()
					return GetProgress:InvokeServer()
				end)
				if ok and type(snapshot) == "table" and snapshot.pets then
					owned = snapshot.pets.owned or owned
					equipped = snapshot.pets.equipped or equipped
					render()
				end
			end
		end)
	end
end)

task.spawn(function()
	local hud = playerGui:WaitForChild("SizerHUD", 30)
	local menu = hud and hud:WaitForChild("SideMenu", 10)
	local tile = menu and menu:WaitForChild("PetsButton", 10)
	if tile then
		tile.MouseButton1Click:Connect(open)
	end
end)

-- Buying an egg from the SHOP: open this window on the eggs tab and hatch
-- it here (ShopClient sets the bus attribute ShopHatch = "<eggId>|<time>").
task.spawn(function()
	local bus = playerGui:WaitForChild("SizerBus", 30)
	if not bus then
		return
	end
	bus:GetAttributeChangedSignal("ShopHatch"):Connect(function()
		local id = tostring(bus:GetAttribute("ShopHatch") or ""):match("^([^|]+)")
		local egg = id and Pets.getEgg(id)
		if not egg or hatching then
			return
		end
		open()
		if not gui.Enabled then
			return
		end
		hatch(egg)
	end)
end)
