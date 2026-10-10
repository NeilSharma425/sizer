--[[
	ChatTags.client.lua
	LocalScript: StarterPlayer.StarterPlayerScripts.ChatTags

	A gold [VIP] tag in front of chat messages from players who own the VIP
	game pass (the server sets their "Pass_vip" attribute).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shop = require(ReplicatedStorage:WaitForChild("Shop"))

TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local sender = source and Players:GetPlayerByUserId(source.UserId)
	if sender and sender:GetAttribute(Shop.attribute("vip")) == true then
		properties.PrefixText = '<font color="#FFCD3C">[VIP]</font> ' .. message.PrefixText
	end
	return properties
end
