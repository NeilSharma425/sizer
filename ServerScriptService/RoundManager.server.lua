--[[
	RoundManager.server.lua
	Script: ServerScriptService.RoundManager

	Owns round selection, scoring, and leaderstats. The client never receives
	targetHeight until after it submits a guess, preventing trivial cheating
	via network inspection (client-side scale is still trusted for now --
	no anti-cheat needed per current scope).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ScaleData = require(ReplicatedStorage:WaitForChild("ScaleData"))

-- How many previous rounds (per player) to avoid repeating.
local HISTORY_LENGTH = 4

-- Log-scale scoring constant: score = clamp(100 - logError * SCORE_SCALE, 0, 100)
local SCORE_SCALE = 140

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

-- Per-player state: recent round indices (for repeat avoidance) and the
-- currently active round (so SubmitGuess can look up the true height).
local playerHistory = {} -- [player] = { roundIndex, roundIndex, ... }
local playerCurrentRound = {} -- [player] = roundIndex

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

local function onRequestRound(player, categoryFilter)
	local roundIndex = pickRoundIndex(player, categoryFilter)
	local round = ScaleData.Rounds[roundIndex]

	playerCurrentRound[player] = roundIndex
	recordHistory(player, roundIndex)

	RequestRound:FireClient(
		player,
		{
			referenceName = round.referenceName,
			referenceHeight = round.referenceHeight,
			targetName = round.targetName,
			category = round.category,
		}
	)
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

	local leaderstats = player:FindFirstChild("leaderstats")
	local scoreValue = leaderstats and leaderstats:FindFirstChild("Score")
	if scoreValue then
		scoreValue.Value += score
	end

	RoundResult:FireClient(player, {
		trueTargetHeight = round.targetHeight,
		guessedTargetHeight = guessedTargetHeight,
		score = score,
		fact = round.fact,
		referenceName = round.referenceName,
		targetName = round.targetName,
	})

	playerCurrentRound[player] = nil
end

RequestRound.OnServerEvent:Connect(onRequestRound)
SubmitGuess.OnServerEvent:Connect(onSubmitGuess)

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = leaderstats
end

local function onPlayerRemoving(player)
	playerHistory[player] = nil
	playerCurrentRound[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
