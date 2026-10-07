--[[
	ScaleGuesserClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ScaleGuesserClient

	Lobby HUD (playtime reward, Quick Play) and the game
	itself: press E at a station podium (or Quick Play) to start rounds in
	that station's category. Playing moves the camera to a local viewing
	room where the reference and target fill the screen; leaving returns
	the camera to the character in the lobby.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- The top-right Roblox player list duplicates our counters and the lobby
-- leaderboard, and covers the counters, so hide it.
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local remotesFolder = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local RequestRound = remotesFolder:WaitForChild("RequestRound")
local SubmitGuess = remotesFolder:WaitForChild("SubmitGuess")
local RoundResult = remotesFolder:WaitForChild("RoundResult")
local TimedStart = remotesFolder:WaitForChild("TimedStart")
local TimedStop = remotesFolder:WaitForChild("TimedStop")
local TimedEnd = remotesFolder:WaitForChild("TimedEnd")
local ProgressEvent = remotesFolder:WaitForChild("ProgressEvent")

-- Small shared folder for talking to ProgressClient: it publishes the daily
-- challenge status as attributes (DailyDone, DailyAnswered, DailyTotal,
-- DailyResetIn, DailyStatusAt) and we set RefreshRequest to ask for a fresh
-- copy after a daily run.
local bus = Instance.new("Folder")
bus.Name = "SizerBus"
bus.Parent = player:WaitForChild("PlayerGui")

local ObjectModels = require(ReplicatedStorage:WaitForChild("ObjectModels"))

local stationsFolder = workspace:WaitForChild("Map"):WaitForChild("Stations")

local MIN_RATIO = 0.02
local MAX_RATIO = 50
local LOG_MIN = math.log(MIN_RATIO)
local LOG_MAX = math.log(MAX_RATIO)

local RESULT_DELAY_SECONDS = 2.2
-- Rounds move faster in the 60-second challenge.
local TIMED_RESULT_DELAY_SECONDS = 0.7
local GOLD = Color3.fromRGB(255, 185, 30)

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

-- Playtime reward card (right column, under the rank card and streak).
local rewardCard = frame(hud, {
	Name = "RewardCard",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 146),
	Size = UDim2.new(0, 290, 0, 78),
	BackgroundColor3 = RED,
})
corner(rewardCard, UDim.new(0, 16))
stroke(rewardCard, 3.5)
gloss(rewardCard, RED)

local giftBadge = frame(rewardCard, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 8, 0.5, 0),
	Size = UDim2.new(0, 56, 0, 56),
	BackgroundColor3 = Color3.fromRGB(255, 195, 50),
})
corner(giftBadge, UDim.new(1, 0))
stroke(giftBadge, 3)
gloss(giftBadge, Color3.fromRGB(255, 195, 50))
label(giftBadge, { Size = UDim2.fromScale(0.66, 0.66), Position = UDim2.fromScale(0.17, 0.17), Text = "🎁" })

textStroke(label(rewardCard, {
	Size = UDim2.new(1, -84, 0, 22),
	Position = UDim2.new(0, 74, 0, 8),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "PLAYTIME REWARD",
}))
local rewardText = label(rewardCard, {
	Size = UDim2.new(1, -84, 0, 20),
	Position = UDim2.new(0, 74, 0, 32),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "NEXT: 25 SENSE",
})
textStroke(rewardText)
local rewardBarBack = frame(rewardCard, {
	Position = UDim2.new(0, 74, 0, 58),
	Size = UDim2.new(1, -90, 0, 9),
	BackgroundColor3 = Color3.fromRGB(120, 25, 30),
})
corner(rewardBarBack, UDim.new(1, 0))
local rewardBarFill = frame(rewardBarBack, {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(255, 200, 60),
})
corner(rewardBarFill, UDim.new(1, 0))

-- QUICK PLAY is the only button along the bottom.
local quickPlayButton = button(hud, "QUICK PLAY", GREEN, {
	Name = "QuickPlayButton",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.new(0, 260, 0, 68),
})

-- Everything else lives in a compact column down the left side.
local DAILY_BLUE = Color3.fromRGB(70, 150, 255)
local sideMenu = frame(hud, {
	Name = "SideMenu",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.new(0, 92, 0, 4 * 84 + 3 * 8),
	BackgroundTransparency = 1,
})
local sideLayout = Instance.new("UIListLayout")
sideLayout.FillDirection = Enum.FillDirection.Vertical
sideLayout.Padding = UDim.new(0, 8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sideMenu

-- A tile is a button with an emoji on top and a short caption underneath
-- (the caption label is named "Caption" so other scripts can change it).
local function menuTile(name, order, icon, caption, color)
	local tile = Instance.new("TextButton")
	tile.Name = name
	tile.LayoutOrder = order
	tile.Size = UDim2.new(1, 0, 0, 84)
	tile.BackgroundColor3 = color
	tile.BorderSizePixel = 0
	tile.Text = ""
	tile.AutoButtonColor = true
	tile.Parent = sideMenu
	corner(tile, UDim.new(0, 14))
	stroke(tile, 3)
	gloss(tile, color)
	label(tile, {
		Name = "Icon",
		Position = UDim2.new(0, 0, 0, 6),
		Size = UDim2.new(1, 0, 0, 42),
		Text = icon,
	})
	textStroke(label(tile, {
		Name = "Caption",
		Position = UDim2.new(0, 4, 0, 52),
		Size = UDim2.new(1, -8, 0, 22),
		Text = caption,
	}), 2)
	return tile
end

local dailyButton = menuTile("DailyButton", 1, "📅", "DAILY", DAILY_BLUE)
local challengeButton = menuTile("ChallengeButton", 2, "⏱️", "60s", GOLD)
menuTile("SizedexButton", 3, "📖", "SIZEDEX", Color3.fromRGB(110, 90, 220))
menuTile("HelpButton", 4, "❓", "HELP", Color3.fromRGB(95, 110, 150))

-- Red "!" badge while today's daily is waiting to be played.
local dailyBadge = frame(dailyButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.new(0, 26, 0, 26),
	BackgroundColor3 = RED,
	ZIndex = 3,
})
corner(dailyBadge, UDim.new(1, 0))
stroke(dailyBadge, 3)
label(dailyBadge, { Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.2, 0.15), Text = "!", ZIndex = 4 })

responsive(rewardCard)
responsive(sideMenu)
responsive(quickPlayButton)

local function setLobbyHudVisible(visible)
	sideMenu.Visible = visible
	quickPlayButton.Visible = visible
	rewardCard.Visible = visible
end

-- Challenge timer (top center, only during the 60-second challenge).
local timerCard = frame(hud, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0, 260, 0, 84),
	BackgroundColor3 = Color3.fromRGB(30, 32, 48),
	BackgroundTransparency = 0.1,
	Visible = false,
})
corner(timerCard, UDim.new(0, 16))
stroke(timerCard, 3, GOLD)
local timerText = label(timerCard, {
	Size = UDim2.new(1, -20, 0, 50),
	Position = UDim2.new(0, 10, 0, 4),
	Text = "⏱️ 1:00",
	TextColor3 = WHITE,
})
textStroke(timerText, 3)
local timedScoreText = label(timerCard, {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.new(0, 10, 0, 54),
	Text = "CHALLENGE SCORE: 0",
	TextColor3 = GOLD,
})
textStroke(timedScoreText, 2)
responsive(timerCard)

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

local comboPopup = label(hud, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.47),
	Size = UDim2.new(0, 460, 0, 46),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 160, 50),
	Visible = false,
	ZIndex = 10,
})
textStroke(comboPopup, 3)

--==========================================================================
-- Game panel
--==========================================================================

local panel = frame(hud, {
	Name = "GamePanel",
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

-- Difficulty badge (top-left of the panel), colored per level.
local DIFFICULTY_COLORS = {
	Easy = Color3.fromRGB(70, 200, 90),
	Medium = Color3.fromRGB(255, 165, 40),
	Hard = Color3.fromRGB(235, 70, 70),
}
local difficultyTag = frame(panel, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0, 0),
	Size = UDim2.new(0, 112, 0, 36),
	BackgroundColor3 = DIFFICULTY_COLORS.Easy,
	Visible = false,
	ZIndex = 2,
})
corner(difficultyTag, UDim.new(1, 0))
stroke(difficultyTag, 3.5)
local difficultyGloss = gloss(difficultyTag, DIFFICULTY_COLORS.Easy)
local difficultyText = label(difficultyTag, {
	Size = UDim2.new(1, -16, 0.76, 0),
	Position = UDim2.new(0, 8, 0.12, 0),
	Text = "EASY",
	ZIndex = 3,
})
textStroke(difficultyText)

local function showDifficulty(level)
	local color = DIFFICULTY_COLORS[level]
	if not color then
		difficultyTag.Visible = false
		return
	end
	difficultyTag.BackgroundColor3 = color
	difficultyGloss.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	difficultyText.Text = string.upper(level)
	difficultyTag.Visible = true
end

local leaveButton = button(panel, "STOP", RED, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 16),
	Size = UDim2.new(0, 100, 0, 44),
})

local questionText = label(panel, {
	Name = "QuestionText",
	Size = UDim2.new(1, -150, 0, 52),
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
	Name = "SliderTrack",
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
	Name = "SliderHandle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.new(0, 34, 0, 34),
	BackgroundColor3 = WHITE,
	ZIndex = 2,
})
corner(sliderHandle, UDim.new(1, 0))
stroke(sliderHandle, 3)

local lockInButton = button(panel, "LOCK IN", GREEN, {
	Name = "LockInButton",
	Position = UDim2.new(0, 22, 1, -78),
	Size = UDim2.new(0, 170, 0, 58),
})

local resultText = label(panel, {
	Name = "ResultText",
	Size = UDim2.new(1, -230, 0, 64),
	Position = UDim2.new(0, 208, 1, -82),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(225, 230, 245),
	Font = Enum.Font.GothamBold,
	Text = "",
})

responsive(panel)

-- End-of-challenge card.
local endCard = frame(hud, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 420, 0, 300),
	BackgroundColor3 = Color3.fromRGB(40, 45, 75),
	Visible = false,
	ZIndex = 5,
})
corner(endCard, UDim.new(0, 22))
stroke(endCard, 4, GOLD)
gloss(endCard, Color3.fromRGB(40, 45, 75))
textStroke(label(endCard, {
	Size = UDim2.new(1, -40, 0, 64),
	Position = UDim2.new(0, 20, 0, 16),
	Text = "TIME'S UP!",
	TextColor3 = GOLD,
	ZIndex = 6,
}), 4)
local endScoreText = label(endCard, {
	Size = UDim2.new(1, -40, 0, 50),
	Position = UDim2.new(0, 20, 0, 86),
	Text = "SCORE: 0",
	ZIndex = 6,
})
textStroke(endScoreText, 3)
local endBestText = label(endCard, {
	Size = UDim2.new(1, -40, 0, 32),
	Position = UDim2.new(0, 20, 0, 140),
	Text = "BEST: 0",
	TextColor3 = Color3.fromRGB(200, 210, 235),
	ZIndex = 6,
})
textStroke(endBestText, 2)
local playAgainButton = button(endCard, "PLAY AGAIN", GREEN, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(0.5, -8, 1, -22),
	Size = UDim2.new(0, 180, 0, 58),
	ZIndex = 6,
})
local endStopButton = button(endCard, "STOP", RED, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 8, 1, -22),
	Size = UDim2.new(0, 150, 0, 58),
	ZIndex = 6,
})
responsive(endCard)

-- End-of-daily card.
local dailyCard = frame(hud, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 440, 0, 330),
	BackgroundColor3 = Color3.fromRGB(40, 45, 75),
	Visible = false,
	ZIndex = 5,
})
corner(dailyCard, UDim.new(0, 22))
stroke(dailyCard, 4, DAILY_BLUE)
gloss(dailyCard, Color3.fromRGB(40, 45, 75))
textStroke(label(dailyCard, {
	Size = UDim2.new(1, -40, 0, 56),
	Position = UDim2.new(0, 20, 0, 16),
	Text = "📅 DAILY COMPLETE!",
	TextColor3 = DAILY_BLUE:Lerp(WHITE, 0.4),
	ZIndex = 6,
}), 4)
local dailyScoreText = label(dailyCard, {
	Size = UDim2.new(1, -40, 0, 56),
	Position = UDim2.new(0, 20, 0, 84),
	Text = "0 / 500",
	ZIndex = 6,
})
textStroke(dailyScoreText, 3)
local dailyRewardText = label(dailyCard, {
	Size = UDim2.new(1, -40, 0, 38),
	Position = UDim2.new(0, 20, 0, 148),
	Text = "+0 SENSE",
	TextColor3 = Color3.fromRGB(120, 255, 130),
	ZIndex = 6,
})
textStroke(dailyRewardText, 2.5)
label(dailyCard, {
	Size = UDim2.new(1, -40, 0, 30),
	Position = UDim2.new(0, 20, 0, 194),
	Text = "COME BACK TOMORROW FOR NEW QUESTIONS",
	TextColor3 = Color3.fromRGB(180, 190, 220),
	ZIndex = 6,
})
local dailyDoneButton = button(dailyCard, "DONE", GREEN, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.new(0, 200, 0, 58),
	ZIndex = 6,
})
responsive(dailyCard)
updateHudScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateHudScale)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudScale)
end

--==========================================================================
-- Viewing room (local to this client, far away from the lobby)
--==========================================================================

-- The camera is moved here while playing; the character stays in the lobby.
local SCENE = Vector3.new(0, 400, 3000)
-- The larger of the two objects is always drawn this tall; the smaller one
-- shrinks instead. This keeps model details above Roblox's minimum part
-- size, which would otherwise distort models at extreme slider values.
local LARGEST_SIZE = 40
local VIEW_FOV = 50
local MAX_RULER_LINES = 50
local CAMERA_STEP = "ScaleViewerCamera"

local viewer = Instance.new("Folder")
viewer.Name = "ScaleViewer"

local function scenePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in pairs(props) do
		if key ~= "Shape" then
			p[key] = value
		end
	end
	p.Parent = viewer
	return p
end

scenePart({
	Name = "Floor",
	Size = Vector3.new(6000, 2, 6000),
	Position = SCENE - Vector3.new(0, 1, 0),
	Color = Color3.fromRGB(196, 206, 226),
})
scenePart({
	Name = "Backdrop",
	Size = Vector3.new(8000, 4000, 2),
	Position = SCENE + Vector3.new(0, 1990, 1500),
	Color = Color3.fromRGB(110, 165, 235),
})
local stageRing = scenePart({
	Name = "StageRing",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(120, 200, 255),
})
local stageDisc = scenePart({ Name = "StageDisc", Shape = Enum.PartType.Cylinder, Color = WHITE })

-- Each object is a low-poly model from ObjectModels plus a floating name tag.
local function makeObject(name, color)
	local anchor = scenePart({ Name = name .. "Tag", Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 })
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 280, 0, 64)
	billboard.SizeOffset = Vector2.new(0, 0.6)
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor
	local text = label(billboard, { Size = UDim2.fromScale(1, 1), Text = name })
	textStroke(text, 3)
	return { color = color, anchor = anchor, label = text, model = nil, measure = 1 }
end

local reference = makeObject("Reference", Color3.fromRGB(60, 120, 230))
local target = makeObject("Target", Color3.fromRGB(255, 150, 40))

local function setModel(obj, name, icon)
	if obj.model then
		obj.model:Destroy()
	end
	local model, measure = ObjectModels.build(name, icon, obj.color)
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = INK
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	model.Parent = viewer
	obj.model = model
	obj.measure = measure
end

-- Horizontal lines at multiples of the reference height (1x, 2x, ...).
local rulerLines = {}
for k = 1, MAX_RULER_LINES do
	local line = scenePart({
		Name = "Ruler" .. k,
		Material = Enum.Material.Neon,
		Color = WHITE,
		Transparency = 1,
	})
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.new(0, 70, 0, 30)
	tag.LightInfluence = 0
	tag.Enabled = false
	tag.Parent = line
	textStroke(label(tag, { Size = UDim2.fromScale(1, 1), Text = k .. "x" }), 2)
	rulerLines[k] = { part = line, tag = tag }
end

local framing = { cx = 0, width = LARGEST_SIZE, height = LARGEST_SIZE, depth = LARGEST_SIZE / 2 }
local refDisplaySize = LARGEST_SIZE

-- Scale a model so its measured dimension equals `measuredSize` studs and
-- return its bounding-box size.
local function scaleObject(obj, measuredSize)
	obj.model:ScaleTo(math.max(measuredSize / obj.measure, 1e-4))
	local _, size = obj.model:GetBoundingBox()
	return size
end

-- Stand the model on the floor with its bounding box centered on centerX.
local function positionObject(obj, centerX)
	local model = obj.model
	local boxCFrame, size = model:GetBoundingBox()
	local offset = boxCFrame.Position - model:GetPivot().Position
	local bottom = offset.Y - size.Y / 2
	model:PivotTo(CFrame.new(SCENE + Vector3.new(centerX - offset.X, -bottom, -offset.Z)))
	obj.anchor.Position = SCENE + Vector3.new(centerX, size.Y, 0)
end

-- Camera that frames both objects so the taller one fills most of the
-- screen, leaving the bottom clear for the game panel.
local function cameraFor(f)
	local camera = workspace.CurrentCamera
	local viewport = camera.ViewportSize
	local aspect = viewport.X / math.max(viewport.Y, 1)
	local t = math.tan(math.rad(VIEW_FOV) / 2)
	local dist = math.max(f.height / 0.68 / (2 * t), f.width / 0.86 / (2 * t * aspect)) + f.depth / 2
	local viewHeight = 2 * dist * t
	local aimY = math.max(f.height * 0.5 - viewHeight * 0.1, 0)
	local aim = SCENE + Vector3.new(f.cx, aimY, 0)
	local eye = SCENE + Vector3.new(f.cx, aimY + dist * 0.1, -dist)
	return CFrame.lookAt(eye, aim), viewHeight
end

local function updateRuler(viewHeight)
	local step = 10
	for _, s in ipairs({ 1, 2, 5, 10 }) do
		if refDisplaySize * s / viewHeight >= 0.07 then
			step = s
			break
		end
	end
	local lineLength = framing.width * 1.3 + 4
	local thickness = math.max(viewHeight * 0.003, 0.03)
	local z = framing.depth / 2 + 0.5
	for k, entry in ipairs(rulerLines) do
		local y = refDisplaySize * k
		local visible = k % step == 0 and y <= viewHeight * 1.05
		entry.part.Transparency = visible and 0.4 or 1
		entry.tag.Enabled = visible
		if visible then
			entry.part.Size = Vector3.new(lineLength, thickness, thickness)
			entry.part.CFrame = CFrame.new(SCENE + Vector3.new(framing.cx, y, z))
			entry.tag.StudsOffsetWorldSpace = Vector3.new(-lineLength / 2, 0, 0)
		end
	end
end

local function placeParts(ratio)
	if not reference.model or not target.model then
		return
	end
	refDisplaySize = LARGEST_SIZE / math.max(1, ratio)
	local refSize = scaleObject(reference, refDisplaySize)
	local targetSize = scaleObject(target, refDisplaySize * ratio)
	local tallest = math.max(refSize.Y, targetSize.Y)
	local gap = math.max(tallest, refSize.X, targetSize.X) * 0.12 + 1
	local refX = -(gap / 2 + refSize.X / 2)
	local targetX = gap / 2 + targetSize.X / 2
	positionObject(reference, refX)
	positionObject(target, targetX)

	local left, right = refX - refSize.X / 2, targetX + targetSize.X / 2
	framing.cx = (left + right) / 2
	framing.width = right - left
	framing.height = tallest
	framing.depth = math.max(refSize.Z, targetSize.Z)

	-- Stage disc under both objects; raised a hair (relative to scale) to
	-- avoid z-fighting with the floor when zoomed far out.
	local radius = framing.width * 0.6 + 2
	local lift = tallest * 0.002 + 0.02
	stageDisc.Size = Vector3.new(lift * 2, radius * 2, radius * 2)
	stageDisc.CFrame = CFrame.new(SCENE + Vector3.new(framing.cx, 0, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local ringRadius = radius * 1.04
	stageRing.Size = Vector3.new(lift * 1.2, ringRadius * 2, ringRadius * 2)
	stageRing.CFrame = stageDisc.CFrame

	local _, viewHeight = cameraFor(framing)
	updateRuler(viewHeight)
end

local function isFiniteCFrame(cf)
	local p, look = cf.Position, cf.LookVector
	return p.X == p.X and p.Y == p.Y and p.Z == p.Z and look.X == look.X and math.abs(p.Magnitude) < 1e7
end

local function cameraStep(dt)
	local camera = workspace.CurrentCamera
	local desired = cameraFor(framing)
	-- Never let a bad value poison the camera; Lerp from NaN stays NaN.
	if not isFiniteCFrame(desired) then
		return
	end
	if not isFiniteCFrame(camera.CFrame) then
		camera.CFrame = desired
		return
	end
	camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-dt * 6))
end

-- Freeze the character while playing by anchoring its root locally (the
-- client owns its character's physics). Never yields, unlike waiting on
-- the PlayerModule, which may not exist in every setup.
local function setCharacterFrozen(frozen)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = frozen
	end
end

local inViewer = false

-- The lobby's haze washes out the viewing room; thin it while playing.
local savedAtmosphereDensity = nil

local function enterViewer()
	inViewer = true
	viewer.Parent = workspace
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		savedAtmosphereDensity = atmosphere.Density
		atmosphere.Density = 0.05
	end
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = VIEW_FOV
	local desired = cameraFor(framing)
	if isFiniteCFrame(desired) then
		camera.CFrame = desired
	end
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, cameraStep)
	setCharacterFrozen(true)
end

local function exitViewer()
	if not inViewer then
		return
	end
	inViewer = false
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	viewer.Parent = nil
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere and savedAtmosphereDensity then
		atmosphere.Density = savedAtmosphereDensity
	end
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	setCharacterFrozen(false)
end

-- White flash between the lobby and the viewing room.
local fadeGui = Instance.new("ScreenGui")
fadeGui.Name = "SizerFade"
fadeGui.IgnoreGuiInset = true
fadeGui.DisplayOrder = 10
fadeGui.ResetOnSpawn = false
fadeGui.Parent = player:WaitForChild("PlayerGui")
local fade = frame(fadeGui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 1,
})

-- Always fades back out, even if the callback errors, so the screen can
-- never get stuck white. Returns pcall-style ok, err.
local function fadeThrough(callback)
	local fadeIn = TweenService:Create(fade, TweenInfo.new(0.18), { BackgroundTransparency = 0 })
	fadeIn:Play()
	-- Hard safety: the overlay can never stay up, even if something yields.
	task.delay(1.5, function()
		fade.BackgroundTransparency = 1
	end)
	fadeIn.Completed:Wait()
	local ok, err = xpcall(callback, debug.traceback)
	TweenService:Create(fade, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	return ok, err
end

--==========================================================================
-- State
--==========================================================================

local activeStation = nil
local sessionId = 0
local currentRound = nil
local currentRatio = 1
local isDragging = false
local guessLocked = false
local transitioning = false
local sessionMode = "normal" -- "normal" or "timed"
local timedEndsAt = nil -- server clock time the challenge ends
local timedEnded = false

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
	difficultyTag.Visible = false
	setLockEnabled(false)
	local category = activeStation:GetAttribute("Category")
	RequestRound:FireServer(category ~= "" and category or nil)
end

local function stopSession()
	if not activeStation or transitioning then
		return
	end
	transitioning = true
	if sessionMode == "timed" and not timedEnded then
		TimedStop:FireServer()
	end
	if sessionMode == "daily" then
		bus:SetAttribute("RefreshRequest", os.clock())
	end
	activeStation = nil
	sessionMode = "normal"
	timedEndsAt = nil
	sessionId += 1
	currentRound = nil
	isDragging = false
	fadeThrough(function()
		exitViewer()
		panel.Visible = false
		timerCard.Visible = false
		endCard.Visible = false
		dailyCard.Visible = false
		setLobbyHudVisible(true)
	end)
	transitioning = false
end

-- Start (or restart) a 60-second run; the server replies with the end time.
local function beginTimedRun()
	timedEnded = false
	timedEndsAt = nil
	timedScoreText.Text = "CHALLENGE SCORE: 0"
	timerText.Text = "⏱️ 1:00"
	timerCard.Visible = true
	endCard.Visible = false
	panel.Visible = true
	TimedStart:FireServer()
end

local function startSession(station)
	if transitioning or activeStation == station then
		return
	end
	transitioning = true
	if sessionMode == "timed" and not timedEnded then
		TimedStop:FireServer()
	end
	activeStation = station
	local mode = station:GetAttribute("Mode")
	sessionMode = (mode == "timed" or mode == "daily") and mode or "normal"
	timedEnded = false
	timedEndsAt = nil
	sessionId += 1
	print("[Sizer] Starting game at", station.Name, station:GetAttribute("DisplayName"), sessionMode)

	local color = station:GetAttribute("Color") or ORANGE
	categoryTag.BackgroundColor3 = color
	categoryGloss.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	categoryText.Text = station:GetAttribute("DisplayName") or "MIXED"

	currentRound = nil
	local ok, err = fadeThrough(function()
		if not inViewer then
			enterViewer()
		end
		setModel(reference, "Reference", "?")
		setModel(target, "Target", "?")
		reference.label.Text = "Reference"
		target.label.Text = "Target"
		setRatio(1)
		local desired = cameraFor(framing)
		if isFiniteCFrame(desired) then
			workspace.CurrentCamera.CFrame = desired
		end
		print(string.format(
			"[Sizer] In viewing room. Camera at %s looking at %s, camera type %s, objects %s / %s",
			tostring(workspace.CurrentCamera.CFrame.Position),
			tostring(workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 10),
			tostring(workspace.CurrentCamera.CameraType),
			tostring(reference.model and reference.model:GetExtentsSize()),
			tostring(target.model and target.model:GetExtentsSize())
		))
		panel.Visible = true
		timerCard.Visible = false
		endCard.Visible = false
		dailyCard.Visible = false
		setLobbyHudVisible(false)
	end)
	transitioning = false
	if not ok then
		warn("[Sizer] Could not start the game:", err)
		activeStation = nil
		sessionMode = "normal"
		exitViewer()
		panel.Visible = false
		setLobbyHudVisible(true)
		return
	end
	if sessionMode == "timed" then
		beginTimedRun()
	end
	requestRound()
end

TimedStart.OnClientEvent:Connect(function(endsAt)
	if activeStation and sessionMode == "timed" then
		timedEndsAt = endsAt
	end
end)

TimedEnd.OnClientEvent:Connect(function(data)
	if not activeStation or sessionMode ~= "timed" then
		return
	end
	timedEnded = true
	sessionId += 1 -- cancel any pending next round
	currentRound = nil
	isDragging = false
	panel.Visible = false
	timerCard.Visible = false
	endScoreText.Text = "SCORE: " .. data.score
	endBestText.Text = data.isNewBest and ("NEW BEST! " .. data.best) or ("BEST: " .. data.best)
	endBestText.TextColor3 = data.isNewBest and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(200, 210, 235)
	endCard.Visible = true
	bump(endCard)
end)

playAgainButton.MouseButton1Click:Connect(function()
	if activeStation and sessionMode == "timed" then
		sessionId += 1
		beginTimedRun()
		requestRound()
	end
end)

endStopButton.MouseButton1Click:Connect(function()
	stopSession()
end)

-- Countdown display; once time is up, no more guesses until the result.
RunService.Heartbeat:Connect(function()
	if sessionMode ~= "timed" or not timedEndsAt or timedEnded then
		return
	end
	local remaining = math.max(0, timedEndsAt - workspace:GetServerTimeNow())
	local whole = math.ceil(remaining)
	timerText.Text = string.format("⏱️ %d:%02d", math.floor(whole / 60), whole % 60)
	timerText.TextColor3 = remaining <= 10 and Color3.fromRGB(255, 110, 110) or WHITE
	if remaining <= 0 and not guessLocked then
		guessLocked = true
		isDragging = false
		setLockEnabled(false)
		questionText.Text = "Time's up!"
	end
end)

RequestRound.OnClientEvent:Connect(function(roundInfo)
	if not activeStation then
		return
	end
	local ok, err = xpcall(function()
		setModel(reference, roundInfo.referenceName, roundInfo.referenceIcon)
		setModel(target, roundInfo.targetName, roundInfo.targetIcon)
		reference.label.Text = string.format("%s\n%s", roundInfo.referenceName, formatHeight(roundInfo.referenceHeight))
		target.label.Text = roundInfo.targetName .. "\n???"
		questionText.Text = string.format("How big is a %s next to a %s?", roundInfo.targetName, roundInfo.referenceName)
		showDifficulty(roundInfo.difficulty)
		if roundInfo.daily then
			categoryText.Text = string.format("DAILY %d/%d", roundInfo.daily.index, roundInfo.daily.total)
		end
		setRatio(1)
	end, debug.traceback)
	if not ok then
		warn("[Sizer] Could not load round", roundInfo.referenceName, "vs", roundInfo.targetName, err)
		task.spawn(stopSession)
		return
	end
	print("[Sizer] Round loaded:", roundInfo.referenceName, "vs", roundInfo.targetName)
	currentRound = roundInfo
	local timeUp = sessionMode == "timed" and timedEndsAt and workspace:GetServerTimeNow() >= timedEndsAt
	if timeUp then
		guessLocked = true
	else
		setLockEnabled(true)
	end
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

local function showCombo(result)
	local combo = result.combo or 0
	if combo < 2 then
		comboPopup.Visible = false
		return
	end
	local text = string.format("🔥 COMBO x%d", combo)
	if (result.comboBonus or 0) > 0 then
		text ..= string.format("   +%d SENSE", result.comboBonus)
	end
	comboPopup.Text = text
	comboPopup.TextTransparency = 0
	comboPopup.Position = UDim2.fromScale(0.5, 0.47)
	comboPopup.Visible = true
	local stroke = comboPopup:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	bump(comboPopup)
	local info = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(comboPopup, info, { Position = UDim2.fromScale(0.5, 0.42), TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
end

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

	-- Reveal: snap the target to its true size; the camera re-frames smoothly.
	placeParts(result.trueTargetHeight / currentRound.referenceHeight)
	target.label.Text = string.format("%s\n%s", currentRound.targetName, formatHeight(result.trueTargetHeight))

	local verdict = result.score >= 90 and "PERFECT!" or result.score >= 70 and "GREAT!" or result.score >= 40 and "CLOSE!" or "WAY OFF!"
	resultText.Text = string.format(
		"%s  Real: %s  |  You: %s  |  +%d sense\n%s",
		verdict,
		formatHeight(result.trueTargetHeight),
		formatHeight(result.guessedTargetHeight),
		result.senseEarned or 0,
		result.fact
	)
	showPopup(result.score)
	showCombo(result)
	if result.timedScore then
		timedScoreText.Text = "CHALLENGE SCORE: " .. result.timedScore
		bump(timedScoreText)
	end

	local mySession = sessionId
	local delaySeconds = sessionMode == "timed" and TIMED_RESULT_DELAY_SECONDS or RESULT_DELAY_SECONDS

	-- The last daily question: show the summary instead of another round.
	if sessionMode == "daily" and result.daily and result.daily.done then
		bus:SetAttribute("RefreshRequest", os.clock())
		task.delay(RESULT_DELAY_SECONDS, function()
			if sessionId == mySession and activeStation and sessionMode == "daily" then
				panel.Visible = false
				dailyScoreText.Text = string.format("%d / %d", result.daily.score, result.daily.total * 100)
				dailyRewardText.Text = string.format("+%d SENSE", result.daily.reward or 0)
				dailyCard.Visible = true
				bump(dailyCard)
			end
		end)
		return
	end
	task.delay(delaySeconds, function()
		local timeLeft = not timedEndsAt or workspace:GetServerTimeNow() < timedEndsAt
		if sessionId == mySession and activeStation and (sessionMode ~= "timed" or timeLeft) then
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
	local stations = {}
	for _, station in ipairs(stationsFolder:GetChildren()) do
		if station:GetAttribute("Mode") ~= "timed" then
			table.insert(stations, station)
		end
	end
	if #stations > 0 then
		startSession(stations[math.random(1, #stations)])
	end
end)

challengeButton.MouseButton1Click:Connect(function()
	for _, station in ipairs(stationsFolder:GetChildren()) do
		if station:GetAttribute("Mode") == "timed" then
			startSession(station)
			return
		end
	end
end)

-- The daily challenge reuses the normal session flow with a stand-in
-- "station" (never placed in the world) that carries the same attributes.
local dailyStation = Instance.new("Folder")
dailyStation.Name = "DailyStation"
dailyStation:SetAttribute("Category", "__daily")
dailyStation:SetAttribute("DisplayName", "DAILY")
dailyStation:SetAttribute("Color", DAILY_BLUE)
dailyStation:SetAttribute("Mode", "daily")

dailyButton.MouseButton1Click:Connect(function()
	if not bus:GetAttribute("DailyDone") then
		startSession(dailyStation)
	end
end)

dailyDoneButton.MouseButton1Click:Connect(stopSession)

-- Lets the tutorial send the player back to the lobby.
bus:GetAttributeChangedSignal("RequestExit"):Connect(function()
	if activeStation then
		stopSession()
	end
end)

-- If the server says today's daily is already finished, leave the screen.
ProgressEvent.OnClientEvent:Connect(function(kind)
	if kind == "dailyDone" and sessionMode == "daily" then
		stopSession()
	end
end)

-- Button text and badge follow the status ProgressClient publishes.
local dailyShownText = nil
local function formatCountdown(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
end
RunService.Heartbeat:Connect(function()
	local done = bus:GetAttribute("DailyDone")
	local answered = bus:GetAttribute("DailyAnswered") or 0
	local total = bus:GetAttribute("DailyTotal") or 5
	local text
	if done then
		local resetIn = (bus:GetAttribute("DailyResetIn") or 0) - (os.clock() - (bus:GetAttribute("DailyStatusAt") or os.clock()))
		text = "✅ " .. formatCountdown(resetIn)
	elseif answered > 0 then
		text = string.format("%d/%d", answered, total)
	else
		text = "DAILY"
	end
	if text ~= dailyShownText then
		dailyShownText = text
		dailyButton.Caption.Text = text
	end
	dailyBadge.Visible = bus:GetAttribute("DailyDone") == false
	dailyButton.BackgroundColor3 = done and Color3.fromRGB(95, 105, 140) or DAILY_BLUE
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
	while true do
		local nextAt = player:GetAttribute("NextRewardAt")
		local interval = player:GetAttribute("RewardInterval") or 120
		local amount = player:GetAttribute("RewardAmount") or 25
		if nextAt then
			local remaining = math.max(0, nextAt - workspace:GetServerTimeNow())
			rewardText.Text = string.format(
				"NEXT: %d SENSE   %d:%02d",
				amount,
				math.floor(remaining / 60),
				math.floor(remaining % 60)
			)
			rewardBarFill.Size = UDim2.fromScale(1 - remaining / interval, 1)
		end
		task.wait(0.25)
	end
end)
