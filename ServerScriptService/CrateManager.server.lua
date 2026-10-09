--[[
	CrateManager.server.lua
	Script: ServerScriptService.CrateManager

	Pet airdrops. Every few minutes a crate falls from the sky at a random
	spot on the map, announced to everyone by rarity only (CrateEvent; the
	pet itself is a surprise). When it lands it breaks open and 3 copies of
	one random crate-only pet spill out around it. Each copy is unlocked by
	the first player to touch it (one per player; players who already own
	the pet can't take one). Leftover copies vanish after LIFETIME seconds.

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
local GAP = { 1800, 3600 } -- 30-60 minutes between drops: 1-2 crates an hour
-- Live rounds (LiveRoundManager) must not overlap a crate: a drop waits if
-- one is running, ended under LIVE_BUFFER seconds ago, or starts within the
-- crate's whole fall + lifetime (plus LIVE_BUFFER).
local LIVE_BUFFER = 30
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
	PlayerData.markDirty(player)
	task.spawn(PlayerData.save, player) -- rare and valuable: save right away
	ProgressEvent:FireClient(player, "pet", { id = pet.id, name = pet.name })
end

local function groundAt(x, z, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, 250, z), Vector3.new(0, -500, 0), params)
	return hit and hit.Position.Y or nil
end

-- One pet copy lying on the ground next to the landing spot: the pet's own
-- model (bobbing and spinning), a big invisible touch zone, sparkles and a
-- name tag. Returns { model, hitbox, animate, base }.
local function spawnCopy(pet, rarity, position, parent)
	local holder = Instance.new("Model")
	holder.Name = "PetCopy"
	local model, animate = Pets.build(pet.id)
	if model then
		model:ScaleTo(1.6)
		model.Parent = holder
	end
	local hitbox = part(holder, {
		Name = "Hitbox",
		Size = Vector3.new(6, 6, 6),
		CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0)),
		Transparency = 1,
		CanTouch = true,
	})
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(rarity.color)
	sparkles.LightEmission = 1
	sparkles.Rate = 12
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Parent = hitbox

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 250
	billboard.LightInfluence = 0
	billboard.Parent = hitbox
	for i, info in ipairs({ { string.upper(pet.name), rarity.color }, { "TOUCH TO CLAIM!", Color3.new(1, 1, 1) } }) do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 0, (i - 1) * 0.55, 0)
		label.Size = UDim2.new(1, 0, i == 1 and 0.55 or 0.45, 0)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = info[1]
		label.TextColor3 = info[2]
		label.Parent = billboard
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Color = Color3.fromRGB(25, 20, 35)
		stroke.Parent = label
	end
	holder.Parent = parent
	return { holder = holder, model = model, hitbox = hitbox, animate = animate, base = position + Vector3.new(0, 2.5, 0), taken = false }
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
	local dropFolder = Instance.new("Folder")
	dropFolder.Name = "PetDrop"
	dropFolder.Parent = crateFolder

	local model = buildCrate(rarity.color, string.format("MYSTERY PET x%d", COPIES), pet.rarity)
	model.Parent = dropFolder
	model:PivotTo(CFrame.new(landing + Vector3.new(0, DROP_HEIGHT, 0)))

	local rules = CrateLogic.new(COPIES)
	local finished = false
	local copies = {}

	workspace:SetAttribute("CrateActive", true)

	-- Only the rarity is announced; which pet is inside is a surprise until
	-- the crate lands and breaks open.
	CrateEvent:FireAllClients("incoming", {
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
		workspace:SetAttribute("CrateActive", false)
		CrateEvent:FireAllClients(kind, { rarity = pet.rarity })
		task.delay(kind == "done" and 1 or 0, function()
			dropFolder:Destroy()
		end)
	end

	-- Fall from the sky.
	local steps = FALL_SECONDS * 30
	for i = 1, steps do
		local t = i / steps
		local eased = 1 - (1 - t) ^ 2
		model:PivotTo(CFrame.new(landing + Vector3.new(0, DROP_HEIGHT * (1 - eased), 0)))
		task.wait(1 / 30)
	end

	-- Landed: the crate breaks open (keeping its light beam so people can
	-- still find the spot) and the pet copies spill out around it.
	local beam = model:FindFirstChild("Beam")
	if beam then
		beam.Parent = dropFolder
		beam.CFrame = CFrame.new(landing + Vector3.new(0, 150, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	end
	model:Destroy()
	CrateEvent:FireAllClients("opened", { rarity = pet.rarity, name = pet.name, color = rarity.color })

	local spin = rng:NextNumber(0, math.pi * 2)
	for i = 1, COPIES do
		local angle = spin + (i - 1) * (math.pi * 2 / COPIES)
		local x, z = landing.X + math.cos(angle) * 6, landing.Z + math.sin(angle) * 6
		local y = groundAt(x, z, { dropFolder }) or landing.Y
		if math.abs(y - landing.Y) > 6 then
			y = landing.Y -- don't put a copy on a roof or down a hole
		end
		local copy = spawnCopy(pet, rarity, Vector3.new(x, y, z), dropFolder)
		table.insert(copies, copy)

		copy.hitbox.Touched:Connect(function(hit)
			if finished or copy.taken then
				return
			end
			local player = playerFromHit(hit)
			if not player then
				return
			end
			local profile = PlayerData.getProfile(player)
			local result = rules:claim(player.UserId, profile.pets[pet.id] == true)
			if result == "owned" then
				CrateEvent:FireClient(player, "owned", { rarity = pet.rarity })
			elseif result == "granted" then
				copy.taken = true
				copy.holder:Destroy()
				grant(player, pet)
				if rules:isEmpty() then
					finish("done")
				end
			end
		end)
	end

	-- Bob and spin the copies until they're all taken or time runs out.
	task.spawn(function()
		local started = os.clock()
		while not finished do
			local t = os.clock() - started
			for i, copy in ipairs(copies) do
				if not copy.taken and copy.model then
					copy.model:PivotTo(CFrame.new(copy.base + Vector3.new(0, math.sin(t * 2 + i) * 0.4, 0)) * CFrame.Angles(0, t * 1.2 + i, 0))
					if copy.animate then
						copy.animate(t)
					end
				end
			end
			task.wait(1 / 20)
		end
	end)

	task.delay(LIFETIME, function()
		if not finished and not rules:isEmpty() then
			finish("expired")
		end
	end)
end

--------------------------------------------------------------------------
-- Schedule
--------------------------------------------------------------------------

-- True while a live round is on, just ended, or due before this crate
-- would be gone.
local function nearLiveRound()
	local now = workspace:GetServerTimeNow()
	if workspace:GetAttribute("LiveRoundActive") then
		return true
	end
	local endedAt = workspace:GetAttribute("LiveRoundEndedAt")
	if endedAt and now - endedAt < LIVE_BUFFER then
		return true
	end
	local nextAt = workspace:GetAttribute("NextLiveRoundAt")
	return nextAt ~= nil and nextAt > now and nextAt - now < FALL_SECONDS + LIFETIME + LIVE_BUFFER
end

task.spawn(function()
	task.wait(rng:NextNumber(FIRST_DROP[1], FIRST_DROP[2]))
	while true do
		while nearLiveRound() do
			task.wait(5)
		end
		if #Players:GetPlayers() > 0 then
			local ok, err = pcall(drop)
			if not ok then
				workspace:SetAttribute("CrateActive", false)
				warn("[Sizer] Crate drop failed:", err)
			end
		end
		task.wait(rng:NextNumber(GAP[1], GAP[2]))
	end
end)
