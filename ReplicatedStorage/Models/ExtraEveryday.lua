--[[
	ExtraEveryday.lua
	ModuleScript: ReplicatedStorage.Models.ExtraEveryday

	More everyday-object models for ObjectModels. Each builder returns the
	length (in model units) that matches the real size in ExtraObjects.

	Usage: require(ExtraEveryday)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, vcyl, zcyl = Kit.box, Kit.ball, Kit.beam, Kit.vcyl, Kit.zcyl
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon

local function wheel(m, x, y, r, w)
	Kit.wheel(m, V(x, y, 0), r, w)
end

return function(builders)
	builders["Pencil"] = function(m)
		box(m, V(1, 19, 1), V(0, 9.5, 0), rgb(250, 205, 40))
		for _, x in ipairs({ -0.35, 0.35 }) do
			box(m, V(0.28, 19, 0.6), V(x, 9.5, -0.5), rgb(235, 175, 30))
		end
		box(m, V(1.05, 2, 1.05), V(0, 20, 0), rgb(235, 235, 240), METAL)
		box(m, V(1.05, 1.4, 1.05), V(0, 21.7, 0), rgb(240, 130, 150))
		Kit.cone(m, 1.8, 0.5, 0.1, V(0, 19, 0), rgb(235, 200, 150), nil, 3)
		return 22.5
	end

	builders["Banana"] = function(m)
		local yellow = rgb(250, 220, 60)
		for i = 0, 7 do
			local t = i / 7
			local x = -7 + t * 14
			local y = 2 + 5 * (1 - (2 * t - 1) ^ 2)
			box(m, V(2.2, 2.2, 2.2), CFrame.new(x, y, 0) * CFrame.Angles(0, 0, (2 * t - 1) * -0.9), yellow)
		end
		box(m, V(1, 1.5, 1), V(-7.6, 2.2, 0), rgb(110, 85, 40))
		box(m, V(0.9, 0.9, 0.9), V(7.5, 2.3, 0), rgb(70, 50, 30))
		return 19
	end

	builders["Apple"] = function(m)
		ball(m, 8, V(0, 4, 0), rgb(220, 40, 45))
		ball(m, 3.4, V(-1.8, 7, 0.5), rgb(220, 40, 45))
		ball(m, 3.4, V(1.8, 7, 0.5), rgb(220, 40, 45))
		box(m, V(0.4, 1.8, 0.4), V(0, 8.7, 0), rgb(100, 70, 40))
		box(m, V(2.2, 0.2, 1.2), CFrame.new(1.6, 9, 0) * CFrame.Angles(0, 0, 0.4), rgb(90, 170, 60))
		ball(m, 1.6, V(-2, 5.6, -3), rgb(250, 120, 120))
		return 8
	end

	builders["Soccer Ball"] = function(m)
		ball(m, 10, V(0, 5, 0), WHITE)
		for _, p in ipairs({ { 0, 0 }, { 0, 55 }, { 0, -55 }, { 40, 25 }, { -40, 25 }, { 35, -30 }, { -35, -30 }, { 60, 0 }, { -60, 0 } }) do
			local pos = Kit.onSphere(V(0, 5, 0), 4.7, p[1], p[2])
			ball(m, 2.2, pos, BLACK)
		end
		return 10
	end

	builders["Bowling Pin"] = function(m)
		local white, red = rgb(250, 250, 245), rgb(210, 40, 40)
		local profile = { { 0, 3.6, 1.2 }, { 3.6, 3.4, 2 }, { 7, 5.4, 2.7 }, { 12.4, 4.4, 2.3 }, { 16.8, 3.4, 1.4 }, { 20.2, 2.4, 1.6 }, { 22.6, 1.6, 1.3 } }
		for _, s in ipairs(profile) do
			vcyl(m, s[2], s[3], V(0, s[1] + s[2] / 2, 0), white)
		end
		vcyl(m, 0.5, 1.45, V(0, 17.7, 0), red)
		vcyl(m, 0.5, 1.4, V(0, 18.6, 0), red)
		return 24
	end

	builders["Acoustic Guitar"] = function(m)
		local wood, dark = rgb(215, 150, 70), rgb(95, 55, 30)
		zcyl(m, 1.3, 4.5, V(0, 6, 0), wood)
		zcyl(m, 1.35, 3.4, V(0, 14.5, 0), wood)
		zcyl(m, 1.4, 1.2, V(0, 8, 0), dark)
		box(m, V(1.5, 18, 0.6), V(0, 25, 0), rgb(120, 75, 40))
		box(m, V(2.4, 3.5, 0.7), V(0, 36, 0), rgb(70, 45, 28))
		for _, x in ipairs({ -0.5, 0, 0.5 }) do
			box(m, V(0.1, 30, 0.1), V(x, 21, -0.7), rgb(225, 225, 225))
		end
		for i = 0, 6 do
			box(m, V(1.6, 0.12, 0.65), V(0, 18 + i * 3.4, -0.02), rgb(190, 190, 195), METAL)
		end
		box(m, V(3.2, 0.5, 0.5), V(0, 2.5, -1.1), dark)
		return 38
	end

	builders["Office Chair"] = function(m)
		local black, steel = rgb(40, 42, 50), rgb(160, 165, 175)
		for i = 0, 4 do
			local a = i * 2 * math.pi / 5
			beam(m, V(0, 1.6, 0), V(math.cos(a) * 3.2, 0.7, math.sin(a) * 3.2), 0.5, steel, METAL)
			ball(m, 0.9, V(math.cos(a) * 3.3, 0.45, math.sin(a) * 3.3), black)
		end
		vcyl(m, 4, 0.5, V(0, 3.6, 0), steel, METAL)
		box(m, V(5.4, 1.1, 5.2), V(0, 5.8, 0), black)
		box(m, V(5, 6.4, 0.9), V(0, 9.6, 2.5), black)
		box(m, V(0.5, 1, 4.6), V(-2.9, 7, 0), black)
		box(m, V(0.5, 1, 4.6), V(2.9, 7, 0), black)
		return 12.8
	end

	builders["Bicycle"] = function(m)
		local frame, tire = rgb(220, 50, 50), rgb(30, 30, 35)
		for _, x in ipairs({ -5.2, 5.2 }) do
			Kit.ring(m, V(x, 3.6, 0), 3.5, 0.45, 0.5, 14, tire)
			Kit.ring(m, V(x, 3.6, 0), 2.6, 0.08, 0.1, 10, rgb(190, 190, 195))
			ball(m, 0.7, V(x, 3.6, 0), rgb(190, 190, 195), METAL)
		end
		beam(m, V(-5.2, 3.6, 0), V(-1.2, 8, 0), 0.4, frame)
		beam(m, V(-1.2, 8, 0), V(3.2, 8, 0), 0.4, frame)
		beam(m, V(-1.2, 8, 0), V(0.2, 3.6, 0), 0.4, frame)
		beam(m, V(0.2, 3.6, 0), V(5.2, 3.6, 0), 0.4, frame)
		beam(m, V(3.2, 8, 0), V(5.2, 3.6, 0), 0.4, frame)
		beam(m, V(-1.2, 8, 0), V(-1.7, 9.8, 0), 0.35, frame)
		box(m, V(2.6, 0.6, 1), V(-1.8, 10.1, 0), BLACK)
		beam(m, V(-5.2, 3.6, 0), V(-4.3, 9.4, 0), 0.35, frame)
		box(m, V(0.5, 0.5, 2.6), V(-4.3, 9.7, 0), BLACK)
		return 11
	end

	builders["Traffic Cone"] = function(m)
		local orange = rgb(250, 110, 30)
		box(m, V(9, 0.8, 9), V(0, 0.4, 0), rgb(235, 100, 30))
		Kit.cone(m, 20, 3.5, 0.7, V(0, 0.8, 0), orange, nil, 8)
		vcyl(m, 3, 2.15, V(0, 12, 0), WHITE)
		vcyl(m, 1.6, 1.45, V(0, 15.6, 0), WHITE)
		return 21
	end

	builders["Fire Hydrant"] = function(m)
		local red, gray = rgb(215, 40, 40), rgb(170, 170, 175)
		vcyl(m, 1, 2.8, V(0, 0.5, 0), gray, METAL)
		vcyl(m, 8, 2.2, V(0, 5, 0), red)
		vcyl(m, 1, 2.6, V(0, 9.5, 0), red)
		Kit.dome(m, 2.4, V(0, 10, 0), red, nil, 3)
		zcyl(m, 5, 1, V(0, 6.2, 0), red)
		for _, z in ipairs({ -2.9, 2.9 }) do
			zcyl(m, 0.8, 1.2, V(0, 6.2, z), gray, METAL)
		end
		box(m, V(1.6, 1.6, 2), V(0, 6.2, -3.6), gray)
		ball(m, 1.4, V(0, 12.6, 0), gray)
		return 12.8
	end

	builders["Mailbox"] = function(m)
		local blue = rgb(40, 85, 170)
		box(m, V(1.2, 12, 1.2), V(0, 6, 0), rgb(110, 80, 50))
		box(m, V(5.4, 4, 7.4), V(0, 14, 0), blue)
		Kit.dome(m, 2.7, V(0, 16, 0), blue, nil, 3)
		box(m, V(5, 3.4, 0.2), V(0, 13.6, -3.8), rgb(25, 55, 120))
		box(m, V(0.3, 1.4, 0.3), V(2.8, 16.2, -1), rgb(230, 50, 50))
		return 17
	end

	builders["Stop Sign"] = function(m)
		box(m, V(0.8, 14, 0.8), V(0, 7, 0), rgb(165, 170, 180), METAL)
		local red = rgb(205, 30, 40)
		for i = 0, 3 do
			box(m, V(8.2, 3.4, 0.4), CFrame.new(0, 17, -0.1) * CFrame.Angles(0, 0, i * math.pi / 4), i == 0 and red or red)
		end
		for i = 0, 3 do
			box(m, V(6.6, 2.8, 0.45), CFrame.new(0, 17, -0.15) * CFrame.Angles(0, 0, i * math.pi / 4 + math.pi / 8), rgb(250, 250, 250), nil)
		end
		for i = 0, 3 do
			box(m, V(6.2, 2.4, 0.5), CFrame.new(0, 17, -0.2) * CFrame.Angles(0, 0, i * math.pi / 4 + math.pi / 8), red)
		end
		for i, x in ipairs({ -2.4, -0.8, 0.8, 2.4 }) do
			box(m, V(1.1, 1.6, 0.1), V(x, 17, -0.5), WHITE)
		end
		return 21
	end

	builders["Street Lamp"] = function(m)
		local steel = rgb(65, 70, 78)
		box(m, V(3, 1.4, 3), V(0, 0.7, 0), steel)
		vcyl(m, 20, 0.7, V(0, 11, 0), steel)
		beam(m, V(0, 21, 0), V(-4, 22.6, 0), 0.5, steel)
		box(m, V(4.6, 1, 2.2), V(-5, 22.6, 0), steel)
		box(m, V(4, 0.4, 1.8), V(-5, 22, 0), rgb(255, 240, 180), NEON)
		return 24
	end

	builders["Ladder"] = function(m)
		local wood = rgb(215, 160, 80)
		for _, sign in ipairs({ -1, 1 }) do
			beam(m, V(sign * 2.4, 0, 0), V(sign * 1.6, 20, 0), 0.6, wood)
		end
		for i = 1, 7 do
			local y = i * 2.5
			box(m, V(4.4 - y * 0.04, 0.5, 0.5), V(0, y, 0), rgb(190, 140, 70))
		end
		return 20
	end

	builders["Umbrella"] = function(m)
		local colors = { rgb(220, 50, 70), rgb(250, 210, 50) }
		for i = 0, 7 do
			local a = i * math.pi / 4
			for k = 0, 2 do
				local r = 4 - k * 1.2
				local y = 8 + k * 1.5
				box(m, V(1.8, 0.5, 3.2 - k), CFrame.new(math.cos(a) * r * 0.7, y, math.sin(a) * r * 0.7) * CFrame.Angles(0, -a, 0), colors[(i % 2) + 1])
			end
		end
		vcyl(m, 8, 0.2, V(0, 4, 0), rgb(60, 60, 70), METAL)
		box(m, V(0.3, 0.9, 0.3), V(0, 11.3, 0), rgb(200, 200, 205))
		for i, x in ipairs({ 0, 1.2 }) do
			box(m, V(1, 0.5, 0.5), V(x, 0.2, 0), rgb(60, 40, 30))
		end
		return 12
	end

	builders["Toothbrush"] = function(m)
		box(m, V(1.2, 18, 0.8), V(0, 9, 0), rgb(70, 160, 230))
		box(m, V(1.8, 5, 0.9), V(0, 20.5, 0), rgb(70, 160, 230))
		box(m, V(1.6, 4.2, 1.4), V(0, 20.6, -1), WHITE)
		for i = 0, 3 do
			box(m, V(1.7, 0.7, 0.3), V(0, 18.9 + i * 1.1, -1.8), rgb(80, 220, 160))
		end
		box(m, V(1.4, 6, 0.6), V(0, 6, -0.6), rgb(250, 250, 250))
		return 23
	end

	builders["Laptop"] = function(m)
		local silver = rgb(195, 198, 208)
		box(m, V(16, 0.7, 11), V(0, 0.35, 0), silver, METAL)
		box(m, V(14, 0.1, 4), V(0, 0.75, -2.4), rgb(40, 42, 50))
		for r = 0, 3 do
			for c = 0, 11 do
				box(m, V(0.9, 0.08, 0.7), V(-6.2 + c * 1.12, 0.78, 0.4 - r * 0.9 + 1), rgb(60, 62, 72))
			end
		end
		box(m, V(16, 10.4, 0.5), CFrame.new(0, 6, 5.4) * CFrame.Angles(math.rad(-12), 0, 0), silver, METAL)
		box(m, V(14.6, 9, 0.1), CFrame.new(0, 6, 5.1) * CFrame.Angles(math.rad(-12), 0, 0), rgb(40, 100, 180), NEON)
		return 16
	end

	builders["Skateboard"] = function(m)
		box(m, V(16, 0.7, 4), V(0, 2.1, 0), rgb(240, 180, 40))
		box(m, V(3, 0.7, 4), CFrame.new(-9.4, 2.7, 0) * CFrame.Angles(0, 0, math.rad(20)), rgb(240, 180, 40))
		box(m, V(3, 0.7, 4), CFrame.new(9.4, 2.7, 0) * CFrame.Angles(0, 0, math.rad(-20)), rgb(240, 180, 40))
		box(m, V(14, 0.1, 3.4), V(0, 2.5, 0), rgb(30, 30, 35))
		for _, x in ipairs({ -5.5, 5.5 }) do
			box(m, V(1.2, 0.5, 3.6), V(x, 1.5, 0), rgb(170, 170, 180), METAL)
			for _, z in ipairs({ -2, 2 }) do
				Kit.xcyl(m, 1.2, 0.8, V(x, 0.9, z), rgb(235, 90, 90))
			end
		end
		return 20
	end

	builders["Surfboard"] = function(m)
		local cream = rgb(250, 240, 210)
		for i = 0, 8 do
			local t = i / 8
			local w = 6.4 * math.sin(math.pi * (0.12 + 0.8 * t)) + 0.6
			box(m, V(w, 2.4, 1.2), V(0, 1.6 + i * 2.3, 0), i % 2 == 0 and cream or rgb(90, 190, 215))
		end
		box(m, V(0.4, 18, 0.15), V(0, 11, -0.4), rgb(235, 90, 70))
		for _, x in ipairs({ -1.4, 1.4 }) do
			Kit.wedge(m, V(0.2, 1.8, 1.2), CFrame.new(x, 1.8, 0.9) * CFrame.Angles(0, math.pi / 2, 0), rgb(60, 60, 70))
		end
		box(m, V(0.2, 1.6, 0.8), V(0, 0.9, 1.1), rgb(60, 60, 70))
		return 22
	end

	builders["Single Bed"] = function(m)
		local wood = rgb(140, 95, 60)
		box(m, V(18, 2, 10), V(0, 2, 0), wood)
		box(m, V(17.4, 2.6, 9.4), V(0, 4.2, 0), rgb(235, 235, 245))
		box(m, V(11, 0.9, 9.5), V(2.5, 5.9, 0), rgb(80, 130, 210))
		box(m, V(3.4, 1.4, 5.6), V(-6, 6, 0), WHITE)
		box(m, V(0.8, 7.5, 10.4), V(-9.4, 5.5, 0), wood)
		box(m, V(0.8, 4, 10.4), V(9.4, 4, 0), wood)
		for _, x in ipairs({ -8.6, 8.6 }) do
			for _, z in ipairs({ -4.6, 4.6 }) do
				box(m, V(0.8, 1.4, 0.8), V(x, 0.7, z), wood)
			end
		end
		return 18
	end

	builders["Washing Machine"] = function(m)
		box(m, V(10, 12, 9), V(0, 6, 0), rgb(240, 242, 248))
		zcyl(m, 0.8, 3.8, V(0, 5.6, -4.6), rgb(190, 195, 205), METAL)
		zcyl(m, 0.9, 3, V(0, 5.6, -4.7), rgb(70, 120, 180), Enum.Material.Glass)
		box(m, V(10.1, 2.2, 0.2), V(0, 10.7, -4.55), rgb(215, 220, 230))
		for i, x in ipairs({ -3.4, -2, 0 }) do
			zcyl(m, 0.4, 0.5, V(x + 0.4, 10.7, -4.8), rgb(60, 65, 80))
		end
		box(m, V(1.4, 0.6, 0.2), V(3.4, 10.7, -4.8), rgb(80, 220, 120), NEON)
		return 12
	end

	builders["Microwave Oven"] = function(m)
		box(m, V(14, 8, 10), V(0, 4, 0), rgb(190, 192, 200), METAL)
		box(m, V(9, 5.6, 0.3), V(-1.6, 4.2, -5.1), rgb(30, 32, 40), Enum.Material.Glass)
		box(m, V(2.4, 6.2, 0.3), V(5.2, 4, -5.1), rgb(45, 48, 60))
		box(m, V(1.6, 0.8, 0.1), V(5.2, 6.4, -5.3), rgb(80, 230, 120), NEON)
		for i = 0, 2 do
			box(m, V(1.4, 0.6, 0.15), V(5.2, 4.6 - i * 1.2, -5.3), rgb(150, 155, 165))
		end
		box(m, V(0.5, 5, 0.4), V(2.9, 4, -5.3), rgb(150, 150, 160), METAL)
		return 8
	end

	builders["Flat-Screen TV"] = function(m)
		box(m, V(24, 14, 1), V(0, 9.5, 0), rgb(25, 25, 30))
		box(m, V(23, 12.8, 0.2), V(0, 9.5, -0.5), rgb(20, 70, 140), NEON)
		box(m, V(23, 1.6, 0.25), CFrame.new(0, 6.2, -0.55) * CFrame.Angles(0, 0, 0), rgb(60, 140, 220), NEON)
		Kit.wedge(m, V(1, 4, 3), CFrame.new(0, 2, 0.5), rgb(30, 30, 35))
		box(m, V(10, 0.6, 5), V(0, 0.3, 0), rgb(35, 35, 42))
		box(m, V(2, 3, 1), V(0, 2, 0.4), rgb(35, 35, 42))
		return 16.5
	end

	builders["Candle"] = function(m)
		vcyl(m, 12, 3, V(0, 6, 0), rgb(250, 235, 200))
		vcyl(m, 0.6, 3.1, V(0, 11.8, 0), rgb(240, 220, 175))
		box(m, V(0.3, 1.3, 0.3), V(0, 12.6, 0), rgb(50, 40, 40))
		ball(m, 1.6, V(0, 14, 0), rgb(255, 190, 60), NEON)
		ball(m, 1, V(0, 14.3, 0), rgb(255, 235, 140), NEON)
		return 15
	end

	builders["Light Bulb"] = function(m)
		ball(m, 8, V(0, 7.5, 0), rgb(255, 245, 190), NEON)
		vcyl(m, 4, 2.6, V(0, 2.6, 0), rgb(190, 190, 200), METAL)
		for i = 0, 2 do
			vcyl(m, 0.3, 2.8, V(0, 1 + i * 1, 0), rgb(150, 150, 160), METAL)
		end
		beam(m, V(-1, 6, 0), V(-0.5, 9, 0), 0.15, rgb(255, 160, 40))
		beam(m, V(1, 6, 0), V(0.5, 9, 0), 0.15, rgb(255, 160, 40))
		return 11.5
	end

	builders["Pumpkin"] = function(m)
		local orange = rgb(240, 130, 30)
		for _, p in ipairs({ { 0, 0.9 }, { -2.2, 0.8 }, { 2.2, 0.8 }, { -1.1, 0.95 }, { 1.1, 0.95 } }) do
			ball(m, 7 * p[2], V(p[1] * 0.8, 3.5, 0), orange)
		end
		box(m, V(1.2, 2.2, 1.2), CFrame.new(0, 7.6, 0) * CFrame.Angles(0, 0, 0.2), rgb(95, 120, 50))
		return 8
	end

	builders["Sedan Car"] = function(m)
		local blue = rgb(50, 100, 190)
		box(m, V(22, 3.4, 8.4), V(0, 3.2, 0), blue)
		box(m, V(11, 3, 7.6), V(1, 6.4, 0), blue)
		for _, z in ipairs({ -3.88, 3.88 }) do
			box(m, V(9.6, 2.2, 0.15), V(1, 6.5, z), rgb(150, 205, 235), Enum.Material.Glass)
		end
		box(m, V(0.15, 2.2, 6.6), V(-4.8, 6.4, 0), rgb(150, 205, 235), Enum.Material.Glass)
		for _, x in ipairs({ -6.6, 6.6 }) do
			for _, z in ipairs({ -4.4, 4.4 }) do
				Kit.zcyl(m, 1.2, 1.9, V(x, 1.9, z), rgb(30, 30, 35))
				Kit.zcyl(m, 1.3, 1, V(x, 1.9, z), rgb(190, 190, 200))
			end
		end
		for _, z in ipairs({ -2.9, 2.9 }) do
			box(m, V(0.2, 0.9, 1.4), V(-11.05, 3.6, z), rgb(255, 240, 180), NEON)
			box(m, V(0.2, 0.8, 1.2), V(11.05, 3.6, z), rgb(230, 40, 40), NEON)
		end
		return 22 -- length
	end

	builders["School Bus"] = function(m)
		local yellow = rgb(250, 190, 30)
		box(m, V(36, 10, 9), V(0, 7.4, 0), yellow)
		box(m, V(36.2, 1, 9.1), V(0, 4.4, 0), BLACK)
		box(m, V(7, 5.4, 8.6), V(-21.5, 5.9, 0), yellow)
		Kit.windows(m, -16, 17, 8.4, 11.6, -4.55, 9, 1, rgb(140, 195, 230), 0.7)
		box(m, V(0.2, 3, 7.4), V(-18, 8.6, 0), rgb(150, 205, 235), Enum.Material.Glass)
		for _, x in ipairs({ -19, 12 }) do
			wheel(m, x, 2.6, 2.6, 1.6)
		end
		for _, z in ipairs({ -3, 3 }) do
			ball(m, 1, V(-25.1, 6.5, z), rgb(255, 245, 190), NEON)
		end
		box(m, V(34, 0.6, 9.2), V(0, 7.6, 0), rgb(40, 40, 45))
		return 43 -- length with the hood
	end

	builders["Shipping Container"] = function(m)
		local blue = rgb(40, 100, 160)
		box(m, V(40, 8.5, 8), V(0, 4.3, 0), blue)
		for i = -9, 9 do
			box(m, V(0.5, 7.8, 8.3), V(i * 2.05, 4.3, 0), rgb(35, 90, 148))
		end
		for _, y in ipairs({ 0.2, 8.4 }) do
			box(m, V(40.4, 0.5, 8.4), V(0, y, 0), rgb(60, 60, 70))
		end
		for _, x in ipairs({ -20.1, 20.1 }) do
			box(m, V(0.4, 8.5, 8.2), V(x, 4.3, 0), rgb(60, 60, 70))
		end
		return 40.4 -- length
	end

	builders["Telephone Booth"] = function(m)
		local red = rgb(205, 35, 40)
		for _, x in ipairs({ -3, 3 }) do
			for _, z in ipairs({ -3, 3 }) do
				box(m, V(0.7, 16, 0.7), V(x, 8, z), red)
			end
		end
		box(m, V(7.4, 0.8, 7.4), V(0, 0.4, 0), red)
		box(m, V(7.4, 1.2, 7.4), V(0, 16.4, 0), red)
		Kit.dome(m, 3.7, V(0, 17, 0), red, nil, 3)
		for _, p in ipairs({ { -3, 0, 0 }, { 3, 0, 0 }, { 0, 0, 3 } }) do
			for r = 0, 2 do
				for c = 0, 1 do
					box(m, V(p[3] == 0 and 0.15 or 1.8, 3.4, p[3] == 0 and 1.8 or 0.15), V(p[1] == 0 and -0.9 + c * 1.8 or p[1], 3 + r * 4.4 + 1.6, p[3] == 0 and -0.9 + c * 1.8 or p[3]), rgb(170, 205, 225), Enum.Material.Glass)
				end
			end
		end
		box(m, V(5, 0.6, 0.3), V(0, 15.6, -3.1), rgb(250, 250, 240))
		return 20
	end
end
