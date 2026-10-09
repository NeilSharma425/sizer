--[[
	OnboardingClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.OnboardingClient

	Picks up where the tutorial leaves off, one nudge at a time:
	  1. right after the tutorial: point at DAILY (the first daily is a
	     short one, 3 questions)
	  2. after the first daily: StreakClient points at DAILY again to show
	     the streak rewards
	  3. then: "YOU UNLOCKED A PET!" pointing at the PETS tile (the server
	     gives the starter pet for finishing the first daily; the player
	     equips it there)
	Each step is remembered on the server (MarkHint) as soon as it shows, so
	it only ever appears once, even if the player ignores it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local ScreenFit = require(ReplicatedStorage:WaitForChild("ScreenFit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local MarkHint = remotes:WaitForChild("MarkHint")
local ProgressEvent = remotes:WaitForChild("ProgressEvent")

local SoundFX = select(2, pcall(function()
	return require(ReplicatedStorage:WaitForChild("SoundFX", 10))
end))
local function sfx(name, opts)
	if type(SoundFX) == "table" then
		pcall(SoundFX.play, name, opts)
	end
end

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local PANEL = Color3.fromRGB(40, 45, 75)
local PINK = Color3.fromRGB(255, 120, 190)
local BLUE = Color3.fromRGB(70, 150, 255)

--==========================================================================
-- Pointer: a pulsing ring around a side-menu tile and a card beside it
--==========================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SizerOnboarding"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local ring = Instance.new("Frame")
ring.BackgroundTransparency = 1
ring.BorderSizePixel = 0
ring.Parent = gui
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(0, 18)
ringCorner.Parent = ring
local ringStroke = Instance.new("UIStroke")
ringStroke.Thickness = 5
ringStroke.Color = GOLD
ringStroke.Parent = ring

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0, 0.5)
card.Size = UDim2.new(0, 320, 0, 104)
card.BackgroundColor3 = PANEL
card.BorderSizePixel = 0
card.Parent = gui
ScreenFit.fit(card, 320, 104, { fx = 0.45, fy = 0.24 })
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 16)
cardCorner.Parent = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Thickness = 4
cardStroke.Color = GOLD
cardStroke.Parent = card

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = WHITE
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = card
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
	return l
end
local titleLabel = label({ Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 34) })
local bodyLabel = label({ Position = UDim2.new(0, 14, 0, 50), Size = UDim2.new(1, -28, 0, 44), TextWrapped = true, TextColor3 = Color3.fromRGB(215, 220, 240) })

-- Small 3D preview of the pet for the "unlocked" step.
local preview = Instance.new("ViewportFrame")
preview.AnchorPoint = Vector2.new(1, 0.5)
preview.Position = UDim2.new(1, -8, 0.5, 0)
preview.Size = UDim2.new(0, 90, 0, 90)
preview.BackgroundTransparency = 1
preview.Ambient = Color3.fromRGB(180, 180, 200)
preview.LightColor = WHITE
preview.Visible = false
preview.Parent = card
local previewCamera = Instance.new("Camera")
previewCamera.FieldOfView = 40
previewCamera.CFrame = CFrame.lookAt(Vector3.new(4.2, 2.4, -7), Vector3.new(0, 0.2, 0))
previewCamera.Parent = preview
preview.CurrentCamera = previewCamera
local previewAnimate = nil

local target = nil -- tile name in the side menu we're pointing at

local function tile(name)
	local hud = playerGui:FindFirstChild("SizerHUD")
	local menu = hud and hud:FindFirstChild("SideMenu")
	return menu and menu:FindFirstChild(name)
end

local function inLobby()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local panel = hud and hud:FindFirstChild("GamePanel")
	local dailyCard = hud and hud:FindFirstChild("DailyCard")
	if (panel and panel.Visible) or (dailyCard and dailyCard.Visible) then
		return false
	end
	for _, name in ipairs({ "SizerStreak", "SizerPets", "SizerStreakHint", "SizerTutorial" }) do
		local other = playerGui:FindFirstChild(name)
		if other and other.Enabled and (name ~= "SizerTutorial" or other:FindFirstChild("Sinks")) then
			return false
		end
	end
	return true
end

local function point(tileName, title, body, color, petId)
	target = tileName
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	bodyLabel.Text = body
	cardStroke.Color = color
	ringStroke.Color = color
	preview:ClearAllChildren()
	previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView = 40
	previewCamera.CFrame = CFrame.lookAt(Vector3.new(4.2, 2.4, -7), Vector3.new(0, 0.2, 0))
	previewCamera.Parent = preview
	preview.CurrentCamera = previewCamera
	previewAnimate = nil
	preview.Visible = petId ~= nil
	titleLabel.Size = UDim2.new(1, petId and -120 or -28, 0, 34)
	bodyLabel.Size = UDim2.new(1, petId and -120 or -28, 0, 44)
	if petId then
		local model, animate = Pets.build(petId)
		if model then
			model.Parent = preview
			previewAnimate = animate
		end
	end
end

local function clearPointer()
	target = nil
	gui.Enabled = false
end

RunService.RenderStepped:Connect(function()
	local t = target and tile(target)
	if not t or not t.Parent or not t.Parent.Visible or not inLobby() then
		gui.Enabled = false
		return
	end
	gui.Enabled = true
	local pad = 8
	local grow = 3 + 3 * (0.5 + 0.5 * math.sin(os.clock() * 6))
	local pos, size = t.AbsolutePosition, t.AbsoluteSize
	ring.Position = UDim2.fromOffset(pos.X - pad - grow, pos.Y - pad - grow)
	ring.Size = UDim2.fromOffset(size.X + (pad + grow) * 2, size.Y + (pad + grow) * 2)
	ringStroke.Transparency = 0.1 + 0.4 * (0.5 + 0.5 * math.sin(os.clock() * 6))
	local bob = math.sin(os.clock() * 4) * 4
	local layout = t.Parent:FindFirstChildOfClass("UIListLayout")
	if layout and layout.FillDirection == Enum.FillDirection.Horizontal then
		-- Phone layout: the menu runs along the top, so point from below.
		card.AnchorPoint = Vector2.new(0, 0)
		card.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + pad + 14 + bob)
	else
		card.AnchorPoint = Vector2.new(0, 0.5)
		card.Position = UDim2.fromOffset(pos.X + size.X + pad + 18 + bob, pos.Y + size.Y / 2)
	end
	if previewAnimate then
		previewAnimate(os.clock())
	end
end)

local function markSeen(name, attribute)
	if player:GetAttribute(attribute) ~= true then
		player:SetAttribute(attribute, true)
		MarkHint:FireServer(name)
	end
end

--==========================================================================
-- Step 1: the first daily
--==========================================================================

local function wantsDailyStep()
	return player:GetAttribute("TutorialDone") == true
		and player:GetAttribute("FirstDailyDone") ~= true
		and player:GetAttribute("DailyIntroSeen") ~= true
end

local function startDailyStep()
	if not wantsDailyStep() then
		return
	end
	sfx("toast")
	point("DailyButton", "YOUR FIRST DAILY CHALLENGE!", "Tap DAILY to play today's challenge!", BLUE)
	markSeen("dailyIntro", "DailyIntroSeen")
end

-- Tapping DAILY (or finishing the first daily anywhere) completes the step.
task.spawn(function()
	local daily = nil
	for _ = 1, 60 do
		daily = tile("DailyButton")
		if daily then
			break
		end
		task.wait(0.5)
	end
	if daily then
		daily.MouseButton1Click:Connect(function()
			if target == "DailyButton" then
				clearPointer()
				markSeen("dailyIntro", "DailyIntroSeen")
			end
		end)
	end
end)

-- Right after the tutorial ends (finished or skipped).
player:GetAttributeChangedSignal("TutorialDone"):Connect(function()
	if player:GetAttribute("TutorialDone") == true then
		task.wait(1.5)
		startDailyStep()
	end
end)

--==========================================================================
-- Step 3: "you unlocked a pet!" (after the streak step)
--==========================================================================

local petId = nil
local petName = nil
local petStepShown = false

local function wantsPetStep()
	return player:GetAttribute("FirstDailyDone") == true and player:GetAttribute("PetIntroSeen") ~= true
end

local function startPetStep()
	if petStepShown or not wantsPetStep() then
		return
	end
	petStepShown = true
	local id = petId or "mouse"
	local info = Pets.get(id)
	sfx("pet")
	point("PetsButton", "YOU UNLOCKED A PET!", string.format("Your %s is here. Tap PETS to equip it!", info and info.name or petName or "new pet"), PINK, id)
	markSeen("petIntro", "PetIntroSeen")
end

task.spawn(function()
	local pets = nil
	for _ = 1, 60 do
		pets = tile("PetsButton")
		if pets then
			break
		end
		task.wait(0.5)
	end
	if pets then
		pets.MouseButton1Click:Connect(function()
			if target == "PetsButton" then
				clearPointer()
				markSeen("petIntro", "PetIntroSeen")
			end
		end)
	end
end)

ProgressEvent.OnClientEvent:Connect(function(kind, payload)
	if kind == "starterPet" and type(payload) == "table" then
		petId = payload.id
		petName = payload.name
	end
end)

-- The first daily finished: drop step 1, then wait for the streak step
-- (StreakClient) before showing the pet. If the player ignores the streak
-- hint, show the pet anyway after a while in the lobby.
player:GetAttributeChangedSignal("FirstDailyDone"):Connect(function()
	if target == "DailyButton" then
		clearPointer()
	end
	markSeen("dailyIntro", "DailyIntroSeen")
end)

task.spawn(function()
	-- Wait for saved data before deciding anything.
	local waited = 0
	while not player:GetAttribute("DataLoaded") and waited < 15 do
		task.wait(0.5)
		waited += 0.5
	end
	task.wait(3)
	-- A returning player who finished the tutorial but never did a daily.
	if wantsDailyStep() and target == nil then
		startDailyStep()
	end
	local lobbySince = nil
	while true do
		task.wait(0.5)
		if wantsPetStep() and not petStepShown then
			if inLobby() then
				lobbySince = lobbySince or os.clock()
				local streakDone = player:GetAttribute("StreakHintSeen") == true
				if streakDone or os.clock() - lobbySince > 25 then
					startPetStep()
				end
			else
				lobbySince = nil
			end
		end
	end
end)
