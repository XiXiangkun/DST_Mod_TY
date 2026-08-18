--[[
	水田地皮工具：湿田集合判定、水量 → 地皮 ID。
	主机 / 客户端都可 require，不依赖 ty_paddy_manager。
]]

local PaddyTiles = {}

local function WetThreshold()
	return TUNING.TY_PADDY_WET_THRESHOLD or 0.01
end

function PaddyTiles.IsWetPaddyTile(tile)
	return tile == WORLD_TILES.TY_PADDY
		or tile == WORLD_TILES.TY_PADDY_50
end

function PaddyTiles.IsPaddyTile(tile)
	return PaddyTiles.IsWetPaddyTile(tile) or tile == WORLD_TILES.TY_PADDY_DRY
end

function PaddyTiles.IsWetPaddyAtPoint(x, y, z)
	if WORLD_TILES.TY_PADDY == nil or TheWorld == nil or TheWorld.Map == nil then
		return false
	end
	return PaddyTiles.IsWetPaddyTile(TheWorld.Map:GetTileAtPoint(x, y, z))
end

-- 地皮两档湿 + 一档干（水面 FX 仍可按四档细分）
-- >=50% TY_PADDY；湿阈值~50% TY_PADDY_50；否则 DRY
function PaddyTiles.GetTileForWater(water)
	water = water or 0
	if water < WetThreshold() then
		return WORLD_TILES.TY_PADDY_DRY
	elseif water >= 0.5 then
		return WORLD_TILES.TY_PADDY
	else
		return WORLD_TILES.TY_PADDY_50
	end
end

function PaddyTiles.GetTileName(tile)
	if tile == WORLD_TILES.TY_PADDY then
		return "TY_PADDY"
	elseif tile == WORLD_TILES.TY_PADDY_50 then
		return "TY_PADDY_50"
	elseif tile == WORLD_TILES.TY_PADDY_DRY then
		return "TY_PADDY_DRY"
	end
	return tostring(tile)
end

return PaddyTiles
