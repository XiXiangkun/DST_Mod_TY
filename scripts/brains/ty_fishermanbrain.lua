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

local function GetManager()
	return TheWorld.components.ty_fisherman_manager
end

local function GetLicensedShop(inst)
	local mgr = GetManager()
	if mgr == nil then
		return nil
	end
	local shop = mgr:GetLicensedShop()
	if shop == nil or not shop:IsValid() then
		return nil
	end
	if not mgr:IsShopReachable(shop) then
		return nil
	end
	inst._shop = shop
	return shop
end

local function HasReachableShop(inst)
	return GetLicensedShop(inst) ~= nil
end

local function GetShopStallPos(inst)
	local shop = GetLicensedShop(inst)
	if shop == nil then
		return nil
	end
	if shop.GetStallPosition ~= nil then
		return shop:GetStallPosition()
	end
	return shop:GetPosition()
end

local function IsNearStall(inst)
	local shop = GetLicensedShop(inst)
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
	local shop = GetLicensedShop(inst)
	if shop ~= nil and shop.components.ty_fisherman_shop ~= nil then
		shop.components.ty_fisherman_shop:SetTending(tending)
	elseif not tending then
		-- 无可达摊时确保关掉旧摊
		local mgr = GetManager()
		local licensed = mgr ~= nil and mgr:GetLicensedShop() or nil
		if licensed ~= nil and licensed.components.ty_fisherman_shop ~= nil then
			licensed.components.ty_fisherman_shop:SetTending(false)
		end
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
			WhileNode(function() return HasReachableShop(self.inst) end, "HasLicensedShop",
				PriorityNode({
					WhileNode(function() return KeepTending(self.inst) end, "TendShop",
						PriorityNode({
							ChattyNode(self.inst, "TY_FISHERMAN_TALK_LOOKATWILSON",
								FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn), 6, 6),
							StandStill(self.inst),
						}, .5)),
					Leash(self.inst, GetShopStallPos, ARRIVE_DIST, 0.5),
				}, .5)),
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
