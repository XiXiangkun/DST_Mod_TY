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
