--[[
	水稻作物 ty_rice_1 ~ ty_rice_5
	bank/build: ty_rice
	阶段: seed → sprout → small → med → tall
	干田暂停生长；1~4 期采后移除；5 期 tall_5_to_seed 后重回 seed。
]]

local assets =
{
	Asset("ANIM", "anim/ty_rice.zip"),
}

local prefabs =
{
	"ty_rice_panicle",
	"ty_rice_seeds_1",
	"ty_rice_seeds_2",
	"ty_rice_seeds_3",
	"ty_rice_seeds_4",
	"ty_rice_seeds_5",
}

local STAGE_SEED = 1
local STAGE_SPROUT = 2
local STAGE_SMALL = 3
local STAGE_MED = 4
local STAGE_TALL = 5

local HARVEST =
{
	[1] = { ears = 3, seed = "ty_rice_seeds_2" },
	[2] = { ears = 3, seed = "ty_rice_seeds_3" },
	[3] = { ears = 3, seed = "ty_rice_seeds_4" },
	[4] = { ears = 4, seed = "ty_rice_seeds_5" },
	[5] = { ears = 5, seed = "ty_rice_seeds_5" },
}

local IDLE_ANIMS =
{
	[STAGE_SEED] = "idle_seed",
	[STAGE_SPROUT] = "idle_sprout",
	[STAGE_SMALL] = "idle_small",
	[STAGE_MED] = "idle_med",
}

local GROW_ANIMS =
{
	[STAGE_SPROUT] = "seed_to_sprout",
	[STAGE_SMALL] = "sprout_to_small",
	[STAGE_MED] = "small_to_med",
}

--------------------------------------------------------------------------

local function GetGrowthSpeed(tier)
	if TheWorld.state.iswinter then
		return (TUNING.TY_RICE_WINTER_SPEED and TUNING.TY_RICE_WINTER_SPEED[tier]) or 1
	end
	return 1
end

local function GetStageGrowTime(inst)
	local base = TUNING.TY_RICE_STAGE_TIME or ((TUNING.TOTAL_DAY_TIME or 480) * 1.25)
	local speed = GetGrowthSpeed(inst.rice_tier or 1)
	if speed <= 0 then
		speed = 1
	end
	inst._growth_speed_applied = speed
	return base / speed
end

local function IsOnWetPaddy(inst)
	if TheWorld.components.ty_paddy_manager == nil then
		return false
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local water = TheWorld.components.ty_paddy_manager:GetWaterAtPoint(x, y, z)
	return water ~= nil and water >= (TUNING.TY_PADDY_WET_THRESHOLD or 0.01)
end

local function UpdateGrowthPause(inst)
	if inst.components.growable == nil then
		return
	end
	if IsOnWetPaddy(inst) then
		inst.components.growable:Resume("dry")
	else
		inst.components.growable:Pause("dry")
	end
end

local function RecalcGrowthForSeason(inst)
	local growable = inst.components.growable
	if growable == nil or not growable:IsGrowing() or growable:IsPaused() then
		return
	end
	if growable.targettime == nil then
		return
	end

	local old_speed = inst._growth_speed_applied or 1
	local new_speed = GetGrowthSpeed(inst.rice_tier or 1)
	if old_speed == new_speed then
		return
	end

	local remaining = math.max(0, growable.targettime - GetTime())
	local base_left = remaining * old_speed
	inst._growth_speed_applied = new_speed
	growable:StartGrowing(base_left / new_speed)
end

--------------------------------------------------------------------------

-- 预留：镰刀收获加成与额外掉草（暂不实现）
local function GetHarvestLoot(inst, picker, tool)
	local data = HARVEST[inst.rice_tier] or HARVEST[1]
	local ears = data.ears
	local seed = data.seed
	local cutgrass = 0
	-- if tool ~= nil and IsRiceScythe(tool) then
	--   ears = ears + bonus
	--   cutgrass = ...
	-- end
	return ears, seed, cutgrass
end

local function DropHarvestLoot(inst, picker)
	local ears, seed = GetHarvestLoot(inst, picker, nil)
	local lootdropper = inst.components.lootdropper
	if lootdropper == nil then
		return
	end
	for _ = 1, ears do
		lootdropper:SpawnLootPrefab("ty_rice_panicle")
	end
	if seed ~= nil then
		lootdropper:SpawnLootPrefab(seed)
	end
end

local function SetPickableState(inst, enabled)
	local pickable = inst.components.pickable
	if pickable == nil then
		return
	end
	pickable.canbepicked = enabled == true
	pickable.caninteractwith = enabled == true
end

local function PlayIdle(inst, stage)
	local tier = inst.rice_tier or 1
	local anim
	if stage == STAGE_TALL then
		anim = "idle_tall_" .. tier
	else
		anim = IDLE_ANIMS[stage] or "idle_seed"
	end
	inst.AnimState:PlayAnimation(anim, true)
end

local function PlayGrowInto(inst, stage)
	local tier = inst.rice_tier or 1
	local grow_anim
	if stage == STAGE_TALL then
		grow_anim = "med_to_tall_" .. tier
	else
		grow_anim = GROW_ANIMS[stage]
	end
	if grow_anim ~= nil then
		inst.AnimState:PlayAnimation(grow_anim)
		local idle = (stage == STAGE_TALL) and ("idle_tall_" .. tier) or IDLE_ANIMS[stage]
		if idle ~= nil then
			inst.AnimState:PushAnimation(idle, true)
		end
	else
		PlayIdle(inst, stage)
	end
end

--------------------------------------------------------------------------

local function OnDigUp(inst, worker)
	inst:Remove()
end

local function OnBurnt(inst)
	inst:Remove()
end

local function OnCycleAnimDone(inst)
	if not inst:IsValid() or not inst._awaiting_seed_cycle then
		return
	end
	inst:RemoveEventCallback("animover", OnCycleAnimDone)
	inst._awaiting_seed_cycle = false
	inst.components.growable:SetStage(STAGE_SEED)
	inst.components.growable:StartGrowing()
	UpdateGrowthPause(inst)
end

local function OnPicked(inst, picker)
	DropHarvestLoot(inst, picker)

	if (inst.rice_tier or 1) < 5 then
		-- remove_when_picked 负责移除
		return
	end

	-- 5 期：播 tall_5_to_seed，再从 seed 重新生长
	SetPickableState(inst, false)
	inst.components.growable:StopGrowing()
	inst._awaiting_seed_cycle = true
	inst.AnimState:PlayAnimation("tall_5_to_seed")
	inst:ListenForEvent("animover", OnCycleAnimDone)
end

--------------------------------------------------------------------------

local function MakeStageFn(stage)
	return function(inst)
		SetPickableState(inst, stage == STAGE_TALL and not inst._awaiting_seed_cycle)
		if not inst._skip_stage_idle then
			PlayIdle(inst, stage)
		end
		inst._skip_stage_idle = nil
	end
end

local function MakePregrowFn()
	return function(inst)
		inst._skip_stage_idle = true
	end
end

local function MakeGrowFn(stage)
	return function(inst)
		PlayGrowInto(inst, stage)
		SetPickableState(inst, stage == STAGE_TALL)
	end
end

local function BuildStages(inst)
	return {
		{
			name = "seed",
			time = GetStageGrowTime,
			fn = MakeStageFn(STAGE_SEED),
		},
		{
			name = "sprout",
			time = GetStageGrowTime,
			fn = MakeStageFn(STAGE_SPROUT),
			pregrowfn = MakePregrowFn(),
			growfn = MakeGrowFn(STAGE_SPROUT),
		},
		{
			name = "small",
			time = GetStageGrowTime,
			fn = MakeStageFn(STAGE_SMALL),
			pregrowfn = MakePregrowFn(),
			growfn = MakeGrowFn(STAGE_SMALL),
		},
		{
			name = "med",
			time = GetStageGrowTime,
			fn = MakeStageFn(STAGE_MED),
			pregrowfn = MakePregrowFn(),
			growfn = MakeGrowFn(STAGE_MED),
		},
		{
			name = "tall",
			fn = MakeStageFn(STAGE_TALL),
			pregrowfn = MakePregrowFn(),
			growfn = MakeGrowFn(STAGE_TALL),
		},
	}
end

--------------------------------------------------------------------------

local function OnPaddyWetnessChanged(inst, data)
	if data == nil or data.tx == nil or data.ty == nil then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	if tx == data.tx and ty == data.ty then
		UpdateGrowthPause(inst)
	end
end

local function OnSeasonTick(inst)
	RecalcGrowthForSeason(inst)
end

local function OnPlanted(inst, data)
	UpdateGrowthPause(inst)
end

local function OnSave(inst, data)
	data.awaiting_seed_cycle = inst._awaiting_seed_cycle or nil
end

local function OnLoad(inst, data)
	if data ~= nil and data.awaiting_seed_cycle then
		inst._awaiting_seed_cycle = true
		if inst.components.growable ~= nil then
			inst.components.growable:StopGrowing()
		end
		SetPickableState(inst, false)
		inst.AnimState:PlayAnimation("tall_5_to_seed")
		inst:ListenForEvent("animover", OnCycleAnimDone)
	end
end

local function OnLoadPostPass(inst)
	UpdateGrowthPause(inst)
	RecalcGrowthForSeason(inst)
end

--------------------------------------------------------------------------

local function MakeRice(tier)
	local name = "ty_rice_" .. tier

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("ty_rice")
		inst.AnimState:SetBuild("ty_rice")
		inst.AnimState:PlayAnimation("idle_seed", true)

		inst:AddTag("plant")
		inst:AddTag("ty_rice")
		inst:AddTag("ty_rice_" .. tier)
		inst:AddTag("canpourwateron") -- 允许对准植株用浇水壶

		inst.rice_tier = tier

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("lootdropper")

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
		inst.components.pickable.onpickedfn = OnPicked
		inst.components.pickable.remove_when_picked = tier < 5
		-- 产物在 onpickedfn 里手动掉落
		inst.components.pickable.canbepicked = false
		inst.components.pickable.product = nil

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(OnDigUp)

		inst:AddComponent("growable")
		inst.components.growable.stages = BuildStages(inst)
		inst.components.growable.growoffscreen = true
		inst.components.growable:SetStage(STAGE_SEED)
		inst.components.growable:StartGrowing()
		UpdateGrowthPause(inst)

		MakeMediumBurnable(inst)
		MakeSmallPropagator(inst)
		inst.components.burnable:SetOnBurntFn(OnBurnt)

		MakeHauntableIgnite(inst)

		inst:ListenForEvent("on_planted", OnPlanted)
		inst:ListenForEvent("ty_paddy_wetness_changed", function(_, data)
			OnPaddyWetnessChanged(inst, data)
		end, TheWorld)
		inst:WatchWorldState("iswinter", function()
			OnSeasonTick(inst)
		end)

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
		inst.OnLoadPostPass = OnLoadPostPass

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return MakeRice(1),
	MakeRice(2),
	MakeRice(3),
	MakeRice(4),
	MakeRice(5)
