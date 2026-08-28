--[[
	渔夫铺面辅助：距离 / 岛屿占位（不再由房屋自动生成铺面）。
]]

local function IsSameIslandPlaceholder(_a, _b)
	return true
end

local function GetManager()
	return TheWorld.components.ty_fisherman_manager
end

local function IsShopReachableFromHouse(house, shop)
	if house == nil or shop == nil or not house:IsValid() or not shop:IsValid() then
		return false
	end
	if not IsSameIslandPlaceholder(house, shop) then
		return false
	end
	local maxd = TUNING.TY_FISHERMAN_SHOP_MAX_DIST or 60
	local hx, _, hz = house.Transform:GetWorldPosition()
	local sx, _, sz = shop.Transform:GetWorldPosition()
	local dx, dz = hx - sx, hz - sz
	return (dx * dx + dz * dz) <= (maxd * maxd)
end

return {
	GetManager = GetManager,
	IsSameIsland = IsSameIslandPlaceholder,
	IsShopReachableFromHouse = IsShopReachableFromHouse,
}
