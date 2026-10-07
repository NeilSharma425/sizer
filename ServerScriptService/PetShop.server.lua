--[[
	PetShop.server.lua
	Script: ServerScriptService.PetShop

	The egg shop. Players spend Sense on eggs (Pets.Eggs) that hatch a random
	egg pet. Spending never lowers rank or leaderboard Sense: the "Sense"
	attribute stays the lifetime total, and what's been spent is tracked
	separately (profile.wallet.spent, mirrored to the "SenseSpent"
	attribute). Spendable Sense = Sense - SenseSpent.

	A duplicate pet gives back part of the price (Pets.DUPLICATE_REFUND) to
	spend again (tracked as wallet.refunded, so rank Sense isn't inflated).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local Progress = require(ReplicatedStorage:WaitForChild("Progress"))

local okData, PlayerData = pcall(function()
	return require(ServerScriptService:WaitForChild("PlayerData", 30))
end)
if not okData or type(PlayerData) ~= "table" then
	warn("[Sizer] PetShop: PlayerData unavailable; egg shop disabled.")
	return
end

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes", 30)
if not remotes then
	warn("[Sizer] PetShop: remotes not found; egg shop disabled.")
	return
end

local HatchEgg = Instance.new("RemoteFunction")
HatchEgg.Name = "HatchEgg"
HatchEgg.Parent = remotes

local COOLDOWN = 1.2
local lastHatch = {} -- [player] = os.clock()
local rng = Random.new()

local function spendable(player)
	local profile = PlayerData.getProfile(player)
	return math.floor((player:GetAttribute("Sense") or 0) - Progress.netSpent(profile))
end

-- Returns { ok, error?, petId, name, rarity, new, refund, balance }.
HatchEgg.OnServerInvoke = function(player, eggId)
	local egg = type(eggId) == "string" and Pets.getEgg(eggId)
	if not egg then
		return { ok = false, error = "Unknown egg" }
	end
	local now = os.clock()
	if lastHatch[player] and now - lastHatch[player] < COOLDOWN then
		return { ok = false, error = "Slow down!" }
	end
	if spendable(player) < egg.price then
		return { ok = false, error = "Not enough Sense", balance = spendable(player) }
	end
	lastHatch[player] = now

	local profile = PlayerData.getProfile(player)
	profile.wallet.spent += egg.price

	local pet = Pets.rollEgg(egg, rng)
	local isNew = not profile.pets[pet.id]
	local refund = 0
	if isNew then
		profile.pets[pet.id] = true
		if profile.pet == "" then
			profile.pet = pet.id
			player:SetAttribute("Pet", pet.id)
		end
	else
		refund = math.floor(egg.price * Pets.DUPLICATE_REFUND)
		profile.wallet.refunded += refund
	end
	player:SetAttribute("SenseSpent", Progress.netSpent(profile))
	PlayerData.markDirty(player)
	task.spawn(PlayerData.save, player)

	return {
		ok = true,
		petId = pet.id,
		name = pet.name,
		rarity = pet.rarity,
		new = isNew,
		refund = refund,
		balance = spendable(player),
	}
end

Players.PlayerRemoving:Connect(function(player)
	lastHatch[player] = nil
end)
