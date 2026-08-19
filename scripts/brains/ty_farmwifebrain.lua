require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/chattynode"
require "behaviours/leash"

local MAX_WANDER_DIST = TUNING.TY_FARMWIFE_WANDER_DIST
local LEASH_MAX_DIST = TUNING.TY_FARMWIFE_LEASH_MAX
local LEASH_RETURN_DIST = TUNING.TY_FARMWIFE_LEASH_RETURN
local START_FACE_DIST = TUNING.TY_FARMWIFE_FACE_DIST
local KEEP_FACE_DIST = TUNING.TY_FARMWIFE_KEEP_FACE_DIST

local function HasValidHome(inst)
	local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
	return home ~= nil and home:IsValid()
end

local function GetHomePos(inst)
	if HasValidHome(inst) then
		return inst.components.homeseeker:GetHomePos()
	end
	return inst.components.knownlocations:GetLocation("home")
end

local function GoHomeAction(inst)
	if HasValidHome(inst) then
		return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
	end
end

local function GetFaceTargetFn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local player = FindClosestPlayerInRange(x, y, z, START_FACE_DIST, true)
	if player ~= nil and not player:HasTag("notarget") then
		return player
	end
end

local function KeepFaceTargetFn(inst, target)
	return target ~= nil
		and target:IsValid()
		and not target:HasTag("notarget")
		and inst:IsNear(target, KEEP_FACE_DIST)
end

local FarmwifeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function FarmwifeBrain:OnStart()
	local day = WhileNode(function() return TheWorld.state.isday end, "IsDay",
		PriorityNode({
			Leash(self.inst, GetHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
			ChattyNode(self.inst, "TY_FARMWIFE_TALK_LOOKATWILSON",
				FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn), 6, 6),
			Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
		}, .5))

	local night = WhileNode(function() return not TheWorld.state.isday end, "IsNight",
		PriorityNode({
			ChattyNode(self.inst, "TY_FARMWIFE_TALK_GO_HOME",
				DoAction(self.inst, GoHomeAction, "go home", true)),
			Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
		}, 1))

	local root = PriorityNode({
		day,
		night,
	}, .5)

	self.bt = BT(self.inst, root)
end

return FarmwifeBrain
