--[[
	MapConfig.lua
	ModuleScript: ReplicatedStorage.MapConfig

	Shared world-space constants so MapBuilder (server) and
	ScaleGuesserClient (client) agree on where the Scale Stage sits.
]]

return {
	-- Center of the Scale Stage (north of the spawn plaza).
	ArenaCenter = Vector3.new(0, 0, 77),
	ArenaRadius = 22,

	-- Top surface of the stage floor; the reference/target parts stand on it.
	GroundY = 3,
}
