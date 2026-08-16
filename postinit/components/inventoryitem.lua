-- 会沉掉落物：湿田脚下挂漂浮波纹；落地时给落水初值湿度

local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local Ripple = require("ty_paddy_ripple")

local function OnLanded(inst)
	if not TheWorld.ismastersim then
		return
	end
	if not Ripple.IsSoakingInPaddy(inst) then
		return
	end
	local inv = inst.components.inventoryitem
	if inv ~= nil and inv.MakeMoistureAtLeast ~= nil then
		inv:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS or 75)
	end
end

TYENV.AddComponentPostInit("inventoryitem", function(self, inst)
	local old_SetSinks = self.SetSinks
	function self:SetSinks(should_sink)
		old_SetSinks(self, should_sink)
		Ripple.MarkSinkable(self.inst, should_sink == true)
	end

	if self.sinks then
		Ripple.MarkSinkable(inst, true)
	end

	if TheWorld.ismastersim then
		inst:ListenForEvent("on_landed", OnLanded)
	end
end)

-- 客户端用 replica 刷新波纹（float_fx 是本地特效）
TYENV.AddClassPostConstruct("components/inventoryitem_replica", function(self)
	if TheNet:IsDedicated() then
		return
	end
	local inst = self.inst
	inst:DoTaskInTime(0, function()
		if not inst:IsValid() then
			return
		end
		inst:DoPeriodicTask(0.5, function()
			Ripple.Update(inst)
		end)
	end)
end)
