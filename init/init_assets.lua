GLOBAL.SH_ITEMS_ATLAS = MODROOT.."images/inventoryimages/ty_items.xml"

Assets = {
	Asset("ATLAS", "images/inventoryimages/ty_items.xml"),
	Asset("IMAGE", "images/inventoryimages/ty_items.tex"),
}

local ITEMS = {
	"ty_grass_carp",
	"ty_grass_carp_cooked",
	"ty_fish_seed",
	"ty_shrimp_seed",
}

-- 常规物品
table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/ty_items.xml", 256))
for _, v in ipairs(ITEMS) do
	RegisterInventoryItemAtlas("images/inventoryimages/ty_items.xml", v..".tex")
end