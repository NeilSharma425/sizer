--[[
	Progress.lua
	ModuleScript: ReplicatedStorage.Progress

	The rules for long-term progression, kept free of Roblox services so
	the server can enforce them and the client can display them (and so
	they can be unit tested):

	  - the player "profile" that gets saved (Sizedex, login streak, daily
	    challenge, weekly records)
	  - Sizedex discovery and mastery stars
	  - combo bonuses
	  - login streak rewards
	  - the shared daily challenge (same 5 questions for everyone each day)
	  - weekly record boards
]]

local Progress = {}

--==========================================================================
-- Tuning
--==========================================================================

Progress.GOOD_SCORE = 80 -- a guess this good extends the combo
Progress.COMBO_START = 3 -- combo needed before bonus Sense kicks in
Progress.COMBO_MAX_BONUS = 5

Progress.DISCOVERY_SENSE = 3
Progress.STAR_SENSE = { 10, 20, 40 } -- reward for reaching star 1, 2, 3
Progress.CATEGORY_SENSE = 100 -- first time every object in a category has a star

Progress.DAILY_PLAN = { "Easy", "Easy", "Medium", "Medium", "Hard" }
Progress.DAILY_COUNT = #Progress.DAILY_PLAN
Progress.FIRST_DAILY_COUNT = 3 -- a player's very first daily is shorter (the first 3 of the plan)
Progress.WEEKLY_SENSE = { 300, 200, 100 } -- previous week's top 3

local SECONDS_PER_DAY = 86400

--==========================================================================
-- Time
--==========================================================================

function Progress.dayOf(unixSeconds)
	return math.floor(unixSeconds / SECONDS_PER_DAY)
end

-- Weeks run Monday to Sunday (UTC). Day 0 (1 Jan 1970) was a Thursday.
function Progress.weekOf(day)
	return math.floor((day + 3) / 7)
end

function Progress.secondsUntilNextDay(unixSeconds)
	return (Progress.dayOf(unixSeconds) + 1) * SECONDS_PER_DAY - unixSeconds
end

function Progress.secondsUntilNextWeek(unixSeconds)
	local week = Progress.weekOf(Progress.dayOf(unixSeconds))
	return ((week + 1) * 7 - 3) * SECONDS_PER_DAY - unixSeconds
end

--==========================================================================
-- Profile (what gets saved)
--==========================================================================

function Progress.newProfile()
	return {
		dex = {}, -- [objectName] = { n = seen, t = played as target, b = best score, g = scores of 90+ }
		cats = {}, -- [category] = true once every object in it has a star
		streak = { count = 0, best = 0, lastDay = 0 },
		pets = {}, -- [petId] = true, unlocked from streak rewards
		pet = "", -- equipped pet id ("" = none)
		flags = {}, -- [name] = true, one-time hints already shown
		wallet = { spent = 0, refunded = 0 }, -- egg shop spending (rank uses lifetime Sense)
		daily = { day = 0, score = 0, answered = 0, total = 0 }, -- today's run (total = its length): score so far, questions answered
		weekly = { week = 0, best = 0, rewardWeek = 0 },
	}
end

-- Fills in anything missing so older or partial saves are safe to use.
function Progress.normalize(profile)
	profile = type(profile) == "table" and profile or {}
	profile.dex = type(profile.dex) == "table" and profile.dex or {}
	profile.cats = type(profile.cats) == "table" and profile.cats or {}
	local function section(key, defaults)
		local value = type(profile[key]) == "table" and profile[key] or {}
		for k, v in pairs(defaults) do
			if type(value[k]) ~= "number" then
				value[k] = v
			end
		end
		profile[key] = value
	end
	profile.pets = type(profile.pets) == "table" and profile.pets or {}
	profile.pet = type(profile.pet) == "string" and profile.pet or ""
	profile.flags = type(profile.flags) == "table" and profile.flags or {}
	section("streak", { count = 0, best = 0, lastDay = 0 })
	section("wallet", { spent = 0, refunded = 0 })
	section("daily", { day = 0, score = 0, answered = 0, total = 0 })
	section("weekly", { week = 0, best = 0, rewardWeek = 0 })
	return profile
end

-- Merges `extra` into `base` (both profiles) keeping the best of each
-- value, so a save can never lose progress. Returns `base`.
function Progress.merge(base, extra)
	base = Progress.normalize(base)
	extra = Progress.normalize(extra)

	for name, entry in pairs(extra.dex) do
		local mine = base.dex[name]
		if not mine then
			mine = { n = 0, t = 0, b = 0, g = 0 }
			base.dex[name] = mine
		end
		mine.n = math.max(mine.n or 0, entry.n or 0)
		mine.t = math.max(mine.t or 0, entry.t or 0)
		mine.b = math.max(mine.b or 0, entry.b or 0)
		mine.g = math.max(mine.g or 0, entry.g or 0)
	end
	for category, done in pairs(extra.cats) do
		if done then
			base.cats[category] = true
		end
	end

	for id, owned in pairs(extra.pets) do
		if owned then
			base.pets[id] = true
		end
	end
	for name, on in pairs(extra.flags) do
		if on then
			base.flags[name] = true
		end
	end
	if extra.pet ~= "" then
		base.pet = extra.pet -- the newer save's choice wins
	end

	base.wallet.spent = math.max(base.wallet.spent, extra.wallet.spent)
	base.wallet.refunded = math.max(base.wallet.refunded, extra.wallet.refunded)

	base.streak.best = math.max(base.streak.best, extra.streak.best)
	if extra.streak.lastDay > base.streak.lastDay then
		base.streak.lastDay = extra.streak.lastDay
		base.streak.count = extra.streak.count
	elseif extra.streak.lastDay == base.streak.lastDay then
		base.streak.count = math.max(base.streak.count, extra.streak.count)
	end

	if extra.daily.day > base.daily.day then
		base.daily.day = extra.daily.day
		base.daily.score = extra.daily.score
		base.daily.answered = extra.daily.answered
		base.daily.total = extra.daily.total
	elseif extra.daily.day == base.daily.day then
		base.daily.score = math.max(base.daily.score, extra.daily.score)
		base.daily.answered = math.max(base.daily.answered, extra.daily.answered)
		if base.daily.total == 0 then
			base.daily.total = extra.daily.total
		end
	end

	if extra.weekly.week > base.weekly.week then
		base.weekly.week = extra.weekly.week
		base.weekly.best = extra.weekly.best
	elseif extra.weekly.week == base.weekly.week then
		base.weekly.best = math.max(base.weekly.best, extra.weekly.best)
	end
	base.weekly.rewardWeek = math.max(base.weekly.rewardWeek, extra.weekly.rewardWeek)
	return base
end

--==========================================================================
-- Sizedex
--==========================================================================

-- 0 stars: only seen. 1: scored 70+ on it. 2: scored 90+. 3: scored 90+
-- three times.
function Progress.starsFor(entry)
	if not entry then
		return 0
	end
	if (entry.g or 0) >= 3 then
		return 3
	elseif (entry.b or 0) >= 90 then
		return 2
	elseif (entry.b or 0) >= 70 then
		return 1
	end
	return 0
end

-- Index of every object in the rounds: { byCategory = { [category] =
-- { names, sorted } }, info = { [name] = { name, icon, height, category } },
-- categories = { sorted category names } }.
function Progress.buildIndex(rounds)
	local info, byCategory = {}, {}
	local function note(name, icon, height, category)
		if info[name] then
			return
		end
		info[name] = { name = name, icon = icon, height = height, category = category }
		byCategory[category] = byCategory[category] or {}
		table.insert(byCategory[category], name)
	end
	for _, round in ipairs(rounds) do
		note(round.referenceName, round.referenceIcon, round.referenceHeight, round.category)
		note(round.targetName, round.targetIcon, round.targetHeight, round.category)
	end
	local categories = {}
	for category, names in pairs(byCategory) do
		table.sort(names)
		table.insert(categories, category)
	end
	table.sort(categories)
	return { byCategory = byCategory, info = info, categories = categories }
end

-- Records a finished round in the Sizedex. Both objects are discovered;
-- mastery counts for the target (the one being sized). Returns
-- { discovered = {names}, starUps = { {name, from, to, reward} },
--   categories = {names newly completed}, sense = total Sense earned }.
function Progress.recordResult(profile, index, referenceName, targetName, score)
	local result = { discovered = {}, starUps = {}, categories = {}, sense = 0 }

	for _, name in ipairs({ referenceName, targetName }) do
		local entry = profile.dex[name]
		if not entry then
			entry = { n = 0, t = 0, b = 0, g = 0 }
			profile.dex[name] = entry
			table.insert(result.discovered, name)
			result.sense += Progress.DISCOVERY_SENSE
		end
		entry.n += 1
	end

	local entry = profile.dex[targetName]
	local before = Progress.starsFor(entry)
	entry.t += 1
	entry.b = math.max(entry.b, score)
	if score >= 90 then
		entry.g += 1
	end
	local after = Progress.starsFor(entry)
	if after > before then
		local reward = 0
		for star = before + 1, after do
			reward += Progress.STAR_SENSE[star]
		end
		table.insert(result.starUps, { name = targetName, from = before, to = after, reward = reward })
		result.sense += reward
	end

	-- Category completion: every object in it has at least one star.
	if index then
		local category = index.info[targetName] and index.info[targetName].category
		if category and not profile.cats[category] then
			local complete = true
			for _, name in ipairs(index.byCategory[category]) do
				if Progress.starsFor(profile.dex[name]) < 1 then
					complete = false
					break
				end
			end
			if complete then
				profile.cats[category] = true
				table.insert(result.categories, category)
				result.sense += Progress.CATEGORY_SENSE
			end
		end
	end
	return result
end

-- { discovered, total, mastered (3 stars), stars, maxStars } over all objects.
function Progress.summary(profile, index)
	local summary = { discovered = 0, total = 0, mastered = 0, stars = 0, maxStars = 0 }
	for name in pairs(index.info) do
		summary.total += 1
		summary.maxStars += 3
		local entry = profile.dex[name]
		if entry then
			summary.discovered += 1
			local stars = Progress.starsFor(entry)
			summary.stars += stars
			if stars >= 3 then
				summary.mastered += 1
			end
		end
	end
	return summary
end

--==========================================================================
-- Combo
--==========================================================================

-- Returns the new combo count and the bonus Sense it earns.
function Progress.combo(previous, score)
	local combo = score >= Progress.GOOD_SCORE and (previous or 0) + 1 or 0
	local bonus = 0
	if combo >= Progress.COMBO_START then
		bonus = math.min(Progress.COMBO_MAX_BONUS, combo - Progress.COMBO_START + 1)
	end
	return combo, bonus
end

--==========================================================================
-- Login streak
--==========================================================================

-- Rewards for day N of a login streak. Rewards grow every day; days 3, 7
-- and 14 unlock pets that can only be earned this way.
Progress.STREAK_REWARDS = {
	{ sense = 20 },
	{ sense = 40 },
	{ sense = 60, pet = "emberfox" },
	{ sense = 80 },
	{ sense = 100 },
	{ sense = 120 },
	{ sense = 200, pet = "cosmiccube" },
	{ sense = 100 },
	{ sense = 120 },
	{ sense = 200 },
	{ sense = 140 },
	{ sense = 160 },
	{ sense = 180 },
	{ sense = 500, pet = "rainbowslime" },
}

-- Returns { sense, pet? } for streak day `streak` (days past 14 keep paying).
function Progress.streakReward(streak)
	local list = Progress.STREAK_REWARDS
	if streak <= #list then
		return list[math.max(1, streak)]
	end
	local sense = 200
	if streak % 7 == 0 then
		sense += 300
	end
	return { sense = sense }
end

function Progress.loginReward(streak)
	return Progress.streakReward(streak).sense
end

-- Compounding bonus on every round's Sense: +5% per streak day, up to +50%.
function Progress.streakBonus(streak)
	return 0.05 * math.min(math.max(streak, 0), 10)
end

-- Sense spent in the shop, net of duplicate refunds. Spendable Sense is the
-- lifetime total minus this.
function Progress.netSpent(profile)
	return math.max(0, profile.wallet.spent - profile.wallet.refunded)
end

-- Updates the streak for a login on `today` (a day number). Returns
-- { isNew, count, best, reward, broken }; isNew is false if this day was
-- already counted.
function Progress.updateStreak(profile, today)
	local streak = profile.streak
	if streak.lastDay == today then
		return { isNew = false, count = streak.count, best = streak.best, reward = 0, broken = false }
	end
	local broken = streak.lastDay > 0 and streak.lastDay < today - 1
	if streak.lastDay == today - 1 then
		streak.count += 1
	else
		streak.count = 1
	end
	streak.best = math.max(streak.best, streak.count)
	streak.lastDay = today
	local reward = Progress.streakReward(streak.count)
	local pet = nil
	profile.pets = profile.pets or {}
	if reward.pet and not profile.pets[reward.pet] then
		profile.pets[reward.pet] = true
		pet = reward.pet
	end
	return {
		isNew = true,
		count = streak.count,
		best = streak.best,
		reward = reward.sense,
		broken = broken,
		pet = pet,
	}
end

--==========================================================================
-- Daily challenge
--==========================================================================

-- Park-Miller generator: deterministic everywhere (no Roblox Random).
local function generator(seed)
	local state = seed % 2147483646 + 1
	return function()
		state = state * 16807 % 2147483647
		return (state - 1) / 2147483646
	end
end

-- The day's questions as indices into `rounds`: the same for every player
-- and every server. `eligible(round)` filters; rounds need a .difficulty.
function Progress.dailyRounds(day, rounds, eligible)
	local buckets = { Easy = {}, Medium = {}, Hard = {} }
	local all = {}
	for index, round in ipairs(rounds) do
		if eligible(round) then
			table.insert(all, index)
			table.insert(buckets[round.difficulty], index)
		end
	end
	if #all == 0 then
		return {}
	end

	local random = generator(day * 7919 + 17)
	local chosen, used = {}, {}
	for _, level in ipairs(Progress.DAILY_PLAN) do
		local pool = buckets[level]
		if #pool == 0 then
			pool = all
		end
		-- Pick one not already used today (fall back if the pool is tiny).
		local pick
		for _ = 1, 20 do
			local candidate = pool[math.floor(random() * #pool) + 1]
			if not used[candidate] then
				pick = candidate
				break
			end
		end
		pick = pick or pool[math.floor(random() * #pool) + 1]
		used[pick] = true
		table.insert(chosen, pick)
	end
	return chosen
end

-- How many questions a new daily has for this player: 3 the very first
-- time (never played one before), 5 after that.
function Progress.dailyLength(profile)
	local flags = profile.flags or {}
	if flags.firstDaily or profile.daily.day ~= 0 then
		return Progress.DAILY_COUNT
	end
	return Progress.FIRST_DAILY_COUNT
end

-- Where the player is in today's daily challenge: { done, answered, score,
-- total }. Anything saved for another day counts as a fresh start.
function Progress.dailyState(profile, today)
	local daily = profile.daily
	if daily.day ~= today then
		return { done = false, answered = 0, score = 0, total = Progress.dailyLength(profile) }
	end
	local total = (daily.total or 0) > 0 and daily.total or Progress.dailyLength(profile)
	return { done = daily.answered >= total, answered = daily.answered, score = daily.score, total = total }
end

-- Records one answered daily question; returns the new state.
function Progress.recordDaily(profile, today, score)
	local daily = profile.daily
	if daily.day ~= today then
		daily.total = Progress.dailyLength(profile) -- before `day` changes
		daily.day = today
		daily.score = 0
		daily.answered = 0
	end
	daily.answered += 1
	daily.score += score
	return Progress.dailyState(profile, today)
end

function Progress.dailyReward(total)
	return 25 + math.floor(total / 10) + (total >= 450 and 50 or 0)
end

--==========================================================================
-- Weekly records
--==========================================================================

-- Records a 60s score for `week`. Returns true if it is a new best this week.
function Progress.recordWeekly(profile, week, score)
	local weekly = profile.weekly
	if weekly.week ~= week then
		weekly.week = week
		weekly.best = 0
	end
	if score > weekly.best then
		weekly.best = score
		return true
	end
	return false
end

-- The player's best for `week` (0 if their saved week is another one).
function Progress.weeklyBest(profile, week)
	return profile.weekly.week == week and profile.weekly.best or 0
end

return Progress
