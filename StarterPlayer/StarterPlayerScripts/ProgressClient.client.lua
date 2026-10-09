--[[
	ProgressClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ProgressClient

	Makes long-term progress visible:
	  - a rank card (top right) with a progress bar toward the next rank,
	    and a login-streak flame
	  - a "RANK UP!" banner when Sense crosses a rank threshold
	  - toasts for logins, weekly rewards, new pets, mastery stars and
	    completed categories

	Shares the daily-challenge status with ScaleGuesserClient through
	attributes on the PlayerGui "SizerBus" folder.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundFX = select(2, pcall(function()
	return require(ReplicatedStorage:WaitForChild("SoundFX", 10))
end))
local function sfx(name, opts)
	if type(SoundFX) == "table" then
		pcall(SoundFX.play, name, opts)
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes")
local ProgressEvent = remotes:WaitForChild("ProgressEvent")
local GetProgress = remotes:WaitForChild("GetProgress")
local RoundResult = remotes:WaitForChild("RoundResult")

local Ranks = require(ReplicatedStorage:WaitForChild("Ranks"))
local Progress = require(ReplicatedStorage:WaitForChild("Progress"))
local ScreenFit = require(ReplicatedStorage:WaitForChild("ScreenFit"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(25, 20, 35)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 50)
local PANEL = Color3.fromRGB(30, 32, 48)
local DARK_CARD = Color3.fromRGB(46, 50, 76)
local RED = Color3.fromRGB(240, 70, 70)

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
	padding.PaddingTop = UDim.new(0.16, 0)
	padding.PaddingBottom = UDim.new(0.16, 0)
	padding.Parent = b
	return b
end

local function bump(guiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = guiObject
	scale.Scale = 1.15
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function withCommas(n)
	local formatted = tostring(math.floor(n + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function formatMeters(m)
	local function trim(text)
		return (text:gsub("%.0$", ""))
	end
	if m >= 10000 then
		return withCommas(m / 1000) .. " km"
	elseif m >= 1000 then
		return trim(string.format("%.1f", m / 1000)) .. " km"
	elseif m >= 1 then
		return trim(string.format("%.1f", m)) .. " m"
	elseif m >= 0.01 then
		return trim(string.format("%.1f", m * 100)) .. " cm"
	end
	return trim(string.format("%.1f", m * 1000)) .. " mm"
end

local function colorHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

-- "★★☆" with filled stars in gold, as RichText.
local function starsText(count)
	return string.format(
		'<font color="%s">%s</font><font color="#4A4F70">%s</font>',
		colorHex(GOLD),
		string.rep("★", count),
		string.rep("★", 3 - count)
	)
end

--==========================================================================
-- Main overlay
--==========================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SizerProgress"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local bus = playerGui:WaitForChild("SizerBus", 20)

-- Roblox's default player list sits in the top-right corner, right where the
-- rank card goes, so hide it (SetCore can fail early in startup; retry).
task.spawn(function()
	local StarterGui = game:GetService("StarterGui")
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		if ok then
			break
		end
		task.wait(1)
	end
end)

-- Rank card -----------------------------------------------------------------

local rankCard = frame(gui, {
	Name = "RankCard",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.new(0, 290, 0, 76),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.1,
})
corner(rankCard, UDim.new(0, 16))
local rankStroke = stroke(rankCard, 3, GOLD)

local rankBadge = frame(rankCard, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 56, 0, 56),
	BackgroundColor3 = GOLD,
})
corner(rankBadge, UDim.new(1, 0))
stroke(rankBadge, 3)
gloss(rankBadge, GOLD)
local rankIcon = Icons.image(rankBadge, "sprout", {
	Size = UDim2.fromScale(0.86, 0.86),
	Position = UDim2.fromScale(0.07, 0.07),
})

local rankName = label(rankCard, {
	Position = UDim2.new(0, 76, 0, 6),
	Size = UDim2.new(1, -86, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "ROOKIE",
})
textStroke(rankName, 2.5)

local barBack = frame(rankCard, {
	Position = UDim2.new(0, 76, 0, 38),
	Size = UDim2.new(1, -90, 0, 14),
	BackgroundColor3 = Color3.fromRGB(20, 22, 40),
})
corner(barBack, UDim.new(1, 0))
stroke(barBack, 2)
local barFill = frame(barBack, {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = GOLD,
})
corner(barFill, UDim.new(1, 0))
gloss(barFill, GOLD)

local senseText = label(rankCard, {
	Position = UDim2.new(0, 76, 0, 54),
	Size = UDim2.new(1, -90, 0, 16),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(200, 205, 230),
	Font = Enum.Font.GothamBold,
	Text = "0 / 50 SENSE",
})

-- Streak row -------------------------------------------------------

local row = frame(gui, {
	Name = "ProgressRow",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 14, 1, -22),
	Size = UDim2.new(0, 112, 0, 40),
	BackgroundTransparency = 1,
})

-- Tapping the streak opens the streak rewards window (StreakClient).
local streakPill = Instance.new("TextButton")
streakPill.Name = "StreakPill"
streakPill.Text = ""
streakPill.AutoButtonColor = true
streakPill.BorderSizePixel = 0
streakPill.Size = UDim2.new(0, 112, 1, 0)
streakPill.BackgroundColor3 = PANEL
streakPill.BackgroundTransparency = 0.1
streakPill.Visible = false -- not shown on the main UI; the streak window opens from DAILY and on login
streakPill.Parent = row
corner(streakPill, UDim.new(1, 0))
stroke(streakPill, 3, Color3.fromRGB(255, 140, 40))
local streakText = label(streakPill, {
	Size = UDim2.new(1, -16, 0.7, 0),
	Position = UDim2.new(0, 8, 0.15, 0),
	Text = "🔥 0",
})
textStroke(streakText, 2)

-- Responsive scaling (about the top-right corner).
local cardScale = Instance.new("UIScale")
cardScale.Parent = rankCard
local rowScale = Instance.new("UIScale")
rowScale.Parent = row
local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		-- Phones: about 13% of the screen's height. Computers: 0.9x-1.15x its
		-- original size.
		local opts = { fx = 0.36, fy = 0.13, min = 0.45, max = 1.4 }
		if not ScreenFit.isCompact(camera.ViewportSize) then
			opts = { fx = 0.3, fy = 0.1, min = 0.9, max = 1.15 }
		end
		local value = ScreenFit.scaleFor(camera.ViewportSize, 290, 76, opts)
		cardScale.Scale = value
		rowScale.Scale = value
	end
end
-- Re-fit whenever the screen size is known or changes (at startup the
-- camera can still report a tiny viewport).
local function hookCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
hookCamera()

--==========================================================================
-- Rank card updates and the rank-up banner
--==========================================================================

local toast -- forward declaration (defined below)

local function updateRankCard(sense, animate)
	local info = Ranks.forSense(sense)
	local rank = info.rank
	rankName.Text = string.upper(rank.name)
	rankName.TextColor3 = rank.color
	Icons.set(rankIcon, rank.icon)
	rankBadge.BackgroundColor3 = rank.color
	rankStroke.Color = rank.color
	barFill.BackgroundColor3 = rank.color
	if info.nextRank then
		senseText.Text = string.format("%s / %s SENSE", withCommas(sense), withCommas(info.nextRank.sense))
	else
		senseText.Text = string.format("%s SENSE  -  MAX RANK", withCommas(sense))
	end
	local fill = UDim2.fromScale(info.progress, 1)
	if animate then
		TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = fill }):Play()
	else
		barFill.Size = fill
	end
	return info
end

local function celebrate(center)
	local pieces = { "party", "star", "sparkles", "glowing_star", "confetti" }
	local rng = Random.new()
	for i = 1, 24 do
		local side = rng:NextInteger(34, 58)
		local piece = Icons.image(gui, pieces[(i % #pieces) + 1], {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = center,
			Size = UDim2.fromOffset(side, side),
			ZIndex = 30,
		})
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.12, 0.4)
		local target = UDim2.fromScale(
			center.X.Scale + math.cos(angle) * distance * 0.9,
			center.Y.Scale + math.sin(angle) * distance + rng:NextNumber(0.04, 0.16)
		)
		local goal = Icons.fade(piece, 1)
		goal.Position = target
		goal.Rotation = rng:NextInteger(-200, 200)
		TweenService:Create(piece, TweenInfo.new(rng:NextNumber(1.1, 1.8), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
		task.delay(2, function()
			piece:Destroy()
		end)
	end
end

local rankBanner = frame(gui, {
	Name = "RankUpBanner",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.32),
	Size = UDim2.new(0, 500, 0, 150),
	BackgroundColor3 = PANEL,
	Visible = false,
	ZIndex = 20,
})
corner(rankBanner, UDim.new(0, 22))
local bannerStroke = stroke(rankBanner, 5, GOLD)
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = rankBanner
local bannerIcon = Icons.image(rankBanner, "sprout", {
	Position = UDim2.new(0, 14, 0.5, -52),
	Size = UDim2.new(0, 104, 0, 104),
	ZIndex = 21,
})
local bannerTitle = label(rankBanner, {
	Position = UDim2.new(0, 126, 0, 16),
	Size = UDim2.new(1, -140, 0, 44),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "RANK UP!",
	TextColor3 = GOLD,
	ZIndex = 21,
})
textStroke(bannerTitle, 4)
local bannerName = label(rankBanner, {
	Position = UDim2.new(0, 126, 0, 66),
	Size = UDim2.new(1, -140, 0, 52),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "ESTIMATOR",
	ZIndex = 21,
})
textStroke(bannerName, 3)
local bannerToken = 0

local function showRankUp(info)
	sfx("rankUp")
	bannerToken += 1
	local myToken = bannerToken
	Icons.set(bannerIcon, info.rank.icon)
	bannerName.Text = string.upper(info.rank.name)
	bannerName.TextColor3 = info.rank.color
	bannerStroke.Color = info.rank.color
	rankBanner.Visible = true
	bannerScale.Scale = 0
	local camera = workspace.CurrentCamera
	local fitted = camera and ScreenFit.scaleFor(camera.ViewportSize, 500, 150, { fx = 0.8, fy = 0.3 }) or 1
	TweenService:Create(bannerScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = fitted }):Play()
	celebrate(UDim2.fromScale(0.5, 0.32))
	task.delay(3.2, function()
		if bannerToken == myToken then
			local out = TweenService:Create(bannerScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
			out:Play()
			out.Completed:Connect(function()
				if bannerToken == myToken then
					rankBanner.Visible = false
				end
			end)
		end
	end)
end

--==========================================================================
-- Toasts
--==========================================================================

local toastHolder = frame(gui, {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.12, 12),
	Size = UDim2.new(0, 460, 0, 300),
	BackgroundTransparency = 1,
})
-- Toasts stay a slim strip on small screens.
ScreenFit.fit(toastHolder, 460, 46, { fx = 0.6, fy = 0.08, max = 1 })
local toastLayout = Instance.new("UIListLayout")
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Parent = toastHolder
local toastCount = 0
local MAX_TOASTS = 4

-- icon: an Icons key shown at the left end of the pill (optional).
function toast(text, color, seconds, icon)
	sfx("toast")
	toastCount += 1
	local order = toastCount
	local existing = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(existing, child)
		end
	end
	while #existing >= MAX_TOASTS do
		table.remove(existing, 1):Destroy()
	end

	local pill = frame(toastHolder, {
		Name = "Toast",
		LayoutOrder = order,
		Size = UDim2.new(0, 440, 0, 46),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 1,
	})
	corner(pill, UDim.new(1, 0))
	local pillStroke = stroke(pill, 3, color or GOLD)
	pillStroke.Transparency = 1
	local inset = icon and 58 or 14
	local message = label(pill, {
		Size = UDim2.new(1, -inset - 14, 0.68, 0),
		Position = UDim2.new(0, inset, 0.16, 0),
		Text = text,
		TextTransparency = 1,
	})
	textStroke(message, 2)
	local iconImage = icon and Icons.image(pill, icon, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(52, 52),
		Rotation = -8,
	})
	if iconImage then
		for k, v in pairs(Icons.fade(iconImage, 1)) do
			iconImage[k] = v
		end
		TweenService:Create(iconImage, TweenInfo.new(0.25), Icons.fade(iconImage, 0)):Play()
	end

	TweenService:Create(pill, TweenInfo.new(0.25), { BackgroundTransparency = 0.08 }):Play()
	TweenService:Create(pillStroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
	TweenService:Create(message, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	bump(pill)

	task.delay(seconds or 3.4, function()
		if pill.Parent then
			local fade = TweenInfo.new(0.3)
			TweenService:Create(pill, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(pillStroke, fade, { Transparency = 1 }):Play()
			if iconImage then
				TweenService:Create(iconImage, fade, Icons.fade(iconImage, 1)):Play()
			end
			local out = TweenService:Create(message, fade, { TextTransparency = 1 })
			out:Play()
			out.Completed:Connect(function()
				pill:Destroy()
			end)
		end
	end)
end

--==========================================================================
-- Progress snapshot (streak, daily)
--==========================================================================

local snapshot = nil
local refreshing = false
local refreshAgain = false

local function applySnapshot()
	if not snapshot then
		return
	end
	streakText.Text = "🔥 " .. snapshot.streak.count
	if bus then
		bus:SetAttribute("DailyDone", snapshot.daily.done)
		bus:SetAttribute("DailyAnswered", snapshot.daily.answered)
		bus:SetAttribute("DailyTotal", snapshot.daily.total)
		bus:SetAttribute("DailyResetIn", snapshot.daily.secondsLeft)
		bus:SetAttribute("DailyStatusAt", os.clock())
	end
end

local function refresh()
	if refreshing then
		refreshAgain = true
		return
	end
	refreshing = true
	repeat
		refreshAgain = false
		local ok, result = pcall(function()
			return GetProgress:InvokeServer()
		end)
		if ok and type(result) == "table" then
			snapshot = result
			applySnapshot()
		else
			warn("[Sizer] Could not load progress:", result)
		end
	until not refreshAgain
	refreshing = false
end

--==========================================================================
-- Events from the server and the game screen
--==========================================================================

ProgressEvent.OnClientEvent:Connect(function(kind, payload)
	if kind == "login" then
		-- Day 1 (a first login, or a streak that just restarted) gets no
		-- streak toast; from day 2 on it's worth celebrating.
		if (payload.count or 0) >= 2 then
			toast(string.format("DAY %d STREAK  +%d SENSE", payload.count, payload.reward), Color3.fromRGB(255, 140, 40), 4, "fire")
			if payload.pet then
				sfx("pet")
				toast("NEW PET UNLOCKED!", Color3.fromRGB(255, 120, 200), 5, "paw")
			end
		end
		task.defer(refresh)
	elseif kind == "weekly" then
		toast(string.format("LAST WEEK'S #%d  +%d SENSE", payload.place, payload.reward), GOLD, 5, "trophy")
	elseif kind == "pet" then
		sfx("pet")
		toast("NEW PET: " .. string.upper(payload.name or "PET"), Color3.fromRGB(255, 120, 200), 5, "paw")
	elseif kind == "dailyDone" then
		toast("TODAY'S DAILY IS ALREADY DONE", Color3.fromRGB(70, 150, 255), 3, "calendar")
	end
end)

RoundResult.OnClientEvent:Connect(function(result)
	local dex = result.dex
	if dex then
		for _, up in ipairs(dex.starUps or {}) do
			toast(string.format("%s %s  +%d SENSE", string.rep("★", up.to), string.upper(up.name), up.reward), GOLD, nil, "star")
		end
		for _, category in ipairs(dex.categories or {}) do
			toast(string.format("%s COMPLETE  +%d SENSE", string.upper(category), Progress.CATEGORY_SENSE), Color3.fromRGB(255, 225, 120), 4.5, "trophy")
		end
	end
	-- Pick up the new daily status.
	task.delay(0.4, refresh)
end)

--==========================================================================
-- Startup
--==========================================================================

local lastRank = nil
local started = false

local function onSenseChanged()
	local sense = player:GetAttribute("Sense") or 0
	local info = updateRankCard(sense, started)
	if started and lastRank and info.index > lastRank then
		showRankUp(info)
	end
	lastRank = info.index
end
player:GetAttributeChangedSignal("Sense"):Connect(onSenseChanged)
onSenseChanged()

-- The streak row is only shown out in the lobby.
task.spawn(function()
	local hud = playerGui:WaitForChild("SizerHUD", 30)
	local gamePanel = hud and hud:WaitForChild("GamePanel", 10)
	if not gamePanel then
		return
	end
	local function sync()
		row.Visible = not gamePanel.Visible
	end
	gamePanel:GetPropertyChangedSignal("Visible"):Connect(sync)
	sync()
end)

if bus then
	bus:GetAttributeChangedSignal("RefreshRequest"):Connect(function()
		task.delay(0.3, refresh)
	end)
end

task.spawn(function()
	-- Wait for saved data so the first rank/streak shown is the real one.
	local waited = 0
	while not player:GetAttribute("DataLoaded") and waited < 10 do
		task.wait(0.25)
		waited += 0.25
	end
	refresh()
	-- Saved Sense just arrived; that jump is not a rank-up.
	lastRank = Ranks.forSense(player:GetAttribute("Sense") or 0).index
	started = true
	onSenseChanged()
end)

-- When the daily resets (midnight UTC), fetch the new status.
task.spawn(function()
	while true do
		task.wait(5)
		if bus and bus:GetAttribute("DailyDone") then
			local left = (bus:GetAttribute("DailyResetIn") or 0) - (os.clock() - (bus:GetAttribute("DailyStatusAt") or os.clock()))
			if left <= 0 then
				refresh()
			end
		end
	end
end)
