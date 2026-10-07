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

Pets.List = {
	{ id = "emberfox", name = "Ember Fox", day = 3, color = Color3.fromRGB(255, 140, 50), blurb = "Warm, quick, and a little bit magic." },
	{ id = "cosmiccube", name = "Cosmic Cube", day = 7, color = Color3.fromRGB(130, 110, 255), blurb = "A tiny galaxy that orbits you." },
	{ id = "rainbowslime", name = "Rainbow Slime", day = 14, color = Color3.fromRGB(255, 120, 200), blurb = "The rarest pet. Shifts through every colour." },
}

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
