--[[
	Pets.lua
	ModuleScript: ReplicatedStorage.Pets

	Pets that can only be unlocked from login-streak rewards (the day each
	one unlocks is set by Progress.STREAK_REWARDS). build(id) returns a small
	anchored Model made of Parts, plus an animate(t) function for the parts
	that move or change colour. Used by the world pets (PetClient) and by the
	streak window previews.
]]

local Pets = {}

-- rule kinds: start (everyone), streak (login streak day, granted by
-- Progress.updateStreak), rank (rank number from Ranks), category (every
-- object in the category earned a Sizedex star), timed (60s challenge best).
Pets.List = {
	{ id = "mouse", name = "Pocket Mouse", color = Color3.fromRGB(190, 190, 205), rule = { kind = "start" }, how = "Everyone starts with this one", blurb = "Small, but it knows its sizes." },
	{ id = "robot", name = "Ruler Bot", color = Color3.fromRGB(120, 190, 255), rule = { kind = "rank", rank = 4 }, how = "Reach the Estimator rank", blurb = "Measures everything it sees." },
	{ id = "duck", name = "Rubber Duck", color = Color3.fromRGB(255, 220, 60), rule = { kind = "category", name = "Everyday Objects" }, how = "Earn a star on every Everyday Objects item", blurb = "Everyday hero." },
	{ id = "owl", name = "Wise Owl", color = Color3.fromRGB(170, 120, 80), rule = { kind = "category", name = "Animals" }, how = "Earn a star on every Animals item", blurb = "Has seen every animal there is." },
	{ id = "pyramid", name = "Pocket Pyramid", color = Color3.fromRGB(235, 200, 120), rule = { kind = "category", name = "Landmarks" }, how = "Earn a star on every Landmarks item", blurb = "A landmark you can carry." },
	{ id = "moon", name = "Moon Buddy", color = Color3.fromRGB(215, 220, 235), rule = { kind = "category", name = "Space" }, how = "Earn a star on every Space item", blurb = "Orbits you, politely." },
	{ id = "verity", name = "Mini Verity", color = Color3.fromRGB(255, 225, 70), rule = { kind = "category", name = "Brainrot" }, how = "Earn a star on every Brainrot item", blurb = "Giant energy, tiny size." },
	{ id = "bee", name = "Speed Bee", color = Color3.fromRGB(255, 205, 40), rule = { kind = "timed", score = 400 }, how = "Score 400 in the 60s challenge", blurb = "Buzzes through the clock." },
	{ id = "emberfox", name = "Ember Fox", color = Color3.fromRGB(255, 140, 50), rule = { kind = "streak", day = 3 }, how = "Reach a 3 day login streak", blurb = "Warm, quick, and a little bit magic." },
	{ id = "ghost", name = "Halo Ghost", color = Color3.fromRGB(235, 240, 255), rule = { kind = "rank", rank = 8 }, how = "Reach the Master rank", blurb = "Friendly, and a little holy." },
	{ id = "cosmiccube", name = "Cosmic Cube", color = Color3.fromRGB(130, 110, 255), rule = { kind = "streak", day = 7 }, how = "Reach a 7 day login streak", blurb = "A tiny galaxy that orbits you." },
	{ id = "rainbowslime", name = "Rainbow Slime", color = Color3.fromRGB(255, 120, 200), rule = { kind = "streak", day = 14 }, how = "Reach a 14 day login streak", blurb = "The rarest pet. Shifts through every colour." },
}

-- True when a non-streak rule is met. state = { rank (number), cats (table),
-- timedBest (number) }. Streak pets are granted by the login streak.
function Pets.qualifies(rule, state)
	if rule.kind == "start" then
		return true
	elseif rule.kind == "rank" then
		return (state.rank or 1) >= rule.rank
	elseif rule.kind == "category" then
		return state.cats ~= nil and state.cats[rule.name] == true
	elseif rule.kind == "timed" then
		return (state.timedBest or 0) >= rule.score
	end
	return false
end

function Pets.get(id)
	for _, pet in ipairs(Pets.List) do
		if pet.id == id then
			return pet
		end
	end
	return nil
end

local function part(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = model
	return p
end

local function ball(model, size, color, offset)
	return part(model, {
		Shape = Enum.PartType.Ball,
		Size = size,
		Color = color,
		CFrame = CFrame.new(offset),
	})
end

-- Each builder fills `model` around the origin (about 2.4 studs tall) and
-- returns an animate(t) function, or nil.
local builders = {}

function builders.emberfox(model)
	local orange = Color3.fromRGB(255, 140, 50)
	local cream = Color3.fromRGB(255, 235, 205)
	local dark = Color3.fromRGB(60, 35, 30)
	ball(model, Vector3.new(1.7, 1.4, 2.2), orange, Vector3.new(0, 0, 0)) -- body
	ball(model, Vector3.new(1.5, 1.4, 1.4), orange, Vector3.new(0, 0.7, -1.1)) -- head
	ball(model, Vector3.new(0.9, 0.6, 0.6), cream, Vector3.new(0, 0.5, -1.7)) -- snout
	ball(model, Vector3.new(0.28, 0.28, 0.28), dark, Vector3.new(0, 0.6, -2.0)) -- nose
	ball(model, Vector3.new(0.25, 0.3, 0.2), dark, Vector3.new(-0.38, 0.95, -1.75))
	ball(model, Vector3.new(0.25, 0.3, 0.2), dark, Vector3.new(0.38, 0.95, -1.75))
	for _, x in ipairs({ -0.5, 0.5 }) do -- ears
		part(model, {
			Size = Vector3.new(0.45, 0.9, 0.3),
			Color = orange,
			CFrame = CFrame.new(x, 1.7, -1.0) * CFrame.Angles(0, 0, x * 0.5),
		})
		part(model, {
			Size = Vector3.new(0.22, 0.5, 0.32),
			Color = dark,
			CFrame = CFrame.new(x, 1.65, -1.05) * CFrame.Angles(0, 0, x * 0.5),
		})
	end
	for _, x in ipairs({ -0.5, 0.5 }) do -- paws
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = dark, CFrame = CFrame.new(x, -0.85, -0.5) })
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = dark, CFrame = CFrame.new(x, -0.85, 0.6) })
	end
	local tail = ball(model, Vector3.new(0.9, 0.9, 2.0), orange, Vector3.new(0, 0.4, 1.7))
	local tip = part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.8, 0.8, 0.9),
		Color = Color3.fromRGB(255, 220, 90),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 0.4, 2.7),
	})
	local tailBase, tipBase = tail.CFrame, tip.CFrame
	return function(t, o)
		local sway = CFrame.Angles(0, math.sin(t * 3) * 0.35, 0)
		local pivot = CFrame.new(0, 0.4, 0.9)
		tail.CFrame = o * pivot * sway * (pivot:Inverse() * tailBase)
		tip.CFrame = o * pivot * sway * (pivot:Inverse() * tipBase)
	end
end

function builders.cosmiccube(model)
	local core = part(model, {
		Size = Vector3.new(1.3, 1.3, 1.3),
		Color = Color3.fromRGB(110, 90, 240),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 0, 0),
	})
	local shell = part(model, {
		Size = Vector3.new(1.9, 1.9, 1.9),
		Color = Color3.fromRGB(190, 170, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		CFrame = CFrame.new(0, 0, 0),
	})
	local moons = {}
	for i = 1, 3 do
		moons[i] = ball(model, Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 240, 160), Vector3.new(0, 0, 0))
		moons[i].Material = Enum.Material.Neon
	end
	return function(t, o)
		local spin = o * CFrame.Angles(t * 0.8, t * 1.1, t * 0.5)
		core.CFrame = spin
		shell.CFrame = spin
		for i, moon in ipairs(moons) do
			local a = t * 1.8 + i * (math.pi * 2 / 3)
			moon.CFrame = o * CFrame.new(math.cos(a) * 1.7, math.sin(a * 0.7 + i) * 0.7, math.sin(a) * 1.7)
		end
	end
end

function builders.rainbowslime(model)
	local body = part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 1.8, 2.2),
		Color = Color3.fromRGB(255, 120, 200),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		CFrame = CFrame.new(0, 0, 0),
	})
	local core = ball(model, Vector3.new(0.9, 0.9, 0.9), Color3.new(1, 1, 1), Vector3.new(0, -0.1, 0))
	core.Material = Enum.Material.Neon
	local eyes = {}
	for _, x in ipairs({ -0.45, 0.45 }) do
		eyes[#eyes + 1] = ball(model, Vector3.new(0.3, 0.42, 0.2), Color3.fromRGB(30, 25, 45), Vector3.new(x, 0.25, -1.0))
	end
	local sparks = {}
	for i = 1, 4 do
		sparks[i] = ball(model, Vector3.new(0.25, 0.25, 0.25), Color3.new(1, 1, 1), Vector3.new(0, 0, 0))
		sparks[i].Material = Enum.Material.Neon
	end
	return function(t, o)
		local squish = 1 + 0.08 * math.sin(t * 4)
		body.Size = Vector3.new(2.2 / squish, 1.8 * squish, 2.2 / squish)
		body.CFrame = o
		core.CFrame = o * CFrame.new(0, -0.1, 0)
		body.Color = Color3.fromHSV((t * 0.25) % 1, 0.6, 1)
		core.Color = Color3.fromHSV((t * 0.25 + 0.5) % 1, 0.5, 1)
		for i, spark in ipairs(sparks) do
			local a = t * 2 + i * (math.pi / 2)
			spark.CFrame = o * CFrame.new(math.cos(a) * 1.5, 1.2 + math.sin(a * 2) * 0.3, math.sin(a) * 1.5)
			spark.Color = Color3.fromHSV((t * 0.5 + i / 4) % 1, 0.7, 1)
		end
	end
end

function builders.mouse(model)
	local gray = Color3.fromRGB(190, 190, 205)
	local pink = Color3.fromRGB(255, 170, 190)
	ball(model, Vector3.new(1.4, 1.2, 1.9), gray, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.0, 0.9, 1.0), gray, Vector3.new(0, 0.2, -1.1))
	ball(model, Vector3.new(0.25, 0.25, 0.25), pink, Vector3.new(0, 0.2, -1.65))
	ball(model, Vector3.new(0.2, 0.25, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(-0.28, 0.5, -1.45))
	ball(model, Vector3.new(0.2, 0.25, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(0.28, 0.5, -1.45))
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 0.8, 0.8), Color = pink, CFrame = CFrame.new(x, 0.95, -0.95) * CFrame.Angles(0, math.pi / 2, 0) })
	end
	local tail = part(model, { Size = Vector3.new(0.15, 0.15, 1.6), Color = pink, CFrame = CFrame.new(0, -0.2, 1.7) })
	local base = tail.CFrame
	return function(t, o)
		tail.CFrame = o * CFrame.Angles(0, math.sin(t * 5) * 0.4, 0) * base
	end
end

function builders.robot(model)
	local blue = Color3.fromRGB(120, 190, 255)
	part(model, { Size = Vector3.new(1.6, 1.4, 1.4), Color = blue, Material = Enum.Material.Metal, CFrame = CFrame.new(0, -0.3, 0) })
	part(model, { Size = Vector3.new(1.3, 1.0, 1.2), Color = Color3.fromRGB(220, 230, 245), Material = Enum.Material.Metal, CFrame = CFrame.new(0, 0.9, 0) })
	for _, x in ipairs({ -0.3, 0.3 }) do
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(80, 255, 200), Material = Enum.Material.Neon, CFrame = CFrame.new(x, 0.95, -0.62) })
	end
	part(model, { Size = Vector3.new(0.08, 0.5, 0.08), Color = Color3.fromRGB(60, 60, 80), CFrame = CFrame.new(0, 1.65, 0) })
	local bulb = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 90, 90), Material = Enum.Material.Neon, CFrame = CFrame.new(0, 1.95, 0) })
	-- ruler marks on the belly
	for i = -2, 2 do
		part(model, { Size = Vector3.new(i % 2 == 0 and 0.5 or 0.3, 0.06, 0.05), Color = Color3.fromRGB(40, 50, 90), CFrame = CFrame.new(0, -0.3 + i * 0.2, -0.71) })
	end
	return function(t, o)
		bulb.CFrame = o * CFrame.new(0, 1.95 + math.sin(t * 6) * 0.05, 0)
		bulb.Transparency = 0.5 + 0.5 * math.sin(t * 6) * 0.5
	end
end

function builders.duck(model)
	local yellow = Color3.fromRGB(255, 220, 60)
	ball(model, Vector3.new(1.9, 1.4, 2.2), yellow, Vector3.new(0, -0.1, 0))
	ball(model, Vector3.new(1.2, 1.2, 1.2), yellow, Vector3.new(0, 0.9, -0.8))
	part(model, { Size = Vector3.new(0.7, 0.2, 0.6), Color = Color3.fromRGB(255, 140, 40), CFrame = CFrame.new(0, 0.75, -1.5) })
	ball(model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(-0.3, 1.1, -1.25))
	ball(model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(0.3, 1.1, -1.25))
	ball(model, Vector3.new(0.5, 0.8, 1.2), Color3.fromRGB(255, 200, 40), Vector3.new(-0.95, 0, 0.1))
	ball(model, Vector3.new(0.5, 0.8, 1.2), Color3.fromRGB(255, 200, 40), Vector3.new(0.95, 0, 0.1))
	return nil
end

function builders.owl(model)
	local brown = Color3.fromRGB(150, 105, 70)
	local cream = Color3.fromRGB(240, 225, 195)
	ball(model, Vector3.new(1.9, 2.1, 1.7), brown, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.2, 1.3, 0.5), cream, Vector3.new(0, -0.2, -0.6))
	for _, x in ipairs({ -0.45, 0.45 }) do
		ball(model, Vector3.new(0.75, 0.75, 0.3), Color3.new(1, 1, 1), Vector3.new(x, 0.55, -0.75))
		ball(model, Vector3.new(0.35, 0.35, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.55, -0.9))
		part(model, { Size = Vector3.new(0.3, 0.55, 0.3), Color = brown, CFrame = CFrame.new(x * 1.2, 1.2, -0.1) * CFrame.Angles(0, 0, x * 0.6) })
	end
	part(model, { Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 170, 50), CFrame = CFrame.new(0, 0.2, -0.9) * CFrame.Angles(math.pi / 4, 0, math.pi / 4) })
	local wings = {}
	for i, x in ipairs({ -1, 1 }) do
		wings[i] = { part = ball(model, Vector3.new(0.35, 1.5, 1.0), Color3.fromRGB(120, 80, 55), Vector3.new(x * 1.0, -0.1, 0.1)), side = x }
	end
	return function(t, o)
		for _, w in ipairs(wings) do
			w.part.CFrame = o * CFrame.new(w.side * 1.0, -0.1, 0.1) * CFrame.Angles(0, 0, w.side * (0.1 + 0.15 * math.sin(t * 3)))
		end
	end
end

function builders.pyramid(model)
	local sand = Color3.fromRGB(235, 200, 120)
	-- stacked slabs make a stepped pyramid
	for i = 0, 4 do
		local w = 2.4 - i * 0.45
		part(model, { Size = Vector3.new(w, 0.45, w), Color = sand:Lerp(Color3.fromRGB(190, 150, 80), i * 0.12), CFrame = CFrame.new(0, -0.9 + i * 0.45, 0) })
	end
	for _, x in ipairs({ -0.35, 0.35 }) do
		ball(model, Vector3.new(0.4, 0.4, 0.2), Color3.new(1, 1, 1), Vector3.new(x, 0.1, -0.85))
		ball(model, Vector3.new(0.2, 0.2, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.1, -0.95))
	end
	return nil
end

function builders.moon(model)
	local gray = Color3.fromRGB(215, 220, 235)
	local moon = ball(model, Vector3.new(2.2, 2.2, 2.2), gray, Vector3.new(0, 0, 0))
	for _, c in ipairs({ { -0.6, 0.5, -0.85, 0.6 }, { 0.5, -0.4, -0.95, 0.5 }, { 0.2, 0.8, -0.8, 0.35 } }) do
		ball(model, Vector3.new(c[4], c[4], 0.15), Color3.fromRGB(175, 180, 200), Vector3.new(c[1], c[2], c[3]))
	end
	ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(-0.35, 0.1, -1.05))
	ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(0.35, 0.1, -1.05))
	local star = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 240, 150), Material = Enum.Material.Neon, CFrame = CFrame.new(1.8, 0, 0) })
	return function(t, o)
		moon.CFrame = o
		star.CFrame = o * CFrame.new(math.cos(t * 2) * 1.8, math.sin(t * 2) * 0.5, math.sin(t * 2) * 1.8)
	end
end

function builders.verity(model)
	local yellow = Color3.fromRGB(255, 225, 70)
	ball(model, Vector3.new(2.2, 2.2, 2.2), yellow, Vector3.new(0, 0, 0))
	for _, x in ipairs({ -0.5, 0.5 }) do
		ball(model, Vector3.new(0.5, 0.8, 0.25), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.3, -1.0))
		ball(model, Vector3.new(0.18, 0.28, 0.1), Color3.new(1, 1, 1), Vector3.new(x + 0.06, 0.5, -1.1))
	end
	part(model, { Size = Vector3.new(1.3, 0.45, 0.15), Color = Color3.new(1, 1, 1), CFrame = CFrame.new(0, -0.5, -1.0) })
	part(model, { Size = Vector3.new(1.3, 0.04, 0.17), Color = Color3.fromRGB(30, 25, 40), CFrame = CFrame.new(0, -0.5, -1.0) })
	return nil
end

function builders.bee(model)
	local yellow = Color3.fromRGB(255, 205, 40)
	local black = Color3.fromRGB(35, 30, 40)
	ball(model, Vector3.new(1.6, 1.5, 2.2), yellow, Vector3.new(0, 0, 0))
	for _, z in ipairs({ -0.3, 0.5 }) do
		part(model, { Size = Vector3.new(1.55, 1.2, 0.3), Color = black, CFrame = CFrame.new(0, 0, z) })
	end
	ball(model, Vector3.new(1.1, 1.1, 1.1), yellow, Vector3.new(0, 0.1, -1.4))
	ball(model, Vector3.new(0.22, 0.28, 0.15), black, Vector3.new(-0.3, 0.3, -1.85))
	ball(model, Vector3.new(0.22, 0.28, 0.15), black, Vector3.new(0.3, 0.3, -1.85))
	local wings = {}
	for i, x in ipairs({ -1, 1 }) do
		wings[i] = { part = part(model, { Size = Vector3.new(1.2, 0.08, 0.8), Color = Color3.fromRGB(210, 240, 255), Transparency = 0.4, CFrame = CFrame.new(x * 0.9, 0.9, 0) }), side = x }
	end
	return function(t, o)
		for _, w in ipairs(wings) do
			w.part.CFrame = o * CFrame.new(w.side * 0.9, 0.9, 0) * CFrame.Angles(0, 0, w.side * math.sin(t * 30) * 0.5)
		end
	end
end

function builders.ghost(model)
	local white = Color3.fromRGB(235, 240, 255)
	ball(model, Vector3.new(1.9, 2.0, 1.9), white, Vector3.new(0, 0.3, 0))
	part(model, { Size = Vector3.new(1.9, 1.0, 1.7), Color = white, CFrame = CFrame.new(0, -0.6, 0) })
	for i = -1, 1 do
		ball(model, Vector3.new(0.65, 0.65, 0.65), white, Vector3.new(i * 0.62, -1.1, 0))
	end
	for _, x in ipairs({ -0.4, 0.4 }) do
		ball(model, Vector3.new(0.3, 0.45, 0.2), Color3.fromRGB(40, 40, 70), Vector3.new(x, 0.45, -0.88))
	end
	ball(model, Vector3.new(0.4, 0.25, 0.2), Color3.fromRGB(255, 160, 170), Vector3.new(0, 0.0, -0.9))
	local halo = part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.5, 1.5), Color = Color3.fromRGB(255, 220, 90), Material = Enum.Material.Neon, CFrame = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.pi / 2) })
	return function(t, o)
		halo.CFrame = o * CFrame.new(0, 1.7 + math.sin(t * 3) * 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
	end
end


-- Returns model, animate (may be nil). The model's PrimaryPart is set to
-- a hidden anchor at its centre so it can be moved with PivotTo.
function Pets.build(id)
	local builder = builders[id]
	if not builder then
		return nil, nil
	end
	local model = Instance.new("Model")
	model.Name = "Pet_" .. id
	local animate = builder(model)
	local root = part(model, {
		Name = "PetRoot",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(0, 0, 0),
	})
	model.PrimaryPart = root
	if not animate then
		return model, nil
	end
	return model, function(t)
		animate(t, root.CFrame)
	end
end

return Pets
