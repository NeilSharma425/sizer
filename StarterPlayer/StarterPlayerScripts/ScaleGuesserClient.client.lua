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

local player = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local RequestRound = remotesFolder:WaitForChild("RequestRound")
local SubmitGuess = remotesFolder:WaitForChild("SubmitGuess")
local RoundResult = remotesFolder:WaitForChild("RoundResult")

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
-- Viewing room (local to this client, far away from the lobby)
--==========================================================================

-- The camera is moved here while playing; the character stays in the lobby.
local SCENE = Vector3.new(0, 400, 3000)
local REF_H = 10
local WIDTH_FACTOR = 0.6
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
	Color = Color3.fromRGB(226, 232, 246),
})
scenePart({
	Name = "Backdrop",
	Size = Vector3.new(8000, 4000, 2),
	Position = SCENE + Vector3.new(0, 1990, 1500),
	Color = Color3.fromRGB(175, 205, 250),
})
local stageRing = scenePart({
	Name = "StageRing",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(120, 200, 255),
})
local stageDisc = scenePart({ Name = "StageDisc", Shape = Enum.PartType.Cylinder, Color = WHITE })

local function makeObject(name, color)
	local p = scenePart({ Name = name, Color = color })

	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = INK
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = p

	-- Emoji icon on the face pointing at the camera.
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Front
	face.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	face.CanvasSize = Vector2.new(400, 400)
	face.LightInfluence = 0
	face.Parent = p
	local icon = label(face, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		Text = "",
	})
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 280, 0, 64)
	billboard.SizeOffset = Vector2.new(0, 0.75)
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = true
	billboard.Parent = p
	local text = label(billboard, { Size = UDim2.fromScale(1, 1), Text = name })
	textStroke(text, 3)

	return { part = p, face = face, icon = icon, billboard = billboard, label = text }
end

local reference = makeObject("Reference", Color3.fromRGB(60, 120, 230))
local target = makeObject("Target", Color3.fromRGB(255, 150, 40))

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

local framing = { cx = 0, width = 20, height = REF_H, depth = REF_H * WIDTH_FACTOR }
local currentShape = "Block"

local function objectSize(height)
	if currentShape == "Ball" then
		return Vector3.new(height, height, height)
	end
	local width = height * WIDTH_FACTOR
	return Vector3.new(width, height, width)
end

local function setObject(obj, size, centerX)
	obj.part.Shape = currentShape == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
	obj.part.Size = size
	obj.part.CFrame = CFrame.new(SCENE + Vector3.new(centerX, size.Y / 2, 0))
	-- Match the canvas aspect to the face so the emoji isn't stretched.
	obj.face.CanvasSize = Vector2.new(math.max(1, math.floor(400 * size.X / size.Y)), 400)
	obj.billboard.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2, 0)
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
		if REF_H * s / viewHeight >= 0.07 then
			step = s
			break
		end
	end
	local lineLength = framing.width * 1.3 + 4
	local thickness = math.max(viewHeight * 0.003, 0.03)
	local z = framing.depth / 2 + 0.5
	for k, entry in ipairs(rulerLines) do
		local y = REF_H * k
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
	local refSize = objectSize(REF_H)
	local targetSize = objectSize(math.max(REF_H * ratio, 0.05))
	local tallest = math.max(refSize.Y, targetSize.Y)
	local gap = tallest * 0.15 + 1
	local refX = -(gap / 2 + refSize.X / 2)
	local targetX = gap / 2 + targetSize.X / 2
	setObject(reference, refSize, refX)
	setObject(target, targetSize, targetX)

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

local function cameraStep(dt)
	local camera = workspace.CurrentCamera
	camera.CFrame = camera.CFrame:Lerp((cameraFor(framing)), 1 - math.exp(-dt * 6))
end

local playerControls = nil
local function setControlsEnabled(enabled)
	if not playerControls then
		local ok, module = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		end)
		if ok and module then
			playerControls = module:GetControls()
		end
	end
	if playerControls then
		if enabled then
			playerControls:Enable()
		else
			playerControls:Disable()
		end
	end
end

local inViewer = false

local function enterViewer()
	inViewer = true
	viewer.Parent = workspace
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = VIEW_FOV
	camera.CFrame = cameraFor(framing)
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, cameraStep)
	setControlsEnabled(false)
end

local function exitViewer()
	if not inViewer then
		return
	end
	inViewer = false
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	viewer.Parent = nil
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	setControlsEnabled(true)
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

local function fadeThrough(callback)
	local fadeIn = TweenService:Create(fade, TweenInfo.new(0.18), { BackgroundTransparency = 0 })
	fadeIn:Play()
	fadeIn.Completed:Wait()
	callback()
	TweenService:Create(fade, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
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

	local color = station:GetAttribute("Color") or ORANGE
	categoryTag.BackgroundColor3 = color
	categoryGloss.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	categoryText.Text = station:GetAttribute("DisplayName") or "MIXED"

	currentRound = nil
	currentShape = "Block"
	reference.label.Text = "Reference"
	target.label.Text = "Target"
	reference.icon.Text = ""
	target.icon.Text = ""
	setRatio(1)

	fadeThrough(function()
		if not inViewer then
			enterViewer()
		end
		panel.Visible = true
		quickPlayButton.Visible = false
		rewardCard.Visible = false
	end)
	transitioning = false
	requestRound()
end

RequestRound.OnClientEvent:Connect(function(roundInfo)
	if not activeStation then
		return
	end
	currentRound = roundInfo
	currentShape = roundInfo.shape == "Ball" and "Ball" or "Block"
	reference.icon.Text = roundInfo.referenceIcon or ""
	target.icon.Text = roundInfo.targetIcon or ""
	reference.label.Text = string.format("%s\n%s", roundInfo.referenceName, formatHeight(roundInfo.referenceHeight))
	target.label.Text = roundInfo.targetName .. "\n???"
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
