--[[
	资源场（矿场 / 林场）：
	默认不可采集（隐藏 show 层）。timer 再生（官方 LongUpdate），
	到期后可空手采集若干次；采空后再等再生。
]]

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

local function RollPicksLeft(def)
	local min = TUNING[def.loot_min_key] or 10
	local max = TUNING[def.loot_max_key] or 13
	return math.random(min, max)
end

local function GetRegenTime(def)
	return (TUNING[def.regen_days_key] or 2) * (TUNING.TOTAL_DAY_TIME or 480)
end

local function StartRegenTimer(inst, def)
	if inst.components.timer == nil then
		return
	end
	if inst.components.timer:TimerExists(REGEN_TIMER) then
		inst.components.timer:StopTimer(REGEN_TIMER)
	end
	inst.components.timer:StartTimer(REGEN_TIMER, GetRegenTime(def))
end

local function SetPickableEnabled(inst, enabled)
	local pickable = inst.components.pickable
	if pickable == nil then
		return
	end
	pickable.canbepicked = enabled == true
	pickable.caninteractwith = true
end

local function SetHarvestable(inst, def, harvestable, picksleft)
	inst._harvestable:set(harvestable == true)
	ApplyShowLayer(inst)

	if harvestable then
		if inst.components.timer ~= nil and inst.components.timer:TimerExists(REGEN_TIMER) then
			inst.components.timer:StopTimer(REGEN_TIMER)
		end
		inst._picks_left = picksleft or RollPicksLeft(def)
		SetPickableEnabled(inst, true)
	else
		inst._picks_left = 0
		SetPickableEnabled(inst, false)
		if inst.components.timer ~= nil and not inst.components.timer:TimerExists(REGEN_TIMER) then
			StartRegenTimer(inst, def)
		end
	end
end

local function DropLoot(inst, def)
	local loot = def.roll_loot()
	if loot ~= nil and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SpawnLootPrefab(loot)
	end
end

local function OnPicked(inst, picker)
	local def = inst._farm_def
	if def == nil then
		return
	end

	DropLoot(inst, def)

	local left = (inst._picks_left or 1) - 1
	inst._picks_left = left

	-- Pick() 在 onpickedfn 之后会把 canbepicked 置 false，需延后处理
	inst:DoTaskInTime(0, function()
		if not inst:IsValid() then
			return
		end
		if left > 0 then
			SetPickableEnabled(inst, true)
		else
			SetHarvestable(inst, def, false)
		end
	end)
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == REGEN_TIMER then
		SetHarvestable(inst, inst._farm_def, true)
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
	if data.harvestable then
		data.picksleft = inst._picks_left
	end
end

local function OnLoad(inst, data)
	if data == nil then
		return
	end
	local def = inst._farm_def
	if data.harvestable then
		SetHarvestable(inst, def, true, data.picksleft)
	else
		SetHarvestable(inst, def, false)
	end
end

local function MakeResourceFarm(def)
	local assets = {
		Asset("ANIM", "anim/" .. def.build .. ".zip"),
	}
	if def.override_build ~= nil then
		table.insert(assets, Asset("ANIM", "anim/" .. def.override_build .. ".zip"))
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, def.physics_radius or 1.5)

		inst.AnimState:SetBank(def.bank)
		inst.AnimState:SetBuild(def.build)
		if def.override_build ~= nil then
			inst.AnimState:AddOverrideBuild(def.override_build)
		end
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:Hide(SHOW_LAYER)

		inst:AddTag(def.tag)
		if def.extra_tags ~= nil then
			for _, tag in ipairs(def.extra_tags) do
				inst:AddTag(tag)
			end
		end

		inst._harvestable = net_bool(inst.GUID, def.name .. "._harvestable", def.name .. "_harvestable_dirty")
		inst._harvestable:set(false)
		inst:ListenForEvent(def.name .. "_harvestable_dirty", ApplyShowLayer)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst._farm_def = def
		inst._picks_left = 0

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = getstatus

		inst:AddComponent("lootdropper")

		inst:AddComponent("timer")
		inst:ListenForEvent("timerdone", OnTimerDone)

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = def.picksound
		inst.components.pickable.onpickedfn = OnPicked
		inst.components.pickable.canbepicked = false
		inst.components.pickable.caninteractwith = true
		-- 不用 pickable 自带 regen / product，由 timer + _picks_left 管

		SetHarvestable(inst, def, false)

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

		return inst
	end

	return Prefab(def.name, fn, assets, def.prefabs)
end

--------------------------------------------------------------------------

local mine = MakeResourceFarm({
	name = "ty_mine",
	tag = "ty_mine",
	extra_tags = { "boulder" },
	bank = "ty_mine",
	build = "ty_mine",
	physics_radius = 1.5,
	picksound = "dontstarve/wilson/use_pick_rock",
	regen_days_key = "TY_MINE_REGEN_DAYS",
	loot_min_key = "TY_MINE_LOOT_MIN",
	loot_max_key = "TY_MINE_LOOT_MAX",
	prefabs = { "rocks", "flint" },
	roll_loot = function()
		return math.random() < 0.5 and "flint" or "rocks"
	end,
})

local forestfarm = MakeResourceFarm({
	name = "ty_forestfarm",
	tag = "ty_forestfarm",
	bank = "ty_forestfarm",
	build = "ty_forestfarm",
	override_build = "evergreen_new",
	physics_radius = 1.5,
	picksound = "dontstarve/wilson/pickup_wood",
	regen_days_key = "TY_FORESTFARM_REGEN_DAYS",
	loot_min_key = "TY_FORESTFARM_LOOT_MIN",
	loot_max_key = "TY_FORESTFARM_LOOT_MAX",
	prefabs = { "log", "pinecone" },
	roll_loot = function()
		-- 偶发松果，其余木头
		if math.random() < (TUNING.TY_FORESTFARM_PINECONE_CHANCE or 0.2) then
			return "pinecone"
		end
		return "log"
	end,
})

return mine, forestfarm
