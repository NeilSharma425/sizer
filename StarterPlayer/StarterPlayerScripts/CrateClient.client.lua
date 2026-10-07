--[[
	CrateClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.CrateClient

	Shows the pet-crate announcements from CrateManager: a banner when a
	crate starts falling (only the rarity, e.g. "LEGENDARY PET CRATE
	FALLING!" - the pet is a surprise), one when it lands and breaks open
	(now the pet is revealed), and one if the leftover pets vanish. Claims
	don't get a banner. The crate, its light beam and the spilled pets are
	real parts in the world.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CrateEvent = ReplicatedStorage:WaitForChild("ScaleGameRemotes"):WaitForChild("CrateEvent")

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

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		scale.Scale = math.clamp(camera.ViewportSize.X / 700, 0.55, 1)
	end
end
updateScale()

local token = 0
local function show(title, sub, color, seconds)
	token += 1
	local mine = token
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	subLabel.Text = sub
	cardStroke.Color = color
	updateScale()
	card.Visible = true
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 90) }):Play()
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
			8
		)
	elseif kind == "opened" then
		show(
			"THE CRATE BROKE OPEN!",
			string.format("%d %s %s pets spilled out - touch one to claim it!", 3, string.upper(data.rarity), string.upper(data.name)),
			color,
			5
		)
	elseif kind == "expired" then
		sfx("crateGone")
		show("THE PET CRATE VANISHED", "Nobody grabbed it in time.", Color3.fromRGB(200, 205, 225), 3.5)
	elseif kind == "done" then
		sfx("crateGone")
	elseif kind == "owned" then
		show("YOU ALREADY HAVE THIS PET", "Leave it for someone else!", Color3.fromRGB(200, 205, 225), 3)
	end
end)
