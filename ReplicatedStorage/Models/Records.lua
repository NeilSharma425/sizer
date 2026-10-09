--[[
	Records.lua
	ModuleScript: ReplicatedStorage.Models.Records

	Record breakers (the CRAZY category) for ObjectModels: the tiniest and biggest living things,
	prehistoric giants, huge machines, Earth's extremes and space giants.
	Side-on builders face -X like the animals; rings, galaxies and flyers
	face the camera. Every builder returns `measure`: the model-unit length
	that matches the size (and dimension) its fact in ExtraObjects uses.

	Usage: require(Records)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local Body = require(script.Parent:WaitForChild("BodyKit"))
local box, ball, beam, rod, slab, taper = Kit.box, Kit.ball, Kit.beam, Kit.rod, Kit.slab, Kit.taper
local quad, swimmer = Kit.quad, Kit.swimmer
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new
local NEON = Enum.Material.Neon
local ell, eyes = Body.ell, Body.eyes
local bird, flyer, snake, lizard = Body.bird, Body.flyer, Body.snake, Body.lizard
local insect, legs, critter, frog = Body.insect, Body.legs, Body.critter, Body.frog

-- Lumpy rock or ice: a cluster of balls around `center`.
local function lumpy(m, center, size, color, count, seed)
	ball(m, size, center, color)
	for i = 1, count or 6 do
		local a, b = (i * 2.39996 + (seed or 0)), (i * 1.3 + (seed or 0) * 0.7)
		local dir = V(math.cos(a) * math.cos(b), math.sin(b) * 0.8, math.sin(a) * math.cos(b))
		ball(m, size * (0.45 + (i % 3) * 0.08), center + dir * size * 0.3, color)
	end
end

-- Flat disc tilted back so its face shows to the camera (plates, pads).
local TILT = CFrame.Angles(math.rad(-60), 0, 0)
local function tilted(y)
	return CFrame.new(0, y, 0) * TILT
end

-- Ring of boxes in an ellipse (rx across, ry up) around `center`, facing
-- the camera; `squash` < 1 makes it look tipped back.
local function ellipseRing(m, center, rx, ry, thickness, segments, color, material)
	for i = 0, segments - 1 do
		local a0, a1 = 2 * math.pi * i / segments, 2 * math.pi * (i + 1) / segments
		local p0 = center + V(math.cos(a0) * rx, math.sin(a0) * ry, 0)
		local p1 = center + V(math.cos(a1) * rx, math.sin(a1) * ry, 0)
		slab(m, p0, p1, 0.2, thickness, color, material)
	end
end

-- A simple tree: tapering trunk and stacked leafy clumps.
local function tree(m, trunkH, r0, r1, crownFrom, crownTo, crownW, bark, leaves)
	taper(m, V(0, 0, 0), V(0, trunkH, 0), r0, r1, 6, bark)
	local n = 6
	for i = 0, n - 1 do
		local f = i / (n - 1)
		local y = crownFrom + (crownTo - crownFrom) * f
		local w = crownW * (1 - f * 0.55)
		ell(m, V(w, (crownTo - crownFrom) / n * 1.6, w), V((i % 2 - 0.5) * 0.3, y, 0), leaves)
	end
	return crownTo + (crownTo - crownFrom) / n * 0.8
end

-- Upright figure (a statue) about `h` tall, standing at height y0.
local function figure(m, h, y0, color, accent)
	local o = V(0, y0, 0)
	for _, s in ipairs({ -1, 1 }) do
		box(m, V(h * 0.1, h * 0.46, h * 0.1), o + V(0, h * 0.23, s * h * 0.07), color)
	end
	box(m, V(h * 0.16, h * 0.32, h * 0.28), o + V(0, h * 0.62, 0), accent or color)
	for _, s in ipairs({ -1, 1 }) do
		beam(m, o + V(0, h * 0.76, s * h * 0.18), o + V(-h * 0.02, h * 0.45, s * h * 0.2), h * 0.07, accent or color)
	end
	ball(m, h * 0.13, o + V(0, h * 0.86, 0), color)
	return y0 + h * 0.93
end

local function octopus(m, color)
	ell(m, V(3.6, 4, 3.2), V(0.6, 6, 0), color)
	ell(m, V(2.6, 2, 2.6), V(0, 3.6, 0), color)
	for _, s in ipairs({ -1, 1 }) do
		ball(m, 0.7, V(-1.2, 3.9, s * 0.8), rgb(250, 230, 150))
	end
	for i = 1, 8 do
		local x = -1 + 2 * (i - 1) / 7
		local z = (i % 2 == 0) and 0.6 or -0.6
		local mid = V(x * 2.6, 1.6, z)
		local tip = V(x * 5.2, 0.4 + (i % 2) * 0.5, z * 1.5)
		taper(m, V(x * 0.8, 2.8, z * 0.5), mid, 0.5, 0.35, 2, color)
		taper(m, mid, tip, 0.35, 0.1, 2, color)
	end
	return 10.4
end

local function squid(m, color, mantle)
	ell(m, V(mantle, 2.6, 2.6), V(mantle / 2, 1.6, 0), color)
	Kit.wedge(m, V(0.2, 2.2, 2.4), CFrame.new(mantle - 0.6, 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0), color)
	ball(m, 2, V(-0.6, 1.6, 0), color)
	eyes(m, V(-0.6, 1.6, 0), 1, 0.7, rgb(30, 30, 40))
	for i = 1, 8 do
		taper(m, V(-1.4, 1.6 + (i - 4.5) * 0.15, (i - 4.5) * 0.15), V(-7, 1.6 + (i - 4.5) * 0.4, (i - 4.5) * 0.3), 0.25, 0.08, 3, color)
	end
	for _, s in ipairs({ -1, 1 }) do
		taper(m, V(-1.4, 1.6, s * 0.3), V(-13, 1.6 + s * 0.7, s * 0.5), 0.12, 0.05, 4, color)
		ell(m, V(1.4, 0.5, 0.5), V(-13.4, 1.6 + s * 0.7, s * 0.5), color)
	end
	return mantle + 14.1
end

local function egg(m, color, spots)
	ell(m, V(2.6, 3.4, 2.6), V(0, 1.7, 0), color)
	if spots then
		for i = 1, 6 do
			ball(m, 0.25, V(-1.15, 1 + (i % 3) * 0.7, (i - 3.5) * 0.3), spots)
		end
	end
	return 3.4
end

local function galaxy(m, rx, ry, armColor, coreColor)
	ell(m, V(rx * 0.35, ry * 0.35, 1), V(0, ry + 1, 0), coreColor, NEON)
	for arm = 0, 1 do
		for i = 1, 22 do
			local t = i / 22
			local a = arm * math.pi + t * 3.6
			local r = 0.15 + t * 0.85
			local p = V(math.cos(a) * r * rx, ry + 1 + math.sin(a) * r * ry, 0)
			ball(m, 0.9 - t * 0.4, p, (i % 4 == 0) and WHITE or armColor, NEON)
		end
	end
	return rx * 2
end

return function(builders)
	--======================================================================
	-- Tiny things
	--======================================================================
	builders["Flu Virus"] = function(m)
		local c = V(0, 2.8, 0)
		ball(m, 4, c, rgb(120, 190, 140))
		for lat = -60, 60, 40 do
			for lon = 0, 330, 45 do
				local p = Kit.onSphere(c, 2, lat, lon + lat)
				local dir = (p - c).Unit
				rod(m, p, p + dir * 0.6, 0.1, rgb(220, 110, 140))
				ball(m, 0.35, p + dir * 0.7, rgb(240, 140, 170))
			end
		end
		return 5.4
	end

	builders["Grain of Salt"] = function(m)
		box(m, V(2.4, 2.4, 2.4), CFrame.new(0, 1.3, 0) * CFrame.Angles(0.15, 0.6, 0.1), rgb(245, 248, 252), Enum.Material.Glass)
		return 2.4
	end

	builders["E. coli Bacterium"] = function(m)
		local green = rgb(110, 175, 95)
		ell(m, V(6, 2, 2), V(0, 1.4, 0), green)
		for i = 1, 4 do
			local p = V(3, 1.4 + (i - 2.5) * 0.3, (i - 2.5) * 0.3)
			for k = 1, 4 do
				local q = p + V(1, (k % 2 == 0) and 0.4 or -0.4, 0)
				rod(m, p, q, 0.05, rgb(90, 140, 80))
				p = q
			end
		end
		return 6
	end

	builders["Red Blood Cell"] = function(m)
		ell(m, V(6, 6, 1.8), V(0, 3, 0), rgb(200, 40, 50))
		ell(m, V(2.8, 2.8, 0.5), V(0, 3, -0.75), rgb(160, 25, 35))
		return 6
	end

	builders["Human Hair (width)"] = function(m)
		Kit.vcyl(m, 3, 1, V(0, 1.5, 0), rgb(90, 60, 40))
		for i = 0, 3 do
			Kit.vcyl(m, 0.08, 1.02, V(0, 0.5 + i * 0.7, 0), rgb(70, 45, 30))
		end
		Kit.vcyl(m, 0.05, 0.9, V(0, 3.02, 0), rgb(130, 95, 70))
		return 2
	end

	builders["Dust Mite"] = function(m)
		legs(m, { body = 2, h = 1.4, legH = 0.6, reach = 1.6, legT = 0.12, color = rgb(230, 215, 190), pairs = 4, abdomen = { 2.2, 1.6 } })
		return 4
	end

	builders["Flea"] = function(m)
		local brown = rgb(120, 70, 40)
		local measure = insect(m, { len = 4, h = 2, legH = 0.6, color = brown, headFrac = 0.18, thoraxFrac = 0.3, abdomen = rgb(140, 85, 50), legColor = brown, antenna = 0.4 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(0.6, 1.2, s * 0.6), V(1.8, 2.6, s * 0.8), 0.3, brown)
			beam(m, V(1.8, 2.6, s * 0.8), V(2.4, 0.1, s * 0.8), 0.22, brown)
		end
		return measure
	end

	builders["Tardigrade"] = function(m)
		local skin = rgb(215, 190, 160)
		for i = 0, 3 do
			ell(m, V(1.8, 2.2 - math.abs(i - 1.5) * 0.25, 2.2), V(-2.2 + i * 1.5, 1.6, 0), skin)
		end
		ell(m, V(1.4, 1.6, 1.6), V(-3.3, 1.7, 0), skin)
		eyes(m, V(-3.3, 1.8, 0), 0.7, 0.18)
		Kit.zcyl(m, 0.3, 0.3, V(-4, 1.5, 0), rgb(180, 150, 130))
		for i = 0, 3 do
			for _, s in ipairs({ -1, 1 }) do
				box(m, V(0.7, 0.9, 0.7), V(-2.2 + i * 1.5, 0.45, s * 0.8), skin)
				for c = -1, 1 do
					beam(m, V(-2.2 + i * 1.5 + c * 0.2, 0.05, s * 0.8), V(-2.5 + i * 1.5 + c * 0.2, 0.05, s * 1.2), 0.08, rgb(90, 70, 60))
				end
			end
		end
		return 6.2
	end

	builders["Grain of Sand"] = function(m)
		lumpy(m, V(0, 1.3, 0), 2.4, rgb(220, 195, 140), 5, 1)
		return 3
	end

	builders["Smallest Computer"] = function(m)
		box(m, V(3, 1, 3), V(0, 0.5, 0), rgb(40, 45, 60))
		box(m, V(2.2, 0.1, 1.2), V(0, 1.05, -0.5), rgb(60, 90, 200))
		for i = -1, 1 do
			box(m, V(0.4, 0.12, 0.4), V(i * 0.9, 1.05, 0.9), rgb(230, 190, 70))
		end
		return 3
	end

	builders["Nano-Chameleon"] = function(m)
		local measure = lizard(m, { len = 2.6, h = 1.4, legH = 0.5, w = 0.9, tail = 2, head = { 1.3, 1.2 }, color = rgb(160, 120, 80), eye = rgb(240, 140, 40) })
		ball(m, 0.9, V(3.1, 0.5, 0), rgb(160, 120, 80))
		return measure
	end

	builders["Pygmy Seahorse"] = function(m)
		local pink = rgb(240, 140, 170)
		taper(m, V(0.8, 5, 0), V(0.6, 2.4, 0), 0.9, 0.7, 3, pink)
		ell(m, V(1.6, 2.4, 1.2), V(0.4, 3.6, 0), pink)
		ball(m, 1.2, V(0.8, 5.6, 0), pink)
		beam(m, V(0.3, 5.6, 0), V(-0.6, 5.4, 0), 0.4, pink)
		eyes(m, V(0.8, 5.6, 0), 0.6, 0.25)
		for i = 0, 5 do
			local a = i * 0.9
			ball(m, 0.6 - i * 0.07, V(0.8 + math.sin(a) * 0.7 * (1 - i / 7), 2.2 - i * 0.35, 0), pink)
		end
		for i = 1, 8 do
			ball(m, 0.35, V(0.2 + (i % 3) * 0.4, 2.6 + i * 0.35, (i % 2 - 0.5) * 1.1), rgb(250, 90, 130))
		end
		return 6.2
	end

	builders["Bumblebee Bat"] = function(m)
		local brown = rgb(110, 85, 70)
		local measure = critter(m, { len = 3, h = 1.6, color = brown, head = 1.2, ear = { 0.6, 1.1 }, nose = rgb(90, 60, 55) })
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(0, 1.6, s * 0.6), V(1.6, 2.6, s * 2.4), 1.4, 0.1, rgb(80, 60, 55))
		end
		return measure
	end

	builders["Etruscan Shrew"] = function(m)
		local measure = critter(m, { len = 3.2, h = 1.3, color = rgb(140, 115, 95), head = 1, ear = { 0.35, 0.3 }, tail = { 2, -10, 0.12 }, nose = rgb(230, 160, 160) })
		beam(m, V(-2, 1.2, 0), V(-2.8, 1.05, 0), 0.3, rgb(160, 130, 110))
		return measure
	end

	builders["Bee Hummingbird"] = function(m)
		return bird(m, { legH = 0.3, body = { 1.8, 0.9, 0.8 }, tilt = 30, color = rgb(60, 140, 200), belly = rgb(225, 225, 225), neck = 0.1, head = 0.7, headColor = rgb(230, 50, 90), beak = { 0.9, BLACK, -0.1, 0.12 }, tail = { 0.7, -30, 0.5 }, legColor = BLACK, measure = "length" })
	end

	builders["Mouse Lemur"] = function(m)
		local measure = critter(m, { len = 2.6, h = 1.5, color = rgb(170, 120, 80), belly = rgb(230, 215, 190), head = 1.3, ear = { 0.6, 0.7 }, tail = { 3, 30, 0.2 }, nose = rgb(90, 60, 50) })
		for _, s in ipairs({ -1, 1 }) do
			ball(m, 0.45, V(-1.65, 2.1, s * 0.4), rgb(255, 200, 60))
			ball(m, 0.25, V(-1.85, 2.1, s * 0.42), BLACK)
		end
		return measure
	end

	builders["Pygmy Marmoset"] = function(m)
		local fur = rgb(150, 125, 85)
		local measure = critter(m, { len = 3, h = 1.8, color = fur, head = 1.6, ear = { 0.3, 0.3 }, nose = BLACK })
		for i = 0, 7 do
			box(m, V(0.4, 0.45, 0.45), V(1.6 + i * 0.3, 2 - i * 0.25, 0), i % 2 == 0 and rgb(90, 75, 55) or fur)
		end
		ball(m, 2, V(-1.4, 1.95, 0), rgb(175, 150, 110))
		return measure
	end

	builders["Thumbelina the Horse"] = function(m)
		return quad(m, { len = 5, bodyH = 2.6, legH = 2, width = 2.2, color = rgb(120, 70, 45), headLen = 2.2, headH = 1.6, neck = 1.6, snout = rgb(90, 55, 35), mane = rgb(60, 35, 25), ear = { 0.4, 0.6 }, tail = 2.4, tailColor = rgb(60, 35, 25) })
	end

	builders["Hummingbird Egg"] = function(m)
		return egg(m, rgb(250, 250, 245))
	end

	--======================================================================
	-- Giants of today
	--======================================================================
	builders["Goliath Beetle"] = function(m)
		local measure = insect(m, { len = 6, h = 2, legH = 0.8, color = BLACK, headFrac = 0.15, thoraxFrac = 0.3, abdomen = rgb(90, 50, 35) })
		for i = 0, 2 do
			box(m, V(0.3, 0.6, 1.62), V(-1.2 + i * 0.4, 2.2, 0), WHITE)
		end
		return measure
	end

	builders["Goliath Frog"] = function(m)
		return frog(m, 1.6, rgb(95, 120, 70), rgb(75, 95, 55))
	end

	builders["Giant Isopod"] = function(m)
		local shell = rgb(190, 175, 200)
		for i = 0, 7 do
			ell(m, V(1.1, 1.8 - math.abs(i - 3.5) * 0.12, 2.4), V(-3.2 + i * 0.95, 1.1, 0), i % 2 == 0 and shell or rgb(175, 160, 185))
		end
		ell(m, V(1.4, 1.4, 2), V(-4, 1, 0), shell)
		eyes(m, V(-4, 1.1, 0), 0.7, 0.25)
		for i = 0, 6 do
			for _, s in ipairs({ -1, 1 }) do
				rod(m, V(-3 + i * 0.95, 0.5, s * 0.9), V(-3.2 + i * 0.95, 0.05, s * 1.5), 0.08, rgb(170, 150, 170))
			end
		end
		for _, s in ipairs({ -1, 1 }) do
			rod(m, V(-4.6, 1.2, s * 0.4), V(-6, 1.8, s * 1), 0.06, shell)
		end
		return 9.4
	end

	builders["Coconut Crab"] = function(m)
		local blue = rgb(70, 80, 160)
		local measure = legs(m, { body = 3, h = 2, legH = 1.6, reach = 3.8, legT = 0.3, color = blue, pairs = 4, abdomen = { 2.6, 1.8 }, abdomenColor = rgb(200, 110, 60), legColor = rgb(200, 110, 60) })
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(2.4, 1.2, 1), V(-3, 1.6, s * 1.4), blue)
		end
		return measure
	end

	builders["Ostrich Egg"] = function(m)
		return egg(m, rgb(245, 235, 210))
	end

	builders["Giant Clam"] = function(m)
		ell(m, V(8, 2.4, 5), V(0, 1.2, 0), rgb(170, 165, 150))
		ell(m, V(7.6, 1, 4.6), V(0, 2.4, 0), rgb(60, 110, 200))
		for i = 1, 8 do
			ball(m, 0.4, V(-3 + i * 0.7, 2.75, -1.6 + (i % 3) * 0.6), rgb(120, 230, 210), NEON)
		end
		ell(m, V(8, 1.6, 5), CFrame.new(0.4, 3.4, 0) * CFrame.Angles(0, 0, -0.15), rgb(180, 175, 160))
		for i = -3, 3 do
			box(m, V(0.3, 0.3, 5.1), V(i * 1.1, 4.1 - math.abs(i) * 0.2, 0), rgb(150, 145, 130))
		end
		return 8
	end

	builders["Ocean Sunfish"] = function(m)
		local gray = rgb(160, 165, 175)
		ell(m, V(6, 5.6, 1.4), V(0, 4.5, 0), gray)
		Kit.wedge(m, V(0.3, 3.4, 1.4), CFrame.new(1.6, 8.6, 0) * CFrame.Angles(0, math.pi / 2, 0), gray)
		Kit.wedge(m, V(0.3, 3.4, 1.4), CFrame.new(1.6, 0.4, 0) * CFrame.Angles(math.pi, math.pi / 2, 0), gray)
		ell(m, V(1.2, 5, 1.3), V(3.2, 4.5, 0), rgb(140, 145, 155))
		ball(m, 0.6, V(-2, 5.2, -0.6), BLACK)
		ball(m, 0.5, V(-2.9, 4.4, 0), rgb(120, 125, 135))
		return 6.8
	end

	builders["Chinese Giant Salamander"] = function(m)
		return lizard(m, { len = 6, h = 1.4, legH = 0.6, w = 2, tail = 5, head = { 2.4, 1 }, color = rgb(100, 80, 60), belly = rgb(130, 110, 85) })
	end

	builders["Giant Tube Worm"] = function(m)
		for i = -1, 1 do
			local h = 8 - math.abs(i) * 1.4
			Kit.vcyl(m, h, 0.5, V(i * 1.3, h / 2, i * 0.4), rgb(235, 230, 220))
			ell(m, V(1.4, 1.6, 1.4), V(i * 1.3, h + 0.7, i * 0.4), rgb(220, 40, 50))
		end
		return 8.8
	end

	builders["Giant Pacific Octopus"] = function(m)
		return octopus(m, rgb(190, 80, 60))
	end

	builders["Reticulated Python"] = function(m)
		return snake(m, { len = 30, thick = 1.2, color = rgb(170, 140, 80), pattern = rgb(60, 50, 35) })
	end

	builders["Colossal Squid"] = function(m)
		return squid(m, rgb(170, 60, 60), 12)
	end

	builders["Lion's Mane Jellyfish"] = function(m)
		local bell = ell(m, V(7, 3.4, 7), V(0, 31, 0), rgb(220, 110, 60))
		bell.Transparency = 0.15
		for i = -6, 6 do
			rod(m, V(i * 0.5, 29.5, (i % 3 - 1) * 0.6), V(i * 0.7 + math.sin(i) * 0.6, 0.2, (i % 3 - 1) * 0.8), 0.05, rgb(240, 170, 120))
		end
		for i = -2, 2 do
			rod(m, V(i * 0.6, 29.5, 0), V(i * 0.8, 22, 0), 0.25, rgb(200, 80, 50))
		end
		return 32.7
	end

	builders["Corpse Flower"] = function(m)
		Kit.vcyl(m, 2, 0.7, V(0, 1, 0), rgb(80, 120, 60))
		Kit.cone(m, 4.6, 3, 2.2, V(0, 1.6, 0), rgb(120, 30, 60), nil, 5)
		taper(m, V(0, 2, 0), V(0, 12, 0), 0.9, 0.4, 5, rgb(230, 200, 90))
		return 12.2
	end

	builders["Giant Water Lily Pad"] = function(m)
		local cf = tilted(2.6)
		Kit.cylinder(m, 0.3, 5, cf * CFrame.Angles(0, 0, math.pi / 2), rgb(80, 150, 70))
		for i = 0, 23 do
			local a = i * math.pi / 12
			box(m, V(1.4, 0.7, 0.3), cf * CFrame.new(math.cos(a) * 5, 0.3, math.sin(a) * 5) * CFrame.Angles(0, -a + math.pi / 2, 0), rgb(150, 50, 70))
		end
		ell(m, V(1.6, 1.2, 1.6), cf * CFrame.new(1.4, 0.8, -1), rgb(250, 240, 245))
		return 10
	end

	builders["Giant Kelp"] = function(m)
		local p = V(0, 0, 0)
		for i = 1, 10 do
			local q = V(math.sin(i * 0.9) * 1.2, i * 3, 0)
			rod(m, p, q, 0.15, rgb(120, 100, 40))
			ell(m, V(2.6, 0.9, 0.1), CFrame.new(q + V((i % 2 == 0) and 1.2 or -1.2, -0.6, 0)) * CFrame.Angles(0, 0, (i % 2 == 0) and -0.5 or 0.5), rgb(150, 130, 50))
			ball(m, 0.5, q, rgb(170, 150, 60))
			p = q
		end
		return 30
	end

	builders["General Sherman Tree"] = function(m)
		return tree(m, 30, 3.2, 1.4, 16, 32, 13, rgb(140, 70, 50), rgb(60, 110, 60))
	end

	builders["Hyperion Tree"] = function(m)
		return tree(m, 42, 1.6, 0.5, 24, 44, 9, rgb(150, 75, 50), rgb(55, 105, 60))
	end

	--======================================================================
	-- Prehistoric giants
	--======================================================================
	builders["Argentinosaurus"] = function(m)
		local green = rgb(120, 130, 100)
		for _, x in ipairs({ -3.4, 3.4 }) do
			for _, z in ipairs({ -1.6, 1.6 }) do
				box(m, V(1.8, 8, 1.8), V(x, 4, z), green)
			end
		end
		ell(m, V(12, 6.4, 5), V(0, 10.4, 0), green)
		taper(m, V(-5, 11.5, 0), V(-14, 18, 0), 1.4, 0.8, 5, green)
		box(m, V(2.4, 1.3, 1.2), V(-15, 18.2, 0), green)
		eyes(m, V(-14.8, 18.4, 0), 0.6, 0.25)
		taper(m, V(5, 10.5, 0), V(20, 3, 0), 1.6, 0.2, 6, green)
		return 36.2
	end

	builders["Titanoboa"] = function(m)
		return snake(m, { len = 40, thick = 2.6, color = rgb(80, 85, 60), pattern = rgb(45, 45, 35) })
	end

	builders["Quetzalcoatlus"] = function(m)
		local measure = flyer(m, { span = 30, bodyL = 3.4, bodyW = 1.6, color = rgb(220, 210, 190), wing = rgb(180, 120, 90), chord = 3, tipChord = 1.4, sweep = 1.4, head = 1.4, beak = { 4, rgb(230, 210, 170) } })
		beam(m, V(0, 6.8, 0), V(0, 5.6, 0.4), 0.5, rgb(200, 80, 60))
		return measure
	end

	builders["Elephant Bird"] = function(m)
		return bird(m, { legH = 5.4, body = { 5, 4.4, 3.8 }, tilt = 10, color = rgb(110, 85, 60), neck = 3.4, head = 1.2, beak = { 0.8, rgb(90, 80, 70) }, tail = { 0.6, -40 }, legColor = rgb(120, 110, 100) })
	end

	builders["Irish Elk"] = function(m)
		local o = { len = 8, bodyH = 3.6, legH = 6, width = 2.6, color = rgb(140, 100, 65), legColor = rgb(110, 80, 55), headLen = 2.8, headH = 1.8, neck = 2.6, snout = rgb(90, 65, 45), mane = rgb(100, 70, 45), ear = { 0.4, 0.8 }, tail = 0.8 }
		local measure = quad(m, o)
		local hx, hy = Body.quadHead(o)
		for _, z in ipairs({ -1, 1 }) do
			box(m, V(4.4, 1.6, 0.3), CFrame.new(hx + 1.4, hy + 2, z * 3.2) * CFrame.Angles(z * 0.3, 0, -0.2), rgb(220, 205, 175))
			for i = 0, 4 do
				box(m, V(0.3, 1.2, 0.3), V(hx - 0.4 + i * 0.9, hy + 3.1 - i * 0.15, z * 3.4), rgb(220, 205, 175))
			end
			beam(m, V(hx + 0.4, hy + 0.9, z * 0.5), V(hx + 1, hy + 1.8, z * 2.6), 0.3, rgb(220, 205, 175))
		end
		return measure
	end

	builders["Giant Moa"] = function(m)
		return bird(m, { legH = 5, body = { 4.4, 3.6, 3.2 }, tilt = 15, color = rgb(120, 90, 60), neck = 5, head = 0.9, beak = { 0.6, rgb(100, 90, 80) }, tail = { 0.4, -40 }, legColor = rgb(110, 100, 90) })
	end

	--======================================================================
	-- Giant machines and buildings
	--======================================================================
	builders["Seawise Giant"] = function(m)
		box(m, V(40, 2.4, 6), V(0, 1.2, 0), rgb(150, 40, 40))
		box(m, V(40, 2, 6), V(0, 3.4, 0), rgb(40, 45, 60))
		Kit.wedge(m, V(6, 4.4, 3), CFrame.new(-21.5, 2.2, 0) * CFrame.Angles(0, -math.pi / 2, 0), rgb(40, 45, 60))
		box(m, V(4, 5, 5), V(17, 6.9, 0), WHITE)
		Kit.windows(m, 15.2, 18.8, 5.5, 9, -2.55, 4, 3, rgb(60, 90, 140))
		box(m, V(1.6, 3, 1.6), V(18.4, 10.8, 0), rgb(220, 120, 40))
		return 43
	end

	builders["Antonov An-225"] = function(m)
		local white = rgb(235, 235, 240)
		ell(m, V(2.6, 22, 2.4), V(0, 12, 0), white)
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(s * 1, 13, 0.1), V(s * 12, 11.4, 0.1), 0.2, 3, white)
			for k = 1, 3 do
				Kit.zcyl(m, 2, 0.5, V(s * (2.4 + k * 2.4), 12.4 - k * 0.3, -0.4), rgb(80, 85, 95))
			end
			slab(m, V(s * 0.6, 2.4, 0.1), V(s * 4.6, 2.2, 0.1), 0.15, 1.4, white)
			box(m, V(0.3, 2, 1.6), V(s * 4.6, 2.6, 0.1), rgb(240, 200, 60))
		end
		box(m, V(2.2, 0.6, 0.3), V(0, 20, -1.2), rgb(40, 90, 200))
		return 24
	end

	builders["Hindenburg"] = function(m)
		local silver = rgb(200, 205, 210)
		ell(m, V(30, 5, 5), V(0, 4.5, 0), silver)
		box(m, V(3, 1, 1.2), V(-8, 1.6, 0), rgb(170, 175, 180))
		for _, s in ipairs({ -1, 1 }) do
			Kit.wedge(m, V(0.2, 2.6, 3), CFrame.new(13, 4.5 + s * 2.6, 0) * CFrame.Angles(s > 0 and 0 or math.pi, math.pi / 2, 0), silver)
		end
		box(m, V(0.8, 2.4, 0.2), V(12.6, 6.4, -0.1), rgb(200, 40, 40))
		return 30
	end

	builders["Bagger 293"] = function(m)
		local gray = rgb(150, 150, 140)
		for _, x in ipairs({ -3, 3 }) do
			box(m, V(5, 1.6, 6), V(x, 0.8, 0), rgb(60, 60, 60))
		end
		box(m, V(9, 4, 5), V(0, 3.6, 0), gray)
		beam(m, V(-3, 5, 0), V(-11, 9, 0), 1, gray)
		local hub = V(-12.5, 9.6, 0)
		Kit.ring(m, hub, 3.4, 0.5, 1, 16, rgb(220, 90, 40))
		for i = 0, 9 do
			local a = i * math.pi / 5
			box(m, V(1, 1, 1.2), hub + V(math.cos(a) * 3.8, math.sin(a) * 3.8, 0), rgb(200, 70, 30))
		end
		beam(m, V(3, 5, 0), V(14, 2.6, 0), 0.8, gray)
		box(m, V(2, 8, 2), V(0, 9.6, 0), gray)
		for _, s in ipairs({ -1, 1 }) do
			rod(m, V(0, 13.4, 0), V(s * 10, 6 + s * 2, 0), 0.06, rgb(60, 60, 60))
		end
		return 30
	end

	builders["BelAZ 75710"] = function(m)
		local yellow = rgb(240, 190, 40)
		for _, x in ipairs({ -3.4, 1.6, 3.6 }) do
			Kit.wheel(m, V(x, 1.6, -1.6), 1.6, 1.2, BLACK, rgb(120, 120, 120))
		end
		box(m, V(10, 1, 3.6), V(0, 2.6, 0), rgb(60, 60, 60))
		box(m, V(6.4, 3, 3.8), V(1.6, 4.6, 0), yellow)
		box(m, V(2.4, 2.2, 2.6), V(-3.6, 4.2, 0), yellow)
		box(m, V(1.6, 1, 0.1), V(-3.6, 4.6, -1.35), rgb(120, 170, 220))
		return 10
	end

	builders["Starship Rocket"] = function(m)
		local steel = rgb(200, 205, 212)
		Kit.vcyl(m, 14, 1.8, V(0, 7, 0), steel)
		for i = 0, 3 do
			box(m, V(1, 0.3, 1), V(math.cos(i * math.pi / 2) * 1.8, 13.6, math.sin(i * math.pi / 2) * 1.8), rgb(120, 125, 130))
		end
		Kit.vcyl(m, 8.6, 1.8, V(0, 18.3, 0), steel)
		Kit.cone(m, 2.4, 1.8, 0.3, V(0, 22.6, 0), steel, nil, 5)
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(1.4, 1.6, 0.2), V(s * 2, 21, 0), rgb(80, 80, 85))
			box(m, V(1.6, 2, 0.2), V(s * 2, 15.6, 0), rgb(80, 80, 85))
		end
		return 25
	end

	builders["Kingda Ka"] = function(m)
		local green = rgb(70, 190, 80)
		for _, z in ipairs({ -0.6, 0.6 }) do
			box(m, V(0.4, 26, 0.4), V(-2.6, 13, z), green)
			box(m, V(0.4, 26, 0.4), V(2.6, 13, z), green)
			local prev = V(-2.6, 26, z)
			for i = 1, 8 do
				local a = math.pi - i * math.pi / 8
				local q = V(math.cos(a) * 2.6, 26 + math.sin(a) * 3.4, z)
				beam(m, prev, q, 0.4, green)
				prev = q
			end
		end
		for y = 2, 24, 4 do
			box(m, V(0.3, 0.3, 1.6), V(-3, y, 0), rgb(230, 230, 230))
		end
		box(m, V(16, 0.6, 1.6), V(-10.6, 0.3, 0), green)
		return 29.6
	end

	builders["Ain Dubai"] = function(m)
		local hub = V(0, 13, 0)
		Kit.ring(m, hub, 11, 0.5, 0.6, 32, rgb(230, 230, 235))
		for i = 0, 11 do
			local a = i * math.pi / 6
			rod(m, hub, hub + V(math.cos(a) * 11, math.sin(a) * 11, 0), 0.06, rgb(180, 185, 190))
			ell(m, V(1.2, 0.8, 0.8), hub + V(math.cos(a) * 11.6, math.sin(a) * 11.6, -0.3), rgb(150, 200, 240))
		end
		for _, x in ipairs({ -1, 1 }) do
			beam(m, V(x * 5, 0, 0.8), hub + V(0, 0, 0.8), 0.8, rgb(200, 200, 205))
		end
		return 25
	end

	builders["Statue of Unity"] = function(m)
		box(m, V(8, 1.6, 8), V(0, 0.8, 0), rgb(190, 185, 170))
		return figure(m, 18, 1.6, rgb(150, 120, 70), rgb(140, 110, 60)) - 1.6 -- the statue itself, not the base
	end

	builders["Three Gorges Dam"] = function(m)
		box(m, V(30, 4, 2.4), V(0, 2, 0), rgb(200, 200, 195))
		for i = -6, 6 do
			box(m, V(0.9, 2.6, 0.1), V(i * 1.6, 2, -1.25), rgb(150, 150, 150))
		end
		box(m, V(30, 3.2, 4), V(0, 1.6, 3.2), rgb(70, 130, 190))
		return 30
	end

	builders["Large Hadron Collider"] = function(m)
		Kit.ring(m, V(0, 8.6, 0), 8, 0.5, 0.5, 40, rgb(70, 140, 230), NEON)
		for _, a in ipairs({ 0, 1.6, 3.2, 4.7 }) do
			box(m, V(1.6, 1.6, 1.4), V(math.cos(a) * 8, 8.6 + math.sin(a) * 8, 0), rgb(200, 200, 205))
		end
		Kit.ring(m, V(0, 8.6, 0.3), 8.3, 0.2, 0.3, 40, rgb(40, 60, 110))
		return 16.5
	end

	builders["Peel P50"] = function(m)
		ell(m, V(4, 2.2, 2.6), V(0, 1.6, 0), rgb(220, 40, 40))
		ell(m, V(1.6, 1, 2.3), V(-0.6, 2.3, 0), rgb(150, 200, 230))
		for _, p in ipairs({ V(-1.2, 0.5, -1.2), V(-1.2, 0.5, 1.2), V(1.4, 0.5, 0) }) do
			Kit.wheel(m, p, 0.5, 0.4, BLACK, rgb(200, 200, 200))
		end
		return 4
	end

	--======================================================================
	-- Earth's extremes
	--======================================================================
	builders["Mariana Trench"] = function(m)
		local rock = rgb(80, 75, 70)
		box(m, V(12, 1, 6), V(0, 0.5, 0), rock)
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(s * 1, 1, 0), V(s * 5, 12, 0), 6, 4, rock)
		end
		local water = box(m, V(14, 12, 6), V(0, 6, 0.1), rgb(40, 90, 170))
		water.Transparency = 0.55
		return 12
	end

	builders["Mauna Kea"] = function(m)
		Kit.cone(m, 12, 14, 1.2, V(0, 0, 0), rgb(120, 85, 65), nil, 8)
		Kit.cone(m, 2, 2.6, 0.8, V(0, 10, 0), WHITE, nil, 3)
		local sea = box(m, V(32, 6.6, 30), V(0, 3.3, 0), rgb(40, 110, 190))
		sea.Transparency = 0.5
		return 12
	end

	builders["Angel Falls"] = function(m)
		box(m, V(8, 14, 6), V(2, 7, 0), rgb(110, 85, 60))
		box(m, V(8.2, 0.8, 6.2), V(2, 14.4, 0), rgb(70, 140, 60))
		local fall = box(m, V(1.6, 14, 0.4), V(-2.2, 7, -1), rgb(220, 240, 255))
		fall.Transparency = 0.15
		for i = 0, 4 do
			ball(m, 1.6, V(-2.2 + (i - 2) * 0.8, 0.6, -1), WHITE).Transparency = 0.3
		end
		return 14.4
	end

	builders["Grand Canyon"] = function(m)
		local layers = { rgb(190, 90, 50), rgb(220, 140, 80), rgb(170, 70, 45), rgb(230, 170, 110) }
		for _, s in ipairs({ -1, 1 }) do
			for i = 1, 4 do
				local w = 6 - i * 0.6
				box(m, V(w, 1.5, 6), V(s * (2 + w / 2 + (4 - i) * 0.25), (i - 0.5) * 1.5, 0), layers[i])
			end
		end
		box(m, V(4, 0.3, 6), V(0, 0.15, 0), rgb(70, 140, 170))
		return 6
	end

	builders["Sahara Desert"] = function(m)
		box(m, V(20, 0.6, 6), V(0, 0.3, 0), rgb(230, 195, 130))
		for i = -3, 3 do
			Kit.dome(m, 2 + (i % 2) * 0.8, V(i * 2.8, 0.6, (i % 3 - 1) * 1.4), rgb(225, 185, 115), nil, 4)
		end
		return 20
	end

	builders["Iceberg B-15"] = function(m)
		box(m, V(20, 2.6, 8), V(0, 2.8, 0), rgb(235, 245, 250))
		box(m, V(20.2, 0.4, 8.2), V(0, 4.1, 0), WHITE)
		local sea = box(m, V(24, 1.6, 10), V(0, 0.8, 0), rgb(50, 110, 170))
		sea.Transparency = 0.4
		return 20
	end

	builders["Giant Hailstone"] = function(m)
		lumpy(m, V(0, 1.6, 0), 2.6, rgb(225, 235, 245), 7, 2)
		return 3.2
	end

	builders["Largest Raindrop"] = function(m)
		local drop = ell(m, V(2.2, 1.8, 2.2), V(0, 1, 0), rgb(110, 170, 240))
		drop.Transparency = 0.25
		return 2.2
	end

	builders["Lightning Bolt"] = function(m)
		local pts = { V(0, 20, 0), V(-1.6, 15, 0), V(0.8, 14, 0), V(-1, 8, 0), V(1, 7.4, 0), V(-0.6, 0, 0) }
		for i = 1, #pts - 1 do
			slab(m, pts[i], pts[i + 1], 0.2, 0.8, rgb(255, 240, 120), NEON)
		end
		return 20
	end

	builders["Naica Giant Crystal"] = function(m)
		local function crystal(len, w, cf)
			local p = box(m, V(len, w, w), cf, rgb(235, 240, 245), Enum.Material.Glass)
			p.Transparency = 0.2
		end
		crystal(14, 1.6, CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, 0.18))
		crystal(9, 1.2, CFrame.new(1, 1.6, 1.2) * CFrame.Angles(0, 0.4, -0.25))
		crystal(7, 1, CFrame.new(-2, 1.2, -1.4) * CFrame.Angles(0, -0.5, 0.3))
		box(m, V(16, 0.6, 6), V(0, 0.3, 0), rgb(160, 120, 90))
		return 14
	end

	builders["Cullinan Diamond"] = function(m)
		local ice = rgb(225, 240, 250)
		Kit.cone(m, 1.6, 1.8, 0.4, V(0, 1.8, 0), ice, Enum.Material.Glass, 4)
		Kit.cone(m, 1.8, 0.2, 1.8, V(0, 0, 0), ice, Enum.Material.Glass, 4)
		return 3.4
	end

	builders["Chicxulub Asteroid"] = function(m)
		lumpy(m, V(0, 3, 0), 5, rgb(110, 105, 100), 7, 3)
		for i = 1, 4 do
			ball(m, 0.9, V(-2.2, 2 + i * 0.6, (i - 2.5) * 0.9), rgb(80, 75, 70))
		end
		return 6
	end

	--======================================================================
	-- Space giants
	--======================================================================
	builders["Neutron Star"] = function(m)
		ball(m, 4, V(0, 6, 0), rgb(200, 225, 255), NEON)
		for _, s in ipairs({ -1, 1 }) do
			Kit.cone(m, 4, 0.8, 0.1, V(0, 6, 0) + V(0, s > 0 and 2 or -6, 0), rgb(150, 190, 255), NEON, 3)
		end
		return 4
	end

	builders["Olympus Mons"] = function(m)
		Kit.cone(m, 3, 20, 4, V(0, 0, 0), rgb(190, 100, 60), nil, 5)
		Kit.vcyl(m, 0.3, 3, V(0, 3, 0), rgb(120, 60, 40))
		return 3
	end

	builders["Valles Marineris"] = function(m)
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(30, 2, 3), V(0, 1, s * 2.4), rgb(190, 100, 60))
		end
		box(m, V(30, 0.4, 2), V(0, 0.2, 0), rgb(120, 60, 40))
		return 30
	end

	builders["Vesta"] = function(m)
		lumpy(m, V(0, 3.2, 0), 5.6, rgb(150, 145, 140), 6, 4)
		ball(m, 1.6, V(-2.4, 3.6, -1.4), rgb(110, 105, 100))
		return 6.4
	end

	builders["Great Red Spot"] = function(m)
		box(m, V(16, 10, 0.4), V(0, 5, 0.6), rgb(230, 200, 160))
		for i = 0, 2 do
			box(m, V(16, 0.8, 0.45), V(0, 2 + i * 3, 0.55), rgb(200, 150, 110))
		end
		ell(m, V(10, 6, 0.6), V(0, 5, 0), rgb(200, 90, 60))
		ell(m, V(6, 3.6, 0.7), V(0, 5, -0.05), rgb(220, 120, 80))
		ell(m, V(2.6, 1.6, 0.8), V(0, 5, -0.1), rgb(240, 160, 110))
		return 10
	end

	builders["Saturn's Rings"] = function(m)
		local center = V(0, 7, 0)
		ball(m, 6, center, rgb(230, 200, 140))
		for i, r in ipairs({ 7, 8.2, 9.6, 11 }) do
			ellipseRing(m, center, r, r * 0.3, 0.6, 40, i % 2 == 0 and rgb(220, 205, 170) or rgb(190, 170, 130))
		end
		return 22
	end

	builders["Sagittarius A*"] = function(m)
		local center = V(0, 7, 0)
		ball(m, 4, center, BLACK)
		ellipseRing(m, center, 4, 1.2, 0.8, 40, rgb(255, 160, 60), NEON)
		ellipseRing(m, center + V(0, 0, 0.5), 2.6, 2.6, 0.4, 32, rgb(255, 200, 120), NEON)
		return 4
	end

	builders["Betelgeuse"] = function(m)
		ball(m, 6, V(0, 3, 0), rgb(255, 120, 60), NEON)
		for i = 1, 4 do
			ball(m, 1.2, V(-2.4, 2 + i * 0.6, (i - 2.5) * 1.1), rgb(230, 90, 40))
		end
		return 6
	end

	builders["UY Scuti"] = function(m)
		ball(m, 6, V(0, 3, 0), rgb(255, 90, 50), NEON)
		for i = 1, 5 do
			ball(m, 1, V(-2.5, 1.6 + i * 0.6, (i - 3) * 1), rgb(220, 60, 30))
		end
		return 6
	end

	builders["TON 618"] = function(m)
		local center = V(0, 9, 0)
		ball(m, 4, center, BLACK)
		ellipseRing(m, center, 6, 1.8, 1.2, 40, rgb(190, 110, 255), NEON)
		ellipseRing(m, center, 8.4, 2.4, 0.6, 48, rgb(140, 80, 220), NEON)
		return 4
	end

	builders["Our Solar System"] = function(m)
		local center = V(0, 12.5, 0)
		ball(m, 2.4, center, rgb(255, 210, 80), NEON)
		local planets = { { 2.2, 0.3, rgb(170, 160, 150) }, { 3.2, 0.5, rgb(230, 200, 150) }, { 4.2, 0.5, rgb(80, 140, 220) }, { 5.2, 0.4, rgb(200, 90, 60) },
			{ 7, 1.2, rgb(220, 180, 140) }, { 8.8, 1, rgb(230, 210, 160) }, { 10.6, 0.8, rgb(150, 210, 230) }, { 12, 0.8, rgb(70, 110, 220) } }
		for i, p in ipairs(planets) do
			ellipseRing(m, center, p[1], p[1], 0.06, 36, rgb(120, 130, 160))
			local a = i * 0.9
			ball(m, p[2], center + V(math.cos(a) * p[1], math.sin(a) * p[1], -0.2), p[3])
		end
		return 24
	end

	builders["Milky Way"] = function(m)
		return galaxy(m, 10, 10, rgb(140, 170, 255), rgb(255, 230, 180))
	end

	builders["Andromeda Galaxy"] = function(m)
		return galaxy(m, 11, 4, rgb(180, 160, 255), rgb(255, 240, 200))
	end

	--======================================================================
	-- Weird and wonderful
	--======================================================================
	builders["Blue Whale Heart"] = function(m)
		local red = rgb(180, 40, 50)
		ball(m, 3.2, V(-1, 4.2, 0), red)
		ball(m, 3.2, V(1, 4.2, 0), red)
		Kit.cone(m, 3.2, 0.3, 2.6, V(0, 0.2, 0), red, nil, 5) -- the point, at the bottom
		for i = -1, 1 do
			rod(m, V(i * 0.8, 5, 0), V(i * 1.2, 6.6, 0), 0.4, rgb(150, 50, 80))
		end
		return 6.6
	end

	builders["Giraffe Tongue"] = function(m)
		local purple = rgb(70, 60, 110)
		taper(m, V(3, 1.6, 0), V(-1, 1.2, 0), 0.9, 0.6, 3, purple)
		taper(m, V(-1, 1.2, 0), V(-3.4, 2.2, 0), 0.6, 0.25, 3, purple)
		ball(m, 0.6, V(-3.5, 2.3, 0), purple)
		return 7
	end

	builders["Narwhal Tusk"] = function(m)
		taper(m, V(0, 0, 0), V(0, 14, 0), 0.5, 0.08, 6, rgb(240, 235, 215))
		for i = 0, 12 do
			box(m, V(1.1 - i * 0.07, 0.12, 0.2), CFrame.new(0, 0.5 + i, 0) * CFrame.Angles(0, i * 0.8, 0.4), rgb(215, 205, 180))
		end
		return 14
	end

	builders["Giant Squid Eye"] = function(m)
		ball(m, 4, V(0, 2.2, 0), rgb(240, 240, 235))
		ell(m, V(2.6, 2.6, 0.6), V(0, 2.2, -1.75), rgb(70, 110, 160))
		ell(m, V(1.5, 1.5, 0.5), V(0, 2.2, -1.95), BLACK)
		ell(m, V(0.4, 0.4, 0.2), V(-0.4, 2.6, -2.15), WHITE)
		return 4
	end

	builders["T. rex Tooth"] = function(m)
		taper(m, V(0, 0, 0), V(-0.8, 8, 0), 1.2, 0.1, 6, rgb(235, 225, 195))
		box(m, V(2.6, 0.6, 1.6), V(0, 0.3, 0), rgb(150, 120, 90))
		return 8.3
	end

	builders["Zeus the Tallest Dog"] = function(m)
		return quad(m, { len = 6.4, bodyH = 2.6, legH = 5, width = 2, color = rgb(90, 95, 110), headLen = 2.6, headH = 2, neck = 1.8, snout = rgb(60, 60, 70), ear = { 0.5, 0.9 }, tail = 3.2 })
	end

	builders["Darius the Giant Rabbit"] = function(m)
		local measure = critter(m, { len = 6, h = 3.4, color = rgb(160, 130, 100), belly = rgb(220, 205, 185), head = 2.4, ear = { 0.8, 3.2 }, tail = { 0.8, 30, 0.6 }, tailColor = WHITE })
		return measure
	end

	builders["Newborn Panda"] = function(m)
		local measure = critter(m, { len = 3, h = 1.4, color = rgb(240, 200, 200), head = 1.2, ear = { 0.3, 0.2 }, tail = { 0.4, -10, 0.2 }, nose = rgb(220, 150, 150) })
		return measure
	end

	builders["Newborn Blue Whale"] = function(m)
		swimmer(m, 10, 2.4, rgb(100, 120, 150), rgb(170, 185, 200), 0.3)
		return 10
	end

	builders["Asian Giant Hornet"] = function(m)
		return insect(m, { len = 5, h = 1.6, color = rgb(230, 150, 40), headColor = rgb(240, 170, 50), abdomen = rgb(240, 170, 50), stripes = rgb(60, 40, 30), wings = rgb(220, 225, 235), wingLen = 2.8 })
	end

	builders["Titan Beetle"] = function(m)
		local measure = insect(m, { len = 6.4, h = 1.8, legH = 0.8, color = rgb(80, 50, 35), headFrac = 0.14, thoraxFrac = 0.26, abdomen = rgb(110, 70, 45), antenna = 2.4 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-3, 1.6, s * 0.3), V(-4, 1.2, s * 0.5), 0.3, BLACK)
		end
		return measure
	end

	--======================================================================
	-- Famous prehistoric giants and well-known record holders
	--======================================================================
	builders["Saber-toothed Cat"] = function(m)
		local o = { len = 6.4, bodyH = 2.8, legH = 3, width = 2.4, color = rgb(200, 150, 90), belly = rgb(230, 205, 160), headLen = 2.2, headH = 2, neck = 0.5, snout = rgb(225, 195, 150), ear = { 0.4, 0.4 }, tail = 0.8 }
		local measure = quad(m, o)
		local hx, hy = Body.quadHead(o)
		for _, z in ipairs({ -0.4, 0.4 }) do
			taper(m, V(hx - 0.8, hy - 0.6, z), V(hx - 0.7, hy - 2, z), 0.18, 0.04, 3, rgb(245, 240, 225))
		end
		return measure
	end

	builders["Dodo"] = function(m)
		return bird(m, { legH = 1.6, body = { 3.6, 3.2, 3 }, tilt = 10, color = rgb(140, 140, 150), wing = rgb(120, 120, 130), neck = 0.8, head = 1.5, beak = { 1.6, rgb(220, 200, 120), 0.5, 0.7 }, tail = { 0.8, 60, 1.2 }, tailColor = rgb(240, 240, 235), legColor = rgb(230, 200, 80) })
	end

	builders["Mosasaurus"] = function(m)
		local blue = rgb(80, 100, 120)
		swimmer(m, 24, 3.4, blue, rgb(200, 205, 200), 0.4)
		box(m, V(5, 1, 2.8), V(-12.5, 2.2, 0), blue) -- long jaws
		for i = 0, 5 do
			box(m, V(0.3, 0.5, 2.9), V(-14.5 + i * 0.7, 2.6, 0), WHITE)
		end
		for _, x in ipairs({ -6, 5 }) do
			slab(m, V(x, 1.4, 0), V(x + 2, 0.2, -2.4), 1.6, 0.3, blue)
		end
		return 28
	end

	builders["Diplodocus"] = function(m)
		local green = rgb(130, 140, 100)
		for _, x in ipairs({ -2.6, 2.6 }) do
			for _, z in ipairs({ -1.2, 1.2 }) do
				box(m, V(1.3, 5.6, 1.3), V(x, 2.8, z), green)
			end
		end
		ell(m, V(9, 4.4, 3.8), V(0, 7.2, 0), green)
		taper(m, V(-4, 8, 0), V(-12, 11, 0), 1, 0.5, 5, green)
		box(m, V(1.8, 0.9, 0.9), V(-12.8, 11.1, 0), green)
		eyes(m, V(-12.6, 11.3, 0), 0.45, 0.2)
		taper(m, V(4, 7.6, 0), V(18, 3, 0), 1.2, 0.1, 7, green)
		return 31.7
	end

	builders["Ankylosaurus"] = function(m)
		local o = { len = 6, bodyH = 2.4, legH = 1.4, width = 3.4, color = rgb(140, 120, 80), headLen = 1.8, headH = 1.4, neck = -0.6, ear = { 0.1, 0.1 }, tail = 0.1 }
		quad(m, o)
		Kit.dome(m, 2.4, V(0, 3.4, 0), rgb(110, 95, 65), nil, 4)
		for i = -2, 2 do
			for _, z in ipairs({ -1.7, 1.7 }) do
				Kit.cone(m, 0.6, 0.3, 0.05, V(i * 1.1, 3.4, z), rgb(200, 185, 150), nil, 3)
			end
		end
		taper(m, V(3, 2.8, 0), V(7.2, 2.2, 0), 0.5, 0.25, 4, rgb(140, 120, 80))
		ell(m, V(1.4, 1, 1.4), V(7.6, 2.2, 0), rgb(110, 95, 65)) -- tail club
		local hx = Body.quadHead(o)
		return 8.3 - (hx - o.headLen / 2)
	end

	builders["Giant Ground Sloth"] = function(m)
		local fur = rgb(130, 100, 70)
		quad(m, { len = 7, bodyH = 4, legH = 2.4, width = 3.4, color = fur, headLen = 2, headH = 1.8, neck = 0.6, snout = rgb(100, 75, 55), ear = { 0.3, 0.3 }, tail = 3, tailColor = fur })
		for _, z in ipairs({ -1.2, 1.2 }) do
			for c = -1, 1 do
				beam(m, V(-3.2, 0.2, z + c * 0.25), V(-4, 0.05, z + c * 0.3), 0.12, rgb(230, 225, 200))
			end
		end
		return 10.8 -- snout to tail tip
	end

	builders["Tallest Sunflower"] = function(m)
		rod(m, V(0, 0, 0), V(0, 28, 0), 0.4, rgb(90, 140, 60))
		for i = 1, 6 do
			local y = i * 4
			ell(m, V(3, 0.2, 1.6), CFrame.new((i % 2 == 0) and 1.4 or -1.4, y, 0) * CFrame.Angles(0, 0, (i % 2 == 0) and -0.4 or 0.4), rgb(80, 150, 60))
		end
		local head = V(0, 29.5, -0.6)
		for k = 0, 15 do
			local a = k * math.pi / 8
			ell(m, V(0.9, 2, 0.3), CFrame.new(head + V(math.cos(a) * 2.2, math.sin(a) * 2.2, 0)) * CFrame.Angles(0, 0, a - math.pi / 2), rgb(250, 200, 30))
		end
		ell(m, V(3, 3, 0.6), head + V(0, 0, -0.2), rgb(100, 60, 30))
		return 31.6
	end

	builders["Titanic"] = function(m)
		box(m, V(36, 2, 4.6), V(0, 1, 0), rgb(160, 40, 40))
		box(m, V(36, 3, 4.6), V(0, 3.5, 0), BLACK)
		box(m, V(26, 2.4, 4.2), V(0, 6.2, 0), WHITE)
		Kit.windows(m, -12, 12, 5.4, 7, -2.15, 18, 1, rgb(40, 60, 90))
		for i = 0, 3 do
			local x = -8 + i * 5
			box(m, V(1.8, 4, 1.8), V(x, 9.4, 0), rgb(230, 170, 60))
			box(m, V(1.82, 0.9, 1.82), V(x, 11, 0), BLACK)
		end
		Kit.wedge(m, V(4.6, 5, 2.4), CFrame.new(-19.2, 2.5, 0) * CFrame.Angles(0, -math.pi / 2, 0), BLACK)
		return 38.4
	end

	builders["Megalodon Tooth"] = function(m)
		Kit.peak(m, 0, 0.8, 0, 2.4, 5, 0.8, rgb(110, 105, 100))
		box(m, V(5.6, 1.2, 0.9), V(0, 0.6, 0), rgb(70, 60, 55))
		return 6.2
	end

end
