--[[
	ExtraSpace.lua
	ModuleScript: ReplicatedStorage.Models.ExtraSpace

	More space models for ObjectModels: planets and moons (10-unit spheres
	centered at (0, 5, 0), measure 10) plus spacecraft and rockets.

	Usage: require(ExtraSpace)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, vcyl, zcyl = Kit.box, Kit.ball, Kit.beam, Kit.vcyl, Kit.zcyl
local rgb, BLACK, WHITE, onSphere = Kit.rgb, Kit.BLACK, Kit.WHITE, Kit.onSphere
local V = Vector3.new
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon
local CENTER = V(0, 5, 0)

-- Colored sphere with optional latitude bands { y, color } and crater
-- patches { lat, lon, size }.
local function planet(m, color, bands, patches, patchColor)
	ball(m, 10, CENTER, color)
	for _, band in ipairs(bands or {}) do
		local r = math.sqrt(25 - band[1] * band[1]) * 1.005
		vcyl(m, band[3] or 0.6, r, CENTER + V(0, band[1], 0), band[2])
	end
	for _, c in ipairs(patches or {}) do
		ball(m, c[3], onSphere(CENTER, 5 - c[3] * 0.4, c[1], c[2]), patchColor)
	end
	return 10
end

-- Lumpy rock made of overlapping balls (moons and comet nuclei).
local function potato(m, color, dark, bumps)
	ball(m, 8, V(0, 4, 0), color)
	for _, b in ipairs(bumps) do
		ball(m, b[4], V(b[1], b[2], b[3]), color)
	end
	for _, c in ipairs({ { -2, 5.5, -3.2, 1.8 }, { 2, 3, -3.4, 1.4 }, { 0.5, 6.8, -2.4, 1.2 } }) do
		ball(m, c[4], V(c[1], c[2], c[3]), dark)
	end
end

return function(builders)
	builders["Uranus"] = function(m)
		return planet(m, rgb(170, 225, 230), { { 0.8, rgb(160, 215, 222), 1.2 }, { -2, rgb(180, 232, 236), 0.8 } })
	end

	builders["Pluto"] = function(m)
		planet(m, rgb(205, 180, 155), nil, { { -10, 5, 3.4 }, { 20, -25, 2.2 }, { 35, 30, 1.6 } }, rgb(245, 235, 220))
		return 10
	end

	builders["Ceres"] = function(m)
		return planet(m, rgb(140, 135, 130), nil, { { 25, -20, 1.6 }, { -15, 25, 2 }, { 40, 20, 1.3 }, { -35, -30, 1.8 } }, rgb(105, 100, 98))
	end

	builders["Ganymede"] = function(m)
		return planet(m, rgb(150, 140, 125), nil, { { 20, 10, 2.8 }, { -25, -20, 3.2 }, { 5, 45, 2 }, { 45, -40, 2.4 } }, rgb(105, 98, 90))
	end

	builders["Titan"] = function(m)
		return planet(m, rgb(225, 170, 70), { { 2, rgb(215, 155, 60), 1.2 }, { -2.6, rgb(235, 185, 90), 0.9 } })
	end

	builders["Io"] = function(m)
		return planet(m, rgb(240, 215, 90), nil, { { 20, -20, 2.4 }, { -25, 30, 2 }, { 5, 50, 1.8 }, { -40, -35, 1.6 } }, rgb(210, 110, 50))
	end

	builders["Phobos"] = function(m)
		potato(m, rgb(120, 112, 105), rgb(85, 78, 72), { { -3, 3.4, 0.5, 5 }, { 3, 4.4, -0.5, 4.6 }, { 0, 5, 2.4, 4 } })
		return 10
	end

	builders["Halley's Comet"] = function(m)
		potato(m, rgb(70, 65, 62), rgb(45, 42, 40), { { -3.5, 4.5, 0, 5 }, { 3.6, 3.6, 0.4, 5.4 } })
		for i = 1, 5 do
			ball(m, 2.4 - i * 0.3, V(5 + i * 2.6, 6 + i * 0.8, 0), rgb(190, 225, 250), NEON).Transparency = 0.2 + i * 0.12
		end
		return 11
	end

	builders["International Space Station"] = function(m)
		local silver, gold = rgb(205, 208, 215), rgb(215, 170, 60)
		box(m, V(24, 1.4, 1.4), V(0, 6, 0), silver, METAL)
		for _, x in ipairs({ -6, 6 }) do
			zcyl(m, 6, 1.5, V(x, 6, 0), silver, METAL)
		end
		vcyl(m, 5, 1.5, V(0, 8, 0), silver, METAL)
		for _, x in ipairs({ -10, -5, 5, 10 }) do
			for _, sign in ipairs({ -1, 1 }) do
				box(m, V(3.2, 0.15, 6.4), V(x, 6, sign * 4.6), gold)
				box(m, V(0.3, 0.3, 4), V(x, 6, sign * 1.9), silver)
			end
		end
		box(m, V(3, 2, 2), V(0, 3.4, 0), silver, METAL)
		return 24
	end

	builders["Hubble Space Telescope"] = function(m)
		local silver = rgb(205, 208, 215)
		zcyl(m, 13, 2, V(0, 6, 0), silver, METAL)
		zcyl(m, 3, 2.2, V(-5, 6, 0), rgb(30, 30, 38))
		zcyl(m, 7, 2.5, V(4.5, 6, 0), rgb(160, 160, 170), METAL)
		for _, z in ipairs({ -5, 5 }) do
			box(m, V(7, 0.15, 3.2), V(3, 6, z), rgb(50, 70, 140))
			box(m, V(0.4, 0.4, 2), V(3, 6, z * 0.55), silver)
		end
		box(m, V(0.4, 3, 0.4), V(-1, 8, 0), silver)
		ball(m, 1.6, V(-1, 9.6, 0), silver)
		return 13
	end

	builders["Saturn V Rocket"] = function(m)
		local white = rgb(245, 245, 245)
		vcyl(m, 22, 2.4, V(0, 11, 0), white)
		vcyl(m, 14, 1.8, V(0, 29, 0), white)
		vcyl(m, 8, 1.2, V(0, 40, 0), white)
		for i = 0, 3 do
			vcyl(m, 2.5, 2.42, V(0, 3 + i * 6, 0), BLACK)
		end
		Kit.cone(m, 7, 1.2, 0.15, V(0, 44, 0), rgb(220, 220, 225), nil, 5)
		beam(m, V(0, 51, 0), V(0, 56, 0), 0.2, rgb(210, 210, 215))
		for _, a in ipairs({ 0, 90, 180, 270 }) do
			local r = math.rad(a)
			Kit.wedge(m, V(0.4, 6, 3.4), CFrame.new(math.cos(r) * 3.4, 3, math.sin(r) * 3.4) * CFrame.Angles(0, -r + math.pi / 2, 0), BLACK)
		end
		return 56
	end

	builders["Falcon 9 Rocket"] = function(m)
		local white = rgb(245, 245, 248)
		vcyl(m, 38, 1.8, V(0, 19, 0), white)
		vcyl(m, 1.4, 1.82, V(0, 11, 0), rgb(40, 40, 45))
		vcyl(m, 12, 1.8, V(0, 44, 0), rgb(235, 235, 240))
		Kit.cone(m, 5, 1.8, 0.7, V(0, 50, 0), white, nil, 4)
		vcyl(m, 3, 0.9, V(0, 2, 0), rgb(60, 60, 68))
		for _, a in ipairs({ 0, 90, 180, 270 }) do
			local r = math.rad(a)
			box(m, V(0.3, 3, 1.4), CFrame.new(math.cos(r) * 2.2, 7, math.sin(r) * 2.2) * CFrame.Angles(0, -r, 0), rgb(40, 40, 45))
		end
		box(m, V(2, 1.6, 0.2), V(0, 40, -1.82), rgb(40, 40, 45))
		return 55
	end

	builders["Sputnik 1"] = function(m)
		local steel = rgb(205, 210, 220)
		ball(m, 8, V(0, 5, 0), steel, METAL)
		for _, a in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			beam(m, V(a[1] * 2, 5 + a[2] * 2, 0), V(a[1] * 14, 5 + a[2] * 6, 0), 0.25, steel, METAL)
		end
		return 8
	end

	builders["Apollo Lunar Module"] = function(m)
		local gold, gray = rgb(225, 175, 60), rgb(190, 190, 195)
		box(m, V(7, 4, 7), V(0, 7.5, 0), gold)
		Kit.dome(m, 3.4, V(0, 9.5, 0), gray, METAL, 3)
		box(m, V(5.4, 3.6, 5.4), V(0, 3.4, 0), gray)
		for _, a in ipairs({ 45, 135, 225, 315 }) do
			local r = math.rad(a)
			beam(m, V(math.cos(r) * 2, 3.4, math.sin(r) * 2), V(math.cos(r) * 7, 0.6, math.sin(r) * 7), 0.4, gold)
			box(m, V(2.2, 0.3, 2.2), V(math.cos(r) * 7, 0.15, math.sin(r) * 7), gold)
		end
		box(m, V(1.6, 1.4, 0.3), V(0, 7.6, -3.6), rgb(60, 70, 90), Enum.Material.Glass)
		return 11
	end
end
