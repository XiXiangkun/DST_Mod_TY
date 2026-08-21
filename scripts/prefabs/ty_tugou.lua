--[[
	大黄狗
	参考官方 warglet / hound。
	不攻击玩家；主动攻击带 monster 的不友好生物；自行游荡。
]]

local assets =
{
	-- Asset("ANIM", "anim/hound_basic.zip"),
	-- Asset("ANIM", "anim/hound_ocean.zip"),
	-- Asset("ANIM", "anim/hound_warglet.zip"),
	Asset("ANIM", "anim/ty_tugou_build_1.zip"),
	Asset("ANIM", "anim/ty_tugou_build_2.zip"),
	Asset("ANIM", "anim/ty_tugou_bank_1.zip"),
	Asset("ANIM", "anim/ty_tugou_bank_2.zip"),
}

local sounds =
{
	pant = "dontstarve/creatures/hound/pant",
	attack = "dontstarve/creatures/hound/attack",
	bite = "dontstarve/creatures/hound/bite",
	bark = "dontstarve/creatures/hound/bark",
	death = "dontstarve/creatures/hound/death",
	sleep = "dontstarve/creatures/hound/sleep",
	growl = "dontstarve/creatures/hound/growl",
	howl = "dontstarve/creatures/together/clayhound/howl",
	hurt = "dontstarve/creatures/hound/hurt",
}

local RETARGET_MUST_TAGS = { "monster", "_combat", "_health" }
local RETARGET_CANT_TAGS = {
	"INLIMBO",
	"player",
	"playerghost",
	"companion",
	"domesticated",
	"ty_tugou",
	"ty_npc",
	"structure",
	"wall",
	"notarget",
	"invisible",
}

local function IsUnfriendlyMonster(inst, guy)
	if guy == nil or guy == inst then
		return false
	end
	if guy:HasTag("player") or guy:HasTag("companion") then
		return false
	end
	if not guy:HasTag("monster") then
		return false
	end
	if guy.components.health == nil or guy.components.health:IsDead() then
		return false
	end
	if guy.components.combat == nil or not inst.components.combat:CanTarget(guy) then
		return false
	end
	if guy.components.follower ~= nil then
		local leader = guy.components.follower:GetLeader()
		if leader ~= nil and leader:HasTag("player") then
			return false
		end
	end
	return true
end

local function RetargetFn(inst)
	return FindEntity(
		inst,
		TUNING.TY_TUGOU_TARGET_DIST,
		function(guy)
			return IsUnfriendlyMonster(inst, guy)
		end,
		RETARGET_MUST_TAGS,
		RETARGET_CANT_TAGS
	)
end

local function KeepTargetFn(inst, target)
	if target == nil or not target:IsValid() or target:HasTag("player") then
		return false
	end
	return IsUnfriendlyMonster(inst, target)
		and inst:IsNear(target, TUNING.TY_TUGOU_KEEP_TARGET_DIST)
end

local function OnAttacked(inst, data)
	local attacker = data ~= nil and data.attacker or nil
	if attacker == nil or not attacker:IsValid() or attacker:HasTag("player") then
		return
	end
	if IsUnfriendlyMonster(inst, attacker) then
		inst.components.combat:SetTarget(attacker)
	end
end

local function OnNewTarget(inst, data)
	if data ~= nil and data.target ~= nil and data.target:HasTag("player") then
		inst.components.combat:SetTarget(nil)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, .5)

	local scale = TUNING.TY_TUGOU_SCALE or 1.35
	inst.Transform:SetScale(scale, scale, scale)
	inst.DynamicShadow:SetSize(2.5, 1.5)
	inst.Transform:SetFourFaced()

	inst:AddTag("animal")
	inst:AddTag("ty_tugou")
	-- 不用 companion：部分系统会特殊处理该标签

	inst.AnimState:SetBank("ty_tugou")
	inst.AnimState:SetBuild("ty_tugou_build_1")
	inst.AnimState:AddOverrideBuild("ty_tugou_build_2")
	inst.AnimState:PlayAnimation("idle", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.sounds = sounds

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.TY_TUGOU_WALK_SPEED or 4
	inst.components.locomotor.runspeed = TUNING.TY_TUGOU_RUN_SPEED or 8

	-- 与官方 warglet 一致：先 locomotor，再用官方 SGhound
	inst:SetStateGraph("SGhound")
	if inst.sg ~= nil and inst.sg.mem ~= nil then
		inst.sg.mem.nolunarmutate = true
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.TY_TUGOU_HEALTH or 300)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.TY_TUGOU_DAMAGE or 25)
	inst.components.combat:SetAttackPeriod(TUNING.TY_TUGOU_ATTACK_PERIOD or 2)
	inst.components.combat:SetRange(TUNING.TY_TUGOU_ATTACK_RANGE or 3)
	inst.components.combat:SetRetargetFunction(2, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat:SetHurtSound(sounds.hurt)
	inst.components.combat.hiteffectsymbol = "hound_body"

	inst:AddComponent("lootdropper")
	inst:AddComponent("knownlocations")
	inst:AddComponent("inspectable")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(2)

	MakeMediumFreezableCharacter(inst, "hound_body")
	MakeMediumBurnableCharacter(inst, "hound_body")
	MakeHauntablePanic(inst)

	-- mastersim 再 require，避免 prefab 注册阶段拉脑图
	inst:SetBrain(require("brains/ty_tugoubrain"))

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst:DoTaskInTime(0, function()
		if inst:IsValid() and inst.components.knownlocations ~= nil then
			inst.components.knownlocations:RememberLocation("home", inst:GetPosition(), true)
		end
	end)

	return inst
end

return Prefab("ty_tugou", fn, assets)
