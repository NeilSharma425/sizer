--[[
	PetMenuClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.PetMenuClient

	The PETS window (opened from the PETS tile in the side menu): every pet
	with a live 3D preview, how to unlock the ones you don't have yet, and an
	EQUIP button for the ones you do.
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local GetProgress = remotes:WaitForChild("GetProgress")
local ProgressEvent = remotes:WaitForChild("ProgressEvent")
local EquipPet = remotes:WaitForChild("EquipPet")

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
local ROWS = math.ceil(#Pets.List / COLUMNS)
local WIDTH = COLUMNS * CARD_W + (COLUMNS - 1) * GAP + 40
local HEIGHT = 84 + ROWS * (CARD_H + GAP) + 14

local gui = Instance.new("ScreenGui")
gui.Name = "SizerPets"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Text = ""
dim.AutoButtonColor = false
dim.BorderSizePixel = 0
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Size = UDim2.fromScale(1, 1)
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
	Size = UDim2.new(0, 260, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "MY PETS",
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

local grid = frame(window, {
	Name = "Pets",
	Position = UDim2.new(0, 20, 0, 84),
	Size = UDim2.new(1, -40, 1, -98),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
local animations = {}
local owned, equipped = {}, ""

local function render()
	for _, child in ipairs(grid:GetChildren()) do
		child:Destroy()
	end
	animations = {}
	local count = 0
	for i, pet in ipairs(Pets.List) do
		local has = owned[pet.id] == true
		if has then
			count += 1
		end
		local row = math.floor((i - 1) / COLUMNS)
		local col = (i - 1) % COLUMNS
		local isOn = has and equipped == pet.id
		local card = frame(grid, {
			Name = "Pet_" .. pet.id,
			Position = UDim2.new(0, col * (CARD_W + GAP), 0, row * (CARD_H + GAP)),
			Size = UDim2.new(0, CARD_W, 0, CARD_H),
			BackgroundColor3 = TILE,
			ZIndex = 3,
		})
		corner(card, UDim.new(0, 14))
		stroke(card, isOn and 4 or 3, isOn and GOLD or (has and pet.color or INK))

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
			Text = has and string.upper(pet.name) or "???",
			TextColor3 = has and pet.color:Lerp(WHITE, 0.3) or Color3.fromRGB(150, 155, 185),
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
	countLabel.Text = string.format("%d / %d UNLOCKED", count, #Pets.List)
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
