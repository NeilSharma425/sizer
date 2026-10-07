--[[
	Difficulty.lua
	ModuleScript: ReplicatedStorage.Difficulty

	Sorts rounds into Easy / Medium / Hard and decides how often a player
	sees each, based on their Sense.

	A round's difficulty comes from how far apart the two objects are in
	size (the log of their ratio): objects within ~2.5x of each other are
	easy to compare, while huge gaps (a mouse next to a whale) are the
	hardest to judge accurately.
]]

local Difficulty = {}

Difficulty.Levels = { "Easy", "Medium", "Hard" }

-- Upper bounds on |ln(targetHeight / referenceHeight)|.
local EASY_MAX = 0.9 -- about 2.5x
local MEDIUM_MAX = 1.9 -- about 6.7x

function Difficulty.classify(referenceHeight, targetHeight)
	local gap = math.abs(math.log(targetHeight / referenceHeight))
	if gap < EASY_MAX then
		return "Easy"
	elseif gap < MEDIUM_MAX then
		return "Medium"
	end
	return "Hard"
end

-- { sense, easy, medium, hard } anchor points; weights are blended
-- linearly between neighbours and held flat past the last one.
local MIX = {
	{ 0, 0.85, 0.15, 0.00 },
	{ 100, 0.65, 0.33, 0.02 },
	{ 300, 0.45, 0.43, 0.12 },
	{ 750, 0.28, 0.45, 0.27 },
	{ 1500, 0.15, 0.40, 0.45 },
	{ 3000, 0.07, 0.33, 0.60 },
}

function Difficulty.weightsForSense(sense)
	sense = math.max(0, sense or 0)
	local last = MIX[#MIX]
	if sense >= last[1] then
		return { Easy = last[2], Medium = last[3], Hard = last[4] }
	end
	for i = 2, #MIX do
		local lo, hi = MIX[i - 1], MIX[i]
		if sense < hi[1] then
			local t = (sense - lo[1]) / (hi[1] - lo[1])
			return {
				Easy = lo[2] + (hi[2] - lo[2]) * t,
				Medium = lo[3] + (hi[3] - lo[3]) * t,
				Hard = lo[4] + (hi[4] - lo[4]) * t,
			}
		end
	end
	return { Easy = last[2], Medium = last[3], Hard = last[4] }
end

-- A level needs about this many unseen rounds to get its full share; with
-- fewer it shows up proportionally less so a tiny pool doesn't repeat.
local FULL_POOL = 6

-- Pick a level at random for this Sense. `counts[level]` is how many
-- rounds of that level are available. `roll` is a number in [0, 1)
-- (math.random() by default) so tests can be deterministic.
function Difficulty.choose(counts, sense, roll)
	local weights = Difficulty.weightsForSense(sense)
	local effective = {}
	local total = 0
	for _, level in ipairs(Difficulty.Levels) do
		local count = counts[level] or 0
		local w = count > 0 and weights[level] * math.min(1, count / FULL_POOL) or 0
		effective[level] = w
		total += w
	end
	if total <= 0 then
		-- Only levels with no weight remain (e.g. just Hard for a new
		-- player); better to show those than nothing.
		for _, level in ipairs(Difficulty.Levels) do
			if (counts[level] or 0) > 0 then
				return level
			end
		end
		return nil
	end
	local target = (roll or math.random()) * total
	local running = 0
	local pick = nil
	for _, level in ipairs(Difficulty.Levels) do
		if effective[level] > 0 then
			running += effective[level]
			pick = level
			if target < running then
				return level
			end
		end
	end
	return pick
end

return Difficulty
