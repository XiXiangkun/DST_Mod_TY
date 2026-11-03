--[[
	世界繁荣度（主机）。
	显示上限见 TUNING.TY_PROSPERITY_DISPLAY_MAX；逻辑值可超过该上限。
]]

local TyProsperity = Class(function(self, inst)
	assert(TheWorld.ismastersim, "ty_prosperity should not exist on the client!")

	self.inst = inst
	self.value = 0

	self:Sync()
	-- TheWorld.net 可能晚于本组件创建，下一帧再刷一次
	self.inst:DoTaskInTime(0, function()
		if self.inst:IsValid() then
			self:Sync()
		end
	end)
end)

local function ClampNonNegInt(n)
	n = math.floor(tonumber(n) or 0)
	if n < 0 then
		return 0
	end
	return n
end

function TyProsperity:Get()
	return self.value
end

function TyProsperity:Sync()
	-- 优先写 TheWorld.net（客户端同步更稳）；兼容旧的 world 挂载
	local netinst = TheWorld ~= nil and TheWorld.net or nil
	if netinst ~= nil and netinst._ty_prosperity ~= nil then
		netinst._ty_prosperity:set(self.value)
	elseif self.inst._ty_prosperity ~= nil then
		self.inst._ty_prosperity:set(self.value)
	end
	-- 主机 HUD 直接听这个本地事件，不依赖 net dirty
	self.inst:PushEvent("ty_prosperity_changed", self.value)
end

function TyProsperity:Set(n)
	local next_value = ClampNonNegInt(n)
	if self.value == next_value then
		return self.value
	end
	self.value = next_value
	self:Sync()
	return self.value
end

function TyProsperity:Add(n, reason)
	n = tonumber(n) or 0
	if n <= 0 then
		return self.value
	end
	self.value = ClampNonNegInt(self.value + n)
	self:Sync()
	return self.value
end

function TyProsperity:GetSortedUnlocks()
	local list = TUNING.TY_PROSPERITY_UNLOCKS
	if list == nil or #list == 0 then
		return {}
	end
	local sorted = {}
	for i, entry in ipairs(list) do
		if entry ~= nil and entry.threshold ~= nil then
			sorted[#sorted + 1] = entry
		end
	end
	table.sort(sorted, function(a, b)
		return (a.threshold or 0) < (b.threshold or 0)
	end)
	return sorted
end

function TyProsperity:GetNextUnlock()
	local value = self.value
	for _, entry in ipairs(self:GetSortedUnlocks()) do
		if value < (entry.threshold or 0) then
			return entry
		end
	end
	return nil
end

function TyProsperity:CanUnlock(id)
	if id == nil then
		return false
	end
	for _, entry in ipairs(self:GetSortedUnlocks()) do
		if entry.id == id then
			return self.value >= (entry.threshold or 0)
		end
	end
	return false
end

function TyProsperity:OnSave()
	return {
		value = self.value,
	}
end

function TyProsperity:OnLoad(data)
	if data ~= nil and data.value ~= nil then
		self.value = ClampNonNegInt(data.value)
		self:Sync()
	end
end

function TyProsperity:GetDebugString()
	local next_unlock = self:GetNextUnlock()
	local next_str = next_unlock ~= nil
		and string.format("%s@%d", tostring(next_unlock.id), next_unlock.threshold or 0)
		or "none"
	return string.format("value=%d next=%s", self.value, next_str)
end

return TyProsperity
