--[[
	LiveRoundManager.server.lua
	Script: ServerScriptService.LiveRoundManager

	Live lobby rounds: every few minutes everyone in the lobby gets the same
	question at once (LiveRound "soon" -> "start"), has GUESS_SECONDS to
	set the slider, and then sees a shared reveal with a top-3 podium
	("results"). Points pay double and the podium earns bonus Sense, plus
	the equipped pet's perk.

	Players in a game session or the tutorial simply skip it (client side).
	In Studio the first round comes after ~45 seconds for testing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ScaleData = require(ReplicatedStorage:WaitForChild("ScaleData"))
local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local Logic = require(script.Parent:WaitForChild("LiveRoundLogic"))

local okData, PlayerData = pcall(function()
	return require(ServerScriptService:WaitForChild("PlayerData", 30))
end)
if not okData or type(PlayerData) ~= "table" then
	PlayerData = nil
end

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes", 30)
if not remotes then
	warn("[Sizer] LiveRoundManager: remotes not found; live rounds disabled.")
	return
end

local LiveRound = Instance.new("RemoteEvent")
LiveRound.Name = "LiveRound"
LiveRound.Parent = remotes

local WARNING_SECONDS = 5
local GUESS_SECONDS = 15
local GRACE = 0.6
local FIRST_ROUND = RunService:IsStudio() and { 45, 55 } or { 150, 240 }
local GAP = { 300, 480 }

local rng = Random.new()
local active = nil -- { id, endsAt, trueRatio, guesses }
local nextId = 0

-- Easy and Medium questions read best for a quick shared round.
local pool = {}
for _, round in ipairs(ScaleData.Rounds) do
	if round.difficulty ~= "Hard" then
		table.insert(pool, round)
	end
end
if #pool == 0 then
	pool = ScaleData.Rounds
end

LiveRound.OnServerEvent:Connect(function(player, kind, roundId, ratio)
	if kind ~= "guess" or not active or roundId ~= active.id then
		return
	end
	if workspace:GetServerTimeNow() > active.endsAt + GRACE or not Logic.validGuess(ratio) then
		return
	end
	-- Later guesses replace earlier ones; `at` keeps the latest lock-in time.
	active.guesses[player.UserId] = { name = player.DisplayName, ratio = ratio, at = workspace:GetServerTimeNow() }
end)

local function perkFor(player)
	if not PlayerData then
		return 0
	end
	local profile = PlayerData.getProfile(player)
	if profile.pet ~= "" and profile.pets[profile.pet] then
		return Pets.perkFor(profile.pet)
	end
	return 0
end

local function runRound()
	local round = pool[rng:NextInteger(1, #pool)]
	nextId += 1
	local id = nextId

	LiveRound:FireAllClients("soon", { id = id, seconds = WARNING_SECONDS })
	task.wait(WARNING_SECONDS)

	local endsAt = workspace:GetServerTimeNow() + GUESS_SECONDS
	active = { id = id, endsAt = endsAt, trueRatio = round.targetHeight / round.referenceHeight, guesses = {} }
	LiveRound:FireAllClients("start", {
		id = id,
		referenceName = round.referenceName,
		referenceIcon = round.referenceIcon,
		referenceHeight = round.referenceHeight,
		targetName = round.targetName,
		targetIcon = round.targetIcon,
		category = round.category,
		endsAt = endsAt,
	})
	task.wait(GUESS_SECONDS + GRACE)

	local finished = active
	active = nil
	local ranking = Logic.rank(finished.guesses, finished.trueRatio)
	local top = {}
	for i = 1, math.min(3, #ranking) do
		table.insert(top, { name = ranking[i].name, score = ranking[i].score })
	end

	local mine = {}
	for _, entry in ipairs(ranking) do
		local player = Players:GetPlayerByUserId(entry.userId)
		if player then
			local sense = Logic.reward(entry.score, entry.place)
			sense += math.floor(sense * perkFor(player) + 0.5)
			player:SetAttribute("Sense", (player:GetAttribute("Sense") or 0) + sense)
			mine[player] = { score = entry.score, place = entry.place, sense = sense }
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		LiveRound:FireClient(player, "results", {
			id = id,
			referenceName = round.referenceName,
			referenceIcon = round.referenceIcon,
			referenceHeight = round.referenceHeight,
			targetName = round.targetName,
			targetIcon = round.targetIcon,
			targetHeight = round.targetHeight,
			fact = round.fact,
			top = top,
			players = #ranking,
			mine = mine[player],
		})
	end
end

task.spawn(function()
	task.wait(rng:NextNumber(FIRST_ROUND[1], FIRST_ROUND[2]))
	while true do
		if #Players:GetPlayers() > 0 then
			local ok, err = pcall(runRound)
			if not ok then
				active = nil
				warn("[Sizer] Live round failed:", err)
			end
		end
		task.wait(rng:NextNumber(GAP[1], GAP[2]))
	end
end)
