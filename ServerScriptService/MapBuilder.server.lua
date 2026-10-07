--[[
	MapBuilder.server.lua
	Script: ServerScriptService.MapBuilder

	Procedurally builds the whole walkable map on server start: a central
	hub (spawn), a signed path leading to the Scale Guesser arena (with a
	ProximityPrompt kiosk that starts the game), a parkour course, and a
	plaza area with light decoration/light parkour for players who are
	just wandering.

	Everything here is built from basic Parts so it needs no imported
	models or Studio hand-placement -- running the server builds the map.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

local mapFolder = Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder.Parent = workspace

--==========================================================================
-- Generic helpers
--==========================================================================

local function createPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = props.Parent or mapFolder
	return part
end

-- Freestanding sign: a thin pole with a BillboardGui label on top, used to
-- mark zones from a distance.
local function createSign(text, position, color, parent)
	local pole = createPart({
		Name = "Sign_" .. text,
		Size = Vector3.new(1, 8, 1),
		Position = position + Vector3.new(0, 4, 0),
		Color = color or Color3.fromRGB(255, 255, 255),
		Parent = parent,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pole

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = billboard

	return pole
end

-- A straight, axis-aligned walkway between two points (only one of X/Z
-- differs between the points, which is true for every path in this map).
local function buildStraightPath(name, fromPoint, toPoint, width, color, parent)
	local center = (fromPoint + toPoint) / 2
	local length = (toPoint - fromPoint).Magnitude

	local sizeX = math.abs(toPoint.X - fromPoint.X) > 0 and length or width
	local sizeZ = math.abs(toPoint.Z - fromPoint.Z) > 0 and length or width

	createPart({
		Name = name,
		Size = Vector3.new(sizeX, 1, sizeZ),
		Position = Vector3.new(center.X, MapConfig.GroundY - 0.5, center.Z),
		Color = color,
		Parent = parent,
	})
end

--==========================================================================
-- Hub (spawn area)
--==========================================================================

local function buildHub()
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"
	hubFolder.Parent = mapFolder

	createPart({
		Name = "HubPlatform",
		Size = Vector3.new(MapConfig.HubRadius * 2, 2, MapConfig.HubRadius * 2),
		Position = Vector3.new(MapConfig.HubCenter.X, 0, MapConfig.HubCenter.Z),
		Color = Color3.fromRGB(180, 180, 190),
		Parent = hubFolder,
	})

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "HubSpawn"
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.Position = Vector3.new(MapConfig.HubCenter.X, MapConfig.GroundY + 0.5, MapConfig.HubCenter.Z)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Neutral = true
	spawnLocation.Color = Color3.fromRGB(80, 200, 120)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Transparency = 0.4
	spawnLocation.Duration = 0
	spawnLocation.Parent = hubFolder

	createSign("HUB", Vector3.new(MapConfig.HubCenter.X, MapConfig.GroundY, MapConfig.HubCenter.Z - 15), Color3.fromRGB(90, 90, 100), hubFolder)
	createSign("-> SCALE GUESSER", Vector3.new(0, MapConfig.GroundY, 20), Color3.fromRGB(60, 120, 220), hubFolder)
	createSign("-> PARKOUR", Vector3.new(20, MapConfig.GroundY, 0), Color3.fromRGB(230, 140, 40), hubFolder)
	createSign("-> PLAZA", Vector3.new(-20, MapConfig.GroundY, 0), Color3.fromRGB(80, 200, 120), hubFolder)
end

--==========================================================================
-- Paths connecting the hub to each zone
--==========================================================================

local function buildPaths()
	local pathFolder = Instance.new("Folder")
	pathFolder.Name = "Paths"
	pathFolder.Parent = mapFolder

	buildStraightPath(
		"PathToArena",
		Vector3.new(0, 0, MapConfig.HubRadius),
		Vector3.new(0, 0, MapConfig.ArenaCenter.Z - MapConfig.ArenaRadius),
		12,
		Color3.fromRGB(140, 170, 220),
		pathFolder
	)

	buildStraightPath(
		"PathToParkour",
		Vector3.new(MapConfig.HubRadius, 0, 0),
		Vector3.new(MapConfig.ParkourOrigin.X - 30, 0, 0),
		12,
		Color3.fromRGB(230, 180, 140),
		pathFolder
	)

	buildStraightPath(
		"PathToPlaza",
		Vector3.new(-MapConfig.HubRadius, 0, 0),
		Vector3.new(MapConfig.PlazaCenter.X + 30, 0, 0),
		12,
		Color3.fromRGB(160, 220, 170),
		pathFolder
	)
end

--==========================================================================
-- Scale Guesser arena + start kiosk
--==========================================================================

local function buildArena()
	local arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "ScaleGuesserArena"
	arenaFolder.Parent = mapFolder

	createPart({
		Name = "ArenaPlatform",
		Size = Vector3.new(MapConfig.ArenaRadius * 2, 2, MapConfig.ArenaRadius * 2),
		Position = Vector3.new(MapConfig.ArenaCenter.X, 0, MapConfig.ArenaCenter.Z),
		Color = Color3.fromRGB(150, 180, 230),
		Parent = arenaFolder,
	})

	createSign(
		"SCALE GUESSER",
		Vector3.new(MapConfig.ArenaCenter.X, MapConfig.GroundY, MapConfig.ArenaCenter.Z + MapConfig.ArenaRadius - 6),
		Color3.fromRGB(60, 120, 220),
		arenaFolder
	)

	local kiosk = createPart({
		Name = "Kiosk",
		Size = Vector3.new(4, 5, 2),
		Position = Vector3.new(
			MapConfig.ArenaCenter.X,
			MapConfig.GroundY + 2.5,
			MapConfig.ArenaCenter.Z - MapConfig.ArenaRadius + 8
		),
		Color = Color3.fromRGB(90, 90, 100),
		Parent = arenaFolder,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ProximityPrompt"
	prompt.ActionText = "Start Game"
	prompt.ObjectText = "Scale Guesser"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = kiosk
end

--==========================================================================
-- Parkour course
--==========================================================================

local function buildParkourCourse()
	local parkourFolder = Instance.new("Folder")
	parkourFolder.Name = "ParkourCourse"
	parkourFolder.Parent = mapFolder

	createSign("PARKOUR COURSE", MapConfig.ParkourOrigin + Vector3.new(10, 0, 10), Color3.fromRGB(230, 140, 40), parkourFolder)

	local platforms = {}
	local position = MapConfig.ParkourOrigin + Vector3.new(20, 5, 0)
	local zigzag = 1

	for i = 1, 10 do
		local size = Vector3.new(6, 1, 6)
		local platform = createPart({
			Name = "ParkourPlatform" .. i,
			Size = size,
			Position = position,
			Color = Color3.fromRGB(230, 140 + (i % 3) * 10, 40),
			Parent = parkourFolder,
		})
		table.insert(platforms, platform)

		local stepX = 8
		local stepZ = zigzag * 6
		local stepY = (i % 2 == 0) and 2 or 1
		position = position + Vector3.new(stepX, stepY, stepZ)
		zigzag = -zigzag
	end

	-- Finish platform, a little larger and clearly marked.
	local finish = createPart({
		Name = "ParkourFinish",
		Size = Vector3.new(10, 1, 10),
		Position = position,
		Color = Color3.fromRGB(80, 200, 120),
		Parent = parkourFolder,
	})

	local finishBillboard = Instance.new("BillboardGui")
	finishBillboard.Size = UDim2.new(0, 160, 0, 40)
	finishBillboard.StudsOffset = Vector3.new(0, 3, 0)
	finishBillboard.AlwaysOnTop = true
	finishBillboard.Parent = finish

	local finishLabel = Instance.new("TextLabel")
	finishLabel.Size = UDim2.fromScale(1, 1)
	finishLabel.BackgroundTransparency = 1
	finishLabel.TextColor3 = Color3.new(1, 1, 1)
	finishLabel.TextStrokeTransparency = 0
	finishLabel.TextScaled = true
	finishLabel.Font = Enum.Font.GothamBold
	finishLabel.Text = "Finish!"
	finishLabel.Parent = finishBillboard

	-- Turn one mid-course platform into a moving platform for an extra
	-- timing challenge. Anchored parts can still be tweened; the position
	-- change replicates to clients normally.
	local movingPlatform = platforms[5]
	if movingPlatform then
		movingPlatform.Color = Color3.fromRGB(220, 60, 60)
		local startPos = movingPlatform.Position
		local endPos = startPos + Vector3.new(0, 0, 14)

		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tween = TweenService:Create(movingPlatform, tweenInfo, { Position = endPos })
		tween:Play()
	end
end

--==========================================================================
-- Plaza (decoration + light, open-ended parkour for wandering players)
--==========================================================================

local function createTree(position, parent)
	createPart({
		Name = "TreeTrunk",
		Size = Vector3.new(2, 6, 2),
		Position = position + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(100, 70, 40),
		Material = Enum.Material.Wood,
		Parent = parent,
	})

	createPart({
		Name = "TreeLeaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8),
		Position = position + Vector3.new(0, 9, 0),
		Color = Color3.fromRGB(60, 150, 70),
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

local function createBench(position, orientationY, parent)
	local seat = createPart({
		Name = "BenchSeat",
		Size = Vector3.new(5, 0.6, 2),
		Position = position + Vector3.new(0, 1.5, 0),
		Orientation = Vector3.new(0, orientationY, 0),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	createPart({
		Name = "BenchBack",
		Size = Vector3.new(5, 2, 0.4),
		CFrame = seat.CFrame * CFrame.new(0, 1, -0.8),
		Orientation = Vector3.new(0, orientationY, 0),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
end

local function createFountain(position, parent)
	createPart({
		Name = "FountainBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 14, 14),
		Orientation = Vector3.new(0, 0, 90),
		Position = position + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(190, 190, 200),
		Material = Enum.Material.Marble,
		Parent = parent,
	})
	createPart({
		Name = "FountainPillar",
		Size = Vector3.new(2, 6, 2),
		Position = position + Vector3.new(0, 5, 0),
		Color = Color3.fromRGB(190, 190, 200),
		Material = Enum.Material.Marble,
		Parent = parent,
	})
	createPart({
		Name = "FountainTop",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Position = position + Vector3.new(0, 9.5, 0),
		Color = Color3.fromRGB(80, 170, 230),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
end

-- A small stepped play structure: climbable blocks at increasing height,
-- loosely "parkour-ish" without being the dedicated course.
local function createJungleGym(position, parent)
	for i = 1, 4 do
		createPart({
			Name = "GymStep" .. i,
			Size = Vector3.new(4, 1, 4),
			Position = position + Vector3.new(i * 4, i * 2, 0),
			Color = Color3.fromRGB(200, 90, 160),
			Parent = parent,
		})
	end
end

local function buildPlaza()
	local plazaFolder = Instance.new("Folder")
	plazaFolder.Name = "Plaza"
	plazaFolder.Parent = mapFolder

	createPart({
		Name = "PlazaPlatform",
		Size = Vector3.new(70, 2, 70),
		Position = Vector3.new(MapConfig.PlazaCenter.X, 0, MapConfig.PlazaCenter.Z),
		Color = Color3.fromRGB(190, 220, 195),
		Parent = plazaFolder,
	})

	createSign("PLAZA", MapConfig.PlazaCenter + Vector3.new(0, 0, -25), Color3.fromRGB(80, 200, 120), plazaFolder)

	createFountain(MapConfig.PlazaCenter, plazaFolder)

	createTree(MapConfig.PlazaCenter + Vector3.new(20, 0, 20), plazaFolder)
	createTree(MapConfig.PlazaCenter + Vector3.new(-20, 0, 20), plazaFolder)
	createTree(MapConfig.PlazaCenter + Vector3.new(20, 0, -20), plazaFolder)
	createTree(MapConfig.PlazaCenter + Vector3.new(-22, 0, -18), plazaFolder)

	createBench(MapConfig.PlazaCenter + Vector3.new(10, 0, 8), 0, plazaFolder)
	createBench(MapConfig.PlazaCenter + Vector3.new(-10, 0, 8), 0, plazaFolder)

	createJungleGym(MapConfig.PlazaCenter + Vector3.new(-25, 0, -5), plazaFolder)
end

--==========================================================================
-- Build everything
--==========================================================================

buildHub()
buildPaths()
buildArena()
buildParkourCourse()
buildPlaza()
