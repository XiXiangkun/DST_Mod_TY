local AddPrefabPostInit = AddPrefabPostInit

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function AddPaddyManager(inst)
	if inst.ismastersim then
		inst:AddComponent("ty_paddy_manager")
	end
end
AddPrefabPostInit("world", AddPaddyManager)
AddPrefabPostInit("cave", AddPaddyManager)