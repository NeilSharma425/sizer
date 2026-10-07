--[[
	ScaleGuesserClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ScaleGuesserClient

	Lobby HUD (coins/trophies, playtime reward, Quick Play) and the game
	itself: press E at a station podium (or Quick Play) to start rounds in
	that station's category. The reference/target parts are local to this
	client and appear at the active station.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local RequestRound = remotesFolder:WaitForChild("RequestRound")
local SubmitGuess = remotesFolder:WaitForChild("SubmitGuess")
local RoundResult = remotesFolder:WaitForChild("RoundResult")

local stationsFolder = workspace:WaitForChild("Map"):WaitForChild("Stations")

-- The reference part is always drawn this tall; matches the 1x line on
-- each station's back panel.
local REFERENCE_DISPLAY_HEIGHT = 6
local PART_OFFSET_X = 4

local MIN_RATIO = 0.02
local MAX_RATIO = 50
local LOG_MIN = math.log(MIN_RATIO)
local LOG_MAX = math.log(MAX_RATIO)

local RESULT_DELAY_SECONDS = 4
local LEAVE_DISTANCE = 35

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(80, 210, 70)
local ORANGE = Color3.fromRGB(255, 170, 40)
local RED = Color3.fromRGB(240, 70, 70)

--==========================================================================
-- UI helpers
--==========================================================================

local function corner(target, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 14)
	c.Parent = target
	return c
end

local function stroke(target, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or INK
	s.ApplyStrokeMode = target:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = target
	return s
end

local function textStroke(target, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2.5
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = target
	return s
end

local function gloss(target, color)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	g.Rotation = 90
	g.Parent = target
	return g
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
	return l
end

local function button(parent, text, color, props)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = FONT
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.Text = text
	for key, value in pairs(props) do
		b[key] = value
	end
	b.Parent = parent
	corner(b, UDim.new(0, 12))
	stroke(b, 3)
	gloss(b, color)
	textStroke(b, 2.5)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.18, 0)
	padding.PaddingBottom = UDim.new(0.18, 0)
	padding.Parent = b

	return b
end

local function bump(guiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = guiObject
	scale.Scale = 1.15
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

--==========================================================================
-- HUD
--==========================================================================

local hud = Instance.new("ScreenGui")
hud.Name = "SizerHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.Parent = player:WaitForChild("PlayerGui")

-- Top-level HUD elements shrink on small screens (each scales about its
-- own AnchorPoint, so corner-anchored widgets stay in their corners).
local responsiveScales = {}
local function responsive(guiObject)
	local scale = Instance.new("UIScale")
	scale.Parent = guiObject
	table.insert(responsiveScales, scale)
end
local function updateHudScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local value = math.clamp(camera.ViewportSize.Y / 900, 0.55, 1.1)
	for _, scale in ipairs(responsiveScales) do
		scale.Scale = value
	end
end

local function counterPill(position, color, icon, iconColor)
	local pill = frame(hud, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = position,
		Size = UDim2.new(0, 230, 0, 52),
		BackgroundColor3 = color,
	})
	corner(pill, UDim.new(1, 0))
	stroke(pill, 3.5)
	gloss(pill, color)

	local badge = frame(pill, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 66, 0, 66),
		BackgroundColor3 = iconColor,
		ZIndex = 2,
	})
	corner(badge, UDim.new(1, 0))
	stroke(badge, 3.5)
	gloss(badge, iconColor)
	label(badge, {
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.15, 0.15),
		Text = icon,
		ZIndex = 3,
	})

	local value = label(pill, {
		Size = UDim2.new(1, -60, 0.8, 0),
		Position = UDim2.new(0, 44, 0.1, 0),
		Text = "0",
	})
	textStroke(value, 3)
	responsive(pill)
	return pill, value
end

local _, coinsText = counterPill(UDim2.new(0.5, -135, 0, 14), GREEN, "⭐", Color3.fromRGB(255, 200, 40))
local _, trophyText = counterPill(UDim2.new(0.5, 135, 0, 14), ORANGE, "🏆", Color3.fromRGB(255, 120, 40))

-- Playtime reward card (bottom-left).
local rewardCard = frame(hud, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.new(0, 330, 0, 92),
	BackgroundColor3 = RED,
})
corner(rewardCard, UDim.new(0, 18))
stroke(rewardCard, 3.5)
gloss(rewardCard, RED)

local giftBadge = frame(rewardCard, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 70, 0, 70),
	BackgroundColor3 = Color3.fromRGB(255, 195, 50),
})
corner(giftBadge, UDim.new(1, 0))
stroke(giftBadge, 3)
gloss(giftBadge, Color3.fromRGB(255, 195, 50))
label(giftBadge, { Size = UDim2.fromScale(0.66, 0.66), Position = UDim2.fromScale(0.17, 0.17), Text = "🎁" })

textStroke(label(rewardCard, {
	Size = UDim2.new(1, -100, 0, 26),
	Position = UDim2.new(0, 90, 0, 10),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "PLAYTIME REWARD",
}))
local rewardText = label(rewardCard, {
	Size = UDim2.new(1, -100, 0, 24),
	Position = UDim2.new(0, 90, 0, 38),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "NEXT: 25 COINS",
})
textStroke(rewardText)
local rewardBarBack = frame(rewardCard, {
	Position = UDim2.new(0, 90, 0, 68),
	Size = UDim2.new(1, -108, 0, 10),
	BackgroundColor3 = Color3.fromRGB(120, 25, 30),
})
corner(rewardBarBack, UDim.new(1, 0))
local rewardBarFill = frame(rewardBarBack, {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(255, 200, 60),
})
corner(rewardBarFill, UDim.new(1, 0))

local quickPlayButton = button(hud, "QUICK PLAY", GREEN, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.new(0, 260, 0, 64),
})

responsive(rewardCard)
responsive(quickPlayButton)

-- Floating score popup.
local popup = label(hud, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.35),
	Size = UDim2.new(0, 400, 0, 110),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 220, 60),
	Visible = false,
	ZIndex = 10,
})
textStroke(popup, 5)

--==========================================================================
-- Game panel
--==========================================================================

local panel = frame(hud, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0, 600, 0, 250),
	BackgroundColor3 = Color3.fromRGB(40, 45, 75),
	Visible = false,
})
corner(panel, UDim.new(0, 20))
stroke(panel, 4)
gloss(panel, Color3.fromRGB(40, 45, 75))

local categoryTag = frame(panel, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.new(0, 220, 0, 42),
	BackgroundColor3 = ORANGE,
	ZIndex = 2,
})
corner(categoryTag, UDim.new(1, 0))
stroke(categoryTag, 3.5)
local categoryGloss = gloss(categoryTag, ORANGE)
local categoryText = label(categoryTag, {
	Size = UDim2.new(1, -20, 0.8, 0),
	Position = UDim2.new(0, 10, 0.1, 0),
	Text = "MIXED",
	ZIndex = 3,
})
textStroke(categoryText)

local leaveButton = button(panel, "X", RED, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.new(0, 44, 0, 44),
})

local questionText = label(panel, {
	Size = UDim2.new(1, -90, 0, 52),
	Position = UDim2.new(0, 22, 0, 28),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Text = "Loading round...",
})
textStroke(questionText)

local guessText = label(panel, {
	Size = UDim2.new(1, -44, 0, 28),
	Position = UDim2.new(0, 22, 0, 84),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = ORANGE,
	Text = "Guess: --",
})
textStroke(guessText)

local sliderTrack = frame(panel, {
	Position = UDim2.new(0, 22, 0, 128),
	Size = UDim2.new(1, -44, 0, 18),
	BackgroundColor3 = Color3.fromRGB(20, 22, 40),
})
corner(sliderTrack, UDim.new(1, 0))
stroke(sliderTrack, 2.5)

local sliderFill = frame(sliderTrack, {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = ORANGE,
})
corner(sliderFill, UDim.new(1, 0))
gloss(sliderFill, ORANGE)

local sliderHandle = frame(sliderTrack, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.new(0, 34, 0, 34),
	BackgroundColor3 = WHITE,
	ZIndex = 2,
})
corner(sliderHandle, UDim.new(1, 0))
stroke(sliderHandle, 3)

local lockInButton = button(panel, "LOCK IN", GREEN, {
	Position = UDim2.new(0, 22, 1, -78),
	Size = UDim2.new(0, 170, 0, 58),
})

local resultText = label(panel, {
	Size = UDim2.new(1, -230, 0, 64),
	Position = UDim2.new(0, 208, 1, -82),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(225, 230, 245),
	Font = Enum.Font.GothamBold,
	Text = "",
})

responsive(panel)
updateHudScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateHudScale)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudScale)
end

--==========================================================================
-- Display parts (local to this client)
--==========================================================================

local function makeDisplayPart(name, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = Vector3.new(4, REFERENCE_DISPLAY_HEIGHT, 4)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 56)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, REFERENCE_DISPLAY_HEIGHT / 2 + 2, 0)
	billboard.LightInfluence = 0
	billboard.Parent = p

	local text = label(billboard, { Size = UDim2.fromScale(1, 1), Text = name })
	textStroke(text, 3)
	return p, text, billboard
end

local referencePart, referenceLabel = makeDisplayPart("Reference", Color3.fromRGB(60, 120, 230))
local targetPart, targetLabel, targetBillboard = makeDisplayPart("Target", Color3.fromRGB(255, 150, 40))

--==========================================================================
-- State
--==========================================================================

local activeStation = nil
local sessionId = 0
local currentRound = nil
local currentRatio = 1
local isDragging = false
local guessLocked = false

local function displayOrigin()
	return activeStation and activeStation:FindFirstChild("DisplayOrigin")
end

local function placeParts(ratio)
	local origin = displayOrigin()
	if not origin then
		return
	end
	local targetHeight = math.max(REFERENCE_DISPLAY_HEIGHT * ratio, 0.05)
	referencePart.Size = Vector3.new(4, REFERENCE_DISPLAY_HEIGHT, 4)
	referencePart.CFrame = origin.CFrame * CFrame.new(-PART_OFFSET_X, REFERENCE_DISPLAY_HEIGHT / 2, 0)
	targetPart.Size = Vector3.new(4, targetHeight, 4)
	targetPart.CFrame = origin.CFrame * CFrame.new(PART_OFFSET_X, targetHeight / 2, 0)
	-- Billboards anchor at the part's center; keep the label above its top.
	targetBillboard.StudsOffsetWorldSpace = Vector3.new(0, targetHeight / 2 + 2, 0)
end

local function withCommas(n)
	local s = tostring(math.floor(n + 0.5))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function formatHeight(meters)
	if meters >= 10000 then
		return withCommas(meters / 1000) .. " km"
	elseif meters >= 1000 then
		return string.format("%.1f km", meters / 1000)
	elseif meters >= 1 then
		return string.format("%.1f m", meters)
	elseif meters >= 0.01 then
		return string.format("%.0f cm", meters * 100)
	else
		return string.format("%.1f mm", meters * 1000)
	end
end

local function alphaToRatio(alpha)
	return math.exp(LOG_MIN + (LOG_MAX - LOG_MIN) * math.clamp(alpha, 0, 1))
end

local function ratioToAlpha(ratio)
	return (math.log(math.clamp(ratio, MIN_RATIO, MAX_RATIO)) - LOG_MIN) / (LOG_MAX - LOG_MIN)
end

local function setRatio(ratio)
	currentRatio = math.clamp(ratio, MIN_RATIO, MAX_RATIO)
	local alpha = ratioToAlpha(currentRatio)
	sliderFill.Size = UDim2.fromScale(alpha, 1)
	sliderHandle.Position = UDim2.fromScale(alpha, 0.5)
	placeParts(currentRatio)
	if currentRound then
		guessText.Text = string.format(
			"Guess: %s  (%.2fx)",
			formatHeight(currentRound.referenceHeight * currentRatio),
			currentRatio
		)
	end
end

--==========================================================================
-- Slider input
--==========================================================================

local function alphaFromX(x)
	local width = sliderTrack.AbsoluteSize.X
	if width <= 0 then
		return 0
	end
	return (x - sliderTrack.AbsolutePosition.X) / width
end

local function beginDrag(input)
	if guessLocked or not currentRound then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		setRatio(alphaToRatio(alphaFromX(input.Position.X)))
	end
end

sliderTrack.InputBegan:Connect(beginDrag)
sliderHandle.InputBegan:Connect(beginDrag)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setRatio(alphaToRatio(alphaFromX(input.Position.X)))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

--==========================================================================
-- Session flow
--==========================================================================

local function setLockEnabled(enabled)
	lockInButton.Active = enabled
	lockInButton.AutoButtonColor = enabled
	lockInButton.BackgroundColor3 = enabled and GREEN or Color3.fromRGB(110, 110, 120)
	lockInButton:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(
		lockInButton.BackgroundColor3:Lerp(WHITE, 0.25),
		lockInButton.BackgroundColor3:Lerp(INK, 0.12)
	)
end

local function requestRound()
	currentRound = nil
	guessLocked = false
	resultText.Text = ""
	questionText.Text = "Loading round..."
	guessText.Text = "Guess: --"
	setLockEnabled(false)
	local category = activeStation:GetAttribute("Category")
	RequestRound:FireServer(category ~= "" and category or nil)
end

local function stopSession()
	activeStation = nil
	sessionId += 1
	currentRound = nil
	isDragging = false
	panel.Visible = false
	quickPlayButton.Visible = true
	rewardCard.Visible = true
	referencePart.Parent = nil
	targetPart.Parent = nil
end

local function startSession(station)
	if activeStation == station then
		return
	end
	activeStation = station
	sessionId += 1

	local color = station:GetAttribute("Color") or ORANGE
	categoryTag.BackgroundColor3 = color
	categoryGloss.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	categoryText.Text = station:GetAttribute("DisplayName") or "MIXED"

	panel.Visible = true
	quickPlayButton.Visible = false
	rewardCard.Visible = false
	referenceLabel.Text = "Reference"
	targetLabel.Text = "Target"
	referencePart.Parent = workspace
	targetPart.Parent = workspace
	setRatio(1)
	requestRound()
end

RequestRound.OnClientEvent:Connect(function(roundInfo)
	if not activeStation then
		return
	end
	currentRound = roundInfo
	referenceLabel.Text = string.format("%s\n%s", roundInfo.referenceName, formatHeight(roundInfo.referenceHeight))
	targetLabel.Text = roundInfo.targetName .. "\n???"
	questionText.Text = string.format("How big is a %s next to a %s?", roundInfo.targetName, roundInfo.referenceName)
	setRatio(1)
	setLockEnabled(true)
end)

lockInButton.MouseButton1Click:Connect(function()
	if guessLocked or not currentRound then
		return
	end
	guessLocked = true
	isDragging = false
	setLockEnabled(false)
	SubmitGuess:FireServer(currentRound.referenceHeight * currentRatio)
end)

local function showPopup(score)
	popup.Text = "+" .. score
	popup.TextColor3 = score >= 80 and Color3.fromRGB(110, 255, 110)
		or score >= 40 and Color3.fromRGB(255, 220, 60)
		or Color3.fromRGB(255, 110, 110)
	popup.Position = UDim2.fromScale(0.5, 0.38)
	popup.TextTransparency = 0
	popup.Visible = true
	local s = popup:FindFirstChildOfClass("UIStroke")
	if s then
		s.Transparency = 0
	end
	bump(popup)
	local info = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(popup, info, { Position = UDim2.fromScale(0.5, 0.28), TextTransparency = 1 }):Play()
	if s then
		TweenService:Create(s, info, { Transparency = 1 }):Play()
	end
end

RoundResult.OnClientEvent:Connect(function(result)
	if not activeStation or not currentRound then
		return
	end

	placeParts(result.trueTargetHeight / currentRound.referenceHeight)
	targetLabel.Text = string.format("%s\n%s", currentRound.targetName, formatHeight(result.trueTargetHeight))

	local verdict = result.score >= 90 and "PERFECT!" or result.score >= 70 and "GREAT!" or result.score >= 40 and "CLOSE!" or "WAY OFF!"
	resultText.Text = string.format(
		"%s  Real: %s  |  You: %s  |  +%d coins\n%s",
		verdict,
		formatHeight(result.trueTargetHeight),
		formatHeight(result.guessedTargetHeight),
		result.coinsEarned or 0,
		result.fact
	)
	showPopup(result.score)

	local mySession = sessionId
	task.delay(RESULT_DELAY_SECONDS, function()
		if sessionId == mySession and activeStation then
			requestRound()
		end
	end)
end)

leaveButton.MouseButton1Click:Connect(stopSession)

--==========================================================================
-- Stations & Quick Play
--==========================================================================

local function hookStation(station)
	local podium = station:WaitForChild("Podium")
	local prompt = podium:WaitForChild("ProximityPrompt")
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			startSession(station)
		end
	end)
end

for _, station in ipairs(stationsFolder:GetChildren()) do
	task.spawn(hookStation, station)
end
stationsFolder.ChildAdded:Connect(hookStation)

quickPlayButton.MouseButton1Click:Connect(function()
	local stations = stationsFolder:GetChildren()
	if #stations == 0 then
		return
	end
	local station = stations[math.random(1, #stations)]
	local approach = station:FindFirstChild("Approach")
	local character = player.Character
	if approach and character then
		character:PivotTo(approach.CFrame)
	end
	startSession(station)
end)

-- End the session if the player walks away from their station.
RunService.Heartbeat:Connect(function()
	local origin = displayOrigin()
	if not origin then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - origin.Position).Magnitude > LEAVE_DISTANCE then
		stopSession()
	end
end)

player.CharacterAdded:Connect(function()
	if activeStation then
		stopSession()
	end
end)

--==========================================================================
-- HUD bindings
--==========================================================================

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins")
	local score = leaderstats:WaitForChild("Score")

	coinsText.Text = tostring(coins.Value)
	trophyText.Text = tostring(score.Value)
	coins.Changed:Connect(function(value)
		coinsText.Text = tostring(value)
		bump(coinsText)
	end)
	score.Changed:Connect(function(value)
		trophyText.Text = tostring(value)
		bump(trophyText)
	end)
end)

task.spawn(function()
	while true do
		local nextAt = player:GetAttribute("NextRewardAt")
		local interval = player:GetAttribute("RewardInterval") or 120
		local amount = player:GetAttribute("RewardAmount") or 25
		if nextAt then
			local remaining = math.max(0, nextAt - workspace:GetServerTimeNow())
			rewardText.Text = string.format(
				"NEXT: %d COINS   %d:%02d",
				amount,
				math.floor(remaining / 60),
				math.floor(remaining % 60)
			)
			rewardBarFill.Size = UDim2.fromScale(1 - remaining / interval, 1)
		end
		task.wait(0.25)
	end
end)
