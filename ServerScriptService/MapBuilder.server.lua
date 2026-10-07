--[[
	MapBuilder.server.lua
	Script: ServerScriptService.MapBuilder

	Builds the lobby at server start: a flat floating grass platform with
	checker-tile paths, a fence, blocky trees, category game stations, a
	leaderboard wall, trampolines, and a short obby off the east edge.

	Stations live in workspace.Map.Stations. Each station folder carries
	attributes the client reads (Category, DisplayName, Color) and contains
	a Podium (with ProximityPrompt). Pressing E sends the player's camera to a separate viewing room
	(built by the client), so stations don't host the objects themselves.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
-- Saving is optional: if the module ever fails to load, run without it
-- instead of taking the whole game down.
local okPlayerData, PlayerData = pcall(function()
	return require(script.Parent:WaitForChild("PlayerData"))
end)
if not okPlayerData then
	warn("[Sizer] PlayerData failed to load; running without saving:", PlayerData)
	PlayerData = {
		load = function()
			return false
		end,
		release = function() end,
		save = function()
			return false
		end,
		getTop = function()
			return {}
		end,
	}
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local rng = Random.new(425)

local Progress = require(ReplicatedStorage:WaitForChild("Progress"))
local Ranks = require(ReplicatedStorage:WaitForChild("Ranks"))

-- Remove the Baseplate template's floor/spawn and any terrain.
local templateBaseplate = workspace:FindFirstChild("Baseplate")
if templateBaseplate then
	templateBaseplate:Destroy()
end
for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("SpawnLocation") then
		child:Destroy()
	end
end
workspace.Terrain:Clear()

local mapFolder = Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder.Parent = workspace

--==========================================================================
-- Palette & layout
--==========================================================================

local C = {
	grass = Color3.fromRGB(98, 200, 80),
	dirt = Color3.fromRGB(120, 85, 55),
	tileA = Color3.fromRGB(228, 228, 234),
	tileB = Color3.fromRGB(206, 208, 218),
	wood = Color3.fromRGB(125, 85, 52),
	woodLight = Color3.fromRGB(170, 120, 75),
	dark = Color3.fromRGB(38, 40, 52),
	white = Color3.fromRGB(250, 250, 250),
	leaves = {
		Color3.fromRGB(60, 160, 70),
		Color3.fromRGB(80, 180, 75),
		Color3.fromRGB(50, 140, 65),
	},
	flowers = {
		Color3.fromRGB(255, 110, 150),
		Color3.fromRGB(255, 215, 70),
		Color3.fromRGB(170, 120, 255),
		Color3.fromRGB(255, 255, 255),
	},
}

local HALF_X, HALF_Z = 95, 90
local TILE = 5
local TILE_TOP = 0.2

--==========================================================================
-- Helpers
--==========================================================================

local ORDERED_KEYS = { Shape = true, Size = true, CFrame = true, Position = true, Parent = true }

local function newPart(className, props)
	local p = Instance.new(className)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Size then
		p.Size = props.Size
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	end
	if props.Position then
		p.Position = props.Position
	end
	for key, value in pairs(props) do
		if not ORDERED_KEYS[key] then
			p[key] = value
		end
	end
	p.Parent = props.Parent or mapFolder
	return p
end

local function part(props)
	return newPart("Part", props)
end

local function cylinder(center, height, radius, props)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, radius * 2, radius * 2)
	props.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2)
	return part(props)
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or mapFolder
	return f
end

local function stroke(target, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or Color3.fromRGB(25, 20, 35)
	s.Parent = target
	return s
end

local function textLabel(parent, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = C.white
	for key, value in pairs(props) do
		label[key] = value
	end
	label.Parent = parent
	return label
end

local function surfaceGui(target, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 40
	gui.LightInfluence = 0
	gui.Parent = target
	return gui
end

local function lerpColor(a, b, t)
	return a:Lerp(b, t)
end

-- Checkerboard floor; x/z ranges must be multiples of TILE.
local function checker(name, minX, maxX, minZ, maxZ, tint, parent)
	local f = folder(name, parent)
	local ix = 0
	for x = minX, maxX - TILE, TILE do
		local iz = 0
		for z = minZ, maxZ - TILE, TILE do
			local color = ((ix + iz) % 2 == 0) and C.tileA or C.tileB
			if tint then
				color = lerpColor(color, tint, 0.28)
			end
			part({
				Name = "Tile",
				Size = Vector3.new(TILE, TILE_TOP, TILE),
				Position = Vector3.new(x + TILE / 2, TILE_TOP / 2, z + TILE / 2),
				Color = color,
				Parent = f,
			})
			iz += 1
		end
		ix += 1
	end
	return f
end

--==========================================================================
-- Lighting
--==========================================================================

local function setupLighting()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(110, 110, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(190, 225, 255)
	atmosphere.Decay = Color3.fromRGB(120, 170, 220)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.6
	atmosphere.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = 0.22
	colorCorrection.Contrast = 0.05
	colorCorrection.Brightness = 0.02
	colorCorrection.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 20
	bloom.Threshold = 1.8
	bloom.Parent = Lighting
end

--==========================================================================
-- Ground, fence, decoration
--==========================================================================

local function buildGround()
	local ground = folder("Ground")
	part({
		Name = "Grass",
		Size = Vector3.new(HALF_X * 2, 2, HALF_Z * 2),
		Position = Vector3.new(0, -1, 0),
		Color = C.grass,
		Parent = ground,
	})
	part({
		Name = "Dirt",
		Size = Vector3.new(HALF_X * 2 - 3, 10, HALF_Z * 2 - 3),
		Position = Vector3.new(0, -7, 0),
		Color = C.dirt,
		Parent = ground,
	})
	-- Rocky chunks under the floating platform.
	for _ = 1, 18 do
		local size = rng:NextNumber(14, 26)
		part({
			Name = "UnderRock",
			Size = Vector3.new(size, size * 0.8, size),
			CFrame = CFrame.new(rng:NextNumber(-70, 70), -14 - rng:NextNumber(0, 8), rng:NextNumber(-70, 70))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Color = Color3.fromRGB(105, 95, 90),
			Parent = ground,
		})
	end
end

local function buildFence()
	local fence = folder("Fence")
	local function isGap(x, z)
		-- Opening on the east side for the obby.
		return x > HALF_X - 1 and z > -51 and z < -39
	end
	local function fenceLine(fromPos, toPos)
		local length = (toPos - fromPos).Magnitude
		local dir = (toPos - fromPos).Unit
		local steps = math.floor(length / 5)
		for i = 0, steps do
			local p = fromPos + dir * (i * 5)
			if not isGap(p.X, p.Z) then
				part({
					Name = "FencePost",
					Size = Vector3.new(0.8, 4, 0.8),
					Position = p + Vector3.new(0, 2, 0),
					Color = C.wood,
					Parent = fence,
				})
			end
			if i < steps then
				local mid = p + dir * 2.5
				if not isGap(mid.X, mid.Z) then
					for _, y in ipairs({ 1.6, 3.1 }) do
						part({
							Name = "FenceRail",
							Size = Vector3.new(0.4, 0.5, 5),
							CFrame = CFrame.lookAt(mid + Vector3.new(0, y, 0), mid + Vector3.new(0, y, 0) + dir),
							Color = C.woodLight,
							Parent = fence,
						})
					end
				end
			end
		end
	end
	local x, z = HALF_X - 0.5, HALF_Z - 0.5
	fenceLine(Vector3.new(-x, 0, -z), Vector3.new(x, 0, -z))
	fenceLine(Vector3.new(x, 0, -z), Vector3.new(x, 0, z))
	fenceLine(Vector3.new(x, 0, z), Vector3.new(-x, 0, z))
	fenceLine(Vector3.new(-x, 0, z), Vector3.new(-x, 0, -z))
end

local function blockyTree(position, scale, parent)
	scale = scale or 1
	part({
		Name = "Trunk",
		Size = Vector3.new(2, 6, 2) * scale,
		Position = position + Vector3.new(0, 3 * scale, 0),
		Color = C.wood,
		Parent = parent,
	})
	local green = C.leaves[rng:NextInteger(1, #C.leaves)]
	part({
		Name = "Leaves",
		Size = Vector3.new(9, 5, 9) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 8 * scale, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 45)), 0),
		Color = green,
		Parent = parent,
	})
	part({
		Name = "LeavesTop",
		Size = Vector3.new(6, 3.5, 6) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 11.5 * scale, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 45)), 0),
		Color = green:Lerp(Color3.new(1, 1, 1), 0.12),
		Parent = parent,
	})
end

local function flowerPatch(position, parent)
	for _ = 1, 7 do
		part({
			Name = "Flower",
			Size = Vector3.new(0.8, 0.8, 0.8),
			Position = position + Vector3.new(rng:NextNumber(-3, 3), 0.4, rng:NextNumber(-3, 3)),
			Color = C.flowers[rng:NextInteger(1, #C.flowers)],
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

local function bench(position, facing, parent)
	local base = CFrame.lookAt(position, position + facing)
	part({ Name = "BenchSeat", Size = Vector3.new(6, 0.5, 2), CFrame = base * CFrame.new(0, 1.6, 0), Color = C.woodLight, Parent = parent })
	part({ Name = "BenchBack", Size = Vector3.new(6, 1.6, 0.4), CFrame = base * CFrame.new(0, 2.8, 0.8), Color = C.woodLight, Parent = parent })
	for _, x in ipairs({ -2.5, 2.5 }) do
		part({ Name = "BenchLeg", Size = Vector3.new(0.5, 1.4, 1.6), CFrame = base * CFrame.new(x, 0.7, 0), Color = C.dark, Parent = parent })
	end
end

local function lampPost(position, parent)
	part({ Name = "LampBase", Size = Vector3.new(1.4, 1, 1.4), Position = position + Vector3.new(0, 0.5, 0), Color = C.dark, Parent = parent })
	part({ Name = "LampPole", Size = Vector3.new(0.6, 9, 0.6), Position = position + Vector3.new(0, 5, 0), Color = C.dark, Parent = parent })
	local bulb = part({
		Name = "LampBulb",
		Size = Vector3.new(1.6, 1.6, 1.6),
		Position = position + Vector3.new(0, 10.2, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 225, 160),
		CanCollide = false,
		Parent = parent,
	})
	part({ Name = "LampCap", Size = Vector3.new(2.2, 0.5, 2.2), Position = position + Vector3.new(0, 11.25, 0), Color = C.dark, Parent = parent })
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 220, 160)
	light.Parent = bulb
end

local function worldLabel(text, position, color, width, parent)
	local anchor = part({
		Name = "Label_" .. text,
		Size = Vector3.new(1, 1, 1),
		Position = position,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(width or 18, 0, 4, 0)
	billboard.MaxDistance = 200
	billboard.LightInfluence = 0
	billboard.Parent = anchor
	stroke(textLabel(billboard, { Size = UDim2.fromScale(1, 1), Text = text, TextColor3 = color }), 4)
end

-- West: oversized everyday objects to climb on (fits the size theme).
local function buildGiantGarden()
	local garden = folder("GiantGarden")
	worldLabel("GIANT GARDEN", Vector3.new(-38, 14, 4), Color3.fromRGB(255, 225, 60), 22, garden)

	-- Giant pencil lying on its side (cylinders run along X by default).
	local function pencilPiece(name, x, length, radius, color)
		part({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(length, radius * 2, radius * 2),
			Position = Vector3.new(x, radius, 36),
			Color = color,
			Parent = garden,
		})
	end
	pencilPiece("PencilBody", -64, 30, 3, Color3.fromRGB(255, 200, 40))
	pencilPiece("PencilBand", -80.25, 2.5, 3.1, Color3.fromRGB(190, 195, 205))
	pencilPiece("PencilEraser", -83.5, 4, 3, Color3.fromRGB(255, 130, 150))
	pencilPiece("PencilWood1", -48, 2, 2.3, Color3.fromRGB(235, 195, 140))
	pencilPiece("PencilWood2", -46, 2, 1.5, Color3.fromRGB(235, 195, 140))
	pencilPiece("PencilLead", -44.25, 1.5, 0.7, Color3.fromRGB(50, 50, 55))

	-- Giant soda can.
	cylinder(Vector3.new(-76, 8, 4), 16, 6, { Name = "CanBody", Color = Color3.fromRGB(220, 40, 45), Parent = garden })
	cylinder(Vector3.new(-76, 8, 4), 3, 6.08, { Name = "CanStripe", Color = C.white, Parent = garden })
	cylinder(Vector3.new(-76, 16.2, 4), 0.4, 5.6, { Name = "CanTop", Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 205, 215), Parent = garden })
	part({ Name = "CanTab", Size = Vector3.new(2.4, 0.3, 1.2), Position = Vector3.new(-74.5, 16.5, 4), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 205, 215), Parent = garden })

	-- Giant rubber duck facing the main path.
	local duckYellow = Color3.fromRGB(255, 215, 50)
	part({ Name = "DuckBody", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 14, 14), Position = Vector3.new(-52, 7, 4), Color = duckYellow, Parent = garden })
	part({ Name = "DuckTail", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Position = Vector3.new(-58.5, 10, 4), Color = duckYellow, Parent = garden })
	part({ Name = "DuckHead", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), Position = Vector3.new(-48, 15, 4), Color = duckYellow, Parent = garden })
	part({ Name = "DuckBeak", Size = Vector3.new(4, 1.6, 3.4), Position = Vector3.new(-43.5, 14.4, 4), Color = Color3.fromRGB(255, 140, 30), Parent = garden })
	for _, z in ipairs({ 2, 6 }) do
		part({ Name = "DuckEye", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Position = Vector3.new(-44.2, 16.5, z), Color = C.dark, Parent = garden })
	end

	-- Giant stack of books (jump up the covers).
	local books = {
		{ Vector3.new(22, 4, 15), Color3.fromRGB(60, 120, 220), 6 },
		{ Vector3.new(19, 4, 13), Color3.fromRGB(220, 70, 70), -9 },
		{ Vector3.new(16, 4, 11), Color3.fromRGB(80, 180, 90), 14 },
	}
	local y = 0
	for i, book in ipairs(books) do
		local size, color, yaw = book[1], book[2], book[3]
		local cf = CFrame.new(-70, y + size.Y / 2, -24) * CFrame.Angles(0, math.rad(yaw), 0)
		part({ Name = "Book" .. i, Size = size, CFrame = cf, Color = color, Parent = garden })
		part({
			Name = "BookPages" .. i,
			Size = Vector3.new(size.X - 1.2, size.Y - 0.8, 0.4),
			CFrame = cf * CFrame.new(0, 0, -size.Z / 2 - 0.05),
			Color = Color3.fromRGB(250, 245, 230),
			Parent = garden,
		})
		y += size.Y
	end

	-- A tiny house for contrast.
	local houseBase = Vector3.new(-44, 0, -22)
	part({ Name = "TinyHouse", Size = Vector3.new(3, 2.4, 3), Position = houseBase + Vector3.new(0, 1.2, 0), Color = Color3.fromRGB(245, 235, 210), Parent = garden })
	newPart("WedgePart", { Name = "TinyRoofA", Size = Vector3.new(3.6, 1.4, 1.8), CFrame = CFrame.new(houseBase + Vector3.new(0, 3.1, -0.9)), Color = Color3.fromRGB(200, 70, 60), Parent = garden })
	newPart("WedgePart", { Name = "TinyRoofB", Size = Vector3.new(3.6, 1.4, 1.8), CFrame = CFrame.new(houseBase + Vector3.new(0, 3.1, 0.9)) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(200, 70, 60), Parent = garden })
	part({ Name = "TinyDoor", Size = Vector3.new(0.1, 1.3, 0.7), Position = houseBase + Vector3.new(1.55, 0.65, 0), Color = C.wood, Parent = garden })
	blockyTree(houseBase + Vector3.new(3, 0, 2.5), 0.22, garden)
	worldLabel("tiny house", houseBase + Vector3.new(0, 6, 0), C.white, 8, garden)
end

-- East: pond, gazebo, benches.
local function buildPark()
	local park = folder("Park")
	worldLabel("THE PARK", Vector3.new(38, 14, 4), Color3.fromRGB(120, 220, 255), 18, park)

	local pondCenter = Vector3.new(62, 0, 20)
	cylinder(pondCenter + Vector3.new(0, 0.12, 0), 0.24, 13.5, {
		Name = "PondWater",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(60, 160, 230),
		Transparency = 0.05,
		Reflectance = 0.15,
		Parent = park,
	})
	for i = 0, 23 do
		local angle = (i / 24) * math.pi * 2
		local pos = pondCenter + Vector3.new(math.cos(angle) * 14, 0.6, math.sin(angle) * 14)
		part({
			Name = "PondStone",
			Size = Vector3.new(2, 1.2, 4),
			CFrame = CFrame.lookAt(pos, Vector3.new(pondCenter.X, pos.Y, pondCenter.Z)) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(165, 160, 155),
			Parent = park,
		})
	end
	for _ = 1, 6 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(3, 10)
		cylinder(pondCenter + Vector3.new(math.cos(angle) * radius, 0.3, math.sin(angle) * radius), 0.1, rng:NextNumber(1, 1.8), {
			Name = "LilyPad",
			Color = Color3.fromRGB(70, 170, 80),
			CanCollide = false,
			Parent = park,
		})
	end
	-- Tiny ducks (a callback to the giant one).
	for i = 1, 3 do
		local p = pondCenter + Vector3.new(-5 + i * 3, 0.6, -2 + (i % 2) * 3)
		part({ Name = "TinyDuck", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), Position = p, Color = Color3.fromRGB(255, 215, 50), CanCollide = false, Parent = park })
		part({ Name = "TinyDuckHead", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Position = p + Vector3.new(0.4, 0.6, 0), Color = Color3.fromRGB(255, 215, 50), CanCollide = false, Parent = park })
	end
	for _, b in ipairs({ { Vector3.new(62, 0, 39), Vector3.new(0, 0, -1) }, { Vector3.new(43, 0, 20), Vector3.new(1, 0, 0) }, { Vector3.new(81, 0, 20), Vector3.new(-1, 0, 0) } }) do
		bench(b[1], b[2], park)
	end

	-- Gazebo with a stepped blocky roof.
	local g = Vector3.new(62, 0, -20)
	cylinder(g + Vector3.new(0, 0.5, 0), 1, 9, { Name = "GazeboFloor", Color = C.white, Parent = park })
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2 + math.pi / 6
		part({
			Name = "GazeboPillar",
			Size = Vector3.new(1, 9, 1),
			Position = g + Vector3.new(math.cos(angle) * 7.8, 5.5, math.sin(angle) * 7.8),
			Color = C.white,
			Parent = park,
		})
	end
	for i, r in ipairs({ 9.8, 7.4, 5, 2.6 }) do
		cylinder(g + Vector3.new(0, 10 + i, 0), 1, r, {
			Name = "GazeboRoof",
			Color = (i % 2 == 1) and Color3.fromRGB(220, 75, 70) or C.white,
			Parent = park,
		})
	end
end

-- South-east: playground.
local function buildPlayground()
	local playground = folder("Playground")
	worldLabel("PLAYGROUND", Vector3.new(58, 14, -66), Color3.fromRGB(255, 140, 200), 18, playground)
	for _, pos in ipairs({ Vector3.new(42, 0, -64), Vector3.new(54, 0, -76), Vector3.new(68, 0, -64) }) do
		cylinder(pos + Vector3.new(0, 0.8, 0), 1.6, 4.6, { Name = "TrampolineFrame", Color = Color3.fromRGB(60, 140, 255), Parent = playground })
		local mat = cylinder(pos + Vector3.new(0, 1.65, 0), 0.2, 4, { Name = "TrampolineMat", Color = C.dark, Parent = playground })
		CollectionService:AddTag(mat, "Trampoline")
	end

	-- Swing set (decorative).
	local s = Vector3.new(80, 0, -72)
	for _, z in ipairs({ -6, 6 }) do
		for _, x in ipairs({ -2, 2 }) do
			part({
				Name = "SwingLeg",
				Size = Vector3.new(0.6, 10, 0.6),
				CFrame = CFrame.new(s + Vector3.new(x * 0.6, 4.8, z)) * CFrame.Angles(0, 0, math.rad(x > 0 and -12 or 12)),
				Color = Color3.fromRGB(240, 90, 90),
				Parent = playground,
			})
		end
	end
	part({ Name = "SwingBar", Size = Vector3.new(0.6, 0.6, 13), Position = s + Vector3.new(0, 9.7, 0), Color = Color3.fromRGB(240, 90, 90), Parent = playground })
	for _, z in ipairs({ -2.5, 2.5 }) do
		for _, x in ipairs({ -0.9, 0.9 }) do
			part({ Name = "SwingRope", Size = Vector3.new(0.15, 7, 0.15), Position = s + Vector3.new(x, 6, z), Color = C.dark, CanCollide = false, Parent = playground })
		end
		part({ Name = "SwingSeat", Size = Vector3.new(2.2, 0.3, 1.2), Position = s + Vector3.new(0, 2.4, z), Color = C.dark, Parent = playground })
	end

	-- Sandbox.
	part({ Name = "Sand", Size = Vector3.new(14, 0.4, 14), Position = Vector3.new(40, 0.2, -80), Material = Enum.Material.Sand, Color = Color3.fromRGB(235, 215, 160), Parent = playground })
	for _, e in ipairs({ { 0, 7.25, 15, 1 }, { 0, -7.25, 15, 1 }, { 7.25, 0, 1, 15 }, { -7.25, 0, 1, 15 } }) do
		part({ Name = "SandEdge", Size = Vector3.new(e[3], 1, e[4]), Position = Vector3.new(40 + e[1], 0.5, -80 + e[2]), Color = C.woodLight, Parent = playground })
	end
end

-- South-west: picnic area.
local function buildPicnic()
	local picnic = folder("Picnic")
	worldLabel("PICNIC SPOT", Vector3.new(-58, 12, -66), Color3.fromRGB(255, 170, 90), 18, picnic)
	for _, pos in ipairs({ Vector3.new(-45, 0, -66), Vector3.new(-62, 0, -76), Vector3.new(-78, 0, -64) }) do
		part({ Name = "TableTop", Size = Vector3.new(8, 0.5, 4), Position = pos + Vector3.new(0, 3, 0), Color = C.woodLight, Parent = picnic })
		part({ Name = "Tablecloth", Size = Vector3.new(6, 0.1, 4.1), Position = pos + Vector3.new(0, 3.3, 0), Color = Color3.fromRGB(230, 70, 70), Parent = picnic })
		for _, x in ipairs({ -3, 3 }) do
			part({ Name = "TableLeg", Size = Vector3.new(0.5, 2.8, 3), Position = pos + Vector3.new(x, 1.4, 0), Color = C.wood, Parent = picnic })
		end
		for _, z in ipairs({ -3, 3 }) do
			part({ Name = "TableBench", Size = Vector3.new(8, 0.5, 1.4), Position = pos + Vector3.new(0, 1.7, z), Color = C.woodLight, Parent = picnic })
		end
		part({ Name = "Basket", Size = Vector3.new(1.4, 1, 1), Position = pos + Vector3.new(1.5, 3.85, 0), Color = Color3.fromRGB(190, 140, 80), Parent = picnic })
	end
end

local function buildDecor()
	local decor = folder("Decor")
	local trees = {
		-- Edges
		{ -88, -84 }, { -60, -86 }, { -30, -84 }, { 30, -86 }, { 88, -84 },
		{ -88, -25 }, { -88, 20 }, { -88, 72 }, { 88, -25 }, { 88, 2 }, { 88, 36 }, { 88, 72 },
		{ -85, 84 }, { -62, 84 }, { -40, 86 }, { 40, 86 }, { 62, 84 }, { 85, 84 },
		-- Inner
		{ -40, 72 }, { -62, 68 }, { 40, 72 }, { 62, 68 }, { 78, -36 }, { 46, -4 },
		{ 47, 44 }, { 82, 46 }, { -36, -60 }, { -84, -48 }, { -36, 82 }, { 36, 82 },
		{ -32, -78 }, { 32, -78 },
	}
	for _, t in ipairs(trees) do
		blockyTree(Vector3.new(t[1], 0, t[2]), rng:NextNumber(0.9, 1.3), decor)
	end
	for _, f in ipairs({
		{ -50, 74 }, { -72, 76 }, { 50, 74 }, { 72, 76 }, { -30, -70 }, { 30, -70 },
		{ -27, 18 }, { 27, -34 }, { 80, -2 }, { -84, 40 }, { -26, 48 }, { 26, 48 },
	}) do
		flowerPatch(Vector3.new(f[1], 0, f[2]), decor)
	end

	-- Lamp posts along the cross paths.
	for _, x in ipairs({ -85, -65, -50, 50, 65, 85 }) do
		for _, z in ipairs({ -52, -38, 48, 62 }) do
			lampPost(Vector3.new(x, 0, z), decor)
		end
	end

	bench(Vector3.new(-12, TILE_TOP, -76), Vector3.new(0, 0, 1), decor)
	bench(Vector3.new(12, TILE_TOP, -76), Vector3.new(0, 0, 1), decor)
end

--==========================================================================
-- Paths & spawn
--==========================================================================

local function buildPaths()
	local paths = folder("Paths")
	checker("SpawnPlaza", -15, 15, -80, -55, nil, paths)
	checker("MainPath", -5, 5, -55, 60, nil, paths)
	-- Cross paths out to the side zones (skip the main path they cross).
	checker("SouthCrossWest", -90, -5, -50, -40, nil, paths)
	checker("SouthCrossEast", 5, 90, -50, -40, nil, paths)
	checker("NorthCrossWest", -90, -5, 50, 60, nil, paths)
	checker("NorthCrossEast", 5, 90, 50, 60, nil, paths)
	-- Spurs from the cross paths into the garden and park.
	checker("GardenSpur", -40, -30, -40, 50, nil, paths)
	checker("ParkSpur", 30, 40, -40, 50, nil, paths)

	cylinder(Vector3.new(0, TILE_TOP + 0.1, -67), 0.2, 5, {
		Name = "SpawnRing",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(90, 200, 255),
		Parent = paths,
	})
	cylinder(Vector3.new(0, TILE_TOP + 0.15, -67), 0.2, 4.2, {
		Name = "SpawnPad",
		Color = C.white,
		Parent = paths,
	})
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = CFrame.new(0, 1, -67) * CFrame.Angles(0, math.pi, 0)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.Transparency = 1
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = paths
end

--==========================================================================
-- Game stations
--==========================================================================

local STATIONS = {
	{ category = "Animals", label = "ANIMALS", icon = "🐘", color = Color3.fromRGB(255, 140, 40), pos = Vector3.new(-15, 0, 32) },
	{ category = "Landmarks", label = "LANDMARKS", icon = "🗽", color = Color3.fromRGB(60, 150, 255), pos = Vector3.new(15, 0, 32) },
	{ category = "Everyday Objects", label = "EVERYDAY", icon = "☕", color = Color3.fromRGB(255, 85, 155), pos = Vector3.new(-15, 0, 2) },
	{ category = "Space", label = "SPACE", icon = "🪐", color = Color3.fromRGB(150, 95, 255), pos = Vector3.new(15, 0, 2) },
	{ category = "", label = "60s CHALLENGE", icon = "⏱️", color = Color3.fromRGB(255, 200, 40), pos = Vector3.new(-15, 0, -28), mode = "timed", subtitle = "BEAT THE CLOCK" },
	{ category = "", label = "MIXED", icon = "🎲", color = Color3.fromRGB(30, 200, 200), pos = Vector3.new(15, 0, -28) },
	-- End of the line, centered on the main path and facing the spawn,
	-- topped with a giant Verity.
	{
		category = "Brainrot",
		label = "BRAINROT",
		icon = "🧠",
		color = Color3.fromRGB(255, 70, 190),
		pos = Vector3.new(0, 0, 70),
		facing = Vector3.new(0, 0, -1),
		subtitle = "MEME SIZES",
		giant = { model = "Verity", scale = 3.2 },
	},
}

local function buildStation(def, index, parent)
	local station = folder("Station" .. index, parent)
	station:SetAttribute("Category", def.category)
	station:SetAttribute("DisplayName", def.label)
	station:SetAttribute("Color", def.color)
	station:SetAttribute("Mode", def.mode or "normal")

	local center = def.pos
	-- Side stations face the main path (x = 0); centered ones set `facing`.
	local facing = def.facing or Vector3.new(-math.sign(center.X), 0, 0)
	local base = CFrame.lookAt(center, center + facing)
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end

	checker("Pad", center.X - 10, center.X + 10, center.Z - 10, center.Z + 10, def.color, station)

	-- Colored border along the three non-path sides.
	for _, edge in ipairs({
		{ Vector3.new(20, 0.5, 0.8), Vector3.new(0, 0, 9.6) },
		{ Vector3.new(0.8, 0.5, 20), Vector3.new(-9.6, 0, 0) },
		{ Vector3.new(0.8, 0.5, 20), Vector3.new(9.6, 0, 0) },
	}) do
		part({
			Name = "Border",
			Size = edge[1],
			CFrame = at(edge[2].X, TILE_TOP + 0.25, edge[2].Z),
			Color = def.color,
			Parent = station,
		})
	end

	-- Podium with the start prompt.
	local podium = part({
		Name = "Podium",
		Size = Vector3.new(4, 3.4, 2),
		CFrame = at(0, TILE_TOP + 1.7, -5),
		Color = C.dark,
		Parent = station,
	})
	part({
		Name = "PodiumTop",
		Size = Vector3.new(4.6, 0.5, 2.6),
		CFrame = at(0, TILE_TOP + 3.65, -5),
		Color = def.color,
		Parent = station,
	})
	local face = part({
		Name = "PodiumFace",
		Size = Vector3.new(3.2, 2, 0.1),
		CFrame = at(0, TILE_TOP + 1.9, -6.05),
		Material = Enum.Material.Neon,
		Color = def.color,
		CanCollide = false,
		Parent = station,
	})
	textLabel(surfaceGui(face, 60), { Size = UDim2.fromScale(1, 1), Text = "PLAY" })

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ProximityPrompt"
	prompt.ActionText = "Play"
	prompt.ObjectText = def.label
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = podium

	-- Back panel showing the category icon.
	local panelHeight = 13
	local panel = part({
		Name = "BackPanel",
		Size = Vector3.new(16, panelHeight, 0.6),
		CFrame = at(0, TILE_TOP + panelHeight / 2, 8),
		Color = C.white,
		Parent = station,
	})
	part({
		Name = "PanelTrim",
		Size = Vector3.new(16.6, 0.8, 1),
		CFrame = at(0, TILE_TOP + panelHeight + 0.4, 8),
		Color = def.color,
		Parent = station,
	})
	local panelGui = surfaceGui(panel, 30)
	textLabel(panelGui, {
		Size = UDim2.fromScale(0.7, 0.62),
		Position = UDim2.fromScale(0.15, 0.06),
		Text = def.icon,
	})
	stroke(textLabel(panelGui, {
		Size = UDim2.fromScale(0.9, 0.22),
		Position = UDim2.fromScale(0.05, 0.72),
		Text = "PRESS E TO PLAY",
		TextColor3 = def.color,
	}), 3)

	-- Giant character perched on top of the back panel.
	local labelCFrame = at(0, TILE_TOP + panelHeight + 4, 8)
	if def.giant then
		local ObjectModels = require(ReplicatedStorage:WaitForChild("ObjectModels"))
		local perchY = TILE_TOP + panelHeight + 0.8
		local perch = at(0, perchY, 8).Position
		cylinder(perch + Vector3.new(0, 0.3, 0), 0.6, 5, {
			Name = "GiantPerch",
			Material = Enum.Material.Neon,
			Color = def.color,
			Parent = station,
		})
		local giant = ObjectModels.build(def.giant.model, def.icon, def.color)
		giant.Name = "Giant" .. def.giant.model
		giant:ScaleTo(def.giant.scale)
		giant:PivotTo(CFrame.new(perch.X, perch.Y + 0.6, perch.Z))
		giant.Parent = station
		local core = giant:FindFirstChildWhichIsA("BasePart")
		if core then
			local glow = Instance.new("PointLight")
			glow.Range = 50
			glow.Brightness = 1.5
			glow.Color = Color3.fromRGB(255, 225, 110)
			glow.Parent = core
		end
		-- The giant covers the usual title spot, so float it in front.
		labelCFrame = at(0, TILE_TOP + 15.5, -1)
	end

	-- Floating world-scaled title above the station.
	local labelAnchor = part({
		Name = "LabelAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = labelCFrame,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = station,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(16, 0, 5, 0)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Parent = labelAnchor
	local title = textLabel(billboard, {
		Size = UDim2.fromScale(1, 0.65),
		Text = def.label,
		TextColor3 = def.color,
	})
	stroke(title, 4)
	local sub = textLabel(billboard, {
		Size = UDim2.fromScale(1, 0.32),
		Position = UDim2.fromScale(0, 0.66),
		Text = def.subtitle or "SOLO",
	})
	stroke(sub, 3)

	return station
end

local function buildStations()
	local stations = folder("Stations")
	for i, def in ipairs(STATIONS) do
		buildStation(def, i, stations)
	end
end

--==========================================================================
-- Leaderboard wall (north)
--==========================================================================

local function darkBoard(name, position, facingTarget, size, parent)
	local center = position + Vector3.new(0, size.Y / 2 + 2, 0)
	local cf = CFrame.lookAt(center, Vector3.new(facingTarget.X, center.Y, facingTarget.Z))
	part({ Name = name .. "Frame", Size = size + Vector3.new(1, 1, 0.4), CFrame = cf * CFrame.new(0, 0, 0.4), Color = C.dark, Parent = parent })
	for _, x in ipairs({ -size.X / 2 + 1, size.X / 2 - 1 }) do
		part({
			Name = name .. "Leg",
			Size = Vector3.new(0.8, 3, 0.8),
			CFrame = cf * CFrame.new(x, -size.Y / 2 - 1, 0.4),
			Color = C.dark,
			Parent = parent,
		})
	end
	return part({
		Name = name,
		Size = Vector3.new(size.X, size.Y, 0.2),
		CFrame = cf,
		Color = Color3.fromRGB(20, 22, 30),
		Parent = parent,
	})
end

local function withCommas(n)
	local formatted = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- "resets in 3d 4h" / "resets in 5h 12m".
local function formatReset(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	if days > 0 then
		return string.format("resets in %dd %dh", days, hours)
	end
	return string.format("resets in %dh %02dm", hours, math.floor(seconds % 3600 / 60))
end

-- kind is "Sense" or "TimedWeek"; entries come from PlayerData (saved
-- global top list merged with the players currently online). The Sense
-- board shows each player's rank icon.
local function refreshLeaderboard(list, kind)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local entries = PlayerData.getTop(kind, 8)
	for i, entry in ipairs(entries) do
		textLabel(list, {
			LayoutOrder = i,
			Size = UDim2.fromScale(1, 0.115),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = (i == 1 and Color3.fromRGB(255, 210, 70))
				or (i == 2 and Color3.fromRGB(210, 220, 235))
				or (i == 3 and Color3.fromRGB(230, 150, 90))
				or C.white,
			Text = string.format(
				"%d.  %s%s  -  %s",
				i,
				kind == "Sense" and (Ranks.forSense(entry.value).rank.icon .. " ") or "",
				entry.name,
				withCommas(entry.value)
			),
		})
	end
	if #entries == 0 then
		textLabel(list, {
			Size = UDim2.fromScale(1, 0.14),
			TextColor3 = Color3.fromRGB(150, 155, 175),
			Text = "No scores yet - be the first!",
		})
	end
end

local function buildBoards()
	local boards = folder("Boards")
	-- All boards surround the spawn pad and face it: one directly behind the
	-- player and one on each side.
	local lookTarget = Vector3.new(0, 0, -67)

	local main = darkBoard("Leaderboard", Vector3.new(0, TILE_TOP, -84), lookTarget, Vector3.new(16, 11, 0.2), boards)
	local gui = surfaceGui(main, 40)
	stroke(textLabel(gui, {
		Size = UDim2.fromScale(1, 0.16),
		Text = "🏆 TOP GUESSERS",
		TextColor3 = Color3.fromRGB(255, 210, 70),
	}), 3)
	textLabel(gui, {
		Size = UDim2.fromScale(0.5, 0.06),
		Position = UDim2.fromScale(0.25, 0.165),
		Text = "ranked by SENSE (rank shown)",
		TextColor3 = Color3.fromRGB(150, 160, 190),
	})
	local list = Instance.new("Frame")
	list.Size = UDim2.fromScale(0.86, 0.72)
	list.Position = UDim2.fromScale(0.07, 0.24)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.008, 0)
	layout.Parent = list
	refreshLeaderboard(list, "Sense")

	local howTo = darkBoard("HowTo", Vector3.new(-21, TILE_TOP, -67), lookTarget, Vector3.new(13, 9, 0.2), boards)
	stroke(textLabel(surfaceGui(howTo, 40), {
		Size = UDim2.fromScale(0.9, 0.9),
		Position = UDim2.fromScale(0.05, 0.05),
		Text = "HOW TO PLAY\n\nWalk up to a station & press E.\nDrag the slider to guess the size.\nLock in to score up to 100!\n\nCome back daily: DAILY + streaks!",
		TextColor3 = Color3.fromRGB(120, 220, 255),
	}), 2)

	local records = darkBoard("TimedRecords", Vector3.new(21, TILE_TOP, -67), lookTarget, Vector3.new(13, 9, 0.2), boards)
	local recordsGui = surfaceGui(records, 40)
	stroke(textLabel(recordsGui, {
		Size = UDim2.fromScale(1, 0.18),
		Text = "⏱️ 60s RECORDS",
		TextColor3 = Color3.fromRGB(255, 200, 40),
	}), 3)
	local resetLabel = textLabel(recordsGui, {
		Size = UDim2.fromScale(0.7, 0.06),
		Position = UDim2.fromScale(0.15, 0.165),
		Text = "THIS WEEK",
		TextColor3 = Color3.fromRGB(150, 160, 190),
	})
	local recordsList = Instance.new("Frame")
	recordsList.Size = UDim2.fromScale(0.86, 0.72)
	recordsList.Position = UDim2.fromScale(0.07, 0.24)
	recordsList.BackgroundTransparency = 1
	recordsList.Parent = recordsGui
	local recordsLayout = Instance.new("UIListLayout")
	recordsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	recordsLayout.Padding = UDim.new(0.008, 0)
	recordsLayout.Parent = recordsList
	local function refreshRecords()
		refreshLeaderboard(recordsList, "TimedWeek")
		resetLabel.Text = "THIS WEEK  -  " .. formatReset(Progress.secondsUntilNextWeek(os.time()))
	end
	refreshRecords()

	task.spawn(function()
		while true do
			task.wait(3)
			refreshLeaderboard(list, "Sense")
			refreshRecords()
		end
	end)
end

--==========================================================================
-- Obby
--==========================================================================

-- Obby positions were authored for an edge at x = 55; shift onto the real edge.
local OBBY_OFFSET = Vector3.new(HALF_X - 55, 0, 5)

local function buildObby()
	local obby = folder("Obby")
	local colors = {
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(255, 170, 50),
		Color3.fromRGB(255, 225, 60),
		Color3.fromRGB(90, 210, 90),
		Color3.fromRGB(60, 160, 255),
		Color3.fromRGB(160, 100, 255),
	}
	local steps = {
		{ Vector3.new(61, 1, -50), Vector3.new(6, 1, 6) },
		{ Vector3.new(68, 2, -46), Vector3.new(5, 1, 5) },
		{ Vector3.new(75, 3, -50), Vector3.new(5, 1, 5) },
		{ Vector3.new(82, 4.5, -45), Vector3.new(4, 1, 4) },
		{ Vector3.new(89, 5, -40), Vector3.new(6, 1, 6), moving = Vector3.new(89, 5, -28) },
		{ Vector3.new(90, 6, -20), Vector3.new(5, 1, 5) },
		{ Vector3.new(85, 7, -11), Vector3.new(2, 1, 10) },
		{ Vector3.new(85, 8, 0), Vector3.new(6, 1, 6) },
		{ Vector3.new(85, 20, 8), Vector3.new(6, 1, 6) },
		{ Vector3.new(77, 20.5, 16), Vector3.new(4, 1, 4) },
		{ Vector3.new(69, 21, 22), Vector3.new(4, 1, 4) },
		{ Vector3.new(61, 21.5, 27), Vector3.new(3, 1, 3) },
	}
	for i, step in ipairs(steps) do
		local platform = part({
			Name = "ObbyStep" .. i,
			Size = step[2],
			Position = step[1] + OBBY_OFFSET,
			Color = colors[(i - 1) % #colors + 1],
			Parent = obby,
		})
		if step.moving then
			platform.Material = Enum.Material.Neon
			TweenService:Create(
				platform,
				TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = step.moving + OBBY_OFFSET }
			):Play()
		end
	end
	newPart("TrussPart", {
		Name = "ObbyTruss",
		Size = Vector3.new(2, 12, 2),
		Position = Vector3.new(85, 14.5, 4) + OBBY_OFFSET,
		Color = C.dark,
		Parent = obby,
	})

	local finish = part({
		Name = "ObbyFinish",
		Size = Vector3.new(12, 1, 12),
		Position = Vector3.new(66, 22, 38) + OBBY_OFFSET,
		Color = C.grass,
		Parent = obby,
	})
	part({
		Name = "ObbyFinishDirt",
		Size = Vector3.new(11, 4, 11),
		Position = finish.Position - Vector3.new(0, 2.5, 0),
		Color = C.dirt,
		Parent = obby,
	})
	local cup = part({
		Name = "Trophy",
		Size = Vector3.new(2, 3, 2),
		Position = finish.Position + Vector3.new(0, 3.5, 2),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(255, 200, 50),
		Reflectance = 0.3,
		Parent = obby,
	})
	part({
		Name = "TrophyBase",
		Size = Vector3.new(3, 1.5, 3),
		Position = finish.Position + Vector3.new(0, 1.25, 2),
		Color = C.dark,
		Parent = obby,
	})
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Rate = 10
	sparkle.Lifetime = NumberRange.new(1, 1.5)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.4)
	sparkle.Parent = cup

	local signAnchor = part({
		Name = "ObbySignAnchor",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(HALF_X - 3, 7, -45),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = obby,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(12, 0, 3, 0)
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0
	billboard.Parent = signAnchor
	stroke(textLabel(billboard, { Size = UDim2.fromScale(1, 1), Text = "OBBY", TextColor3 = Color3.fromRGB(255, 225, 60) }), 4)
end

--==========================================================================
-- Build
--==========================================================================

-- Each step runs on its own so one failure can't leave the rest unbuilt.
local steps = {
	{ "lighting", setupLighting },
	{ "ground", buildGround },
	{ "fence", buildFence },
	{ "paths", buildPaths },
	{ "stations", buildStations },
	{ "boards", buildBoards },
	{ "giant garden", buildGiantGarden },
	{ "park", buildPark },
	{ "playground", buildPlayground },
	{ "picnic", buildPicnic },
	{ "decor", buildDecor },
	{ "obby", buildObby },
}

local failed = 0
for _, step in ipairs(steps) do
	local ok, err = xpcall(step[2], debug.traceback)
	if not ok then
		failed += 1
		warn("[Sizer] Map step '" .. step[1] .. "' failed:", err)
	end
end
print(string.format("[Sizer] Map built (%d of %d steps ok)", #steps - failed, #steps))
