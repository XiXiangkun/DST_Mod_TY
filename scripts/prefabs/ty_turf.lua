--[[
	装饰石砖：可堆叠放置，贴地平铺。
	铺下后按格子 (tx+ty)%2 交错播 idle_onground_1 / idle_onground_2。
	铲子可挖回物品。
]]

require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ty_turfs.zip"),
}

local prefabs =
{
	"ty_turf_ground",
}

local GROUND_TAGS = { "ty_turf_ground" }

local function GetGroundAnimForPoint(x, y, z)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	if ((tx + ty) % 2) == 0 then
		return "idle_onground_1"
	end
	return "idle_onground_2"
end

local function ApplyGroundAnim(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.AnimState:PlayAnimation(GetGroundAnimForPoint(x, y, z))
end

local function CanDeployTurf(inst, pt, mouseover, deployer, rot)
	local map = TheWorld.Map
	local x, y, z = pt:Get()
	if not map:IsAboveGroundAtPoint(x, 0, z, false) then
		return false
	end

	local tile = map:GetTileAtPoint(x, 0, z)
	if tile == nil or not IsLandTile(tile) then
		return false
	end

	local cx, cy, cz = map:GetTileCenterPoint(x, 0, z)
	return TheSim:CountEntities(cx, cy, cz, 0.9, GROUND_TAGS) == 0
end

local function OnDeploy(inst, pt, deployer)
	if deployer ~= nil and deployer.SoundEmitter ~= nil then
		deployer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
	end

	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(pt:Get())
	local ground = SpawnPrefab("ty_turf_ground")
	if ground ~= nil then
		ground.Transform:SetPosition(cx, cy, cz)
		ApplyGroundAnim(ground)
	end

	inst.components.stackable:Get():Remove()
end

--------------------------------------------------------------------------

local function OnDug(inst, worker)
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SpawnLootPrefab("ty_turf")
	end
	inst:Remove()
end

local function ground_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("ty_turfs")
	inst.AnimState:SetBuild("ty_turfs")
	inst.AnimState:PlayAnimation("idle_onground_1")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddTag("ty_turf_ground")
	inst:AddTag("NOBLOCK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, ApplyGroundAnim)
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnDug)

	inst:DoTaskInTime(0, ApplyGroundAnim)

	return inst
end

--------------------------------------------------------------------------

local function item_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("ty_turfs")
	inst.AnimState:SetBuild("ty_turfs")
	inst.AnimState:PlayAnimation("brick")

	inst:AddTag("ty_turf")

	MakeInventoryFloatable(inst, "med", nil, 0.65)

	-- DEPLOYMODE.CUSTOM：客户端也会走此回调
	inst._custom_candeploy_fn = CanDeployTurf

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	-- 暂用官方地皮图标；有自制图标后改 atlas / imagename
	inst.components.inventoryitem:ChangeImageName("turf_rocky")

	inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
	inst.components.deployable.ondeploy = OnDeploy

	MakeHauntableLaunch(inst)

	return inst
end

--------------------------------------------------------------------------

local function placer_postinit(inst)
	inst.components.placer.snap_to_tile = true
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	inst:DoPeriodicTask(0, ApplyGroundAnim)
end

return Prefab("ty_turf", item_fn, assets, prefabs),
	Prefab("ty_turf_ground", ground_fn, assets),
	MakePlacer("ty_turf_placer", "ty_turfs", "ty_turfs", "idle_onground_1", true, nil, nil, nil, nil, nil, placer_postinit)
