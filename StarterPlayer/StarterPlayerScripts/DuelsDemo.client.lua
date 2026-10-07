--[[
	DuelsDemo.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.DuelsDemo

	The little show on the DUELS "coming soon" stand (MapBuilder tags it
	"DuelsDemo"): a bacon hair steps in, winds up and slaps a classic noob
	across the face. The noob's head whips round, he's knocked back, goes
	wild (spins, jumps, flails, yells) and ends up dizzy. Loops forever.
	The characters' roots are anchored; this script moves the roots and
	bends the joints (Motor6D.C0) locally, only while the camera is close
	enough to see it.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local LOOP = 6 -- seconds per slap
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
	leftElbow = { "LeftElbow" },
	leftWrist = { "LeftWrist" },
	waist = { "Waist" },
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

	-- A white streak behind the slapping hand so the swing reads clearly.
	local hand = slapper:FindFirstChild("LeftHand") or slapper:FindFirstChild("Left Arm")
	local trail
	if hand then
		local reach = hand.Name == "LeftHand" and 0 or -0.8 -- the stand-in's "hand" is the bottom of its arm
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, reach + 0.35, 0)
		a0.Parent = hand
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, reach - 0.35, 0)
		a1.Parent = hand
		trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.22
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.LightEmission = 1
		trail.Enabled = false
		trail.Parent = hand
	end

	-- White burst where the hand lands.
	local flash = Instance.new("Part")
	flash.Name = "SlapFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.new(1, 1, 1)
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.Transparency = 1
	flash.Parent = folder

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/uuhhh.mp3"
	sound.Volume = 0.35
	sound.PlaybackSpeed = 1.15
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 60
	sound.Parent = b.root

	demos[folder] = { a = a, b = b, slapText = slapText, yellText = yellText, yellLabel = yellLabel, stars = stars, flash = flash, trail = trail, sound = sound, lastLoop = -1 }
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

local IMPACT = 1.66 -- the moment the hand lands

-- Linear blend of keyframes { {time, value}, ... } with smoothing.
local function keyed(t, keys)
	if t <= keys[1][1] then
		return keys[1][2]
	end
	for i = 1, #keys - 1 do
		local k0, k1 = keys[i], keys[i + 1]
		if t <= k1[1] then
			local k = (t - k0[1]) / (k1[1] - k0[1])
			if not k1[3] then -- the 3rd field marks a fast, unsmoothed move
				k = smooth(k)
			end
			return k0[2] + (k1[2] - k0[2]) * k
		end
	end
	return keys[#keys][2]
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
		-- Slapper (bacon hair): step in, wind the arm back, whip it across
		-- the noob's face, follow through, then step back.
		------------------------------------------------------------------
		-- 0.4-0.7 step in, 0.7-1.3 raise the hand up by the head, hold,
		-- 1.5-1.75 swing it down and across (hits at IMPACT), follow
		-- through, 2.1-2.7 relax and step back.
		local step = keyed(t, { { 0.4, 0 }, { 0.7, 0.35 }, { 2.3, 0.35 }, { 2.8, 0 } })
		local twist = keyed(t, { { 0.7, 0 }, { 1.3, 30 }, { 1.5, 32 }, { 1.75, -25 }, { 2.1, -25 }, { 2.7, 0 } })
		local pitch = keyed(t, { { 0.7, 0 }, { 1.3, 150 }, { 1.5, 155 }, { 1.75, 80 }, { 2.1, 80 }, { 2.7, 0 } })
		local yaw = keyed(t, { { 0.7, 0 }, { 1.3, 55 }, { 1.5, 60 }, { 1.75, -45 }, { 2.1, -45 }, { 2.7, 0 } })
		local elbow = keyed(t, { { 0.7, 0 }, { 1.3, 95 }, { 1.5, 100 }, { 1.75, 5 }, { 2.1, 10 }, { 2.7, 0 } })
		local wrist = keyed(t, { { 1.3, 0 }, { 1.5, -35 }, { 1.75, 30 }, { 2.1, 0 } })
		a.root.CFrame = a.base * CFrame.new(0, 0, -step) * CFrame.Angles(0, math.rad(twist), 0)
		setJoint(a, "leftArm", CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0))
		setJoint(a, "leftElbow", CFrame.Angles(math.rad(elbow), 0, 0))
		setJoint(a, "leftWrist", CFrame.Angles(0, 0, math.rad(wrist)))
		if d.trail then
			d.trail.Enabled = t >= 1.48 and t < 1.85
		end

		------------------------------------------------------------------
		-- Noob: head snaps away and he's knocked back, then goes wild,
		-- then stands there dizzy.
		------------------------------------------------------------------
		local knock = keyed(t, { { IMPACT, 0 }, { IMPACT + 0.12, 1.2, true }, { IMPACT + 0.4, 1.2 }, { IMPACT + 2.5, 0 } })
		local tilt = keyed(t, { { IMPACT, 0 }, { IMPACT + 0.1, 18, true }, { IMPACT + 0.4, 8 }, { IMPACT + 0.9, 0 } })
		local rootCF = b.base * CFrame.new(0, 0, knock) * CFrame.Angles(math.rad(tilt), 0, math.rad(-tilt * 0.6))
		local neckCF = CFrame.new()
		local CRAZY_START, CRAZY_END = IMPACT + 0.4, IMPACT + 2.6
		if t >= IMPACT and t < CRAZY_START then
			-- head whips round, then wobbles back
			local c = t - IMPACT
			neckCF = CFrame.Angles(0, math.rad(70 * math.exp(-c * 4) * math.cos(c * 18)), math.rad(-25 * math.exp(-c * 5)))
			for _, key in ipairs({ "leftArm", "rightArm", "leftLeg", "rightLeg" }) do
				setJoint(b, key, CFrame.new())
			end
			setJoint(b, "leftArm", CFrame.Angles(0, 0, math.rad(-40) * math.exp(-c * 3)))
			setJoint(b, "rightArm", CFrame.Angles(0, 0, math.rad(40) * math.exp(-c * 3)))
		elseif t >= CRAZY_START and t < CRAZY_END then
			local c = t - CRAZY_START
			local fade = 1 - smooth((c - 1.75) / 0.45) -- winds down at the end
			local spin = CFrame.Angles(0, c * 14 * fade, 0)
			local hop = math.abs(math.sin(c * 11)) * 1.5 * fade
			local wobble = CFrame.Angles(math.sin(c * 17) * 0.25 * fade, 0, math.sin(c * 13) * 0.3 * fade)
			rootCF = rootCF * CFrame.new(0, hop, 0) * spin * wobble
			local flail = c * 22
			setJoint(b, "leftArm", CFrame.Angles(math.sin(flail) * 2.6 * fade, 0, -math.abs(math.cos(flail)) * 1.2 * fade))
			setJoint(b, "rightArm", CFrame.Angles(math.cos(flail) * 2.6 * fade, 0, math.abs(math.sin(flail)) * 1.2 * fade))
			setJoint(b, "leftLeg", CFrame.Angles(math.sin(c * 18) * 0.9 * fade, 0, 0))
			setJoint(b, "rightLeg", CFrame.Angles(-math.sin(c * 18) * 0.9 * fade, 0, 0))
			neckCF = CFrame.Angles(0, math.sin(c * 30) * 0.5 * fade, math.sin(c * 25) * 0.3 * fade)
		else
			for _, key in ipairs({ "leftArm", "rightArm", "leftLeg", "rightLeg" }) do
				setJoint(b, key, CFrame.new())
			end
			if t >= CRAZY_END then
				-- dizzy sway
				neckCF = CFrame.Angles(0, 0, math.sin(now * 3) * 0.15)
				rootCF = rootCF * CFrame.Angles(0, 0, math.sin(now * 3) * 0.04)
			end
		end
		setJoint(b, "neck", neckCF)
		b.root.CFrame = rootCF

		------------------------------------------------------------------
		-- Effects
		------------------------------------------------------------------
		if loopIndex ~= d.lastLoop and t >= IMPACT then
			d.lastLoop = loopIndex
			d.sound:Play()
		end
		local sinceHit = t - IMPACT
		if sinceHit >= 0 and sinceHit < 0.25 then
			local k = sinceHit / 0.25
			local size = 0.6 + 2.2 * k
			d.flash.Size = Vector3.new(size, size, size)
			d.flash.Transparency = 0.1 + 0.9 * k
			d.flash.CFrame = b.base * CFrame.new(0.3, 1.5, -0.8)
		else
			d.flash.Transparency = 1
		end
		d.slapText.Enabled = sinceHit >= 0 and sinceHit < 0.6
		d.yellText.Enabled = t >= IMPACT + 0.45 and t < IMPACT + 2.3
		d.yellLabel.Text = math.floor(now * 6) % 2 == 0 and "AAAAH!" or "WHY?!"
		local showStars = t >= IMPACT + 2.6 and t < LOOP - 0.1
		local headPos = (rootCF * CFrame.new(0, 2.6, 0)).Position
		for i, star in ipairs(d.stars) do
			local ang = now * 5 + i * (math.pi * 2 / 3)
			star.Transparency = showStars and 0 or 1
			star.CFrame = CFrame.new(headPos + Vector3.new(math.cos(ang) * 1.3, 0, math.sin(ang) * 1.3))
		end
	end
end)
