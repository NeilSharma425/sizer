--[[
	NameTagClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.NameTagClient

	Keeps a crowded lobby readable: of the overhead rank/Sense tags (built by
	RoundManager), only the closest few other players' tags are shown, plus
	your own. Changes are local, so each player sees their own nearest set.
]]

local Players = game:GetService("Players")

local MAX_VISIBLE = 6 -- other players' tags shown at once
local REFRESH_SECONDS = 0.4

local localPlayer = Players.LocalPlayer

local function tagOf(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	return head and head:FindFirstChild("SenseTag"), head
end

while true do
	local camera = workspace.CurrentCamera
	local origin = camera and camera.CFrame.Position
	local nearby = {}
	for _, player in Players:GetPlayers() do
		local tag, head = tagOf(player)
		if tag then
			if player == localPlayer or not origin then
				tag.Enabled = true
			else
				table.insert(nearby, { tag = tag, distance = (head.Position - origin).Magnitude })
			end
		end
	end
	table.sort(nearby, function(a, b)
		return a.distance < b.distance
	end)
	for index, entry in nearby do
		entry.tag.Enabled = index <= MAX_VISIBLE
	end
	task.wait(REFRESH_SECONDS)
end
