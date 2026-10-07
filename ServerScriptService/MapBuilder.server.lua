--[[
	MapBuilder.server.lua
	Script: ServerScriptService.MapBuilder

	Builds "Sizer Island" at server start: a small terrain island with a
	beach, a cobblestone spawn plaza (fountain, leaderboard, stalls, lamps),
	the Scale Stage where the game is played, a cottage lane, a climbable
	lighthouse, a trampoline playground, and an obby over the water.

	Everything is generated from terrain + Parts using Roblox's built-in
	materials, so no uploaded assets are needed.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

local Terrain = workspace.Terrain
local rng = Random.new(425)

-- Remove the Baseplate template's floor and spawn so the island replaces them.
local templateBaseplate = workspace:FindFirstChild("Baseplate")
if templateBaseplate then
	templateBaseplate:Destroy()
end
for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("SpawnLocation") then
		child:Destroy()
	end
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder.Parent = workspace

--==========================================================================
-- Palette
--==========================================================================

local C = {
	stone = Color3.fromRGB(150, 145, 140),
	darkStone = Color3.fromRGB(95, 95, 100),
	cobble = Color3.fromRGB(170, 160, 150),
	wood = Color3.fromRGB(110, 75, 48),
	planks = Color3.fromRGB(165, 118, 76),
	darkMetal = Color3.fromRGB(45, 48, 55),
	warmLight = Color3.fromRGB(255, 205, 140),
	cream = Color3.fromRGB(240, 232, 215),
	brick = Color3.fromRGB(165, 85, 65),
	roofRed = Color3.fromRGB(170, 70, 55),
	roofBlue = Color3.fromRGB(70, 95, 140),
	signText = Color3.fromRGB(255, 245, 225),
	accentBlue = Color3.fromRGB(60, 120, 220),
	accentOrange = Color3.fromRGB(240, 145, 40),
	leafGreens = {
		Color3.fromRGB(76, 140, 60),
		Color3.fromRGB(95, 160, 70),
		Color3.fromRGB(60, 120, 55),
		Color3.fromRGB(110, 165, 80),
	},
	flowers = {
		Color3.fromRGB(255, 120, 160),
		Color3.fromRGB(255, 220, 90),
		Color3.fromRGB(180, 120, 255),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 90, 80),
	},
}

--==========================================================================
-- Part helpers
--==========================================================================

local ORDERED_KEYS = { Shape = true, Size = true, CFrame = true, Position = true, Parent = true }

local function newPart(className, props)
	local p = Instance.new(className)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	-- Shape must be applied before Size (Ball forces a uniform size), and
	-- Size before CFrame so the part is centered where requested.
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

-- Vertical cylinder (Roblox cylinders run along local X, so roll 90 degrees).
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

local function addSurfaceText(target, text, props)
	props = props or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = props.Face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0.3
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = props.Font or Enum.Font.FredokaOne
	label.TextColor3 = props.TextColor or C.signText
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	local pad = UDim.new(props.Padding or 0.08, 0)
	padding.PaddingTop = pad
	padding.PaddingBottom = pad
	padding.PaddingLeft = pad
	padding.PaddingRight = pad
	padding.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 25, 15)
	stroke.Transparency = 0.2
	stroke.Parent = label

	return gui, label
end

-- Wooden signpost; the board's front faces `facing`.
local function signPost(text, position, facing, parent)
	part({
		Name = "SignPost",
		Size = Vector3.new(0.6, 6, 0.6),
		Position = position + Vector3.new(0, 3, 0),
		Material = Enum.Material.Wood,
		Color = C.wood,
		Parent = parent,
	})
	local boardPos = position + Vector3.new(0, 5.2, 0)
	local board = part({
		Name = "SignBoard",
		Size = Vector3.new(6, 2, 0.4),
		CFrame = CFrame.lookAt(boardPos, boardPos + facing),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	addSurfaceText(board, text)
	addSurfaceText(board, text, { Face = Enum.NormalId.Back })
	return board
end

local function pointLight(parentPart, range, brightness, color)
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = color or C.warmLight
	light.Shadows = true
	light.Parent = parentPart
	return light
end

--==========================================================================
-- Lighting & atmosphere
--==========================================================================

local function setupLighting()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	Lighting.ClockTime = 15.3
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(70, 70, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 140)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(199, 220, 255)
	atmosphere.Decay = Color3.fromRGB(106, 140, 180)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = 0.15
	colorCorrection.Contrast = 0.08
	colorCorrection.Brightness = 0.02
	colorCorrection.TintColor = Color3.fromRGB(255, 250, 240)
	colorCorrection.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.06
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting

	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Terrain
end

--==========================================================================
-- Terrain island
--==========================================================================

local ISLAND_GRASS_RADIUS = 88
local ISLAND_SAND_RADIUS = 100

local function buildTerrain()
	Terrain:Clear()

	Terrain.WaterColor = Color3.fromRGB(40, 130, 160)
	Terrain.WaterTransparency = 0.6
	Terrain.WaterWaveSize = 0.15
	Terrain.WaterWaveSpeed = 8
	Terrain.WaterReflectance = 0.6
	Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(106, 160, 70))
	Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(222, 203, 155))
	Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(120, 118, 115))
	pcall(function()
		Terrain.Decoration = true
	end)

	-- Later fills overwrite earlier ones: sea, seabed, beach, then grass.
	Terrain:FillCylinder(CFrame.new(0, -8.75, 0), 14.5, 260, Enum.Material.Water)
	Terrain:FillCylinder(CFrame.new(0, -18, 0), 4, 260, Enum.Material.Sand)
	Terrain:FillCylinder(CFrame.new(0, -8.5, 0), 16, ISLAND_SAND_RADIUS, Enum.Material.Sand)
	Terrain:FillCylinder(CFrame.new(0, -8, 0), 16, ISLAND_GRASS_RADIUS, Enum.Material.Grass)

	-- Rocks scattered along the beach.
	for _, angle in ipairs({ 20, 55, 75, 130, 160, 200, 230, 250, 290, 320, 345 }) do
		local radians = math.rad(angle)
		local radius = rng:NextNumber(93, 99)
		local position = Vector3.new(math.cos(radians) * radius, -1, math.sin(radians) * radius)
		Terrain:FillBall(position, rng:NextNumber(2.5, 5), Enum.Material.Rock)
	end
end

--==========================================================================
-- Nature props
--==========================================================================

local function tree(position, scale, parent)
	scale = scale or 1
	local height = 7 * scale
	part({
		Name = "Trunk",
		Size = Vector3.new(1.6 * scale, height, 1.6 * scale),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0))
			* CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-4, 4))),
		Material = Enum.Material.Wood,
		Color = C.wood,
		Parent = parent,
	})

	local top = position + Vector3.new(0, height, 0)
	local blobs = {
		{ Vector3.new(0, 2 * scale, 0), 8 },
		{ Vector3.new(2.5 * scale, 0.5 * scale, 1.5 * scale), 6 },
		{ Vector3.new(-2.2 * scale, 0.8 * scale, -1.8 * scale), 6 },
		{ Vector3.new(0.5 * scale, 4 * scale, -0.5 * scale), 5 },
	}
	for _, blob in ipairs(blobs) do
		local size = blob[2] * scale * rng:NextNumber(0.9, 1.1)
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = top + blob[1],
			Material = Enum.Material.LeafyGrass,
			Color = C.leafGreens[rng:NextInteger(1, #C.leafGreens)],
			Parent = parent,
		})
	end
end

local function bush(position, parent)
	for _ = 1, 3 do
		local size = rng:NextNumber(2.2, 3.4)
		part({
			Name = "Bush",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = position + Vector3.new(rng:NextNumber(-1.2, 1.2), size * 0.35, rng:NextNumber(-1.2, 1.2)),
			Material = Enum.Material.LeafyGrass,
			Color = C.leafGreens[rng:NextInteger(1, #C.leafGreens)],
			Parent = parent,
		})
	end
end

local function flowerPlanter(position, facing, parent)
	local base = CFrame.lookAt(position, position + facing)
	part({
		Name = "Planter",
		Size = Vector3.new(6, 1.4, 3),
		CFrame = base * CFrame.new(0, 0.7, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	part({
		Name = "Soil",
		Size = Vector3.new(5.6, 0.2, 2.6),
		CFrame = base * CFrame.new(0, 1.45, 0),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(90, 65, 45),
		Parent = parent,
	})
	for _ = 1, 10 do
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.7, 0.7, 0.7),
			CFrame = base * CFrame.new(rng:NextNumber(-2.5, 2.5), 1.9, rng:NextNumber(-1, 1)),
			Color = C.flowers[rng:NextInteger(1, #C.flowers)],
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

local function lampPost(position, parent)
	part({
		Name = "LampBase",
		Size = Vector3.new(1.4, 1, 1.4),
		Position = position + Vector3.new(0, 0.5, 0),
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = parent,
	})
	cylinder(position + Vector3.new(0, 5, 0), 9, 0.3, {
		Name = "LampPole",
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = parent,
	})
	part({
		Name = "LampCap",
		Size = Vector3.new(1.8, 0.4, 1.8),
		Position = position + Vector3.new(0, 11.4, 0),
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = parent,
	})
	part({
		Name = "LampGlass",
		Size = Vector3.new(1.3, 1.6, 1.3),
		Position = position + Vector3.new(0, 10.4, 0),
		Material = Enum.Material.Glass,
		Color = C.warmLight,
		Transparency = 0.4,
		Parent = parent,
	})
	local bulb = part({
		Name = "LampBulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.7, 0.7, 0.7),
		Position = position + Vector3.new(0, 10.4, 0),
		Material = Enum.Material.Neon,
		Color = C.warmLight,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	pointLight(bulb, 18, 1.5)
end

local function bench(position, facing, parent)
	local base = CFrame.lookAt(position, position + facing)
	part({
		Name = "BenchSeat",
		Size = Vector3.new(5, 0.4, 1.6),
		CFrame = base * CFrame.new(0, 1.6, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	part({
		Name = "BenchBack",
		Size = Vector3.new(5, 1.4, 0.3),
		CFrame = base * CFrame.new(0, 2.6, 0.75) * CFrame.Angles(math.rad(-10), 0, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	for _, x in ipairs({ -2.1, 2.1 }) do
		part({
			Name = "BenchLeg",
			Size = Vector3.new(0.3, 1.6, 1.4),
			CFrame = base * CFrame.new(x, 0.8, 0),
			Material = Enum.Material.Metal,
			Color = C.darkMetal,
			Parent = parent,
		})
	end
end

--==========================================================================
-- Spawn plaza
--==========================================================================

local function buildFountain(parent)
	cylinder(Vector3.new(0, 1, 0), 2, 9, {
		Name = "FountainBasin",
		Material = Enum.Material.Slate,
		Color = C.stone,
		Parent = parent,
	})
	cylinder(Vector3.new(0, 2.05, 0), 0.2, 8, {
		Name = "FountainWater",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(70, 170, 220),
		Transparency = 0.3,
		Reflectance = 0.2,
		CanCollide = false,
		Parent = parent,
	})
	-- Raised lip around the basin.
	for i = 0, 15 do
		local angle = (i / 16) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 8.6, 2.4, math.sin(angle) * 8.6)
		part({
			Name = "FountainLip",
			Size = Vector3.new(1.2, 0.8, 3.6),
			CFrame = CFrame.lookAt(pos, Vector3.new(0, 2.4, 0)),
			Material = Enum.Material.Slate,
			Color = C.stone,
			Parent = parent,
		})
	end
	cylinder(Vector3.new(0, 4.5, 0), 5, 1.4, {
		Name = "FountainPillar",
		Material = Enum.Material.Marble,
		Color = C.cream,
		Parent = parent,
	})
	cylinder(Vector3.new(0, 7.2, 0), 0.8, 3.5, {
		Name = "FountainBowl",
		Material = Enum.Material.Marble,
		Color = C.cream,
		Parent = parent,
	})
	local spout = part({
		Name = "FountainSpout",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Position = Vector3.new(0, 8.2, 0),
		Material = Enum.Material.Marble,
		Color = C.cream,
		Parent = parent,
	})

	local spray = Instance.new("ParticleEmitter")
	spray.Rate = 80
	spray.Lifetime = NumberRange.new(0.9, 1.2)
	spray.Speed = NumberRange.new(14, 18)
	spray.SpreadAngle = Vector2.new(12, 12)
	spray.Acceleration = Vector3.new(0, -40, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	spray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	spray.Color = ColorSequence.new(Color3.fromRGB(205, 235, 255))
	spray.LightEmission = 0.3
	spray.Parent = spout
end

local function buildStall(position, awningColor, label, parent)
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	part({
		Name = "StallCounter",
		Size = Vector3.new(8, 3, 2),
		CFrame = base * CFrame.new(0, 1.5, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	for _, offset in ipairs({ Vector3.new(-3.8, 0, -0.8), Vector3.new(3.8, 0, -0.8), Vector3.new(-3.8, 0, 3), Vector3.new(3.8, 0, 3) }) do
		part({
			Name = "StallPole",
			Size = Vector3.new(0.4, 7, 0.4),
			CFrame = base * CFrame.new(offset.X, 3.5, offset.Z),
			Material = Enum.Material.Wood,
			Color = C.wood,
			Parent = parent,
		})
	end
	for i = 1, 5 do
		part({
			Name = "Awning",
			Size = Vector3.new(1.6, 0.25, 5.4),
			CFrame = base * CFrame.new(-4 + 0.8 + (i - 1) * 1.6, 7.1, 1.1) * CFrame.Angles(math.rad(12), 0, 0),
			Material = Enum.Material.Fabric,
			Color = (i % 2 == 1) and awningColor or C.cream,
			Parent = parent,
		})
	end
	for i = 1, 4 do
		part({
			Name = "Crate",
			Size = Vector3.new(1.4, 1.4, 1.4),
			CFrame = base * CFrame.new(-3 + i * 1.3, 3.7, 0.2) * CFrame.Angles(0, math.rad(rng:NextNumber(-15, 15)), 0),
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(185, 140, 90),
			Parent = parent,
		})
	end
	local sign = part({
		Name = "StallSign",
		Size = Vector3.new(6, 1.4, 0.3),
		CFrame = base * CFrame.new(0, 8.3, -1.4),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})
	addSurfaceText(sign, label)
end

local function buildLeaderboard(position, facing, parent)
	part({
		Name = "LeaderboardFrame",
		Size = Vector3.new(13, 10, 0.8),
		CFrame = CFrame.lookAt(position + Vector3.new(0, 6, 0), position + Vector3.new(0, 6, 0) + facing)
			* CFrame.new(0, 0, 0.45),
		Material = Enum.Material.WoodPlanks,
		Color = C.wood,
		Parent = parent,
	})
	for _, x in ipairs({ -5.5, 5.5 }) do
		part({
			Name = "LeaderboardLeg",
			Size = Vector3.new(0.8, 6, 0.8),
			CFrame = CFrame.lookAt(position, position + facing) * CFrame.new(x, 1, 0.3),
			Material = Enum.Material.Wood,
			Color = C.wood,
			Parent = parent,
		})
	end
	local boardCenter = position + Vector3.new(0, 6, 0)
	local board = part({
		Name = "LeaderboardScreen",
		Size = Vector3.new(12, 9, 0.2),
		CFrame = CFrame.lookAt(boardCenter, boardCenter + facing),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(35, 45, 40),
		Parent = parent,
	})

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Text = "TOP GUESSERS"
	title.Parent = gui

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Size = UDim2.fromScale(0.9, 0.78)
	list.Position = UDim2.fromScale(0.05, 0.19)
	list.BackgroundTransparency = 1
	list.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = list

	return list
end

local function refreshLeaderboard(list)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local entries = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local stats = plr:FindFirstChild("leaderstats")
		local score = stats and stats:FindFirstChild("Score")
		table.insert(entries, { name = plr.DisplayName, score = score and score.Value or 0 })
	end
	table.sort(entries, function(a, b)
		return a.score > b.score
	end)

	if #entries == 0 then
		entries = { { name = "Nobody yet!", score = 0 } }
	end

	for i = 1, math.min(8, #entries) do
		local row = Instance.new("TextLabel")
		row.LayoutOrder = i
		row.Size = UDim2.fromScale(1, 0.11)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(235, 235, 225)
		row.Text = string.format("%d.  %s   %d", i, entries[i].name, entries[i].score)
		row.Parent = list
	end
end

local function buildPlaza()
	local plaza = folder("Plaza")

	cylinder(Vector3.new(0, 0.1, 0), 0.8, 31, {
		Name = "PlazaBorder",
		Material = Enum.Material.Slate,
		Color = C.darkStone,
		Parent = plaza,
	})
	cylinder(Vector3.new(0, 0.1, 0), 1, 29, {
		Name = "PlazaFloor",
		Material = Enum.Material.Cobblestone,
		Color = C.cobble,
		Parent = plaza,
	})

	buildFountain(plaza)

	-- Spawn: an invisible SpawnLocation over a decorated pad, facing the stage.
	cylinder(Vector3.new(0, 0.7, -16), 0.4, 4.6, {
		Name = "SpawnRing",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 220, 255),
		Parent = plaza,
	})
	cylinder(Vector3.new(0, 0.75, -16), 0.4, 4, {
		Name = "SpawnPad",
		Material = Enum.Material.Marble,
		Color = C.cream,
		Parent = plaza,
	})
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "IslandSpawn"
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = CFrame.new(0, 1.5, -16) * CFrame.Angles(0, math.pi, 0)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.Transparency = 1
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = plaza

	for _, angle in ipairs({ 30, 60, 120, 150, 210, 240, 300, 330 }) do
		local radians = math.rad(angle)
		lampPost(Vector3.new(math.cos(radians) * 27, 0.6, math.sin(radians) * 27), plaza)
	end

	flowerPlanter(Vector3.new(15, 0.6, 15), Vector3.new(-1, 0, -1), plaza)
	flowerPlanter(Vector3.new(-15, 0.6, 15), Vector3.new(1, 0, -1), plaza)

	buildStall(Vector3.new(-18, 0.6, -18), Color3.fromRGB(200, 60, 60), "SNACKS", plaza)
	buildStall(Vector3.new(18, 0.6, -18), C.accentBlue, "FUN FACTS", plaza)

	bench(Vector3.new(-10, 0.6, -24), Vector3.new(0, 0, 1), plaza)
	bench(Vector3.new(10, 0.6, -24), Vector3.new(0, 0, 1), plaza)

	local leaderboardList = buildLeaderboard(Vector3.new(-22, 0.6, 6), Vector3.new(1, 0, 0), plaza)
	refreshLeaderboard(leaderboardList)
	task.spawn(function()
		while true do
			task.wait(3)
			refreshLeaderboard(leaderboardList)
		end
	end)

	local infoPos = Vector3.new(22, 0.6, 6)
	for _, x in ipairs({ -4.5, 4.5 }) do
		part({
			Name = "InfoLeg",
			Size = Vector3.new(0.6, 5, 0.6),
			CFrame = CFrame.lookAt(infoPos, infoPos + Vector3.new(-1, 0, 0)) * CFrame.new(x, 2.5, 0),
			Material = Enum.Material.Wood,
			Color = C.wood,
			Parent = plaza,
		})
	end
	local infoCenter = infoPos + Vector3.new(0, 6.5, 0)
	local info = part({
		Name = "InfoBoard",
		Size = Vector3.new(11, 6, 0.5),
		CFrame = CFrame.lookAt(infoCenter, infoCenter + Vector3.new(-1, 0, 0)),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = plaza,
	})
	addSurfaceText(
		info,
		"WELCOME TO SIZER ISLAND!\nNorth: Scale Stage (play here)\nEast: Obby  |  South: Lighthouse\nWest: Cottages",
		{ Padding = 0.06 }
	)
end

--==========================================================================
-- Paths
--==========================================================================

local function buildPaths()
	local paths = folder("Paths")

	-- North to the stage steps.
	part({
		Name = "PathNorth",
		Size = Vector3.new(10, 0.4, 30),
		Position = Vector3.new(0, 0.2, 43),
		Material = Enum.Material.Cobblestone,
		Color = C.cobble,
		Parent = paths,
	})
	-- East to the dock.
	part({
		Name = "PathEast",
		Size = Vector3.new(58, 0.4, 7),
		Position = Vector3.new(58, 0.2, 0),
		Material = Enum.Material.Cobblestone,
		Color = C.cobble,
		Parent = paths,
	})
	-- South to the lighthouse.
	part({
		Name = "PathSouth",
		Size = Vector3.new(6, 0.4, 42),
		Position = Vector3.new(0, 0.2, -50),
		Material = Enum.Material.Cobblestone,
		Color = C.cobble,
		Parent = paths,
	})
	-- West to the cottages.
	part({
		Name = "PathWest",
		Size = Vector3.new(44, 0.4, 7),
		Position = Vector3.new(-51, 0.2, 0),
		Material = Enum.Material.Cobblestone,
		Color = C.cobble,
		Parent = paths,
	})

	signPost("OBBY", Vector3.new(33, 0, 6), Vector3.new(-1, 0, 0), paths)
	signPost("LIGHTHOUSE", Vector3.new(6, 0, -33), Vector3.new(0, 0, 1), paths)
	signPost("COTTAGES", Vector3.new(-33, 0, -6), Vector3.new(1, 0, 0), paths)
end

--==========================================================================
-- Scale Stage (where the game is played)
--==========================================================================

local function buildStage()
	local arena = folder("ScaleGuesserArena")
	local center = MapConfig.ArenaCenter
	local stageTop = MapConfig.GroundY
	local stageFrontZ = center.Z - 14

	-- Archway over the path.
	for _, x in ipairs({ -7, 7 }) do
		part({
			Name = "ArchPillar",
			Size = Vector3.new(2.5, 12, 2.5),
			Position = Vector3.new(x, 6, 40),
			Material = Enum.Material.Brick,
			Color = C.brick,
			Parent = arena,
		})
		part({
			Name = "ArchPillarCap",
			Size = Vector3.new(3, 0.6, 3),
			Position = Vector3.new(x, 12.3, 40),
			Material = Enum.Material.Slate,
			Color = C.darkStone,
			Parent = arena,
		})
	end
	local beam = part({
		Name = "ArchBeam",
		Size = Vector3.new(18, 2.6, 1.6),
		CFrame = CFrame.lookAt(Vector3.new(0, 13.9, 40), Vector3.new(0, 13.9, 39)),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = arena,
	})
	addSurfaceText(beam, "SCALE STAGE", { Padding = 0.1 })

	-- Stage floor and skirt.
	part({
		Name = "StageFloor",
		Size = Vector3.new(44, stageTop, 28),
		Position = Vector3.new(center.X, stageTop / 2, center.Z),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(150, 100, 62),
		Parent = arena,
	})
	part({
		Name = "StageSkirt",
		Size = Vector3.new(44.2, stageTop - 0.4, 0.3),
		Position = Vector3.new(center.X, (stageTop - 0.4) / 2, stageFrontZ - 0.1),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(150, 35, 45),
		Parent = arena,
	})

	-- Front steps.
	for i = 1, 3 do
		part({
			Name = "StageStep" .. i,
			Size = Vector3.new(16, i, 2),
			Position = Vector3.new(center.X, i / 2, stageFrontZ - (3 - i) * 2 - 1),
			Material = Enum.Material.Slate,
			Color = C.stone,
			Parent = arena,
		})
	end

	-- Backdrop with height markers (each line = 1x the reference height).
	local backdropHeight = 26
	local backdropCenter = Vector3.new(center.X, stageTop + backdropHeight / 2, center.Z + 14.5)
	local backdrop = part({
		Name = "Backdrop",
		Size = Vector3.new(50, backdropHeight, 1),
		CFrame = CFrame.lookAt(backdropCenter, backdropCenter + Vector3.new(0, 0, -1)),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(35, 50, 90),
		Parent = arena,
	})
	local backdropGui = Instance.new("SurfaceGui")
	backdropGui.Face = Enum.NormalId.Front
	backdropGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	backdropGui.PixelsPerStud = 25
	backdropGui.LightInfluence = 0.2
	backdropGui.Parent = backdrop

	local backdropTitle = Instance.new("TextLabel")
	backdropTitle.Size = UDim2.fromScale(0.8, 0.14)
	backdropTitle.Position = UDim2.fromScale(0.1, 0.03)
	backdropTitle.BackgroundTransparency = 1
	backdropTitle.Font = Enum.Font.FredokaOne
	backdropTitle.TextScaled = true
	backdropTitle.TextColor3 = Color3.fromRGB(255, 215, 90)
	backdropTitle.Text = "HOW BIG IS IT REALLY?"
	backdropTitle.Parent = backdropGui

	local REFERENCE_STUDS = 6
	for k = 1, 3 do
		local yScale = 1 - (REFERENCE_STUDS * k) / backdropHeight
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0.86, 0, 0, 4)
		line.Position = UDim2.fromScale(0.1, yScale)
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BackgroundTransparency = 0.6
		line.BorderSizePixel = 0
		line.Parent = backdropGui

		local tag = Instance.new("TextLabel")
		tag.Size = UDim2.fromScale(0.08, 0.07)
		tag.Position = UDim2.fromScale(0.015, yScale - 0.035)
		tag.BackgroundTransparency = 1
		tag.Font = Enum.Font.FredokaOne
		tag.TextScaled = true
		tag.TextColor3 = Color3.fromRGB(255, 255, 255)
		tag.Text = k .. "x"
		tag.Parent = backdropGui
	end

	-- Backdrop side pillars.
	for _, x in ipairs({ -25.5, 25.5 }) do
		part({
			Name = "BackdropPillar",
			Size = Vector3.new(2, backdropHeight + 2, 2),
			Position = Vector3.new(x, stageTop + (backdropHeight + 2) / 2, center.Z + 14.5),
			Material = Enum.Material.Brick,
			Color = C.brick,
			Parent = arena,
		})
	end

	-- Spotlight towers aimed at the display area.
	local aimPoint = Vector3.new(center.X, stageTop + 6, center.Z + 10)
	for _, x in ipairs({ -25, 25 }) do
		local base = Vector3.new(x, 0, stageFrontZ - 2)
		part({
			Name = "SpotTowerBase",
			Size = Vector3.new(2, 1, 2),
			Position = base + Vector3.new(0, 0.5, 0),
			Material = Enum.Material.DiamondPlate,
			Color = C.darkMetal,
			Parent = arena,
		})
		part({
			Name = "SpotTowerPole",
			Size = Vector3.new(0.8, 16, 0.8),
			Position = base + Vector3.new(0, 8, 0),
			Material = Enum.Material.Metal,
			Color = C.darkMetal,
			Parent = arena,
		})
		local headPos = base + Vector3.new(0, 16.5, 0)
		local head = part({
			Name = "SpotHead",
			Size = Vector3.new(2, 2, 3),
			CFrame = CFrame.lookAt(headPos, aimPoint),
			Material = Enum.Material.Metal,
			Color = C.darkMetal,
			Parent = arena,
		})
		local lens = part({
			Name = "SpotLens",
			Size = Vector3.new(1.6, 1.6, 0.2),
			CFrame = head.CFrame * CFrame.new(0, 0, -1.55),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 240, 210),
			CanCollide = false,
			Parent = arena,
		})
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Range = 60
		spot.Angle = 45
		spot.Brightness = 3
		spot.Color = Color3.fromRGB(255, 240, 210)
		spot.Parent = lens
	end

	-- Side bleachers facing the stage.
	for _, x in ipairs({ -34, 34 }) do
		local origin = Vector3.new(x, 0, center.Z - 3)
		local base = CFrame.lookAt(origin, Vector3.new(center.X, 0, center.Z - 3))
		for tier = 1, 3 do
			part({
				Name = "BleacherTier" .. tier,
				Size = Vector3.new(14, 1.2 * tier, 2.5),
				CFrame = base * CFrame.new(0, 0.6 * tier, 2.5 * (tier - 1)),
				Material = tier % 2 == 1 and Enum.Material.WoodPlanks or Enum.Material.Wood,
				Color = tier % 2 == 1 and C.planks or C.wood,
				Parent = arena,
			})
		end
	end

	-- Start kiosk (name and ProximityPrompt are what the client looks for).
	local kioskPos = Vector3.new(center.X, stageTop + 2, stageFrontZ + 4)
	local kiosk = part({
		Name = "Kiosk",
		Size = Vector3.new(3, 4, 1.5),
		CFrame = CFrame.lookAt(kioskPos, kioskPos + Vector3.new(0, 0, -1)),
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = arena,
	})
	local screen = part({
		Name = "KioskScreen",
		Size = Vector3.new(2.4, 1.6, 0.1),
		CFrame = kiosk.CFrame * CFrame.new(0, 0.9, -0.8),
		Material = Enum.Material.Neon,
		Color = C.accentOrange,
		CanCollide = false,
		Parent = arena,
	})
	addSurfaceText(screen, "PLAY", { TextColor = Color3.fromRGB(255, 255, 255), Padding = 0.12 })
	pointLight(screen, 10, 1, C.accentOrange)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ProximityPrompt"
	prompt.ActionText = "Start Game"
	prompt.ObjectText = "Scale Guesser"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = kiosk

	-- Hedges flanking the stage approach.
	for _, x in ipairs({ -12, 12 }) do
		for z = 30, 56, 4 do
			bush(Vector3.new(x, 0, z), arena)
		end
	end
end

--==========================================================================
-- Cottage lane (west)
--==========================================================================

local function cottage(position, facing, wallColor, roofColor, parent)
	local W, D, H, ROOF_H = 16, 14, 10, 6
	local base = CFrame.lookAt(position, position + facing)
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	local wall = { Material = Enum.Material.Plaster, Color = wallColor }

	local function wallPart(name, size, cf)
		return part({ Name = name, Size = size, CFrame = cf, Material = wall.Material, Color = wall.Color, Parent = parent })
	end

	part({
		Name = "CottageFloor",
		Size = Vector3.new(W, 1, D),
		CFrame = at(0, 0.5, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = parent,
	})

	wallPart("BackWall", Vector3.new(W, H, 1), at(0, 1 + H / 2, D / 2 - 0.5))
	for _, side in ipairs({ -1, 1 }) do
		wallPart("SideWall", Vector3.new(1, H, D), at(side * (W / 2 - 0.5), 1 + H / 2, 0))
		part({
			Name = "Window",
			Size = Vector3.new(1.2, 3.5, 4.5),
			CFrame = at(side * (W / 2 - 0.5), 1 + 5.5, 0),
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(170, 210, 230),
			Transparency = 0.35,
			Parent = parent,
		})
		part({
			Name = "WindowSill",
			Size = Vector3.new(1.6, 0.3, 5.2),
			CFrame = at(side * (W / 2 - 0.5), 1 + 3.6, 0),
			Material = Enum.Material.WoodPlanks,
			Color = C.wood,
			Parent = parent,
		})
	end

	local DOOR_W, DOOR_H = 5, 7
	local sideW = (W - DOOR_W) / 2
	for _, side in ipairs({ -1, 1 }) do
		wallPart("FrontWall", Vector3.new(sideW, H, 1), at(side * (DOOR_W / 2 + sideW / 2), 1 + H / 2, -D / 2 + 0.5))
	end
	wallPart("Lintel", Vector3.new(DOOR_W, H - DOOR_H, 1), at(0, 1 + DOOR_H + (H - DOOR_H) / 2, -D / 2 + 0.5))
	part({
		Name = "DoorFrame",
		Size = Vector3.new(DOOR_W + 1, 0.6, 1.3),
		CFrame = at(0, 1 + DOOR_H + 0.3, -D / 2 + 0.5),
		Material = Enum.Material.WoodPlanks,
		Color = C.wood,
		Parent = parent,
	})

	-- Gable roof: two wedges meeting at a ridge along local X.
	local roofDepth = D / 2 + 1
	newPart("WedgePart", {
		Name = "RoofFront",
		Size = Vector3.new(W + 2, ROOF_H, roofDepth),
		CFrame = at(0, 1 + H + ROOF_H / 2, -roofDepth / 2),
		Material = Enum.Material.ClayRoofTiles,
		Color = roofColor,
		Parent = parent,
	})
	newPart("WedgePart", {
		Name = "RoofBack",
		Size = Vector3.new(W + 2, ROOF_H, roofDepth),
		CFrame = at(0, 1 + H + ROOF_H / 2, roofDepth / 2) * CFrame.Angles(0, math.pi, 0),
		Material = Enum.Material.ClayRoofTiles,
		Color = roofColor,
		Parent = parent,
	})
	for _, side in ipairs({ -1, 1 }) do
		newPart("WedgePart", {
			Name = "GableFront",
			Size = Vector3.new(1, ROOF_H, D / 2),
			CFrame = at(side * (W / 2 - 0.5), 1 + H + ROOF_H / 2, -D / 4),
			Material = wall.Material,
			Color = wall.Color,
			Parent = parent,
		})
		newPart("WedgePart", {
			Name = "GableBack",
			Size = Vector3.new(1, ROOF_H, D / 2),
			CFrame = at(side * (W / 2 - 0.5), 1 + H + ROOF_H / 2, D / 4) * CFrame.Angles(0, math.pi, 0),
			Material = wall.Material,
			Color = wall.Color,
			Parent = parent,
		})
	end

	part({
		Name = "Chimney",
		Size = Vector3.new(2, 6, 2),
		CFrame = at(W / 4, 1 + H + ROOF_H - 1.5, D / 4),
		Material = Enum.Material.Brick,
		Color = C.brick,
		Parent = parent,
	})

	local doorLamp = part({
		Name = "DoorLamp",
		Size = Vector3.new(0.6, 0.9, 0.6),
		CFrame = at(DOOR_W / 2 + 1, 1 + DOOR_H, -D / 2 - 0.3),
		Material = Enum.Material.Neon,
		Color = C.warmLight,
		CanCollide = false,
		Parent = parent,
	})
	pointLight(doorLamp, 12, 1)

	bush(at(-W / 2 + 1.5, 0, -D / 2 - 2).Position, parent)
	bush(at(W / 2 - 1.5, 0, -D / 2 - 2).Position, parent)
end

local function buildCottages()
	local lane = folder("Cottages")
	cottage(Vector3.new(-58, 0, 20), Vector3.new(0, 0, -1), Color3.fromRGB(235, 225, 200), C.roofRed, lane)
	cottage(Vector3.new(-58, 0, -20), Vector3.new(0, 0, 1), Color3.fromRGB(215, 230, 235), C.roofBlue, lane)

	-- Door paths off the main lane.
	for _, z in ipairs({ 8.25, -8.25 }) do
		part({
			Name = "DoorPath",
			Size = Vector3.new(4, 0.4, 9.5),
			Position = Vector3.new(-58, 0.2, z),
			Material = Enum.Material.Cobblestone,
			Color = C.cobble,
			Parent = lane,
		})
	end

	lampPost(Vector3.new(-44, 0, 5), lane)
	lampPost(Vector3.new(-72, 0, -5), lane)
	bench(Vector3.new(-76, 0, 6), Vector3.new(1, 0, 0), lane)
end

--==========================================================================
-- Lighthouse (south, climbable)
--==========================================================================

local function buildLighthouse()
	local lh = folder("Lighthouse")
	local base = Vector3.new(0, 0, -80)

	cylinder(base + Vector3.new(0, 1, 0), 2, 9, {
		Name = "LighthouseBase",
		Material = Enum.Material.Slate,
		Color = C.darkStone,
		Parent = lh,
	})
	for i = 0, 5 do
		cylinder(base + Vector3.new(0, 2 + 2.5 + i * 5, 0), 5, 6 - i * 0.25, {
			Name = "LighthouseStripe",
			Material = Enum.Material.Plaster,
			Color = (i % 2 == 0) and Color3.fromRGB(240, 240, 235) or Color3.fromRGB(200, 50, 45),
			Parent = lh,
		})
	end
	local galleryY = 32.5
	cylinder(base + Vector3.new(0, galleryY, 0), 1, 9, {
		Name = "Gallery",
		Material = Enum.Material.DiamondPlate,
		Color = C.darkMetal,
		Parent = lh,
	})
	-- Railing posts around the gallery, with a gap where the truss arrives.
	for i = 0, 19 do
		local angle = (i / 20) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		if dir.Z < 0.9 then
			part({
				Name = "RailPost",
				Size = Vector3.new(0.3, 2.5, 0.3),
				Position = base + dir * 8.6 + Vector3.new(0, galleryY + 1.75, 0),
				Material = Enum.Material.Metal,
				Color = C.darkMetal,
				Parent = lh,
			})
		end
	end
	cylinder(base + Vector3.new(0, galleryY + 3.5, 0), 6, 4.2, {
		Name = "LanternGlass",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(255, 240, 200),
		Transparency = 0.5,
		Parent = lh,
	})
	part({
		Name = "LanternDome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 9, 9),
		Position = base + Vector3.new(0, galleryY + 6.8, 0),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(200, 50, 45),
		Parent = lh,
	})

	local beacon = part({
		Name = "Beacon",
		Size = Vector3.new(1.6, 1.6, 1.6),
		Position = base + Vector3.new(0, galleryY + 3.5, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 230, 150),
		CanCollide = false,
		Parent = lh,
	})
	pointLight(beacon, 30, 2, Color3.fromRGB(255, 230, 150))
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local beam = Instance.new("SpotLight")
		beam.Face = face
		beam.Range = 60
		beam.Angle = 25
		beam.Brightness = 4
		beam.Color = Color3.fromRGB(255, 235, 170)
		beam.Parent = beacon
	end
	TweenService:Create(
		beacon,
		TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
		{ Orientation = Vector3.new(0, 360, 0) }
	):Play()

	-- Climbable truss up the island-facing side.
	newPart("TrussPart", {
		Name = "LighthouseTruss",
		Size = Vector3.new(2, 34, 2),
		Position = base + Vector3.new(0, 17, 9.5),
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = lh,
	})
	signPost("CLIMB ME!", base + Vector3.new(5, 0, 13), Vector3.new(0, 0, 1), lh)
end

--==========================================================================
-- Playground (trampolines) & beach props
--==========================================================================

local function buildPlayground()
	local playground = folder("Playground")
	for _, pos in ipairs({ Vector3.new(42, 0, 30), Vector3.new(54, 0, 42), Vector3.new(40, 0, 50) }) do
		cylinder(pos + Vector3.new(0, 0.8, 0), 1.6, 4.6, {
			Name = "TrampolineFrame",
			Material = Enum.Material.Metal,
			Color = C.accentBlue,
			Parent = playground,
		})
		local bounce = cylinder(pos + Vector3.new(0, 1.65, 0), 0.2, 4, {
			Name = "TrampolineMat",
			Material = Enum.Material.Fabric,
			Color = Color3.fromRGB(30, 30, 35),
			Parent = playground,
		})
		CollectionService:AddTag(bounce, "Trampoline")
	end
	signPost("BOUNCE!", Vector3.new(34, 0, 22), Vector3.new(-1, 0, -1), playground)
end

local function buildBeach()
	local beach = folder("Beach")
	local umbrellaColors = { Color3.fromRGB(230, 70, 70), Color3.fromRGB(70, 150, 230), Color3.fromRGB(250, 200, 60) }
	for i, pos in ipairs({ Vector3.new(55, -0.5, -76), Vector3.new(71, -0.5, -60), Vector3.new(-62, -0.5, -72) }) do
		cylinder(pos + Vector3.new(0, 3.5, 0), 7, 0.2, {
			Name = "UmbrellaPole",
			Material = Enum.Material.Wood,
			Color = C.cream,
			Parent = beach,
		})
		cylinder(pos + Vector3.new(0, 7, 0), 0.4, 4, {
			Name = "UmbrellaCanopy",
			Material = Enum.Material.Fabric,
			Color = umbrellaColors[i],
			Parent = beach,
		})
		part({
			Name = "Towel",
			Size = Vector3.new(3, 0.1, 6),
			CFrame = CFrame.new(pos + Vector3.new(2.5, 0.05, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), 0),
			Material = Enum.Material.Fabric,
			Color = umbrellaColors[(i % #umbrellaColors) + 1],
			Parent = beach,
		})
	end
end

local function buildTrees()
	local nature = folder("Nature")
	local spots = {
		{ 62, 15 }, { 68, -22 }, { 60, -50 }, { 42, -34 }, { 24, -50 }, { 36, -68 },
		{ -24, -74 }, { -30, -55 }, { -50, -60 }, { -70, -42 }, { -80, 8 },
		{ -72, 40 }, { -45, 48 }, { -30, 50 }, { -55, 58 }, { 24, 54 }, { 56, 62 }, { 68, 42 },
		{ 18, -62 }, { -40, 30 },
	}
	for _, spot in ipairs(spots) do
		tree(Vector3.new(spot[1], 0, spot[2]), rng:NextNumber(0.85, 1.25), nature)
	end

	-- Keep random bushes off the paths, stage, and lighthouse.
	local function isClear(x, z)
		if math.abs(z) < 7 then
			return false
		end
		if math.abs(x) < 28 and z > 55 then
			return false
		end
		if math.abs(x) < 14 and z < -55 then
			return false
		end
		return true
	end
	local placed = 0
	while placed < 18 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(70, 84)
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		if isClear(x, z) then
			bush(Vector3.new(x, 0, z), nature)
			placed += 1
		end
	end
end

--==========================================================================
-- Obby over the water (east)
--==========================================================================

local function buildObby()
	local obby = folder("Obby")

	-- Dock from the end of the east path out over the water.
	part({
		Name = "Dock",
		Size = Vector3.new(28, 1, 8),
		Position = Vector3.new(100, 0, 0),
		Material = Enum.Material.WoodPlanks,
		Color = C.planks,
		Parent = obby,
	})
	for x = 88, 112, 6 do
		for _, z in ipairs({ -3.6, 3.6 }) do
			cylinder(Vector3.new(x, -3, z), 6, 0.45, {
				Name = "DockPost",
				Material = Enum.Material.Wood,
				Color = C.wood,
				Parent = obby,
			})
		end
	end
	signPost("OBBY START", Vector3.new(110, 0.5, 3.4), Vector3.new(-1, 0, 0), obby)

	local P = Enum.Material
	local steps = {
		{ Vector3.new(119, 1, 0), Vector3.new(6, 1, 6), P.WoodPlanks, C.planks },
		{ Vector3.new(127, 2, 3), Vector3.new(5, 1, 5), P.WoodPlanks, C.planks },
		{ Vector3.new(135, 3, -2), Vector3.new(5, 1, 5), P.Slate, C.stone },
		{ Vector3.new(143, 4.5, 2), Vector3.new(4, 1, 4), P.Slate, C.stone },
		{ Vector3.new(150, 5, 4), Vector3.new(6, 1, 6), P.Neon, Color3.fromRGB(255, 90, 90), moving = Vector3.new(150, 5, 16) },
		{ Vector3.new(151, 6, 24), Vector3.new(5, 1, 5), P.Ice, Color3.fromRGB(175, 220, 255) },
		{ Vector3.new(146, 7, 33), Vector3.new(2, 1, 10), P.WoodPlanks, C.planks },
		{ Vector3.new(146, 8, 44), Vector3.new(6, 1, 6), P.Slate, C.stone },
		{ Vector3.new(146, 20, 52), Vector3.new(6, 1, 6), P.WoodPlanks, C.planks },
		{ Vector3.new(138, 20.5, 60), Vector3.new(4, 1, 4), P.Ice, Color3.fromRGB(175, 220, 255) },
		{ Vector3.new(129, 21, 66), Vector3.new(4, 1, 4), P.Slate, C.stone },
		{ Vector3.new(120, 21.5, 71), Vector3.new(3, 1, 3), P.Neon, Color3.fromRGB(255, 120, 200) },
	}
	for i, step in ipairs(steps) do
		local platform = part({
			Name = "ObbyStep" .. i,
			Size = step[2],
			Position = step[1],
			Material = step[3],
			Color = step[4],
			Parent = obby,
		})
		if step.moving then
			TweenService:Create(
				platform,
				TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = step.moving }
			):Play()
		end
	end

	newPart("TrussPart", {
		Name = "ObbyTruss",
		Size = Vector3.new(2, 12, 2),
		Position = Vector3.new(146, 14.5, 48),
		Material = Enum.Material.Metal,
		Color = C.darkMetal,
		Parent = obby,
	})

	-- Finish island with a trophy.
	local finishCenter = Vector3.new(106, 18, 78)
	part({
		Name = "FinishRock",
		Size = Vector3.new(18, 8, 18),
		Position = finishCenter,
		Material = Enum.Material.Rock,
		Color = Color3.fromRGB(115, 110, 105),
		Parent = obby,
	})
	part({
		Name = "FinishGrass",
		Size = Vector3.new(17, 1, 17),
		Position = finishCenter + Vector3.new(0, 4, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(106, 160, 70),
		Parent = obby,
	})
	local trophyBase = finishCenter + Vector3.new(0, 4.5, 2)
	part({
		Name = "TrophyPedestal",
		Size = Vector3.new(3, 3, 3),
		Position = trophyBase + Vector3.new(0, 1.5, 0),
		Material = Enum.Material.Marble,
		Color = C.cream,
		Parent = obby,
	})
	local cup = cylinder(trophyBase + Vector3.new(0, 4.6, 0), 3, 1.1, {
		Name = "TrophyCup",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(240, 190, 60),
		Reflectance = 0.3,
		Parent = obby,
	})
	pointLight(cup, 16, 2, Color3.fromRGB(255, 210, 90))
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Rate = 12
	sparkle.Lifetime = NumberRange.new(1, 1.6)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.4)
	sparkle.Parent = cup

	signPost("YOU MADE IT!", finishCenter + Vector3.new(-5, 4.5, -5), Vector3.new(1, 0, -1), obby)
	tree(finishCenter + Vector3.new(5, 4.5, 5), 0.8, obby)
end

--==========================================================================
-- Build everything
--==========================================================================

setupLighting()
buildTerrain()
buildPlaza()
buildPaths()
buildStage()
buildCottages()
buildLighthouse()
buildPlayground()
buildBeach()
buildTrees()
buildObby()
