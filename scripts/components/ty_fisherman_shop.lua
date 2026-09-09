--[[
	渔夫铺面：日出刷库存、到摊可买、黄昏清空、单人锁。
	slots[1..12] = { prefab=, price=, stock= } 或 nil（空格）
	布局 4 列 × 3 行，索引行优先：row0 col0 = 1 …；第 3 行后两格(11,12)为稀有。
]]

local function CatalogLookup()
	local map = {}
	local function add(list)
		for i = 1, #list do
			local e = list[i]
			map[e.prefab] = e
		end
	end
	add(TUNING.TY_FISHERMAN_SHOP_COMMON or {})
	add(TUNING.TY_FISHERMAN_SHOP_RARE or {})
	return map
end

local function ShuffleCopy(list)
	local t = {}
	for i = 1, #list do
		t[i] = list[i]
	end
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function EncodeSlots(slots)
	local parts = {}
	for i = 1, 12 do
		local s = slots[i]
		-- 售罄也同步 prefab/price/stock=0，UI 仍显示图案
		if s ~= nil and s.prefab ~= nil then
			parts[i] = string.format("%s:%d:%d", s.prefab, s.price or 0, s.stock or 0)
		else
			parts[i] = ""
		end
	end
	return table.concat(parts, ";")
end

local function DecodeSlots(str)
	local slots = {}
	if type(str) ~= "string" or str == "" then
		return slots
	end
	local i = 1
	for part in string.gmatch(str .. ";", "([^;]*);") do
		if part ~= "" then
			local prefab, price, stock = string.match(part, "^([^:]+):(%d+):(%d+)$")
			if prefab ~= nil then
				slots[i] = {
					prefab = prefab,
					price = tonumber(price) or 0,
					stock = tonumber(stock) or 0,
				}
			end
		end
		i = i + 1
		if i > 12 then
			break
		end
	end
	return slots
end

local TyFishermanShop = Class(function(self, inst)
	self.inst = inst
	self.slots = {}
	self.tending = false
	self.licensed = false
	self.lock_userid = nil
	self.lock_task = nil
	self._catalog = CatalogLookup()

	inst:ListenForEvent("ty_shop_stock_dirty", function()
		if not TheWorld.ismastersim then
			self.slots = DecodeSlots(inst._stock_str:value())
			self.tending = inst._tending:value()
			if inst._licensed ~= nil then
				self.licensed = inst._licensed:value()
			end
			inst:PushEvent("ty_shop_ui_dirty")
		end
	end)

	if not TheWorld.ismastersim and inst._stock_str ~= nil then
		self.slots = DecodeSlots(inst._stock_str:value())
		self.tending = inst._tending ~= nil and inst._tending:value() or false
		self.licensed = inst._licensed ~= nil and inst._licensed:value() or false
	end
end)

function TyFishermanShop:OnRemoveFromEntity()
	self:ReleaseLock()
	self:SetTending(false)
end

function TyFishermanShop:Sync()
	if not TheWorld.ismastersim then
		return
	end
	if self.inst._stock_str ~= nil then
		self.inst._stock_str:set(EncodeSlots(self.slots))
	end
	if self.inst._tending ~= nil then
		self.inst._tending:set(self.tending)
	end
	if self.inst._licensed ~= nil then
		self.inst._licensed:set(self.licensed)
	end
	self.inst:PushEvent("ty_shop_ui_dirty")
end

function TyFishermanShop:IsLicensed()
	if not TheWorld.ismastersim and self.inst._licensed ~= nil then
		return self.inst._licensed:value()
	end
	return self.licensed
end

function TyFishermanShop:SetLicensed(licensed)
	licensed = licensed and true or false
	if self.licensed == licensed then
		return
	end
	self.licensed = licensed
	self.inst:AddOrRemoveTag("ty_shop_licensed", licensed)
	if licensed then
		if TheWorld.state.isday then
			self:RerollStock()
		end
	else
		self:SetTending(false)
		self:ClearStock()
	end
	self:Sync()
end

function TyFishermanShop:GetSlots()
	if not TheWorld.ismastersim and self.inst._stock_str ~= nil then
		self.slots = DecodeSlots(self.inst._stock_str:value())
		self.tending = self.inst._tending:value()
	end
	return self.slots
end

function TyFishermanShop:IsTending()
	if not TheWorld.ismastersim and self.inst._tending ~= nil then
		return self.inst._tending:value()
	end
	return self.tending
end

function TyFishermanShop:IsSoldOut()
	local slots = self:GetSlots()
	for i = 1, 12 do
		local s = slots[i]
		if s ~= nil and (s.stock or 0) > 0 then
			return false
		end
	end
	return true
end

function TyFishermanShop:ClearStock()
	self.slots = {}
	self:Sync()
end

function TyFishermanShop:RerollStock()
	if not self:IsLicensed() then
		return
	end
	local slots = {}
	local common = ShuffleCopy(TUNING.TY_FISHERMAN_SHOP_COMMON or {})
	local rare = ShuffleCopy(TUNING.TY_FISHERMAN_SHOP_RARE or {})
	local common_n = TUNING.TY_FISHERMAN_SHOP_COMMON_SLOTS or 10
	local rare_n = TUNING.TY_FISHERMAN_SHOP_RARE_SLOTS or 2

	for i = 1, common_n do
		local e = common[i]
		if e ~= nil then
			slots[i] = { prefab = e.prefab, price = e.price, stock = e.stock }
		end
	end
	for i = 1, rare_n do
		local e = rare[i]
		local idx = common_n + i
		if e ~= nil then
			slots[idx] = { prefab = e.prefab, price = e.price, stock = e.stock }
		end
	end

	self.slots = slots
	self:Sync()
end

function TyFishermanShop:SetTending(tending)
	tending = tending and true or false
	if tending and not self:IsLicensed() then
		tending = false
	end
	if self.tending == tending then
		return
	end
	self.tending = tending
	if not tending then
		self:ForceCloseUI()
		self:ReleaseLock()
	end
	self:Sync()
	self.inst:AddOrRemoveTag("ty_shop_tending", tending)
end

function TyFishermanShop:GetLockUserId()
	return self.lock_userid
end

function TyFishermanShop:IsLockedBy(userid)
	return self.lock_userid ~= nil and self.lock_userid == userid
end

function TyFishermanShop:IsLocked()
	return self.lock_userid ~= nil
end

function TyFishermanShop:_ClearLockTask()
	if self.lock_task ~= nil then
		self.lock_task:Cancel()
		self.lock_task = nil
	end
end

function TyFishermanShop:ReleaseLock()
	self:_ClearLockTask()
	self.lock_userid = nil
end

function TyFishermanShop:RefreshLockTimeout()
	self:_ClearLockTask()
	if self.lock_userid == nil then
		return
	end
	local t = TUNING.TY_FISHERMAN_SHOP_LOCK_TIME or 45
	self.lock_task = self.inst:DoTaskInTime(t, function()
		self.lock_task = nil
		local userid = self.lock_userid
		self.lock_userid = nil
		if userid ~= nil then
			self:SendCloseToUser(userid)
		end
	end)
end

function TyFishermanShop:TryAcquireLock(doer)
	if doer == nil or doer.userid == nil then
		return false, "busy"
	end
	if not self:IsLicensed() or not self:IsTending() then
		return false, "closed"
	end
	if self.lock_userid ~= nil and self.lock_userid ~= doer.userid then
		return false, "busy"
	end
	self.lock_userid = doer.userid
	self:RefreshLockTimeout()
	return true
end

function TyFishermanShop:SendCloseToUser(userid)
	if userid == nil then
		return
	end
	local player = UserToPlayer(userid)
	if player ~= nil then
		SendModRPCToClient(GetClientModRPC("ty", "FishermanShopForceClose"), player.userid, self.inst)
	end
end

function TyFishermanShop:ForceCloseUI()
	if self.lock_userid ~= nil then
		self:SendCloseToUser(self.lock_userid)
	end
end

function TyFishermanShop:TryOpen(doer)
	if doer == nil then
		return false
	end
	if not self:IsLicensed() or not self:IsTending() then
		return false
	end

	local ok, reason = self:TryAcquireLock(doer)
	if not ok then
		if reason == "busy" and doer.components.talker ~= nil then
			doer.components.talker:Say(STRINGS.TY_FISHERMAN_SHOP_BUSY)
		end
		return false
	end

	SendModRPCToClient(GetClientModRPC("ty", "FishermanShopOpen"), doer.userid, self.inst)
	return true
end

function TyFishermanShop:CloseFrom(doer)
	if doer ~= nil and self:IsLockedBy(doer.userid) then
		self:ReleaseLock()
	end
end

local function CountCurrency(doer, prefab)
	if doer.components.inventory == nil then
		return 0
	end
	local _, n = doer.components.inventory:Has(prefab, 1, true)
	return n or 0
end

local function ConsumeCurrency(doer, prefab, amount)
	if doer.components.inventory == nil or amount <= 0 then
		return false
	end
	if CountCurrency(doer, prefab) < amount then
		return false
	end
	doer.components.inventory:ConsumeByName(prefab, amount)
	return true
end

function TyFishermanShop:TryBuy(doer, slot_index)
	if doer == nil or not TheWorld.ismastersim then
		return false
	end
	slot_index = math.floor(tonumber(slot_index) or 0)
	if slot_index < 1 or slot_index > 12 then
		return false
	end
	if not self:IsLicensed() or not self:IsTending() then
		return false
	end
	if not self:IsLockedBy(doer.userid) then
		local ok = self:TryAcquireLock(doer)
		if not ok then
			return false
		end
	else
		self:RefreshLockTimeout()
	end

	local slot = self.slots[slot_index]
	if slot == nil or slot.prefab == nil or (slot.stock or 0) <= 0 then
		return false
	end

	local currency = TUNING.TY_FISHERMAN_SHOP_CURRENCY or "goldnugget"
	local price = slot.price or 0
	local prefab = slot.prefab
	if price > 0 and not ConsumeCurrency(doer, currency, price) then
		return false
	end

	slot.stock = math.max(0, (slot.stock or 0) - 1)
	self:Sync()

	local item = SpawnPrefab(prefab)
	if item ~= nil then
		local pos = doer:GetPosition()
		if doer.components.inventory ~= nil then
			doer.components.inventory:GiveItem(item, nil, pos)
		else
			item.Transform:SetPosition(pos:Get())
		end
	end
	return true
end

function TyFishermanShop:OnSave()
	local data = { tending = false, licensed = self.licensed, slots = {} }
	for i = 1, 12 do
		local s = self.slots[i]
		if s ~= nil then
			data.slots[i] = { prefab = s.prefab, price = s.price, stock = s.stock }
		end
	end
	return data
end

function TyFishermanShop:OnLoad(data)
	if data == nil then
		return
	end
	self.slots = {}
	if data.slots ~= nil then
		for i = 1, 12 do
			local s = data.slots[i]
			if s ~= nil and s.prefab ~= nil then
				self.slots[i] = {
					prefab = s.prefab,
					price = s.price or 0,
					stock = s.stock or 0,
				}
			end
		end
	end
	self.tending = false
	if data.licensed then
		self.licensed = true
		self.inst:AddTag("ty_shop_licensed")
		self.inst:DoTaskInTime(0, function()
			if self.inst:IsValid() and self.licensed then
				TheWorld:PushEvent("ty_register_licensed_shop", self.inst)
				self:Sync()
			end
		end)
	else
		self.licensed = false
	end
	self:Sync()
end

function TyFishermanShop:GetStatus()
	if not self:IsLicensed() then
		return "UNLICENSED"
	end
	if not self:IsTending() then
		return "CLOSED"
	end
	if self:IsSoldOut() then
		return "SOLDOUT"
	end
	return "OPEN"
end

TyFishermanShop.EncodeSlots = EncodeSlots
TyFishermanShop.DecodeSlots = DecodeSlots

return TyFishermanShop
