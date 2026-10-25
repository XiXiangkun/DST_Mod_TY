--[[
	桃树 / 柳树 / 松树
	动画：idle（随机帧）、砍伐 shake、倒下 fall、树桩 stump
	树桩可挖出木头；点燃烧完直接消失。
]]

local CHOP_WORKLEFT = 10

local function PlayIdleRandom(inst)
	inst.AnimState:PlayAnimation("idle", true)
	local len = inst.AnimState:GetCurrentAnimationLength()
	if len ~= nil and len > 0 then
		inst.AnimState:SetTime(math.random() * len)
	end
end

local function OnBurnt(inst)
	inst:Remove()
end

local function DigUpStump(inst, digger)
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SpawnLootPrefab("log")
	end
	inst:Remove()
end

local function MakeStump(inst, instant)
	inst:AddTag("stump")

	if instant then
		inst.AnimState:PlayAnimation("stump")
	end

	RemovePhysicsColliders(inst)

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetOnWorkCallback(nil)
		inst.components.workable:SetOnFinishCallback(DigUpStump)
		inst.components.workable:SetWorkLeft(1)
	end
end

local function OnChop(inst, chopper, workleft)
	if not (chopper ~= nil and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound(
			chopper ~= nil and chopper:HasTag("beaver") and
			"dontstarve/characters/woodie/beaver_chop_tree"
			or "dontstarve/wilson/use_axe_tree"
		)
	end

	inst.AnimState:PlayAnimation("shake")
	inst.AnimState:PushAnimation("idle", true)
end

local function OnChopDown(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	inst.AnimState:PlayAnimation("fall")
	inst.AnimState:PushAnimation("stump")

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot()
	end

	MakeStump(inst, false)
end

local function GetStatus(inst)
	if inst:HasTag("stump") then
		return "CHOPPED"
	end
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return "BURNING"
	end
	return nil
end

local function OnSave(inst, data)
	if inst:HasTag("stump") then
		data.stump = true
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.stump then
		MakeStump(inst, true)
	end
end

local function MakeTree(name, bank, build)
	local assets =
	{
		Asset("ANIM", "anim/"..build..".zip"),
	}

	local prefabs =
	{
		"log",
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddDynamicShadow()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .25)

		inst.DynamicShadow:SetSize(1.5, .75)

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		PlayIdleRandom(inst)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag(name)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = GetStatus

		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetLoot({ "log", "log" })

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetWorkLeft(CHOP_WORKLEFT)
		inst.components.workable:SetOnWorkCallback(OnChop)
		inst.components.workable:SetOnFinishCallback(OnChopDown)

		MakeMediumBurnable(inst)
		MakeMediumPropagator(inst)
		inst.components.burnable:SetOnBurntFn(OnBurnt)

		MakeHauntableWork(inst)

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return MakeTree("ty_peachtree", "ty_peachtree", "ty_peachtree"),
	MakeTree("ty_willow", "ty_willow", "ty_willow"),
	MakeTree("ty_pine", "ty_pine", "ty_pine")
