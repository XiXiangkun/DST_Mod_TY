--[[
	草鱼（参考官方 fish / fish_cooked）
	bank/build: ty_grass_carp
	anim: idle / dead / cooked
]]

local assets =
{
	Asset("ANIM", "anim/ty_grass_carp.zip"),
}

local prefabs =
{
	"ty_grass_carp_cooked",
	"fishmeat_small_dried",
	"spoiled_food",
}

local function stopkicking(inst)
	if inst.floptask then
		inst.floptask:Cancel()
		inst.floptask = nil
	end
	inst.AnimState:PlayAnimation("dead")
end

local function commonfn(anim, loop, dryable, cookable, scale)
	local inst = CreateEntity()
	inst.entity:AddSoundEmitter()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("ty_grass_carp")
	inst.AnimState:SetBuild("ty_grass_carp")
	inst.AnimState:PlayAnimation(anim, loop)
	inst.Transform:SetScale(scale, scale, scale)

	inst:AddTag("meat")
	inst:AddTag("catfood")
	inst:AddTag("pondfish")
	inst:AddTag("fish")

	if dryable then
		inst:AddTag("dryable")
	end

	if cookable then
		inst:AddTag("cookable")
	end

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 钓鱼时角色手持覆写用官方鱼 build（本资源无角色手持符号）
	inst.build = "fish01"

	inst:AddComponent("edible")
	inst.components.edible.ismeat = true
	inst.components.edible.foodtype = FOODTYPE.MEAT

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("bait")

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	if dryable then
		inst:AddComponent("dryable")
		inst.components.dryable:SetProduct("fishmeat_small_dried")
		inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
		inst.components.dryable:SetDriedBuildFile("meat_rack_food_tot")
	end

	if cookable then
		inst:AddComponent("cookable")
		inst.components.cookable.product = "ty_grass_carp_cooked"
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	-- 暂无专用图标
	inst.components.inventoryitem.imagename = cookable and "ty_grass_carp" or "ty_grass_carp_cooked"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/ty_items.xml"

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
	inst.data = {}

	return inst
end

local function flopsound(inst)
	inst.floptask = inst:DoTaskInTime(10 / 30, function()
		inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland")
		if inst.floptask then
			inst.floptask:Cancel()
			inst.floptask = nil
		end
		inst.floptask = inst:DoTaskInTime(12 / 30, function()
			inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland")
		end)
	end)
end

local function rawfn()
	local inst = commonfn("idle", false, true, true, 0.75)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.edible.healthvalue = TUNING.HEALING_TINY
	inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
	inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)

	inst:DoTaskInTime(5, stopkicking)
	inst.components.inventoryitem:SetOnPutInInventoryFn(stopkicking)
	inst.OnLoad = stopkicking

	inst:ListenForEvent("animover", function()
		if inst.AnimState:IsCurrentAnimation("idle") then
			flopsound(inst)
			inst.AnimState:PlayAnimation("idle")
		end
	end)
	flopsound(inst)

	return inst
end

local function cookedfn()
	local inst = commonfn("cooked", false, false, false, 0.65)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.edible.healthvalue = TUNING.HEALING_TINY
	inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

	inst.components.floater:SetVerticalOffset(0.2)
	inst.components.floater:SetScale(0.75)

	return inst
end

return Prefab("ty_grass_carp", rawfn, assets, prefabs),
	Prefab("ty_grass_carp_cooked", cookedfn, assets)
