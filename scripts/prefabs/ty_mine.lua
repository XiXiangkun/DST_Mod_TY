--[[
	矿场：默认不可采集（隐藏 show 层）。用 timer 再生（官方 LongUpdate），
	2 天后可挖 10~13 次，每次掉落燧石或石头；采空后再等 2 天。
]]

local assets =
{
	Asset("ANIM", "anim/ty_mine.zip"),
}

local prefabs =
{
	"rocks",
	"flint",
}

local SHOW_LAYER = "show"
local REGEN_TIMER = "regen"

local function ApplyShowLayer(inst)
	if inst.AnimState == nil or inst._harvestable == nil then
		return
	end
	if inst._harvestable:value() then
		inst.AnimState:Show(SHOW_LAYER)
	else
		inst.AnimState:Hide(SHOW_LAYER)
	end
end

local function RollWorkLeft()
	local min = TUNING.TY_MINE_LOOT_MIN or 10
	local max = TUNING.TY_MINE_LOOT_MAX or 13
	return math.random(min, max)
end

local function GetRegenTime()
	return (TUNING.TY_MINE_REGEN_DAYS or 2) * (TUNING.TOTAL_DAY_TIME or 480)
end

local function StartRegenTimer(inst)
	if inst.components.timer == nil then
		return
	end
	if inst.components.timer:TimerExists(REGEN_TIMER) then
		inst.components.timer:StopTimer(REGEN_TIMER)
	end
	inst.components.timer:StartTimer(REGEN_TIMER, GetRegenTime())
end

local function SetHarvestable(inst, harvestable, workleft)
	inst._harvestable:set(harvestable == true)
	ApplyShowLayer(inst)

	if inst.components.workable == nil then
		return
	end

	if harvestable then
		if inst.components.timer ~= nil and inst.components.timer:TimerExists(REGEN_TIMER) then
			inst.components.timer:StopTimer(REGEN_TIMER)
		end
		inst.components.workable:SetWorkable(true)
		inst.components.workable:SetWorkLeft(workleft or RollWorkLeft())
	else
		inst.components.workable:SetWorkable(false)
		if inst.components.timer ~= nil and not inst.components.timer:TimerExists(REGEN_TIMER) then
			StartRegenTimer(inst)
		end
	end
end

local function OnWork(inst, worker, workleft)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pick_rock")
	local loot = math.random() < 0.5 and "flint" or "rocks"
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SpawnLootPrefab(loot)
	end
	if workleft <= 0 then
		SetHarvestable(inst, false)
	end
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == REGEN_TIMER then
		SetHarvestable(inst, true)
	end
end

local function getstatus(inst)
	if inst._harvestable ~= nil and inst._harvestable:value() then
		return "READY"
	end
	return "DEPLETED"
end

local function OnSave(inst, data)
	data.harvestable = inst._harvestable ~= nil and inst._harvestable:value() or false
	if data.harvestable and inst.components.workable ~= nil then
		data.workleft = inst.components.workable.workleft
	end
end

local function OnLoad(inst, data)
	if data == nil then
		return
	end
	if data.harvestable then
		SetHarvestable(inst, true, data.workleft)
	else
		SetHarvestable(inst, false)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1.5)

	inst.AnimState:SetBank("ty_mine")
	inst.AnimState:SetBuild("ty_mine")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:Hide(SHOW_LAYER)

	inst:AddTag("boulder")
	inst:AddTag("ty_mine")

	inst._harvestable = net_bool(inst.GUID, "ty_mine._harvestable", "ty_mine_harvestable_dirty")
	inst._harvestable:set(false)
	inst:ListenForEvent("ty_mine_harvestable_dirty", ApplyShowLayer)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("lootdropper")

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", OnTimerDone)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnWorkCallback(OnWork)
	inst.components.workable.savestate = true
	SetHarvestable(inst, false)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("ty_mine", fn, assets, prefabs)
