--[[
	CrateLogic.lua
	ModuleScript: ReplicatedStorage.CrateLogic

	The claim rules for a pet crate, kept separate from the world/physics
	code in CrateManager so they can be tested on their own.

	A crate has `copies` copies of one pet. claim() is called for every
	player who touches it and answers what should happen.
]]

local CrateLogic = {}
CrateLogic.__index = CrateLogic

function CrateLogic.new(copies)
	return setmetatable({ left = copies, claimed = {}, told = {} }, CrateLogic)
end

-- Returns one of:
--   "granted"  this player takes a copy (left goes down by one)
--   "owned"    they already own the pet (first time only; "ignored" after)
--   "ignored"  nothing happens (already claimed, already told, or empty)
function CrateLogic:claim(userId, alreadyOwns)
	if self.left <= 0 or self.claimed[userId] then
		return "ignored"
	end
	if alreadyOwns then
		if self.told[userId] then
			return "ignored"
		end
		self.told[userId] = true
		return "owned"
	end
	self.claimed[userId] = true
	self.left -= 1
	return "granted"
end

function CrateLogic:isEmpty()
	return self.left <= 0
end

return CrateLogic
