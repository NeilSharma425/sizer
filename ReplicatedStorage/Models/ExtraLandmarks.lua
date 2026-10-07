--[[
	ExtraLandmarks.lua
	ModuleScript: ReplicatedStorage.Models.ExtraLandmarks

	More landmark models for ObjectModels. Each builder returns the model
	height (or the measured length) in model units.

	Usage: require(ExtraLandmarks)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, vcyl, spire, cone, dome = Kit.box, Kit.ball, Kit.beam, Kit.vcyl, Kit.spire, Kit.cone, Kit.dome
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new

-- Rocky/snowy mountain from stacked tapering blocks.
local function peakMountain(m, width, height, rock, snow, snowFrac)
	local steps = 10
	local h = height / steps
	for i = 0, steps - 1 do
		local w = width * (1 - i / steps) + 0.4
		local isSnow = (i + 0.5) / steps > 1 - snowFrac
		box(m, V(w, h, w * 0.8), V(0, h * (i + 0.5), 0), isSnow and snow or rock)
	end
end

return function(builders)
	builders["Leaning Tower of Pisa"] = function(m)
		local marble = rgb(235, 228, 210)
		box(m, V(9, 0.6, 9), V(0, 0.3, 0), rgb(150, 150, 145))
		for i = 0, 7 do
			local lean = i * 0.28
			box(m, V(6, 1.6, 6), V(lean, 0.6 + i * 1.7 + 0.8, 0), i % 2 == 0 and marble or rgb(220, 212, 190))
			box(m, V(6.4, 0.18, 6.4), V(lean, 0.6 + i * 1.7 + 1.65, 0), rgb(200, 190, 165))
			for _, x in ipairs({ -2, 0, 2 }) do
				box(m, V(0.5, 1.1, 0.15), V(lean + x, 0.6 + i * 1.7 + 0.8, -3.05), rgb(120, 110, 100))
			end
		end
		box(m, V(3.6, 1.8, 3.6), V(8 * 0.28 + 0.2, 14.9, 0), rgb(205, 195, 170))
		box(m, V(3.9, 0.3, 3.9), V(8 * 0.28 + 0.2, 15.9, 0), rgb(150, 70, 55))
		return 16
	end

	builders["Taj Mahal"] = function(m)
		local white = rgb(245, 243, 235)
		box(m, V(16, 1.2, 16), V(0, 0.6, 0), rgb(235, 225, 205))
		box(m, V(9, 5.5, 9), V(0, 3.95, 0), white)
		box(m, V(2.6, 3.6, 0.3), V(0, 3.7, -4.6), rgb(60, 70, 110))
		Kit.dome(m, 3.2, V(0, 6.7, 0), white, nil, 6)
		vcyl(m, 1.4, 0.2, V(0, 10.6, 0), rgb(240, 200, 80))
		for _, p in ipairs({ { -3.4, -3.4 }, { 3.4, -3.4 }, { -3.4, 3.4 }, { 3.4, 3.4 } }) do
			vcyl(m, 2, 0.8, V(p[1], 7.7, p[2]), white)
			Kit.dome(m, 0.9, V(p[1], 8.7, p[2]), white, nil, 3)
		end
		for _, x in ipairs({ -7.6, 7.6 }) do
			vcyl(m, 9, 0.7, V(x, 5.7, 0), white)
			Kit.dome(m, 0.9, V(x, 10.2, 0), white, nil, 3)
			vcyl(m, 0.25, 1, V(x, 6, 0), rgb(200, 195, 185))
		end
		return 11
	end

	builders["Colosseum"] = function(m)
		local stone, dark = rgb(215, 190, 150), rgb(95, 80, 65)
		local n, r = 18, 11
		for i = 0, n - 1 do
			local a = 2 * math.pi * i / n
			local x, z = math.cos(a) * r, math.sin(a) * r
			local cf = CFrame.new(x, 4, z) * CFrame.Angles(0, -a + math.pi / 2, 0)
			box(m, V(2 * r * math.sin(math.pi / n) + 0.3, 8, 1.4), cf, stone)
			for k = 0, 2 do
				box(m, V(0.9, 1.2, 0.2), cf * CFrame.new(0, -2.8 + k * 2.6, 0.75), dark)
			end
		end
		return 23 -- diameter
	end

	builders["Sydney Opera House"] = function(m)
		local white = rgb(245, 245, 240)
		box(m, V(20, 1.4, 12), V(0, 0.7, 0), rgb(200, 190, 175))
		local shells = { { -6, 7, 6 }, { -1, 9, 7 }, { 4.5, 6.5, 5.5 }, { 8.2, 4, 3.2 } }
		for _, s in ipairs(shells) do
			for i = 0, 4 do
				local f = i / 5
				local w = s[3] * (1 - f * 0.85)
				box(m, V(w, s[2] / 5, 2.2), V(s[1] - f * 1.2, 1.4 + (i + 0.5) * s[2] / 5, 0), white)
			end
		end
		box(m, V(20.5, 1.6, 0.2), V(0, 1.6, -6.1), rgb(90, 130, 150))
		return 20.5 -- length
	end

	builders["CN Tower"] = function(m)
		local gray = rgb(205, 205, 210)
		cone(m, 22, 1.3, 0.7, V(0, 0, 0), gray, nil, 7)
		vcyl(m, 1.6, 3.4, V(0, 23, 0), gray)
		vcyl(m, 0.6, 3.8, V(0, 24.4, 0), rgb(110, 120, 135))
		vcyl(m, 8, 0.45, V(0, 29, 0), gray)
		vcyl(m, 0.6, 1.2, V(0, 26, 0), rgb(160, 160, 170))
		beam(m, V(0, 33, 0), V(0, 44, 0), 0.25, rgb(220, 60, 60))
		return 44
	end

	builders["Empire State Building"] = function(m)
		local stone = rgb(200, 195, 180)
		local tiers = { { 8, 12 }, { 6.4, 8 }, { 5, 6 }, { 3.6, 4 }, { 2.4, 3 } }
		local y = 0
		for _, t in ipairs(tiers) do
			box(m, V(t[1], t[2], t[1]), V(0, y + t[2] / 2, 0), stone)
			Kit.windows(m, -t[1] / 2 + 0.4, t[1] / 2 - 0.4, y + 0.6, y + t[2] - 0.4, -t[1] / 2 - 0.05, 5, math.floor(t[2] / 1.6), rgb(90, 110, 140))
			y += t[2]
		end
		beam(m, V(0, y, 0), V(0, y + 9, 0), 0.5, rgb(190, 190, 195))
		return y + 9
	end

	builders["Space Needle"] = function(m)
		local white = rgb(240, 240, 235)
		for _, a in ipairs({ 0, 120, 240 }) do
			local r = math.rad(a)
			beam(m, V(math.cos(r) * 2.6, 0, math.sin(r) * 2.6), V(math.cos(r) * 0.6, 13, math.sin(r) * 0.6), 0.5, white)
		end
		vcyl(m, 1.4, 4.8, V(0, 14, 0), white)
		vcyl(m, 0.6, 5.4, V(0, 14.1, 0), rgb(110, 175, 190))
		vcyl(m, 0.5, 2.6, V(0, 15.2, 0), rgb(235, 140, 70))
		cone(m, 5, 1.4, 0.2, V(0, 15.5, 0), white, nil, 5)
		beam(m, V(0, 20, 0), V(0, 23, 0), 0.2, white)
		return 23
	end

	builders["Washington Monument"] = function(m)
		local white = rgb(240, 238, 232)
		spire(m, 36, 4.4, 2.8, V(0, 0, 0), white, nil, 9)
		Kit.peak(m, 0, 36, 0, 1.4, 3, 2.8, white)
		box(m, V(0.3, 0.3, 2.9), V(0, 37.5, 0), white)
		return 39
	end

	builders["Arc de Triomphe"] = function(m)
		local stone = rgb(215, 195, 155)
		box(m, V(14, 4, 7), V(0, 2, 0), stone)
		for _, x in ipairs({ -5, 5 }) do
			box(m, V(4, 8, 7), V(x, 6, 0), stone)
		end
		box(m, V(14, 3.4, 7), V(0, 11.9, 0), stone)
		box(m, V(14.6, 0.7, 7.5), V(0, 13.9, 0), rgb(195, 175, 135))
		box(m, V(6, 8, 7.2), V(0, 4, 0), rgb(70, 65, 60))
		for _, x in ipairs({ -5, 5 }) do
			box(m, V(2.4, 3.4, 0.3), V(x, 8, -3.7), rgb(190, 165, 125))
		end
		return 14.6
	end

	builders["Christ the Redeemer"] = function(m)
		local white = rgb(235, 240, 235)
		box(m, V(9, 3, 9), V(0, 1.5, 0), rgb(170, 165, 155))
		box(m, V(5.5, 2.6, 5.5), V(0, 4.3, 0), rgb(190, 185, 175))
		for _, x in ipairs({ -0.9, 0.9 }) do
			box(m, V(1.4, 3, 1.2), V(x, 7.6, 0), white)
		end
		beam(m, V(0, 9, 0), V(0, 16, 0), 2.6, white)
		box(m, V(16, 1.3, 1.3), V(0, 15.2, 0), white)
		box(m, V(2.1, 2.4, 2), V(0, 17.2, 0), white)
		box(m, V(1.2, 1.6, 1), V(0, 14, -0.1), white)
		return 20
	end

	builders["Stonehenge"] = function(m)
		local stone = rgb(150, 148, 140)
		local n, r = 9, 7
		for i = 0, n - 1 do
			local a = 2 * math.pi * i / n
			box(m, V(1.6, 4.5, 1), CFrame.new(math.cos(a) * r, 2.25, math.sin(a) * r) * CFrame.Angles(0, -a, 0), stone)
		end
		for i = 0, n - 1, 2 do
			local a1, a2 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
			local x1, z1 = math.cos(a1) * r, math.sin(a1) * r
			local x2, z2 = math.cos(a2) * r, math.sin(a2) * r
			box(m, V(1.2, 0.9, 2 * r * math.sin(math.pi / n) + 1.2), CFrame.lookAt(V((x1 + x2) / 2, 4.95, (z1 + z2) / 2), V(x2, 4.95, z2)), rgb(135, 133, 125))
		end
		for _, a in ipairs({ 0.8, 2.6, 4.4 }) do
			box(m, V(1, 3, 0.8), V(math.cos(a) * 2.8, 1.5, math.sin(a) * 2.8), rgb(120, 120, 130))
		end
		return 15.6 -- diameter
	end

	builders["Moai Statue"] = function(m)
		local rock = rgb(120, 110, 100)
		box(m, V(3.6, 4.6, 2.8), V(0, 2.3, 0), rock)
		box(m, V(3.4, 4.6, 2.8), V(0, 6.9, 0), rock)
		box(m, V(3, 3.2, 2.8), V(0, 10.8, 0), rock)
		box(m, V(3.1, 0.7, 1.4), V(0, 9.3, -1.7), rgb(100, 92, 85))
		box(m, V(1.2, 3, 0.8), V(0, 10.4, -1.7), rgb(105, 98, 90))
		for _, x in ipairs({ -0.8, 0.8 }) do
			box(m, V(0.9, 0.5, 0.4), V(x, 11.4, -1.5), BLACK)
		end
		box(m, V(2.2, 0.5, 0.9), V(0, 8.2, -1.6), rgb(95, 88, 80))
		return 12.4
	end

	builders["Great Sphinx"] = function(m)
		local sand = rgb(220, 190, 130)
		box(m, V(20, 5, 7), V(2, 2.5, 0), sand)
		box(m, V(5, 3, 6), V(-8.5, 5.4, 0), sand)
		box(m, V(5.6, 5.6, 6.4), V(-9, 9.6, 0), sand)
		box(m, V(6.4, 1.6, 7), V(-9, 12.8, 0), rgb(70, 110, 160))
		for _, z in ipairs({ -3.6, 3.6 }) do
			box(m, V(5, 8, 1.2), V(-9, 9, z), rgb(70, 110, 160))
		end
		box(m, V(1.4, 1.2, 0.5), V(-12.2, 9.2, 0), rgb(200, 165, 110))
		for _, z in ipairs({ -1.3, 1.3 }) do
			box(m, V(0.2, 0.2, 0.7), V(-12, 10.5, z), BLACK)
			box(m, V(8, 2.4, 2), V(-9.5, 1.3, z * 1.9), sand)
		end
		return 24.5 -- length
	end

	builders["Parthenon"] = function(m)
		local marble = rgb(235, 228, 212)
		box(m, V(24, 1.2, 12), V(0, 0.6, 0), rgb(215, 205, 185))
		box(m, V(23, 0.6, 11), V(0, 1.5, 0), rgb(225, 215, 195))
		for i = 0, 8 do
			for _, z in ipairs({ -4.6, 4.6 }) do
				vcyl(m, 6.4, 0.65, V(-10 + i * 2.5, 5, z), marble)
			end
		end
		box(m, V(23, 1.2, 10.8), V(0, 8.8, 0), marble)
		Kit.peak(m, 0, 9.4, 0, 11.5, 2.4, 10.4, rgb(220, 210, 190))
		box(m, V(16, 6, 6), V(0, 5, 0), rgb(205, 195, 175))
		return 24 -- length
	end

	builders["Petronas Towers"] = function(m)
		local steel = rgb(195, 205, 215)
		for _, x in ipairs({ -4.4, 4.4 }) do
			box(m, V(5.6, 6, 5.6), V(x, 3, 0), steel)
			box(m, V(5, 6, 5), V(x, 9, 0), rgb(185, 195, 208))
			box(m, V(4.2, 6, 4.2), V(x, 15, 0), steel)
			box(m, V(3.4, 6, 3.4), V(x, 21, 0), rgb(185, 195, 208))
			box(m, V(2.6, 5, 2.6), V(x, 26.5, 0), steel)
			cone(m, 5, 1.2, 0.2, V(x, 29, 0), steel, nil, 4)
			Kit.windows(m, x - 2.2, x + 2.2, 0.8, 26, -2.85, 3, 12, rgb(80, 110, 150), 0.5)
		end
		box(m, V(3.2, 1.4, 1.6), V(0, 17, 0), steel)
		return 34
	end

	builders["Tokyo Skytree"] = function(m)
		local white = rgb(225, 235, 240)
		for _, a in ipairs({ 45, 135, 225, 315 }) do
			local r = math.rad(a)
			beam(m, V(math.cos(r) * 3, 0, math.sin(r) * 3), V(math.cos(r) * 0.5, 22, math.sin(r) * 0.5), 0.45, white)
		end
		vcyl(m, 1.2, 2.6, V(0, 22.5, 0), rgb(150, 190, 215))
		vcyl(m, 0.8, 1.9, V(0, 25, 0), rgb(150, 190, 215))
		vcyl(m, 12, 0.35, V(0, 31.5, 0), white)
		beam(m, V(0, 37, 0), V(0, 42, 0), 0.15, white)
		return 42
	end

	builders["Mount Fuji"] = function(m)
		peakMountain(m, 26, 14, rgb(95, 110, 150), rgb(250, 250, 255), 0.35)
		return 14
	end

	builders["Matterhorn"] = function(m)
		peakMountain(m, 15, 17, rgb(110, 105, 100), rgb(245, 245, 250), 0.25)
		beam(m, V(0, 16.5, 0), V(1.6, 17.8, 0), 0.6, rgb(110, 105, 100))
		return 17.8
	end

	builders["Golden Gate Bridge"] = function(m)
		local red = rgb(190, 60, 45)
		for _, x in ipairs({ -12, 12 }) do
			box(m, V(1.5, 18, 1.5), V(x, 9, -2), red)
			box(m, V(1.5, 18, 1.5), V(x, 9, 2), red)
			for _, y in ipairs({ 5, 10, 15 }) do
				box(m, V(1.4, 0.8, 5.2), V(x, y, 0), red)
			end
		end
		box(m, V(40, 1, 5), V(0, 5, 0), rgb(165, 55, 40))
		for _, z in ipairs({ -2, 2 }) do
			Kit.beam(m, V(-12, 17.5, z), V(0, 7, z), 0.25, red)
			Kit.beam(m, V(0, 7, z), V(12, 17.5, z), 0.25, red)
			Kit.beam(m, V(-12, 17.5, z), V(-20, 5.5, z), 0.25, red)
			Kit.beam(m, V(12, 17.5, z), V(20, 5.5, z), 0.25, red)
			for i = -9, 9, 3 do
				local y = 7 + 10.5 * (math.abs(i) / 12) ^ 1.2
				beam(m, V(i, y, z), V(i, 5.5, z), 0.1, red)
			end
		end
		return 40 -- span between the anchorages
	end

	builders["Tower Bridge"] = function(m)
		local stone, blue = rgb(190, 180, 160), rgb(70, 130, 190)
		for _, x in ipairs({ -8, 8 }) do
			box(m, V(5, 14, 5), V(x, 7, 0), stone)
			for _, cx in ipairs({ -1.8, 1.8 }) do
				cone(m, 3.4, 0.9, 0.2, V(x + cx, 14, -1.6), rgb(90, 100, 110), nil, 3)
				cone(m, 3.4, 0.9, 0.2, V(x + cx, 14, 1.6), rgb(90, 100, 110), nil, 3)
			end
			Kit.peak(m, x, 14, 0, 2.5, 3, 5, rgb(95, 105, 120))
		end
		box(m, V(11, 1, 4), V(0, 10.5, 0), blue)
		box(m, V(11, 0.5, 4.1), V(0, 11.3, 0), rgb(220, 220, 225))
		for _, x in ipairs({ -15, 15 }) do
			Kit.slab(m, V(x * 0.55, 4.5, 0), V(x, 3.4, 0), 3.4, 0.8, blue)
		end
		box(m, V(28, 1, 4), V(0, 3, 0), blue)
		return 31 -- length
	end
end
