--[[
	LiveRoundClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.LiveRoundClient

	The live lobby round (LiveRoundManager runs it). Everyone in the lobby
	sees a "LIVE ROUND! JOIN" prompt at the top of the screen; players who
	join get the question with a slider and LOCK IN while a timer counts
	down, then a shared reveal with both objects at their real sizes, their
	score and Sense, and the top-3 podium.

	Players who are in a game session or haven't finished the tutorial skip
	it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local LiveRound = remotes:WaitForChild("LiveRound")
local ObjectModels = require(ReplicatedStorage:WaitForChild("ObjectModels"))
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
local GOLD = Color3.fromRGB(255, 200, 50)
local GREEN = Color3.fromRGB(80, 210, 70)
local PANEL = Color3.fromRGB(40, 45, 75)
local LIVE = Color3.fromRGB(255, 80, 110)
local MUTED = Color3.fromRGB(205, 210, 235)

local MIN_RATIO, MAX_RATIO = 0.02, 50
local LOG_MIN, LOG_MAX = math.log(MIN_RATIO), math.log(MAX_RATIO)

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
	corner(b, UDim.new(0, 12))
	stroke(b, 3)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.Parent = b
	return b
end

local function formatMeters(m)
	local function trim(text)
		return (text:gsub("%.0$", ""))
	end
	if m >= 1000 then
		return trim(string.format("%.1f", m / 1000)) .. " km"
	elseif m >= 1 then
		return trim(string.format("%.1f", m)) .. " m"
	elseif m >= 0.01 then
		return trim(string.format("%.1f", m * 100)) .. " cm"
	end
	return trim(string.format("%.1f", m * 1000)) .. " mm"
end

local function formatRatio(r)
	if r >= 10 then
		return string.format("%dx", math.floor(r + 0.5))
	end
	return (string.format("%.2fx", r):gsub("0x$", "x"))
end

--==========================================================================
-- Panel
--==========================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SizerLiveRound"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = frame(gui, {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.new(0, 560, 0, 330),
	BackgroundColor3 = PANEL,
})
corner(card, UDim.new(0, 22))
stroke(card, 5, LIVE)
local cardScale = Instance.new("UIScale")
cardScale.Parent = card
local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		cardScale.Scale = math.clamp(math.min(camera.ViewportSize.X / 620, camera.ViewportSize.Y / 520), 0.5, 1)
	end
end

local header = label(card, { Position = UDim2.new(0, 20, 0, 12), Size = UDim2.new(1, -150, 0, 38), TextXAlignment = Enum.TextXAlignment.Left, Text = "LIVE ROUND!", TextColor3 = LIVE })
local timerLabel = label(card, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 12), Size = UDim2.new(0, 110, 0, 38), Text = "15", TextColor3 = GOLD })

-- Question view ----------------------------------------------------------

local questionView = frame(card, { Name = "Question", Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1 })
local questionText = label(questionView, { Position = UDim2.new(0, 20, 0, 4), Size = UDim2.new(1, -40, 0, 56), TextWrapped = true, Text = "" })
local guessText = label(questionView, { Position = UDim2.new(0, 20, 0, 70), Size = UDim2.new(1, -40, 0, 34), Text = "", TextColor3 = GOLD })

local track = frame(questionView, { Name = "Track", Position = UDim2.new(0, 40, 0, 128), Size = UDim2.new(1, -80, 0, 18), BackgroundColor3 = Color3.fromRGB(25, 28, 48) })
corner(track, UDim.new(1, 0))
stroke(track, 2)
local fill = frame(track, { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = LIVE })
corner(fill, UDim.new(1, 0))
local handle = frame(track, { Name = "Handle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 34, 0, 34), BackgroundColor3 = WHITE, ZIndex = 3 })
corner(handle, UDim.new(1, 0))
stroke(handle, 3)
label(questionView, { Position = UDim2.new(0, 30, 0, 152), Size = UDim2.new(0, 80, 0, 20), Text = "SMALLER", TextColor3 = MUTED })
label(questionView, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -30, 0, 152), Size = UDim2.new(0, 80, 0, 20), Text = "BIGGER", TextColor3 = MUTED })

local lockButton = textButton(questionView, "LOCK IN", GREEN, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(0, 220, 0, 56) })
local lockedNote = label(questionView, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(0, 360, 0, 34), Text = "LOCKED IN! WAITING FOR OTHERS...", TextColor3 = GREEN, Visible = false })

-- Results view -----------------------------------------------------------

local resultsView = frame(card, { Name = "Results", Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, Visible = false })
local viewport = Instance.new("ViewportFrame")
viewport.Position = UDim2.new(0, 16, 0, 4)
viewport.Size = UDim2.new(0, 250, 0, 200)
viewport.BackgroundColor3 = Color3.fromRGB(52, 58, 92)
viewport.BorderSizePixel = 0
viewport.Ambient = Color3.fromRGB(170, 170, 190)
viewport.LightColor = WHITE
viewport.LightDirection = Vector3.new(-1, -1.2, -0.6)
viewport.Parent = resultsView
corner(viewport, UDim.new(0, 12))
local viewCamera = Instance.new("Camera")
viewCamera.FieldOfView = 35
viewCamera.Parent = viewport
viewport.CurrentCamera = viewCamera

local realText = label(resultsView, { Position = UDim2.new(0, 280, 0, 4), Size = UDim2.new(1, -296, 0, 52), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "" })
local mineText = label(resultsView, { Position = UDim2.new(0, 280, 0, 60), Size = UDim2.new(1, -296, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Text = "", TextColor3 = GOLD })
local podium = {}
for i = 1, 3 do
	podium[i] = label(resultsView, {
		Position = UDim2.new(0, 280, 0, 96 + (i - 1) * 30),
		Size = UDim2.new(1, -296, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		TextColor3 = ({ GOLD, Color3.fromRGB(215, 220, 235), Color3.fromRGB(225, 150, 90) })[i],
	})
end
local closeButton = textButton(resultsView, "OK", Color3.fromRGB(95, 105, 140), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -12), Size = UDim2.new(0, 100, 0, 44) })

--==========================================================================
-- State
--==========================================================================

local current = nil -- { id, referenceHeight, endsAt, ratio, locked }
local dragging = false
local hideToken = 0

local function inGame()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local panel = hud and hud:FindFirstChild("GamePanel")
	return panel ~= nil and panel.Visible
end

local function canPlay()
	return player:GetAttribute("TutorialDone") == true and not inGame()
end

local function setRatio(ratio)
	if not current then
		return
	end
	current.ratio = math.clamp(ratio, MIN_RATIO, MAX_RATIO)
	local a = (math.log(current.ratio) - LOG_MIN) / (LOG_MAX - LOG_MIN)
	handle.Position = UDim2.fromScale(a, 0.5)
	fill.Size = UDim2.fromScale(a, 1)
	guessText.Text = string.format("YOUR GUESS: %s  (%s)", formatRatio(current.ratio), formatMeters(current.referenceHeight * current.ratio))
end

local function sendGuess()
	if current and not current.locked then
		LiveRound:FireServer("guess", current.id, current.ratio)
	end
end

local function ratioFromX(x)
	local pos, size = track.AbsolutePosition, track.AbsoluteSize
	local a = math.clamp((x - pos.X) / math.max(size.X, 1), 0, 1)
	return math.exp(LOG_MIN + a * (LOG_MAX - LOG_MIN))
end

local function beginDrag(input)
	if not current or current.locked then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		setRatio(ratioFromX(input.Position.X))
	end
end
track.InputBegan:Connect(beginDrag)
handle.InputBegan:Connect(beginDrag)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setRatio(ratioFromX(input.Position.X))
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		dragging = false
		sendGuess() -- the server keeps the latest guess until time runs out
	end
end)

lockButton.MouseButton1Click:Connect(function()
	if not current or current.locked then
		return
	end
	sendGuess()
	current.locked = true
	dragging = false
	lockButton.Visible = false
	lockedNote.Visible = true
	sfx("lock")
end)

local function hide()
	hideToken += 1
	gui.Enabled = false
	viewport:ClearAllChildren()
	viewCamera = Instance.new("Camera")
	viewCamera.FieldOfView = 35
	viewCamera.Parent = viewport
	viewport.CurrentCamera = viewCamera
end
closeButton.MouseButton1Click:Connect(hide)

-- Both objects side by side at their true relative sizes.
local function showModels(data)
	viewport:ClearAllChildren()
	viewCamera = Instance.new("Camera")
	viewCamera.FieldOfView = 35
	viewCamera.Parent = viewport
	viewport.CurrentCamera = viewCamera

	local tallest = math.max(data.referenceHeight, data.targetHeight)
	local x = 0
	local maxHeight, totalWidth = 0, 0
	for _, entry in ipairs({ { data.referenceName, data.referenceIcon, data.referenceHeight }, { data.targetName, data.targetIcon, data.targetHeight } }) do
		local ok, model, measure = pcall(ObjectModels.build, entry[1], entry[2], Color3.fromRGB(200, 200, 200))
		if ok and model then
			local studs = 10 * entry[3] / tallest
			model:ScaleTo(math.max(studs / measure, 1e-4))
			local boxCFrame, size = model:GetBoundingBox()
			local offset = boxCFrame.Position - model:GetPivot().Position
			model:PivotTo(CFrame.new(x + size.X / 2 - offset.X, size.Y / 2 - offset.Y, -offset.Z))
			model.Parent = viewport
			x += size.X + 1
			maxHeight = math.max(maxHeight, size.Y)
			totalWidth = x
		end
	end
	local center = Vector3.new(totalWidth / 2, maxHeight / 2, 0)
	local dist = math.max(maxHeight, totalWidth * 0.8) / (2 * math.tan(math.rad(35) / 2)) + 4
	viewCamera.CFrame = CFrame.lookAt(center + Vector3.new(0, maxHeight * 0.15, -dist), center)
end

--==========================================================================
-- Events
--==========================================================================

--==========================================================================
-- Join prompt (top of the screen). Nobody is pulled into a live round;
-- they tap JOIN if they want in.
--==========================================================================

local promptGui = Instance.new("ScreenGui")
promptGui.Name = "SizerLivePrompt"
promptGui.ResetOnSpawn = false
promptGui.DisplayOrder = 6
promptGui.Enabled = false
promptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
promptGui.Parent = playerGui

local prompt = frame(promptGui, {
	Name = "Prompt",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.new(0, 470, 0, 76),
	BackgroundColor3 = PANEL,
})
corner(prompt, UDim.new(0, 18))
stroke(prompt, 4, LIVE)
local promptScale = Instance.new("UIScale")
promptScale.Parent = prompt
label(prompt, { Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Text = "LIVE ROUND!", TextColor3 = LIVE })
local promptSub = label(prompt, { Position = UDim2.new(0, 16, 0, 42), Size = UDim2.new(1, -150, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Text = "", TextColor3 = GOLD })
local joinButton = textButton(prompt, "JOIN", GREEN, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 116, 0, 52) })

local promptId = nil -- round the prompt is for
local promptStartsAt = nil -- os.clock() when the question starts (during "soon")
local pending = nil -- "start" data for a round the player hasn't joined yet
local joinedId = nil

local function hidePrompt()
	promptGui.Enabled = false
end

local function showPrompt(id)
	promptId = id
	local camera = workspace.CurrentCamera
	if camera then
		promptScale.Scale = ScreenFit.scaleFor(camera.ViewportSize, 470, 76, { fx = 0.6, fy = 0.13 })
	end
	promptGui.Enabled = true
end

local function openWaiting(seconds)
	hideToken += 1
	current = nil
	updateScale()
	gui.Enabled = true
	questionView.Visible = true
	resultsView.Visible = false
	header.Text = "LIVE ROUND!"
	questionText.Text = "Everyone in the lobby gets the same question. Get ready!"
	guessText.Text = ""
	lockButton.Visible = false
	lockedNote.Visible = false
	track.Visible = false
	timerLabel.Text = tostring(math.max(1, math.ceil(seconds)))
	local endsAt = os.clock() + seconds
	task.spawn(function()
		while gui.Enabled and not current and os.clock() < endsAt do
			timerLabel.Text = tostring(math.max(1, math.ceil(endsAt - os.clock())))
			task.wait(0.2)
		end
	end)
end

local function openQuestion(data)
	hideToken += 1
	current = { id = data.id, referenceHeight = data.referenceHeight, endsAt = data.endsAt, ratio = 1, locked = false }
	updateScale()
	gui.Enabled = true
	questionView.Visible = true
	resultsView.Visible = false
	track.Visible = true
	lockButton.Visible = true
	lockedNote.Visible = false
	header.Text = "LIVE ROUND!"
	questionText.Text = string.format(
		"How big is %s %s compared to %s %s (%s)?",
		data.targetIcon or "",
		string.upper(data.targetName),
		data.referenceIcon or "",
		string.upper(data.referenceName),
		formatMeters(data.referenceHeight)
	)
	setRatio(1)
	sfx("start")
end

joinButton.MouseButton1Click:Connect(function()
	if not promptId or not canPlay() then
		hidePrompt()
		return
	end
	joinedId = promptId
	hidePrompt()
	sfx("click")
	if pending and pending.id == joinedId then
		openQuestion(pending)
		pending = nil
	else
		openWaiting(promptStartsAt and (promptStartsAt - os.clock()) or 3)
	end
end)

-- Keep the prompt's countdown current, and drop it once the round is over.
RunService.Heartbeat:Connect(function()
	if not promptGui.Enabled then
		return
	end
	if not canPlay() then
		hidePrompt()
		return
	end
	if pending then
		local left = pending.endsAt - workspace:GetServerTimeNow()
		if left <= 1 then
			hidePrompt()
			return
		end
		promptSub.Text = string.format("Win up to +70 SENSE!  %ds left to join", math.ceil(left))
	elseif promptStartsAt then
		promptSub.Text = string.format("Win up to +70 SENSE!  Starts in %ds", math.max(1, math.ceil(promptStartsAt - os.clock())))
	end
end)

LiveRound.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then
		return
	end
	if kind == "soon" then
		if not canPlay() then
			return
		end
		pending = nil
		joinedId = nil
		promptStartsAt = os.clock() + data.seconds
		showPrompt(data.id)
		sfx("live")
	elseif kind == "start" then
		if joinedId == data.id then
			openQuestion(data)
		elseif canPlay() then
			pending = data
			promptStartsAt = nil
			if promptId ~= data.id or not promptGui.Enabled then
				showPrompt(data.id)
			end
		end
	elseif kind == "results" then
		pending = nil
		hidePrompt()
		if not current or current.id ~= data.id or not gui.Enabled then
			return
		end
		current = nil
		dragging = false
		questionView.Visible = false
		resultsView.Visible = true
		header.Text = "THE ANSWER"
		timerLabel.Text = ""
		local ratio = data.targetHeight / data.referenceHeight
		realText.Text = string.format("%s is %s the size of %s (%s)", data.targetName, formatRatio(ratio), data.referenceName, formatMeters(data.targetHeight))
		if data.mine then
			mineText.Text = string.format("YOU: %d POINTS  #%d  +%d SENSE", data.mine.score, data.mine.place, data.mine.sense)
			local score = data.mine.score
			sfx(score >= 90 and "perfect" or score >= 70 and "great" or score >= 40 and "close" or "bad")
		else
			mineText.Text = "You didn't guess this time."
		end
		for i = 1, 3 do
			local entry = data.top[i]
			podium[i].Text = entry and string.format("#%d  %s  -  %d", i, entry.name, entry.score) or ""
		end
		showModels(data)
		local mine = hideToken + 1
		hideToken = mine
		task.delay(9, function()
			if hideToken == mine then
				hide()
			end
		end)
	end
end)

-- Countdown, and send the slider position just before time runs out so a
-- guess counts even without pressing LOCK IN.
local sentFinal = false
RunService.Heartbeat:Connect(function()
	if not current or not gui.Enabled then
		sentFinal = false
		return
	end
	local left = current.endsAt - workspace:GetServerTimeNow()
	timerLabel.Text = tostring(math.max(0, math.ceil(left)))
	if left <= 0.4 and not sentFinal then
		sentFinal = true
		sendGuess()
		current.locked = true
		lockButton.Visible = false
	end
	if inGame() then
		hide()
		current = nil
	end
end)
