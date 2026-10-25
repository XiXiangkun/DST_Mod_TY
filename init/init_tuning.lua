TUNING.TY_PADDY_WATER_LOSS_PER_DAY = 0.2
TUNING.TY_PADDY_SUMMER_LOSS_MULT = 1.5
-- 满雨强时每天 +1.0（再乘 precipitationrate）；明显强于浇水壶性价比
TUNING.TY_PADDY_RAIN_GAIN_PER_DAY = 1.0
-- 浇水壶每次给整片水域 +0.125（干→满约 8 次）
TUNING.TY_PADDY_CAN_WATER_AMOUNT = 0.125
-- 达到该水位才切换湿田外观 / 水稻恢复生长（内部仍累计更低水量）
TUNING.TY_PADDY_WET_THRESHOLD = 0.01

TUNING.TY_PADDY_CREATURE_RIPPLE = GetModConfigData("paddy_creature_ripple")
if TUNING.TY_PADDY_CREATURE_RIPPLE == nil then
	TUNING.TY_PADDY_CREATURE_RIPPLE = true
end

-- 水稻：种下到 tall 共 5 天，seed/sprout/small/med 各 1.25 天
TUNING.TY_RICE_GROW_DAYS = 5
TUNING.TY_RICE_STAGE_TIME = (TUNING.TOTAL_DAY_TIME or 480) * (TUNING.TY_RICE_GROW_DAYS / 4)

-- 冬天生长速度倍率（1~4 期；5 期恒为 1）
TUNING.TY_RICE_WINTER_SPEED = {
	[1] = 0.2,
	[2] = 0.3,
	[3] = 0.5,
	[4] = 0.8,
	[5] = 1,
}

-- 水田养殖（一格一塘）
-- 繁殖：湿田每 1 天 +1；鱼上限 4（约 4 天满）、虾上限 2（约 2 天满）
TUNING.TY_AQUA_BREED_TIME = (TUNING.TOTAL_DAY_TIME or 480)
TUNING.TY_AQUA_FISH_MAX = 4
TUNING.TY_AQUA_SHRIMP_MAX = 2
TUNING.TY_AQUA_FISH_DROP = "ty_grass_carp"
TUNING.TY_AQUA_SHRIMP_DROP = "wobster_sheller_land"

-- 渔夫
TUNING.TY_FISHERMAN_WALK_SPEED = 3
TUNING.TY_FISHERMAN_RUN_SPEED = 5
TUNING.TY_FISHERMAN_WANDER_DIST = 16
TUNING.TY_FISHERMAN_LEASH_MAX = 24
TUNING.TY_FISHERMAN_LEASH_RETURN = 12
TUNING.TY_FISHERMAN_FACE_DIST = 4
TUNING.TY_FISHERMAN_KEEP_FACE_DIST = 8
TUNING.TY_FISHERMAN_HOUSE_RESPAWN = (TUNING.TOTAL_DAY_TIME or 480) * 4

-- 渔夫铺面
TUNING.TY_FISHERMAN_SHOP_DIST = 8
TUNING.TY_FISHERMAN_SHOP_DIST_FALLBACKS = { 8, 6, 4, 2 }
TUNING.TY_FISHERMAN_SHOP_LOCK_TIME = 45
TUNING.TY_FISHERMAN_SHOP_STALL_DIST = 1.4
TUNING.TY_FISHERMAN_SHOP_ARRIVE_DIST = 2.2
TUNING.TY_FISHERMAN_SHOP_INTERACT_DIST = 3.5
TUNING.TY_FISHERMAN_SHOP_MAX_DIST = 60
TUNING.TY_FISHERMAN_SHOP_CURRENCY = "goldnugget"
TUNING.TY_FISHERMAN_SHOP_LICENSE_ITEM = "transistor"
TUNING.TY_FISHERMAN_SHOP_LICENSE_COST = 1
TUNING.TY_FISHERMAN_SHOP_COMMON_SLOTS = 10
TUNING.TY_FISHERMAN_SHOP_RARE_SLOTS = 2
TUNING.TY_FISHERMAN_SHOP_COLS = 4
TUNING.TY_FISHERMAN_SHOP_ROWS = 3
-- 普通池 / 稀有池：price=金块单价，stock=出现时库存
TUNING.TY_FISHERMAN_SHOP_COMMON = {
	{ prefab = "oceanfish_small_1_inv", price = 1, stock = 3 },
	{ prefab = "oceanfish_small_2_inv", price = 1, stock = 2 },
	{ prefab = "oceanfish_small_3_inv", price = 1, stock = 3 },
	{ prefab = "oceanfish_small_4_inv", price = 1, stock = 2 },
	{ prefab = "fish", price = 1, stock = 3 },
	{ prefab = "fish_cooked", price = 1, stock = 2 },
	{ prefab = "fishmeat_small", price = 1, stock = 3 },
	{ prefab = "fishmeat_small_cooked", price = 1, stock = 2 },
	{ prefab = "fishmeat_small_dried", price = 2, stock = 2 },
	{ prefab = "fishmeat", price = 2, stock = 2 },
	{ prefab = "fishmeat_cooked", price = 2, stock = 2 },
	{ prefab = "fishmeat_dried", price = 3, stock = 1 },
	{ prefab = "eel", price = 2, stock = 2 },
	{ prefab = "eel_cooked", price = 2, stock = 1 },
}
TUNING.TY_FISHERMAN_SHOP_RARE = {
	{ prefab = "ty_fish_seed", price = 5, stock = 1 },
	{ prefab = "ty_shrimp_seed", price = 5, stock = 1 },
}

-- 农妇 / 农家
TUNING.TY_FARMWIFE_WALK_SPEED = 3
TUNING.TY_FARMWIFE_RUN_SPEED = 5
TUNING.TY_FARMWIFE_WANDER_DIST = 16
TUNING.TY_FARMWIFE_LEASH_MAX = 24
TUNING.TY_FARMWIFE_LEASH_RETURN = 12
TUNING.TY_FARMWIFE_FACE_DIST = 4
TUNING.TY_FARMWIFE_KEEP_FACE_DIST = 8
TUNING.TY_FARMHOUSE_RESPAWN = (TUNING.TOTAL_DAY_TIME or 480) * 4

-- 大黄狗
TUNING.TY_TUGOU_HEALTH = 300
TUNING.TY_TUGOU_DAMAGE = 25
TUNING.TY_TUGOU_ATTACK_PERIOD = 2
TUNING.TY_TUGOU_ATTACK_RANGE = 3
TUNING.TY_TUGOU_HIT_RANGE = 4.5
TUNING.TY_TUGOU_HIT_RECOVERY = 1
TUNING.TY_TUGOU_WALK_SPEED = 4
TUNING.TY_TUGOU_RUN_SPEED = 8
TUNING.TY_TUGOU_SCALE = 1.35
TUNING.TY_TUGOU_TARGET_DIST = 16
TUNING.TY_TUGOU_KEEP_TARGET_DIST = 24
TUNING.TY_TUGOU_WANDER_DIST = 20

-- 矿场：平时不可采；每 2 天可挖 10~13 次（燧石或石头）
TUNING.TY_MINE_REGEN_DAYS = 2
TUNING.TY_MINE_LOOT_MIN = 10
TUNING.TY_MINE_LOOT_MAX = 13

-- 犁：持犁移速倍率、攻击伤害（占手）
TUNING.TY_PLOUGH_SPEED_MULT = 0.6
TUNING.TY_PLOUGH_DAMAGE = 17
