--[[
	ObjectModels.lua
	ModuleScript: ReplicatedStorage.ObjectModels

	Low-poly Part models for every object in ScaleData, built on demand by
	the client's viewing room. Each builder works in its own units with the
	ground at y = 0, centered on x = 0, and the "front" facing -Z (toward
	the camera). Animals and vehicles are shown side-on.

	ObjectModels.build(name, icon, fallbackColor) returns:
		model    -- Model with WorldPivot at its bottom center
		measure  -- the length (in model units) that equals the real-world
		            size from ScaleData, e.g. rim height for the hoop
	Unknown names fall back to a colored block with the emoji icon.
]]

local ObjectModels = {}

local SMOOTH = Enum.Material.SmoothPlastic

--==========================================================================
-- Primitive helpers
--==========================================================================

local function add(model, p, color, material)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or SMOOTH
	p.Parent = model
	return p
end

local function toCFrame(pos)
	return typeof(pos) == "CFrame" and pos or CFrame.new(pos)
end

local function box(model, size, pos, color, material)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = toCFrame(pos)
	return add(model, p, color, material)
end

local function ball(model, diameter, pos, color, material)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.CFrame = CFrame.new(pos)
	return add(model, p, color, material)
end

-- Cylinder whose axis follows the given CFrame's X axis.
local function cylinder(model, length, radius, cf, color, material)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, radius * 2, radius * 2)
	p.CFrame = cf
	return add(model, p, color, material)
end

local function vcyl(model, height, radius, pos, color, material)
	return cylinder(model, height, radius, CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material)
end

local function zcyl(model, length, radius, pos, color, material)
	return cylinder(model, length, radius, CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), color, material)
end

-- Square beam from one point to another. CFrame.lookAt with the default up
-- vector yields NaN for vertical beams, so those use X as "up" instead.
local function beam(model, from, to, thickness, color, material)
	local delta = to - from
	local length = delta.Magnitude
	local up = math.abs(delta.Unit.Y) > 0.99 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
	return box(model, Vector3.new(thickness, thickness, length), CFrame.lookAt((from + to) / 2, to, up), color, material)
end

local function wedge(model, size, cf, color, material)
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	return add(model, p, color, material)
end

-- Triangular peak in the X/Y plane (faces the camera), extruded along Z.
-- Wedges rise toward their local +Z, so each half is turned to rise
-- toward the center line.
local function peak(model, centerX, baseY, centerZ, halfWidth, height, depth, color, material)
	local size = Vector3.new(depth, height, halfWidth)
	local y = baseY + height / 2
	wedge(model, size, CFrame.new(centerX - halfWidth / 2, y, centerZ) * CFrame.Angles(0, math.pi / 2, 0), color, material)
	wedge(model, size, CFrame.new(centerX + halfWidth / 2, y, centerZ) * CFrame.Angles(0, -math.pi / 2, 0), color, material)
end

-- Point on a sphere; lon = 0 faces the camera (-Z).
local function onSphere(center, radius, latDeg, lonDeg)
	local lat, lon = math.rad(latDeg), math.rad(lonDeg)
	return center + Vector3.new(radius * math.cos(lat) * math.sin(lon), radius * math.sin(lat), -radius * math.cos(lat) * math.cos(lon))
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local BLACK = rgb(25, 25, 30)
local WHITE = rgb(245, 245, 245)

--==========================================================================
-- Animals
--==========================================================================

local builders = {}

builders["African Elephant"] = function(m)
	local gray, dark = rgb(128, 128, 138), rgb(100, 100, 112)
	for _, x in ipairs({ -2.8, 2.8 }) do
		for _, z in ipairs({ -1.4, 1.4 }) do
			box(m, Vector3.new(1.7, 3.6, 1.7), Vector3.new(x, 1.8, z), gray)
		end
	end
	box(m, Vector3.new(9, 5, 5), Vector3.new(0, 6.1, 0), gray)
	box(m, Vector3.new(3.6, 4, 3.6), Vector3.new(-5.6, 7.4, 0), gray)
	for _, z in ipairs({ -2.3, 2.3 }) do
		box(m, Vector3.new(0.5, 3.6, 2.8), Vector3.new(-4.1, 7.6, z), dark)
	end
	beam(m, Vector3.new(-7.1, 7, 0), Vector3.new(-8.1, 1.8, 0), 1.2, gray)
	for _, z in ipairs({ -0.9, 0.9 }) do
		beam(m, Vector3.new(-7, 5.6, z), Vector3.new(-8.6, 4.5, z * 1.2), 0.45, rgb(240, 235, 220))
	end
	box(m, Vector3.new(0.4, 0.4, 0.2), Vector3.new(-6.5, 8.5, -1.85), BLACK)
	beam(m, Vector3.new(4.5, 7.5, 0), Vector3.new(5.2, 4.5, 0), 0.35, dark)
end

builders["Giraffe"] = function(m)
	local yellow, spot = rgb(232, 185, 95), rgb(150, 90, 45)
	for _, x in ipairs({ -2.2, 2.2 }) do
		for _, z in ipairs({ -0.9, 0.9 }) do
			box(m, Vector3.new(0.7, 6, 0.7), Vector3.new(x, 3, z), yellow)
			box(m, Vector3.new(0.75, 0.4, 0.75), Vector3.new(x, 0.2, z), spot)
		end
	end
	box(m, Vector3.new(6, 3, 2.6), Vector3.new(0, 7.5, 0), yellow)
	beam(m, Vector3.new(-2.2, 8.5, 0), Vector3.new(-4.2, 15, 0), 1.3, yellow)
	box(m, Vector3.new(2.8, 1.3, 1.2), Vector3.new(-5.2, 15.6, 0), yellow)
	for _, z in ipairs({ -0.35, 0.35 }) do
		box(m, Vector3.new(0.25, 0.8, 0.25), Vector3.new(-4.4, 16.6, z), spot)
	end
	box(m, Vector3.new(0.3, 0.3, 0.1), Vector3.new(-5.6, 15.9, -0.62), BLACK)
	beam(m, Vector3.new(3, 8.5, 0), Vector3.new(3.4, 5.5, 0), 0.25, spot)
	for _, p in ipairs({ { -2, 8 }, { 0, 7.2 }, { 1.8, 8.3 }, { -0.8, 8.6 }, { 2.2, 6.8 }, { -2.3, 6.8 }, { 0.6, 8.5 } }) do
		box(m, Vector3.new(1, 0.8, 0.1), Vector3.new(p[1], p[2], -1.33), spot)
	end
end

builders["House Cat"] = function(m)
	local orange, stripe = rgb(235, 145, 60), rgb(190, 100, 40)
	for _, x in ipairs({ -1.6, 1.6 }) do
		for _, z in ipairs({ -0.6, 0.6 }) do
			box(m, Vector3.new(0.6, 1.5, 0.6), Vector3.new(x, 0.75, z), orange)
		end
	end
	box(m, Vector3.new(4.6, 2.2, 1.8), Vector3.new(0, 2.6, 0), orange)
	for _, x in ipairs({ -0.8, 0.4, 1.6 }) do
		box(m, Vector3.new(0.4, 2.25, 1.85), Vector3.new(x, 2.6, 0), stripe)
	end
	box(m, Vector3.new(2, 1.9, 1.8), Vector3.new(-2.9, 3.8, 0), orange)
	-- Ears: rotated squares half-sunk into the head read as triangles.
	for _, x in ipairs({ -3.5, -2.4 }) do
		box(m, Vector3.new(0.7, 0.7, 0.3), CFrame.new(x, 4.75, 0) * CFrame.Angles(0, 0, math.pi / 4), orange)
	end
	box(m, Vector3.new(0.3, 0.3, 0.1), Vector3.new(-3.4, 4.0, -0.92), rgb(90, 200, 90))
	box(m, Vector3.new(0.1, 0.25, 0.25), Vector3.new(-3.92, 3.5, 0), rgb(255, 150, 170))
	beam(m, Vector3.new(2.2, 3.2, 0), Vector3.new(3.4, 5.6, 0), 0.45, orange)
end

builders["Grizzly Bear"] = function(m)
	local brown, light = rgb(105, 68, 42), rgb(160, 120, 80)
	for _, x in ipairs({ -1.2, 1.2 }) do
		box(m, Vector3.new(1.7, 3.8, 1.8), Vector3.new(x, 1.9, 0), brown)
	end
	box(m, Vector3.new(4.6, 5.6, 3), Vector3.new(0, 6.6, 0), brown)
	box(m, Vector3.new(3, 3.6, 0.2), Vector3.new(0, 6.4, -1.55), light)
	for _, side in ipairs({ -1, 1 }) do
		beam(m, Vector3.new(side * 2.6, 8.8, 0), Vector3.new(side * 3.8, 11, -0.8), 1.4, brown)
	end
	box(m, Vector3.new(3, 2.7, 2.6), Vector3.new(0, 10.75, 0), brown)
	for _, x in ipairs({ -1.2, 1.2 }) do
		box(m, Vector3.new(0.8, 0.8, 0.6), Vector3.new(x, 12.3, 0), brown)
	end
	box(m, Vector3.new(1.5, 1.1, 1), Vector3.new(0, 10.3, -1.7), light)
	box(m, Vector3.new(0.6, 0.4, 0.2), Vector3.new(0, 10.6, -2.25), BLACK)
	for _, x in ipairs({ -0.7, 0.7 }) do
		box(m, Vector3.new(0.35, 0.35, 0.1), Vector3.new(x, 11.3, -1.32), BLACK)
	end
end

builders["Human (Average Adult)"] = function(m)
	local skin, shirt, pants, hair = rgb(255, 205, 160), rgb(60, 140, 230), rgb(50, 60, 110), rgb(70, 45, 30)
	for _, x in ipairs({ -0.55, 0.55 }) do
		box(m, Vector3.new(1, 4.4, 1), Vector3.new(x, 2.2, 0), pants)
		box(m, Vector3.new(1.05, 0.4, 1.3), Vector3.new(x, 0.2, -0.15), BLACK)
	end
	box(m, Vector3.new(2.2, 3.4, 1.1), Vector3.new(0, 6.1, 0), shirt)
	for _, x in ipairs({ -1.6, 1.6 }) do
		box(m, Vector3.new(0.9, 2.9, 0.9), Vector3.new(x, 6.35, 0), shirt)
		box(m, Vector3.new(0.9, 0.6, 0.9), Vector3.new(x, 4.6, 0), skin)
	end
	box(m, Vector3.new(1.5, 1.5, 1.4), Vector3.new(0, 8.6, 0), skin)
	box(m, Vector3.new(1.6, 0.5, 1.5), Vector3.new(0, 9.5, 0), hair)
	box(m, Vector3.new(1.6, 1.2, 0.3), Vector3.new(0, 9, 0.7), hair)
	for _, x in ipairs({ -0.35, 0.35 }) do
		box(m, Vector3.new(0.2, 0.25, 0.1), Vector3.new(x, 8.75, -0.72), BLACK)
	end
	box(m, Vector3.new(0.6, 0.12, 0.1), Vector3.new(0, 8.3, -0.72), BLACK)
end

builders["Blue Whale"] = function(m)
	local blue, belly = rgb(70, 100, 150), rgb(170, 185, 205)
	box(m, Vector3.new(20, 4.4, 4.6), Vector3.new(0, 2.6, 0), blue)
	box(m, Vector3.new(16, 1.2, 4.7), Vector3.new(-1, 0.9, 0), belly)
	box(m, Vector3.new(3, 3.6, 4.4), Vector3.new(-11.3, 2.4, 0), blue)
	box(m, Vector3.new(4.6, 0.15, 0.1), Vector3.new(-10.3, 1.6, -2.36), BLACK)
	box(m, Vector3.new(0.4, 0.4, 0.1), Vector3.new(-9, 3.2, -2.36), BLACK)
	beam(m, Vector3.new(10, 2.8, 0), Vector3.new(15, 3.6, 0), 2, blue)
	box(m, Vector3.new(1.2, 0.5, 8), Vector3.new(15.6, 4, 0), blue)
	beam(m, Vector3.new(-5, 1.8, -2.3), Vector3.new(-2.5, 0.4, -3.6), 0.5, blue)
	box(m, Vector3.new(1.2, 1.2, 0.4), CFrame.new(6, 4.8, 0) * CFrame.Angles(0, 0, math.pi / 4), blue)
	-- The whale's real-world size is its length.
	return 29
end

builders["Emperor Penguin"] = function(m)
	local orange = rgb(255, 170, 40)
	box(m, Vector3.new(3.2, 6.6, 2.8), Vector3.new(0, 3.6, 0), BLACK)
	box(m, Vector3.new(2.4, 5.2, 0.2), Vector3.new(0, 3.4, -1.45), WHITE)
	box(m, Vector3.new(1.6, 0.6, 0.2), Vector3.new(0, 6.6, -1.46), rgb(255, 200, 80))
	box(m, Vector3.new(2.4, 2.2, 2.2), Vector3.new(0, 8, 0), BLACK)
	for _, side in ipairs({ -1, 1 }) do
		box(m, Vector3.new(0.3, 1, 1), Vector3.new(side * 1.25, 7.8, -0.3), orange)
		box(m, Vector3.new(0.25, 0.25, 0.1), Vector3.new(side * 0.55, 8.3, -1.12), WHITE)
		beam(m, Vector3.new(side * 1.7, 6, 0), Vector3.new(side * 2.4, 2.8, -0.2), 0.5, BLACK)
		box(m, Vector3.new(1, 0.3, 1.2), Vector3.new(side * 0.7, 0.15, -0.6), orange)
	end
	box(m, Vector3.new(0.4, 0.4, 1.2), Vector3.new(0, 7.7, -1.6), orange)
end

builders["Ostrich"] = function(m)
	local skin = rgb(225, 170, 150)
	for _, z in ipairs({ -0.5, 0.5 }) do
		box(m, Vector3.new(0.5, 6, 0.5), Vector3.new(z * 0.6, 3, z), skin)
		box(m, Vector3.new(1.2, 0.3, 0.6), Vector3.new(z * 0.6 - 0.4, 0.15, z), skin)
	end
	box(m, Vector3.new(4.6, 3, 3), Vector3.new(0.4, 7.3, 0), BLACK)
	box(m, Vector3.new(1.2, 1.6, 2.6), Vector3.new(3, 7.8, 0), WHITE)
	beam(m, Vector3.new(-1.6, 8.4, 0), Vector3.new(-2.4, 13.4, 0), 0.55, skin)
	box(m, Vector3.new(1.1, 0.9, 0.8), Vector3.new(-2.6, 13.8, 0), skin)
	box(m, Vector3.new(0.8, 0.3, 0.5), Vector3.new(-3.4, 13.7, 0), rgb(240, 210, 180))
	box(m, Vector3.new(0.25, 0.25, 0.1), Vector3.new(-2.7, 14, -0.42), BLACK)
end

--==========================================================================
-- Landmarks
--==========================================================================

builders["Statue of Liberty"] = function(m)
	local green, dark, flame = rgb(115, 180, 150), rgb(90, 150, 125), rgb(255, 180, 60)
	box(m, Vector3.new(4.2, 1.2, 4.2), Vector3.new(0, 0.6, 0), dark)
	box(m, Vector3.new(3.4, 4.4, 2.6), Vector3.new(0, 3.4, 0), green)
	box(m, Vector3.new(2.9, 3, 2.3), Vector3.new(0, 7.1, 0), green)
	box(m, Vector3.new(3, 1, 2.2), Vector3.new(0, 9.1, 0), green)
	box(m, Vector3.new(0.8, 0.6, 0.8), Vector3.new(0, 9.9, 0), green)
	box(m, Vector3.new(1.4, 1.5, 1.4), Vector3.new(0, 10.95, 0), green)
	box(m, Vector3.new(1.6, 0.35, 1.6), Vector3.new(0, 11.55, 0), dark)
	for _, deg in ipairs({ -60, -30, 0, 30, 60 }) do
		local a = math.rad(deg)
		beam(m, Vector3.new(0, 11.8, -0.3), Vector3.new(math.sin(a) * 1.4, 11.8 + math.cos(a) * 1.4, -0.3), 0.2, green)
	end
	-- Raised torch arm on her right (+X, appears on the left on screen).
	beam(m, Vector3.new(1.4, 9.2, 0), Vector3.new(1.9, 13.2, 0), 0.6, green)
	beam(m, Vector3.new(1.9, 13.2, 0), Vector3.new(2, 14.4, 0), 0.35, dark)
	ball(m, 0.9, Vector3.new(2, 14.9, 0), flame, Enum.Material.Neon)
	beam(m, Vector3.new(-1.5, 9, 0), Vector3.new(-1.75, 7.8, -0.4), 0.5, green)
	box(m, Vector3.new(1.2, 1.7, 0.45), Vector3.new(-1.75, 7.6, -0.6), dark)
end

builders["Great Pyramid of Giza"] = function(m)
	local layers = 8
	for i = 0, layers - 1 do
		local width = 20 * (1 - i / layers)
		local shade = (i % 2 == 0) and rgb(215, 185, 120) or rgb(200, 170, 110)
		box(m, Vector3.new(width, 1.25, width), Vector3.new(0, 0.625 + i * 1.25, 0), shade, Enum.Material.Sandstone)
	end
end

builders["Eiffel Tower"] = function(m)
	local iron = rgb(115, 85, 60)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			beam(m, Vector3.new(sx * 4.2, 0, sz * 4.2), Vector3.new(sx * 2.4, 6.4, sz * 2.4), 1.1, iron)
			beam(m, Vector3.new(sx * 2.6, 6.9, sz * 2.6), Vector3.new(sx * 1.5, 12.6, sz * 1.5), 0.8, iron)
			beam(m, Vector3.new(sx * 1.5, 13, sz * 1.5), Vector3.new(sx * 0.45, 22, sz * 0.45), 0.55, iron)
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		box(m, Vector3.new(6.6, 0.4, 0.4), Vector3.new(0, 3.2, s * 3.3), iron)
		box(m, Vector3.new(0.4, 0.4, 6.6), Vector3.new(s * 3.3, 3.2, 0), iron)
	end
	box(m, Vector3.new(7.4, 0.7, 7.4), Vector3.new(0, 6.6, 0), iron)
	box(m, Vector3.new(4.2, 0.5, 4.2), Vector3.new(0, 12.8, 0), iron)
	box(m, Vector3.new(1.4, 0.4, 1.4), Vector3.new(0, 22.2, 0), iron)
	box(m, Vector3.new(1, 1.2, 1), Vector3.new(0, 23, 0), iron)
	beam(m, Vector3.new(0, 23.6, 0), Vector3.new(0, 26.5, 0), 0.25, iron)
end

builders["London Double-Decker Bus"] = function(m)
	local red, glass = rgb(200, 30, 35), rgb(40, 60, 80)
	box(m, Vector3.new(11, 4.4, 2.6), Vector3.new(0, 2.9, 0), red)
	box(m, Vector3.new(11.05, 0.35, 2.65), Vector3.new(0, 3.05, 0), WHITE)
	for i = 0, 4 do
		box(m, Vector3.new(1.6, 1.1, 0.1), Vector3.new(-3.2 + i * 1.9, 2.1, -1.32), glass)
		box(m, Vector3.new(1.7, 1.2, 0.1), Vector3.new(-4 + i * 2, 4.1, -1.32), glass)
	end
	box(m, Vector3.new(1.2, 2.4, 0.1), Vector3.new(-4.6, 1.9, -1.32), rgb(60, 60, 70))
	for _, y in ipairs({ 2.1, 4.1 }) do
		box(m, Vector3.new(0.1, 1.2, 2.2), Vector3.new(-5.52, y, 0), glass)
	end
	box(m, Vector3.new(0.1, 0.5, 1.6), Vector3.new(-5.52, 5, 0), BLACK)
	box(m, Vector3.new(0.1, 0.4, 0.5), Vector3.new(-5.52, 1.1, -0.8), rgb(255, 230, 120))
	for _, x in ipairs({ -3.4, 3.4 }) do
		for _, z in ipairs({ -1.2, 1.2 }) do
			zcyl(m, 0.6, 0.75, Vector3.new(x, 0.75, z), BLACK)
			zcyl(m, 0.62, 0.35, Vector3.new(x, 0.75, z), rgb(170, 170, 180))
		end
	end
end

builders["Big Ben Clock Tower"] = function(m)
	local stone, roof, gold = rgb(205, 185, 140), rgb(60, 70, 65), rgb(220, 180, 70)
	box(m, Vector3.new(4, 16, 4), Vector3.new(0, 8, 0), stone)
	for _, y in ipairs({ 6, 12 }) do
		box(m, Vector3.new(4.2, 0.4, 4.2), Vector3.new(0, y, 0), rgb(185, 165, 120))
	end
	box(m, Vector3.new(4.6, 4.4, 4.6), Vector3.new(0, 18.2, 0), stone)
	zcyl(m, 0.15, 1.85, Vector3.new(0, 18.2, -2.32), gold)
	zcyl(m, 0.2, 1.7, Vector3.new(0, 18.2, -2.36), WHITE)
	box(m, Vector3.new(0.15, 1.2, 0.1), Vector3.new(0, 18.7, -2.5), BLACK)
	box(m, Vector3.new(0.9, 0.15, 0.1), Vector3.new(0.35, 18.2, -2.5), BLACK)
	box(m, Vector3.new(4, 3, 4), Vector3.new(0, 21.9, 0), stone)
	box(m, Vector3.new(2.4, 1.8, 0.1), Vector3.new(0, 21.9, -2.02), roof)
	for i, w in ipairs({ 3.4, 2.6, 1.8 }) do
		box(m, Vector3.new(w, 1.4, w), Vector3.new(0, 23.4 + (i - 0.5) * 1.4, 0), roof)
	end
	box(m, Vector3.new(1, 1.6, 1), Vector3.new(0, 28.4, 0), roof)
	beam(m, Vector3.new(0, 29.2, 0), Vector3.new(0, 31.5, 0), 0.3, gold)
end

builders["Burj Khalifa"] = function(m)
	local glass = rgb(170, 195, 220)
	local y = 0
	for _, tier in ipairs({ { 5, 14 }, { 4, 12 }, { 3.2, 10 }, { 2.4, 8 }, { 1.6, 6 }, { 1, 4 } }) do
		box(m, Vector3.new(tier[1], tier[2], tier[1]), Vector3.new(0, y + tier[2] / 2, 0), glass, Enum.Material.Glass)
		y += tier[2]
	end
	for _, side in ipairs({ -1, 1 }) do
		box(m, Vector3.new(2.6, 9, 3), Vector3.new(side * 3.4, 4.5, 0), glass, Enum.Material.Glass)
		box(m, Vector3.new(2, 7, 2.4), Vector3.new(side * 2.6, 12.5, 0), glass, Enum.Material.Glass)
	end
	beam(m, Vector3.new(0, y, 0), Vector3.new(0, y + 8, 0), 0.35, rgb(200, 210, 220))
end

-- Rocky peak with a snow cap; the cap sits a hair proud of the rock so the
-- slopes don't z-fight.
local function mountain(m, cx, cz, halfWidth, height, depth, rock, snowFraction)
	peak(m, cx, 0, cz, halfWidth, height, depth, rock)
	local snowHeight = height * snowFraction
	peak(m, cx, height - snowHeight + 0.15, cz - 0.15, halfWidth * snowFraction, snowHeight, depth + 0.3, rgb(245, 248, 255))
end

builders["Mount Everest"] = function(m)
	mountain(m, -9, 3, 8, 9, 10, rgb(90, 82, 78), 0.3)
	mountain(m, 9, 2.5, 7, 8, 10, rgb(90, 82, 78), 0.3)
	mountain(m, 0, 0, 12, 14, 12, rgb(115, 105, 100), 0.36)
	return 14
end

--==========================================================================
-- Everyday objects
--==========================================================================

builders["Soda Can"] = function(m)
	local red, silver = rgb(215, 35, 40), rgb(200, 205, 215)
	vcyl(m, 6, 1.65, Vector3.new(0, 3.2, 0), red)
	vcyl(m, 0.8, 1.68, Vector3.new(0, 3.6, 0), WHITE)
	vcyl(m, 0.3, 1.55, Vector3.new(0, 0.15, 0), silver, Enum.Material.Metal)
	vcyl(m, 0.35, 1.6, Vector3.new(0, 6.35, 0), silver, Enum.Material.Metal)
	box(m, Vector3.new(0.9, 0.12, 0.5), Vector3.new(0.4, 6.58, 0), silver, Enum.Material.Metal)
end

builders["Basketball Hoop"] = function(m)
	local pole, orange = rgb(70, 75, 85), rgb(240, 110, 30)
	box(m, Vector3.new(2.5, 0.6, 2.5), Vector3.new(0, 0.3, 1.8), pole)
	box(m, Vector3.new(0.6, 11, 0.6), Vector3.new(0, 5.5, 1.8), pole)
	beam(m, Vector3.new(0, 10.6, 1.8), Vector3.new(0, 10.6, 0.4), 0.4, pole)
	box(m, Vector3.new(6, 3.6, 0.25), Vector3.new(0, 11.2, 0.3), WHITE)
	for _, y in ipairs({ 10.2, 11.6 }) do
		box(m, Vector3.new(2.4, 0.15, 0.1), Vector3.new(0, y, 0.13), rgb(220, 50, 50))
	end
	for _, x in ipairs({ -1.15, 1.15 }) do
		box(m, Vector3.new(0.15, 1.4, 0.1), Vector3.new(x, 10.9, 0.13), rgb(220, 50, 50))
	end
	local rimCenter = Vector3.new(0, 10, -0.9)
	for i = 0, 11 do
		local a = (i / 12) * math.pi * 2
		local pos = rimCenter + Vector3.new(math.cos(a) * 1.1, 0, math.sin(a) * 1.1)
		box(m, Vector3.new(0.6, 0.15, 0.15), CFrame.lookAt(pos, rimCenter), orange)
		if i % 2 == 0 then
			local low = rimCenter + Vector3.new(math.cos(a) * 0.7, -1.3, math.sin(a) * 0.7)
			beam(m, pos, low, 0.08, WHITE)
		end
	end
	ball(m, 1.5, Vector3.new(1.8, 0.75, -1), orange)
	-- Real-world size is the rim height.
	return 10
end

builders["A4 Sheet of Paper"] = function(m)
	box(m, Vector3.new(6.3, 8.9, 0.12), Vector3.new(0, 4.45, 0), WHITE)
	box(m, Vector3.new(3.4, 0.35, 0.05), Vector3.new(-0.8, 7.9, -0.08), rgb(60, 60, 70))
	for i = 1, 9 do
		box(m, Vector3.new(4.8 - (i % 3) * 0.6, 0.16, 0.05), Vector3.new(-0.3 - (i % 3) * 0.3, 7.2 - i * 0.7, -0.08), rgb(150, 150, 160))
	end
end

builders["Standard Door"] = function(m)
	local wood, panel, frame = rgb(150, 100, 60), rgb(125, 82, 48), rgb(240, 240, 235)
	box(m, Vector3.new(3.6, 8, 0.3), Vector3.new(0, 4, 0), wood)
	for _, x in ipairs({ -0.85, 0.85 }) do
		box(m, Vector3.new(1.2, 2.6, 0.1), Vector3.new(x, 6, -0.18), panel)
		box(m, Vector3.new(1.2, 3, 0.1), Vector3.new(x, 2.2, -0.18), panel)
	end
	for _, x in ipairs({ -2, 2 }) do
		box(m, Vector3.new(0.4, 8.4, 0.5), Vector3.new(x, 4.2, 0), frame)
	end
	box(m, Vector3.new(4.4, 0.4, 0.5), Vector3.new(0, 8.6, 0), frame)
	ball(m, 0.45, Vector3.new(1.3, 4, -0.3), rgb(220, 180, 70), Enum.Material.Metal)
	return 8
end

builders["Smartphone"] = function(m)
	box(m, Vector3.new(3, 6.2, 0.35), Vector3.new(0, 3.1, 0), rgb(30, 30, 35))
	box(m, Vector3.new(2.7, 5.6, 0.05), Vector3.new(0, 3.15, -0.18), rgb(70, 140, 240))
	box(m, Vector3.new(0.9, 0.18, 0.05), Vector3.new(0, 5.75, -0.21), rgb(30, 30, 35))
	local appColors = { rgb(255, 90, 90), rgb(90, 210, 110), rgb(255, 200, 60), rgb(160, 110, 255), WHITE, rgb(255, 140, 60) }
	local n = 0
	for row = 0, 3 do
		for col = 0, 2 do
			n += 1
			box(m, Vector3.new(0.55, 0.55, 0.05), Vector3.new(-0.8 + col * 0.8, 5.0 - row * 0.85, -0.21), appColors[(n - 1) % #appColors + 1])
		end
	end
end

builders["Refrigerator"] = function(m)
	local white, metal = rgb(235, 238, 242), rgb(170, 175, 185)
	box(m, Vector3.new(3.6, 9, 3.2), Vector3.new(0, 4.5, 0), white)
	box(m, Vector3.new(3.62, 0.08, 0.05), Vector3.new(0, 6.2, -1.62), rgb(150, 155, 165))
	box(m, Vector3.new(0.2, 1.6, 0.3), Vector3.new(1.4, 7.4, -1.75), metal, Enum.Material.Metal)
	box(m, Vector3.new(0.2, 3.2, 0.3), Vector3.new(1.4, 4.2, -1.75), metal, Enum.Material.Metal)
	for i, c in ipairs({ rgb(255, 90, 90), rgb(90, 160, 255), rgb(255, 210, 60) }) do
		box(m, Vector3.new(0.35, 0.35, 0.08), Vector3.new(-1.2 + i * 0.5, 4.8 - (i % 2) * 0.5, -1.64), c)
	end
end

builders["Coffee Mug"] = function(m)
	local mug = rgb(220, 60, 60)
	vcyl(m, 8, 3.6, Vector3.new(0, 4, 0), mug)
	vcyl(m, 0.05, 3.1, Vector3.new(0, 8.02, 0), rgb(90, 55, 30))
	box(m, Vector3.new(0.6, 4, 0.8), Vector3.new(4.6, 4, 0), mug)
	for _, y in ipairs({ 6, 2 }) do
		box(m, Vector3.new(1.2, 0.6, 0.8), Vector3.new(4.1, y, 0), mug)
	end
	return 8
end

builders["Upright Piano"] = function(m)
	local black = rgb(22, 22, 26)
	box(m, Vector3.new(8, 7.4, 2.2), Vector3.new(0, 3.7, 0.4), black)
	box(m, Vector3.new(7.6, 0.5, 1.6), Vector3.new(0, 3.6, -1.3), black)
	box(m, Vector3.new(7.2, 0.25, 1.4), Vector3.new(0, 3.95, -1.35), WHITE)
	local pattern = { 1, 1, 0, 1, 1, 1, 0 }
	for k = 0, 15 do
		if pattern[k % 7 + 1] == 1 then
			box(m, Vector3.new(0.18, 0.2, 0.8), Vector3.new(-3.3 + k * 0.43, 4.15, -1.1), black)
		end
	end
	for _, x in ipairs({ -3.6, 3.6 }) do
		box(m, Vector3.new(0.4, 3.4, 0.4), Vector3.new(x, 1.7, -1.7), black)
	end
	box(m, Vector3.new(4, 1, 0.15), Vector3.new(0, 5.2, -0.75), black)
	for _, x in ipairs({ -0.4, 0, 0.4 }) do
		box(m, Vector3.new(0.2, 0.1, 0.5), Vector3.new(x, 0.15, -0.9), rgb(220, 180, 70), Enum.Material.Metal)
	end
end

--==========================================================================
-- Space (diameter = 10 model units)
--==========================================================================

local PLANET_CENTER = Vector3.new(0, 5, 0)

builders["Earth"] = function(m)
	ball(m, 10, PLANET_CENTER, rgb(45, 105, 210))
	for _, c in ipairs({ { 20, -30, 4 }, { 35, 10, 3.5 }, { -10, 20, 3 }, { -25, -15, 3.2 }, { 50, -10, 2.8 }, { 0, 45, 2.6 }, { 15, -60, 2.5 } }) do
		ball(m, c[3], onSphere(PLANET_CENTER, 5 - c[3] * 0.38, c[1], c[2]), rgb(80, 170, 80))
	end
	for _, c in ipairs({ { 5, -10 }, { -35, 30 }, { 30, 40 } }) do
		ball(m, 1.6, onSphere(PLANET_CENTER, 4.5, c[1], c[2]), WHITE)
	end
	ball(m, 3.4, PLANET_CENTER + Vector3.new(0, 3.9, 0), WHITE)
	ball(m, 3, PLANET_CENTER - Vector3.new(0, 4.1, 0), WHITE)
	return 10
end

builders["Moon"] = function(m)
	ball(m, 10, PLANET_CENTER, rgb(185, 185, 190))
	for _, c in ipairs({ { 20, -20, 2.6 }, { -15, 10, 2 }, { 35, 25, 1.6 }, { -30, -35, 2.2 }, { 5, 35, 1.4 }, { -5, -5, 1.2 } }) do
		ball(m, c[3], onSphere(PLANET_CENTER, 5 - c[3] * 0.45, c[1], c[2]), rgb(145, 145, 152))
	end
	return 10
end

builders["Jupiter"] = function(m)
	ball(m, 10, PLANET_CENTER, rgb(215, 180, 140))
	local bands = {
		{ 3.2, rgb(190, 140, 100) },
		{ 1.6, rgb(230, 205, 170) },
		{ 0.4, rgb(175, 120, 85) },
		{ -1, rgb(225, 195, 160) },
		{ -2.4, rgb(185, 135, 95) },
		{ -3.6, rgb(220, 190, 150) },
	}
	for _, b in ipairs(bands) do
		local r = math.sqrt(25 - b[1] * b[1]) * 1.012
		vcyl(m, 0.8, r, PLANET_CENTER + Vector3.new(0, b[1], 0), b[2])
	end
	ball(m, 1.6, onSphere(PLANET_CENTER, 4.6, -22, -25), rgb(200, 90, 60))
	return 10
end

builders["The Sun"] = function(m)
	local core = ball(m, 10, PLANET_CENTER, rgb(255, 200, 50), Enum.Material.Neon)
	local glow = ball(m, 11.5, PLANET_CENTER, rgb(255, 150, 40), Enum.Material.Neon)
	glow.Transparency = 0.75
	glow.CastShadow = false
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 2
	light.Color = rgb(255, 210, 120)
	light.Parent = core
	return 10
end

--==========================================================================
-- Fallback & public API
--==========================================================================

local function fallback(m, icon, color)
	local block = box(m, Vector3.new(6, 10, 6), Vector3.new(0, 5, 0), color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(240, 400)
	gui.LightInfluence = 0
	gui.Parent = block
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.85, 0.85)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = icon or "?"
	label.Parent = gui
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = label
	return 10
end

function ObjectModels.build(name, icon, fallbackColor)
	local model = Instance.new("Model")
	model.Name = name
	local builder = builders[name]
	local measure
	if builder then
		measure = builder(model)
	else
		measure = fallback(model, icon, fallbackColor or Color3.fromRGB(200, 200, 200))
	end
	model.WorldPivot = CFrame.new(0, 0, 0)
	if not measure then
		local _, size = model:GetBoundingBox()
		measure = size.Y
	end
	return model, measure
end

function ObjectModels.has(name)
	return builders[name] ~= nil
end

return ObjectModels
