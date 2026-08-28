local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local Ripple = require("ty_paddy_ripple")

local function AddPaddyManager(inst)
	if inst.ismastersim then
		inst:AddComponent("ty_paddy_manager")
		inst:AddComponent("ty_fisherman_manager")
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
	AddPaddyManager(inst)
	AddCreatureRippleScanner(inst)
end

TYENV.AddPrefabPostInit("world", OnWorld)
TYENV.AddPrefabPostInit("cave", OnWorld)
