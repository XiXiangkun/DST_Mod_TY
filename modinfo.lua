name = "田园风"
description = [[
国风田园模拟经营。
小岛耕作、商人交易、繁荣扩张、反哺饥荒。

当前测试内容：稻鱼共生。
]]
author = "你要帮帮威吊"
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
}
