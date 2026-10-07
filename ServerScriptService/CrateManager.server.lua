--[[
	CrateManager.server.lua
	Script: ServerScriptService.CrateManager

	Pet airdrops. Every few minutes a crate falls from the sky at a random
	spot on the map, announced to everyone (CrateEvent). It holds 3 copies
	of one random crate-only pet (see Pets: rarity Rare / Epic / Legendary).
	The first 3 different players to touch it each unlock the pet; players
	who already own it can't take a copy. The crate vanishes when it's empty
	or after LIFETIME seconds.

	In Studio the first drop comes after ~20 seconds so it's easy to test.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Pets = require(ReplicatedStorage:WaitForChild("Pets"))
local CrateLogic = require(ReplicatedStorage:WaitForChild("CrateLogic"))

local okData, PlayerData = pcall(function()
	return require(ServerScriptService:WaitForChild("PlayerData", 30))
end)
if not okData or type(PlayerData) ~= "table" then
	warn("[Sizer] CrateManager: PlayerData unavailable; crates disabled.")
	return
end

local remotes = ReplicatedStorage:WaitForChild("ScaleGameRemotes", 30)
if not remotes then
	warn("[Sizer] CrateManager: remotes not found; crates disabled.")
	return
end
local ProgressEvent = remotes:WaitForChild("ProgressEvent", 30)

local CrateEvent = Instance.new("RemoteEvent")
CrateEvent.Name = "CrateEvent"
CrateEvent.Parent = remotes

--------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------

local COPIES = 3 -- how many players get the pet from one crate
local FALL_SECONDS = 7
local LIFETIME = 90 -- seconds a landed crate waits before vanishing
local FIRST_DROP = RunService:IsStudio() and { 20, 30 } or { 90, 180 }
local GAP = { 240, 480 } -- random seconds between drops
local MAP_HALF_X, MAP_HALF_Z = 85, 80 -- keep drops on the platform
local DROP_HEIGHT = 170

local rng = Random.new()

--------------------------------------------------------------------------
-- Finding a place to land
--------------------------------------------------------------------------

local function findLanding(ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	for _ = 1, 40 do
		local x = rng:NextNumber(-MAP_HALF_X, MAP_HALF_X)
		local z = rng:NextNumber(-MAP_HALF_Z, MAP_HALF_Z)
		local hit = workspace:Raycast(Vector3.new(x, 250, z), Vector3.new(0, -500, 0), params)
		if hit and hit.Normal.Y > 0.7 and hit.Instance.CanCollide and hit.Position.Y < 40 then
			return hit.Position
		end
	end
	return Vector3.new(0, 2, -40) -- near the spawn as a fallback
end

--------------------------------------------------------------------------
-- The crate
--------------------------------------------------------------------------

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function buildCrate(rarityColor, titleText, rarityName)
	local model = Instance.new("Model")
	model.Name = "PetCrate"

	local wood, dark, gold = Color3.fromRGB(150, 100, 60), Color3.fromRGB(105, 70, 42), Color3.fromRGB(255, 210, 70)
	-- The crate sits with its bottom at y = 0 of its own space.
	part(model, { Name = "Body", Size = Vector3.new(5, 3, 4), CFrame = CFrame.new(0, 1.5, 0), Color = wood, Material = Enum.Material.Wood })
	part(model, { Size = Vector3.new(5.2, 1.2, 4.2), CFrame = CFrame.new(0, 3.6, 0), Color = dark, Material = Enum.Material.Wood })
	for _, x in ipairs({ -1.8, 1.8 }) do
		part(model, { Size = Vector3.new(0.5, 4.5, 4.4), CFrame = CFrame.new(x, 2.4, 0), Color = rarityColor, Material = Enum.Material.Neon })
	end
	part(model, { Size = Vector3.new(1, 1, 0.3), CFrame = CFrame.new(0, 2.8, -2.15), Color = gold, Material = Enum.Material.Metal })
	part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		CFrame = CFrame.new(0, 5.4, 0),
		Color = rarityColor,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
	})

	-- Big, easy-to-hit touch zone.
	local hitbox = part(model, {
		Name = "Hitbox",
		Size = Vector3.new(11, 8, 11),
		CFrame = CFrame.new(0, 4, 0),
		Transparency = 1,
		CanTouch = true,
	})

	-- Light beam so everyone can see where it is, from anywhere.
	local beam = part(model, {
		Name = "Beam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(300, 2.4, 2.4),
		CFrame = CFrame.new(0, 150, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rarityColor,
		Material = Enum.Material.Neon,
		Transparency = 0.65,
	})
	local light = Instance.new("PointLight")
	light.Color = rarityColor
	light.Range = 24
	light.Brightness = 3
	light.Parent = model.Body

	local anchor = part(model, { Name = "LabelAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 9, 0), Transparency = 1 })
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 84)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 2000
	billboard.LightInfluence = 0
	billboard.Parent = anchor
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = rarityColor
	title.Text = string.upper(rarityName) .. " PET CRATE"
	title.Parent = billboard
	local stroke1 = Instance.new("UIStroke")
	stroke1.Thickness = 2.5
	stroke1.Color = Color3.fromRGB(25, 20, 35)
	stroke1.Parent = title
	local left = Instance.new("TextLabel")
	left.Name = "Left"
	left.BackgroundTransparency = 1
	left.Position = UDim2.new(0, 0, 0.5, 0)
	left.Size = UDim2.new(1, 0, 0.5, 0)
	left.Font = Enum.Font.FredokaOne
	left.TextScaled = true
	left.TextColor3 = Color3.new(1, 1, 1)
	left.Text = titleText
	left.Parent = billboard
	local stroke2 = Instance.new("UIStroke")
	stroke2.Thickness = 2.5
	stroke2.Color = Color3.fromRGB(25, 20, 35)
	stroke2.Parent = left

	model.PrimaryPart = model.Body
	return model, hitbox, left, beam
end

--------------------------------------------------------------------------
-- One drop
--------------------------------------------------------------------------

local function playerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if player and humanoid and humanoid.Health > 0 then
		return player
	end
	return nil
end

local function grant(player, pet)
	local profile = PlayerData.getProfile(player)
	profile.pets[pet.id] = true
	if profile.pet == "" then
		profile.pet = pet.id
		player:SetAttribute("Pet", pet.id)
	end
	PlayerData.markDirty(player)
	task.spawn(PlayerData.save, player) -- rare and valuable: save right away
	ProgressEvent:FireClient(player, "pet", { id = pet.id, name = pet.name })
end

local function drop()
	local pet = Pets.rollCratePet(rng)
	local rarity = Pets.Rarities[pet.rarity]
	local landing = findLanding({})
	local crateFolder = workspace:FindFirstChild("PetCrates")
	if not crateFolder then
		crateFolder = Instance.new("Folder")
		crateFolder.Name = "PetCrates"
		crateFolder.Parent = workspace
	end

	local model, hitbox, leftLabel = buildCrate(rarity.color, string.format("%s x%d", pet.name, COPIES), pet.rarity)
	model.Parent = crateFolder
	model:PivotTo(CFrame.new(landing + Vector3.new(0, DROP_HEIGHT, 0)))

	local rules = CrateLogic.new(COPIES)
	local open = false
	local finished = false

	CrateEvent:FireAllClients("incoming", {
		id = pet.id,
		name = pet.name,
		rarity = pet.rarity,
		color = rarity.color,
		copies = COPIES,
		fallSeconds = FALL_SECONDS,
	})

	local function finish(kind)
		if finished then
			return
		end
		finished = true
		CrateEvent:FireAllClients(kind, { name = pet.name, rarity = pet.rarity })
		task.delay(kind == "done" and 1.5 or 0, function()
			model:Destroy()
		end)
	end

	hitbox.Touched:Connect(function(hit)
		if not open or finished then
			return
		end
		local player = playerFromHit(hit)
		if not player then
			return
		end
		local profile = PlayerData.getProfile(player)
		local result = rules:claim(player.UserId, profile.pets[pet.id] == true)
		if result == "owned" then
			CrateEvent:FireClient(player, "owned", { name = pet.name })
		elseif result == "granted" then
			grant(player, pet)
			leftLabel.Text = rules.left > 0 and string.format("%d LEFT!", rules.left) or "ALL CLAIMED"
			if rules:isEmpty() then
				finish("done")
			end
		end
	end)

	-- Fall from the sky.
	local steps = FALL_SECONDS * 30
	for i = 1, steps do
		local t = i / steps
		local eased = 1 - (1 - t) ^ 2
		model:PivotTo(CFrame.new(landing + Vector3.new(0, DROP_HEIGHT * (1 - eased), 0)))
		task.wait(1 / 30)
		if finished then
			return
		end
	end
	model:PivotTo(CFrame.new(landing))
	open = true
	leftLabel.Text = string.format("%s x%d", pet.name, COPIES)

	task.delay(LIFETIME, function()
		if not finished and not rules:isEmpty() then
			finish("expired")
		end
	end)
end

--------------------------------------------------------------------------
-- Schedule
--------------------------------------------------------------------------

task.spawn(function()
	task.wait(rng:NextNumber(FIRST_DROP[1], FIRST_DROP[2]))
	while true do
		if #Players:GetPlayers() > 0 then
			local ok, err = pcall(drop)
			if not ok then
				warn("[Sizer] Crate drop failed:", err)
			end
		end
		task.wait(rng:NextNumber(GAP[1], GAP[2]))
	end
end)
