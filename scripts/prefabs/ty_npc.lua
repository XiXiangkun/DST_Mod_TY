--[[
	NPC（日出游荡、夜晚回家）
	共用角色骨架；各 NPC 用 MakeNPC 配置动画、语速与 brain/SG。
	后期加独特功能时，改对应条目的 brain/sg，或补 master_postinit。
]]

local function MakeNPC(def)
	local assets = def.assets or {}

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

		inst.AnimState:SetBank(def.bank)
		inst.AnimState:SetBuild(def.build)
		inst.AnimState:PlayAnimation("idle_loop", true)
		local hides = def.hide or {}
		for i = 1, #hides do
			inst.AnimState:Hide(hides[i])
		end

		inst:AddTag("ty_npc")
		inst:AddTag(def.tag or def.name)
		inst:AddTag("notarget")

		inst:AddComponent("talker")
		inst.components.talker.fontsize = 35
		inst.components.talker.font = TALKINGFONT
		inst.components.talker.offset = Vector3(0, -400, 0)
		inst.components.talker:MakeChatter()

		inst.entity:SetPristine()

		-- 雨天显示层（如斗笠/雨披）：客户端也要跟世界天气同步
		if def.rain_show ~= nil then
			local symbols = def.rain_show
			local function SyncRainLayers(inst, israining)
				for i = 1, #symbols do
					if israining then
						inst.AnimState:Show(symbols[i])
					else
						inst.AnimState:Hide(symbols[i])
					end
				end
			end
			SyncRainLayers(inst, TheWorld.state.israining)
			inst:WatchWorldState("israining", SyncRainLayers)
		end

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("locomotor")
		inst.components.locomotor.walkspeed = def.walkspeed
		inst.components.locomotor.runspeed = def.runspeed
		inst.components.locomotor:SetAllowPlatformHopping(false)

		inst:AddComponent("knownlocations")
		inst:AddComponent("inspectable")

		inst:SetStateGraph(def.sg)
		inst:SetBrain(require(def.brain))

		if def.master_postinit ~= nil then
			def.master_postinit(inst)
		end

		return inst
	end

	return Prefab(def.name, fn, assets)
end

return MakeNPC({
	name = "ty_fisherman",
	tag = "ty_fisherman",
	bank = "ty_npc_farmer_1",
	build = "ty_npc_farmer_1",
	hide = { "swap_hat", "swap_object", "arm_carry", "torso_overlay", "headtopper" },
	rain_show = { "torso_overlay", "headtopper" },
	assets = {
		Asset("ANIM", "anim/ty_npc_farmer_1_build.zip"),
		Asset("ANIM", "anim/ty_npc_farmer_1_bank.zip"),
	},
	walkspeed = TUNING.TY_FISHERMAN_WALK_SPEED,
	runspeed = TUNING.TY_FISHERMAN_RUN_SPEED,
	sg = "SGty_fisherman",
	brain = "brains/ty_fishermanbrain",
}),
MakeNPC({
	name = "ty_farmwife",
	tag = "ty_farmwife",
	bank = "ty_npc_farmer_2_bank",
	build = "ty_npc_farmer_2_build",
	hide = { "swap_hat", "swap_object", "arm_carry" },
	assets = {
		Asset("ANIM", "anim/ty_npc_farmer_2_build.zip"),
		Asset("ANIM", "anim/ty_npc_farmer_2_bank.zip"),
	},
	walkspeed = TUNING.TY_FARMWIFE_WALK_SPEED,
	runspeed = TUNING.TY_FARMWIFE_RUN_SPEED,
	sg = "SGty_farmwife",
	brain = "brains/ty_farmwifebrain",
})
