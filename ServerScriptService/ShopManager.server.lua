--[[
	ShopManager.server.lua
	Script: ServerScriptService.ShopManager

	Robux purchases (items listed in ReplicatedStorage.Shop):
	  - game passes: ownership is checked when a player joins and after a
	    purchase, and mirrored to "Pass_<key>" attributes. The pet pass
	    also unlocks its pet.
	  - developer products (ProcessReceipt): "Save my streak" restores the
	    login streak lost today. Each receipt is recorded in the player's
	    saved data before it is granted, so it is never applied twice.
	What the passes do lives where the Sense is paid out (RoundManager,
	LiveRoundManager): 2x Sense, VIP playtime and name tag.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shop = require(ReplicatedStorage:WaitForChild("Shop"))
local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local Progress = require(ReplicatedStorage:WaitForChild("Progress"))

local okData, PlayerData = pcall(function()
	return require(ServerScriptService:WaitForChild("PlayerData", 30))
end)
if not okData or type(PlayerData) ~= "table" then
	warn("[Sizer] ShopManager: PlayerData unavailable; shop disabled.")
	return
end

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes", 30)
local ProgressEvent = remotes and remotes:WaitForChild("ProgressEvent", 30)

local function notify(player, kind, payload)
	if ProgressEvent then
		ProgressEvent:FireClient(player, kind, payload)
	end
end

-- Marks a pass as owned and applies anything it unlocks.
local function grantPass(player, pass, announce)
	player:SetAttribute(Shop.attribute(pass.key), true)
	if pass.pet then
		local profile = PlayerData.getProfile(player)
		if not profile.pets[pass.pet] then
			profile.pets[pass.pet] = true
			PlayerData.markDirty(player)
			if announce then
				local pet = Pets.get(pass.pet)
				notify(player, "pet", { id = pass.pet, name = pet and pet.name or pass.name })
			end
		end
	end
end

local function checkPasses(player)
	for _, pass in ipairs(Shop.Passes) do
		if pass.id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owns and player.Parent then
				grantPass(player, pass, false)
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Wait for saved data so a pass pet lands in the loaded profile.
	local waited = 0
	while player.Parent and not player:GetAttribute("DataLoaded") and waited < 30 do
		task.wait(0.5)
		waited += 0.5
	end
	if player.Parent then
		checkPasses(player)
	end
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkPasses, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	for _, pass in ipairs(Shop.Passes) do
		if pass.id ~= 0 and pass.id == passId then
			grantPass(player, pass, true)
			task.spawn(PlayerData.save, player)
		end
	end
end)

--==========================================================================
-- Developer products
--==========================================================================

local SAVE_STREAK_FALLBACK = 100 -- Sense given if the streak can't be saved any more

local handlers = {
	saveStreak = function(player, profile)
		local today = Progress.dayOf(os.time())
		local count = Progress.saveStreak(profile, today)
		player:SetAttribute("StreakSavable", 0)
		if count then
			notify(player, "streakSaved", { count = count })
		else
			-- Bought too late (e.g. after midnight): never leave a purchase empty-handed.
			player:SetAttribute("Sense", (player:GetAttribute("Sense") or 0) + SAVE_STREAK_FALLBACK)
			notify(player, "streakSaved", { count = profile.streak.count, sense = SAVE_STREAK_FALLBACK })
		end
	end,
}

local function productFor(id)
	for _, product in ipairs(Shop.Products) do
		if product.id ~= 0 and product.id == id then
			return product
		end
	end
	return nil
end

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productFor(receipt.ProductId)
	if not player or not product or not handlers[product.key] then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PlayerData.available() and not player:GetAttribute("DataLoaded") then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = PlayerData.getProfile(player)
	local flag = "receipt_" .. tostring(receipt.PurchaseId)
	if not profile.flags[flag] then
		handlers[product.key](player, profile)
		profile.flags[flag] = true
		PlayerData.markDirty(player)
	end
	-- Only confirm once it's saved (Roblox retries otherwise). Without
	-- DataStores (unpublished place) there is nothing to save to.
	if PlayerData.available() and not PlayerData.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
