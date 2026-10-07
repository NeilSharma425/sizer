--[[
	RoundManager.server.lua
	Script: ServerScriptService.RoundManager

	Owns round selection, scoring, and the Sense tag over each player
	(saved across sessions by PlayerData). The client never receives
	targetHeight until after it submits a guess, preventing trivial cheating
	via network inspection (client-side scale is still trusted for now --
	no anti-cheat needed per current scope).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ScaleData = require(ReplicatedStorage:WaitForChild("ScaleData"))
-- Saving is optional: if the module ever fails to load, run without it
-- instead of taking the whole game down.
local okPlayerData, PlayerData = pcall(function()
	return require(script.Parent:WaitForChild("PlayerData"))
end)
if not okPlayerData then
	warn("[Sizer] PlayerData failed to load; running without saving:", PlayerData)
	PlayerData = {
		load = function()
			return false
		end,
		release = function() end,
		save = function()
			return false
		end,
		getTop = function()
			return {}
		end,
	}
end

-- How many previous rounds (per player) to avoid repeating.
local HISTORY_LENGTH = 4

-- Log-scale scoring constant: score = clamp(100 - logError * SCORE_SCALE, 0, 100)
local SCORE_SCALE = 140

local PLAYTIME_REWARD_INTERVAL = 120
local PLAYTIME_REWARD_SENSE = 25

-- 60-second challenge. Guesses submitted up to this long after the buzzer
-- still count, to absorb network latency.
local TIMED_DURATION = 60
local TIMED_GRACE = 1

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "ScaleGameRemotes"
remotesFolder.Parent = ReplicatedStorage

local RequestRound = Instance.new("RemoteEvent")
RequestRound.Name = "RequestRound"
RequestRound.Parent = remotesFolder

local SubmitGuess = Instance.new("RemoteEvent")
SubmitGuess.Name = "SubmitGuess"
SubmitGuess.Parent = remotesFolder

local RoundResult = Instance.new("RemoteEvent")
RoundResult.Name = "RoundResult"
RoundResult.Parent = remotesFolder

-- Client -> server to begin a challenge; server replies on the same event
-- with the server-clock end time.
local TimedStart = Instance.new("RemoteEvent")
TimedStart.Name = "TimedStart"
TimedStart.Parent = remotesFolder

local TimedStop = Instance.new("RemoteEvent")
TimedStop.Name = "TimedStop"
TimedStop.Parent = remotesFolder

local TimedEnd = Instance.new("RemoteEvent")
TimedEnd.Name = "TimedEnd"
TimedEnd.Parent = remotesFolder

-- Per-player state: recent round indices (for repeat avoidance) and the
-- currently active round (so SubmitGuess can look up the true height).
local playerHistory = {} -- [player] = { roundIndex, roundIndex, ... }
local playerCurrentRound = {} -- [player] = roundIndex
local timedSessions = {} -- [player] = { id, endsAt, score }
local nextTimedId = 0

-- Optional hook point for a future category filter: pass a categoryFilter
-- string (or nil for "any category") and only matching rounds are eligible.
local function pickRoundIndex(player, categoryFilter)
	local history = playerHistory[player] or {}
	local candidates = {}

	for index, round in ipairs(ScaleData.Rounds) do
		if categoryFilter == nil or round.category == categoryFilter then
			local recentlyUsed = false
			for _, historyIndex in ipairs(history) do
				if historyIndex == index then
					recentlyUsed = true
					break
				end
			end
			if not recentlyUsed then
				table.insert(candidates, index)
			end
		end
	end

	-- If every eligible round was recently used (small data set), fall back
	-- to the full eligible set rather than failing to produce a round.
	if #candidates == 0 then
		for index, round in ipairs(ScaleData.Rounds) do
			if categoryFilter == nil or round.category == categoryFilter then
				table.insert(candidates, index)
			end
		end
	end

	return candidates[math.random(1, #candidates)]
end

local function recordHistory(player, roundIndex)
	local history = playerHistory[player]
	if not history then
		history = {}
		playerHistory[player] = history
	end

	table.insert(history, roundIndex)
	while #history > HISTORY_LENGTH do
		table.remove(history, 1)
	end
end

local validCategories = {}
for _, round in ipairs(ScaleData.Rounds) do
	validCategories[round.category] = true
end

local function onRequestRound(player, categoryFilter)
	if type(categoryFilter) ~= "string" or not validCategories[categoryFilter] then
		categoryFilter = nil
	end
	local roundIndex = pickRoundIndex(player, categoryFilter)
	local round = ScaleData.Rounds[roundIndex]

	playerCurrentRound[player] = roundIndex
	recordHistory(player, roundIndex)

	RequestRound:FireClient(
		player,
		{
			referenceName = round.referenceName,
			referenceIcon = round.referenceIcon,
			referenceHeight = round.referenceHeight,
			targetName = round.targetName,
			targetIcon = round.targetIcon,
			category = round.category,
		}
	)
end

local function addSense(player, amount)
	player:SetAttribute("Sense", (player:GetAttribute("Sense") or 0) + amount)
end

local function onSubmitGuess(player, guessedTargetHeight)
	local roundIndex = playerCurrentRound[player]
	if not roundIndex then
		return
	end

	local round = ScaleData.Rounds[roundIndex]
	if type(guessedTargetHeight) ~= "number" or guessedTargetHeight <= 0 then
		return
	end

	local trueRatio = round.targetHeight / round.referenceHeight
	local guessedRatio = guessedTargetHeight / round.referenceHeight

	local logError = math.abs(math.log(guessedRatio) - math.log(trueRatio))
	local score = math.clamp(100 - logError * SCORE_SCALE, 0, 100)
	score = math.floor(score + 0.5)

	local senseEarned = math.floor(score / 10)

	addSense(player, senseEarned)

	local timed = timedSessions[player]
	local timedScore = nil
	if timed and workspace:GetServerTimeNow() <= timed.endsAt + TIMED_GRACE then
		timed.score += score
		timedScore = timed.score
	end

	RoundResult:FireClient(player, {
		trueTargetHeight = round.targetHeight,
		guessedTargetHeight = guessedTargetHeight,
		score = score,
		senseEarned = senseEarned,
		timedScore = timedScore,
		fact = round.fact,
		referenceName = round.referenceName,
		targetName = round.targetName,
	})

	playerCurrentRound[player] = nil
end

RequestRound.OnServerEvent:Connect(onRequestRound)
SubmitGuess.OnServerEvent:Connect(onSubmitGuess)

local function finishTimed(player, session)
	timedSessions[player] = nil
	local previousBest = player:GetAttribute("TimedBest") or 0
	local isNewBest = session.score > previousBest
	if isNewBest then
		player:SetAttribute("TimedBest", session.score)
	end
	TimedEnd:FireClient(player, {
		score = session.score,
		best = math.max(previousBest, session.score),
		isNewBest = isNewBest,
	})
end

TimedStart.OnServerEvent:Connect(function(player)
	nextTimedId += 1
	local session = { id = nextTimedId, endsAt = workspace:GetServerTimeNow() + TIMED_DURATION, score = 0 }
	timedSessions[player] = session
	TimedStart:FireClient(player, session.endsAt, TIMED_DURATION)
	task.delay(TIMED_DURATION + TIMED_GRACE, function()
		if timedSessions[player] == session then
			finishTimed(player, session)
		end
	end)
end)

-- Stopping early abandons the run without recording a best.
TimedStop.OnServerEvent:Connect(function(player)
	timedSessions[player] = nil
end)

-- Floating tag over the player's head showing their Sense.
local function attachSenseTag(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then
		return
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "SenseTag"
	tag.Adornee = head
	tag.Size = UDim2.new(0, 150, 0, 34)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 80
	tag.LightInfluence = 0
	tag.Parent = head

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
	pill.BackgroundTransparency = 0.15
	pill.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 195, 40)
	stroke.Thickness = 2.5
	stroke.Parent = pill

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Parent = pill
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = text

	local function refresh()
		text.Text = string.format("📏 %d SENSE", player:GetAttribute("Sense") or 0)
	end
	refresh()
	player:GetAttributeChangedSignal("Sense"):Connect(function()
		if tag.Parent then
			refresh()
		end
	end)
end

local function onPlayerAdded(player)
	-- Start at 0 so the tag shows immediately; the saved totals are added
	-- on top as soon as they load.
	player:SetAttribute("Sense", 0)
	task.spawn(PlayerData.load, player)

	player.CharacterAdded:Connect(function(character)
		attachSenseTag(player, character)
	end)
	if player.Character then
		task.spawn(attachSenseTag, player, player.Character)
	end

	-- Playtime reward; the client renders the countdown from NextRewardAt.
	task.spawn(function()
		while player.Parent do
			local nextAt = workspace:GetServerTimeNow() + PLAYTIME_REWARD_INTERVAL
			player:SetAttribute("NextRewardAt", nextAt)
			player:SetAttribute("RewardInterval", PLAYTIME_REWARD_INTERVAL)
			player:SetAttribute("RewardAmount", PLAYTIME_REWARD_SENSE)
			task.wait(PLAYTIME_REWARD_INTERVAL)
			if not player.Parent then
				break
			end
			addSense(player, PLAYTIME_REWARD_SENSE)
		end
	end)
end

local function onPlayerRemoving(player)
	playerHistory[player] = nil
	playerCurrentRound[player] = nil
	timedSessions[player] = nil
	task.spawn(PlayerData.release, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[Sizer] Round manager ready")
