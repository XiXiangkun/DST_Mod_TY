--[[
	金币（参考官方 goldnugget）
	bank/build: ty_coin
	anim: idle / sparkle
]]

local assets =
{
	Asset("ANIM", "anim/ty_coin.zip"),
}

local function shine(inst)
	inst.shinetask = nil
	if not inst.AnimState:IsCurrentAnimation("sparkle") then
		inst.AnimState:PlayAnimation("sparkle")
		inst.AnimState:PushAnimation("idle", false)
	end
	if not inst:IsAsleep() then
		inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, shine)
	end
end

local function OnEntityWake(inst)
	if inst.shinetask == nil then
		inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, shine)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetBank("ty_coin")
	inst.AnimState:SetBuild("ty_coin")
	inst.AnimState:PlayAnimation("idle")

	inst.pickupsound = "metal"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/ty_items.xml"
	inst.components.inventoryitem.imagename = "ty_coin"
	
	inst.components.inventoryitem:SetSinks(true)

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")

	MakeHauntableLaunchAndSmash(inst)

	shine(inst)
	inst.OnEntityWake = OnEntityWake

	return inst
end

return Prefab("ty_coin", fn, assets)
