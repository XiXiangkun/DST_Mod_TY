--[[
	渔夫世界管理：唯一小屋 + 唯一挂牌铺。
	实体通过 TheWorld:PushEvent 自行注册；组件只持有实体引用，不存 GUID。
]]

local function IsSameIslandPlaceholder(_a, _b)
	-- 占位：日后接陆地连通 / 岛屿判定
	return true
end

local TyFishermanManager = Class(function(self, inst)
	assert(TheWorld.ismastersim, "ty_fisherman_manager should not exist on the client!")

	self.inst = inst
	self.house = nil
	self.licensed_shop = nil
	self.fisherman = nil
	self.registered_entities = {}

	self.inst:ListenForEvent("ty_register_fisherman_house", function(_, ent)
		self:RegisterHouse(ent)
	end, TheWorld)

	self.inst:ListenForEvent("ty_register_licensed_shop", function(_, ent)
		self:RegisterLicensedShop(ent)
	end, TheWorld)

	self.inst:ListenForEvent("ty_register_fisherman", function(_, ent)
		self:RegisterFisherman(ent)
	end, TheWorld)
end)

function TyFishermanManager:_WatchRemove(ent, slot)
	if ent == nil then
		return
	end
	self.registered_entities[ent] = slot
	ent:ListenForEvent("onremove", function(removed)
		local stored = self.registered_entities[removed]
		if stored == nil then
			return
		end
		self.registered_entities[removed] = nil
		if self[stored] == removed then
			self[stored] = nil
		end
		if stored == "licensed_shop" then
			self:OnLicensedShopRemoved(removed)
		elseif stored == "house" then
			self:OnHouseRemoved(removed)
		end
	end)
end

function TyFishermanManager:HasHouse()
	return self.house ~= nil and self.house:IsValid()
end

function TyFishermanManager:HasLicensedShop()
	return self.licensed_shop ~= nil and self.licensed_shop:IsValid()
end

function TyFishermanManager:GetHouse()
	if self.house ~= nil and self.house:IsValid() then
		return self.house
	end
	return nil
end

function TyFishermanManager:GetLicensedShop()
	if self.licensed_shop ~= nil and self.licensed_shop:IsValid() then
		return self.licensed_shop
	end
	return nil
end

function TyFishermanManager:GetFisherman()
	if self.fisherman ~= nil and self.fisherman:IsValid() then
		return self.fisherman
	end
	local house = self:GetHouse()
	if house ~= nil and house.components.spawner ~= nil then
		local child = house.components.spawner.child
		if child ~= nil and child:IsValid() and child:HasTag("ty_fisherman") then
			self.fisherman = child
			return child
		end
	end
	return nil
end

function TyFishermanManager:RegisterHouse(ent)
	if ent == nil or not ent:IsValid() then
		return false
	end
	if self.house == ent then
		return true
	end
	if self:HasHouse() then
		return false
	end
	self.house = ent
	self:_WatchRemove(ent, "house")
	return true
end

function TyFishermanManager:RegisterLicensedShop(ent)
	if ent == nil or not ent:IsValid() then
		return false
	end
	if self.licensed_shop == ent then
		self:NotifyFishermanOpenShop()
		return true
	end
	if self:HasLicensedShop() then
		return false
	end
	self.licensed_shop = ent
	self:_WatchRemove(ent, "licensed_shop")
	self:NotifyFishermanOpenShop()
	return true
end

function TyFishermanManager:RegisterFisherman(ent)
	if ent == nil or not ent:IsValid() or not ent:HasTag("ty_fisherman") then
		return false
	end
	if self.fisherman == ent then
		if TheWorld.state.isday then
			self:NotifyFishermanOpenShop()
		end
		return true
	end
	self.fisherman = ent
	self:_WatchRemove(ent, "fisherman")
	if TheWorld.state.isday then
		self:NotifyFishermanOpenShop()
	end
	return true
end

function TyFishermanManager:OnLicensedShopRemoved(shop)
	local fisher = self:GetFisherman()
	if fisher ~= nil then
		fisher._tending_shop = false
		fisher._shop = nil
		if shop ~= nil and shop:IsValid() and shop.components.ty_fisherman_shop ~= nil then
			shop.components.ty_fisherman_shop:SetTending(false)
		end
	end
end

function TyFishermanManager:OnHouseRemoved(house)
	-- 挂牌保留（方案：拆屋不摘牌）；渔夫随 spawner 移除
	self.fisherman = nil
end

function TyFishermanManager:IsSameIsland(a, b)
	return IsSameIslandPlaceholder(a, b)
end

function TyFishermanManager:GetShopMaxDist()
	return TUNING.TY_FISHERMAN_SHOP_MAX_DIST or 60
end

function TyFishermanManager:IsShopReachable(shop)
	shop = shop or self:GetLicensedShop()
	local house = self:GetHouse()
	if shop == nil or house == nil then
		return false
	end
	if not self:IsSameIsland(house, shop) then
		return false
	end
	local maxd = self:GetShopMaxDist()
	local hx, _, hz = house.Transform:GetWorldPosition()
	local sx, _, sz = shop.Transform:GetWorldPosition()
	local dx, dz = hx - sx, hz - sz
	return (dx * dx + dz * dz) <= (maxd * maxd)
end

function TyFishermanManager:CanLicenseShop(shop, doer)
	if shop == nil or not shop:IsValid() then
		return false, "INVALID"
	end
	if shop.components.ty_fisherman_shop ~= nil and shop.components.ty_fisherman_shop:IsLicensed() then
		return false, "ALREADY"
	end
	if self:HasLicensedShop() then
		return false, "BUSY"
	end
	if not self:HasHouse() then
		return false, "NOHOUSE"
	end
	if not self:IsShopReachable(shop) then
		return false, "TOOFAR"
	end
	local currency = TUNING.TY_FISHERMAN_SHOP_LICENSE_ITEM or "transistor"
	local cost = TUNING.TY_FISHERMAN_SHOP_LICENSE_COST or 1
	if doer ~= nil and doer.components.inventory ~= nil then
		local ok = doer.components.inventory:Has(currency, cost)
		if not ok then
			return false, "NOITEM"
		end
	end
	return true
end

function TyFishermanManager:TryLicenseShop(shop, doer)
	local ok, reason = self:CanLicenseShop(shop, doer)
	if not ok then
		return false, reason
	end
	local currency = TUNING.TY_FISHERMAN_SHOP_LICENSE_ITEM or "transistor"
	local cost = TUNING.TY_FISHERMAN_SHOP_LICENSE_COST or 1
	if doer ~= nil and doer.components.inventory ~= nil and cost > 0 then
		doer.components.inventory:ConsumeByName(currency, cost)
	end
	if shop.components.ty_fisherman_shop ~= nil then
		shop.components.ty_fisherman_shop:SetLicensed(true)
	end
	TheWorld:PushEvent("ty_register_licensed_shop", shop)
	return true
end

function TyFishermanManager:NotifyFishermanOpenShop()
	if not TheWorld.state.isday then
		return
	end
	local shop = self:GetLicensedShop()
	if shop == nil or not self:IsShopReachable(shop) then
		return
	end
	local fisher = self:GetFisherman()
	if fisher == nil then
		return
	end
	-- 在家则等白天放出；已出门则立刻改目标
	local home = fisher.components.homeseeker ~= nil and fisher.components.homeseeker.home or nil
	if home ~= nil and home.components.spawner ~= nil and home.components.spawner:IsOccupied() then
		return
	end
	fisher._shop = shop
	fisher:PushEvent("ty_go_open_shop")
	if fisher:IsAsleep() then
		fisher:ForceFacePoint(shop.Transform:GetWorldPosition())
	end
end

-- 不存实体 / GUID；挂牌态由摊自身 OnSave
function TyFishermanManager:OnSave()
	return nil
end

function TyFishermanManager:OnLoad(data)
end

return TyFishermanManager
