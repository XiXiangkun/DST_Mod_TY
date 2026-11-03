local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local Ripple = require("ty_paddy_ripple")

local function AddPaddyManager(inst)
	if inst.ismastersim then
		inst:AddComponent("ty_paddy_manager")
		inst:AddComponent("ty_fisherman_manager")
	end
end

local function AddProsperityComponent(inst)
	if inst.ismastersim then
		inst:AddComponent("ty_prosperity")
	end
end

-- net 挂在 world_network 上，客户端才能稳定收到 dirty
local function AddProsperityNet(inst)
	inst._ty_prosperity = net_uint(inst.GUID, "ty._prosperity", "ty_prosperity_dirty")
	-- 若组件已先于 network 创建，补一次同步
	if TheWorld.ismastersim
		and TheWorld.components.ty_prosperity ~= nil then
		TheWorld.components.ty_prosperity:Sync()
	end
end

local function AddCreatureRippleScanner(inst)
	if TheNet:IsDedicated() then
		return
	end
	if TUNING.TY_PADDY_CREATURE_RIPPLE == false then
		return
	end
	if inst._ty_creature_ripple_task ~= nil then
		return
	end
	inst._ty_creature_ripple_task = inst:DoPeriodicTask(0.5, function()
		Ripple.ScanCreatures()
	end)
end

local function OnWorld(inst)
	AddProsperityComponent(inst)
	AddPaddyManager(inst)
	AddCreatureRippleScanner(inst)
end

TYENV.AddPrefabPostInit("world", OnWorld)
TYENV.AddPrefabPostInit("cave", OnWorld)
TYENV.AddPrefabPostInit("forest_network", AddProsperityNet)
TYENV.AddPrefabPostInit("cave_network", AddProsperityNet)
