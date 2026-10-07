--[[
	Ranks.lua
	ModuleScript: ReplicatedStorage.Ranks

	Rank titles earned from lifetime Sense. Sense is never spent, so rank
	only goes up. Thresholds line up with the difficulty mix in Difficulty
	(harder questions as the rank climbs).
]]

local Ranks = {}

Ranks.List = {
	{ name = "Rookie", icon = "🌱", sense = 0, color = Color3.fromRGB(140, 205, 110) },
	{ name = "Eyeballer", icon = "👀", sense = 50, color = Color3.fromRGB(110, 200, 220) },
	{ name = "Guesser", icon = "🎯", sense = 150, color = Color3.fromRGB(90, 160, 255) },
	{ name = "Estimator", icon = "📏", sense = 350, color = Color3.fromRGB(130, 130, 255) },
	{ name = "Sizer", icon = "📐", sense = 700, color = Color3.fromRGB(180, 110, 255) },
	{ name = "Scale Pro", icon = "⚖️", sense = 1200, color = Color3.fromRGB(240, 120, 220) },
	{ name = "Size Sage", icon = "🧠", sense = 2000, color = Color3.fromRGB(255, 130, 120) },
	{ name = "Master", icon = "🏅", sense = 3500, color = Color3.fromRGB(255, 165, 60) },
	{ name = "Grandmaster", icon = "👑", sense = 6000, color = Color3.fromRGB(255, 205, 60) },
	{ name = "Legend", icon = "🌟", sense = 10000, color = Color3.fromRGB(255, 240, 130) },
}

-- Returns { index, rank, nextRank, progress (0-1 toward the next rank,
-- 1 at the top), toNext (Sense still needed, 0 at the top) }.
function Ranks.forSense(sense)
	sense = math.max(0, math.floor(sense or 0))
	local index = 1
	for i, rank in ipairs(Ranks.List) do
		if sense >= rank.sense then
			index = i
		end
	end
	local rank = Ranks.List[index]
	local nextRank = Ranks.List[index + 1]
	local progress, toNext = 1, 0
	if nextRank then
		progress = (sense - rank.sense) / (nextRank.sense - rank.sense)
		toNext = nextRank.sense - sense
	end
	return { index = index, rank = rank, nextRank = nextRank, progress = progress, toNext = toNext }
end

return Ranks
