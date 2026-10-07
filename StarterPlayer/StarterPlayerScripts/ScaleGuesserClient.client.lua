--[[
	ScaleGuesserClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ScaleGuesserClient

	Renders the reference/target parts and the guess UI, and drives the
	round loop by talking to RoundManager over ScaleGameRemotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

local remotesFolder = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local RequestRound = remotesFolder:WaitForChild("RequestRound")
local SubmitGuess = remotesFolder:WaitForChild("SubmitGuess")
local RoundResult = remotesFolder:WaitForChild("RoundResult")

-- The reference part is always drawn at this constant stud height, so the
-- player's sense of "real size" comes entirely from the fact/label text,
-- not from the reference model's true dimensions.
local REFERENCE_DISPLAY_HEIGHT = 6

-- Slider covers a log-scale range from 0.02x to 50x the reference height.
local MIN_RATIO = 0.02
local MAX_RATIO = 50
local LOG_MIN = math.log(MIN_RATIO)
local LOG_MAX = math.log(MAX_RATIO)

local RESULT_DELAY_SECONDS = 4

--==========================================================================
-- Workspace parts
--==========================================================================

local PART_GAP = 10

-- The two display parts live inside the Scale Guesser arena that
-- MapBuilder constructs, centered on MapConfig.ArenaCenter.
local ARENA_ORIGIN = MapConfig.ArenaCenter + Vector3.new(0, 0, 10)
local GROUND_Y = MapConfig.GroundY

local referencePart = Instance.new("Part")
referencePart.Name = "ReferencePart"
referencePart.Anchored = true
referencePart.CanCollide = false
referencePart.Material = Enum.Material.SmoothPlastic
referencePart.Color = Color3.fromRGB(60, 120, 220)
referencePart.Size = Vector3.new(4, REFERENCE_DISPLAY_HEIGHT, 4)
referencePart.Position = ARENA_ORIGIN + Vector3.new(-PART_GAP / 2, GROUND_Y + REFERENCE_DISPLAY_HEIGHT / 2, 0)
referencePart.Parent = workspace

local referenceLabel = Instance.new("BillboardGui")
referenceLabel.Name = "Label"
referenceLabel.Size = UDim2.new(0, 200, 0, 50)
referenceLabel.StudsOffset = Vector3.new(0, 2, 0)
referenceLabel.AlwaysOnTop = true
referenceLabel.Parent = referencePart

local referenceLabelText = Instance.new("TextLabel")
referenceLabelText.Size = UDim2.fromScale(1, 1)
referenceLabelText.BackgroundTransparency = 1
referenceLabelText.TextColor3 = Color3.new(1, 1, 1)
referenceLabelText.TextScaled = true
referenceLabelText.Font = Enum.Font.GothamBold
referenceLabelText.Text = "Reference"
referenceLabelText.Parent = referenceLabel

local targetPart = Instance.new("Part")
targetPart.Name = "TargetPart"
targetPart.Anchored = true
targetPart.CanCollide = false
targetPart.Material = Enum.Material.SmoothPlastic
targetPart.Color = Color3.fromRGB(230, 140, 40)
targetPart.Size = Vector3.new(4, REFERENCE_DISPLAY_HEIGHT, 4)
targetPart.Position = ARENA_ORIGIN + Vector3.new(PART_GAP / 2, GROUND_Y + REFERENCE_DISPLAY_HEIGHT / 2, 0)
targetPart.Parent = workspace

local targetLabel = Instance.new("BillboardGui")
targetLabel.Name = "Label"
targetLabel.Size = UDim2.new(0, 200, 0, 50)
targetLabel.StudsOffset = Vector3.new(0, 2, 0)
targetLabel.AlwaysOnTop = true
targetLabel.Parent = targetPart

local targetLabelText = Instance.new("TextLabel")
targetLabelText.Size = UDim2.fromScale(1, 1)
targetLabelText.BackgroundTransparency = 1
targetLabelText.TextColor3 = Color3.new(1, 1, 1)
targetLabelText.TextScaled = true
targetLabelText.Font = Enum.Font.GothamBold
targetLabelText.Text = "Target"
targetLabelText.Parent = targetLabel

-- Updates the target part's size/position to reflect a given ratio
-- (targetHeight / referenceHeight) using the same fixed reference display
-- height, so the visual comparison always matches the guessed ratio.
local function setTargetRatio(ratio)
	local displayHeight = REFERENCE_DISPLAY_HEIGHT * ratio
	displayHeight = math.max(displayHeight, 0.05)
	targetPart.Size = Vector3.new(4, displayHeight, 4)
	targetPart.Position = ARENA_ORIGIN + Vector3.new(PART_GAP / 2, GROUND_Y + displayHeight / 2, 0)
end

--==========================================================================
-- UI
--==========================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScaleGuesserGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local rootFrame = Instance.new("Frame")
rootFrame.Name = "Root"
rootFrame.AnchorPoint = Vector2.new(0.5, 1)
rootFrame.Position = UDim2.new(0.5, 0, 1, -30)
rootFrame.Size = UDim2.new(0, 560, 0, 220)
rootFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
rootFrame.BackgroundTransparency = 0.1
rootFrame.BorderSizePixel = 0
rootFrame.Visible = false
rootFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = rootFrame

local promptLabel = Instance.new("TextLabel")
promptLabel.Name = "Prompt"
promptLabel.Size = UDim2.new(1, -40, 0, 50)
promptLabel.Position = UDim2.new(0, 20, 0, 10)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.new(1, 1, 1)
promptLabel.TextScaled = true
promptLabel.Font = Enum.Font.GothamBold
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Text = "Loading round..."
promptLabel.Parent = rootFrame

local guessLabel = Instance.new("TextLabel")
guessLabel.Name = "GuessLabel"
guessLabel.Size = UDim2.new(1, -40, 0, 30)
guessLabel.Position = UDim2.new(0, 20, 0, 60)
guessLabel.BackgroundTransparency = 1
guessLabel.TextColor3 = Color3.fromRGB(230, 140, 40)
guessLabel.TextScaled = true
guessLabel.Font = Enum.Font.Gotham
guessLabel.TextXAlignment = Enum.TextXAlignment.Left
guessLabel.Text = "Guess: --"
guessLabel.Parent = rootFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(1, -40, 0, 12)
sliderTrack.Position = UDim2.new(0, 20, 0, 105)
sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = rootFrame

local sliderTrackCorner = Instance.new("UICorner")
sliderTrackCorner.CornerRadius = UDim.new(1, 0)
sliderTrackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderHandle = Instance.new("Frame")
sliderHandle.Name = "SliderHandle"
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.Size = UDim2.new(0, 24, 0, 24)
sliderHandle.Position = UDim2.new(0, 0, 0.5, 0)
sliderHandle.BackgroundColor3 = Color3.new(1, 1, 1)
sliderHandle.BorderSizePixel = 0
sliderHandle.ZIndex = 2
sliderHandle.Parent = sliderTrack

local sliderHandleCorner = Instance.new("UICorner")
sliderHandleCorner.CornerRadius = UDim.new(1, 0)
sliderHandleCorner.Parent = sliderHandle

local lockInButton = Instance.new("TextButton")
lockInButton.Name = "LockInButton"
lockInButton.Size = UDim2.new(0, 160, 0, 44)
lockInButton.Position = UDim2.new(0, 20, 0, 150)
lockInButton.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
lockInButton.TextColor3 = Color3.new(1, 1, 1)
lockInButton.Font = Enum.Font.GothamBold
lockInButton.TextScaled = true
lockInButton.Text = "Lock In"
lockInButton.Parent = rootFrame

local lockInCorner = Instance.new("UICorner")
lockInCorner.CornerRadius = UDim.new(0, 8)
lockInCorner.Parent = lockInButton

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -220, 0, 60)
resultLabel.Position = UDim2.new(0, 200, 0, 145)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
resultLabel.TextScaled = true
resultLabel.TextWrapped = true
resultLabel.Font = Enum.Font.Gotham
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.Text = ""
resultLabel.Parent = rootFrame

--==========================================================================
-- Round / slider state
--==========================================================================

local currentRound = nil -- { referenceName, referenceHeight, targetName, category }
local currentRatio = 1
local isDragging = false
local guessLocked = false

local function formatHeight(meters)
	if meters >= 1000 then
		return string.format("%.0f m", meters)
	elseif meters >= 1 then
		return string.format("%.2f m", meters)
	else
		return string.format("%.3f m", meters)
	end
end

-- Converts a fraction along the slider track [0, 1] into a ratio using a
-- log scale, so both very small and very large ratios are reachable with
-- smooth, evenly distributed drag sensitivity.
local function alphaToRatio(alpha)
	alpha = math.clamp(alpha, 0, 1)
	local logValue = LOG_MIN + (LOG_MAX - LOG_MIN) * alpha
	return math.exp(logValue)
end

local function ratioToAlpha(ratio)
	ratio = math.clamp(ratio, MIN_RATIO, MAX_RATIO)
	return (math.log(ratio) - LOG_MIN) / (LOG_MAX - LOG_MIN)
end

local function updateGuessDisplay()
	if not currentRound then
		return
	end
	local guessedHeight = currentRound.referenceHeight * currentRatio
	guessLabel.Text = string.format("Guess: %s tall (%.2fx the reference)", formatHeight(guessedHeight), currentRatio)
end

local function setRatio(ratio)
	currentRatio = math.clamp(ratio, MIN_RATIO, MAX_RATIO)
	local alpha = ratioToAlpha(currentRatio)
	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	sliderHandle.Position = UDim2.new(alpha, 0, 0.5, 0)
	setTargetRatio(currentRatio)
	updateGuessDisplay()
end

local function alphaFromInputPosition(inputPositionX)
	local trackAbsolutePosition = sliderTrack.AbsolutePosition.X
	local trackAbsoluteSize = sliderTrack.AbsoluteSize.X
	if trackAbsoluteSize <= 0 then
		return 0
	end
	return (inputPositionX - trackAbsolutePosition) / trackAbsoluteSize
end

local function beginDrag(inputPositionX)
	if guessLocked then
		return
	end
	isDragging = true
	setRatio(alphaToRatio(alphaFromInputPosition(inputPositionX)))
end

sliderHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input.Position.X)
	end
end)

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not isDragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		setRatio(alphaToRatio(alphaFromInputPosition(input.Position.X)))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

--==========================================================================
-- Round flow
--==========================================================================

local isPlaying = false

local function startNewRound()
	isPlaying = true
	rootFrame.Visible = true
	guessLocked = false
	resultLabel.Text = ""
	lockInButton.Visible = true
	lockInButton.Active = true
	lockInButton.AutoButtonColor = true
	lockInButton.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	promptLabel.Text = "Loading round..."
	RequestRound:FireServer()
end

lockInButton.MouseButton1Click:Connect(function()
	if guessLocked or not currentRound then
		return
	end
	guessLocked = true
	lockInButton.Active = false
	lockInButton.AutoButtonColor = false
	lockInButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)

	local guessedHeight = currentRound.referenceHeight * currentRatio
	SubmitGuess:FireServer(guessedHeight)
end)

RequestRound.OnClientEvent:Connect(function(roundInfo)
	currentRound = roundInfo
	referenceLabelText.Text = string.format("%s\n(%s)", roundInfo.referenceName, formatHeight(roundInfo.referenceHeight))
	targetLabelText.Text = roundInfo.targetName
	promptLabel.Text = string.format("How tall is a %s compared to a %s?", roundInfo.targetName, roundInfo.referenceName)

	setRatio(1)
end)

RoundResult.OnClientEvent:Connect(function(result)
	if not currentRound then
		return
	end

	local trueRatio = result.trueTargetHeight / currentRound.referenceHeight
	setTargetRatio(trueRatio)

	resultLabel.Text = string.format(
		"True height: %s | Your guess: %s | Score: %d/100\n%s",
		formatHeight(result.trueTargetHeight),
		formatHeight(result.guessedTargetHeight),
		result.score,
		result.fact
	)

	lockInButton.Active = false
	lockInButton.AutoButtonColor = false

	task.delay(RESULT_DELAY_SECONDS, function()
		startNewRound()
	end)
end)

--==========================================================================
-- Start kiosk (walk up to it in the arena and press E)
--==========================================================================

local arenaFolder = workspace:WaitForChild("Map"):WaitForChild("ScaleGuesserArena")
local kiosk = arenaFolder:WaitForChild("Kiosk")
local startPrompt = kiosk:WaitForChild("ProximityPrompt")

startPrompt.Triggered:Connect(function(triggeringPlayer)
	if triggeringPlayer == player and not isPlaying then
		startNewRound()
	end
end)

-- Once a player wanders far enough from the arena, hide the UI so it
-- doesn't follow them around the rest of the map. The round loop simply
-- stops advancing (RoundResult re-shows the UI) until they walk back and
-- trigger the kiosk again.
local HIDE_DISTANCE = MapConfig.ArenaRadius + 20

RunService.Heartbeat:Connect(function()
	if not isPlaying then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local distance = (rootPart.Position - MapConfig.ArenaCenter).Magnitude
	if distance > HIDE_DISTANCE then
		isPlaying = false
		rootFrame.Visible = false
	end
end)
