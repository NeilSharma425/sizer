--[[
	MoreAnimals.lua
	ModuleScript: ReplicatedStorage.Models.MoreAnimals

	135 more animal models for ObjectModels, built from the body-shape
	helpers in BodyKit (four-legged, bird, flyer, swimmer, seal, snake,
	lizard, turtle, insect, many-legged, critter). Side-on views facing -X, like
	ExtraAnimals; flyers and rays are seen from above with wings spread
	across the screen. Every builder returns `measure`: the model-unit
	length that matches the size listed for it in ExtraObjects (shoulder
	height, standing height, length or wingspan, as its fact says).

	Usage: require(MoreAnimals)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local Body = require(script.Parent:WaitForChild("BodyKit"))
local box, ball, beam, rod, slab, taper = Kit.box, Kit.ball, Kit.beam, Kit.rod, Kit.slab, Kit.taper
local quad, swimmer = Kit.quad, Kit.swimmer
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new
local ell, eyes, spots, antlers, quadHead = Body.ell, Body.eyes, Body.spots, Body.antlers, Body.quadHead
local bird, flyer, seal, snake, lizard, turtle = Body.bird, Body.flyer, Body.seal, Body.snake, Body.lizard, Body.turtle
local insect, legs, critter, ape, theropod, frog = Body.insect, Body.legs, Body.critter, Body.ape, Body.theropod, Body.frog
local trunk, tusks = Body.trunk, Body.tusks

return function(builders)
	local function q(name, o, extra)
		builders[name] = function(m)
			local measure = quad(m, o)
			if extra then
				extra(m, o)
			end
			return measure
		end
	end

	--======================================================================
	-- Dogs and wild canines
	--======================================================================
	q("Chihuahua", { len = 3, bodyH = 1.4, legH = 1.4, width = 1.2, color = rgb(225, 185, 130), headLen = 1.4, headH = 1.3, neck = 0.4, snout = rgb(200, 160, 110), ear = { 0.5, 1.1 }, tail = 1.4 })
	q("Great Dane", { len = 6, bodyH = 2.6, legH = 4.4, width = 2, color = rgb(115, 120, 135), headLen = 2.5, headH = 2, neck = 1.6, snout = rgb(85, 90, 100), ear = { 0.5, 0.9 }, tail = 3 })
	q("German Shepherd", { len = 5.4, bodyH = 2.4, legH = 3.2, width = 2, color = rgb(190, 135, 70), headLen = 2.2, headH = 1.8, neck = 1, snout = BLACK, ear = { 0.5, 1.2 }, earColor = rgb(60, 45, 35), tail = 2.6 }, function(m, o)
		box(m, V(3.4, 1.2, 2.04), V(0.4, 5.05, 0), rgb(50, 40, 35))
	end)
	q("Dachshund", { len = 5, bodyH = 1.6, legH = 0.8, width = 1.4, color = rgb(140, 75, 40), headLen = 2, headH = 1.3, neck = 0.4, snout = rgb(120, 60, 30), ear = { 0.5, 1.1 }, earColor = rgb(100, 50, 25), tail = 1.6 })
	q("Corgi", { len = 4.4, bodyH = 1.8, legH = 1, width = 1.8, color = rgb(225, 150, 70), belly = WHITE, legColor = WHITE, headLen = 1.8, headH = 1.6, neck = 0.4, snout = WHITE, ear = { 0.6, 1 }, tail = 0.4 })
	q("Gray Wolf", { len = 6, bodyH = 2.6, legH = 4, width = 2, color = rgb(140, 140, 148), belly = rgb(215, 215, 220), headLen = 2.4, headH = 1.8, neck = 1, snout = rgb(205, 205, 210), ear = { 0.5, 0.9 }, tail = 3 })
	q("Red Fox", { len = 5, bodyH = 1.9, legH = 2.1, width = 1.6, color = rgb(215, 110, 40), belly = WHITE, legColor = rgb(60, 40, 35), headLen = 2, headH = 1.5, neck = 0.6, snout = WHITE, ear = { 0.5, 0.9 }, tail = 4 }, function(m)
		ball(m, 0.9, V(5.4, 2.1, 0), WHITE)
	end)
	q("Arctic Fox", { len = 4.4, bodyH = 1.9, legH = 1.6, width = 1.7, color = rgb(242, 242, 248), headLen = 1.8, headH = 1.5, neck = 0.5, snout = rgb(230, 230, 236), ear = { 0.5, 0.6 }, tail = 3.4 })
	q("Coyote", { len = 5.4, bodyH = 2.2, legH = 3.4, width = 1.8, color = rgb(170, 140, 100), belly = rgb(225, 210, 185), headLen = 2.2, headH = 1.6, neck = 0.8, snout = rgb(200, 175, 140), ear = { 0.5, 1 }, tail = 2.8, tailColor = rgb(120, 100, 75) })

	--======================================================================
	-- Big cats
	--======================================================================
	q("Bengal Tiger", { len = 8, bodyH = 3.2, legH = 3.6, width = 2.8, color = rgb(230, 130, 40), stripes = BLACK, belly = WHITE, headLen = 2.4, headH = 2.4, neck = 0.6, snout = WHITE, ear = { 0.5, 0.5 }, tail = 4 })
	local leopard = { len = 6.6, bodyH = 2.6, legH = 3, width = 2.2, color = rgb(225, 180, 90), headLen = 2.2, headH = 2, neck = 0.6, snout = rgb(240, 220, 180), ear = { 0.5, 0.5 }, tail = 4.2 }
	q("Leopard", leopard, function(m, o)
		spots(m, o, rgb(60, 40, 25), 14)
	end)
	local cheetah = { len = 6.4, bodyH = 2.2, legH = 4, width = 1.8, color = rgb(230, 190, 100), headLen = 1.8, headH = 1.6, neck = 0.6, snout = rgb(245, 230, 200), ear = { 0.4, 0.4 }, tail = 4.6 }
	q("Cheetah", cheetah, function(m, o)
		spots(m, o, BLACK, 16)
	end)
	local snowLeopard = { len = 6, bodyH = 2.4, legH = 2.6, width = 2, color = rgb(225, 225, 220), headLen = 2, headH = 1.9, neck = 0.5, snout = rgb(240, 240, 238), ear = { 0.4, 0.4 }, tail = 5.2 }
	q("Snow Leopard", snowLeopard, function(m, o)
		spots(m, o, rgb(120, 120, 125), 12)
	end)
	q("Eurasian Lynx", { len = 4.6, bodyH = 2.4, legH = 3.2, width = 1.8, color = rgb(190, 160, 120), headLen = 1.9, headH = 1.8, neck = 0.6, snout = rgb(230, 215, 190), ear = { 0.4, 1 }, earColor = rgb(60, 45, 35), tail = 0.6, tailColor = BLACK })

	--======================================================================
	-- Bears and big grazers
	--======================================================================
	q("American Black Bear", { len = 7, bodyH = 3.8, legH = 3, width = 3, color = rgb(40, 35, 38), headLen = 2.6, headH = 2.2, neck = 0.3, snout = rgb(170, 130, 90), ear = { 0.6, 0.6 }, tail = 0.6 })
	local moose = { len = 8, bodyH = 4, legH = 7, width = 3, color = rgb(85, 60, 40), legColor = rgb(60, 42, 30), headLen = 3.4, headH = 2.2, neck = 1.2, snout = rgb(70, 50, 35), ear = { 0.5, 1 }, tail = 0.8 }
	q("Moose", moose, function(m, o)
		local hx, hy = quadHead(o)
		for _, z in ipairs({ -1, 1 }) do
			box(m, V(2.8, 1.2, 0.3), CFrame.new(hx + 1, hy + 1.8, z * 1.4) * CFrame.Angles(0, 0, -0.25), rgb(205, 185, 150))
			for i = 0, 3 do
				box(m, V(0.25, 0.8, 0.25), V(hx + i * 0.7, hy + 2.6 - i * 0.18, z * 1.4), rgb(205, 185, 150))
			end
		end
		box(m, V(0.8, 1.6, 0.6), V(hx + 0.4, hy - 1.7, 0), rgb(60, 42, 30)) -- dewlap
	end)
	local elk = { len = 7.6, bodyH = 3.4, legH = 5.4, width = 2.6, color = rgb(165, 115, 70), legColor = rgb(110, 75, 50), headLen = 2.8, headH = 1.8, neck = 2.4, snout = rgb(90, 65, 45), mane = rgb(95, 65, 45), ear = { 0.4, 0.9 }, tail = 0.8, tailColor = rgb(225, 205, 170) }
	q("Elk", elk, function(m, o)
		local hx, hy = quadHead(o)
		antlers(m, hx + 0.6, hy + 0.9, o.width, 4.4, rgb(220, 205, 175))
	end)
	local reindeer = { len = 6.4, bodyH = 3, legH = 4, width = 2.4, color = rgb(130, 105, 85), mane = rgb(235, 230, 220), legColor = rgb(100, 80, 65), headLen = 2.4, headH = 1.8, neck = 1.6, snout = rgb(60, 50, 45), ear = { 0.4, 0.8 }, tail = 0.6, tailColor = WHITE }
	q("Reindeer", reindeer, function(m, o)
		local hx, hy = quadHead(o)
		antlers(m, hx + 0.5, hy + 0.9, o.width, 3.6, rgb(220, 205, 175))
	end)
	builders["American Bison"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 3.6, width = 3.6, color = rgb(95, 65, 40), headLen = 3, headH = 3, neck = -0.6, mane = rgb(60, 40, 28), horns = rgb(50, 45, 40), ear = { 0.5, 0.4 }, tail = 1.6, hump = 2.2 }
		quad(m, o)
		box(m, V(4.6, 3.6, 3.7), V(-2.4, 6.8, 0), rgb(65, 45, 30))
		return o.legH + o.bodyH + o.hump
	end
	q("Water Buffalo", { len = 8.4, bodyH = 4, legH = 4, width = 3.2, color = rgb(70, 70, 76), headLen = 2.8, headH = 2.4, neck = 0, snout = rgb(55, 55, 60), ear = { 0.6, 0.5 }, tail = 2.6 }, function(m, o)
		local hx, hy = quadHead(o)
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(hx + 0.4, hy + 1.2, z * 0.9), V(hx + 2.4, hy + 2, z * 2.6), 0.5, rgb(60, 55, 50))
			beam(m, V(hx + 2.4, hy + 2, z * 2.6), V(hx + 3.2, hy + 3.2, z * 2.2), 0.4, rgb(60, 55, 50))
		end
	end)
	q("Yak", { len = 8, bodyH = 4.2, legH = 3.6, width = 3.4, color = rgb(60, 45, 40), headLen = 2.6, headH = 2.4, neck = -0.2, horns = rgb(225, 215, 195), ear = { 0.5, 0.5 }, tail = 2.6, hump = 1.2 }, function(m, o)
		box(m, V(8.2, 1.8, 3.5), V(0, 3.6, 0), rgb(50, 38, 34)) -- shaggy skirt
	end)
	q("Llama", { len = 5.6, bodyH = 3, legH = 4.6, width = 2.2, color = rgb(235, 225, 205), headLen = 2, headH = 1.6, neck = 4.6, snout = rgb(210, 195, 170), ear = { 0.4, 1.2 }, tail = 1 })
	q("Alpaca", { len = 4.6, bodyH = 3, legH = 3.2, width = 2.4, color = rgb(200, 160, 120), headLen = 1.8, headH = 1.6, neck = 3.4, snout = rgb(170, 130, 95), ear = { 0.4, 0.9 }, tail = 0.8 }, function(m, o)
		ball(m, 1.4, V(-2.7, 10.4, 0), rgb(215, 180, 140)) -- fluffy topknot
	end)
	q("Goat", { len = 5, bodyH = 2.6, legH = 3, width = 2, color = WHITE, headLen = 2, headH = 1.6, neck = 1, snout = rgb(240, 220, 215), horns = rgb(150, 135, 115), ear = { 0.6, 0.4 }, tail = 0.8 }, function(m, o)
		local hx, hy = quadHead(o)
		box(m, V(0.5, 1.2, 0.5), V(hx - 0.3, hy - 1.3, 0), rgb(225, 225, 225)) -- beard
	end)
	q("Donkey", { len = 6.4, bodyH = 3.2, legH = 4.4, width = 2.4, color = rgb(150, 140, 135), belly = rgb(220, 215, 210), headLen = 3, headH = 1.9, neck = 1.8, snout = rgb(225, 220, 215), mane = rgb(70, 60, 55), ear = { 0.5, 2 }, tail = 3 })
	q("Shetland Pony", { len = 6, bodyH = 3.2, legH = 3.4, width = 2.4, color = rgb(110, 70, 45), headLen = 2.6, headH = 1.9, neck = 2, snout = rgb(90, 55, 35), mane = rgb(235, 225, 200), ear = { 0.4, 0.7 }, tail = 3.4, tailColor = rgb(235, 225, 200) })
	q("Clydesdale Horse", { len = 9, bodyH = 4.2, legH = 6.6, width = 3, color = rgb(125, 60, 35), headLen = 3.6, headH = 2.4, neck = 4, snout = WHITE, mane = BLACK, ear = { 0.4, 1 }, tail = 4.4, tailColor = BLACK }, function(m, o)
		for _, x in ipairs({ -3.6, 3.6 }) do
			for _, z in ipairs({ -1.05, 1.05 }) do
				box(m, V(1.3, 1.6, 1.3), V(x, 0.8, z), WHITE) -- feathered feet
			end
		end
	end)
	q("Okapi", { len = 7, bodyH = 3.2, legH = 5.4, width = 2.4, color = rgb(75, 40, 35), headLen = 2.8, headH = 1.8, neck = 2.6, snout = rgb(225, 215, 200), ear = { 0.7, 1.2 }, tail = 2.4 }, function(m, o)
		for _, x in ipairs({ -2.9, 2.9 }) do
			for i = 0, 3 do
				box(m, V(0.75, 0.3, 2.45), V(x, 1.4 + i * 0.8, 0), WHITE)
			end
		end
	end)
	q("Blue Wildebeest", { len = 7, bodyH = 3.4, legH = 4.4, width = 2.4, color = rgb(100, 100, 108), stripes = rgb(70, 70, 76), headLen = 3, headH = 2, neck = 0.6, snout = BLACK, mane = BLACK, horns = rgb(60, 55, 50), ear = { 0.4, 0.5 }, tail = 3, tailColor = BLACK })
	q("Thomson's Gazelle", { len = 4.4, bodyH = 2, legH = 3.2, width = 1.4, color = rgb(205, 145, 80), belly = WHITE, headLen = 1.8, headH = 1.2, neck = 1.6, snout = rgb(230, 210, 180), horns = BLACK, ear = { 0.3, 0.8 }, tail = 0.8, tailColor = BLACK }, function(m, o)
		box(m, V(4.2, 0.35, 1.42), V(0, 4, 0), BLACK)
	end)
	q("Warthog", { len = 5.4, bodyH = 2.6, legH = 2.2, width = 2.2, color = rgb(120, 100, 92), headLen = 2.4, headH = 2, neck = -0.2, snout = rgb(140, 115, 105), mane = rgb(70, 55, 50), ear = { 0.5, 0.6 }, tail = 2 }, function(m, o)
		local hx, hy = quadHead(o)
		tusks(m, hx, hy + 0.5, o.headLen, 1.2, o.width, rgb(240, 235, 215))
	end)
	q("Wild Boar", { len = 6, bodyH = 3, legH = 2.4, width = 2.4, color = rgb(95, 75, 60), headLen = 2.6, headH = 2.2, neck = -0.3, snout = rgb(110, 85, 70), ear = { 0.5, 0.7 }, tail = 1.2 }, function(m, o)
		local hx, hy = quadHead(o)
		tusks(m, hx, hy + 0.4, o.headLen, 0.8, o.width, rgb(240, 235, 215))
		box(m, V(5, 0.6, 1.2), V(0, 5.6, 0), rgb(70, 55, 45))
	end)
	q("Malayan Tapir", { len = 7, bodyH = 3.4, legH = 3, width = 2.6, color = BLACK, headLen = 2.6, headH = 2, neck = 0, ear = { 0.5, 0.6 }, tail = 0.6 }, function(m, o)
		box(m, V(3.4, 3.45, 2.65), V(1.2, 4.7, 0), WHITE)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 1.2, 0.45, BLACK)
	end)
	q("Capybara", { len = 4.6, bodyH = 2.6, legH = 1.4, width = 2.2, color = rgb(150, 105, 70), headLen = 2, headH = 1.8, neck = 0, snout = rgb(120, 85, 55), ear = { 0.4, 0.4 }, tail = 0.1 })
	builders["Woolly Mammoth"] = function(m)
		local o = { len = 9, bodyH = 5.6, legH = 5, width = 4.4, color = rgb(110, 75, 45), headLen = 3.4, headH = 3.4, neck = 0, ear = { 0.6, 0.8 }, tail = 1.2, hump = 1.4 }
		quad(m, o)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 5.6, 0.9, o.color)
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(hx - 1.2, hy - 1.4, z * 1.1), V(hx - 3.6, hy - 2.4, z * 1.4), 0.6, rgb(240, 230, 200))
			beam(m, V(hx - 3.6, hy - 2.4, z * 1.4), V(hx - 4.6, hy - 0.4, z * 1.2), 0.55, rgb(240, 230, 200))
		end
		return o.legH + o.bodyH + o.hump
	end
	builders["Asian Elephant"] = function(m)
		local o = { len = 9, bodyH = 5, legH = 4.4, width = 4, color = rgb(140, 135, 135), headLen = 3.2, headH = 3.4, neck = 0, ear = { 0.4, 2.2 }, tail = 2.4 }
		local measure = quad(m, o)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 5.2, 0.8, o.color)
		box(m, V(1.6, 2.6, 4.2), V(hx + 1.4, hy - 0.2, 0), rgb(125, 120, 122)) -- ears
		return measure
	end
	q("Giant Anteater", { len = 6, bodyH = 2.4, legH = 2, width = 1.8, color = rgb(120, 100, 82), headLen = 3.4, headH = 0.9, neck = -0.6, ear = { 0.2, 0.2 }, tail = 5.6, tailColor = rgb(80, 65, 55) }, function(m, o)
		slab(m, V(-2.6, 4.2, 0), V(1, 2.6, 0), 1.85, 0.6, BLACK)
		box(m, V(2.4, 2.4, 0.6), V(4.6, 3, 0), rgb(80, 65, 55)) -- bushy tail
	end)
	q("Ring-tailed Lemur", { len = 3.6, bodyH = 1.6, legH = 1.6, width = 1.4, color = rgb(160, 160, 165), belly = WHITE, headLen = 1.4, headH = 1.2, neck = 0.4, snout = BLACK, ear = { 0.4, 0.5 }, tail = 0.1 }, function(m)
		for i = 0, 9 do
			box(m, V(0.5, 0.42, 0.5), V(2.1 + i * 0.12, 3.4 + i * 0.42, 0), i % 2 == 0 and BLACK or WHITE)
		end
	end)

	--======================================================================
	-- Small mammals
	--======================================================================
	q("Raccoon", { len = 4, bodyH = 2, legH = 1.4, width = 1.8, color = rgb(130, 130, 135), headLen = 1.6, headH = 1.4, neck = 0.2, snout = WHITE, ear = { 0.4, 0.5 }, tail = 0.1 }, function(m)
		box(m, V(1, 0.4, 1.4), V(-2.5, 3.2, 0), BLACK)
		for i = 0, 5 do
			box(m, V(0.4, 0.6, 0.6), V(2.2 + i * 0.32, 2.6 - i * 0.12, 0), i % 2 == 0 and BLACK or rgb(170, 170, 175))
		end
	end)
	q("Striped Skunk", { len = 3.6, bodyH = 1.8, legH = 0.8, width = 1.6, color = BLACK, headLen = 1.4, headH = 1.2, neck = 0.2, ear = { 0.3, 0.3 }, tail = 0.1 }, function(m)
		box(m, V(3.4, 0.4, 0.8), V(0, 2.75, 0), WHITE)
		ell(m, V(1.6, 3.2, 1.2), V(2.4, 3.4, 0), BLACK)
		ell(m, V(0.6, 2.8, 1.25), V(2.3, 3.6, 0), WHITE)
	end)
	q("European Badger", { len = 4.4, bodyH = 2, legH = 1, width = 2, color = rgb(140, 140, 145), legColor = BLACK, headLen = 1.8, headH = 1.4, neck = 0, snout = WHITE, ear = { 0.3, 0.3 }, tail = 0.6 }, function(m)
		box(m, V(1.9, 0.35, 1.52), V(-2.8, 2.6, 0), BLACK)
	end)
	builders["Hedgehog"] = function(m)
		local measure = critter(m, { len = 3, h = 2, color = rgb(120, 100, 80), head = 1.1, headColor = rgb(215, 195, 165), nose = BLACK, ear = { 0.3, 0.3 } })
		for i = 0, 11 do
			local a = math.rad(20 + i * 12)
			local p = V(math.cos(a) * 1.5 - 0.1, 1.3 + math.sin(a) * 1.05, 0)
			beam(m, p, p + V(math.cos(a), math.sin(a), 0) * 0.6, 0.12, rgb(70, 55, 45))
		end
		return measure
	end
	builders["Nine-banded Armadillo"] = function(m)
		local measure = critter(m, { len = 4, h = 1.8, color = rgb(160, 140, 120), head = 1, ear = { 0.4, 0.6 }, tail = { 3, -15, 0.25 }, nose = rgb(140, 120, 100) })
		for i = -4, 4 do
			box(m, V(0.18, 1.9, 1.7), V(i * 0.4, 1.35, 0), rgb(130, 112, 95))
		end
		return measure
	end
	builders["North American Beaver"] = function(m)
		critter(m, { len = 4.4, h = 2.4, color = rgb(120, 75, 45), head = 1.8, ear = { 0.4, 0.3 }, nose = BLACK })
		box(m, V(0.3, 0.4, 0.4), V(-3.15, 1.6, 0), WHITE)
		box(m, V(3.2, 0.3, 1.4), V(3.6, 0.3, 0), rgb(65, 50, 45)) -- flat tail
		return (3.6 + 1.6) - (-2.2 - 1.1)
	end
	builders["Red Squirrel"] = function(m)
		local measure = critter(m, { len = 2.4, h = 1.4, color = rgb(200, 90, 40), belly = WHITE, head = 1.1, ear = { 0.3, 0.6 }, nose = BLACK })
		ell(m, V(1.4, 3, 1.1), CFrame.new(1.7, 2.4, 0) * CFrame.Angles(0, 0, 0.25), rgb(190, 85, 35))
		return measure
	end
	builders["Guinea Pig"] = function(m)
		local measure = critter(m, { len = 2.8, h = 1.6, color = rgb(230, 150, 70), head = 1.3, ear = { 0.4, 0.3 }, legH = 0.15 })
		box(m, V(1.2, 1.62, 1.46), V(0.4, 1.0, 0), WHITE)
		return measure
	end
	builders["House Mouse"] = function(m)
		return critter(m, { len = 2.2, h = 1.2, color = rgb(150, 145, 140), head = 0.9, ear = { 0.6, 0.6 }, earColor = rgb(240, 170, 170), tail = { 2.6, -10, 0.1 }, tailColor = rgb(240, 170, 170) })
	end
	builders["Brown Rat"] = function(m)
		return critter(m, { len = 3, h = 1.4, color = rgb(120, 95, 75), belly = rgb(190, 175, 160), head = 1.1, ear = { 0.5, 0.45 }, earColor = rgb(225, 160, 160), tail = { 3, -12, 0.14 }, tailColor = rgb(225, 160, 160) })
	end
	builders["Ferret"] = function(m)
		local measure = critter(m, { len = 4, h = 1.1, color = rgb(215, 195, 160), head = 0.9, headColor = WHITE, ear = { 0.3, 0.3 }, tail = { 1.6, -10, 0.25 }, tailColor = rgb(90, 70, 55), legColor = rgb(90, 70, 55) })
		box(m, V(0.35, 0.25, 0.92), V(-2.05, 1.05, 0), rgb(90, 70, 55)) -- mask
		return measure
	end
	builders["Meerkat"] = function(m)
		local tan = rgb(200, 170, 125)
		for _, z in ipairs({ -0.35, 0.35 }) do
			box(m, V(0.5, 1.2, 0.35), V(0.2, 0.6, z), tan)
		end
		ell(m, V(1.5, 3.6, 1.3), V(0, 2.8, 0), tan)
		ell(m, V(0.9, 2.4, 1.2), V(-0.35, 2.4, 0), rgb(230, 210, 175))
		for _, z in ipairs({ -0.45, 0.45 }) do
			beam(m, V(-0.4, 3.8, z), V(-0.8, 3.1, z * 0.8), 0.28, tan)
		end
		local head = V(-0.25, 5, 0)
		ell(m, V(1.5, 1, 1), head, tan)
		box(m, V(0.35, 0.3, 1.05), head + V(-0.15, 0.1, 0), BLACK)
		ball(m, 0.2, head + V(-0.78, -0.05, 0), BLACK)
		taper(m, V(0.6, 1.4, 0), V(2.2, 0.1, 0), 0.25, 0.1, 3, tan)
		return 5.5
	end
	builders["Koala"] = function(m)
		local gray = rgb(160, 160, 168)
		ell(m, V(3, 3.6, 2.8), V(0, 2, 0), gray)
		ell(m, V(1.6, 2.2, 2.4), V(-0.8, 1.7, 0), rgb(230, 228, 225))
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(-0.6, 2.8, z * 1.2), V(-1.4, 1.4, z * 1.1), 0.7, gray)
			ell(m, V(1.6, 0.8, 1), V(-0.8, 0.4, z * 0.9), gray)
		end
		local head = V(-0.6, 4.6, 0)
		ell(m, V(2.4, 2.2, 2.4), head, gray)
		for _, z in ipairs({ -1, 1 }) do
			ell(m, V(0.7, 1.4, 1.4), head + V(0.3, 0.9, z * 1.3), rgb(220, 220, 225))
		end
		ell(m, V(0.5, 1, 0.7), head + V(-1.2, -0.2, 0), BLACK)
		eyes(m, head + V(0, 0.2, 0), 1.1, 0.25)
		return 5.9
	end
	builders["Red Kangaroo"] = function(m)
		local red = rgb(190, 95, 60)
		for _, z in ipairs({ -0.6, 0.6 }) do
			box(m, V(3, 0.5, 0.6), V(-0.6, 0.25, z), red)
			slab(m, V(0.6, 0.4, z), V(-0.4, 3.4, z), 0.7, 1.2, red)
		end
		ell(m, V(3, 6, 2.6), CFrame.new(0.4, 5.4, 0) * CFrame.Angles(0, 0, -0.25), red)
		ell(m, V(1.8, 3.6, 2.4), CFrame.new(-0.4, 5, 0) * CFrame.Angles(0, 0, -0.25), rgb(225, 190, 160))
		taper(m, V(1.6, 3.2, 0), V(5.6, 0.2, 0), 0.7, 0.25, 4, red)
		for _, z in ipairs({ -0.7, 0.7 }) do
			beam(m, V(-0.6, 7, z), V(-1.6, 5.8, z), 0.35, red)
		end
		local head = V(-0.8, 9.2, 0)
		ell(m, V(2.4, 1.4, 1.3), head + V(-0.4, 0, 0), red)
		for _, z in ipairs({ -0.4, 0.4 }) do
			ell(m, V(0.4, 1.4, 0.6), head + V(0.5, 1.1, z), red)
		end
		eyes(m, head, 0.6, 0.22)
		ball(m, 0.3, head + V(-1.6, -0.05, 0), BLACK)
		return 10.2
	end
	builders["Chimpanzee"] = function(m)
		return ape(m, { h = 8, color = rgb(45, 38, 35), skin = rgb(205, 170, 140) })
	end
	builders["Bornean Orangutan"] = function(m)
		return ape(m, { h = 8, color = rgb(190, 90, 35), skin = rgb(120, 85, 70), cheeks = rgb(110, 80, 65) })
	end

	--======================================================================
	-- Birds
	--======================================================================
	builders["Flamingo"] = function(m)
		return bird(m, { legH = 5, body = { 3, 1.8, 1.6 }, tilt = 10, color = rgb(250, 140, 160), wing = rgb(240, 110, 135), neck = 4, head = 1, beak = { 1.2, BLACK, 0.6, 0.35 }, tail = { 0.8, 0 }, legColor = rgb(240, 120, 140) })
	end
	builders["Peacock"] = function(m)
		local measure = bird(m, { legH = 2, body = { 2.6, 2, 1.6 }, tilt = 25, color = rgb(30, 90, 200), wing = rgb(70, 120, 90), neck = 1.6, head = 0.9, beak = { 0.5, rgb(220, 210, 180) }, crest = rgb(30, 90, 200), tail = { 9, -12, 2.2 }, tailColor = rgb(40, 140, 80), legColor = rgb(160, 150, 140), measure = "length" })
		for i = 1, 6 do
			local p = V(1.4 + i * 1.3, 2.6 - i * 0.28, -0.6)
			ball(m, 0.6, p, rgb(30, 90, 200))
			ball(m, 0.3, p + V(0, 0, -0.2), rgb(240, 200, 60))
		end
		return measure
	end
	builders["Chicken"] = function(m)
		return bird(m, { legH = 1.2, body = { 2.4, 2, 1.8 }, tilt = 20, color = rgb(245, 240, 230), neck = 0.8, head = 1.1, beak = { 0.4, rgb(240, 180, 50) }, crest = rgb(225, 40, 40), tail = { 1.4, 50, 1.2 }, legColor = rgb(240, 180, 50) })
	end
	builders["Wild Turkey"] = function(m)
		local measure = bird(m, { legH = 2.6, body = { 4, 3, 2.6 }, tilt = 20, color = rgb(90, 60, 40), wing = rgb(120, 85, 55), neck = 1.6, head = 0.9, headColor = rgb(170, 200, 230), beak = { 0.4, rgb(220, 200, 160) }, tail = { 0.5, 60 }, legColor = rgb(200, 120, 110) })
		for i = -3, 3 do
			local a = math.rad(70 + i * 16)
			slab(m, V(1.6, 4.4, 0), V(1.6 + math.cos(a) * 3.4, 4.4 + math.sin(a) * 3.4, 0), 0.2, 1.1, i % 2 == 0 and rgb(110, 75, 45) or rgb(150, 105, 65))
		end
		ball(m, 0.5, V(-2.6, 6.4, 0), rgb(210, 50, 50)) -- wattle
		return math.max(measure, 4.4 + 3.4)
	end
	builders["Mallard Duck"] = function(m)
		return bird(m, { legH = 0.5, body = { 3.2, 1.8, 1.8 }, tilt = 0, color = rgb(150, 125, 100), wing = rgb(120, 100, 85), neck = 0.7, head = 1.1, headColor = rgb(30, 120, 60), beak = { 0.8, rgb(240, 200, 40), 0.1, 0.3 }, tail = { 0.6, 20 }, legColor = rgb(240, 140, 40), measure = "length" })
	end
	builders["Mute Swan"] = function(m)
		return bird(m, { legH = 0.4, body = { 4.6, 2.2, 2.4 }, tilt = -5, color = WHITE, neck = 3.4, head = 1, beak = { 1, rgb(240, 120, 40), 0.2, 0.35 }, tail = { 0.8, 25 }, legColor = BLACK, measure = "length" })
	end
	builders["Canada Goose"] = function(m)
		return bird(m, { legH = 1.2, body = { 3.6, 2, 2 }, tilt = 5, color = rgb(130, 110, 90), belly = rgb(225, 220, 210), neck = 2.4, neckColor = BLACK, head = 1, headColor = BLACK, beak = { 0.7, BLACK }, tail = { 0.7, 15 }, legColor = BLACK, measure = "length" })
	end
	builders["Rock Pigeon"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.2, 1.4, 1.3 }, tilt = 20, color = rgb(130, 135, 150), wing = rgb(160, 165, 178), neck = 0.4, head = 0.9, neckColor = rgb(100, 140, 120), beak = { 0.35, rgb(60, 60, 65) }, tail = { 1.6, -10, 0.9 }, tailColor = rgb(100, 105, 120), legColor = rgb(220, 90, 90), measure = "length" })
	end
	builders["American Crow"] = function(m)
		return bird(m, { legH = 0.8, body = { 2.6, 1.4, 1.3 }, tilt = 20, color = rgb(30, 30, 38), neck = 0.4, head = 1, beak = { 0.8, rgb(25, 25, 30), 0.1, 0.35 }, tail = { 2, -12, 0.9 }, legColor = rgb(25, 25, 30), measure = "length" })
	end
	builders["Scarlet Macaw"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.6, 1.6, 1.4 }, tilt = 65, color = rgb(220, 30, 40), wing = rgb(250, 200, 40), neck = 0.3, head = 1.2, beak = { 0.5, rgb(235, 225, 210), 0.4, 0.5 }, tail = { 4.4, -100, 0.6 }, tailColor = rgb(40, 90, 200), legColor = rgb(100, 100, 105), measure = "long" })
	end
	builders["Toco Toucan"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.4, 1.6, 1.4 }, tilt = 60, color = rgb(25, 25, 30), belly = WHITE, neck = 0.2, head = 1.1, beak = { 2.6, rgb(250, 140, 30), 0.3, 0.8 }, tail = { 2.2, -105, 0.7 }, legColor = rgb(60, 110, 200), measure = "long" })
	end
	builders["Great Horned Owl"] = function(m)
		local measure = bird(m, { legH = 0.6, body = { 3, 2.6, 2.4 }, tilt = 80, color = rgb(130, 100, 70), belly = rgb(200, 180, 150), neck = 0, head = 2, beak = { 0.3, rgb(50, 45, 40), 0.3, 0.35 }, tail = { 0.6, -100 }, legColor = rgb(200, 180, 150) })
		for _, z in ipairs({ -0.55, 0.55 }) do
			box(m, V(0.35, 0.9, 0.35), V(-0.2, measure + 0.25, z), rgb(110, 85, 60)) -- ear tufts
			ball(m, 0.6, V(-1.25, measure - 0.85, z * 1.05), rgb(250, 190, 40))
		end
		return measure + 0.6
	end
	builders["Ruby-throated Hummingbird"] = function(m)
		local measure = bird(m, { legH = 0.3, body = { 1.8, 0.9, 0.8 }, tilt = 30, color = rgb(70, 150, 90), belly = rgb(225, 225, 225), neck = 0.1, head = 0.7, beak = { 1.4, BLACK, -0.1, 0.12 }, tail = { 0.8, -30, 0.5 }, legColor = BLACK, measure = "length" })
		ball(m, 0.5, V(-0.95, 1.05, 0), rgb(220, 30, 60))
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(0.5, 2.2, 0.08), CFrame.new(0.1, 1.9, s * 0.5) * CFrame.Angles(0, 0, 0.4), rgb(160, 200, 190), nil).Transparency = 0.3
		end
		return measure
	end
	builders["Emu"] = function(m)
		return bird(m, { legH = 5, body = { 4.4, 3.2, 2.8 }, tilt = 10, color = rgb(100, 85, 70), neck = 3.4, neckColor = rgb(120, 130, 160), head = 0.9, beak = { 0.6, rgb(60, 55, 50) }, tail = { 0.6, -40 }, legColor = rgb(120, 110, 100) })
	end
	builders["Southern Cassowary"] = function(m)
		local measure = bird(m, { legH = 4.4, body = { 4.4, 3.4, 3 }, tilt = 15, color = rgb(25, 25, 30), neck = 3, neckColor = rgb(40, 110, 220), head = 1, headColor = rgb(40, 110, 220), beak = { 0.7, BLACK }, tail = { 0.6, -40 }, legColor = rgb(120, 110, 90) })
		box(m, V(0.8, 1.2, 0.5), V(-2.6, measure + 0.4, 0), rgb(120, 90, 60)) -- casque
		box(m, V(0.3, 1, 0.5), V(-2.6, measure - 2.2, 0), rgb(220, 40, 40)) -- wattle
		return measure + 1
	end
	builders["Brown Kiwi"] = function(m)
		return bird(m, { legH = 0.9, body = { 3, 2.6, 2.4 }, tilt = 0, color = rgb(130, 100, 70), neck = 0, head = 1.1, beak = { 2, rgb(225, 205, 175), 0.9, 0.2 }, tail = { 0.2, 0 }, legColor = rgb(200, 180, 150) })
	end
	builders["Atlantic Puffin"] = function(m)
		return bird(m, { legH = 0.6, body = { 2, 2.2, 1.6 }, tilt = 55, color = rgb(25, 25, 30), belly = WHITE, neck = 0, head = 1.3, headColor = rgb(230, 230, 230), beak = { 0.6, rgb(240, 110, 40), 0.15, 0.6 }, tail = { 0.4, -80 }, legColor = rgb(240, 120, 40) })
	end
	builders["Shoebill"] = function(m)
		return bird(m, { legH = 4.4, body = { 3, 3.2, 2.4 }, tilt = 60, color = rgb(130, 140, 150), neck = 1, head = 1.6, beak = { 1.6, rgb(200, 180, 140), 0.4, 1 }, tail = { 0.6, -90 }, legColor = rgb(60, 60, 65) })
	end
	builders["Secretary Bird"] = function(m)
		local measure = bird(m, { legH = 5.6, body = { 3.4, 2, 2 }, tilt = 15, color = rgb(200, 205, 210), wing = BLACK, neck = 1.8, head = 1, beak = { 0.5, rgb(90, 90, 95), 0.2 }, tail = { 3.4, -60, 0.8 }, legColor = rgb(240, 180, 120) })
		for i = 0, 3 do
			beam(m, V(-0.4, measure - 0.6, 0), V(0.8 + i * 0.25, measure + 0.5 - i * 0.25, 0), 0.15, BLACK)
		end
		return measure + 0.3
	end
	builders["White Stork"] = function(m)
		return bird(m, { legH = 4.4, body = { 3.6, 2, 2 }, tilt = 10, color = WHITE, wing = BLACK, neck = 2.2, head = 1, beak = { 2, rgb(225, 50, 40), 0.6, 0.35 }, tail = { 0.8, -20 }, legColor = rgb(225, 50, 40) })
	end
	builders["Great Blue Heron"] = function(m)
		return bird(m, { legH = 5, body = { 3.4, 1.8, 1.8 }, tilt = 25, color = rgb(120, 140, 165), neck = 3.6, neckColor = rgb(170, 175, 185), head = 0.9, crest = BLACK, beak = { 1.8, rgb(230, 200, 80), 0.2, 0.3 }, tail = { 1, -20 }, legColor = rgb(150, 140, 120) })
	end
	builders["Andean Condor"] = function(m)
		return flyer(m, { span = 32, bodyL = 6, bodyW = 3, color = BLACK, wing = BLACK, tip = rgb(230, 230, 230), chord = 4.4, tipChord = 3.2, sweep = 1.2, head = 1.6, headColor = rgb(200, 120, 110), beak = { 0.8, rgb(220, 210, 190) }, tail = { 2.6, 2.2 } })
	end
	builders["Wandering Albatross"] = function(m)
		return flyer(m, { span = 31, bodyL = 5, bodyW = 2.6, color = WHITE, wing = WHITE, tip = BLACK, chord = 2.4, tipChord = 1.6, sweep = -0.4, head = 1.5, beak = { 1.2, rgb(240, 190, 160) }, tail = { 1.2, 1.4 } })
	end
	builders["Large Flying Fox"] = function(m)
		local brown = rgb(70, 55, 45)
		local measure = flyer(m, { span = 15, bodyL = 4, bodyW = 2, color = rgb(130, 85, 45), wing = brown, chord = 4.4, tipChord = 3.6, sweep = 1.6, head = 1.6, headColor = rgb(150, 100, 55) })
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(0.4, 0.8, 0.4), V(s * 0.5, 5.3, 0), rgb(150, 100, 55)) -- ears
			for i = 1, 3 do
				beam(m, V(s * 1, 4.2, 0), V(s * i * 2.4, 4.2 + 1.6 - i * 1.4, 0), 0.15, rgb(50, 40, 35))
			end
		end
		return measure
	end

	--======================================================================
	-- Ocean
	--======================================================================
	builders["Humpback Whale"] = function(m)
		swimmer(m, 30, 7, rgb(50, 55, 70), rgb(220, 220, 225), 1.4)
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(-6, 3, s * 3.2), V(2, 1, s * 4.6), 2, 0.6, rgb(220, 220, 225))
		end
		return 30
	end
	builders["Sperm Whale"] = function(m)
		swimmer(m, 32, 7, rgb(85, 85, 95), rgb(120, 120, 130), 1.4)
		box(m, V(11, 7.4, 6.6), V(-11, 5.6, 0), rgb(85, 85, 95))
		box(m, V(8, 0.8, 1.6), V(-11.5, 2, 0), rgb(110, 110, 120)) -- lower jaw
		box(m, V(0.4, 0.4, 0.1), V(-8, 5, -3.35), BLACK)
		return 32
	end
	builders["Narwhal"] = function(m)
		swimmer(m, 9, 2.4, rgb(150, 155, 160), rgb(225, 225, 228), 0.3)
		for i = 0, 6 do
			box(m, V(0.6, 0.6, 2.2), V(-3 + i * 1.1, 2.6, 0), rgb(100, 105, 115))
		end
		taper(m, V(-5.2, 1.8, 0), V(-11.4, 2.6, 0), 0.22, 0.05, 4, rgb(240, 235, 215))
		return 9
	end
	builders["Beluga Whale"] = function(m)
		swimmer(m, 8, 2.8, rgb(240, 242, 245), rgb(225, 228, 232), 0.2)
		ell(m, V(1.8, 2, 2.2), V(-3.6, 2.8, 0), rgb(240, 242, 245)) -- melon
		return 8
	end
	builders["West Indian Manatee"] = function(m)
		return seal(m, { len = 9, thick = 3.4, color = rgb(130, 130, 135), head = 2.2, raise = 0, fluke = true })
	end
	builders["Walrus"] = function(m)
		local measure = seal(m, { len = 9, thick = 4, color = rgb(170, 120, 95), head = 2.6, raise = 1.6 })
		local head = V(-4.5 + 1.3, 2.4 + 1.6, 0)
		for _, z in ipairs({ -0.5, 0.5 }) do
			beam(m, head + V(-1, -0.8, z), head + V(-1.2, -3.2, z), 0.35, rgb(245, 240, 225))
		end
		ell(m, V(1.2, 1, 2), head + V(-1.1, -0.4, 0), rgb(200, 160, 135))
		return measure
	end
	builders["California Sea Lion"] = function(m)
		return seal(m, { len = 7, thick = 2.2, color = rgb(110, 80, 55), head = 1.5, raise = 2.4 })
	end
	builders["Harbor Seal"] = function(m)
		local measure = seal(m, { len = 6, thick = 2.2, color = rgb(150, 150, 155), belly = rgb(200, 200, 205), head = 1.6, raise = 0.6 })
		for i = 1, 10 do
			box(m, V(0.3, 0.3, 2.1), V(-2 + (i * 37 % 50) / 10, 1 + (i * 17 % 10) / 10, 0), rgb(90, 90, 95))
		end
		return measure
	end
	builders["Sea Otter"] = function(m)
		local brown = rgb(110, 80, 60)
		ell(m, V(5, 1.6, 1.8), V(0, 1, 0), brown)
		local head = V(-2.8, 1.4, 0)
		ball(m, 1.6, head, rgb(200, 185, 165))
		eyes(m, head, 0.8, 0.22)
		ball(m, 0.3, head + V(-0.8, 0, 0), BLACK)
		ball(m, 0.9, V(-1.4, 2, 0), rgb(130, 100, 80)) -- paws holding a shell
		box(m, V(1.6, 0.4, 0.8), V(3.2, 1.3, 0), brown)
		return 7.6
	end
	builders["Great Hammerhead"] = function(m)
		swimmer(m, 18, 3.6, rgb(130, 140, 150), WHITE, 4)
		box(m, V(1.2, 0.8, 6), V(-9.6, 2.7, 0), rgb(130, 140, 150))
		for _, z in ipairs({ -3, 3 }) do
			box(m, V(0.3, 0.3, 0.1), V(-9.8, 2.8, z - 0.05 * z), BLACK)
		end
		return 18
	end
	builders["Whale Shark"] = function(m)
		swimmer(m, 24, 5.6, rgb(70, 90, 115), rgb(225, 228, 232), 3)
		for i = 1, 18 do
			box(m, V(0.4, 0.4, 5.2), V(-9 + (i * 41 % 180) / 10, 5 + (i * 23 % 25) / 10, 0), WHITE)
		end
		box(m, V(0.6, 0.8, 4), V(-14, 3.6, 0), rgb(40, 50, 65)) -- wide mouth
		return 24
	end
	builders["Giant Manta Ray"] = function(m)
		local back, belly = rgb(40, 45, 60), rgb(225, 228, 232)
		local measure = flyer(m, { span = 28, bodyL = 9, bodyW = 6, color = back, wing = back, tip = rgb(55, 60, 75), chord = 7, tipChord = 3, sweep = -2.4, head = 2, tail = { 6, 0.4 } })
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(0.9, 2.6, 0.5), V(s * 1.6, 17.2, -0.2), back) -- head fins
			ell(m, V(2.4, 3, 0.2), V(s * 1.6, 12.4, -2.3), belly) -- pale shoulder patches
		end
		return measure
	end
	builders["Swordfish"] = function(m)
		swimmer(m, 10, 2, rgb(70, 80, 120), rgb(200, 205, 215), 2.2)
		beam(m, V(-5.2, 1.5, 0), V(-11, 1.6, 0), 0.25, rgb(70, 80, 120))
		return 16.5
	end
	builders["Clownfish"] = function(m)
		swimmer(m, 4, 1.8, rgb(250, 120, 30), rgb(250, 140, 50), 0.8)
		for _, x in ipairs({ -1.4, 0, 1.3 }) do
			box(m, V(0.35, 1.9, 1.75), V(x, 1.45, 0), WHITE)
		end
		return 4
	end
	builders["Goldfish"] = function(m)
		swimmer(m, 4, 2, rgb(250, 150, 40), rgb(255, 190, 90), 1)
		for _, a in ipairs({ 0.5, -0.5 }) do
			ell(m, V(2.4, 1.2, 0.15), CFrame.new(2.8, 1.8, 0) * CFrame.Angles(0, 0, a), rgb(255, 170, 70))
		end
		return 4.5
	end
	builders["Atlantic Bluefin Tuna"] = function(m)
		swimmer(m, 12, 3.2, rgb(30, 50, 100), rgb(210, 215, 225), 1.6)
		for i = 0, 5 do
			box(m, V(0.35, 0.35, 0.8), V(1 + i * 0.6, 1.6, 0), rgb(250, 210, 40))
		end
		return 12
	end
	builders["Atlantic Salmon"] = function(m)
		swimmer(m, 8, 1.8, rgb(140, 155, 170), rgb(240, 200, 195), 1)
		for i = 1, 8 do
			box(m, V(0.2, 0.2, 1.65), V(-2.5 + i * 0.6, 1.8 + (i % 2) * 0.2, 0), BLACK)
		end
		return 8
	end
	builders["Common Octopus"] = function(m)
		local red = rgb(210, 100, 80)
		ell(m, V(3.6, 4, 3.2), V(0.6, 6, 0), red)
		ell(m, V(2.6, 2, 2.6), V(0, 3.6, 0), red)
		for _, s in ipairs({ -1, 1 }) do
			ball(m, 0.7, V(-1.2, 3.9, s * 0.8), rgb(250, 230, 150))
		end
		for i = 1, 8 do
			local x = -1 + 2 * (i - 1) / 7
			local z = (i % 2 == 0) and 0.6 or -0.6
			local mid = V(x * 2.6, 1.6, z)
			local tip = V(x * 5.2, 0.4 + (i % 2) * 0.5, z * 1.5)
			taper(m, V(x * 0.8, 2.8, z * 0.5), mid, 0.5, 0.35, 2, red)
			taper(m, mid, tip, 0.35, 0.1, 2, red)
		end
		return 10.4
	end
	builders["Giant Squid"] = function(m)
		local red = rgb(200, 90, 75)
		ell(m, V(10, 2.6, 2.6), V(5, 1.6, 0), red)
		Kit.wedge(m, V(0.2, 2.2, 2.4), CFrame.new(9.4, 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0), red)
		ball(m, 2, V(-0.6, 1.6, 0), red)
		eyes(m, V(-0.6, 1.6, 0), 1, 0.7, rgb(30, 30, 40))
		for i = 1, 8 do
			taper(m, V(-1.4, 1.6 + (i - 4.5) * 0.15, (i - 4.5) * 0.15), V(-7, 1.6 + (i - 4.5) * 0.4, (i - 4.5) * 0.3), 0.25, 0.08, 3, red)
		end
		for _, s in ipairs({ -1, 1 }) do
			taper(m, V(-1.4, 1.6, s * 0.3), V(-13, 1.6 + s * 0.7, s * 0.5), 0.12, 0.05, 4, red)
			ell(m, V(1.4, 0.5, 0.5), V(-13.4, 1.6 + s * 0.7, s * 0.5), red)
		end
		return 24
	end
	builders["Moon Jellyfish"] = function(m)
		local jelly = rgb(200, 210, 255)
		local bell = ell(m, V(6, 3, 6), V(0, 7, 0), jelly)
		bell.Transparency = 0.25
		for i = 0, 3 do
			ell(m, V(0.9, 0.9, 0.6), V(-1.6 + i * 1.05, 7, -1.6), rgb(240, 160, 220))
		end
		for i = -5, 5 do
			rod(m, V(i * 0.55, 5.6, 0), V(i * 0.6 + math.sin(i) * 0.4, 0.4, 0), 0.06, jelly)
		end
		return 6
	end
	builders["Seahorse"] = function(m)
		local yellow = rgb(240, 180, 60)
		taper(m, V(0.8, 5, 0), V(0.6, 2.4, 0), 0.9, 0.7, 3, yellow)
		ell(m, V(1.6, 2.4, 1.2), V(0.4, 3.6, 0), yellow)
		ball(m, 1.2, V(0.8, 5.6, 0), yellow)
		beam(m, V(0.3, 5.6, 0), V(-1, 5.3, 0), 0.4, yellow)
		eyes(m, V(0.8, 5.6, 0), 0.6, 0.25)
		for i = 0, 5 do
			local a = i * 0.9
			local p = V(0.8 + math.sin(a) * 0.7 * (1 - i / 7), 2.2 - i * 0.35, 0)
			ball(m, 0.6 - i * 0.07, p, yellow)
		end
		box(m, V(0.2, 0.9, 0.6), V(1.3, 3.8, 0), rgb(250, 220, 140)) -- fin
		return 6.2
	end
	builders["Common Starfish"] = function(m)
		local orange = rgb(240, 110, 50)
		ball(m, 1.4, V(0, 0.5, 0), orange)
		for i = 0, 4 do
			local a = math.rad(i * 72)
			taper(m, V(0, 0.4, 0), V(math.cos(a) * 3, 0.2, math.sin(a) * 3), 0.6, 0.15, 3, orange)
		end
		return 6
	end
	builders["American Lobster"] = function(m)
		local red = rgb(190, 60, 40)
		local measure = insect(m, { len = 6, h = 1.4, legH = 0.5, color = red, headFrac = 0.18, thoraxFrac = 0.35, legColor = red, antenna = 4 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-2, 1, s * 0.6), V(-3.4, 1.3, s * 1.2), 0.35, red)
			ell(m, V(2.4, 1.1, 0.9), V(-4.4, 1.4, s * 1.3), red)
		end
		ell(m, V(1.4, 0.3, 2.2), V(3.4, 1.2, 0), red) -- tail fan
		return measure
	end
	builders["Japanese Spider Crab"] = function(m)
		local orange = rgb(220, 110, 60)
		local measure = legs(m, { body = 3, h = 2, legH = 2.4, reach = 15, legT = 0.18, color = orange, pairs = 4, legColor = rgb(235, 140, 90) })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-1.2, 3.2, s * 0.6), V(-4, 2.6, s * 1.2), 0.25, orange)
		end
		return measure
	end
	builders["Green Sea Turtle"] = function(m)
		return turtle(m, { r = 4, shell = rgb(110, 115, 70), skin = rgb(140, 150, 110), under = rgb(220, 210, 160), pattern = rgb(90, 80, 50), flippers = true, legH = 0.8 })
	end
	builders["Megalodon"] = function(m)
		swimmer(m, 30, 8, rgb(105, 115, 130), WHITE, 6)
		for i = 0, 5 do
			box(m, V(0.5, 0.8, 0.4), V(-16 + i * 0.8, 4.8, -3.4), WHITE)
		end
		return 30
	end

	--======================================================================
	-- Reptiles and amphibians
	--======================================================================
	builders["Komodo Dragon"] = function(m)
		return lizard(m, { len = 5, h = 1.6, legH = 1, w = 1.8, tail = 5, head = { 2, 1.1 }, color = rgb(110, 105, 85), belly = rgb(150, 140, 110) })
	end
	builders["Green Anaconda"] = function(m)
		return snake(m, { len = 30, thick = 1.6, color = rgb(85, 100, 50), pattern = rgb(40, 40, 30) })
	end
	builders["King Cobra"] = function(m)
		return snake(m, { len = 20, thick = 0.9, color = rgb(110, 95, 50), pattern = rgb(220, 200, 120), rise = 4.4, hood = rgb(130, 110, 60) })
	end
	builders["Rattlesnake"] = function(m)
		return snake(m, { len = 12, thick = 0.9, color = rgb(180, 150, 100), pattern = rgb(110, 85, 55), rise = 1, rattle = rgb(220, 200, 160) })
	end
	builders["Green Iguana"] = function(m)
		return lizard(m, { len = 3.6, h = 1.4, legH = 0.8, w = 1.4, tail = 7, head = { 1.6, 1.2 }, color = rgb(90, 170, 70), spikes = rgb(70, 130, 55), tailColor = rgb(80, 140, 60) })
	end
	builders["Panther Chameleon"] = function(m)
		local measure = lizard(m, { len = 3, h = 1.8, legH = 0.6, w = 1, tail = 2.6, head = { 1.4, 1.4 }, color = rgb(60, 160, 200), belly = rgb(240, 200, 60), eye = rgb(240, 140, 40) })
		box(m, V(0.7, 0.7, 0.6), V(-1.8, 2.3, 0), rgb(60, 160, 200)) -- helmet crest
		ball(m, 1.2, V(3.4, 0.7, 0), rgb(60, 160, 200)) -- curled tail
		return measure
	end
	builders["Leopard Gecko"] = function(m)
		local measure = lizard(m, { len = 3.2, h = 1, legH = 0.6, w = 1.1, tail = 2.6, head = { 1.4, 0.9 }, color = rgb(240, 210, 80), belly = rgb(250, 240, 210) })
		for i = 1, 8 do
			box(m, V(0.25, 0.25, 1.15), V(-1.4 + i * 0.5, 1.3 + (i % 2) * 0.2, 0), rgb(60, 50, 40))
		end
		return measure
	end
	builders["American Alligator"] = function(m)
		return lizard(m, { len = 7, h = 1.8, legH = 0.8, w = 3, tail = 8, head = { 4, 1.1 }, color = rgb(55, 65, 45), belly = rgb(190, 185, 150), spikes = rgb(45, 55, 38) })
	end
	builders["Eastern Box Turtle"] = function(m)
		return turtle(m, { r = 3, shell = rgb(120, 85, 40), skin = rgb(100, 90, 70), under = rgb(190, 160, 90), pattern = rgb(240, 190, 60) })
	end
	builders["Axolotl"] = function(m)
		local pink = rgb(250, 175, 190)
		local measure = lizard(m, { len = 3.4, h = 1.4, legH = 0.6, w = 1.4, tail = 3, head = { 1.8, 1.4 }, color = pink, eye = BLACK })
		for _, s in ipairs({ -1, 1 }) do
			for i = 0, 2 do
				beam(m, V(-2.6, 1.6 + i * 0.35, s * 0.6), V(-2 + i * 0.1, 2.4 + i * 0.5, s * 1.5), 0.2, rgb(240, 90, 130))
			end
		end
		return measure
	end
	builders["Strawberry Poison Frog"] = function(m)
		local measure = frog(m, 1, rgb(220, 30, 40), rgb(40, 70, 170))
		for i = 0, 4 do
			box(m, V(0.3, 0.3, 2.65), V(-1 + i * 0.5, 1.4 + (i % 2) * 0.4, 0), BLACK)
		end
		return measure
	end
	builders["American Bullfrog"] = function(m)
		return frog(m, 1.3, rgb(100, 130, 60), rgb(80, 105, 50))
	end

	--======================================================================
	-- Bugs and other small creatures
	--======================================================================
	builders["Honeybee"] = function(m)
		return insect(m, { len = 4, h = 1.6, color = rgb(240, 180, 40), abdomen = rgb(240, 180, 40), stripes = BLACK, wings = rgb(220, 235, 245), wingLen = 2.4, abdomenLift = -0.1 })
	end
	builders["Ladybug"] = function(m)
		local measure = insect(m, { len = 3, h = 1.6, legH = 0.4, color = BLACK, headFrac = 0.22, thoraxFrac = 0.18, abdomen = rgb(220, 30, 30) })
		for i = 1, 5 do
			box(m, V(0.35, 0.35, 1.55), V(-0.2 + (i % 3) * 0.6, 1.5 + (i % 2) * 0.45, 0), BLACK)
		end
		return measure
	end
	builders["Monarch Butterfly"] = function(m)
		local orange = rgb(240, 130, 30)
		ell(m, V(0.5, 3.4, 0.5), V(0, 4, 0), BLACK)
		ball(m, 0.6, V(0, 5.9, 0), BLACK)
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(4.6, 3.4, 0.1), CFrame.new(s * 2.4, 5.2, 0.05) * CFrame.Angles(0, 0, s * 0.35), orange)
			ell(m, V(3.6, 2.8, 0.1), CFrame.new(s * 1.8, 2.8, 0.05) * CFrame.Angles(0, 0, -s * 0.3), orange)
			ell(m, V(4.8, 0.4, 0.12), CFrame.new(s * 2.4, 6.4, 0.02) * CFrame.Angles(0, 0, s * 0.35), BLACK)
			for i = 1, 3 do
				ball(m, 0.3, V(s * (1.6 + i * 1.1), 6.2 - i * 0.2, -0.05), WHITE)
			end
			rod(m, V(s * 0.1, 6.2, 0), V(s * 0.9, 7.6, 0), 0.05, BLACK)
		end
		return 9.6
	end
	builders["Black Garden Ant"] = function(m)
		return insect(m, { len = 4, h = 1, legH = 0.8, color = BLACK, headFrac = 0.25, thoraxFrac = 0.3, abdomen = rgb(40, 35, 35) })
	end
	builders["Goliath Birdeater"] = function(m)
		local brown = rgb(110, 75, 55)
		return legs(m, { body = 2.4, h = 1.6, legH = 1.6, reach = 3.6, legT = 0.3, color = brown, pairs = 4, abdomen = { 2.8, 2.2 }, eyeColor = rgb(20, 20, 20) })
	end
	builders["Emperor Scorpion"] = function(m)
		local black = rgb(30, 30, 40)
		local measure = insect(m, { len = 5, h = 1, legH = 0.6, color = black, headFrac = 0.2, thoraxFrac = 0.35, legColor = black, antenna = 0.1 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-2.4, 1, s * 0.5), V(-3.4, 1.1, s * 1.2), 0.3, black)
			ell(m, V(1.6, 0.8, 0.8), V(-4.2, 1.2, s * 1.2), black)
		end
		local p = V(2.5, 1.1, 0)
		for i = 1, 5 do
			local a = math.rad(20 + i * 30)
			local q2 = p + V(math.cos(a) * 0.9, math.sin(a) * 0.9, 0)
			rod(m, p, q2, 0.25, black)
			p = q2
		end
		ball(m, 0.5, p, rgb(140, 90, 40))
		return measure
	end
	builders["Praying Mantis"] = function(m)
		local green = rgb(120, 190, 80)
		local measure = insect(m, { len = 6, h = 0.8, legH = 1.2, color = green, headFrac = 0.1, thoraxFrac = 0.35, legColor = green, wings = rgb(150, 210, 110), wingLen = 2.6, antenna = 1.5 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-1.8, 2, s * 0.3), V(-2.6, 3, s * 0.5), 0.2, green)
			beam(m, V(-2.6, 3, s * 0.5), V(-2.6, 2.2, s * 0.5), 0.2, green)
		end
		ell(m, V(0.6, 0.8, 1), V(-3.2, 2.3, 0), green)
		return measure
	end
	builders["Emperor Dragonfly"] = function(m)
		local blue = rgb(60, 140, 220)
		local measure = insect(m, { len = 8, h = 0.7, legH = 0.6, color = rgb(90, 160, 90), headFrac = 0.1, thoraxFrac = 0.15, abdomen = blue, eyeColor = rgb(80, 180, 120), antenna = 0.2 })
		for _, s in ipairs({ -1, 1 }) do
			for _, dx in ipairs({ -0.3, 0.5 }) do
				ell(m, V(1, 4, 0.06), CFrame.new(-2.4 + dx * 1.6, 3, s * 0.3) * CFrame.Angles(0, 0, dx * 0.4), rgb(210, 230, 240)).Transparency = 0.3
			end
		end
		return measure
	end
	builders["Garden Snail"] = function(m)
		local skin = rgb(170, 150, 120)
		ell(m, V(5, 0.8, 1.2), V(0, 0.4, 0), skin)
		beam(m, V(-2, 0.4, 0), V(-2.6, 1.6, 0), 0.6, skin)
		for _, z in ipairs({ -0.2, 0.2 }) do
			rod(m, V(-2.6, 1.6, z), V(-2.9, 2.6, z * 2), 0.06, skin)
			ball(m, 0.2, V(-2.9, 2.6, z * 2), BLACK)
		end
		ball(m, 3, V(0.4, 2.1, 0), rgb(150, 100, 50))
		ball(m, 2, V(0.2, 2.2, -0.6), rgb(180, 130, 70))
		ball(m, 1, V(0.1, 2.3, -1.1), rgb(150, 100, 50))
		return 5
	end
	builders["Earthworm"] = function(m)
		return snake(m, { len = 10, thick = 0.5, color = rgb(210, 130, 130), pattern = rgb(190, 110, 115), headColor = rgb(220, 140, 140) })
	end
	builders["Atlas Moth"] = function(m)
		local rust = rgb(170, 70, 40)
		ell(m, V(0.8, 3, 0.8), V(0, 4.4, 0), rgb(140, 60, 40))
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(6, 4.2, 0.1), CFrame.new(s * 3, 5.6, 0.05) * CFrame.Angles(0, 0, s * 0.2), rust)
			ell(m, V(4.6, 3.6, 0.1), CFrame.new(s * 2.2, 2.8, 0.05) * CFrame.Angles(0, 0, -s * 0.3), rgb(150, 60, 35))
			ell(m, V(1.2, 0.8, 0.12), V(s * 3, 5.6, 0), rgb(250, 240, 220))
			ell(m, V(1.4, 1.6, 0.12), V(s * 5.6, 6.8, 0), rgb(240, 200, 120)) -- snake-head wing tips
			rod(m, V(s * 0.2, 5.8, 0), V(s * 1, 7, 0), 0.15, rgb(200, 150, 90))
		end
		return 12
	end
	builders["Hercules Beetle"] = function(m)
		insect(m, { len = 6, h = 2, legH = 0.8, color = BLACK, headFrac = 0.15, thoraxFrac = 0.25, abdomen = rgb(180, 160, 90) })
		beam(m, V(-1.6, 3.2, 0), V(-5, 3.4, 0), 0.4, BLACK) -- upper horn
		beam(m, V(-2.6, 2, 0), V(-4.6, 2.6, 0), 0.3, BLACK) -- lower horn
		return 8
	end
	builders["Grasshopper"] = function(m)
		local green = rgb(130, 180, 60)
		local measure = insect(m, { len = 5, h = 1.1, legH = 0.6, color = green, headFrac = 0.18, thoraxFrac = 0.3, legColor = rgb(110, 150, 50), wings = rgb(150, 170, 90), wingLen = 2.6, antenna = 2 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(0, 1.4, s * 0.5), V(1.6, 2.6, s * 0.6), 0.3, green)
			beam(m, V(1.6, 2.6, s * 0.6), V(2.4, 0.1, s * 0.6), 0.2, green)
		end
		return measure
	end

	--======================================================================
	-- Dinosaurs
	--======================================================================
	builders["Triceratops"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 2.8, width = 4, color = rgb(150, 120, 80), headLen = 3.6, headH = 2.8, neck = -0.4, ear = { 0.1, 0.1 }, tail = 5 }
		quad(m, o)
		local hx, hy = quadHead(o)
		box(m, V(0.8, 4.6, 4.6), V(hx + 2, hy + 1.6, 0), rgb(175, 110, 70)) -- frill
		for _, z in ipairs({ -0.8, 0.8 }) do
			beam(m, V(hx, hy + 1.2, z), V(hx - 2.4, hy + 3, z), 0.35, rgb(240, 230, 200))
		end
		beam(m, V(hx - 1.4, hy + 0.4, 0), V(hx - 2, hy + 1.4, 0), 0.4, rgb(240, 230, 200))
		local head = hx - o.headLen / 2 - 0.4
		return (o.len / 2 + o.tail * 0.7) - head
	end
	builders["Stegosaurus"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 3.4, width = 3.4, color = rgb(120, 140, 80), headLen = 2, headH = 1.4, neck = -2.2, ear = { 0.1, 0.1 }, tail = 6 }
		quad(m, o)
		for i = -3, 3 do
			local h = 2.6 - math.abs(i) * 0.4
			Kit.peak(m, i * 1.2, 7.8, 0, 0.6, h, 0.4, rgb(200, 110, 70))
		end
		for _, z in ipairs({ -0.4, 0.4 }) do
			beam(m, V(8, 5.4, z), V(9.2, 6.4, z * 3), 0.25, rgb(235, 225, 195))
		end
		local hx = quadHead(o)
		return (o.len / 2 + o.tail * 0.7 + 0.6) - (hx - o.headLen / 2)
	end
	builders["Brachiosaurus"] = function(m)
		local o = { len = 10, bodyH = 5, legH = 6.4, width = 4, color = rgb(120, 140, 120), headLen = 2.4, headH = 1.6, neck = 10, ear = { 0.1, 0.1 }, tail = 6 }
		quad(m, o)
		local _, hy = quadHead(o)
		return hy + o.headH / 2 + 0.2
	end
	builders["Velociraptor"] = function(m)
		local measure = theropod(m, { len = 4, h = 2, color = rgb(160, 120, 80), belly = rgb(215, 190, 150), head = { 1.6, 0.8 }, tail = 4.4, arms = true })
		for i = 0, 3 do
			box(m, V(0.3, 0.6, 0.6), V(-1.2 + i * 0.8, 3.6, 0), rgb(110, 70, 50)) -- feathers
		end
		return measure
	end
	builders["Spinosaurus"] = function(m)
		return theropod(m, { len = 12, h = 6, color = rgb(110, 110, 90), belly = rgb(190, 180, 150), head = { 5, 1.6 }, tail = 12, arms = true, sail = 5, sailColor = rgb(190, 90, 70) })
	end
	builders["Pteranodon"] = function(m)
		local measure = flyer(m, { span = 24, bodyL = 4, bodyW = 1.8, color = rgb(200, 170, 130), wing = rgb(150, 110, 80), chord = 3.4, tipChord = 1.6, sweep = 1, head = 1.4, beak = { 3.4, rgb(220, 200, 160) } })
		beam(m, V(0, 5.4, 0), V(0, 3.8, 0.3), 0.4, rgb(200, 90, 60)) -- crest behind the head
		return measure
	end
end
