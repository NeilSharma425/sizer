--[[
	DuelsDemo.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.DuelsDemo

	The little show on the DUELS "coming soon" stand (MapBuilder tags it
	"DuelsDemo"): a classic noob winds up and slaps a normal Roblox player
	(the first player's avatar), who goes
	wild (spins, jumps, flails, yells) and then shakes it off. Loops forever.
	The characters' roots are anchored; this script moves the roots and
	bends the joints (Motor6D.C0) locally, only while the camera is close
	enough to see it.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local LOOP = 5.2 -- seconds per slap
local VIEW_DISTANCE = 170

local demos = {}

-- Find the root and the joints we animate (works for R15 and the R6-style
-- stand-in), remembering each joint's resting C0.
local JOINTS = {
	leftArm = { "LeftShoulder", "Left Shoulder" },
	rightArm = { "RightShoulder", "Right Shoulder" },
	leftLeg = { "LeftHip", "Left Hip" },
	rightLeg = { "RightHip", "Right Hip" },
	neck = { "Neck" },
}

local function rig(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local r = { model = model, root = root, base = root.CFrame, joints = {} }
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			for key, names in pairs(JOINTS) do
				for _, n in ipairs(names) do
					if d.Name == n then
						r.joints[key] = { motor = d, c0 = d.C0 }
					end
				end
			end
		end
	end
	r.head = model:FindFirstChild("Head")
	return r
end

local function setJoint(r, key, rotation)
	local j = r.joints[key]
	if j then
		j.motor.C0 = j.c0 * rotation
	end
end

local function makeBillboard(adornee, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 160, 0, 60)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = VIEW_DISTANCE
	gui.LightInfluence = 0
	gui.Enabled = false
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(25, 20, 35)
	stroke.Parent = label
	gui.Adornee = adornee
	gui.Parent = adornee
	return gui, label
end

local function setup(folder)
	if demos[folder] then
		return
	end
	-- The victim is built once the first player joins, so it may arrive late.
	local slapper, victim
	for _ = 1, 120 do
		slapper = folder:FindFirstChild("Slapper")
		victim = folder:FindFirstChild("Victim")
		if slapper and victim and victim:FindFirstChild("HumanoidRootPart") and victim:FindFirstChild("Head") then
			break
		end
		task.wait(1)
	end
	if not slapper or not victim then
		return
	end
	local a, b = rig(slapper), rig(victim)
	if not a or not b or not b.head then
		return
	end
	local slapText = makeBillboard(b.head, "SLAP!", Color3.fromRGB(255, 230, 60))
	local yellText, yellLabel = makeBillboard(b.head, "AAAAH!", Color3.fromRGB(255, 90, 90))
	yellText.StudsOffset = Vector3.new(0, 5.5, 0)

	-- Dizzy stars that circle the victim's head.
	local stars = {}
	for i = 1, 3 do
		local star = Instance.new("Part")
		star.Name = "DizzyStar"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(0.45, 0.45, 0.45)
		star.Material = Enum.Material.Neon
		star.Color = Color3.fromRGB(255, 230, 70)
		star.Anchored = true
		star.CanCollide = false
		star.CanQuery = false
		star.CanTouch = false
		star.Transparency = 1
		star.Parent = folder
		stars[i] = star
	end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/uuhhh.mp3"
	sound.Volume = 0.35
	sound.PlaybackSpeed = 1.15
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 60
	sound.Parent = b.root

	demos[folder] = { a = a, b = b, slapText = slapText, yellText = yellText, yellLabel = yellLabel, stars = stars, sound = sound, lastLoop = -1 }
end

for _, folder in ipairs(CollectionService:GetTagged("DuelsDemo")) do
	task.spawn(setup, folder)
end
CollectionService:GetInstanceAddedSignal("DuelsDemo"):Connect(function(folder)
	task.spawn(setup, folder)
end)

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local now = os.clock()
	for _, d in pairs(demos) do
		local a, b = d.a, d.b
		if not a.root.Parent or (camera and (camera.CFrame.Position - a.base.Position).Magnitude > VIEW_DISTANCE) then
			continue
		end
		local t = now % LOOP
		local loopIndex = math.floor(now / LOOP)

		------------------------------------------------------------------
		-- Slapper: wind up (0.3-1.2s), slap (1.2-1.35s), follow through.
		------------------------------------------------------------------
		local pitch, yaw = 0, 0
		if t < 0.3 then
			pitch, yaw = 0, 0
		elseif t < 1.2 then
			local k = smooth((t - 0.3) / 0.6)
			pitch, yaw = math.rad(90) * k, math.rad(75) * k
		elseif t < 1.35 then
			local k = (t - 1.2) / 0.15
			pitch, yaw = math.rad(90), math.rad(75 - 115 * k)
		elseif t < 2.2 then
			pitch, yaw = math.rad(90), math.rad(-40)
		elseif t < 2.7 then
			local k = smooth((t - 2.2) / 0.5)
			pitch, yaw = math.rad(90) * (1 - k), math.rad(-40) * (1 - k)
		end
		local lean = (t > 1.2 and t < 1.6) and CFrame.Angles(0, math.rad(-12), 0) or CFrame.new()
		a.root.CFrame = a.base * lean
		setJoint(a, "leftArm", CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0))

		------------------------------------------------------------------
		-- Victim: goes wild after the slap (1.35-3.8s), then settles.
		------------------------------------------------------------------
		local rootCF = b.base
		if t >= 1.35 and t < 3.8 then
			local c = t - 1.35
			local fade = 1 - smooth((c - 2.0) / 0.45) -- winds down at the end
			local spin = CFrame.Angles(0, c * 14 * fade, 0)
			local hop = math.abs(math.sin(c * 11)) * 1.6 * fade
			local wobble = CFrame.Angles(math.sin(c * 17) * 0.25 * fade, 0, math.sin(c * 13) * 0.3 * fade)
			rootCF = b.base * CFrame.new(0, hop, 0) * spin * wobble
			local flail = c * 22
			setJoint(b, "leftArm", CFrame.Angles(math.sin(flail) * 2.6 * fade, 0, -math.abs(math.cos(flail)) * 1.2 * fade))
			setJoint(b, "rightArm", CFrame.Angles(math.cos(flail) * 2.6 * fade, 0, math.abs(math.sin(flail)) * 1.2 * fade))
			setJoint(b, "leftLeg", CFrame.Angles(math.sin(c * 18) * 0.9 * fade, 0, 0))
			setJoint(b, "rightLeg", CFrame.Angles(-math.sin(c * 18) * 0.9 * fade, 0, 0))
			setJoint(b, "neck", CFrame.Angles(0, math.sin(c * 30) * 0.5 * fade, math.sin(c * 25) * 0.3 * fade))
		else
			if t >= 1.2 and t < 1.35 then
				rootCF = b.base * CFrame.Angles(0, 0, math.rad(-8)) -- brace for impact
			end
			for _, key in ipairs({ "leftArm", "rightArm", "leftLeg", "rightLeg", "neck" }) do
				setJoint(b, key, CFrame.new())
			end
		end
		b.root.CFrame = rootCF

		------------------------------------------------------------------
		-- Effects
		------------------------------------------------------------------
		if loopIndex ~= d.lastLoop and t >= 1.3 then
			d.lastLoop = loopIndex
			d.sound:Play()
		end
		d.slapText.Enabled = t >= 1.3 and t < 1.9
		d.yellText.Enabled = t >= 1.6 and t < 3.4
		d.yellLabel.Text = math.floor(now * 6) % 2 == 0 and "AAAAH!" or "WHY?!"
		local showStars = t >= 3.4 and t < 5.0
		local headPos = (rootCF * CFrame.new(0, 3.2, 0)).Position
		for i, star in ipairs(d.stars) do
			local ang = now * 5 + i * (math.pi * 2 / 3)
			star.Transparency = showStars and 0 or 1
			star.CFrame = CFrame.new(headPos + Vector3.new(math.cos(ang) * 1.3, 0, math.sin(ang) * 1.3))
		end
	end
end)
