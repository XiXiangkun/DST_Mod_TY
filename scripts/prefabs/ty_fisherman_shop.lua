--[[
	渔夫铺面（可建造，可多建；挂牌后渔夫才会来开张）。
]]

local assets =
{
	Asset("ANIM", "anim/ty_fisherman_shop.zip"),
}

local prefabs =
{
	"collapse_small",
}

local function OnStartDay(inst)
	if inst.components.ty_fisherman_shop ~= nil
		and inst.components.ty_fisherman_shop:IsLicensed() then
		inst.components.ty_fisherman_shop:RerollStock()
	end
end

local function OnStartDusk(inst)
	local shop = inst.components.ty_fisherman_shop
	if shop == nil then
		return
	end
	shop:SetTending(false)
	if shop:IsLicensed() then
		shop:ClearStock()
	end
end

local function getstatus(inst)
	if inst.components.ty_fisherman_shop ~= nil then
		return inst.components.ty_fisherman_shop:GetStatus()
	end
	return nil
end

local function onhammered(inst, worker)
	local fx = SpawnPrefab("collapse_small")
	if fx ~= nil then
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		fx:SetMaterial("wood")
	end
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot()
	end
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("idle")
end

local function onbuilt(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
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

	inst.AnimState:SetBank("ty_fisherman_shop")
	inst.AnimState:SetBuild("ty_fisherman_shop")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("structure")
	inst:AddTag("ty_fisherman_shop")

	inst._stock_str = net_string(inst.GUID, "ty_fisherman_shop._stock_str", "ty_shop_stock_dirty")
	inst._tending = net_bool(inst.GUID, "ty_fisherman_shop._tending", "ty_shop_stock_dirty")
	inst._licensed = net_bool(inst.GUID, "ty_fisherman_shop._licensed", "ty_shop_stock_dirty")

	inst.entity:SetPristine()

	inst.GetStallPosition = GetStallPosition

	inst:AddComponent("ty_fisherman_shop")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ "boards", "boards" })

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:ListenForEvent("onbuilt", onbuilt)

	inst:WatchWorldState("startday", OnStartDay)
	inst:WatchWorldState("startcaveday", OnStartDay)
	inst:WatchWorldState("startdusk", OnStartDusk)
	inst:WatchWorldState("startcavedusk", OnStartDusk)

	return inst
end

return Prefab("ty_fisherman_shop", fn, assets, prefabs),
	MakePlacer("ty_fisherman_shop_placer", "ty_fisherman_shop", "ty_fisherman_shop", "idle")
