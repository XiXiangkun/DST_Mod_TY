-- 田园(TY) 测试命令
-- c_ty_paddy()           脚下开垦满水水田
-- c_ty_paddy_set(0.6)    设置脚下水位 0~1
-- c_ty_paddy_set(0)      干涸
-- c_ty_paddy_info()      打印脚下水位信息

function c_ty_paddy()
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	TheWorld.components.ty_paddy_manager:TillAtPoint(x, y, z)
	print("[ty] tilled paddy at feet, water=100%")
end

function c_ty_paddy_set(water)
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	water = water or 1
	local x, y, z = player.Transform:GetWorldPosition()
	if TheWorld.components.ty_paddy_manager:GetWaterAtPoint(x, y, z) == nil then
		TheWorld.components.ty_paddy_manager:TillAtPoint(x, y, z)
	end
	TheWorld.components.ty_paddy_manager:SetWaterAtPoint(x, y, z, water)
	print(string.format("[ty] paddy water set to %.1f%%", water * 100))
end

function c_ty_paddy_info()
	local player = ConsoleCommandPlayer()
	if player == nil or TheWorld == nil or TheWorld.components.ty_paddy_manager == nil then
		print("[ty] paddy manager missing")
		return
	end
	local x, y, z = player.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	local water = TheWorld.components.ty_paddy_manager:GetWater(tx, ty)
	local tier = TheWorld.components.ty_paddy_manager:GetTier(tx, ty)
	local tile = TheWorld.Map:GetTile(tx, ty)
	print(string.format(
		"[ty] tile=(%d,%d) map_tile=%s water=%s tier=%s",
		tx, ty, tostring(tile),
		water ~= nil and string.format("%.1f%%", water * 100) or "n/a",
		tostring(tier)
	))
end
