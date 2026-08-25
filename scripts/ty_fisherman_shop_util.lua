--[[
	渔夫铺面：相对房屋找点与绑定。
]]

local function IsValidShopGround(pt)
	if not TheWorld.Map:IsPassableAtPoint(pt:Get()) then
		return false
	end
	if TheWorld.Map.IsOceanAtPoint ~= nil and TheWorld.Map:IsOceanAtPoint(pt:Get()) then
		return false
	end
	return true
end

local function FindShopSpawnPos(house)
	local x, y, z = house.Transform:GetWorldPosition()
	local pt = Vector3(x, y, z)
	local dists = TUNING.TY_FISHERMAN_SHOP_DIST_FALLBACKS or { 8, 6, 4, 2 }
	for di = 1, #dists do
		local dist = dists[di]
		local offset = FindWalkableOffset(
			pt,
			math.random() * 2 * PI,
			dist,
			16,
			true,
			true,
			IsValidShopGround
		)
		if offset ~= nil then
			return pt + offset
		end
	end
	return Vector3(x + 2, 0, z)
end

local function LinkHouseAndShop(house, shop)
	house._ty_shop = shop
	shop._ty_house = house
end

local function EnsureShopForHouse(house)
	if house == nil or not house:IsValid() then
		return nil
	end
	if house._ty_shop ~= nil and house._ty_shop:IsValid() then
		return house._ty_shop
	end
	local shop = SpawnPrefab("ty_fisherman_shop")
	if shop == nil then
		return nil
	end
	local pos = FindShopSpawnPos(house)
	shop.Transform:SetPosition(pos:Get())
	local hx, _, hz = house.Transform:GetWorldPosition()
	local angle = math.atan2(hz - pos.z, pos.x - hx) / DEGREES
	shop.Transform:SetRotation(angle)
	LinkHouseAndShop(house, shop)
	return shop
end

return {
	EnsureShopForHouse = EnsureShopForHouse,
	FindShopSpawnPos = FindShopSpawnPos,
	LinkHouseAndShop = LinkHouseAndShop,
}
