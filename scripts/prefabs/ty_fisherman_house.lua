--[[
	渔夫的家
	动画暂用官方 pig_house；spawner 绑定 ty_fisherman。
	白天放出渔夫，夜晚收回。参考官方 pighouse（DST）。
]]

local assets =
{
}

local prefabs =
{
	"ty_fisherman",
	"collapse_big",
}

local function LightsOn(inst)
	if not inst.lightson then
		inst.Light:Enable(true)
		inst.AnimState:PlayAnimation("lit", true)
		inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
		inst.lightson = true
	end
end

local function LightsOff(inst)
	if inst.lightson then
		inst.Light:Enable(false)
		inst.AnimState:PlayAnimation("idle", true)
		inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
		inst.lightson = false
	end
end

local function onfar(inst)
	if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
		LightsOn(inst)
	end
end

local function onnear(inst)
	if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
		LightsOff(inst)
	end
end

local function getstatus(inst)
	if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
		return inst.lightson and "FULL" or "LIGHTSOUT"
	end
	return nil
end

local function onoccupieddoortask(inst)
	inst.doortask = nil
	if inst.components.playerprox ~= nil and not inst.components.playerprox:IsPlayerClose() then
		LightsOn(inst)
	end
end

local function onoccupied(inst, child)
	inst.SoundEmitter:PlaySound("dontstarve/pig/pig_in_hut", "pigsound")
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")

	if inst.doortask ~= nil then
		inst.doortask:Cancel()
	end
	inst.doortask = inst:DoTaskInTime(1, onoccupieddoortask)
end

local function onvacate(inst, child)
	if inst.doortask ~= nil then
		inst.doortask:Cancel()
		inst.doortask = nil
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
	inst.SoundEmitter:KillSound("pigsound")
	LightsOff(inst)
end

local function onhammered(inst, worker)
	if inst.doortask ~= nil then
		inst.doortask:Cancel()
		inst.doortask = nil
	end

	local child = inst.components.spawner ~= nil and inst.components.spawner.child or nil
	inst:RemoveComponent("spawner")
	if child ~= nil then
		child:Remove()
	end

	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	if inst.lightson then
		inst.AnimState:PushAnimation("lit")
	else
		inst.AnimState:PushAnimation("idle")
	end
end

local function OnStartDay(inst)
	if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
		if inst.doortask ~= nil then
			inst.doortask:Cancel()
		end
		inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function()
			inst.doortask = nil
			if inst:IsValid() and inst.components.spawner ~= nil then
				LightsOff(inst)
				inst.components.spawner:ReleaseChild()
			end
		end)
	end
end

local function spawncheckday(inst)
	inst.inittask = nil
	inst:WatchWorldState("startcaveday", OnStartDay)
	if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
		if TheWorld.state.iscaveday or TheWorld.state.isday then
			inst.components.spawner:ReleaseChild()
		else
			inst.components.playerprox:ForceUpdate()
			onoccupieddoortask(inst)
		end
	end
end

local function oninit(inst)
	inst.inittask = inst:DoTaskInTime(math.random(), spawncheckday)
	if inst.components.spawner ~= nil
		and inst.components.spawner.child == nil
		and inst.components.spawner.childname ~= nil
		and not inst.components.spawner:IsSpawnPending() then
		local child = SpawnPrefab(inst.components.spawner.childname)
		if child ~= nil then
			inst.components.spawner:TakeOwnership(child)
			inst.components.spawner:GoHome(child)
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddLight()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

	inst.MiniMapEntity:SetIcon("pighouse.png")

	inst.Light:SetFalloff(1)
	inst.Light:SetIntensity(.5)
	inst.Light:SetRadius(1)
	inst.Light:Enable(false)
	inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

	inst.AnimState:SetBank("pig_house")
	inst.AnimState:SetBuild("pig_house")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("structure")
	inst:AddTag("ty_fisherman_house")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.lightson = false

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ "boards", "boards", "cutstone" })

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("spawner")
	inst.components.spawner:Configure("ty_fisherman", TUNING.TY_FISHERMAN_HOUSE_RESPAWN)
	inst.components.spawner.onoccupied = onoccupied
	inst.components.spawner.onvacate = onvacate
	inst.components.spawner:SetWaterSpawning(false, true)
	inst.components.spawner:CancelSpawning()

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(10, 13)
	inst.components.playerprox:SetOnPlayerNear(onnear)
	inst.components.playerprox:SetOnPlayerFar(onfar)

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	MakeSnowCovered(inst)

	inst.inittask = inst:DoTaskInTime(0, oninit)

	return inst
end

return Prefab("ty_fisherman_house", fn, assets, prefabs)
