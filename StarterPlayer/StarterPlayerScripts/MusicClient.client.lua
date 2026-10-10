--[[
	MusicClient.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.MusicClient

	Background music: plays TRACKS in a loop, quietly, with a small mute
	button in the bottom-right corner. Use free tracks from Roblox's own
	music library (Creator Store > Audio > made by Roblox): copy each track's
	asset ID into TRACKS. With no tracks listed, nothing plays.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local TRACKS = {
	139132289200391,
	9047883011,
	87235694180663,
	139127004857974,
	1839825760,
}
local VOLUME = 0.25

if #TRACKS == 0 then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sound = Instance.new("Sound")
sound.Name = "BackgroundMusic"
sound.Volume = VOLUME
sound.Parent = SoundService

local index = math.random(1, #TRACKS)
local muted = false
local function playNext()
	index = index % #TRACKS + 1
	sound.SoundId = "rbxassetid://" .. TRACKS[index]
	sound.TimePosition = 0
	if not muted then
		sound:Play()
	end
end
sound.Ended:Connect(playNext)
playNext()

-- Mute button
local gui = Instance.new("ScreenGui")
gui.Name = "SizerMusic"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.Parent = playerGui
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -14, 1, -22)
button.Size = UDim2.fromOffset(44, 44)
button.BackgroundColor3 = Color3.fromRGB(40, 45, 75)
button.BackgroundTransparency = 0.15
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)
button.Text = "♪"
button.Parent = gui
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(1, 0)
c.Parent = button
local s = Instance.new("UIStroke")
s.Thickness = 3
s.Color = Color3.fromRGB(25, 20, 35)
s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
s.Parent = button
button.MouseButton1Click:Connect(function()
	muted = not muted
	button.Text = muted and "×" or "♪"
	button.TextColor3 = muted and Color3.fromRGB(150, 155, 180) or Color3.new(1, 1, 1)
	if muted then
		sound:Pause()
	else
		sound:Resume()
	end
end)
