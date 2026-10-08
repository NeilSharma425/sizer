--[[
	ExtraBrainrot.lua
	ModuleScript: ReplicatedStorage.Models.ExtraBrainrot

	More brainrot characters for ObjectModels (meme sizes are made up!).
	Each builder returns the character's height (or length) in model units.

	Usage: require(ExtraBrainrot)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, vcyl, zcyl = Kit.box, Kit.ball, Kit.beam, Kit.vcyl, Kit.zcyl
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new
local NEON = Enum.Material.Neon

local function eyes(m, cx, y, z, gap, size)
	for _, sign in ipairs({ -1, 1 }) do
		ball(m, size * 1.6, V(cx + sign * gap, y, z), WHITE)
		ball(m, size * 0.8, V(cx + sign * gap, y, z - size * 0.6), BLACK)
	end
end

return function(builders)
	builders["Bobrito Bandito"] = function(m)
		local brown = rgb(140, 95, 60)
		for _, x in ipairs({ -1.4, 1.4 }) do
			box(m, V(1.6, 3, 1.8), V(x, 1.5, 0), brown)
		end
		box(m, V(5, 6, 3.6), V(0, 6, 0), brown)
		box(m, V(3.2, 3.8, 0.2), V(0, 5.6, -1.85), rgb(210, 175, 130))
		ball(m, 5.2, V(0, 10.8, 0), brown)
		box(m, V(5.2, 1.4, 0.4), V(0, 11.2, -2.6), BLACK) -- bandit mask
		eyes(m, 0, 11.2, -2.7, 1.1, 0.4)
		for _, x in ipairs({ -0.5, 0.5 }) do
			box(m, V(0.8, 1.2, 0.3), V(x, 9.2, -2.55), WHITE)
		end
		box(m, V(6.4, 0.7, 6.4), V(0, 13.2, 0), rgb(60, 45, 40))
		box(m, V(3.8, 1.8, 3.8), V(0, 14.3, 0), rgb(60, 45, 40))
		box(m, V(2, 5, 0.8), V(2.4, 3, 2.8), rgb(95, 65, 40))
		return 15
	end

	builders["Frigo Camelo"] = function(m)
		local camel, steel = rgb(210, 170, 105), rgb(225, 230, 238)
		for _, x in ipairs({ -2.4, 2.4 }) do
			for _, z in ipairs({ -1.2, 1.2 }) do
				box(m, V(1, 7, 1), V(x, 3.5, z), camel)
			end
		end
		box(m, V(8, 6, 4.6), V(0, 10, 0), steel)
		box(m, V(0.3, 5.4, 4.7), V(-1.2, 10, 0), rgb(150, 155, 165))
		box(m, V(0.4, 1.4, 0.3), V(-1.6, 11, -2.45), rgb(110, 115, 125))
		beam(m, V(-4, 12, 0), V(-6.4, 17, 0), 1.5, camel)
		box(m, V(3.2, 1.8, 1.8), V(-7.6, 17.8, 0), camel)
		eyes(m, -7.2, 18.6, -0.95, 0.0, 0.3)
		ball(m, 3, V(2.6, 14, 0), camel)
		return 20
	end

	builders["Glorbo Fruttodrillo"] = function(m)
		local green = rgb(95, 150, 70)
		box(m, V(14, 3, 5), V(0, 2.5, 0), green)
		box(m, V(8, 2, 4.4), V(-10.5, 2, 0), green)
		beam(m, V(7, 2.5, 0), V(15, 1.2, 0), 3, green)
		for i, c in ipairs({ rgb(235, 60, 70), rgb(250, 190, 40), rgb(160, 90, 190), rgb(250, 140, 40), rgb(110, 190, 70) }) do
			ball(m, 3, V(-4 + i * 2.2, 5.2, 0), c)
		end
		eyes(m, -7, 4.6, -1.6, 1.2, 0.5)
		for _, x in ipairs({ -4, 4 }) do
			for _, z in ipairs({ -2.8, 2.8 }) do
				box(m, V(1.3, 1.6, 1.3), V(x, 0.8, z), green)
			end
		end
		return 29
	end

	builders["Tric Trac Baraboom"] = function(m)
		local red, tan = rgb(210, 50, 50), rgb(235, 215, 170)
		vcyl(m, 9, 3.4, V(0, 6.5, 0), tan)
		Kit.dome(m, 3.4, V(0, 11, 0), red, nil, 4)
		for _, x in ipairs({ -1.2, 1.2 }) do
			box(m, V(0.5, 1.6, 0.4), V(x, 11.6, -3.1), BLACK)
		end
		box(m, V(2.4, 0.5, 0.4), V(0, 9.8, -3.3), rgb(110, 40, 40))
		for _, x in ipairs({ -3.4, 3.4 }) do
			beam(m, V(x, 7, 0), V(x * 1.5, 3, 0), 0.9, tan)
			ball(m, 1.6, V(x * 1.5, 2.5, 0), WHITE)
		end
		for _, x in ipairs({ -1.4, 1.4 }) do
			box(m, V(1.4, 2.6, 1.4), V(x, 1.3, 0), tan)
		end
		return 14
	end

	builders["Boneca Ambalabu"] = function(m)
		local tire = rgb(40, 40, 46)
		Kit.zcyl(m, 3, 3.6, V(0, 3.6, 0), tire)
		Kit.zcyl(m, 3.1, 1.6, V(0, 3.6, 0), rgb(170, 170, 180))
		box(m, V(3.6, 5, 2.4), V(0, 9.6, 0), rgb(240, 200, 130))
		ball(m, 4.6, V(0, 14, 0), rgb(240, 200, 130))
		eyes(m, 0, 14.4, -2, 1, 0.6)
		box(m, V(1.2, 0.3, 0.2), V(0, 12.8, -2.2), rgb(200, 90, 90))
		for _, x in ipairs({ -1, 1 }) do
			beam(m, V(x * 2, 15, 0), V(x * 3.4, 10, 0), 1.4, rgb(70, 45, 30))
		end
		box(m, V(5, 1.2, 2), V(0, 16.7, 0), rgb(70, 45, 30))
		return 18
	end

	builders["Bombombini Gusini"] = function(m)
		local gray, orange = rgb(110, 118, 130), rgb(250, 160, 40)
		box(m, V(9, 4, 4), V(0, 4, 0), gray)
		beam(m, V(-4, 5, 0), V(-6, 9.5, 0), 1.6, gray)
		ball(m, 3, V(-6.4, 10.4, 0), WHITE)
		box(m, V(2.4, 0.9, 1.1), V(-8.2, 10.3, 0), orange)
		eyes(m, -6.4, 11, -1.1, 0, 0.35)
		for _, z in ipairs({ -3.4, 3.4 }) do
			Kit.xcyl(m, 6, 1.1, V(0.5, 4, z), rgb(190, 195, 205))
			ball(m, 1.2, V(3.6, 4, z), rgb(255, 150, 50), NEON)
		end
		box(m, V(1, 1.4, 1), V(-1, 1.2, -1), orange)
		box(m, V(1, 1.4, 1), V(-1, 1.2, 1), orange)
		box(m, V(5, 0.3, 12), V(1, 4.6, 0), gray)
		return 13
	end

	builders["Orcalero Orcala"] = function(m)
		box(m, V(16, 6, 6), V(0, 9, 0), BLACK)
		box(m, V(13, 2.4, 6.1), V(0, 7.6, 0), WHITE)
		box(m, V(3, 5, 6), V(-9, 9, 0), BLACK)
		box(m, V(3.4, 1, 0.2), V(-8, 10, -3.1), WHITE)
		Kit.wedge(m, V(0.5, 4, 4), CFrame.new(1, 14, 0) * CFrame.Angles(0, math.pi / 2, 0), BLACK)
		beam(m, V(8, 9.5, 0), V(14, 11, 0), 2.4, BLACK)
		for _, x in ipairs({ -3, 3 }) do
			for _, z in ipairs({ -1.6, 1.6 }) do
				box(m, V(1.2, 6, 1.2), V(x, 3, z), rgb(60, 60, 70))
				box(m, V(2, 0.8, 1.8), V(x - 0.3, 0.4, z), rgb(230, 230, 235))
			end
		end
		return 30
	end

	builders["Gorillo Subwoofero"] = function(m)
		local fur = rgb(60, 60, 68)
		for _, x in ipairs({ -1.4, 1.4 }) do
			box(m, V(1.8, 3.4, 2), V(x, 1.7, 0), fur)
		end
		box(m, V(6, 6.4, 3.6), V(0, 6.6, 0), fur)
		for _, x in ipairs({ -3.8, 3.8 }) do
			box(m, V(3.2, 4.6, 3.2), V(x, 6.4, 0), rgb(40, 40, 46))
			ball(m, 2.6, V(x, 6.4, -1.7), rgb(70, 70, 80))
			ball(m, 1.2, V(x, 6.4, -2.4), rgb(25, 25, 30))
			beam(m, V(x * 0.7, 9, 0), V(x * 1.1, 3.6, -0.3), 1.2, fur)
		end
		box(m, V(3, 3, 2.8), V(0, 11, -0.2), fur)
		box(m, V(2, 1.4, 0.4), V(0, 10.6, -1.7), rgb(110, 100, 98))
		eyes(m, 0, 11.6, -1.5, 0.6, 0.25)
		return 12.6
	end

	builders["Elefanto Cocofanto"] = function(m)
		local gray, shell = rgb(150, 150, 160), rgb(120, 80, 50)
		for _, x in ipairs({ -3, 3 }) do
			for _, z in ipairs({ -1.6, 1.6 }) do
				box(m, V(1.8, 4, 1.8), V(x, 2, z), gray)
			end
		end
		ball(m, 10, V(0, 7.6, 0), shell)
		ball(m, 4, V(0, 11, 0), rgb(250, 245, 235))
		box(m, V(4, 4.4, 4), V(-5.6, 9, 0), gray)
		beam(m, V(-7.6, 8, 0), V(-8.4, 2, 0), 1.2, gray)
		for _, z in ipairs({ -2.6, 2.6 }) do
			box(m, V(0.5, 3.4, 2.6), V(-4.2, 9.4, z), gray)
		end
		eyes(m, -6.6, 10.4, -1.8, 0, 0.3)
		return 13.6
	end

	builders["Burbaloni Luliloli"] = function(m)
		local shell = rgb(125, 85, 55)
		box(m, V(9, 1.6, 4), V(0, 0.8, 0), rgb(235, 200, 155))
		ball(m, 7, V(1.4, 4.6, 0), shell)
		Kit.zcyl(m, 0.5, 2.6, V(1.4, 4.6, -3.4), rgb(95, 65, 40))
		beam(m, V(-3.4, 1.2, 0), V(-4.6, 5.4, 0), 1.5, rgb(235, 200, 155))
		ball(m, 3.4, V(-4.8, 6.4, 0), rgb(235, 200, 155))
		eyes(m, -4.8, 6.8, -1.4, 0.9, 0.4)
		for i = 0, 5 do
			beam(m, V(-4.8 + (i - 2.5) * 0.7, 8.1, 0), V(-4.8 + (i - 2.5) * 1.2, 5, 0.3), 0.4, rgb(250, 190, 60))
		end
		return 10
	end

	builders["Pot Hotspot"] = function(m)
		local steel = rgb(165, 170, 180)
		Kit.vcyl(m, 6, 4.4, V(0, 3, 0), steel, Enum.Material.Metal)
		Kit.vcyl(m, 0.6, 4.7, V(0, 6.3, 0), rgb(200, 205, 215), Enum.Material.Metal)
		Kit.dome(m, 4.2, V(0, 6.6, 0), rgb(190, 195, 205), Enum.Material.Metal, 3)
		ball(m, 1, V(0, 11.2, 0), rgb(40, 40, 46))
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(4, 0.9, 0.9), V(s * 5.8, 5, 0), rgb(40, 40, 46))
		end
		eyes(m, 0, 4.4, -4.1, 1.5, 0.5)
		box(m, V(2.6, 0.5, 0.3), V(0, 2.6, -4.5), rgb(60, 30, 30))
		for i, x in ipairs({ -1.4, 0, 1.4 }) do
			ball(m, 0.9, V(x, 13 + i % 2 * 1.4, 0), rgb(240, 240, 250)).Transparency = 0.3
		end
		return 11
	end

	builders["Piccione Macchina"] = function(m)
		local gray, red = rgb(150, 155, 170), rgb(205, 45, 50)
		box(m, V(14, 3.4, 6), V(0, 3.4, 0), red)
		box(m, V(7, 3, 5.4), V(1, 6.5, 0), red)
		for _, z in ipairs({ -2.75, 2.75 }) do
			box(m, V(6, 2, 0.1), V(1, 6.6, z), rgb(150, 205, 235), Enum.Material.Glass)
		end
		for _, x in ipairs({ -4.4, 4.4 }) do
			for _, z in ipairs({ -3.1, 3.1 }) do
				Kit.zcyl(m, 1.2, 1.7, V(x, 1.7, z), BLACK)
			end
		end
		ball(m, 5, V(-5.2, 8.6, 0), gray)
		box(m, V(2, 0.7, 0.8), V(-8, 8.4, 0), rgb(250, 190, 60))
		eyes(m, -5.4, 9.2, -2.2, 0, 0.5)
		ball(m, 2.4, V(-4.4, 7.4, 0), rgb(120, 190, 150))
		box(m, V(4, 0.4, 7), V(-1, 8.2, 0), gray)
		return 11.2
	end

	-- Tall, starved figure with a crooked neck, hollow eyes and a grin.
	builders["Scary Verity"] = function(m)
		local skin, dark, bone = rgb(150, 118, 74), rgb(92, 70, 42), rgb(182, 150, 100)
		local function ellipsoid(size, cf, color, material)
			local p = Instance.new("Part")
			p.Size = size
			p.CFrame = cf
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
			return Kit.add(m, p, color, material)
		end
		local rod = Kit.rod

		-- Legs: bony shins and thighs with knobbly knees, long flat feet.
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(1.1, 0.6, 2.6), V(s * 1.35, 0.3, -0.5), skin)
			for t = 0, 3 do
				box(m, V(0.24, 0.3, 0.5), V(s * 1.35 + (t - 1.5) * 0.27, 0.2, -1.95), skin)
			end
			ball(m, 0.9, V(s * 1.3, 0.8, 0), skin)
			rod(m, V(s * 1.3, 0.8, 0), V(s * 1.15, 8, -0.1), 0.42, skin)
			ball(m, 1.35, V(s * 1.15, 8.1, -0.2), bone)
			rod(m, V(s * 1.15, 8.2, -0.1), V(s * 0.95, 14.6, 0), 0.5, skin)
		end

		-- Narrow hips, caved-in belly, ribcage you can count.
		ellipsoid(V(3.1, 1.9, 2), CFrame.new(0, 15, 0), skin)
		rod(m, V(0, 15.4, 0.1), V(0, 18, 0.1), 0.8, rgb(122, 95, 58))
		ellipsoid(V(3.4, 4.6, 2.4), CFrame.new(0, 19.6, 0.15) * CFrame.Angles(math.rad(-8), 0, 0), skin)
		for i = 0, 6 do
			local y = 17.9 + i * 0.52
			local w = 2.7 - math.abs(i - 3.5) * 0.16
			box(m, V(w, 0.2, 0.3), V(0, y, -1.12), dark)
			box(m, V(w - 0.2, 0.22, 0.3), V(0, y + 0.26, -1.08), bone)
		end
		box(m, V(0.3, 2.6, 0.3), V(0, 19.4, -1.2), dark) -- breastbone groove

		-- Shoulders and collarbones.
		for _, s in ipairs({ -1, 1 }) do
			ball(m, 1.3, V(s * 2.15, 21.6, 0.2), skin)
			Kit.beam(m, V(s * 0.3, 21.8, -0.7), V(s * 2, 21.9, -0.4), 0.3, bone)
		end

		-- Arms hang way past the hips, ending in long, curled fingers.
		for _, s in ipairs({ -1, 1 }) do
			local shoulder, elbow, wrist = V(s * 2.3, 21.5, 0.2), V(s * 2.75, 15.2, 0.3), V(s * 2.95, 8.8, -0.2)
			rod(m, shoulder, elbow, 0.4, skin)
			ball(m, 0.95, elbow, bone)
			rod(m, elbow, wrist, 0.32, skin)
			box(m, V(0.5, 1.5, 1.1), V(s * 3, 8.1, -0.25), skin)
			for f = 0, 3 do
				local top = V(s * 3.02, 7.5, -0.6 + f * 0.3)
				local knuckle = top + V(s * 0.05, -1.6, -0.1)
				rod(m, top, knuckle, 0.1, skin)
				rod(m, knuckle, knuckle + V(-s * 0.15, -1.1, -0.35), 0.09, dark)
			end
		end

		-- Thin neck bent to one side, head lolling on it.
		rod(m, V(0, 21.6, 0.3), V(-0.6, 23.2, -0.3), 0.38, skin)
		rod(m, V(-0.6, 23.2, -0.3), V(-1.25, 24.1, -0.7), 0.34, skin)
		local head = CFrame.new(-1.6, 25.1, -0.9) * CFrame.Angles(0, 0, math.rad(38))
		ellipsoid(V(3, 3.4, 3.2), head, skin)
		ellipsoid(V(1.9, 1.5, 2.2), head * CFrame.new(0, -1.25, -0.3), skin) -- jaw
		ellipsoid(V(2.5, 0.7, 1), head * CFrame.new(0, 0.75, -1.15), bone) -- brow ridge

		local function face(x, y)
			local k = 1 - (x / 1.5) ^ 2 - (y / 1.7) ^ 2
			return -1.6 * math.sqrt(math.max(k, 0.05))
		end
		-- Deep black eye sockets with pinprick glowing pupils.
		for _, x in ipairs({ -0.62, 0.62 }) do
			ellipsoid(V(0.85, 1.05, 0.4), head * CFrame.new(x, 0.15, face(x, 0.15) + 0.1), BLACK)
			ball(m, 0.16, (head * CFrame.new(x, 0.1, face(x, 0.1) - 0.08)).Position, rgb(255, 40, 30), NEON)
		end
		-- Slit nostrils.
		for _, x in ipairs({ -0.14, 0.14 }) do
			box(m, V(0.1, 0.28, 0.1), head * CFrame.new(x, -0.45, face(x, -0.45) - 0.02), BLACK)
		end
		-- Huge grin stretching up the cheeks, full of yellowed teeth.
		local teeth = rgb(222, 210, 160)
		for i = -5, 5 do
			local x = i * 0.18
			local y = -1.0 + 0.09 * i * i * 0.18
			local z = face(x, y)
			local tilt = CFrame.Angles(0, 0, math.atan(0.032 * i * 2))
			box(m, V(0.2, 0.5, 0.2), head * CFrame.new(x, y, z + 0.05) * tilt, BLACK)
			box(m, V(0.13, 0.18, 0.12), head * CFrame.new(x, y + 0.13, z - 0.04) * tilt, teeth)
			box(m, V(0.13, 0.16, 0.12), head * CFrame.new(x, y - 0.14, z - 0.04) * tilt, teeth)
		end
		return 27
	end
end
