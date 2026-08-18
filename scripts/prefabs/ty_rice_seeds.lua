--[[
	水稻种子（5 期）
	bank/build: ty_rice_seeds
	anim: idle_1 ~ idle_5
	可栽种到任意湿田地皮；对应作物 ty_rice_1~5。
]]

local assets =
{
	Asset("ANIM", "anim/ty_rice_seeds.zip"),
}

local PaddyTiles = require("ty_paddy_tiles")

local PLANT_SPACING = 0.75

local function CanPlantOnPaddy(inst, pt, mouseover, deployer)
	if not PaddyTiles.IsWetPaddyAtPoint(pt.x, 0, pt.z) then
		return false
	end

	-- 作物尚未注册时仍允许瞄准湿田，便于联调；真正种下时若缺 prefab 会退回种子
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, PLANT_SPACING, { "ty_rice" })
	return ents == nil or #ents == 0
end

local function OnDeploy(inst, pt, deployer)
	local plant_prefab = inst._plant_prefab
	local plant = plant_prefab ~= nil and SpawnPrefab(plant_prefab) or nil
	if plant == nil then
		print(string.format("[ty] rice plant missing (%s), seed refunded", tostring(plant_prefab)))
		if deployer ~= nil and deployer.components.inventory ~= nil then
			deployer.components.inventory:GiveItem(inst)
		else
			inst:Remove()
		end
		return
	end

	plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant:PushEvent("on_planted", { in_soil = false, doer = deployer, seed = inst })
	if plant.SoundEmitter ~= nil then
		plant.SoundEmitter:PlaySound("dontstarve/common/plant")
	end
	inst:Remove()
end

local function MakeSeed(stage)
	local name = "ty_rice_seeds_" .. stage
	local anim = "idle_" .. stage
	local plant_prefab = "ty_rice_" .. stage

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("ty_rice_seeds")
		inst.AnimState:SetBuild("ty_rice_seeds")
		inst.AnimState:PlayAnimation(anim)
		inst.AnimState:SetRayTestOnBB(true)

		inst.pickupsound = "vegetation_firm"

		inst:AddTag("deployedplant")
		inst:AddTag("ty_rice_seeds")

		inst.overridedeployplacername = "seeds_placer"
		inst._plant_prefab = plant_prefab
		inst._custom_candeploy_fn = CanPlantOnPaddy

		MakeInventoryFloatable(inst, "small", 0.05, 0.8)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		-- 暂无原版种子图标；之后补 inventoryimages
		inst.components.inventoryitem.imagename = "seeds"
		inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

		inst:AddComponent("tradable")

		inst:AddComponent("farmplantable")
		inst.components.farmplantable.plant = plant_prefab
		inst:AddComponent("deployable")
		inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
		inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
		inst.components.deployable.ondeploy = OnDeploy

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		MakeHauntableLaunch(inst)

		return inst
	end

	return Prefab(name, fn, assets)
end

return MakeSeed(1),
	MakeSeed(2),
	MakeSeed(3),
	MakeSeed(4),
	MakeSeed(5)
