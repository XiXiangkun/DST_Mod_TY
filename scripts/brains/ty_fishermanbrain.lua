require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/chattynode"
require "behaviours/leash"
require "behaviours/standstill"

local MAX_WANDER_DIST = TUNING.TY_FISHERMAN_WANDER_DIST
local LEASH_MAX_DIST = TUNING.TY_FISHERMAN_LEASH_MAX
local LEASH_RETURN_DIST = TUNING.TY_FISHERMAN_LEASH_RETURN
local START_FACE_DIST = TUNING.TY_FISHERMAN_FACE_DIST
local KEEP_FACE_DIST = TUNING.TY_FISHERMAN_KEEP_FACE_DIST
local ARRIVE_DIST = TUNING.TY_FISHERMAN_SHOP_ARRIVE_DIST or 2.2

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

local function EnsureShop(inst)
	if inst._shop ~= nil and inst._shop:IsValid() then
		return inst._shop
	end
	local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
	if home ~= nil and home:IsValid() then
		local util = require("ty_fisherman_shop_util")
		local shop = util.EnsureShopForHouse(home)
		if shop ~= nil then
			inst._shop = shop
			shop._ty_fisherman = inst
		end
	end
	return inst._shop
end

local function GetShopStallPos(inst)
	local shop = EnsureShop(inst)
	if shop == nil then
		return nil
	end
	if shop.GetStallPosition ~= nil then
		return shop:GetStallPosition()
	end
	return shop:GetPosition()
end

local function HasShop(inst)
	return EnsureShop(inst) ~= nil
end

local function IsNearStall(inst)
	local shop = EnsureShop(inst)
	if shop == nil then
		return false
	end
	local pos = GetShopStallPos(inst)
	if pos == nil then
		return false
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local dx, dz = x - pos.x, z - pos.z
	return (dx * dx + dz * dz) <= (ARRIVE_DIST * ARRIVE_DIST)
end

local function SetTending(inst, tending)
	tending = tending and true or false
	inst._tending_shop = tending
	local shop = EnsureShop(inst)
	if shop ~= nil and shop.components.ty_fisherman_shop ~= nil then
		shop.components.ty_fisherman_shop:SetTending(tending)
	end
end

local function KeepTending(inst)
	if not IsNearStall(inst) then
		if inst._tending_shop then
			SetTending(inst, false)
		end
		return false
	end
	if not inst._tending_shop then
		SetTending(inst, true)
	end
	return true
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

local FishermanBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function FishermanBrain:OnStart()
	local day = WhileNode(function() return TheWorld.state.isday end, "IsDay",
		PriorityNode({
			-- 有铺：去摊 / 守摊
			WhileNode(function() return HasShop(self.inst) end, "HasShop",
				PriorityNode({
					WhileNode(function() return KeepTending(self.inst) end, "TendShop",
						PriorityNode({
							ChattyNode(self.inst, "TY_FISHERMAN_TALK_LOOKATWILSON",
								FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn), 6, 6),
							StandStill(self.inst),
						}, .5)),
					Leash(self.inst, GetShopStallPos, ARRIVE_DIST, 0.5),
				}, .5)),
			-- 无铺兜底：旧行为
			Leash(self.inst, GetHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
			ChattyNode(self.inst, "TY_FISHERMAN_TALK_LOOKATWILSON",
				FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn), 6, 6),
			Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
		}, .5))

	local night = WhileNode(function() return not TheWorld.state.isday end, "IsNight",
		PriorityNode({
			ChattyNode(self.inst, "TY_FISHERMAN_TALK_GO_HOME",
				DoAction(self.inst, function()
					SetTending(self.inst, false)
					return GoHomeAction(self.inst)
				end, "go home", true)),
			Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
		}, 1))

	local root = PriorityNode({
		day,
		night,
	}, .5)

	self.bt = BT(self.inst, root)
end

return FishermanBrain
