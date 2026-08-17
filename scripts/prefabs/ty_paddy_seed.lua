--[[
	鱼苗 / 虾苗
	bank/build: ty_paddy_seed
	anim: idle_fish / idle_shrimp
	可放养到湿田；每格仅一种苗，不可重复投放。
]]

local assets =
{
	Asset("ANIM", "anim/ty_paddy_seed.zip"),
}

local function GetAquaFailSpeech(kind)
	if kind == "shrimp" then
		return STRINGS.TY_ANNOUNCE_AQUA_HAS_SHRIMP
	end
	return STRINGS.TY_ANNOUNCE_AQUA_HAS_FISH
end

-- 客户端无 ty_paddy_manager，只能用地皮判断（与水稻种子一致）
local function CanDeployOnWetPaddy(inst, pt, mouseover, deployer)
	return TheWorld.Map:GetTileAtPoint(pt.x, 0, pt.z) == WORLD_TILES.TY_PADDY
end

local function OnDeploy(inst, pt, deployer)
	local mgr = TheWorld.components.ty_paddy_manager
	local kind = inst._aqua_kind
	local ok, reason_kind = false, nil
	if mgr ~= nil and kind ~= nil then
		ok, reason_kind = mgr:TryStockAquaAtPoint(pt.x, 0, pt.z, kind)
	end

	if not ok then
		if deployer ~= nil and deployer.components.talker ~= nil then
			local speech = GetAquaFailSpeech(reason_kind or kind)
			if speech ~= nil then
				deployer.components.talker:Say(speech)
			end
		end
		if deployer ~= nil and deployer.components.inventory ~= nil then
			deployer.components.inventory:GiveItem(inst)
		end
		return
	end

	if deployer ~= nil and deployer.SoundEmitter ~= nil then
		deployer.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught")
	end
	inst:Remove()
end

local function MakeSeed(kind, anim, inv_image)
	local name = kind == "fish" and "ty_fish_seed" or "ty_shrimp_seed"
	local placer_name = name .. "_placer"

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("ty_paddy_seed")
		inst.AnimState:SetBuild("ty_paddy_seed")
		inst.AnimState:PlayAnimation(anim)
		inst.AnimState:SetRayTestOnBB(true)

		inst.pickupsound = "vegetation_firm"

		inst:AddTag("ty_paddy_seed")
		inst:AddTag(name)

		-- 不用 deployedplant / seeds_placer，避免耕种预览与栽种动作语义
		inst._aqua_kind = kind
		inst._custom_candeploy_fn = CanDeployOnWetPaddy

		MakeInventoryFloatable(inst, "small", 0.05, 0.8)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = inv_image
		inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

		inst:AddComponent("tradable")

		inst:AddComponent("deployable")
		inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
		inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
		inst.components.deployable.ondeploy = OnDeploy

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		MakeHauntableLaunch(inst)

		return inst
	end

	return Prefab(name, fn, assets),
		MakePlacer(placer_name, "ty_paddy_seed", "ty_paddy_seed", anim)
end

local fish_seed, fish_placer = MakeSeed("fish", "idle_fish", "pondfish")
local shrimp_seed, shrimp_placer = MakeSeed("shrimp", "idle_shrimp", "wobster_sheller_land")

return fish_seed, fish_placer, shrimp_seed, shrimp_placer
