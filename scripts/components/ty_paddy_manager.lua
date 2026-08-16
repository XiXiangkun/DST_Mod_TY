--[[
	主机：水田水量（八向连通水域统一水位）、日耗、雨水补给、地皮湿/干与水面实体。
	水分按秒结算（OnUpdate + LongUpdate），跳时间会一起推进。
]]

local FLOATER_SCAN_RADIUS = (TILE_SCALE or 4) * 0.75
local FLOATER_CANT_TAGS = { "INLIMBO", "player", "FX", "DECOR", "CLASSIFIED", "ty_paddy_water" }

-- 八邻接（含斜角）
local NEIGHBOR_OFFSETS = {
	{ -1, -1 }, { 0, -1 }, { 1, -1 },
	{ -1,  0 },            { 1,  0 },
	{ -1,  1 }, { 0,  1 }, { 1,  1 },
}

local function TileKey(tx, ty)
	return tx .. "_" .. ty
end

local function ParseTileKey(key)
	local tx, ty = string.match(key, "^(%-?%d+)_(%-?%d+)$")
	return tonumber(tx), tonumber(ty)
end

-- 0~1。日耗用 SnapDry 只清掉浮点残渣（1e-6），不能用 0.001：
-- 否则「雨加一点 → 蒸发 SnapDry 归零」每帧振荡，水面闪烁且停雨立刻干。
local function Clamp01(water)
	return math.max(0, math.min(1, water or 0))
end

local function SnapDry(water)
	water = Clamp01(water)
	if water < 1e-6 then
		return 0
	end
	return water
end

-- 达到该水量才算「可见湿田」（切地皮 / 水面 / 通知水稻）
local function WetThreshold()
	return TUNING.TY_PADDY_WET_THRESHOLD or 0.01
end

local function IsVisiblyWet(water)
	return (water or 0) >= WetThreshold()
end

local function WaterDisplayBucket(water)
	return math.floor((water or 0) * 100 + 1e-6)
end

local function GetTier(water)
	if water == nil or water <= 0 then
		return "dry"
	elseif water >= 0.75 then
		return "full"
	elseif water >= 0.5 then
		return "mid"
	elseif water >= 0.25 then
		return "shallow"
	else
		return "nearly_dry"
	end
end

local TyPaddyManager = Class(function(self, inst)
	self.inst = inst
	self.tiles = {} -- [key] = { water = 0~1 }

	self.inst:StartUpdatingComponent(self)
end)

--------------------------------------------------------------------------
-- 连通水域

function TyPaddyManager:CollectBodyKeys(start_tx, start_ty)
	local start_key = TileKey(start_tx, start_ty)
	if self.tiles[start_key] == nil then
		return nil
	end

	local body = {}
	local visited = { [start_key] = true }
	local queue = { start_key }
	local qi = 1

	while qi <= #queue do
		local key = queue[qi]
		qi = qi + 1
		body[#body + 1] = key

		local tx, ty = ParseTileKey(key)
		if tx ~= nil then
			for i = 1, #NEIGHBOR_OFFSETS do
				local ox, oy = NEIGHBOR_OFFSETS[i][1], NEIGHBOR_OFFSETS[i][2]
				local nkey = TileKey(tx + ox, ty + oy)
				if self.tiles[nkey] ~= nil and not visited[nkey] then
					visited[nkey] = true
					queue[#queue + 1] = nkey
				end
			end
		end
	end

	return body
end

-- 开垦前：把即将开垦的格子也算进连通（用于合并平均）
function TyPaddyManager:CollectBodyKeysIncluding(start_tx, start_ty)
	local start_key = TileKey(start_tx, start_ty)
	local body = {}
	local visited = { [start_key] = true }
	local queue = { start_key }
	local qi = 1

	while qi <= #queue do
		local key = queue[qi]
		qi = qi + 1
		body[#body + 1] = key

		local tx, ty = ParseTileKey(key)
		if tx ~= nil then
			for i = 1, #NEIGHBOR_OFFSETS do
				local ox, oy = NEIGHBOR_OFFSETS[i][1], NEIGHBOR_OFFSETS[i][2]
				local nx, ny = tx + ox, ty + oy
				local nkey = TileKey(nx, ny)
				if not visited[nkey] and (nkey == start_key or self.tiles[nkey] ~= nil) then
					visited[nkey] = true
					queue[#queue + 1] = nkey
				end
			end
		end
	end

	return body
end

function TyPaddyManager:ForEachBody(fn)
	local visited = {}
	for key in pairs(self.tiles) do
		if not visited[key] then
			local tx, ty = ParseTileKey(key)
			if tx ~= nil then
				local body = self:CollectBodyKeys(tx, ty)
				if body ~= nil then
					for i = 1, #body do
						visited[body[i]] = true
					end
					fn(body)
				end
			end
		end
	end
end

--------------------------------------------------------------------------
-- 日耗 / 雨水（按水域，不按格数）

local function GetDayFraction(dt)
	if dt == nil or dt <= 0 then
		return 0
	end
	local day = TUNING.TOTAL_DAY_TIME or 480
	if day <= 0 then
		return 0
	end
	return dt / day
end

local function GetLossForDelta(dt)
	local frac = GetDayFraction(dt)
	if frac <= 0 then
		return 0
	end
	local loss = (TUNING.TY_PADDY_WATER_LOSS_PER_DAY or 0.2) * frac
	if TheWorld.state.issummer then
		loss = loss * (TUNING.TY_PADDY_SUMMER_LOSS_MULT or 1.5)
	end
	return loss
end

local function GetRainGainForDelta(dt)
	if not TheWorld.state.israining then
		return 0
	end
	local frac = GetDayFraction(dt)
	if frac <= 0 then
		return 0
	end
	local rate = TheWorld.state.precipitationrate or 0
	if rate <= 0 then
		return 0
	end
	return (TUNING.TY_PADDY_RAIN_GAIN_PER_DAY or 1.0) * rate * frac
end

function TyPaddyManager:ApplyWaterLoss(dt)
	local loss = GetLossForDelta(dt)
	if loss <= 0 then
		return
	end

	self:ForEachBody(function(body)
		local key0 = body[1]
		local water = self.tiles[key0] ~= nil and self.tiles[key0].water or 0
		if water > 0 then
			self:SetBodyWater(body, SnapDry(water - loss))
		end
	end)
end

function TyPaddyManager:ApplyRainGain(dt)
	local gain = GetRainGainForDelta(dt)
	if gain <= 0 then
		return
	end

	self:ForEachBody(function(body)
		local key0 = body[1]
		local water = self.tiles[key0] ~= nil and self.tiles[key0].water or 0
		if water < 1 then
			self:SetBodyWater(body, Clamp01(water + gain))
		end
	end)
end

function TyPaddyManager:OnUpdate(dt)
	self:ApplyWaterLoss(dt)
	self:ApplyRainGain(dt)
end

function TyPaddyManager:LongUpdate(dt)
	self:ApplyWaterLoss(dt)
	self:ApplyRainGain(dt)
end

--------------------------------------------------------------------------
-- 外观 / 查询

function TyPaddyManager:RefreshFloaters(tx, ty, wet, silent)
	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
	local ents = TheSim:FindEntities(cx, cy, cz, FLOATER_SCAN_RADIUS, nil, FLOATER_CANT_TAGS)
	local event = wet and "on_landed" or "on_no_longer_landed"
	for i = 1, #ents do
		local ent = ents[i]
		if ent ~= nil and ent:IsValid() then
			local etx, ety = TheWorld.Map:GetTileCoordsAtPoint(ent.Transform:GetWorldPosition())
			if etx == tx and ety == ty then
				if ent.components.floater ~= nil then
					local floater = ent.components.floater
					local prev_splash = floater.splash
					if silent then
						floater.splash = false
					end
					ent:PushEvent(event)
					floater.splash = prev_splash
				elseif wet and ent.components.inventoryitem ~= nil and ent.components.inventoryitem.sinks then
					ent:PushEvent("on_landed")
				end
			end
		end
	end
end

function TyPaddyManager:IsPaddyTile(tile)
	return tile == WORLD_TILES.TY_PADDY or tile == WORLD_TILES.TY_PADDY_DRY
end

function TyPaddyManager:GetWater(tx, ty)
	local data = self.tiles[TileKey(tx, ty)]
	return data ~= nil and data.water or nil
end

function TyPaddyManager:GetWaterAtPoint(x, y, z)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:GetWater(tx, ty)
end

function TyPaddyManager:GetTier(tx, ty)
	local water = self:GetWater(tx, ty)
	if water == nil then
		return nil
	end
	return GetTier(water)
end

--------------------------------------------------------------------------
-- 写水位（整片水域）

function TyPaddyManager:ApplyTileWaterState(tx, ty, water, prev_water)
	local key = TileKey(tx, ty)
	self.tiles[key] = self.tiles[key] or {}
	self.tiles[key].water = water

	local was_wet = IsVisiblyWet(prev_water)
	local now_wet = IsVisiblyWet(water)

	if now_wet then
		if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY then
			TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY)
		end
	else
		if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY_DRY then
			TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY_DRY)
		end
	end

	local prev_tier = GetTier(was_wet and prev_water or 0)
	local now_tier = GetTier(now_wet and water or 0)
	if was_wet ~= now_wet or prev_tier ~= now_tier then
		self:SyncVisual(tx, ty)
	elseif now_wet and WaterDisplayBucket(prev_water) ~= WaterDisplayBucket(water) then
		-- 同档内只按 1% 精度刷检查用数值，避免每帧 set net 导致闪烁
		local ent = self:FindWaterEnt(tx, ty)
		if ent ~= nil and ent.SetPaddyWater ~= nil then
			ent:SetPaddyWater(water)
		end
	end

	if was_wet ~= now_wet then
		self:RefreshFloaters(tx, ty, now_wet)
		TheWorld:PushEvent("ty_paddy_wetness_changed", { tx = tx, ty = ty, wet = now_wet })
	end
end

function TyPaddyManager:SetBodyWater(body, water, force)
	if body == nil or #body == 0 then
		return false
	end
	water = Clamp01(water)

	for i = 1, #body do
		local tx, ty = ParseTileKey(body[i])
		if tx ~= nil and self.tiles[body[i]] ~= nil then
			local prev = self.tiles[body[i]].water or 0
			if force or prev ~= water then
				self:ApplyTileWaterState(tx, ty, water, prev)
			end
		end
	end
	return true
end

function TyPaddyManager:SetWater(tx, ty, water)
	local key = TileKey(tx, ty)
	if self.tiles[key] == nil and not self:IsPaddyTile(TheWorld.Map:GetTile(tx, ty)) then
		return false
	end
	if self.tiles[key] == nil then
		self.tiles[key] = { water = 0 }
	end

	local body = self:CollectBodyKeys(tx, ty)
	if body == nil then
		return false
	end
	return self:SetBodyWater(body, water)
end

function TyPaddyManager:SetWaterAtPoint(x, y, z, water)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:SetWater(tx, ty, water)
end

function TyPaddyManager:AddWater(tx, ty, delta)
	local water = self:GetWater(tx, ty)
	if water == nil or delta == nil or delta == 0 then
		return false
	end
	return self:SetWater(tx, ty, water + delta)
end

function TyPaddyManager:AddWaterAtPoint(x, y, z, delta)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:AddWater(tx, ty, delta)
end

-- 开垦：并入八向连通水域，水位取加权平均（开垦格按满水 1 计入）
function TyPaddyManager:Till(tx, ty)
	local key = TileKey(tx, ty)
	local body_keys = self:CollectBodyKeysIncluding(tx, ty)

	local sum = 0
	local count = 0
	for i = 1, #body_keys do
		local bkey = body_keys[i]
		if bkey == key then
			sum = sum + 1
		else
			sum = sum + (self.tiles[bkey].water or 0)
		end
		count = count + 1
	end

	local avg = Clamp01(count > 0 and (sum / count) or 1)

	-- 先登记格子；水位由 SetBodyWater 统一写入（force 确保新格也会刷外观）
	if self.tiles[key] == nil then
		self.tiles[key] = { water = 0 }
	end

	TheWorld.Map:SetTile(tx, ty, IsVisiblyWet(avg) and WORLD_TILES.TY_PADDY or WORLD_TILES.TY_PADDY_DRY)
	self:SetBodyWater(body_keys, avg, true)

	return true
end

function TyPaddyManager:TillAtPoint(x, y, z)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:Till(tx, ty)
end

--------------------------------------------------------------------------
-- 水面实体

function TyPaddyManager:FindWaterEnt(tx, ty)
	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
	local ents = TheSim:FindEntities(cx, cy, cz, 0.75, { "ty_paddy_water" })
	for i = 1, #ents do
		local ent = ents[i]
		if ent ~= nil and ent:IsValid() and ent.ty_tile_x == tx and ent.ty_tile_y == ty then
			return ent
		end
	end
	return ents[1]
end

function TyPaddyManager:RemoveWaterEnt(tx, ty)
	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
	local ents = TheSim:FindEntities(cx, cy, cz, 0.75, { "ty_paddy_water" })
	for i = 1, #ents do
		local ent = ents[i]
		if ent ~= nil and ent:IsValid() then
			ent:Remove()
		end
	end
end

function TyPaddyManager:RemoveVisualEnts(tx, ty)
	self:RemoveWaterEnt(tx, ty)
end

function TyPaddyManager:SyncVisual(tx, ty)
	local water = self:GetWater(tx, ty)
	if water == nil then
		return
	end

	if not IsVisiblyWet(water) then
		self:RemoveVisualEnts(tx, ty)
		return
	end

	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)

	local ent = self:FindWaterEnt(tx, ty)
	if ent == nil then
		ent = SpawnPrefab("ty_paddy_water")
		if ent == nil then
			return
		end
		ent.Transform:SetPosition(cx, cy, cz)
		ent.ty_tile_x = tx
		ent.ty_tile_y = ty
	end

	if ent.SetPaddyWater ~= nil then
		ent:SetPaddyWater(water)
	end
end

--------------------------------------------------------------------------
-- 存档

function TyPaddyManager:OnSave()
	local data = { tiles = {} }
	for key, info in pairs(self.tiles) do
		data.tiles[key] = { water = info.water }
	end
	return data
end

function TyPaddyManager:OnLoad(data)
	if data == nil or data.tiles == nil then
		return
	end
	self.tiles = {}
	for key, info in pairs(data.tiles) do
		self.tiles[key] = { water = SnapDry(info.water) }
	end
end

function TyPaddyManager:LoadPostPass()
	self.inst:DoTaskInTime(0, function()
		-- 同片水位拉齐（新档无关，顺手保证一致）
		self:ForEachBody(function(body)
			local sum = 0
			for i = 1, #body do
				sum = sum + (self.tiles[body[i]].water or 0)
			end
			self:SetBodyWater(body, Clamp01(sum / #body))
		end)

		for key, info in pairs(self.tiles) do
			local tx, ty = ParseTileKey(key)
			if tx ~= nil then
				local water = info.water or 0
				if IsVisiblyWet(water) then
					if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY then
						TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY)
					end
				else
					if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY_DRY then
						TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY_DRY)
					end
				end
				self:SyncVisual(tx, ty)
				if IsVisiblyWet(water) then
					self:RefreshFloaters(tx, ty, true, true)
				end
			end
		end
	end)
end

return TyPaddyManager
