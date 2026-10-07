--[[
	MapBuilder.server.lua
	Script: ServerScriptService.MapBuilder

	Builds the lobby at server start: a flat floating grass platform with
	checker-tile paths, a fence, blocky trees, category game stations, a
	leaderboard wall, trampolines, and a short obby off the east edge.

	Stations live in workspace.Map.Stations. Each station folder carries
	attributes the client reads (Category, DisplayName, Color) and contains
	a Podium (with ProximityPrompt), a DisplayOrigin part, and an Approach
	part used by Quick Play.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local rng = Random.new(425)

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

local HALF_X, HALF_Z = 55, 75
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
	for _ = 1, 10 do
		local size = rng:NextNumber(10, 20)
		part({
			Name = "UnderRock",
			Size = Vector3.new(size, size * 0.8, size),
			CFrame = CFrame.new(rng:NextNumber(-35, 35), -14 - rng:NextNumber(0, 6), rng:NextNumber(-55, 55))
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
		return x > HALF_X - 1 and z > -55 and z < -45
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

local function buildDecor()
	local decor = folder("Decor")
	local trees = {
		{ -42, -64 }, { 42, -66 }, { -46, -18 }, { 44, -22 }, { -44, 18 }, { 46, 14 },
		{ -42, 50 }, { 44, 52 }, { -24, 66 }, { 26, 67 }, { -36, -42 }, { 38, 34 },
	}
	for _, t in ipairs(trees) do
		blockyTree(Vector3.new(t[1], 0, t[2]), rng:NextNumber(0.9, 1.2), decor)
	end
	for _, f in ipairs({ { -32, -2 }, { 34, -6 }, { -34, 44 }, { 32, 48 }, { 18, -64 }, { -18, -66 } }) do
		flowerPatch(Vector3.new(f[1], 0, f[2]), decor)
	end
	bench(Vector3.new(-12, TILE_TOP, -62), Vector3.new(0, 0, 1), decor)
	bench(Vector3.new(12, TILE_TOP, -62), Vector3.new(0, 0, 1), decor)
end

--==========================================================================
-- Paths & spawn
--==========================================================================

local function buildPaths()
	local paths = folder("Paths")
	checker("SpawnPlaza", -15, 15, -65, -40, nil, paths)
	checker("MainPath", -5, 5, -40, 50, nil, paths)
	checker("NorthPlaza", -25, 25, 50, 65, nil, paths)

	cylinder(Vector3.new(0, TILE_TOP + 0.1, -52), 0.2, 5, {
		Name = "SpawnRing",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(90, 200, 255),
		Parent = paths,
	})
	cylinder(Vector3.new(0, TILE_TOP + 0.15, -52), 0.2, 4.2, {
		Name = "SpawnPad",
		Color = C.white,
		Parent = paths,
	})
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = CFrame.new(0, 1, -52) * CFrame.Angles(0, math.pi, 0)
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
	{ category = "Animals", label = "ANIMALS", color = Color3.fromRGB(255, 140, 40), pos = Vector3.new(-15, 0, 32) },
	{ category = "Landmarks", label = "LANDMARKS", color = Color3.fromRGB(60, 150, 255), pos = Vector3.new(15, 0, 32) },
	{ category = "Everyday Objects", label = "EVERYDAY", color = Color3.fromRGB(255, 85, 155), pos = Vector3.new(-15, 0, 2) },
	{ category = "Space", label = "SPACE", color = Color3.fromRGB(150, 95, 255), pos = Vector3.new(15, 0, 2) },
	{ category = "", label = "MIXED", color = Color3.fromRGB(255, 200, 40), pos = Vector3.new(-15, 0, -28) },
	{ category = "", label = "MIXED", color = Color3.fromRGB(30, 200, 200), pos = Vector3.new(15, 0, -28) },
}

local function buildStation(def, index, parent)
	local station = folder("Station" .. index, parent)
	station:SetAttribute("Category", def.category)
	station:SetAttribute("DisplayName", def.label)
	station:SetAttribute("Color", def.color)

	local center = def.pos
	-- Station faces the main path (x = 0).
	local facing = Vector3.new(-math.sign(center.X), 0, 0)
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

	-- Where the reference/target parts stand (client places them here).
	part({
		Name = "DisplayOrigin",
		Size = Vector3.new(1, 0.2, 1),
		CFrame = at(0, TILE_TOP, 3),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = station,
	})

	-- Where Quick Play drops the player, looking at the podium.
	local approachPos = at(0, 3, -9).Position
	part({
		Name = "Approach",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.lookAt(approachPos, Vector3.new(center.X, approachPos.Y, center.Z)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = station,
	})

	-- Back panel with 1x / 2x height marks (reference is 6 studs tall).
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
	for k = 1, 2 do
		local yScale = 1 - (6 * k) / panelHeight
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0.84, 0, 0, 4)
		line.Position = UDim2.fromScale(0.13, yScale)
		line.BackgroundColor3 = def.color
		line.BorderSizePixel = 0
		line.Parent = panelGui
		textLabel(panelGui, {
			Size = UDim2.fromScale(0.11, 0.1),
			Position = UDim2.fromScale(0.01, yScale - 0.05),
			Text = k .. "x",
			TextColor3 = C.dark,
		})
	end

	-- Floating world-scaled title above the station.
	local labelAnchor = part({
		Name = "LabelAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = at(0, TILE_TOP + panelHeight + 4, 8),
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
		Text = "SOLO",
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
	for i = 1, math.min(8, #entries) do
		textLabel(list, {
			LayoutOrder = i,
			Size = UDim2.fromScale(1, 0.115),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = (i == 1 and Color3.fromRGB(255, 210, 70))
				or (i == 2 and Color3.fromRGB(210, 220, 235))
				or (i == 3 and Color3.fromRGB(230, 150, 90))
				or C.white,
			Text = string.format("%d.  %s  -  %d", i, entries[i].name, entries[i].score),
		})
	end
end

local function buildBoards()
	local boards = folder("Boards")
	local lookTarget = Vector3.new(0, 0, 20)

	local main = darkBoard("Leaderboard", Vector3.new(0, TILE_TOP, 62), lookTarget, Vector3.new(16, 11, 0.2), boards)
	local gui = surfaceGui(main, 40)
	stroke(textLabel(gui, {
		Size = UDim2.fromScale(1, 0.16),
		Text = "🏆 TOP GUESSERS",
		TextColor3 = Color3.fromRGB(255, 210, 70),
	}), 3)
	local list = Instance.new("Frame")
	list.Size = UDim2.fromScale(0.86, 0.78)
	list.Position = UDim2.fromScale(0.07, 0.19)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.008, 0)
	layout.Parent = list
	refreshLeaderboard(list)
	task.spawn(function()
		while true do
			task.wait(3)
			refreshLeaderboard(list)
		end
	end)

	local howTo = darkBoard("HowTo", Vector3.new(-19, TILE_TOP, 58), lookTarget, Vector3.new(13, 9, 0.2), boards)
	stroke(textLabel(surfaceGui(howTo, 40), {
		Size = UDim2.fromScale(0.9, 0.9),
		Position = UDim2.fromScale(0.05, 0.05),
		Text = "HOW TO PLAY\n\nWalk up to a station & press E.\nDrag the slider to guess the size.\nLock in to score up to 100!",
		TextColor3 = Color3.fromRGB(120, 220, 255),
	}), 2)

	local tips = darkBoard("Tips", Vector3.new(19, TILE_TOP, 58), lookTarget, Vector3.new(13, 9, 0.2), boards)
	stroke(textLabel(surfaceGui(tips, 40), {
		Size = UDim2.fromScale(0.9, 0.9),
		Position = UDim2.fromScale(0.05, 0.05),
		Text = "TIPS\n\nThe lines on each station show 1x and 2x the reference.\nEarn coins for every guess!",
		TextColor3 = Color3.fromRGB(255, 170, 90),
	}), 2)
end

--==========================================================================
-- Trampolines & obby
--==========================================================================

local function buildTrampolines()
	local playground = folder("Playground")
	for _, pos in ipairs({ Vector3.new(-36, 0, -54), Vector3.new(-36, 0, -28), Vector3.new(36, 0, -38) }) do
		cylinder(pos + Vector3.new(0, 0.8, 0), 1.6, 4.6, {
			Name = "TrampolineFrame",
			Color = Color3.fromRGB(60, 140, 255),
			Parent = playground,
		})
		local mat = cylinder(pos + Vector3.new(0, 1.65, 0), 0.2, 4, {
			Name = "TrampolineMat",
			Color = C.dark,
			Parent = playground,
		})
		CollectionService:AddTag(mat, "Trampoline")
	end
end

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
			Position = step[1],
			Color = colors[(i - 1) % #colors + 1],
			Parent = obby,
		})
		if step.moving then
			platform.Material = Enum.Material.Neon
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
		Position = Vector3.new(85, 14.5, 4),
		Color = C.dark,
		Parent = obby,
	})

	local finish = part({
		Name = "ObbyFinish",
		Size = Vector3.new(12, 1, 12),
		Position = Vector3.new(66, 22, 38),
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
		Position = Vector3.new(52, 7, -50),
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

setupLighting()
buildGround()
buildFence()
buildPaths()
buildStations()
buildBoards()
buildDecor()
buildTrampolines()
buildObby()
