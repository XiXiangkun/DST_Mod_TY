--[[
	狗屋：可建造建筑。仅结构本身，不含宠物逻辑。
]]

require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ty_pethouse.zip"),
}

local prefabs =
{
	"collapse_small",
}

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
	inst.AnimState:PlayAnimation("idle1")
	inst.AnimState:PushAnimation("idle1", true)
end

local function onbuilt(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.6)

	inst.AnimState:SetBank("ty_pethouse")
	inst.AnimState:SetBuild("ty_pethouse")
	inst.AnimState:PlayAnimation("idle1", true)

	inst:AddTag("structure")
	inst:AddTag("ty_pethouse")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ "boards", "boards" })

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	MakeSnowCovered(inst)

	inst:ListenForEvent("onbuilt", onbuilt)

	return inst
end

return Prefab("ty_pethouse", fn, assets, prefabs),
	MakePlacer("ty_pethouse_placer", "ty_pethouse", "ty_pethouse", "idle1")
