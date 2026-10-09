--[[
	CrateClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.CrateClient

	Shows the pet-crate announcements from CrateManager: a banner when a
	crate starts falling (only the rarity, e.g. "LEGENDARY PET CRATE
	FALLING!" - the pet is a surprise). Breaking open and the leftover pets
	vanishing have no banner (just a sound), and neither do claims. The
	crate, its light beam and the spilled pets are real parts in the world.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CrateEvent = ReplicatedStorage:WaitForChild("ScaleGameRemotes"):WaitForChild("CrateEvent")
local ScreenFit = require(ReplicatedStorage:WaitForChild("ScreenFit"))

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
local PANEL = Color3.fromRGB(40, 45, 75)

local gui = Instance.new("ScreenGui")
gui.Name = "SizerCrate"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Banner"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, -120)
card.Size = UDim2.new(0, 480, 0, 76)
card.BackgroundColor3 = PANEL
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 18)
cardCorner.Parent = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Thickness = 4
cardStroke.Parent = card
local scale = Instance.new("UIScale")
scale.Parent = card

local function makeLabel(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = WHITE
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = card
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
	return l
end
local titleLabel = makeLabel({ Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -28, 0, 34) })
local subLabel = makeLabel({ Position = UDim2.new(0, 14, 0, 42), Size = UDim2.new(1, -28, 0, 26), TextColor3 = Color3.fromRGB(215, 220, 240) })

-- True while the player is in a round (the game panel is showing).
local function inGame()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local panel = hud and hud:FindFirstChild("GamePanel")
	return panel ~= nil and panel.Visible
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		-- At most ~60% of the width and ~13% of the height (small on phones),
		-- and smaller still while playing a round.
		local value = ScreenFit.scaleFor(camera.ViewportSize, 480, 76, { fx = 0.6, fy = 0.13 })
		scale.Scale = inGame() and value * 0.65 or value
	end
end
updateScale()

local token = 0
-- Top of the screen, or just under the live round's JOIN prompt if that's up.
local function bannerTop()
	local livePrompt = playerGui:FindFirstChild("SizerLivePrompt")
	local promptFrame = livePrompt and livePrompt.Enabled and livePrompt:FindFirstChild("Prompt")
	if promptFrame and promptFrame.AbsoluteSize then
		return promptFrame.AbsolutePosition.Y + promptFrame.AbsoluteSize.Y + 8
	end
	return inGame() and 2 or 12
end

local function show(title, sub, color, seconds)
	token += 1
	local mine = token
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	subLabel.Text = sub
	cardStroke.Color = color
	updateScale()
	card.Visible = true
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, bannerTop()) }):Play()
	task.delay(seconds, function()
		if token ~= mine then
			return
		end
		local out = TweenService:Create(card, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -120) })
		out:Play()
		out.Completed:Connect(function()
			if token == mine then
				card.Visible = false
			end
		end)
	end)
end

CrateEvent.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then
		return
	end
	local color = data.color or Color3.fromRGB(255, 200, 50)
	if kind == "incoming" then
		sfx("crate")
		show(
			string.upper(data.rarity) .. " PET CRATE FALLING!",
			string.format("A mystery %s pet  -  only %d copies. Find the light beam!", data.rarity, data.copies),
			color,
			5
		)
	elseif kind == "expired" then
		sfx("crateGone")
	elseif kind == "done" then
		sfx("crateGone")
	elseif kind == "owned" then
		show("YOU ALREADY HAVE THIS PET", "Leave it for someone else!", Color3.fromRGB(200, 205, 225), 3)
	end
end)
