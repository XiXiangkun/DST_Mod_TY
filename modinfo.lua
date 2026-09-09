--[[
	归园田居 modinfo
	配置项用 CONFIG_SCHEMA 集中维护：加分区、改选项、补多语言文案都在本文件完成。
]]

local TY_LANGUAGE = "en"
if locale == "zh" or locale == "zht" or locale == "zhr" then
	TY_LANGUAGE = "zh"
else
	TY_LANGUAGE = "en"
end

name = "归田录"
author = "素冥, 你要帮帮威吊"
version = "1.0.0"

local info_version = "[ Version " .. version .. " ]\n"
description = info_version .. [[
国风田园模拟经营。
小岛耕作、商人交易、繁荣扩张、反哺饥荒。

当前测试内容：稻鱼共生。
]]

if TY_LANGUAGE == "en" then
	name = "Return to the Fields"
	description = info_version .. [[
A Chinese pastoral sim for DST:
island farming, traders, prosperity, and feedback into the survival loop.

Current test content: rice–fish coexistence.
]]
end

forumthread = ""
api_version = 10
api_version_dst = 10
priority = 0

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

server_filter_tags = TY_LANGUAGE == "zh" and { "ty", "归园田居" } or { "ty", "fields" }

--------------------------------------------------------------------------
-- 配置构建工具（参考 Montfluv 写法）

local function get_lang_text(text_map, lang)
	return (text_map and text_map[lang]) or (text_map and text_map.en) or ""
end

local function make_title(label)
	return {
		name = "Title",
		label = label or "",
		options = { { description = "", data = "" } },
		default = "",
	}
end

local CONFIG_TEXT = {
	sections = {
		general = { zh = "通用设置", en = "General" },
		display = { zh = "显示设置", en = "Display" },
	},
	labels = {
		language = { zh = "语言", en = "Language" },
		paddy_creature_ripple = { zh = "水田生物波纹", en = "Creature Ripples on Paddy" },
	},
	hovers = {
		language = {
			zh = "模组内文本语言（名称、检查描述等）",
			en = "In-mod text language (names, inspect lines, etc.)",
		},
		paddy_creature_ripple = {
			zh = "地面生物站在湿田上时，脚下是否显示波纹（掉落物漂浮波纹不受影响）",
			en = "Show foot ripples for ground creatures on wet paddies (item float ripples are unaffected).",
		},
	},
}

-- 新增配置：在 SCHEMA 加一项，并在 CONFIG_TEXT 补 label/hover（及 options 文案）
local CONFIG_SCHEMA = {
	{ type = "section", key = "general" },
	{
		type = "setting",
		name = "language",
		default = { zh = "zh", en = "en" },
		options = {
			{ data = "zh", text = { zh = "中文", en = "Chinese" } },
			{ data = "en", text = { zh = "英文", en = "English" } },
		},
	},
	{ type = "spacer" },
	{ type = "section", key = "display" },
	{
		type = "setting",
		name = "paddy_creature_ripple",
		default = true,
		options = {
			{
				data = true,
				text = { zh = "开启(默认)", en = "On (Default)" },
				hover = {
					zh = "湿田上的地面生物显示脚下波纹",
					en = "Ground creatures on wet paddies show foot ripples",
				},
			},
			{
				data = false,
				text = { zh = "关闭", en = "Off" },
				hover = {
					zh = "不显示生物波纹",
					en = "Hide creature ripples",
				},
			},
		},
	},
	{ type = "spacer" },
}

local function build_configuration_options(lang)
	local options = {}
	for i = 1, #CONFIG_SCHEMA do
		local item = CONFIG_SCHEMA[i]
		if item.type == "spacer" then
			options[#options + 1] = make_title("")
		elseif item.type == "section" then
			options[#options + 1] = make_title(get_lang_text(CONFIG_TEXT.sections[item.key], lang))
		elseif item.type == "setting" then
			local setting_options = {}
			local raw_opts = item.options or {}
			for j = 1, #raw_opts do
				local opt = raw_opts[j]
				local entry = {
					description = get_lang_text(opt.text, lang),
					data = opt.data,
				}
				if opt.hover ~= nil then
					entry.hover = get_lang_text(opt.hover, lang)
				end
				setting_options[#setting_options + 1] = entry
			end
			local default_value = item.default
			if item.name == "language" then
				default_value = item.default[lang] or item.default.en
			end
			options[#options + 1] = {
				name = item.name,
				label = get_lang_text(CONFIG_TEXT.labels[item.name], lang),
				hover = get_lang_text(CONFIG_TEXT.hovers[item.name], lang),
				options = setting_options,
				default = default_value,
			}
		end
	end
	return options
end

configuration_options = build_configuration_options(TY_LANGUAGE)
