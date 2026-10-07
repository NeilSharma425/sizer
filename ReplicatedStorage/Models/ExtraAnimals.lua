--[[
	ExtraAnimals.lua
	ModuleScript: ReplicatedStorage.Models.ExtraAnimals

	Low-poly animal models for ObjectModels. Side-on views facing -X (like
	the originals). Every builder returns `measure`: the model-unit length
	that matches the real size listed in ExtraObjects.

	Usage: require(ExtraAnimals)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, vcyl = Kit.box, Kit.ball, Kit.beam, Kit.vcyl
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new

-- Four-legged body with legs, head, ears and tail. Options:
-- len, bodyH, legH, width, color, belly, headLen, headH, neck (rise of the
-- head above the back), ear = {w, h}, tail (length), snout (color),
-- horns (color), mane (color), hump (height), stripes (color).
local function quad(m, o)
	local len, bh, lh, w = o.len, o.bodyH, o.legH, o.width
	local lw = o.legW or w * 0.3
	local color = o.color
	for _, x in ipairs({ -len / 2 + lw * 0.7, len / 2 - lw * 0.7 }) do
		for _, z in ipairs({ -w / 2 + lw / 2, w / 2 - lw / 2 }) do
			box(m, V(lw, lh, lw), V(x, lh / 2, z), o.legColor or color)
		end
	end
	box(m, V(len, bh, w), V(0, lh + bh / 2, 0), color)
	if o.belly then
		box(m, V(len * 0.8, bh * 0.35, w * 1.02), V(0, lh + bh * 0.2, 0), o.belly)
	end
	if o.stripes then
		for i = -2, 2 do
			box(m, V(len * 0.07, bh * 1.02, w * 1.02), V(i * len * 0.17, lh + bh / 2, 0), o.stripes)
		end
	end
	if o.hump then
		box(m, V(len * 0.28, o.hump, w * 0.8), V(len * 0.05, lh + bh + o.hump / 2, 0), color)
	end
	local hl, hh = o.headLen, o.headH
	local neck = o.neck or 0
	local hx = -len / 2 - hl * 0.35
	local hy = lh + bh + neck - hh * 0.1
	if neck > 0 then
		beam(m, V(-len / 2 + len * 0.1, lh + bh * 0.8, 0), V(hx + hl * 0.3, hy, 0), w * 0.55, color)
	end
	box(m, V(hl, hh, w * 0.75), V(hx, hy, 0), color)
	if o.snout then
		box(m, V(hl * 0.35, hh * 0.55, w * 0.6), V(hx - hl * 0.45, hy - hh * 0.2, 0), o.snout)
		box(m, V(hl * 0.08, hh * 0.15, w * 0.3), V(hx - hl * 0.66, hy - hh * 0.1, 0), BLACK)
	end
	if o.mane then
		box(m, V(hl * 0.8, hh * 1.25, w * 0.95), V(hx + hl * 0.55, hy, 0), o.mane)
	end
	local ear = o.ear or { w * 0.18, hh * 0.45 }
	for _, z in ipairs({ -w * 0.22, w * 0.22 }) do
		box(m, V(ear[1], ear[2], ear[1]), V(hx + hl * 0.2, hy + hh / 2 + ear[2] / 2, z), o.earColor or color)
		if o.horns then
			beam(m, V(hx + hl * 0.1, hy + hh / 2, z * 1.2), V(hx - hl * 0.1, hy + hh / 2 + ear[2] * 1.6, z * 1.8), w * 0.08, o.horns)
		end
	end
	box(m, V(hl * 0.12, hh * 0.18, 0.05 * w), V(hx - hl * 0.25, hy + hh * 0.18, -w * 0.38), BLACK)
	local tl = o.tail or len * 0.25
	beam(m, V(len / 2, lh + bh * 0.85, 0), V(len / 2 + tl * 0.7, lh + bh * 0.85 - tl * 0.5, 0), w * 0.12, o.tailColor or color)
end

-- Torpedo-shaped swimmer facing -X with fins.
local function swimmer(m, len, thick, color, belly, finH)
	local y = thick * 0.8
	box(m, V(len * 0.5, thick, thick * 0.9), V(0, y, 0), color)
	box(m, V(len * 0.25, thick * 0.8, thick * 0.8), V(-len * 0.34, y - thick * 0.05, 0), color)
	box(m, V(len * 0.18, thick * 0.55, thick * 0.55), V(-len * 0.5, y - thick * 0.1, 0), color)
	box(m, V(len * 0.3, thick * 0.65, thick * 0.7), V(len * 0.38, y + thick * 0.05, 0), color)
	box(m, V(len * 0.5, thick * 0.45, thick * 0.92), V(-len * 0.02, y - thick * 0.3, 0), belly)
	Kit.wedge(m, V(thick * 0.1, finH, len * 0.16), CFrame.new(-len * 0.02, y + thick / 2 + finH / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), color)
	box(m, V(len * 0.1, thick * 0.12, thick * 1.1), V(len * 0.5, y + thick * 0.15, 0), color)
	box(m, V(len * 0.14, thick * 0.1, thick * 1.3), V(-len * 0.18, y - thick * 0.45, 0), color)
	box(m, V(thick * 0.08, thick * 0.08, 0.1), V(-len * 0.4, y + thick * 0.15, -thick * 0.4), BLACK)
end

return function(builders)
	builders["Labrador Dog"] = function(m)
		quad(m, { len = 5, bodyH = 2.4, legH = 2.8, width = 2, color = rgb(222, 180, 100), headLen = 2, headH = 1.8, neck = 0.6, snout = rgb(200, 155, 80), ear = { 0.5, 1.2 }, earColor = rgb(170, 125, 60), tail = 2.5 })
		return 5.2
	end

	builders["Horse"] = function(m)
		quad(m, { len = 8, bodyH = 3.6, legH = 6, width = 2.6, color = rgb(140, 85, 50), legColor = rgb(120, 70, 40), headLen = 3.4, headH = 2.2, neck = 3.6, snout = rgb(110, 65, 40), mane = rgb(50, 30, 25), ear = { 0.4, 1 }, tail = 4, tailColor = rgb(50, 30, 25) })
		return 9.6 -- shoulder height ~1.6 m (the model's back line)
	end

	builders["Dairy Cow"] = function(m)
		quad(m, { len = 7, bodyH = 3.8, legH = 3.8, width = 3, color = WHITE, headLen = 2.6, headH = 2.4, neck = 0.2, snout = rgb(255, 190, 190), horns = rgb(240, 235, 215), ear = { 0.5, 0.6 }, tail = 3, tailColor = BLACK })
		for _, p in ipairs({ { -1.5, 5.5 }, { 1.2, 6.6 }, { 2.4, 4.8 }, { -0.4, 4.8 } }) do
			box(m, V(1.6, 1.3, 3.05), V(p[1], p[2], 0), BLACK)
		end
		return 7.6
	end

	builders["Sheep"] = function(m)
		local wool = rgb(245, 242, 232)
		quad(m, { len = 5, bodyH = 3.4, legH = 2.6, width = 3, color = wool, legColor = rgb(60, 55, 55), headLen = 1.8, headH = 2, neck = 0.1, snout = rgb(70, 62, 60), ear = { 0.6, 0.5 }, earColor = rgb(70, 62, 60), tail = 1 })
		box(m, V(1.8, 2.1, 1.7), V(-3.2, 4.6, 0), rgb(70, 62, 60))
		ball(m, 3.2, V(0, 5.2, 0), wool)
		return 6.4
	end

	builders["Pig"] = function(m)
		local pink = rgb(250, 175, 185)
		quad(m, { len = 5.4, bodyH = 3.2, legH = 1.6, width = 3, color = pink, headLen = 2, headH = 2.4, neck = -0.2, snout = rgb(245, 140, 155), ear = { 0.7, 0.7 }, earColor = rgb(240, 150, 165), tail = 1 })
		return 4.8
	end

	builders["Rabbit"] = function(m)
		local fur = rgb(190, 170, 150)
		quad(m, { len = 3.4, bodyH = 2.2, legH = 0.8, width = 1.8, color = fur, headLen = 1.5, headH = 1.5, neck = 0.1, snout = WHITE, ear = { 0.4, 2.2 }, tail = 0.5, tailColor = WHITE })
		ball(m, 1, V(2.1, 1.8, 0), WHITE)
		return 4.8
	end

	builders["White-tailed Deer"] = function(m)
		quad(m, { len = 6, bodyH = 3, legH = 5, width = 2.2, color = rgb(160, 110, 70), belly = rgb(240, 225, 205), legColor = rgb(135, 90, 55), headLen = 2.4, headH = 1.8, neck = 2.6, snout = rgb(120, 85, 55), ear = { 0.5, 1 }, tail = 1.4, tailColor = WHITE })
		for _, z in ipairs({ -0.5, 0.5 }) do
			beam(m, V(-4.2, 11.7, z), V(-3.8, 14, z * 2.2), 0.2, rgb(215, 195, 160))
			beam(m, V(-3.9, 13.4, z * 2), V(-4.8, 14.4, z * 2.6), 0.15, rgb(215, 195, 160))
		end
		return 8
	end

	builders["Lion"] = function(m)
		local tan = rgb(215, 165, 90)
		quad(m, { len = 7, bodyH = 3.2, legH = 3, width = 2.6, color = tan, headLen = 2.2, headH = 2.4, neck = 0.8, snout = rgb(235, 200, 140), mane = rgb(120, 70, 35), ear = { 0.5, 0.5 }, tail = 3.5, tailColor = tan })
		ball(m, 1, V(3.5 + 3.4, 2.3, 0), rgb(120, 70, 35))
		return 6.2
	end

	builders["Plains Zebra"] = function(m)
		quad(m, { len = 7, bodyH = 3.4, legH = 4.2, width = 2.4, color = WHITE, stripes = BLACK, headLen = 2.8, headH = 2, neck = 1.8, snout = rgb(60, 55, 55), mane = BLACK, ear = { 0.4, 0.8 }, earColor = BLACK, tail = 3, tailColor = BLACK })
		return 7.6
	end

	builders["Dromedary Camel"] = function(m)
		local sand = rgb(205, 165, 105)
		quad(m, { len = 7, bodyH = 3.6, legH = 6, width = 2.6, color = sand, hump = 2.2, headLen = 2.8, headH = 1.8, neck = 5, snout = rgb(170, 130, 85), ear = { 0.4, 0.6 }, tail = 2 })
		return 11.8
	end

	builders["Hippopotamus"] = function(m)
		local gray = rgb(150, 125, 140)
		quad(m, { len = 8, bodyH = 4.8, legH = 1.8, width = 4, color = gray, belly = rgb(190, 150, 160), headLen = 3.8, headH = 3.2, neck = 0, snout = rgb(185, 150, 165), ear = { 0.6, 0.6 }, tail = 1.2 })
		return 6.8
	end

	builders["White Rhinoceros"] = function(m)
		local gray = rgb(150, 150, 155)
		quad(m, { len = 8.4, bodyH = 4.4, legH = 3, width = 3.4, color = gray, headLen = 3.6, headH = 2.8, neck = -0.4, ear = { 0.6, 0.9 }, tail = 2 })
		beam(m, V(-6.8, 5.6, 0), V(-7.4, 7.6, 0), 0.9, rgb(225, 220, 205))
		return 7.4
	end

	builders["Polar Bear"] = function(m)
		quad(m, { len = 8, bodyH = 4.4, legH = 3.4, width = 3.2, color = rgb(250, 250, 255), headLen = 3, headH = 2.4, neck = 0.2, snout = rgb(235, 235, 245), ear = { 0.6, 0.6 }, tail = 0.8 })
		box(m, V(0.5, 0.5, 0.2), V(-5.6, 8.1, 0), BLACK)
		return 7.8
	end

	builders["Giant Panda"] = function(m)
		quad(m, { len = 5.6, bodyH = 4, legH = 2.6, width = 3.2, color = WHITE, legColor = BLACK, headLen = 2.4, headH = 2.6, neck = 0.3, snout = rgb(235, 235, 235), ear = { 0.7, 0.7 }, earColor = BLACK, tail = 0.6 })
		box(m, V(1, 4.05, 3.25), V(-1.6, 4.6, 0), BLACK)
		for _, z in ipairs({ -0.85, 0.85 }) do
			box(m, V(0.6, 0.7, 0.4), V(-4.6, 6.6, z), BLACK)
		end
		return 6.4
	end

	builders["Mountain Gorilla"] = function(m)
		local fur = rgb(55, 55, 62)
		for _, x in ipairs({ -1, 1 }) do
			box(m, V(1.5, 3, 1.6), V(x, 1.5, 0), fur)
		end
		box(m, V(5, 5.6, 3), V(0, 5.8, 0), fur)
		box(m, V(3.2, 3.4, 0.2), V(0, 5.6, -1.55), rgb(95, 90, 90))
		for _, x in ipairs({ -3.2, 3.2 }) do
			beam(m, V(x * 0.6, 7.8, 0), V(x, 3.2, -0.3), 1.3, fur)
			box(m, V(1.5, 1.2, 1.6), V(x, 2.6, -0.3), rgb(40, 40, 46))
		end
		box(m, V(2.4, 2.4, 2.2), V(0, 9.2, -0.2), fur)
		box(m, V(1.6, 1.2, 0.5), V(0, 8.9, -1.4), rgb(110, 100, 98))
		for _, x in ipairs({ -0.5, 0.5 }) do
			box(m, V(0.3, 0.3, 0.1), V(x, 9.6, -1.35), BLACK)
		end
		return 10.4
	end

	builders["Saltwater Crocodile"] = function(m)
		local green, belly = rgb(80, 105, 60), rgb(215, 215, 160)
		for _, x in ipairs({ -2.6, 3.4 }) do
			for _, z in ipairs({ -2.6, 2.6 }) do
				box(m, V(1, 1.3, 1), V(x, 0.65, z), green)
			end
		end
		box(m, V(9, 1.9, 4.6), V(0, 1.9, 0), green)
		box(m, V(8, 0.5, 4.2), V(0, 1.1, 0), belly)
		box(m, V(7.5, 0.7, 2.4), V(-8.2, 1.5, 0), green)
		box(m, V(3, 1.6, 3.4), V(-5.2, 1.7, 0), green)
		beam(m, V(4.5, 1.9, 0), V(12.5, 0.9, 0), 2.2, green)
		for i = 0, 8 do
			box(m, V(0.6, 0.5, 0.6), V(-3 + i * 1.5, 3, 0), rgb(60, 80, 45))
		end
		for _, z in ipairs({ -1.1, 1.1 }) do
			box(m, V(0.5, 0.5, 0.5), V(-5.6, 2.8, z), rgb(235, 220, 90))
		end
		return 21
	end

	builders["Great White Shark"] = function(m)
		swimmer(m, 20, 5, rgb(120, 130, 145), WHITE, 3.5)
		return 20
	end

	builders["Bottlenose Dolphin"] = function(m)
		swimmer(m, 12, 3, rgb(115, 135, 160), rgb(225, 230, 235), 1.8)
		beam(m, V(-6.6, 2.4, 0), V(-8, 2.1, 0), 0.8, rgb(105, 125, 150))
		return 12
	end

	builders["Orca"] = function(m)
		swimmer(m, 24, 6, BLACK, WHITE, 5)
		box(m, V(3.2, 0.9, 0.1), V(-9, 5.2, -2.7), WHITE)
		return 24
	end

	builders["Bald Eagle"] = function(m)
		local brown, white, yellow = rgb(95, 60, 35), WHITE, rgb(250, 205, 60)
		for _, z in ipairs({ -0.45, 0.45 }) do
			box(m, V(0.3, 1.4, 0.3), V(0, 0.7, z), yellow)
		end
		box(m, V(2, 3.6, 1.8), V(0, 2.8, 0), brown)
		box(m, V(2.1, 1.1, 1.9), V(0, 1.6, 0), rgb(120, 80, 50))
		box(m, V(1.5, 1.5, 1.4), V(-0.4, 5.1, 0), white)
		box(m, V(0.8, 0.7, 0.3), V(-1.5, 4.9, 0), yellow)
		box(m, V(0.35, 0.3, 0.1), V(-0.9, 5.4, -0.72), BLACK)
		for _, z in ipairs({ -1.1, 1.1 }) do
			box(m, V(1.4, 3, 0.35), V(0.4, 3, z), rgb(80, 50, 30))
		end
		box(m, V(1.2, 1.8, 1.4), V(1.2, 1.1, 0), white)
		return 5.9
	end

	builders["Giant Tortoise"] = function(m)
		local shell, skin = rgb(120, 105, 70), rgb(150, 140, 100)
		Kit.dome(m, 4.4, V(0, 1.2, 0), shell, nil, 5)
		box(m, V(9, 1.2, 6.6), V(0, 0.6, 0), rgb(175, 160, 110))
		for _, x in ipairs({ -3.2, 3.2 }) do
			for _, z in ipairs({ -3.2, 3.2 }) do
				box(m, V(1.6, 1.6, 1.6), V(x, 0.8, z), skin)
			end
		end
		beam(m, V(-4, 2.4, 0), V(-6.2, 4, 0), 1.5, skin)
		box(m, V(1.6, 1.4, 1.5), V(-6.9, 4.1, 0), skin)
		box(m, V(0.25, 0.25, 0.1), V(-7.1, 4.4, -0.78), BLACK)
		return 9
	end

	builders["Tyrannosaurus Rex"] = function(m)
		local green, belly = rgb(95, 120, 70), rgb(185, 190, 130)
		for _, z in ipairs({ -1.6, 1.6 }) do
			box(m, V(2, 5.6, 1.6), V(0.5, 2.8, z), green)
			box(m, V(3.2, 0.8, 1.6), V(-0.6, 0.4, z), rgb(70, 90, 55))
		end
		box(m, V(7, 5.4, 4.6), V(0, 7.8, 0), green)
		box(m, V(6, 2, 4.7), V(0, 5.9, 0), belly)
		beam(m, V(3.5, 8.6, 0), V(13, 5.2, 0), 3, green)
		box(m, V(4, 3.4, 3.8), V(-4.4, 10.8, 0), green)
		box(m, V(3, 1.6, 3.6), V(-6.8, 9.9, 0), green)
		for i = 0, 3 do
			box(m, V(0.35, 0.5, 0.35), V(-7.8 + i * 0.7, 9.1, -1.4), WHITE)
			box(m, V(0.35, 0.5, 0.35), V(-7.8 + i * 0.7, 9.1, 1.4), WHITE)
		end
		box(m, V(0.5, 0.5, 0.1), V(-5.4, 11.8, -1.95), rgb(250, 200, 50))
		for _, z in ipairs({ -1.2, 1.2 }) do
			beam(m, V(-3.2, 7.4, z), V(-4.4, 6.2, z), 0.45, green)
		end
		return 21 -- nose to tail
	end

	builders["Common Frog"] = function(m)
		local green = rgb(100, 165, 70)
		box(m, V(3, 1.6, 2.6), V(0, 1.2, 0), green)
		box(m, V(2.2, 1.2, 2.4), V(-1.5, 1.8, 0), green)
		for _, z in ipairs({ -0.8, 0.8 }) do
			ball(m, 0.9, V(-2, 2.7, z), green)
			ball(m, 0.4, V(-2.35, 2.75, z * 1.1), BLACK)
			box(m, V(2.4, 0.6, 0.6), V(1.2, 0.4, z * 2.2), rgb(80, 140, 60))
			box(m, V(0.6, 0.6, 0.6), V(-2.4, 0.3, z * 1.7), green)
		end
		box(m, V(1.8, 0.1, 1.6), V(-2, 1.35, 0), rgb(240, 200, 120))
		return 3.4
	end

	builders["Golden Hamster"] = function(m)
		local fur = rgb(225, 170, 95)
		ball(m, 3.2, V(0, 1.7, 0), fur)
		ball(m, 1.8, V(-1.5, 1.6, 0), rgb(245, 225, 190))
		ball(m, 2, V(-1.9, 1.9, 0), fur)
		for _, z in ipairs({ -0.65, 0.65 }) do
			ball(m, 0.7, V(-1.5, 3.1, z), rgb(230, 150, 120))
			box(m, V(0.3, 0.3, 0.1), V(-2.8, 2.2, z * 0.8), BLACK)
		end
		ball(m, 0.4, V(-3, 1.8, 0), rgb(230, 130, 120))
		box(m, V(0.7, 0.5, 0.7), V(-1.4, 0.25, -0.7), rgb(245, 225, 190))
		box(m, V(0.7, 0.5, 0.7), V(-1.4, 0.25, 0.7), rgb(245, 225, 190))
		return 3.4
	end
end
