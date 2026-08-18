--[[
	渔夫 NPC
	白天在家附近游荡，靠近玩家时说话；夜晚回家。
	v1：不可攻击、无血条。
	动画暂用官方 pigman。ty_npc_farmer_1.zip 在进档时会原生崩溃（无 Lua 堆栈），修好后再换回。
]]

local assets =
{
	Asset("ANIM", "anim/ty_npc_farmer_1_build.zip"),
	Asset("ANIM", "anim/ty_npc_farmer_1_bank.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 50, .5)

	inst.DynamicShadow:SetSize(1.5, .75)
	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("pigman")
	inst.AnimState:SetBuild("pig_build")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:Hide("hat")
	inst.AnimState:Hide("ARM_carry")
	inst.AnimState:Hide("ARM_carry_up")

	inst:AddTag("ty_npc")
	inst:AddTag("ty_fisherman")
	inst:AddTag("notarget")

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 35
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.offset = Vector3(0, -400, 0)
	inst.components.talker:MakeChatter()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.TY_FISHERMAN_WALK_SPEED
	inst.components.locomotor.runspeed = TUNING.TY_FISHERMAN_RUN_SPEED
	inst.components.locomotor:SetAllowPlatformHopping(false)

	inst:AddComponent("knownlocations")
	inst:AddComponent("inspectable")

	inst:SetStateGraph("SGty_fisherman")
	inst:SetBrain(require("brains/ty_fishermanbrain"))

	return inst
end

return Prefab("ty_fisherman", fn, assets)
