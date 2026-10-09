--[[
	StreakClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.StreakClient

	The streak rewards window: a 14-day track showing what each day of a
	login streak pays, the pets that only streaks can unlock (days 3, 7 and
	14), and the compounding Sense bonus. Opens when the streak pill is
	tapped, and automatically on the first login of a day.
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

local Progress = require(ReplicatedStorage:WaitForChild("Progress"))
local Pets = require(ReplicatedStorage:WaitForChild("Pets"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local GetProgress = remotes:WaitForChild("GetProgress")
local ProgressEvent = remotes:WaitForChild("ProgressEvent")
local EquipPet = remotes:WaitForChild("EquipPet")
local MarkHint = remotes:WaitForChild("MarkHint")
local bus = playerGui:WaitForChild("SizerBus", 20)

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local ORANGE = Color3.fromRGB(255, 140, 40)
local PANEL = Color3.fromRGB(40, 45, 75)
local TILE = Color3.fromRGB(58, 64, 104)
local GREEN = Color3.fromRGB(80, 210, 70)

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
	s.Parent = target
	return s
end

local function textStroke(target, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2.5
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

-- A gold coin drawn from shapes.
local function drawCoin(parent, size, position)
	local coin = frame(parent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.new(0, size, 0, size),
		BackgroundColor3 = GOLD,
	})
	corner(coin, UDim.new(1, 0))
	stroke(coin, 3)
	local inner = frame(coin, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.64, 0.64),
		BackgroundColor3 = Color3.fromRGB(255, 225, 120),
	})
	corner(inner, UDim.new(1, 0))
	local bar = frame(inner, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.2, 0.6),
		BackgroundColor3 = Color3.fromRGB(215, 150, 20),
	})
	corner(bar, UDim.new(0, 2))
	return coin
end

local function drawCheck(parent)
	local disc = frame(parent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundColor3 = GREEN,
		ZIndex = 6,
	})
	corner(disc, UDim.new(1, 0))
	stroke(disc, 3)
	local short = frame(disc, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.38, 0, 0.58, 0),
		Size = UDim2.new(0, 6, 0, 12),
		BackgroundColor3 = WHITE,
		Rotation = -40,
		ZIndex = 7,
	})
	corner(short, UDim.new(0, 2))
	local long = frame(disc, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.58, 0, 0.5, 0),
		Size = UDim2.new(0, 6, 0, 20),
		BackgroundColor3 = WHITE,
		Rotation = 40,
		ZIndex = 7,
	})
	corner(long, UDim.new(0, 2))
end

-- A small ViewportFrame showing a pet; returns the frame and an update(t).
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

local gui = Instance.new("ScreenGui")
gui.Name = "SizerStreak"
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

local WIDTH, HEIGHT = 700, 556
local window = frame(gui, {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, WIDTH, 0, HEIGHT),
	BackgroundColor3 = PANEL,
	ZIndex = 2,
})
corner(window, UDim.new(0, 22))
stroke(window, 5, ORANGE)
local windowScale = Instance.new("UIScale")
windowScale.Parent = window
local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		windowScale.Scale = math.clamp(math.min(camera.ViewportSize.Y / (HEIGHT + 40), camera.ViewportSize.X / (WIDTH + 40)), 0.45, 1)
	end
end
updateScale()

-- Header
label(window, {
	Position = UDim2.new(0, 24, 0, 14),
	Size = UDim2.new(0, 360, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "DAILY STREAK",
	TextColor3 = ORANGE,
	ZIndex = 3,
})
local subtitle = label(window, {
	Position = UDim2.new(0, 24, 0, 56),
	Size = UDim2.new(1, -160, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Play every day. Rewards keep growing!",
	TextColor3 = Color3.fromRGB(205, 210, 235),
	ZIndex = 3,
})
local closeButton = textButton(window, "X", Color3.fromRGB(235, 80, 80), {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.new(0, 44, 0, 44),
	ZIndex = 4,
})
local bonusPill = frame(window, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -72, 0, 22),
	Size = UDim2.new(0, 190, 0, 36),
	BackgroundColor3 = Color3.fromRGB(30, 33, 56),
	ZIndex = 3,
})
corner(bonusPill, UDim.new(1, 0))
stroke(bonusPill, 3, GOLD)
local bonusLabel = label(bonusPill, {
	Position = UDim2.new(0, 10, 0, 4),
	Size = UDim2.new(1, -20, 1, -8),
	Text = "+0% SENSE",
	TextColor3 = GOLD,
	ZIndex = 4,
})

-- Day tiles
local grid = frame(window, {
	Name = "Days",
	Position = UDim2.new(0, 20, 0, 92),
	Size = UDim2.new(1, -40, 0, 252),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
local TILE_W, TILE_H, GAP = 86, 120, 8
local animations = {}

local function clearGrid()
	for _, child in ipairs(grid:GetChildren()) do
		child:Destroy()
	end
	animations = {}
end

local function buildTiles(count)
	clearGrid()
	for day = 1, 14 do
		local reward = Progress.streakReward(day)
		local claimed = day < count
		local isToday = day == count
		local row = math.floor((day - 1) / 7)
		local col = (day - 1) % 7
		local tile = frame(grid, {
			Name = "Day" .. day,
			Position = UDim2.new(0, col * (TILE_W + GAP), 0, row * (TILE_H + GAP)),
			Size = UDim2.new(0, TILE_W, 0, TILE_H),
			BackgroundColor3 = reward.pet and Color3.fromRGB(78, 62, 120) or TILE,
			ZIndex = 3,
		})
		corner(tile, UDim.new(0, 14))
		stroke(tile, isToday and 4 or 3, isToday and GOLD or (reward.pet and Color3.fromRGB(255, 170, 230) or INK))

		label(tile, {
			Position = UDim2.new(0, 4, 0, 4),
			Size = UDim2.new(1, -8, 0, 18),
			Text = "DAY " .. day,
			TextColor3 = isToday and GOLD or Color3.fromRGB(205, 210, 235),
			ZIndex = 4,
		})
		if reward.pet then
			local _, animate = petPreview(tile, reward.pet, {
				Position = UDim2.new(0, 4, 0, 24),
				Size = UDim2.new(1, -8, 0, 64),
				ZIndex = 4,
			})
			if animate then
				table.insert(animations, animate)
			end
		else
			drawCoin(tile, 40, UDim2.new(0.5, 0, 0, 56))
		end
		label(tile, {
			Position = UDim2.new(0, 4, 1, -30),
			Size = UDim2.new(1, -8, 0, 22),
			Text = "+" .. reward.sense,
			TextColor3 = GOLD,
			ZIndex = 4,
		})
		if reward.pet then
			local info = Pets.get(reward.pet)
			label(tile, {
				Position = UDim2.new(0, 2, 1, -12),
				Size = UDim2.new(1, -4, 0, 12),
				Text = info and string.upper(info.name) or "PET",
				TextColor3 = Color3.fromRGB(255, 170, 230),
				ZIndex = 4,
			})
		end
		if claimed or isToday then
			local cover = frame(tile, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = isToday and 0.7 or 0.45,
				ZIndex = 5,
			})
			corner(cover, UDim.new(0, 14))
			drawCheck(cover)
		end
	end
end

-- Pets row
local petsRow = frame(window, {
	Name = "Pets",
	Position = UDim2.new(0, 20, 0, 354),
	Size = UDim2.new(1, -40, 0, 140),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
local petCards = {}

local function buildPets(owned, equipped)
	for _, child in ipairs(petsRow:GetChildren()) do
		child:Destroy()
	end
	petCards = {}
	label(petsRow, {
		Position = UDim2.new(0, 2, 0, 0),
		Size = UDim2.new(0, 260, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "STREAK-ONLY PETS",
		TextColor3 = Color3.fromRGB(255, 170, 230),
		ZIndex = 4,
	})
	local cardW = (WIDTH - 40 - 2 * GAP) / 3
	local streakPets = {}
	for _, pet in ipairs(Pets.List) do
		if pet.rule.kind == "streak" then
			table.insert(streakPets, pet)
		end
	end
	for i, pet in ipairs(streakPets) do
		local has = owned[pet.id] == true
		local card = frame(petsRow, {
			Name = "Pet_" .. pet.id,
			Position = UDim2.new(0, (i - 1) * (cardW + GAP), 0, 26),
			Size = UDim2.new(0, cardW, 0, 112),
			BackgroundColor3 = TILE,
			ZIndex = 3,
		})
		corner(card, UDim.new(0, 14))
		stroke(card, 3, has and pet.color or INK)
		local viewport, animate = petPreview(card, pet.id, {
			Position = UDim2.new(0, 6, 0, 6),
			Size = UDim2.new(0, 96, 0, 100),
			ZIndex = 4,
		})
		if animate then
			table.insert(animations, animate)
		end
		if not has then
			-- Silhouette: darken the preview.
			viewport.ImageColor3 = Color3.new(0, 0, 0)
			viewport.ImageTransparency = 0.1
			viewport.Ambient = Color3.new(0, 0, 0)
			viewport.LightColor = Color3.new(0, 0, 0)
		end
		label(card, {
			Position = UDim2.new(0, 108, 0, 8),
			Size = UDim2.new(1, -114, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = has and string.upper(pet.name) or "???",
			TextColor3 = has and pet.color:Lerp(WHITE, 0.3) or Color3.fromRGB(150, 155, 185),
			ZIndex = 4,
		})
		if has then
			local isOn = equipped == pet.id
			local btn = textButton(card, isOn and "EQUIPPED" or "EQUIP", isOn and Color3.fromRGB(95, 105, 140) or GREEN, {
				Name = "EquipButton",
				Position = UDim2.new(0, 108, 1, -42),
				Size = UDim2.new(1, -118, 0, 32),
				ZIndex = 4,
			})
			btn.MouseButton1Click:Connect(function()
				if equipped ~= pet.id then
					sfx("equip")
					EquipPet:FireServer(pet.id)
					equipped = pet.id
					buildPets(owned, equipped)
				end
			end)
			label(card, {
				Position = UDim2.new(0, 108, 0, 34),
				Size = UDim2.new(1, -114, 0, 32),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				TextScaled = true,
				Text = pet.blurb,
				TextColor3 = Color3.fromRGB(205, 210, 235),
				ZIndex = 4,
			})
		else
			label(card, {
				Position = UDim2.new(0, 108, 0, 40),
				Size = UDim2.new(1, -114, 0, 40),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "REACH DAY " .. pet.rule.day,
				TextColor3 = GOLD,
				ZIndex = 4,
			})
		end
		petCards[pet.id] = card
	end
end

-- Footer
local footer = label(window, {
	Position = UDim2.new(0, 24, 1, -44),
	Size = UDim2.new(1, -48, 0, 28),
	Text = "",
	TextColor3 = Color3.fromRGB(205, 210, 235),
	ZIndex = 3,
})

--==========================================================================
-- Opening, closing, refreshing
--==========================================================================

local function render(snapshot)
	local count = snapshot.streak.count
	local pets = snapshot.pets or { owned = {}, equipped = "" }
	buildTiles(count)
	buildPets(pets.owned or {}, pets.equipped or "")
	local bonus = math.floor(Progress.streakBonus(count) * 100 + 0.5)
	bonusLabel.Text = string.format("+%d%% SENSE", bonus)
	if count < 1 then
		footer.Text = "Come back tomorrow to start your streak!"
	elseif count < 14 then
		local nextReward = Progress.streakReward(count + 1)
		footer.Text = string.format("DAY %d  -  tomorrow: +%d SENSE%s", count, nextReward.sense, nextReward.pet and " + A NEW PET" or "")
	else
		footer.Text = string.format("DAY %d  -  every day now pays +%d SENSE (+500 bonus every 7th day)", count, Progress.streakReward(count + 1).sense)
	end
	if count >= 10 then
		subtitle.Text = "Max streak bonus reached. Keep it going!"
	else
		subtitle.Text = "Play every day. Rewards and your Sense bonus keep growing!"
	end
end

local opening = false
local function open()
	if opening then
		return
	end
	opening = true
	local ok, snapshot = pcall(function()
		return GetProgress:InvokeServer()
	end)
	opening = false
	if not ok or type(snapshot) ~= "table" or not snapshot.streak then
		return
	end
	render(snapshot)
	updateScale()
	sfx("window")
	gui.Enabled = true
end

local function close()
	gui.Enabled = false
end

closeButton.MouseButton1Click:Connect(close)
dim.MouseButton1Click:Connect(close)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		local t = os.clock()
		for _, animate in ipairs(animations) do
			animate(t)
		end
	end
end)

-- The streak pill (built by ProgressClient) opens the window.
task.spawn(function()
	local progressGui = playerGui:WaitForChild("SizerProgress", 30)
	local row = progressGui and progressGui:WaitForChild("ProgressRow", 10)
	local pill = row and row:WaitForChild("StreakPill", 10)
	if pill then
		pill.MouseButton1Click:Connect(open)
	end
end)

-- First login of the day: show what today's streak earned.
ProgressEvent.OnClientEvent:Connect(function(kind, payload)
	if kind ~= "login" or type(payload) ~= "table" then
		return
	end
	-- Day 1 is skipped: new players already have plenty on screen.
	if payload.count >= 2 and (player:GetAttribute("TutorialDone") == true or payload.pet) then
		task.delay(1.6, function()
			local hud = playerGui:FindFirstChild("SizerHUD")
			local panel = hud and hud:FindFirstChild("GamePanel")
			if not (panel and panel.Visible) then
				open()
			end
		end)
	end
end)

--==========================================================================
-- Tapping DAILY after it's done opens this window; the first time a player
-- finishes the daily, a spotlight points them at that button.
--==========================================================================

local hintGui = Instance.new("ScreenGui")
hintGui.Name = "SizerStreakHint"
hintGui.ResetOnSpawn = false
hintGui.DisplayOrder = 6
hintGui.Enabled = false
hintGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hintGui.Parent = playerGui

local hintRing = frame(hintGui, { BackgroundTransparency = 1, ZIndex = 3 })
corner(hintRing, UDim.new(0, 18))
local hintRingStroke = stroke(hintRing, 5, GOLD)
local hintCard = frame(hintGui, {
	AnchorPoint = Vector2.new(0, 0.5),
	Size = UDim2.new(0, 280, 0, 84),
	BackgroundColor3 = PANEL,
	ZIndex = 4,
})
corner(hintCard, UDim.new(0, 16))
stroke(hintCard, 4, GOLD)
label(hintCard, {
	Position = UDim2.new(0, 14, 0, 8),
	Size = UDim2.new(1, -28, 1, -16),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "TAP DAILY AGAIN TO SEE YOUR STREAK REWARDS",
	ZIndex = 5,
})

local hintShown = false
local hintToken = 0
local function hideHint()
	hintShown = false
	hintToken += 1
	hintGui.Enabled = false
end

local function dailyTile()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local menu = hud and hud:FindFirstChild("SideMenu")
	return menu and menu:FindFirstChild("DailyButton")
end

RunService.RenderStepped:Connect(function()
	if not hintShown then
		return
	end
	local tile = dailyTile()
	if not tile then
		return
	end
	local pad = 8
	local grow = 3 + 3 * (0.5 + 0.5 * math.sin(os.clock() * 6))
	local pos, size = tile.AbsolutePosition, tile.AbsoluteSize
	hintRing.Position = UDim2.fromOffset(pos.X - pad - grow, pos.Y - pad - grow)
	hintRing.Size = UDim2.fromOffset(size.X + (pad + grow) * 2, size.Y + (pad + grow) * 2)
	hintRingStroke.Transparency = 0.1 + 0.4 * (0.5 + 0.5 * math.sin(os.clock() * 6))
	hintCard.Position = UDim2.fromOffset(pos.X + size.X + pad + 18, pos.Y + size.Y / 2)
end)

local function markSeen()
	if player:GetAttribute("StreakHintSeen") ~= true then
		player:SetAttribute("StreakHintSeen", true)
		MarkHint:FireServer("streak")
	end
end

-- Shown once ever: it counts as seen as soon as it appears.
local function showHint()
	hideHint()
	hintShown = true
	hintGui.Enabled = true
	markSeen()
	local myToken = hintToken
	task.delay(20, function()
		if hintToken == myToken then
			hideHint()
		end
	end)
end

if bus then
	bus:GetAttributeChangedSignal("OpenStreak"):Connect(function()
		if hintShown then
			markSeen()
		end
		hideHint()
		open()
	end)

	-- Detect the daily being finished during this session (false -> true).
	local lastDone = bus:GetAttribute("DailyDone")
	local pending = false
	bus:GetAttributeChangedSignal("DailyDone"):Connect(function()
		local done = bus:GetAttribute("DailyDone")
		if lastDone == false and done == true and player:GetAttribute("StreakHintSeen") ~= true then
			pending = true
		end
		lastDone = done
	end)
	task.spawn(function()
		while true do
			task.wait(0.3)
			if pending then
				local hud = playerGui:FindFirstChild("SizerHUD")
				local panel = hud and hud:FindFirstChild("GamePanel")
				local dailyCard = hud and hud:FindFirstChild("DailyCard")
				local tile = dailyTile()
				if panel and not panel.Visible and not (dailyCard and dailyCard.Visible) and tile and tile.Parent and tile.Parent.Visible and not gui.Enabled then
					pending = false
					showHint()
				end
			end
		end
	end)
end
