--[[
	MapConfig.lua
	ModuleScript: ReplicatedStorage.MapConfig

	Shared world-space constants so MapBuilder (server) and
	ScaleGuesserClient (client) agree on where the game arena sits,
	without hardcoding the same numbers in two places.
]]

return {
	HubCenter = Vector3.new(0, 0, 0),
	HubRadius = 30,

	ArenaCenter = Vector3.new(0, 0, 160),
	ArenaRadius = 30,

	ParkourOrigin = Vector3.new(160, 0, 0),
	PlazaCenter = Vector3.new(-160, 0, 0),

	-- Top surface height of the hub/arena/path platforms. Reference and
	-- target parts should sit with their base at this height.
	GroundY = 1,
}
