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
local Difficulty = require(ReplicatedStorage:WaitForChild("Difficulty"))
local Progress = require(ReplicatedStorage:WaitForChild("Progress"))
local Ranks = require(ReplicatedStorage:WaitForChild("Ranks"))
local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
-- Saving is optional: if the module ever fails to load, run without it
-- instead of taking the whole game down.
local okPlayerData, PlayerData = pcall(function()
	return require(script.Parent:WaitForChild("PlayerData"))
end)
if not okPlayerData then
	warn("[Sizer] PlayerData failed to load; running without saving:", PlayerData)
	local profiles = {}
	PlayerData = {
		init = function(player)
			profiles[player] = profiles[player] or Progress.newProfile()
		end,
		getProfile = function(player)
			profiles[player] = profiles[player] or Progress.newProfile()
			return profiles[player]
		end,
		markDirty = function() end,
		available = function()
			return false
		end,
		getLastWeekPlace = function()
			return nil
		end,
		load = function(player)
			player:SetAttribute("DataLoaded", true)
			return false
		end,
		markTutorialDone = function(player)
			player:SetAttribute("TutorialDone", true)
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

-- Server -> client progression messages: ProgressEvent(kind, payload) for
-- login rewards, weekly rewards and "daily already done"; GetProgress
-- returns the player's Sizedex, streak, daily and weekly state.
local ProgressEvent = Instance.new("RemoteEvent")
ProgressEvent.Name = "ProgressEvent"
ProgressEvent.Parent = remotesFolder

local GetProgress = Instance.new("RemoteFunction")
GetProgress.Name = "GetProgress"
GetProgress.Parent = remotesFolder

-- Client -> server: a one-time hint was shown (only known names are kept).
local MarkHint = Instance.new("RemoteEvent")
MarkHint.Name = "MarkHint"
MarkHint.Parent = remotesFolder

-- Client -> server: equip one of the pets the player has unlocked.
local EquipPet = Instance.new("RemoteEvent")
EquipPet.Name = "EquipPet"
EquipPet.Parent = remotesFolder

-- Client -> server: the player finished or skipped the tutorial.
local TutorialDone = Instance.new("RemoteEvent")
TutorialDone.Name = "TutorialDone"
TutorialDone.Parent = remotesFolder
TutorialDone.OnServerEvent:Connect(function(player)
	PlayerData.markTutorialDone(player)
end)

-- Per-player state: recent round indices (for repeat avoidance) and the
-- currently active round (so SubmitGuess can look up the true height).
local playerHistory = {} -- [player] = { roundIndex, roundIndex, ... }
local playerCurrentRound = {} -- [player] = roundIndex
local timedSessions = {} -- [player] = { id, endsAt, score }
local nextTimedId = 0
local playerCurrentDaily = {} -- [player] = question number if the current round is a daily one
local dailySessions = {} -- [player] = { day, rounds }
local combos = {} -- [player] = consecutive good guesses
local progressReady = {} -- [player] = true once the client asked for its progress
local progressQueue = {} -- [player] = { {kind, payload}, ... } waiting for the client

local objectIndex = Progress.buildIndex(ScaleData.Rounds)

local function currentWeek()
	return Progress.weekOf(Progress.dayOf(os.time()))
end

-- Messages are held until the client has started (it asks for its progress
-- on startup); anything fired earlier would be lost.
local function sendProgress(player, kind, payload)
	if progressReady[player] then
		ProgressEvent:FireClient(player, kind, payload)
	else
		progressQueue[player] = progressQueue[player] or {}
		table.insert(progressQueue[player], { kind, payload })
	end
end

-- Unlocks any pets whose requirement (rank, Sizedex category, 60s score) is
-- now met. Only runs once the player's saved data is in.
local petsReady = {} -- [player] = true
local function checkPetUnlocks(player)
	if not petsReady[player] then
		return
	end
	local profile = PlayerData.getProfile(player)
	local state = {
		rank = Ranks.forSense(player:GetAttribute("Sense") or 0).index,
		cats = profile.cats,
		timedBest = player:GetAttribute("TimedBest") or 0,
	}
	for _, pet in ipairs(Pets.List) do
		if pet.rule.kind ~= "streak" and not profile.pets[pet.id] and Pets.qualifies(pet.rule, state) then
			profile.pets[pet.id] = true
			if profile.pet == "" then
				profile.pet = pet.id
				player:SetAttribute("Pet", pet.id)
			end
			PlayerData.markDirty(player)
			if pet.rule.kind ~= "start" then
				sendProgress(player, "pet", { id = pet.id, name = pet.name })
			end
		end
	end
end

-- Categories left out of "any category" rounds (MIXED, 60s challenge); they
-- are still playable from their own station.
local EXCLUDED_FROM_MIXED = { Brainrot = true }

local function isEligible(round, categoryFilter)
	if categoryFilter == nil then
		return not EXCLUDED_FROM_MIXED[round.category]
	end
	return round.category == categoryFilter
end

-- Picks a round for this player: first a difficulty, weighted by their
-- Sense (more Sense = harder mix), then a random unseen round of that
-- difficulty. Pass a categoryFilter string, or nil for "any category".
local function pickRoundIndex(player, categoryFilter)
	local history = playerHistory[player] or {}
	local recent = {}
	for _, historyIndex in ipairs(history) do
		recent[historyIndex] = true
	end

	local fresh = { Easy = {}, Medium = {}, Hard = {} }
	local eligible = {}
	for index, round in ipairs(ScaleData.Rounds) do
		if isEligible(round, categoryFilter) then
			table.insert(eligible, index)
			if not recent[index] then
				table.insert(fresh[round.difficulty], index)
			end
		end
	end

	local counts = {}
	for _, level in ipairs(Difficulty.Levels) do
		counts[level] = #fresh[level]
	end
	local level = Difficulty.choose(counts, player:GetAttribute("Sense") or 0)
	if level then
		return fresh[level][math.random(1, #fresh[level])]
	end

	-- Everything eligible was seen recently (tiny category): allow repeats.
	return eligible[math.random(1, #eligible)]
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

local DAILY_CATEGORY = "__daily"

local function roundPayload(round, daily)
	return {
		referenceName = round.referenceName,
		referenceIcon = round.referenceIcon,
		referenceHeight = round.referenceHeight,
		targetName = round.targetName,
		targetIcon = round.targetIcon,
		category = round.category,
		difficulty = round.difficulty,
		daily = daily,
	}
end

-- The shared daily challenge: the same questions for every player today,
-- one scored run per day. Progress is saved after each answer, so quitting
-- and returning resumes at the next question instead of allowing a retry.
local function serveDaily(player)
	local profile = PlayerData.getProfile(player)
	local today = Progress.dayOf(os.time())
	local state = Progress.dailyState(profile, today)
	if state.done then
		sendProgress(player, "dailyDone", { score = state.score })
		return
	end

	local session = dailySessions[player]
	if not session or session.day ~= today then
		session = {
			day = today,
			rounds = Progress.dailyRounds(today, ScaleData.Rounds, function(round)
				return isEligible(round, nil)
			end),
		}
		dailySessions[player] = session
	end

	local question = state.answered + 1
	local roundIndex = session.rounds[question]
	if not roundIndex then
		return
	end
	playerCurrentRound[player] = roundIndex
	playerCurrentDaily[player] = question
	RequestRound:FireClient(player, roundPayload(ScaleData.Rounds[roundIndex], {
		index = question,
		total = Progress.DAILY_COUNT,
		score = state.score,
	}))
end

local function onRequestRound(player, categoryFilter)
	if categoryFilter == DAILY_CATEGORY then
		serveDaily(player)
		return
	end
	if type(categoryFilter) ~= "string" or not validCategories[categoryFilter] then
		categoryFilter = nil
	end
	local roundIndex = pickRoundIndex(player, categoryFilter)
	local round = ScaleData.Rounds[roundIndex]

	playerCurrentRound[player] = roundIndex
	playerCurrentDaily[player] = nil
	recordHistory(player, roundIndex)

	RequestRound:FireClient(player, roundPayload(round, nil))
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

	local senseBase = math.floor(score / 10)
	-- Compounding login-streak bonus: +5% per streak day, up to +50%.
	local streakCount = PlayerData.getProfile(player).streak.count
	senseBase += math.floor(senseBase * Progress.streakBonus(streakCount) + 0.5)

	-- Combo: back-to-back good guesses earn bonus Sense.
	local combo, comboBonus = Progress.combo(combos[player] or 0, score)
	combos[player] = combo

	-- Sizedex: discoveries, mastery stars and category completions.
	local profile = PlayerData.getProfile(player)
	local dex = Progress.recordResult(profile, objectIndex, round.referenceName, round.targetName, score)

	local senseEarned = senseBase + comboBonus + dex.sense
	addSense(player, senseEarned)

	-- Daily challenge: tally this answer and pay out when all are done.
	local dailyInfo = nil
	local dailyQuestion = playerCurrentDaily[player]
	if dailyQuestion then
		local state = Progress.recordDaily(profile, Progress.dayOf(os.time()), score)
		dailyInfo = { index = dailyQuestion, total = Progress.DAILY_COUNT, score = state.score, done = state.done }
		if state.done then
			dailyInfo.reward = Progress.dailyReward(state.score)
			addSense(player, dailyInfo.reward)
		end
	end
	PlayerData.markDirty(player)
	checkPetUnlocks(player)

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
		senseBase = senseBase,
		comboBonus = comboBonus,
		combo = combo,
		dex = dex,
		daily = dailyInfo,
		timedScore = timedScore,
		fact = round.fact,
		referenceName = round.referenceName,
		targetName = round.targetName,
	})

	playerCurrentRound[player] = nil
	playerCurrentDaily[player] = nil
end

MarkHint.OnServerEvent:Connect(function(player, name)
	if name == "streak" then
		local profile = PlayerData.getProfile(player)
		if not profile.flags.streak then
			profile.flags.streak = true
			PlayerData.markDirty(player)
		end
		player:SetAttribute("StreakHintSeen", true)
	end
end)

EquipPet.OnServerEvent:Connect(function(player, id)
	local profile = PlayerData.getProfile(player)
	if type(id) == "string" and profile.pets[id] and profile.pet ~= id then
		profile.pet = id
		player:SetAttribute("Pet", id)
		PlayerData.markDirty(player)
	end
end)

RequestRound.OnServerEvent:Connect(onRequestRound)
SubmitGuess.OnServerEvent:Connect(onSubmitGuess)

local function finishTimed(player, session)
	timedSessions[player] = nil
	local previousBest = player:GetAttribute("TimedBest") or 0
	local isNewBest = session.score > previousBest
	if isNewBest then
		player:SetAttribute("TimedBest", session.score)
	end

	-- The records board is weekly.
	local profile = PlayerData.getProfile(player)
	local isWeekBest = Progress.recordWeekly(profile, currentWeek(), session.score)
	if isWeekBest then
		player:SetAttribute("TimedWeek", session.score)
	end
	PlayerData.markDirty(player)

	TimedEnd:FireClient(player, {
		score = session.score,
		best = math.max(previousBest, session.score),
		isNewBest = isNewBest,
		weekBest = Progress.weeklyBest(profile, currentWeek()),
		isWeekBest = isWeekBest,
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

-- Floating tag over the player's head: their rank and Sense.
local function attachSenseTag(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then
		return
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "SenseTag"
	tag.Adornee = head
	tag.Size = UDim2.new(0, 170, 0, 56)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	tag.MaxDistance = 80
	tag.LightInfluence = 0
	tag.Parent = head

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
	pill.BackgroundTransparency = 0.15
	pill.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 195, 40)
	stroke.Thickness = 2.5
	stroke.Parent = pill

	local function line(position, height, font)
		local text = Instance.new("TextLabel")
		text.Position = UDim2.fromScale(0.04, position)
		text.Size = UDim2.fromScale(0.92, height)
		text.BackgroundTransparency = 1
		text.Font = font
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.Parent = pill
		return text
	end
	local rankText = line(0.06, 0.42, Enum.Font.GothamBold)
	local senseText = line(0.5, 0.44, Enum.Font.GothamBlack)

	local function refresh()
		local sense = player:GetAttribute("Sense") or 0
		local info = Ranks.forSense(sense)
		rankText.Text = info.rank.icon .. " " .. string.upper(info.rank.name)
		rankText.TextColor3 = info.rank.color
		stroke.Color = info.rank.color
		senseText.Text = string.format("📏 %d SENSE", sense)
	end
	refresh()
	player:GetAttributeChangedSignal("Sense"):Connect(function()
		if tag.Parent then
			refresh()
		end
	end)
end

--==========================================================================
-- Progress snapshot, login streak and weekly rewards
--==========================================================================

local function buildSnapshot(player)
	local profile = PlayerData.getProfile(player)
	local now = os.time()
	local today = Progress.dayOf(now)
	local daily = Progress.dailyState(profile, today)
	return {
		dex = profile.dex,
		cats = profile.cats,
		streak = { count = profile.streak.count, best = profile.streak.best, lastDay = profile.streak.lastDay },
		pets = { owned = profile.pets, equipped = profile.pet },
		daily = {
			done = daily.done,
			answered = daily.answered,
			score = daily.score,
			total = Progress.DAILY_COUNT,
			secondsLeft = Progress.secondsUntilNextDay(now),
		},
		weekly = { best = Progress.weeklyBest(profile, currentWeek()), secondsLeft = Progress.secondsUntilNextWeek(now) },
		today = today,
		serverTime = now,
	}
end

-- The client asks for this once on startup (which also releases any
-- messages queued for it) and again whenever it opens the Sizedex.
GetProgress.OnServerInvoke = function(player)
	local snapshot = buildSnapshot(player)
	if not progressReady[player] then
		progressReady[player] = true
		task.delay(0.6, function()
			local queue = progressQueue[player]
			progressQueue[player] = nil
			for _, message in ipairs(queue or {}) do
				ProgressEvent:FireClient(player, message[1], message[2])
			end
		end)
	end
	return snapshot
end

-- Runs once the player's saved data is in: counts today's login for the
-- streak and pays out last week's records podium.
local function onDataLoaded(player)
	local profile = PlayerData.getProfile(player)
	local today = Progress.dayOf(os.time())
	local week = currentWeek()

	local streak = Progress.updateStreak(profile, today)
	if streak.isNew then
		addSense(player, streak.reward)
		PlayerData.markDirty(player)
		sendProgress(player, "login", streak)
	end
	player:SetAttribute("Pet", profile.pet ~= "" and profile.pet or nil)
	if profile.flags.streak then
		player:SetAttribute("StreakHintSeen", true)
	end
	petsReady[player] = true
	checkPetUnlocks(player)

	if profile.weekly.rewardWeek < week then
		local place = PlayerData.getLastWeekPlace(player)
		profile.weekly.rewardWeek = week
		PlayerData.markDirty(player)
		if place and Progress.WEEKLY_SENSE[place] then
			local reward = Progress.WEEKLY_SENSE[place]
			addSense(player, reward)
			sendProgress(player, "weekly", { place = place, reward = reward })
		end
	end
	player:SetAttribute("TimedWeek", Progress.weeklyBest(profile, week))
end

local function onPlayerAdded(player)
	-- Start at 0 so the tag shows immediately; the saved totals are added
	-- on top as soon as they load.
	player:SetAttribute("Sense", 0)
	PlayerData.init(player)
	player:GetAttributeChangedSignal("Sense"):Connect(function()
		checkPetUnlocks(player)
	end)
	player:GetAttributeChangedSignal("TimedBest"):Connect(function()
		checkPetUnlocks(player)
	end)
	task.spawn(function()
		local loaded = PlayerData.load(player)
		-- If saving exists but loading failed, don't hand out streak or
		-- weekly rewards against an empty profile that can't be saved.
		if loaded or not PlayerData.available() then
			onDataLoaded(player)
		end
	end)

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
	petsReady[player] = nil
	playerHistory[player] = nil
	playerCurrentRound[player] = nil
	playerCurrentDaily[player] = nil
	dailySessions[player] = nil
	combos[player] = nil
	progressReady[player] = nil
	progressQueue[player] = nil
	timedSessions[player] = nil
	task.spawn(PlayerData.release, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[Sizer] Round manager ready")
