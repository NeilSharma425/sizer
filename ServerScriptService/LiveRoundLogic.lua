--[[
	LiveRoundLogic.lua
	ModuleScript: ServerScriptService.LiveRoundLogic

	Rules for live lobby rounds, kept apart from the networking in
	LiveRoundManager so they can be tested on their own: scoring a guess,
	ranking everyone, and the Sense each place earns.
]]

local LiveRoundLogic = {}

LiveRoundLogic.SCORE_SCALE = 140 -- same curve as normal rounds
LiveRoundLogic.MIN_RATIO = 0.02
LiveRoundLogic.MAX_RATIO = 50
LiveRoundLogic.SENSE_PER_10 = 2 -- live rounds pay double: 2 Sense per 10 points
LiveRoundLogic.PODIUM_BONUS = { 50, 30, 15 }

function LiveRoundLogic.score(trueRatio, guessedRatio)
	local logError = math.abs(math.log(guessedRatio) - math.log(trueRatio))
	return math.floor(math.clamp(100 - logError * LiveRoundLogic.SCORE_SCALE, 0, 100) + 0.5)
end

function LiveRoundLogic.validGuess(ratio)
	return type(ratio) == "number" and ratio == ratio and ratio >= LiveRoundLogic.MIN_RATIO and ratio <= LiveRoundLogic.MAX_RATIO
end

-- guesses: { [userId] = { name, ratio, at } }. Returns a list sorted best
-- first (ties go to whoever locked in first): { userId, name, score, place }.
function LiveRoundLogic.rank(guesses, trueRatio)
	local list = {}
	for userId, g in pairs(guesses) do
		table.insert(list, { userId = userId, name = g.name, at = g.at, score = LiveRoundLogic.score(trueRatio, g.ratio) })
	end
	table.sort(list, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.at ~= b.at then
			return a.at < b.at
		end
		return a.userId < b.userId
	end)
	for i, entry in ipairs(list) do
		entry.place = i
	end
	return list
end

-- Sense for one result before pet perks: points plus a podium bonus (only
-- for a score above zero, so a wild guess can't win a medal).
function LiveRoundLogic.reward(score, place)
	local sense = math.floor(score / 10) * LiveRoundLogic.SENSE_PER_10
	if score > 0 and LiveRoundLogic.PODIUM_BONUS[place] then
		sense += LiveRoundLogic.PODIUM_BONUS[place]
	end
	return sense
end

return LiveRoundLogic
