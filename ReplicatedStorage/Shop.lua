--[[
	Shop.lua
	ModuleScript: ReplicatedStorage.Shop

	Robux items sold in the SHOP window (ShopClient) and handled on the
	server (ShopManager). Create each one on the Creator Hub (your game >
	Monetization > Passes / Developer Products), then paste its ID here.
	While an ID is 0 the item shows as "coming soon" and can't be bought.
	The price shown in game is read from Roblox; `price` is only the
	fallback label.

	Owned passes are mirrored to player attributes ("Pass_double", ...) by
	the server so every script can check them.
]]

local Shop = {}

Shop.Passes = {
	{
		key = "double",
		id = 0, -- paste the 2x Sense game pass ID here
		name = "2x SENSE",
		blurb = "Earn double Sense from every round, daily, live round and playtime reward. Forever!",
		price = 199,
		icon = "bolt",
	},
	{
		key = "vip",
		id = 0, -- paste the VIP game pass ID here
		name = "VIP",
		blurb = "Gold VIP name tag, a VIP chat tag and double playtime rewards.",
		price = 149,
		icon = "crown",
	},
	{
		key = "pet",
		id = 0, -- paste the exclusive pet game pass ID here
		name = "DIAMOND FOX",
		blurb = "A shop-only pet with a crown and +15% Sense. Equip it from PETS.",
		price = 249,
		icon = "paw",
		pet = "diamondfox",
	},
}

Shop.Products = {
	{
		key = "saveStreak",
		id = 0, -- paste the "Save my streak" developer product ID here
		name = "SAVE MY STREAK",
		blurb = "Missed a day? Get your login streak back, as if you never left.",
		price = 25,
		icon = "fire",
	},
}

Shop.DOUBLE_SENSE = 2 -- multiplier from the 2x Sense pass
Shop.VIP_PLAYTIME = 2 -- playtime reward multiplier for VIPs

function Shop.attribute(key)
	return "Pass_" .. key
end

function Shop.getPass(key)
	for _, pass in ipairs(Shop.Passes) do
		if pass.key == key then
			return pass
		end
	end
	return nil
end

function Shop.getProduct(key)
	for _, product in ipairs(Shop.Products) do
		if product.key == key then
			return product
		end
	end
	return nil
end

-- Sense multiplier for what `player` earns by playing (2x pass).
function Shop.senseMultiplier(player)
	return player:GetAttribute(Shop.attribute("double")) == true and Shop.DOUBLE_SENSE or 1
end

return Shop
