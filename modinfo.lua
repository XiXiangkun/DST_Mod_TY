name = "归园田居"
description = [[
国风田园模拟经营。
小岛耕作、商人交易、繁荣扩张、反哺饥荒。

当前测试内容：稻鱼共生。
]]
author = "素冥；你要帮帮威吊"
version = "0.0.1"
forumthread = ""

api_version = 10
api_version_dst = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

priority = 0
server_filter_tags = { "ty" }

configuration_options = {
	{
		name = "language",
		label = "语言 / Language",
		hover = "模组内文本语言",
		options = {
			{ description = "中文", data = "zh" },
			{ description = "English", data = "en" },
		},
		default = "zh",
	},
	{
		name = "paddy_creature_ripple",
		label = "水田生物波纹 / Creature ripples",
		hover = "地面生物站在湿田上时，脚下是否显示波纹",
		options = {
			{ description = "开启 / On", data = true, hover = "湿田上的地面生物显示脚下波纹" },
			{ description = "关闭 / Off", data = false, hover = "不显示生物波纹（掉落物漂浮波纹不受影响）" },
		},
		default = true,
	},
}
