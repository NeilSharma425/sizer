--[[
	PlayerData.lua
	ModuleScript: ServerScriptService.PlayerData

	Persists each player's Sense and best 60s-challenge score across
	sessions, and serves the lobby leaderboards.

	- load(player) sets the "Sense" and "TimedBest" attributes from the
	  DataStore (earnings made while loading are kept).
	- Saves use UpdateAsync with deltas, so two servers running at once
	  can't overwrite each other's progress. Players whose data failed to
	  load are never saved over, so a DataStore outage can't wipe progress.
	- Each save also updates two OrderedDataStores, which back the
	  leaderboards (getTop). Online players' live values are merged in, so
	  boards update instantly in-server and persist across servers.

	In Studio, DataStores need the place published and
	Game Settings > Security > "Enable Studio Access to API Services".
	Without that everything still works in memory for the session.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE_NAME = "SizerPlayerData_v1"
local BOARD_NAMES = {
	Sense = "SizerSenseBoard_v1",
	TimedBest = "SizerTimedBoard_v1",
}
local AUTOSAVE_SECONDS = 60
local BOARD_REFRESH_SECONDS = 45
local MAX_ATTEMPTS = 3
local BOARD_SIZE = 10

local PlayerData = {}

-- Creating a DataStore throws in an unpublished place (and when Studio
-- API access is off). That must never break the game, so fall back to a
-- memory-only mode where progress lasts for the session.
local store = nil
local orderedBoards = {}
do
	local ok, err = pcall(function()
		store = DataStoreService:GetDataStore(STORE_NAME)
		for kind, name in pairs(BOARD_NAMES) do
			orderedBoards[kind] = DataStoreService:GetOrderedDataStore(name)
		end
	end)
	if not ok then
		store = nil
		orderedBoards = {}
		warn("[Sizer] Saving is unavailable (" .. tostring(err) .. "). Publish the place and enable Studio API access to save progress. Running without saving.")
	end
end

local states = {} -- [player] = { loaded, saving, savedSense, savedTimed }
local topCache = { Sense = {}, TimedBest = {} } -- kind -> { {userId, name, value} }
local nameCache = {} -- [userId] = name
local warnedBoards = false

local function withRetry(fn)
	local lastError
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(attempt * 1.5)
		end
	end
	return false, lastError
end

local function loadInternal(player)
	local state = { loaded = false, saving = false, savedSense = 0, savedTimed = 0, savedTutorial = false }
	states[player] = state
	if not store then
		return false
	end

	local key = tostring(player.UserId)
	local ok, data = withRetry(function()
		return store:GetAsync(key)
	end)
	if not player.Parent then
		states[player] = nil
		return false
	end
	if not ok then
		warn("[Sizer] Could not load saved data for", player.Name, "- progress this session will not be saved:", data)
		return false
	end

	data = type(data) == "table" and data or {}
	local storedSense = math.max(0, math.floor(tonumber(data.sense) or 0))
	local storedTimed = math.max(0, math.floor(tonumber(data.timedBest) or 0))
	state.loaded = true
	state.savedSense = storedSense
	state.savedTimed = storedTimed
	state.savedTutorial = data.tutorialDone == true
	if state.savedTutorial then
		player:SetAttribute("TutorialDone", true)
	end

	-- Anything earned while loading is added on top of the saved totals.
	player:SetAttribute("Sense", storedSense + (player:GetAttribute("Sense") or 0))
	player:SetAttribute("TimedBest", math.max(storedTimed, player:GetAttribute("TimedBest") or 0))
	return true
end

-- Loads saved data. The "DataLoaded" attribute is set once the attempt is
-- over (success or not) so the client knows when saved flags such as
-- TutorialDone can be trusted.
function PlayerData.load(player)
	local ok = loadInternal(player)
	player:SetAttribute("DataLoaded", true)
	return ok
end

-- Remember that the player has seen (or skipped) the tutorial.
function PlayerData.markTutorialDone(player)
	player:SetAttribute("TutorialDone", true)
	task.spawn(PlayerData.save, player)
end

function PlayerData.save(player)
	local state = states[player]
	if not state or not state.loaded then
		return false
	end
	while state.saving do
		task.wait(0.1)
	end

	local sense = math.floor(player:GetAttribute("Sense") or 0)
	local timed = math.floor(player:GetAttribute("TimedBest") or 0)
	local tutorial = player:GetAttribute("TutorialDone") == true
	local deltaSense = sense - state.savedSense
	if deltaSense == 0 and timed <= state.savedTimed and (state.savedTutorial or not tutorial) then
		return true
	end

	state.saving = true
	local key = tostring(player.UserId)
	local ok, merged = withRetry(function()
		return store:UpdateAsync(key, function(old)
			old = type(old) == "table" and old or {}
			old.sense = math.max(0, (tonumber(old.sense) or 0) + deltaSense)
			old.timedBest = math.max(tonumber(old.timedBest) or 0, timed)
			if tutorial then
				old.tutorialDone = true
			end
			return old
		end)
	end)

	if ok and type(merged) == "table" then
		state.savedSense = sense
		state.savedTimed = math.max(state.savedTimed, timed)
		state.savedTutorial = state.savedTutorial or tutorial
		pcall(function()
			orderedBoards.Sense:SetAsync(key, math.floor(merged.sense or 0))
			if (merged.timedBest or 0) > 0 then
				orderedBoards.TimedBest:SetAsync(key, math.floor(merged.timedBest))
			end
		end)
	else
		warn("[Sizer] Could not save data for", player.Name, merged)
	end
	state.saving = false
	return ok
end

-- Save and forget a leaving player.
function PlayerData.release(player)
	PlayerData.save(player)
	states[player] = nil
end

--==========================================================================
-- Leaderboards
--==========================================================================

local function nameFor(userId)
	local online = Players:GetPlayerByUserId(userId)
	if online then
		return online.DisplayName
	end
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or "Player"
	return nameCache[userId]
end

local function refreshBoards()
	if not store then
		return
	end
	for kind, ordered in pairs(orderedBoards) do
		local ok, pages = pcall(function()
			return ordered:GetSortedAsync(false, BOARD_SIZE)
		end)
		if ok then
			local list = {}
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local userId = tonumber(entry.key)
				if userId and entry.value > 0 then
					table.insert(list, { userId = userId, name = nameFor(userId), value = entry.value })
				end
			end
			topCache[kind] = list
		elseif not warnedBoards then
			warnedBoards = true
			warn("[Sizer] Leaderboards can't read saved data (showing this server's players only):", pages)
		end
	end
end

-- Top entries for "Sense" or "TimedBest": the saved global list with
-- online players' live values merged in.
function PlayerData.getTop(kind, count)
	local byUser = {}
	for _, entry in ipairs(topCache[kind] or {}) do
		byUser[entry.userId] = { userId = entry.userId, name = entry.name, value = entry.value }
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local live = math.floor(player:GetAttribute(kind) or 0)
		if live > 0 then
			local existing = byUser[player.UserId]
			byUser[player.UserId] = {
				userId = player.UserId,
				name = player.DisplayName,
				value = existing and math.max(existing.value, live) or live,
			}
		end
	end
	local list = {}
	for _, entry in pairs(byUser) do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.userId < b.userId
	end)
	while #list > count do
		table.remove(list)
	end
	return list
end

--==========================================================================
-- Background jobs
--==========================================================================

task.spawn(function()
	while true do
		refreshBoards()
		task.wait(BOARD_REFRESH_SECONDS)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(PlayerData.save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			PlayerData.save(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

return PlayerData
