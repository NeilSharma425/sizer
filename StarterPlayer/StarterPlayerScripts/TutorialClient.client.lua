--[[
	TutorialClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.TutorialClient

	A short "show, don't tell" tutorial. New players get a prompt on join.
	If they accept, there are no instructions to read:

	  1. a glowing trail, arrow and key cap lead to a station podium
	  2. round 1: a ghost hand demonstrates the slider, a pulse points at
	     LOCK IN
	  3. round 2: just the LOCK IN pulse
	  4. the game screen closes and a quick spotlight tour points out the
	     reasons to come back (DAILY, 60s challenge, pets, rank)

	It reads the game's UI by name (SizerHUD > GamePanel, SliderTrack,
	LockInButton, ResultText, SideMenu) and only ever asks the game to leave
	the game screen (SizerBus.RequestExit). When done or skipped, it tells
	the server (TutorialDone) so it isn't offered again; the HELP tile in the
	side menu replays it any time.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialDoneRemote = ReplicatedStorage:WaitForChild("ScaleGameRemotes"):WaitForChild("TutorialDone")
local ScreenFit = require(ReplicatedStorage:WaitForChild("ScreenFit"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local GREEN = Color3.fromRGB(80, 210, 70)
local GRAY = Color3.fromRGB(95, 100, 130)
local PURPLE = Color3.fromRGB(40, 45, 75)

--==========================================================================
-- UI helpers
--==========================================================================

local function corner(target, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 14)
	c.Parent = target
end

local function stroke(target, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or INK
	s.Parent = target
	return s
end

local function textStroke(target, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2.5
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = target
end

local function gloss(target, color)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.12))
	g.Rotation = 90
	g.Parent = target
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

--==========================================================================
-- Overlay
--==========================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SizerTutorial"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- The HELP tile (built into the side menu by the main HUD script) replays
-- the tutorial any time.
local replayButton
do
	local hud = playerGui:WaitForChild("SizerHUD", 30)
	local menu = hud and hud:WaitForChild("SideMenu", 10)
	replayButton = menu and menu:WaitForChild("HelpButton", 10)
	if not replayButton then
		replayButton = Instance.new("TextButton") -- detached stand-in
	end
end

-- Skip pill and progress dots (shown only during the tutorial).
local skipButton = button(gui, "SKIP", GRAY, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 110, 0, 36),
	Visible = false,
})

local dotsRow = frame(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 56),
	Size = UDim2.new(0, 120, 0, 14),
	BackgroundTransparency = 1,
	Visible = false,
})
local dots = {}
for i = 1, 4 do
	local dot = frame(dotsRow, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((i - 0.5) / 4, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = Color3.fromRGB(70, 75, 100),
	})
	corner(dot, UDim.new(1, 0))
	stroke(dot, 2)
	dots[i] = dot
end

local function setProgress(stage)
	for i, dot in ipairs(dots) do
		TweenService:Create(dot, TweenInfo.new(0.25), {
			BackgroundColor3 = i <= stage and GOLD or Color3.fromRGB(70, 75, 100),
		}):Play()
	end
end

--==========================================================================
-- State & helpers
--==========================================================================

local running = false
local token = 0 -- bumped to cancel a running tutorial
local cleanups = {} -- functions run when the tutorial ends

local function addCleanup(fn)
	table.insert(cleanups, fn)
end

local function runCleanups()
	for i = #cleanups, 1, -1 do
		pcall(cleanups[i])
	end
	cleanups = {}
end

local function findHud()
	local hud = playerGui:FindFirstChild("SizerHUD")
	local panel = hud and hud:FindFirstChild("GamePanel")
	if not panel then
		return nil
	end
	return {
		panel = panel,
		sliderTrack = panel:FindFirstChild("SliderTrack"),
		lockIn = panel:FindFirstChild("LockInButton"),
		result = panel:FindFirstChild("ResultText"),
		question = panel:FindFirstChild("QuestionText"),
	}
end

-- Polls `condition` until it is true, the tutorial is cancelled, or the
-- timeout passes. Returns true if the condition was met.
local function waitUntil(myToken, condition, timeout)
	local started = os.clock()
	while token == myToken do
		if condition() then
			return true
		end
		if timeout and os.clock() - started > timeout then
			return false
		end
		task.wait(0.15)
	end
	return false
end

-- Follows `fn(dt, t)` every frame until cleaned up.
local function everyFrame(fn)
	local started = os.clock()
	local connection = RunService.RenderStepped:Connect(function(dt)
		fn(dt, os.clock() - started)
	end)
	addCleanup(function()
		connection:Disconnect()
	end)
	return connection
end

--==========================================================================
-- Stage 1: lead the player to a station (trail, arrow, key cap)
--==========================================================================

local function pickStation()
	local stations = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Stations")
	if not stations then
		return nil
	end
	local fallback = nil
	for _, station in ipairs(stations:GetChildren()) do
		if station:GetAttribute("DisplayName") == "ANIMALS" then
			return station
		end
		if not fallback and station:GetAttribute("Mode") ~= "timed" then
			fallback = station
		end
	end
	return fallback
end

local function startGuide(station)
	local podium = station and station:FindFirstChild("Podium")
	if not podium then
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	folder.Parent = workspace
	addCleanup(function()
		folder:Destroy()
	end)

	local function guidePart(props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = GOLD
		for key, value in pairs(props) do
			p[key] = value
		end
		p.Parent = folder
		return p
	end

	-- Pulsing ring on the ground around the podium.
	local ring = guidePart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 11, 11),
		CFrame = CFrame.new(podium.Position.X, 0.45, podium.Position.Z) * CFrame.Angles(0, 0, math.pi / 2),
	})

	-- Bobbing arrow plus an "E" key cap above the podium.
	local anchor = guidePart({
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		Position = podium.Position + Vector3.new(0, 7, 0),
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 190)
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	local keyCap = frame(billboard, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, 80, 0, 80),
		BackgroundColor3 = WHITE,
	})
	corner(keyCap, UDim.new(0, 16))
	stroke(keyCap, 5)
	local keyLabel = label(keyCap, {
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.15, 0.1),
		Text = "E",
		TextColor3 = INK,
	})
	local keyScale = Instance.new("UIScale")
	keyScale.Parent = keyCap
	keyLabel.ZIndex = 2

	local arrow = Icons.image(billboard, "arrow_down", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.new(0, 90, 0, 90),
	})

	-- Dotted trail from the player to the podium.
	local trail = {}
	for i = 1, 40 do
		trail[i] = guidePart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(0, -50, 0),
		})
	end

	local base = anchor.Position
	everyFrame(function(_, t)
		-- Pulse and bob.
		ring.Transparency = 0.45 + 0.3 * math.sin(t * 4)
		anchor.Position = base + Vector3.new(0, math.sin(t * 3) * 0.7, 0)
		keyScale.Scale = 1 + 0.08 * math.sin(t * 5)
		arrow.Position = UDim2.new(0.5, 0, 0, 90 + math.sin(t * 3) * 6)

		-- Lay the dots along the line from the player to the podium.
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local from = root and Vector3.new(root.Position.X, 0, root.Position.Z)
		local to = Vector3.new(podium.Position.X, 0, podium.Position.Z - 6)
		if from then
			local offset = to - from
			local distance = offset.Magnitude
			local dir = distance > 0.01 and offset.Unit or Vector3.new(0, 0, 1)
			for i, dot in ipairs(trail) do
				local along = 5 + (i - 1) * 4.5
				if along < distance - 3 then
					local size = 0.8 + 0.45 * math.sin(t * 6 - i * 0.6)
					dot.Size = Vector3.new(size, size, size)
					dot.Position = Vector3.new(from.X + dir.X * along, 0.9, from.Z + dir.Z * along)
				else
					dot.Position = Vector3.new(0, -50, 0)
				end
			end
		end
	end)
	return podium
end

--==========================================================================
-- Stage 2: ghost hand demonstrates dragging the slider
--==========================================================================

local function showSliderDemo(ui)
	local hint = frame(gui, { -- glow around the slider
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(100, 30),
		ZIndex = 20,
	})
	corner(hint, UDim.new(1, 0))
	local hintStroke = stroke(hint, 4, GOLD)

	local ghost = frame(gui, { -- ghost of the draggable handle
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.25,
		ZIndex = 21,
	})
	corner(ghost, UDim.new(1, 0))
	stroke(ghost, 3, GOLD)

	local hand = Icons.image(gui, "point_up", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(64, 64),
		ZIndex = 22,
	})

	addCleanup(function()
		hint:Destroy()
		ghost:Destroy()
		hand:Destroy()
	end)

	local CYCLE = 3.2
	everyFrame(function(_, t)
		local track = ui.sliderTrack
		if not track or not track.Parent then
			return
		end
		local pos, size = track.AbsolutePosition, track.AbsoluteSize
		hint.Position = UDim2.fromOffset(pos.X - 6, pos.Y - 6)
		hint.Size = UDim2.fromOffset(size.X + 12, size.Y + 12)
		hintStroke.Transparency = 0.2 + 0.4 * (0.5 + 0.5 * math.sin(t * 5))

		local phase = (t % CYCLE) / CYCLE
		local from, to = 0.18, 0.78
		local alpha, shown, pressed
		if phase < 0.12 then -- appear and press
			alpha, shown, pressed = from, phase / 0.12, phase > 0.06
		elseif phase < 0.65 then -- drag
			local p = (phase - 0.12) / 0.53
			p = p * p * (3 - 2 * p)
			alpha, shown, pressed = from + (to - from) * p, 1, true
		elseif phase < 0.8 then -- hold, release
			alpha, shown, pressed = to, 1, false
		else -- fade out
			alpha, shown, pressed = to, 1 - (phase - 0.8) / 0.2, false
		end

		local x = pos.X + size.X * alpha
		local y = pos.Y + size.Y / 2
		ghost.Position = UDim2.fromOffset(x, y)
		ghost.BackgroundTransparency = 1 - 0.75 * shown
		hand.Position = UDim2.fromOffset(x, y + (pressed and 6 or 14))
		for k, v in pairs(Icons.fade(hand, 1 - shown)) do
			hand[k] = v
		end
		hand.Size = pressed and UDim2.fromOffset(58, 58) or UDim2.fromOffset(66, 66)
	end)
end

--==========================================================================
-- Stage 3: pulse points at LOCK IN
--==========================================================================

local function showLockHint(ui)
	local ring = frame(gui, {
		BackgroundTransparency = 1,
		ZIndex = 20,
	})
	corner(ring, UDim.new(0, 18))
	local ringStroke = stroke(ring, 5, GOLD)

	local hand = Icons.image(gui, "point_down", {
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(64, 64),
		ZIndex = 22,
	})
	addCleanup(function()
		ring:Destroy()
		hand:Destroy()
	end)

	everyFrame(function(_, t)
		local button = ui.lockIn
		if not button or not button.Parent then
			return
		end
		local pos, size = button.AbsolutePosition, button.AbsoluteSize
		local grow = 6 + 4 * (0.5 + 0.5 * math.sin(t * 6))
		ring.Position = UDim2.fromOffset(pos.X - grow, pos.Y - grow)
		ring.Size = UDim2.fromOffset(size.X + grow * 2, size.Y + grow * 2)
		ringStroke.Transparency = 0.1 + 0.5 * (0.5 + 0.5 * math.sin(t * 6))
		hand.Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y - 6 - 8 * (0.5 + 0.5 * math.sin(t * 6)))
	end)
end

--==========================================================================
-- Stage 4: celebration
--==========================================================================

local function celebrate()
	local pieces = { "party", "star", "sparkles", "glowing_star", "confetti" }
	local rng = Random.new()
	for i = 1, 26 do
		local side = rng:NextInteger(36, 64)
		local piece = Icons.image(gui, pieces[(i % #pieces) + 1], {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(side, side),
			ZIndex = 30,
		})
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.18, 0.45)
		local target = UDim2.fromScale(
			0.5 + math.cos(angle) * distance * 0.9,
			0.45 + math.sin(angle) * distance + rng:NextNumber(0.05, 0.2)
		)
		local info = TweenInfo.new(rng:NextNumber(1.1, 1.8), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = Icons.fade(piece, 1)
		goal.Position = target
		goal.Rotation = rng:NextInteger(-200, 200)
		TweenService:Create(piece, info, goal):Play()
		task.delay(2, function()
			piece:Destroy()
		end)
	end
end

--==========================================================================
-- The tutorial flow
--==========================================================================

--==========================================================================
-- While the tutorial runs, the lobby buttons are covered by invisible
-- click-catchers so they can't be used (and break the flow).
--==========================================================================

local SINK_TARGETS = {
	{ "SizerHUD", "SideMenu", "DailyButton" },
	{ "SizerHUD", "SideMenu", "ChallengeButton" },
	{ "SizerHUD", "SideMenu", "PetsButton" },
	{ "SizerHUD", "SideMenu", "HelpButton" },
	{ "SizerHUD", "QuickPlayButton" },
	{ "SizerProgress", "ProgressRow", "StreakPill" },
}

local sinkFolder = nil
local sinkConnection = nil

local function isShown(inst)
	while inst and not inst:IsA("ScreenGui") do
		if inst:IsA("GuiObject") and not inst.Visible then
			return false
		end
		inst = inst.Parent
	end
	return true
end

local function lookup(path)
	local current = playerGui
	for _, name in ipairs(path) do
		current = current and current:FindFirstChild(name)
	end
	return current
end

local function stopSinks()
	if sinkConnection then
		sinkConnection:Disconnect()
		sinkConnection = nil
	end
	if sinkFolder then
		sinkFolder:Destroy()
		sinkFolder = nil
	end
end

local function startSinks()
	stopSinks()
	sinkFolder = frame(gui, { Name = "Sinks", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
	local sinks = {}
	for i = 1, #SINK_TARGETS do
		local sink = Instance.new("TextButton")
		sink.Name = "Sink"
		sink.Text = ""
		sink.AutoButtonColor = false
		sink.BackgroundTransparency = 1
		sink.BorderSizePixel = 0
		sink.ZIndex = 50
		sink.Visible = false
		sink.Parent = sinkFolder
		sinks[i] = sink
	end
	sinkConnection = RunService.RenderStepped:Connect(function()
		for i, path in ipairs(SINK_TARGETS) do
			local target = lookup(path)
			local sink = sinks[i]
			if target and isShown(target) then
				sink.Visible = true
				sink.Position = UDim2.fromOffset(target.AbsolutePosition.X, target.AbsolutePosition.Y)
				sink.Size = UDim2.fromOffset(target.AbsoluteSize.X, target.AbsoluteSize.Y)
			else
				sink.Visible = false
			end
		end
	end)
end

local function hideChrome()
	skipButton.Visible = false
	dotsRow.Visible = false
end

local function finish(myToken, completed)
	if token ~= myToken then
		return
	end
	token += 1
	running = false
	runCleanups()
	stopSinks()
	hideChrome()
	if completed then
		TutorialDoneRemote:FireServer()
	end
end

--==========================================================================
-- Feature tour: spotlight on each reason to come back
--==========================================================================

local function findProgressGui()
	local g = playerGui:FindFirstChild("SizerProgress")
	return g and g:FindFirstChild("RankCard")
end

local function findMenuTile(name)
	local hud = playerGui:FindFirstChild("SizerHUD")
	local menu = hud and hud:FindFirstChild("SideMenu")
	return menu and menu:FindFirstChild(name)
end

local TOUR = {
	{ find = function() return findMenuTile("DailyButton") end, text = "5 new questions every day", color = Color3.fromRGB(70, 150, 255) },
	{ find = function() return findMenuTile("ChallengeButton") end, text = "60 seconds. Beat the clock!", color = GOLD },
	{ find = function() return findMenuTile("PetsButton") end, text = "Unlock cool pets", color = Color3.fromRGB(255, 120, 190) },
	{ find = findProgressGui, text = "Earn Sense, rank up, keep your streak", color = Color3.fromRGB(255, 140, 40) },
}
local TOUR_STEP_SECONDS = 2.1

local function runTour(myToken)
	local dim = Color3.new(0, 0, 0)
	local blockers = {}
	for i = 1, 4 do
		blockers[i] = frame(gui, { BackgroundColor3 = dim, BackgroundTransparency = 0.45, ZIndex = 10 })
	end
	local ring = frame(gui, { BackgroundTransparency = 1, ZIndex = 12 })
	corner(ring, UDim.new(0, 18))
	local ringStroke = stroke(ring, 5, GOLD)

	local card = frame(gui, { Size = UDim2.new(0, 270, 0, 78), BackgroundColor3 = PURPLE, ZIndex = 14 })
	ScreenFit.fit(card, 270, 78, { fx = 0.45, fy = 0.2 })
	corner(card, UDim.new(0, 16))
	local cardStroke = stroke(card, 4, GOLD)
	local cardText = label(card, {
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -28, 1, -16),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 15,
	})
	textStroke(cardText, 2)
	addCleanup(function()
		for _, b in ipairs(blockers) do
			b:Destroy()
		end
		ring:Destroy()
		card:Destroy()
	end)

	local current = nil
	everyFrame(function(_, t)
		local target = current
		if not target or not target.Parent then
			return
		end
		local screen = gui.AbsoluteSize
		local pad = 8
		local x, y = target.AbsolutePosition.X - pad, target.AbsolutePosition.Y - pad
		local w, h = target.AbsoluteSize.X + pad * 2, target.AbsoluteSize.Y + pad * 2
		-- The top shade reaches up over Roblox's top bar so no strip is left bright.
		blockers[1].Position, blockers[1].Size = UDim2.fromOffset(0, -80), UDim2.fromOffset(screen.X, math.max(0, y) + 80)
		blockers[2].Position, blockers[2].Size = UDim2.fromOffset(0, y + h), UDim2.fromOffset(screen.X, math.max(0, screen.Y - y - h))
		blockers[3].Position, blockers[3].Size = UDim2.fromOffset(0, y), UDim2.fromOffset(math.max(0, x), h)
		blockers[4].Position, blockers[4].Size = UDim2.fromOffset(x + w, y), UDim2.fromOffset(math.max(0, screen.X - x - w), h)
		local grow = 3 + 3 * (0.5 + 0.5 * math.sin(t * 6))
		ring.Position = UDim2.fromOffset(x - grow, y - grow)
		ring.Size = UDim2.fromOffset(w + grow * 2, h + grow * 2)
		ringStroke.Transparency = 0.1 + 0.4 * (0.5 + 0.5 * math.sin(t * 6))

		-- Caption beside the target, on whichever side has room (below it
		-- when the menu runs along the top, as on phones).
		local cy = y + h / 2
		local layout = target.Parent and target.Parent:FindFirstChildOfClass("UIListLayout")
		if layout and layout.FillDirection == Enum.FillDirection.Horizontal then
			card.AnchorPoint = Vector2.new(0, 0)
			card.Position = UDim2.fromOffset(math.max(8, x), y + h + 16)
		elseif x + w / 2 < screen.X / 2 then
			card.AnchorPoint = Vector2.new(0, 0.5)
			card.Position = UDim2.fromOffset(x + w + 16, cy)
		else
			card.AnchorPoint = Vector2.new(1, 0.5)
			card.Position = UDim2.fromOffset(x - 16, cy)
		end
	end)

	for i, step in ipairs(TOUR) do
		local target = step.find()
		if target and target.Visible and target.AbsoluteSize.X > 0 then
			current = target
			cardText.Text = step.text
			cardStroke.Color = step.color
			ringStroke.Color = step.color
			card.Visible = true
			if not waitUntil(myToken, function() return false end, TOUR_STEP_SECONDS) and token ~= myToken then
				return false
			end
		end
	end
	return token == myToken
end

local bus = playerGui:WaitForChild("SizerBus", 20)

local function questionLoaded(ui)
	return ui.question == nil or ui.question.Text ~= "Loading round..."
end

-- Returns "done" on completion, "restart" if the player left the game
-- screen during round 1, or "cancel" if the tutorial was cancelled.
local function runOnce(myToken)
	local ui = findHud()
	if not ui or not ui.sliderTrack or not ui.lockIn or not ui.result then
		warn("[Sizer] Tutorial could not find the game UI")
		return "cancel"
	end

	-- 1: lead the player to a station.
	setProgress(1)
	local station = pickStation()
	startGuide(station)
	if not waitUntil(myToken, function()
		return ui.panel.Visible
	end) then
		return "cancel"
	end
	runCleanups()

	-- 2: round 1. Ghost hand shows the slider drag, until the player tries it.
	setProgress(2)
	waitUntil(myToken, function()
		return questionLoaded(ui)
	end, 8)
	showSliderDemo(ui)
	local touched = false
	local function onInput(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			touched = true
		end
	end
	local c1 = ui.sliderTrack.InputBegan:Connect(onInput)
	local c2 = ui.sliderTrack:FindFirstChild("SliderHandle") and ui.sliderTrack.SliderHandle.InputBegan:Connect(onInput)
	addCleanup(function()
		c1:Disconnect()
		if c2 then
			c2:Disconnect()
		end
	end)
	local reached = waitUntil(myToken, function()
		return touched or not ui.panel.Visible
	end)
	if not reached then
		return "cancel"
	end
	runCleanups()
	if not ui.panel.Visible then
		return "restart"
	end

	-- Pulse on LOCK IN until the player presses it.
	showLockHint(ui)
	local locked = false
	local c3 = ui.lockIn.MouseButton1Click:Connect(function()
		locked = true
	end)
	addCleanup(function()
		c3:Disconnect()
	end)
	reached = waitUntil(myToken, function()
		return locked or not ui.panel.Visible
	end)
	if not reached then
		return "cancel"
	end
	runCleanups()
	if not ui.panel.Visible then
		return "restart"
	end

	-- The result plays out with a little celebration.
	waitUntil(myToken, function()
		return ui.result.Text ~= ""
	end, 10)
	if token ~= myToken then
		return "cancel"
	end
	celebrate()

	-- 3: round 2. Only the LOCK IN pulse; the player already knows the slider.
	setProgress(3)
	waitUntil(myToken, function()
		return not ui.panel.Visible or (ui.result.Text == "" and questionLoaded(ui))
	end, 8)
	if token ~= myToken then
		return "cancel"
	end
	if ui.panel.Visible then
		showLockHint(ui)
		locked = false
		local c4 = ui.lockIn.MouseButton1Click:Connect(function()
			locked = true
		end)
		addCleanup(function()
			c4:Disconnect()
		end)
		reached = waitUntil(myToken, function()
			return locked or not ui.panel.Visible
		end)
		if not reached then
			return "cancel"
		end
		runCleanups()
		if ui.panel.Visible then
			waitUntil(myToken, function()
				return ui.result.Text ~= "" or not ui.panel.Visible
			end, 10)
			task.wait(1.8)
		end
	end
	if token ~= myToken then
		return "cancel"
	end

	-- 4: back to the lobby for the feature tour.
	setProgress(4)
	if ui.panel.Visible and bus then
		bus:SetAttribute("RequestExit", os.clock())
		waitUntil(myToken, function()
			return not ui.panel.Visible
		end, 4)
		task.wait(0.4)
	end
	if token ~= myToken then
		return "cancel"
	end
	if not runTour(myToken) then
		return "cancel"
	end
	runCleanups()
	celebrate()
	task.wait(1.2)
	return token == myToken and "done" or "cancel"
end

local function startTutorial()
	if running then
		return
	end
	running = true
	token += 1
	local myToken = token
	skipButton.Visible = true
	dotsRow.Visible = true
	startSinks()

	task.spawn(function()
		local outcome = "restart"
		while outcome == "restart" and token == myToken do
			outcome = runOnce(myToken)
			if outcome == "restart" then
				runCleanups()
			end
		end
		finish(myToken, outcome == "done")
	end)
end

skipButton.MouseButton1Click:Connect(function()
	-- Skipping counts as done so the prompt isn't shown again.
	finish(token, true)
end)

replayButton.MouseButton1Click:Connect(startTutorial)

--==========================================================================
-- Welcome prompt on join
--==========================================================================

local function showPrompt()
	local card = frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 440, 0, 300),
		BackgroundColor3 = PURPLE,
		ZIndex = 40,
	})
	corner(card, UDim.new(0, 24))
	stroke(card, 5, GOLD)
	gloss(card, PURPLE)

	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = card

	local icon = Icons.image(card, "grad_cap", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.new(0, 104, 0, 104),
		ZIndex = 41,
	})
	local title = label(card, {
		Position = UDim2.new(0, 20, 0, 120),
		Size = UDim2.new(1, -40, 0, 60),
		Text = "NEW HERE?",
		ZIndex = 41,
	})
	textStroke(title, 4)

	local showMe = button(card, "SHOW ME", GREEN, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(0.5, -8, 1, -24),
		Size = UDim2.new(0, 190, 0, 62),
		ZIndex = 41,
	})
	local skip = button(card, "SKIP", GRAY, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, 8, 1, -24),
		Size = UDim2.new(0, 150, 0, 62),
		ZIndex = 41,
	})

	local camera = workspace.CurrentCamera
	local fitted = camera and ScreenFit.scaleFor(camera.ViewportSize, 440, 300, { fx = 0.7, fy = 0.7 }) or 1
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = fitted }):Play()
	local bob = RunService.RenderStepped:Connect(function()
		icon.Position = UDim2.new(0.5, 0, 0, 18 + math.sin(os.clock() * 3) * 5)
	end)

	local function close(afterClose)
		bob:Disconnect()
		local out = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		out:Play()
		out.Completed:Connect(function()
			card:Destroy()
			afterClose()
		end)
	end

	showMe.MouseButton1Click:Connect(function()
		close(startTutorial)
	end)
	skip.MouseButton1Click:Connect(function()
		close(function()
			TutorialDoneRemote:FireServer()
		end)
	end)
end

task.spawn(function()
	-- Wait for the game UI, the player's character, and their saved data
	-- (so a returning player who finished the tutorial is not asked again).
	local hud = playerGui:WaitForChild("SizerHUD", 30)
	if not hud then
		return
	end
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	local waited = 0
	while not player:GetAttribute("DataLoaded") and waited < 10 do
		task.wait(0.25)
		waited += 0.25
	end
	task.wait(1.5)
	if player:GetAttribute("TutorialDone") then
		return
	end
	showPrompt()
end)
