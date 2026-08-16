-- 田园(TY) 测试命令
-- c_ty_paddy()           脚下开垦水田（并入连通水域，水位取平均）
-- c_ty_paddy_set(0.6)    设置脚下整片水域水位 0~1
-- c_ty_paddy_set(0)      整片干涸
-- c_ty_paddy_info()      打印脚下水位/连通格数
-- c_ty_rice_seeds()      给予 5 期水稻种子各 10
-- c_ty_rice_seeds(3)     只给三期种子 10
-- c_ty_rice(5)           脚下生成对应期成熟水稻（可采）
-- c_ty_rice(5, 1)        脚下生成对应期指定阶段 1~5

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
	local tile = TheWorld.Map:GetTile(tx, ty)
	local tile_name = tostring(tile)
	if tile == WORLD_TILES.TY_PADDY then
		tile_name = "TY_PADDY"
	elseif tile == WORLD_TILES.TY_PADDY_DRY then
		tile_name = "TY_PADDY_DRY"
	end
	print(string.format(
		"[ty] tile=(%d,%d) map_tile=%s water=%s tier=%s body=%d raining=%s rate=%.2f",
		tx, ty, tile_name,
		water ~= nil and string.format("%.1f%%", water * 100) or "n/a",
		tostring(tier),
		body_n,
		tostring(TheWorld.state.israining),
		TheWorld.state.precipitationrate or 0
	))
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
