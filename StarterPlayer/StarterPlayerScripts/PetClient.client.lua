--[[
	PetClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.PetClient

	Shows every player's equipped pet (the "Pet" player attribute, set by the
	server from the streak rewards) following them around the lobby. Pets are
	built locally from ReplicatedStorage.Pets, so nothing is replicated.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Pets = require(ReplicatedStorage:WaitForChild("Pets"))

local folder = Instance.new("Folder")
folder.Name = "SizerPets"
folder.Parent = workspace

local active = {} -- [player] = { id, model, animate, cframe }

local function remove(player)
	local entry = active[player]
	if entry then
		entry.model:Destroy()
		active[player] = nil
	end
end

local function sync(player)
	local id = player:GetAttribute("Pet")
	local entry = active[player]
	if entry and entry.id == id then
		return
	end
	remove(player)
	if type(id) ~= "string" or id == "" then
		return
	end
	local model, animate = Pets.build(id)
	if model then
		model.Parent = folder
		active[player] = { id = id, model = model, animate = animate, cframe = nil }
	end
end

local function track(player)
	player:GetAttributeChangedSignal("Pet"):Connect(function()
		sync(player)
	end)
	sync(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	track(player)
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(remove)

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for player, entry in pairs(active) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- The viewing room is far away; hide pets that aren't near their owner.
		if root then
			local bob = math.sin(t * 2.4 + player.UserId % 7) * 0.35
			local goal = root.CFrame * CFrame.new(3.2, 0.4 + bob, 2.2)
			-- Smooth follow.
			local current = entry.cframe or goal
			local alpha = 1 - math.exp(-8 * dt)
			current = current:Lerp(goal, alpha)
			entry.cframe = current
			-- Face the same way as the owner.
			local look = CFrame.new(current.Position) * (root.CFrame - root.CFrame.Position)
			entry.model:PivotTo(look)
			if entry.animate then
				entry.animate(t)
			end
		end
	end
end)
