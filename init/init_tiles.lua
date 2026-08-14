-- 水田地皮：类似耕地，不可挖取
-- TY_PADDY      有水/开垦后湿田（noise_ty_paddy）
-- TY_PADDY_DRY  干涸（官方 quagmire_parkstone_noise）

if WORLD_TILES.TY_PADDY ~= nil then
	return
end

AddTile(
	"TY_PADDY",
	"LAND",
	{ ground_name = "Ty Paddy" },
	{
		name = "pebble",
		noise_texture = "noise_ty_paddy",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
		cannotbedug = true,
	},
	{
		name = "map_edge",
		noise_texture = "noise_ty_paddy",
	}
)

AddTile(
	"TY_PADDY_DRY",
	"LAND",
	{ ground_name = "Ty Paddy Dry" },
	{
		name = "farmsoil",
		noise_texture = "quagmire_parkstone_noise",
		runsound = "dontstarve/movement/run_dirt",
		walksound = "dontstarve/movement/walk_dirt",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
		cannotbedug = true,
	},
	{
		name = "map_edge",
		noise_texture = "quagmire_parkstone_mini",
	}
)

ChangeTileRenderOrder(WORLD_TILES.TY_PADDY, WORLD_TILES.FARMING_SOIL)
ChangeTileRenderOrder(WORLD_TILES.TY_PADDY_DRY, WORLD_TILES.FARMING_SOIL)
