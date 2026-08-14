--[[
	主机：管理水田格子水量、日耗、地皮湿/干切换，并生成水面检查实体。
]]

local function TileKey(tx, ty)
	return tx .. "_" .. ty
end

local function ParseTileKey(key)
	local tx, ty = string.match(key, "^(%-?%d+)_(%-?%d+)$")
	return tonumber(tx), tonumber(ty)
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

	self.inst:WatchWorldState("cycles", function()
		self:OnDayPassed()
	end)
end)

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

-- 开垦：湿田 + 满水
function TyPaddyManager:Till(tx, ty)
	local key = TileKey(tx, ty)
	TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY)
	self.tiles[key] = { water = 1 }
	self:SyncVisual(tx, ty)
	return true
end

function TyPaddyManager:TillAtPoint(x, y, z)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:Till(tx, ty)
end

-- 设置水量（测试/浇水用），自动切湿干地皮
function TyPaddyManager:SetWater(tx, ty, water)
	local key = TileKey(tx, ty)
	if self.tiles[key] == nil and not self:IsPaddyTile(TheWorld.Map:GetTile(tx, ty)) then
		return false
	end

	water = math.max(0, math.min(1, water or 0))
	self.tiles[key] = self.tiles[key] or {}
	self.tiles[key].water = water

	if water > 0 then
		if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY then
			TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY)
		end
	else
		if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY_DRY then
			TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY_DRY)
		end
	end

	self:SyncVisual(tx, ty)
	return true
end

function TyPaddyManager:SetWaterAtPoint(x, y, z, water)
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	return self:SetWater(tx, ty, water)
end

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

function TyPaddyManager:SyncVisual(tx, ty)
	local water = self:GetWater(tx, ty)
	if water == nil then
		return
	end

	if water <= 0 then
		self:RemoveWaterEnt(tx, ty)
		return
	end

	local ent = self:FindWaterEnt(tx, ty)
	if ent == nil then
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
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

function TyPaddyManager:OnDayPassed()
	local loss = TUNING.TY_PADDY_WATER_LOSS_PER_DAY or 0.025
	if TheWorld.state.issummer then
		loss = loss * (TUNING.TY_PADDY_SUMMER_LOSS_MULT or 1.5)
	end

	for key, data in pairs(self.tiles) do
		if data.water ~= nil and data.water > 0 then
			local tx, ty = ParseTileKey(key)
			if tx ~= nil then
				self:SetWater(tx, ty, data.water - loss)
			end
		end
	end
end

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
		self.tiles[key] = { water = info.water or 0 }
	end
end

-- DST 实体加载完成后调用的是 LoadPostPass（不是 OnLoadPostPass）
function TyPaddyManager:LoadPostPass()
	self.inst:DoTaskInTime(0, function()
		for key, info in pairs(self.tiles) do
			local tx, ty = ParseTileKey(key)
			if tx ~= nil then
				local water = info.water or 0
				if water > 0 then
					if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY then
						TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY)
					end
				else
					if TheWorld.Map:GetTile(tx, ty) ~= WORLD_TILES.TY_PADDY_DRY then
						TheWorld.Map:SetTile(tx, ty, WORLD_TILES.TY_PADDY_DRY)
					end
				end
				self:SyncVisual(tx, ty)
			end
		end
	end)
end

return TyPaddyManager
