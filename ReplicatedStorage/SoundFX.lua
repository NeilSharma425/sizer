--[[
	SoundFX.lua
	ModuleScript: ReplicatedStorage.SoundFX

	One place for every sound in the game. Client scripts call
	SoundFX.play("name") for events (clicks, results, rewards, ...).

	The sounds below use files that ship with the Roblox client
	(rbxasset://sounds/...), so they work with no uploads. To use your own,
	upload audio in Creator Hub and swap `id` for "rbxassetid://<number>" --
	the rest of the game doesn't change. `speed` re-pitches a sound so one
	file can serve several events.

	A missing or failing sound is simply silent. SoundFX.setMuted(true)
	silences everything.
]]

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local SoundFX = {}

local PING = "rbxasset://sounds/electronicpingshort.wav"
local SWITCH = "rbxasset://sounds/switch.wav"
local CLICK = "rbxasset://sounds/clickfast.wav"
local BUTTON = "rbxasset://sounds/button.wav"
local FANFARE = "rbxasset://sounds/victory.wav"
local JUMP = "rbxasset://sounds/action_jump.mp3"
local OOF = "rbxasset://sounds/uuhhh.mp3"

SoundFX.Library = {
	click = { id = BUTTON, volume = 0.5 }, -- menu tiles, buttons
	start = { id = SWITCH, volume = 0.6, speed = 1.1 }, -- entering a game
	window = { id = SWITCH, volume = 0.35, speed = 1.5 }, -- a window opens
	lock = { id = CLICK, volume = 0.6 }, -- LOCK IN
	perfect = { id = FANFARE, volume = 0.5, speed = 1.15 }, -- 90+
	great = { id = PING, volume = 0.6, speed = 1.35 }, -- 70-89
	close = { id = PING, volume = 0.5, speed = 1.0 }, -- 40-69
	bad = { id = OOF, volume = 0.3, speed = 1.3 }, -- under 40
	combo = { id = PING, volume = 0.5, speed = 1.0 }, -- raised with the combo
	tick = { id = CLICK, volume = 0.35, speed = 0.9 }, -- last seconds of the 60s run
	timerEnd = { id = PING, volume = 0.7, speed = 0.55 }, -- time's up
	coin = { id = PING, volume = 0.5, speed = 1.8 }, -- playtime reward
	toast = { id = PING, volume = 0.3, speed = 1.5 }, -- small notifications
	rankUp = { id = FANFARE, volume = 0.7 },
	pet = { id = FANFARE, volume = 0.6, speed = 1.3 }, -- new pet unlocked
	equip = { id = SWITCH, volume = 0.5, speed = 1.25 },
	daily = { id = FANFARE, volume = 0.55, speed = 1.1 }, -- daily complete
	boing = { id = JUMP, volume = 0.6, speed = 1.7 }, -- trampolines
}

local muted = false
local lastPlayed = {} -- [name] = os.clock(), to stop identical sounds stacking

function SoundFX.setMuted(value)
	muted = value == true
end

-- opts: volume (multiplier), speed (multiplier)
function SoundFX.play(name, opts)
	local def = SoundFX.Library[name]
	if not def or muted then
		return
	end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < 0.06 then
		return
	end
	lastPlayed[name] = now

	opts = opts or {}
	local sound = Instance.new("Sound")
	sound.Name = "SFX_" .. name
	sound.SoundId = def.id
	sound.Volume = (def.volume or 0.5) * (opts.volume or 1)
	sound.PlaybackSpeed = (def.speed or 1) * (opts.speed or 1)
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 6)
end

return SoundFX
