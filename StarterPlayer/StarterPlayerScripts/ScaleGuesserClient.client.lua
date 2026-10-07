--[[
	ScaleGuesserClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ScaleGuesserClient

	Lobby HUD (coins/trophies, playtime reward, Quick Play) and the game
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

local ObjectModels = require(ReplicatedStorage:WaitForChild("ObjectModels"))

local stationsFolder = workspace:WaitForChild("Map"):WaitForChild("Stations")

local MIN_RATIO = 0.02
local MAX_RATIO = 50
local LOG_MIN = math.log(MIN_RATIO)
local LOG_MAX = math.log(MAX_RATIO)

local RESULT_DELAY_SECONDS = 4

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

-- Compact labeled counters stacked in the top-right corner, e.g.
-- [🪙 COINS 120]. Scale about their top-right anchor on small screens.
local function counter(order, title, icon, color)
	local card = frame(hud, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12 + (order - 1) * 54),
		Size = UDim2.new(0, 190, 0, 46),
		BackgroundColor3 = Color3.fromRGB(30, 32, 48),
		BackgroundTransparency = 0.15,
	})
	corner(card, UDim.new(0, 12))
	stroke(card, 2.5, color:Lerp(INK, 0.3))

	local badge = frame(card, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundColor3 = color,
	})
	corner(badge, UDim.new(1, 0))
	gloss(badge, color)
	label(badge, {
		Size = UDim2.fromScale(0.72, 0.72),
		Position = UDim2.fromScale(0.14, 0.14),
		Text = icon,
	})

	label(card, {
		Size = UDim2.new(0, 70, 0, 16),
		Position = UDim2.new(0, 50, 0, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color:Lerp(WHITE, 0.35),
		Text = title,
	})
	local value = label(card, {
		Size = UDim2.new(1, -60, 0, 22),
		Position = UDim2.new(0, 50, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "0",
	})
	textStroke(value, 2)
	responsive(card)
	return value
end

local coinsText = counter(1, "COINS", "🪙", Color3.fromRGB(255, 195, 40))
local trophyText = counter(2, "SCORE", "🏆", Color3.fromRGB(255, 130, 50))

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
	if not activeStation or transitioning then
		return
	end
	transitioning = true
	activeStation = nil
	sessionId += 1
	currentRound = nil
	isDragging = false
	fadeThrough(function()
		exitViewer()
		panel.Visible = false
		quickPlayButton.Visible = true
		rewardCard.Visible = true
	end)
	transitioning = false
end

local function startSession(station)
	if transitioning or activeStation == station then
		return
	end
	transitioning = true
	activeStation = station
	sessionId += 1
	print("[Sizer] Starting game at", station.Name, station:GetAttribute("DisplayName"))

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
		quickPlayButton.Visible = false
		rewardCard.Visible = false
	end)
	transitioning = false
	if not ok then
		warn("[Sizer] Could not start the game:", err)
		activeStation = nil
		exitViewer()
		panel.Visible = false
		quickPlayButton.Visible = true
		rewardCard.Visible = true
		return
	end
	requestRound()
end

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
		setRatio(1)
	end, debug.traceback)
	if not ok then
		warn("[Sizer] Could not load round", roundInfo.referenceName, "vs", roundInfo.targetName, err)
		task.spawn(stopSession)
		return
	end
	print("[Sizer] Round loaded:", roundInfo.referenceName, "vs", roundInfo.targetName)
	currentRound = roundInfo
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

	-- Reveal: snap the target to its true size; the camera re-frames smoothly.
	placeParts(result.trueTargetHeight / currentRound.referenceHeight)
	target.label.Text = string.format("%s\n%s", currentRound.targetName, formatHeight(result.trueTargetHeight))

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
	if #stations > 0 then
		startSession(stations[math.random(1, #stations)])
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
