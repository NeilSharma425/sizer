--[[
	RoundGenerator.lua
	ModuleScript: ReplicatedStorage.RoundGenerator

	Expands the hand-written rounds by pairing up objects that already
	appear in them: every pair of objects within the same category whose
	sizes differ by 1.25x to 50x can become a round (the slider covers
	0.02x-50x); each object joins at most MAX_PAIRS_PER_OBJECT of them.
	Mixed mode also gets cross-category rounds (category "Mixed") for
	objects within 20x of each other. Facts are written from the sizes, so they stay accurate.
	No new models are needed -- only objects that already have rounds are
	used -- and a pair that already exists in either order is skipped.
]]

local RoundGenerator = {}

local MIN_RATIO = 1.25
local MAX_RATIO = 50
-- Each object joins at most this many generated rounds, so a category with
-- lots of objects (Animals) doesn't swamp the mixed rounds. Objects that
-- would end up with fewer than MIN_PAIRS still get that many.
local MAX_PAIRS_PER_OBJECT = 40
local MIN_PAIRS = 4

-- Cross-category rounds (category "Mixed", only played in mixed mode): any
-- two objects from different categories, as long as one isn't hugely
-- bigger than the other (no cat vs. Earth). Brainrot sizes are made up, so
-- it stays out.
RoundGenerator.MIXED = "Mixed"
local MIXED_MAX_RATIO = 20
local MIXED_PAIRS_PER_OBJECT = 12
local MIXED_EXCLUDED = { Brainrot = true }

local function withCommas(n)
	local formatted = tostring(math.floor(n + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function trimZero(text)
	return (text:gsub("%.0$", ""))
end

local function formatMeters(m)
	if m >= 10000 then
		return withCommas(m / 1000) .. " km"
	elseif m >= 1000 then
		return trimZero(string.format("%.1f", m / 1000)) .. " km"
	elseif m >= 1 then
		return trimZero(string.format("%.1f", m)) .. " m"
	elseif m >= 0.01 then
		return trimZero(string.format("%.1f", m * 100)) .. " cm"
	end
	return trimZero(string.format("%.1f", m * 1000)) .. " mm"
end

local function formatTimes(ratio)
	if ratio >= 10 then
		return withCommas(ratio)
	end
	return trimZero(string.format("%.1f", ratio))
end

-- Stable hash of a pair, used for its orientation and its place in line.
local function pairHash(a, b)
	local sum = 0
	for _, text in ipairs({ a, b }) do
		for i = 1, #text do
			sum = (sum * 31 + string.byte(text, i)) % 1000003
		end
	end
	return sum
end

-- Stable 0/1 per pair so the same pair always gets the same orientation.
local function coin(a, b)
	return pairHash(a, b) % 2
end

local function writeFact(reference, target)
	local ratio = target.height / reference.height
	local head = string.format("%s is about %s", target.name, formatMeters(target.height))
	local fact
	if ratio >= 1 then
		fact = string.format(
			"%s -- roughly %s times the size of %s (%s).",
			head,
			formatTimes(ratio),
			reference.name,
			formatMeters(reference.height)
		)
	else
		fact = string.format(
			"%s -- only about %d%% the size of %s (%s).",
			head,
			math.floor(100 * ratio + 0.5),
			reference.name,
			formatMeters(reference.height)
		)
	end
	if target.fact then
		fact ..= " " .. target.fact
	end
	if reference.category == "Brainrot" then
		fact ..= " (Made-up meme sizes!)"
	end
	return fact
end

-- Appends generated rounds to `rounds` (in place) and returns how many
-- were added. `extras` is an optional list of { name, icon, height,
-- category, fact } objects to include in the pairing.
function RoundGenerator.expand(rounds, extras)
	local objects = {} -- [category] = { {name, icon, height, category}, ... }
	local seenObject = {}
	local existing = {} -- [referenceName .. "|" .. targetName] = true

	local function note(name, icon, height, category, fact)
		local key = category .. "|" .. name
		if seenObject[key] then
			return
		end
		seenObject[key] = true
		objects[category] = objects[category] or {}
		table.insert(objects[category], { name = name, icon = icon, height = height, category = category, fact = fact })
	end

	-- Extra objects (ExtraObjects) join the pool even without a hand-written round.
	for _, object in ipairs(extras or {}) do
		note(object.name, object.icon, object.height, object.category, object.fact)
	end

	for _, round in ipairs(rounds) do
		note(round.referenceName, round.referenceIcon, round.referenceHeight, round.category)
		note(round.targetName, round.targetIcon, round.targetHeight, round.category)
		existing[round.referenceName .. "|" .. round.targetName] = true
		existing[round.targetName .. "|" .. round.referenceName] = true
	end

	local added = 0
	local categories = {}
	for category in pairs(objects) do
		table.insert(categories, category)
	end
	table.sort(categories)

	for _, category in ipairs(categories) do
		local list = objects[category]
		table.sort(list, function(a, b)
			return a.name < b.name
		end)
		local candidates = {}
		for i = 1, #list - 1 do
			for j = i + 1, #list do
				local a, b = list[i], list[j]
				local ratio = math.max(a.height, b.height) / math.min(a.height, b.height)
				if ratio >= MIN_RATIO and ratio <= MAX_RATIO and not existing[a.name .. "|" .. b.name] then
					table.insert(candidates, { a = a, b = b, order = pairHash(b.name, a.name) })
				end
			end
		end
		-- A stable shuffle, so the cap spreads partners evenly.
		table.sort(candidates, function(x, y)
			if x.order ~= y.order then
				return x.order < y.order
			end
			return x.a.name .. x.b.name < y.a.name .. y.b.name
		end)
		local used = {}
		local taken = {}
		local function take(pair)
			local a, b = pair.a, pair.b
			local reference, target = a, b
			if coin(a.name, b.name) == 1 then
				reference, target = b, a
			end
			table.insert(rounds, {
				referenceName = reference.name,
				referenceIcon = reference.icon,
				referenceHeight = reference.height,
				targetName = target.name,
				targetIcon = target.icon,
				targetHeight = target.height,
				category = category,
				fact = writeFact(reference, target),
			})
			used[a.name] = (used[a.name] or 0) + 1
			used[b.name] = (used[b.name] or 0) + 1
			taken[pair] = true
			added += 1
		end
		for _, pair in ipairs(candidates) do
			if (used[pair.a.name] or 0) < MAX_PAIRS_PER_OBJECT and (used[pair.b.name] or 0) < MAX_PAIRS_PER_OBJECT then
				take(pair)
			end
		end
		for _, pair in ipairs(candidates) do
			if not taken[pair] and ((used[pair.a.name] or 0) < MIN_PAIRS or (used[pair.b.name] or 0) < MIN_PAIRS) then
				take(pair)
			end
		end
	end
	-- Cross-category pairs for mixed mode.
	local pool = {}
	for _, category in ipairs(categories) do
		if not MIXED_EXCLUDED[category] then
			for _, object in ipairs(objects[category]) do
				table.insert(pool, object)
			end
		end
	end
	local candidates = {}
	for i = 1, #pool - 1 do
		for j = i + 1, #pool do
			local a, b = pool[i], pool[j]
			if a.category ~= b.category and a.name ~= b.name and not existing[a.name .. "|" .. b.name] then
				local ratio = math.max(a.height, b.height) / math.min(a.height, b.height)
				if ratio >= MIN_RATIO and ratio <= MIXED_MAX_RATIO then
					table.insert(candidates, { a = a, b = b, order = pairHash(b.name, a.name) })
				end
			end
		end
	end
	table.sort(candidates, function(x, y)
		if x.order ~= y.order then
			return x.order < y.order
		end
		return x.a.name .. x.b.name < y.a.name .. y.b.name
	end)
	local used = {}
	for _, pair in ipairs(candidates) do
		local a, b = pair.a, pair.b
		if (used[a.name] or 0) < MIXED_PAIRS_PER_OBJECT and (used[b.name] or 0) < MIXED_PAIRS_PER_OBJECT then
			local reference, target = a, b
			if coin(a.name, b.name) == 1 then
				reference, target = b, a
			end
			table.insert(rounds, {
				referenceName = reference.name,
				referenceIcon = reference.icon,
				referenceHeight = reference.height,
				referenceCategory = reference.category,
				targetName = target.name,
				targetIcon = target.icon,
				targetHeight = target.height,
				targetCategory = target.category,
				category = RoundGenerator.MIXED,
				fact = writeFact(reference, target),
			})
			used[a.name] = (used[a.name] or 0) + 1
			used[b.name] = (used[b.name] or 0) + 1
			existing[a.name .. "|" .. b.name] = true
			existing[b.name .. "|" .. a.name] = true
			added += 1
		end
	end
	return added
end

return RoundGenerator
