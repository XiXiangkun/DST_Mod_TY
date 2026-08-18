-- 水田地皮：类似耕地，不可挖取
-- TY_PADDY      偏湿 100%~50%（noise_ty_paddy）
-- TY_PADDY_50   偏干 50%~湿阈值（noise_ty_paddy_50）
-- TY_PADDY_DRY  干涸（官方 quagmire_parkstone_noise）

if WORLD_TILES.TY_PADDY ~= nil then
	return
end

local function AddWetPaddyTile(id, ground_name, noise)
	AddTile(
		id,
		"LAND",
		{ ground_name = ground_name },
		{
			name = "pebble",
			noise_texture = noise,
			runsound = "dontstarve/movement/run_marsh",
			walksound = "dontstarve/movement/walk_marsh",
			snowsound = "dontstarve/movement/run_ice",
			mudsound = "dontstarve/movement/run_mud",
			cannotbedug = true,
		},
		{
			name = "map_edge",
			noise_texture = noise,
		}
	)
end

AddWetPaddyTile("TY_PADDY", "Ty Paddy", "noise_ty_paddy")
AddWetPaddyTile("TY_PADDY_50", "Ty Paddy 50", "noise_ty_paddy_50")

AddTile(
	"TY_PADDY_DRY",
	"LAND",
	{ ground_name = "Ty Paddy Dry" },
	{
		name = "pebble",
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
ChangeTileRenderOrder(WORLD_TILES.TY_PADDY_50, WORLD_TILES.FARMING_SOIL)
ChangeTileRenderOrder(WORLD_TILES.TY_PADDY_DRY, WORLD_TILES.FARMING_SOIL)
