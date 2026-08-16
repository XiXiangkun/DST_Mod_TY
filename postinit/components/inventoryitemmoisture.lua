-- 会沉掉落物在湿田：湿度目标按「泡在水里」→ 持续趋向 MAX_WETNESS

local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local Ripple = require("ty_paddy_ripple")

TYENV.AddComponentPostInit("inventoryitemmoisture", function(self)
	local old_GetTargetMoisture = self.GetTargetMoisture
	function self:GetTargetMoisture(...)
		if Ripple.IsSoakingInPaddy(self.inst) then
			return TUNING.MAX_WETNESS
		end
		return old_GetTargetMoisture(self, ...)
	end
end)
