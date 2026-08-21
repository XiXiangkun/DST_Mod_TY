--[[
	大黄狗 brain：追击当前目标，否则在出生点附近游荡。
]]

require "behaviours/chaseandattack"
require "behaviours/wander"

local MAX_WANDER_DIST = TUNING.TY_TUGOU_WANDER_DIST or 20
local MAX_CHASE_TIME = 8

local function GetHomePos(inst)
	return inst.components.knownlocations ~= nil
		and inst.components.knownlocations:GetLocation("home")
		or nil
end

local TyTugouBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function TyTugouBrain:OnStart()
	local root = PriorityNode({
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
	}, .25)

	self.bt = BT(self.inst, root)
end

return TyTugouBrain
