--[[
	稻穗占位物品（后续补动画/图标/食用等）
]]

local assets =
{
	Asset("ANIM", "anim/seeds.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("seeds")
	inst.AnimState:SetBuild("seeds")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

	MakeInventoryFloatable(inst, "small", 0.05, 0.8)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "seeds"
	inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

	inst:AddComponent("tradable")

	MakeSmallBurnable(inst)
	MakeSmallPropagator(inst)
	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("ty_rice_panicle", fn, assets)
