-- 浇水壶可对水田地皮浇水，并给整片连通水域补水

local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local function IsTyPaddyTile(tile)
	return tile == WORLD_TILES.TY_PADDY or tile == WORLD_TILES.TY_PADDY_DRY
end

-- 原版 POINT 浇水只允许 FARMING_SOIL，这里补上水田
TYENV.AddComponentAction("POINT", "wateryprotection", function(inst, doer, pos, actions, right, target)
	if not right or pos == nil then
		return
	end
	if IsTyPaddyTile(TheWorld.Map:GetTileAtPoint(pos:Get())) then
		table.insert(actions, ACTIONS.POUR_WATER_GROUNDTILE)
	end
end)

TYENV.AddComponentPostInit("wateryprotection", function(self)
	local old_SpreadProtectionAtPoint = self.SpreadProtectionAtPoint
	function self:SpreadProtectionAtPoint(x, y, z, dist, noextinguish)
		old_SpreadProtectionAtPoint(self, x, y, z, dist, noextinguish)

		if not TheWorld.ismastersim then
			return
		end
		if self.addwetness == nil or self.addwetness <= 0 then
			return
		end
		if TheWorld.components.ty_paddy_manager == nil then
			return
		end

		local amount = TUNING.TY_PADDY_CAN_WATER_AMOUNT or 0.25
		TheWorld.components.ty_paddy_manager:AddWaterAtPoint(x, y, z, amount)
	end
end)
