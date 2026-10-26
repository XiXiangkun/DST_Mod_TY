-- 田园(TY) 测试命令
-- c_ty_paddy()           脚下开垦水田（并入连通水域，水位取平均）
-- c_ty_paddy_set(0.6)    设置脚下整片水域水位 0~1
-- c_ty_paddy_set(0)      整片干涸
-- c_ty_paddy_info()      打印脚下水位/连通格数
-- c_ty_fish_fx()         脚下生成游鱼特效（测试分层/动画）
-- c_ty_shrimp_fx()       脚下生成游虾特效（测试分层/动画）
-- c_ty_fish_seed()       给予鱼苗 x10
-- c_ty_shrimp_seed()     给予虾苗 x10
-- c_ty_grass_carp()      给予生草鱼 x1（可传数量）
-- c_ty_grass_carp_cooked() 给予熟草鱼 x1（可传数量）
-- c_ty_rice_seeds()      给予 5 期水稻种子各 10
-- c_ty_rice_seeds(3)     只给三期种子 10
-- c_ty_rice(5)           脚下生成对应期成熟水稻（可采）
-- c_ty_rice(5, 1)        脚下生成对应期指定阶段 1~5
-- c_ty_fisherman_house() 身前放置渔夫小屋（世界唯一，会向世界组件注册）
-- c_ty_fisherman_shop()  身前放置铺面（未挂牌）
-- c_ty_license_shop()    给附近最近铺面强制挂牌（调试，不耗电子元件）
-- c_ty_farmhouse()       身前放置农家（白天会放出农妇）
-- c_ty_tugou()           身前生成大黄狗
-- c_ty_mine()            身前生成矿场（默认不可采，2 天后可采）
-- c_ty_forestfarm()      身前生成林场（默认不可采，2 天后可采）
-- c_ty_peachtree()       身前生成桃树
-- c_ty_willow()          身前生成柳树
-- c_ty_pine()            身前生成松树
-- c_ty_plough()          给予犁 x1

function c_ty_paddy()
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	TheWorld.components.ty_paddy_manager:TillAtPoint(x, y, z)
	print("[ty] tilled paddy at feet, water=100%")
end

function c_ty_paddy_set(water)
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	water = water or 1
	local x, y, z = player.Transform:GetWorldPosition()
	if TheWorld.components.ty_paddy_manager:GetWaterAtPoint(x, y, z) == nil then
		TheWorld.components.ty_paddy_manager:TillAtPoint(x, y, z)
	end
	TheWorld.components.ty_paddy_manager:SetWaterAtPoint(x, y, z, water)
	print(string.format("[ty] paddy water set to %.1f%%", water * 100))
end

function c_ty_paddy_info()
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	local water = TheWorld.components.ty_paddy_manager:GetWater(tx, ty)
	local tier = TheWorld.components.ty_paddy_manager:GetTier(tx, ty)
	local body = TheWorld.components.ty_paddy_manager:CollectBodyKeys(tx, ty)
	local body_n = body ~= nil and #body or 0
	local aqua = TheWorld.components.ty_paddy_manager:GetAqua(tx, ty)
	local aqua_str = "none"
	if aqua ~= nil then
		aqua_str = string.format("%s count=%d breed=%.1fs", tostring(aqua.kind), aqua.count or 0, aqua.breed_t or 0)
	end
	local tile = TheWorld.Map:GetTile(tx, ty)
	local PaddyTiles = require("ty_paddy_tiles")
	local tile_name = PaddyTiles.GetTileName(tile)
	print(string.format(
		"[ty] tile=(%d,%d) map_tile=%s water=%s tier=%s body=%d aqua=%s raining=%s rate=%.2f",
		tx, ty, tile_name,
		water ~= nil and string.format("%.1f%%", water * 100) or "n/a",
		tostring(tier),
		body_n,
		aqua_str,
		tostring(TheWorld.state.israining),
		TheWorld.state.precipitationrate or 0
	))
end

local function SpawnTyFxAtFeet(prefab)
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local cx, cy, cz = x, 0, z
	if TheWorld ~= nil and TheWorld.Map ~= nil then
		local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
		cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
	end
	local fx = SpawnPrefab(prefab)
	if fx == nil then
		print("[ty] failed to spawn " .. prefab)
		return
	end
	fx.Transform:SetPosition(cx, cy, cz)
	print(string.format("[ty] spawned %s at (%.1f, %.1f, %.1f)", prefab, cx, cy, cz))
end

function c_ty_fish_fx()
	SpawnTyFxAtFeet("ty_fish_fx")
end

function c_ty_shrimp_fx()
	SpawnTyFxAtFeet("ty_shrimp_fx")
end

local function GiveTyItem(prefab, count)
	local player = ConsoleCommandPlayer()
	if player == nil or player.components.inventory == nil then
		return
	end
	local item = SpawnPrefab(prefab)
	if item == nil then
		print("[ty] failed to spawn " .. prefab)
		return
	end
	count = count or 10
	if item.components.stackable ~= nil then
		item.components.stackable:SetStackSize(count)
	end
	player.components.inventory:GiveItem(item)
	print(string.format("[ty] gave %s x%d", prefab, count))
end

function c_ty_fish_seed(n)
	GiveTyItem("ty_fish_seed", n or 10)
end

function c_ty_shrimp_seed(n)
	GiveTyItem("ty_shrimp_seed", n or 10)
end

function c_ty_grass_carp(n)
	GiveTyItem("ty_grass_carp", n or 1)
end

function c_ty_grass_carp_cooked(n)
	GiveTyItem("ty_grass_carp_cooked", n or 1)
end

function c_ty_rice_seeds(stage)
	local player = ConsoleCommandPlayer()
	if player == nil or player.components.inventory == nil then
		return
	end

	local stages = stage ~= nil and { tonumber(stage) } or { 1, 2, 3, 4, 5 }
	for _, s in ipairs(stages) do
		if s == nil or s < 1 or s > 5 then
			print("[ty] rice seed stage must be 1~5")
		else
			local prefab = "ty_rice_seeds_" .. s
			local item = SpawnPrefab(prefab)
			if item ~= nil then
				if item.components.stackable ~= nil then
					item.components.stackable:SetStackSize(10)
				end
				player.components.inventory:GiveItem(item)
				print("[ty] gave " .. prefab .. " x10")
			end
		end
	end
end

function c_ty_rice(tier, stage)
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	tier = tonumber(tier) or 1
	stage = tonumber(stage) or 5
	if tier < 1 or tier > 5 then
		print("[ty] rice tier must be 1~5")
		return
	end
	if stage < 1 or stage > 5 then
		print("[ty] rice stage must be 1~5 (seed..tall)")
		return
	end

	local x, y, z = player.Transform:GetWorldPosition()
	if TheWorld ~= nil and TheWorld.components.ty_paddy_manager ~= nil then
		if TheWorld.components.ty_paddy_manager:GetWaterAtPoint(x, y, z) == nil then
			TheWorld.components.ty_paddy_manager:TillAtPoint(x, y, z)
		end
	end

	local inst = SpawnPrefab("ty_rice_" .. tier)
	if inst == nil then
		print("[ty] failed to spawn ty_rice_" .. tier)
		return
	end
	inst.Transform:SetPosition(x, 0, z + 1)
	if inst.components.growable ~= nil then
		inst.components.growable:SetStage(stage)
		if stage < 5 then
			inst.components.growable:StartGrowing()
		else
			inst.components.growable:StopGrowing()
		end
	end
	inst:PushEvent("on_planted")
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z + 1)
	local water = TheWorld.components.ty_paddy_manager ~= nil
		and TheWorld.components.ty_paddy_manager:GetWater(tx, ty)
	TheWorld:PushEvent("ty_paddy_wetness_changed", {
		tx = tx,
		ty = ty,
		wet = water ~= nil and water > 0,
	})
	print(string.format("[ty] spawned ty_rice_%d stage=%d", tier, stage))
end

function c_ty_fisherman_house()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local mgr = TheWorld.components.ty_fisherman_manager
	if mgr ~= nil and mgr:HasHouse() then
		print("[ty] fisherman house already exists")
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local house = SpawnPrefab("ty_fisherman_house")
	if house == nil then
		print("[ty] failed to spawn ty_fisherman_house")
		return
	end
	house.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned ty_fisherman_house")
end

function c_ty_fisherman_shop()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local shop = SpawnPrefab("ty_fisherman_shop")
	if shop == nil then
		print("[ty] failed to spawn ty_fisherman_shop")
		return
	end
	shop.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned ty_fisherman_shop (unlicensed)")
end

function c_ty_license_shop()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local shop = FindEntity(player, 12, nil, { "ty_fisherman_shop" })
	if shop == nil then
		print("[ty] no ty_fisherman_shop nearby")
		return
	end
	local mgr = TheWorld.components.ty_fisherman_manager
	if mgr == nil then
		print("[ty] no ty_fisherman_manager")
		return
	end
	if shop.components.ty_fisherman_shop ~= nil then
		shop.components.ty_fisherman_shop:SetLicensed(true)
	end
	TheWorld:PushEvent("ty_register_licensed_shop", shop)
	print("[ty] licensed shop (debug, free)")
end

function c_ty_farmhouse()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local house = SpawnPrefab("ty_farmhouse")
	if house == nil then
		print("[ty] failed to spawn ty_farmhouse")
		return
	end
	house.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned ty_farmhouse")
end

function c_ty_tugou()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local dog = SpawnPrefab("ty_tugou")
	if dog == nil then
		print("[ty] failed to spawn ty_tugou")
		return
	end
	dog.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned ty_tugou")
end

local function c_ty_spawn_resource_farm(prefab)
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local farm = SpawnPrefab(prefab)
	if farm == nil then
		print("[ty] failed to spawn " .. prefab)
		return
	end
	farm.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned " .. prefab .. " (depleted)")
end

function c_ty_mine()
	c_ty_spawn_resource_farm("ty_mine")
end

function c_ty_forestfarm()
	c_ty_spawn_resource_farm("ty_forestfarm")
end

local function c_ty_spawn_tree(prefab)
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = (player.Transform:GetRotation() or 0) * DEGREES
	local tree = SpawnPrefab(prefab)
	if tree == nil then
		print("[ty] failed to spawn "..tostring(prefab))
		return
	end
	tree.Transform:SetPosition(x + math.cos(angle) * 3, 0, z - math.sin(angle) * 3)
	print("[ty] spawned "..prefab)
end

function c_ty_peachtree()
	c_ty_spawn_tree("ty_peachtree")
end

function c_ty_willow()
	c_ty_spawn_tree("ty_willow")
end

function c_ty_pine()
	c_ty_spawn_tree("ty_pine")
end

function c_ty_plough()
	local player = ConsoleCommandPlayer()
	if player == nil then
		return
	end
	local item = c_give("ty_plough", 1)
	print("[ty] gave ty_plough")
	return item
end
