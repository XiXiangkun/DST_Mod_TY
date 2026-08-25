--[[
	渔夫铺面建筑（动画 ms_fisherman_shop）。
	与 ty_fisherman_house 绑定；日出刷货，到摊可买，黄昏清货。
]]

local assets =
{
	Asset("ANIM", "anim/ms_fisherman_shop.zip"),
}

local function OnStartDay(inst)
	if inst.components.ty_fisherman_shop ~= nil then
		inst.components.ty_fisherman_shop:RerollStock()
	end
end

local function OnStartDusk(inst)
	local shop = inst.components.ty_fisherman_shop
	if shop == nil then
		return
	end
	shop:SetTending(false)
	shop:ClearStock()
end

local function getstatus(inst)
	if inst.components.ty_fisherman_shop ~= nil then
		return inst.components.ty_fisherman_shop:GetStatus()
	end
	return nil
end

local function onhammered(inst, worker)
	-- 预留：废墟重建。第一版直接倒塌移除。
	local fx = SpawnPrefab("collapse_small")
	if fx ~= nil then
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		fx:SetMaterial("wood")
	end
	if inst._ty_house ~= nil and inst._ty_house:IsValid() then
		inst._ty_house._ty_shop = nil
	end
	local fisher = inst._ty_fisherman
	if fisher ~= nil and fisher:IsValid() then
		fisher._shop = nil
		fisher._tending_shop = false
	end
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("idle")
end

local function OnSave(inst, data)
	if inst._ty_house ~= nil and inst._ty_house:IsValid() then
		data.house = inst._ty_house.GUID
	end
end

local function OnLoadPostPass(inst, newents, data)
	if data ~= nil and data.house ~= nil and newents[data.house] ~= nil then
		local util = require("ty_fisherman_shop_util")
		util.LinkHouseAndShop(newents[data.house].entity, inst)
	end
end

local function GetStallPosition(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local angle = (inst.Transform:GetRotation() or 0) * DEGREES
	local d = TUNING.TY_FISHERMAN_SHOP_STALL_DIST or 1.4
	return Vector3(x + math.cos(angle) * d, y, z - math.sin(angle) * d)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.45)

	inst.MiniMapEntity:SetIcon("fish.png")

	inst.AnimState:SetBank("ms_fisherman_shop")
	inst.AnimState:SetBuild("ms_fisherman_shop")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("structure")
	inst:AddTag("ty_fisherman_shop")

	inst._stock_str = net_string(inst.GUID, "ty_fisherman_shop._stock_str", "ty_shop_stock_dirty")
	inst._tending = net_bool(inst.GUID, "ty_fisherman_shop._tending", "ty_shop_stock_dirty")

	inst.entity:SetPristine()

	inst.GetStallPosition = GetStallPosition

	-- 客户端也需要组件，供 ComponentAction 识别
	inst:AddComponent("ty_fisherman_shop")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:WatchWorldState("startday", OnStartDay)
	inst:WatchWorldState("startcaveday", OnStartDay)
	inst:WatchWorldState("startdusk", OnStartDusk)
	inst:WatchWorldState("startcavedusk", OnStartDusk)

	inst:DoTaskInTime(0, function()
		if TheWorld.state.isday and inst.components.ty_fisherman_shop ~= nil then
			local slots = inst.components.ty_fisherman_shop.slots
			local empty = true
			for i = 1, 12 do
				if slots[i] ~= nil then
					empty = false
					break
				end
			end
			if empty then
				inst.components.ty_fisherman_shop:RerollStock()
			end
		end
	end)

	inst.OnSave = OnSave
	inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("ty_fisherman_shop", fn, assets)
