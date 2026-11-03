local TYENV = env
GLOBAL.setfenv(1, GLOBAL)

-- 左上角写死位置（不做可配置偏移）
local HUD_POS = Vector3(100, -70, 0)

TYENV.AddClassPostConstruct("widgets/controls", function(self)
	if self.owner == nil or self.topleft_root == nil then
		return
	end
	if TheNet:IsDedicated() then
		return
	end

	local TyProsperityBadge = require("widgets/ty_prosperitybadge")
	self.ty_prosperitybadge = self.topleft_root:AddChild(TyProsperityBadge(self.owner))
	self.ty_prosperitybadge:SetPosition(HUD_POS:Get())
end)
