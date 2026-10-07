--[[
	Planets.lua
	ModuleScript: ReplicatedStorage.Models.Planets

	More space models for ObjectModels: Mercury, Venus, Mars, Saturn and
	Neptune. Like the other planets, each is a 10-unit sphere centered at
	(0, 5, 0) and reports its diameter as the measure.

	Usage: require(Planets)(builders) -- adds the builders to the table.
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, vcyl, onSphere, rgb = Kit.box, Kit.ball, Kit.vcyl, Kit.onSphere, Kit.rgb
local WHITE = Kit.WHITE

local CENTER = Vector3.new(0, 5, 0)

-- Darker blobs pressed into the sphere's surface: { lat, lon, size }.
local function patches(m, list, color)
	for _, c in ipairs(list) do
		ball(m, c[3], onSphere(CENTER, 5 - c[3] * 0.4, c[1], c[2]), color)
	end
end

return function(builders)
	builders["Mercury"] = function(m)
		ball(m, 10, CENTER, rgb(150, 145, 140))
		patches(m, { { 20, -20, 2.4 }, { -15, 15, 2 }, { 35, 30, 1.6 }, { -30, -35, 2.2 }, { 5, 40, 1.4 }, { -5, -5, 1.2 }, { 50, -45, 1.5 } }, rgb(115, 110, 108))
		return 10
	end

	builders["Venus"] = function(m)
		ball(m, 10, CENTER, rgb(235, 200, 130))
		for _, band in ipairs({ { 3.2, rgb(225, 175, 100) }, { 1.1, rgb(245, 220, 160) }, { -1.2, rgb(220, 170, 95) }, { -3.1, rgb(240, 212, 150) } }) do
			local r = math.sqrt(25 - band[1] * band[1]) * 1.005
			vcyl(m, 0.5, r, CENTER + Vector3.new(0, band[1], 0), band[2])
		end
		return 10
	end

	builders["Mars"] = function(m)
		ball(m, 10, CENTER, rgb(205, 100, 60))
		patches(m, { { 12, -25, 3 }, { -20, 15, 2.6 }, { 5, 50, 2.2 }, { -35, -40, 2 }, { 25, 20, 1.8 } }, rgb(160, 70, 45))
		ball(m, 3.2, CENTER + Vector3.new(0, 4.3, 0), WHITE)
		ball(m, 2.4, CENTER - Vector3.new(0, 4.5, 0), WHITE)
		return 10
	end

	builders["Saturn"] = function(m)
		ball(m, 10, CENTER, rgb(225, 195, 135))
		for _, band in ipairs({ { 2.6, rgb(205, 170, 110) }, { -0.4, rgb(235, 210, 160) }, { -2.8, rgb(210, 175, 120) } }) do
			local r = math.sqrt(25 - band[1] * band[1]) * 1.005
			vcyl(m, 0.5, r, CENTER + Vector3.new(0, band[1], 0), band[2])
		end
		-- Two tilted rings built from short segments (parts can't have a hole).
		local ringFrame = CFrame.new(CENTER) * CFrame.Angles(math.rad(-18), 0, math.rad(8))
		for _, ring in ipairs({ { 7.4, 1.7, rgb(215, 185, 130) }, { 9.4, 1.5, rgb(190, 160, 110) } }) do
			local segments = 56
			local radius, width, color = ring[1], ring[2], ring[3]
			for i = 0, segments - 1 do
				local a = (i / segments) * math.pi * 2
				local cf = ringFrame * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -a, 0)
				box(m, Vector3.new(width, 0.22, (2 * math.pi * radius / segments) + 0.15), cf, color)
			end
		end
		return 10
	end

	builders["Neptune"] = function(m)
		ball(m, 10, CENTER, rgb(55, 95, 205))
		for _, band in ipairs({ { 2.4, rgb(70, 115, 225) }, { -1.8, rgb(45, 80, 185) } }) do
			local r = math.sqrt(25 - band[1] * band[1]) * 1.005
			vcyl(m, 0.5, r, CENTER + Vector3.new(0, band[1], 0), band[2])
		end
		ball(m, 2.4, onSphere(CENTER, 4.5, -15, -25), rgb(30, 55, 140))
		for _, c in ipairs({ { 25, 10, 1.6 }, { 8, 35, 1.2 }, { -30, 30, 1.4 } }) do
			ball(m, c[3], onSphere(CENTER, 5 - c[3] * 0.4, c[1], c[2]), rgb(210, 230, 250))
		end
		return 10
	end
end
