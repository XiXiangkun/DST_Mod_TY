-- 湿水田视为可漂浮水面（真落水：走官方湿润/溅水）
-- 干田 TY_PADDY_DRY 不漂

local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

local PaddyTiles = require("ty_paddy_tiles")

local function IsOnWetPaddy(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	return PaddyTiles.IsWetPaddyAtPoint(x, y, z)
end

TYENV.AddComponentPostInit("floater", function(self)
	local old_ShouldShowEffect = self.ShouldShowEffect
	function self:ShouldShowEffect(...)
		if old_ShouldShowEffect(self, ...) then
			return true
		end
		return IsOnWetPaddy(self.inst)
	end

	-- 已在漂时再次收到 on_landed，但当前位置已不该漂（如水位刚干）→ 收起
	local old_OnLandedServer = self.OnLandedServer
	function self:OnLandedServer(...)
		local was_showing = self.showing_effect
		local rets = { old_OnLandedServer(self, ...) }
		if was_showing and not self:ShouldShowEffect() then
			self:OnNoLongerLandedServer()
		end
		return unpack(rets)
	end
end)
