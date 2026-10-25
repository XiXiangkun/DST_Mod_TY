local lang = GetModConfigData("language") or "zh"
TUNING.TY_LANG = lang

if lang == "en" then
	STRINGS.NAMES.TY_PADDY_WATER = "Paddy Water"
	STRINGS.NAMES.TY_RICE_SEEDS_1 = "Rice Seeds"
	STRINGS.NAMES.TY_RICE_SEEDS_2 = "Rice Seeds II"
	STRINGS.NAMES.TY_RICE_SEEDS_3 = "Rice Seeds III"
	STRINGS.NAMES.TY_RICE_SEEDS_4 = "Rice Seeds IV"
	STRINGS.NAMES.TY_RICE_SEEDS_5 = "Rice Seeds V"
	STRINGS.NAMES.TY_RICE_1 = "Rice"
	STRINGS.NAMES.TY_RICE_2 = "Rice II"
	STRINGS.NAMES.TY_RICE_3 = "Rice III"
	STRINGS.NAMES.TY_RICE_4 = "Rice IV"
	STRINGS.NAMES.TY_RICE_5 = "Rice V"
	STRINGS.NAMES.TY_RICE_PANICLE = "Rice Panicle"
	STRINGS.NAMES.TY_FISH_SEED = "Fish Fry"
	STRINGS.NAMES.TY_SHRIMP_SEED = "Shrimp Fry"
	STRINGS.NAMES.TY_GRASS_CARP = "Grass Carp"
	STRINGS.NAMES.TY_GRASS_CARP_COOKED = "Cooked Grass Carp"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_GRASS_CARP = "A plump carp from the paddy."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_GRASS_CARP_COOKED = "Grilled carp from the paddy."
	STRINGS.TY_ANNOUNCE_AQUA_HAS_FISH = "This paddy already has fish fry."
	STRINGS.TY_ANNOUNCE_AQUA_HAS_SHRIMP = "This paddy already has shrimp fry."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISH_SEED = "Release into a wet paddy. They'll multiply over time."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_SHRIMP_SEED = "Release into a wet paddy. They'll multiply over time."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_1 = "Rice seeds. Plant on wet paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_2 = "Second-stage rice seeds. Plant on wet paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_3 = "Third-stage rice seeds. Plant on wet paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_4 = "Fourth-stage rice seeds. Plant on wet paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_5 = "Fifth-stage rice seeds. Plant on wet paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_1 = "Young rice of the first lineage."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_2 = "Young rice of the second lineage."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_3 = "Young rice of the third lineage."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_4 = "Young rice of the fourth lineage."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_5 = "Hardy rice that regrows after harvest."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_PANICLE = "A placeholder rice panicle."
	STRINGS.NAMES.TY_FISHERMAN = "Fisherman"
	STRINGS.NAMES.TY_FISHERMAN_HOUSE = "Fisherman's House"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN = "He knows every ripple in these paddies."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN_HOUSE = {
		GENERIC = "A quiet house by the water.",
		BURNT = "The fisherman's home is gone.",
		FULL = "He's home for the night.",
		LIGHTSOUT = "Someone's in there, keeping quiet.",
	}
	STRINGS.TY_FISHERMAN_TALK_LOOKATWILSON = {
		"The catch looks fair today.",
		"Paddy water raises the fattest fish.",
		"Don't stir the mud too much.",
		"A still pond keeps secrets.",
		"Come back at dusk and I'll be gone.",
	}
	STRINGS.TY_FISHERMAN_TALK_GO_HOME = {
		"Light's failing. Time to head in.",
		"The fish can wait till morning.",
		"Home before the dark takes the path.",
	}
	STRINGS.NAMES.TY_FISHERMAN_SHOP = "Fish Stall"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN_SHOP = {
		GENERIC = "A little stall for today's catch.",
		UNLICENSED = "Needs a license before the fisherman will come.",
		CLOSED = "Not open for business yet.",
		OPEN = "Fresh from the paddies.",
		SOLDOUT = "Everything's gone for today.",
	}
	STRINGS.ACTIONS.TY_OPEN_FISH_SHOP = "Browse"
	STRINGS.ACTIONS.TY_LICENSE_FISH_SHOP = "Hang Sign"
	STRINGS.TY_FISHERMAN_SHOP_BUSY = "Someone's already buying."
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_BUSY = "A stall is already licensed."
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_NOHOUSE = "Build a fisherman's house first."
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_TOOFAR = "Too far from the fisherman's house."
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_NOITEM = "Need a transistor to hang the sign."
	STRINGS.TY_FISHERMAN_SHOP_TITLE = "Fish Stall"
	STRINGS.TY_FISHERMAN_SHOP_BUY = "Buy"
	STRINGS.TY_FISHERMAN_SHOP_STOCK = "Stock: %d"
	STRINGS.TY_FISHERMAN_SHOP_PRICE = "%d"
	STRINGS.TY_FISHERMAN_HOUSE_EXISTS = "There is already a fisherman's house."
	STRINGS.UI.CRAFTING.TY_FISHERMAN_HOUSE_EXISTS = "There is already a fisherman's house."
	STRINGS.NAMES.TY_FARMWIFE = "Farmwife"
	STRINGS.NAMES.TY_FARMHOUSE = "Farmhouse"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FARMWIFE = "She keeps the paddies in order."
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FARMHOUSE = {
		GENERIC = "A modest house among the fields.",
		BURNT = "The farmhouse is gone.",
		FULL = "She's home for the night.",
		LIGHTSOUT = "Someone's in there, keeping quiet.",
	}
	STRINGS.TY_FARMWIFE_TALK_LOOKATWILSON = {
		"The rice needs watching today.",
		"Don't trample the seedlings.",
		"A wet paddy grows the best grain.",
		"There's always more work in the fields.",
		"Come back at dusk and I'll be gone.",
	}
	STRINGS.TY_FARMWIFE_TALK_GO_HOME = {
		"Light's failing. Time to head in.",
		"The fields can wait till morning.",
		"Home before the dark takes the path.",
	}
	STRINGS.NAMES.TY_TUGOU = "Yellow Dog"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_TUGOU = "A big farm dog. It keeps monsters away."
	STRINGS.NAMES.TY_COIN = "Coin"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_COIN = "A shiny coin. Good for trading."
	STRINGS.NAMES.TY_MINE = "Quarry"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_MINE = {
		GENERIC = "A stone quarry.",
		READY = "There's stone ready to be mined.",
		DEPLETED = "Nothing worth picking at right now.",
	}
	STRINGS.NAMES.TY_PEACHTREE = "Peach Tree"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PEACHTREE = {
		GENERIC = "A peach tree.",
		CHOPPED = "Just a stump now.",
		BURNING = "It's on fire!",
	}
	STRINGS.NAMES.TY_WILLOW = "Willow"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_WILLOW = {
		GENERIC = "A willow tree.",
		CHOPPED = "Just a stump now.",
		BURNING = "It's on fire!",
	}
	STRINGS.NAMES.TY_PINE = "Pine"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PINE = {
		GENERIC = "A pine tree.",
		CHOPPED = "Just a stump now.",
		BURNING = "It's on fire!",
	}
	STRINGS.NAMES.TY_PLOUGH = "Plough"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PLOUGH = "Equip it and walk to till dry paddies."
	STRINGS.ACTIONS.TY_STOP_PLOUGH = "Put Away"
else
	STRINGS.NAMES.TY_PADDY_WATER = "水田水面"
	STRINGS.NAMES.TY_RICE_SEEDS_1 = "水稻种子"
	STRINGS.NAMES.TY_RICE_SEEDS_2 = "二期水稻种子"
	STRINGS.NAMES.TY_RICE_SEEDS_3 = "三期水稻种子"
	STRINGS.NAMES.TY_RICE_SEEDS_4 = "四期水稻种子"
	STRINGS.NAMES.TY_RICE_SEEDS_5 = "五期水稻种子"
	STRINGS.NAMES.TY_RICE_1 = "水稻"
	STRINGS.NAMES.TY_RICE_2 = "二期水稻"
	STRINGS.NAMES.TY_RICE_3 = "三期水稻"
	STRINGS.NAMES.TY_RICE_4 = "四期水稻"
	STRINGS.NAMES.TY_RICE_5 = "五期水稻"
	STRINGS.NAMES.TY_RICE_PANICLE = "稻穗"
	STRINGS.NAMES.TY_FISH_SEED = "鱼苗"
	STRINGS.NAMES.TY_SHRIMP_SEED = "虾苗"
	STRINGS.NAMES.TY_GRASS_CARP = "草鱼"
	STRINGS.NAMES.TY_GRASS_CARP_COOKED = "熟草鱼"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_GRASS_CARP = "水田里养出来的肥草鱼。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_GRASS_CARP_COOKED = "烤好的草鱼，香气扑鼻。"
	STRINGS.TY_ANNOUNCE_AQUA_HAS_FISH = "这块水田已经有鱼苗了。"
	STRINGS.TY_ANNOUNCE_AQUA_HAS_SHRIMP = "这块水田已经有虾苗了。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISH_SEED = "放入湿田后会慢慢繁殖，干涸时会蹦出来。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_SHRIMP_SEED = "放入湿田后会慢慢繁殖，干涸时会蹦出来。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_1 = "水稻种子，可种在湿田上。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_2 = "二期水稻种子，可种在湿田上。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_3 = "三期水稻种子，可种在湿田上。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_4 = "四期水稻种子，可种在湿田上。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_SEEDS_5 = "五期水稻种子，可种在湿田上。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_1 = "一期水稻。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_2 = "二期水稻。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_3 = "三期水稻。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_4 = "四期水稻。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_5 = "五期水稻，收获后会重新生长。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_RICE_PANICLE = "稻穗（占位）。"
	STRINGS.NAMES.TY_FISHERMAN = "渔夫"
	STRINGS.NAMES.TY_FISHERMAN_HOUSE = "渔夫的家"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN = "他熟悉这片水田的每一道涟漪。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN_HOUSE = {
		GENERIC = "水边一间安静的小屋。",
		BURNT = "渔夫的家没了。",
		FULL = "他已经回家歇着了。",
		LIGHTSOUT = "屋里有人，只是灯没亮。",
	}
	STRINGS.TY_FISHERMAN_TALK_LOOKATWILSON = {
		"今天渔获还算过得去。",
		"稻田边的水最肥。",
		"别把泥搅得太浑。",
		"静水才养得住鱼。",
		"天黑我就回家了，你白天再来。",
	}
	STRINGS.TY_FISHERMAN_TALK_GO_HOME = {
		"天色不早了，该回家了。",
		"鱼明天再钓。",
		"趁还能看清路，赶紧回去。",
	}
	STRINGS.NAMES.TY_FISHERMAN_SHOP = "渔夫小摊"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FISHERMAN_SHOP = {
		GENERIC = "卖当日渔获的小铺面。",
		UNLICENSED = "还没挂牌，渔夫不会来。",
		CLOSED = "还未开张。",
		OPEN = "水田里刚捞上来的鲜货。",
		SOLDOUT = "今天的货卖光了。",
	}
	STRINGS.ACTIONS.TY_OPEN_FISH_SHOP = "选购"
	STRINGS.ACTIONS.TY_LICENSE_FISH_SHOP = "挂牌"
	STRINGS.TY_FISHERMAN_SHOP_BUSY = "有人在买。"
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_BUSY = "已经有挂牌的铺面了。"
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_NOHOUSE = "先建一座渔夫小屋。"
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_TOOFAR = "离渔夫小屋太远了。"
	STRINGS.TY_FISHERMAN_SHOP_LICENSE_NOITEM = "需要一个电子元件才能挂牌。"
	STRINGS.TY_FISHERMAN_SHOP_TITLE = "渔夫小摊"
	STRINGS.TY_FISHERMAN_SHOP_BUY = "购买"
	STRINGS.TY_FISHERMAN_SHOP_STOCK = "库存：%d"
	STRINGS.TY_FISHERMAN_SHOP_PRICE = "%d"
	STRINGS.TY_FISHERMAN_HOUSE_EXISTS = "已经有一座渔夫小屋了。"
	STRINGS.UI.CRAFTING.TY_FISHERMAN_HOUSE_EXISTS = "已经有一座渔夫小屋了。"
	STRINGS.NAMES.TY_FARMWIFE = "农妇"
	STRINGS.NAMES.TY_FARMHOUSE = "农家"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FARMWIFE = "她把这片田地照料得井井有条。"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_FARMHOUSE = {
		GENERIC = "田边一间朴素的屋子。",
		BURNT = "农家没了。",
		FULL = "她已经回家歇着了。",
		LIGHTSOUT = "屋里有人，只是灯没亮。",
	}
	STRINGS.TY_FARMWIFE_TALK_LOOKATWILSON = {
		"今天得盯着稻子。",
		"别踩着秧苗。",
		"湿田才长得出好粮。",
		"田里的活永远做不完。",
		"天黑我就回家了，你白天再来。",
	}
	STRINGS.TY_FARMWIFE_TALK_GO_HOME = {
		"天色不早了，该回家了。",
		"田明天再种。",
		"趁还能看清路，赶紧回去。",
	}
	STRINGS.NAMES.TY_TUGOU = "大黄狗"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_TUGOU = "田边看家的大黄狗，专咬不友好的怪物。"
	STRINGS.NAMES.TY_COIN = "金币"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_COIN = "亮闪闪的金币，可以用来交易。"
	STRINGS.NAMES.TY_MINE = "矿场"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_MINE = {
		GENERIC = "一座矿场。",
		READY = "可以开采了。",
		DEPLETED = "现在没什么可挖的。",
	}
	STRINGS.NAMES.TY_PEACHTREE = "桃树"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PEACHTREE = {
		GENERIC = "一棵桃树。",
		CHOPPED = "只剩树桩了。",
		BURNING = "着火了！",
	}
	STRINGS.NAMES.TY_WILLOW = "柳树"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_WILLOW = {
		GENERIC = "一棵柳树。",
		CHOPPED = "只剩树桩了。",
		BURNING = "着火了！",
	}
	STRINGS.NAMES.TY_PINE = "松树"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PINE = {
		GENERIC = "一棵松树。",
		CHOPPED = "只剩树桩了。",
		BURNING = "着火了！",
	}
	STRINGS.NAMES.TY_PLOUGH = "犁"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.TY_PLOUGH = "装备后走动即可把脚下开成干涸水田。"
	STRINGS.ACTIONS.TY_STOP_PLOUGH = "收起犁"
end
