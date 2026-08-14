local lang = GetModConfigData("language") or "zh"
TUNING.TY_LANG = lang

local STR = {
	zh = {
		NAMES = {
			TY_PADDY_WATER = "水田水面",
		},
		CHARACTERS = {
			GENERIC = {
				DESCRIBE = {
					TY_PADDY_WATER = "田里的水，会慢慢干下去。",
				},
			},
		},
	},
	en = {
		NAMES = {
			TY_PADDY_WATER = "Paddy Water",
		},
		CHARACTERS = {
			GENERIC = {
				DESCRIBE = {
					TY_PADDY_WATER = "Flooded field water. It will dry out over time.",
				},
			},
		},
	},
}

local t = STR[lang] or STR.zh

for k, v in pairs(t.NAMES) do
	STRINGS.NAMES[k] = v
end
for k, v in pairs(t.CHARACTERS.GENERIC.DESCRIBE) do
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[k] = v
end
