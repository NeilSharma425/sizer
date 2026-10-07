--[[
	MapEffects.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.MapEffects

	Client-side map interactions. Trampolines launch the local character
	upward; this runs on the client because players own their character's
	physics.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local SoundFX = select(2, pcall(function()
	return require(ReplicatedStorage:WaitForChild("SoundFX", 10))
end))

local BOUNCE_SPEED = 212 -- jump height grows with speed squared: 95 * sqrt(5) is 5x the old height
local COOLDOWN = 0.35

local lastBounce = 0

local function hookTrampoline(mat)
	mat.Touched:Connect(function(hit)
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		local now = os.clock()
		if now - lastBounce < COOLDOWN then
			return
		end
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end
		lastBounce = now
		if type(SoundFX) == "table" then
			pcall(SoundFX.play, "boing")
		end
		local v = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(v.X, BOUNCE_SPEED, v.Z)
	end)
end

for _, mat in ipairs(CollectionService:GetTagged("Trampoline")) do
	hookTrampoline(mat)
end
CollectionService:GetInstanceAddedSignal("Trampoline"):Connect(hookTrampoline)
