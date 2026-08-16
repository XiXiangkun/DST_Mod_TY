--[[
	水田水面（ty_paddy_wave）
	贴地水纹 + 可检查水位
]]

local assets =
{
	Asset("ANIM", "anim/ty_paddy_wave.zip"),
}

local TIER_ANIM =
{
	full = "idle",
	mid = "idle",
	shallow = "idle",
	nearly_dry = "idle",
}

local TIER_ALPHA =
{
	full = 1.0,
	mid = 0.85,
	shallow = 0.65,
	nearly_dry = 0.4,
}

local TIER_NAME_ZH =
{
	full = "满水",
	mid = "半水",
	shallow = "浅水",
	nearly_dry = "近干",
	dry = "干涸",
}

local TIER_NAME_EN =
{
	full = "Full",
	mid = "Half",
	shallow = "Shallow",
	nearly_dry = "Nearly dry",
	dry = "Dry",
}

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

local function ApplyVisual(inst)
	local water = inst._water:value()
	local tier = GetTier(water)

	if tier == "dry" then
		inst:Hide()
		return
	end

	inst:Show()
	local anim = TIER_ANIM[tier] or "idle"
	if not inst.AnimState:IsCurrentAnimation(anim) then
		inst.AnimState:PlayAnimation(anim, true)
		inst._ty_anim_phased = false
	end
	-- 读档批量重建时避免所有水纹同相位；每块只随机一次
	if not inst._ty_anim_phased then
		local len = inst.AnimState:GetCurrentAnimationLength()
		if len ~= nil and len > 0 then
			inst.AnimState:SetTime(math.random() * len)
		end
		inst._ty_anim_phased = true
	end

	local a = TIER_ALPHA[tier] or 1
	inst.AnimState:SetMultColour(1, 1, 1, a)

	inst.ty_tier = tier
end

local function OnWaterDirty(inst)
	ApplyVisual(inst)
end

local function GetDescribe(inst, viewer)
	local water = inst._water ~= nil and inst._water:value() or 0
	-- 检查走主机；从 manager 读当前水量，避免档内扣水时百分比滞后
	if TheWorld.ismastersim and inst.ty_tile_x ~= nil then
		local mgr = TheWorld.components.ty_paddy_manager
		if mgr ~= nil then
			local live = mgr:GetWater(inst.ty_tile_x, inst.ty_tile_y)
			if live ~= nil then
				water = live
			end
		end
	end

	local tier = GetTier(water)
	local lang = TUNING.TY_LANG or "zh"
	local tier_name = (lang == "en" and TIER_NAME_EN[tier] or TIER_NAME_ZH[tier]) or tier
	local pct = math.floor(water * 1000 + 0.5) / 10 -- 一位小数

	if lang == "en" then
		return string.format("Paddy water: %.1f%% (%s)", pct, tier_name)
	end
	return string.format("水田水位：%.1f%%（%s）", pct, tier_name)
end

local function SetPaddyWater(inst, water)
	water = math.max(0, math.min(1, water or 0))
	inst._water:set(water)
	if not TheWorld.ismastersim then
		return
	end
	-- 主机也立刻刷一次（net 回调有时只在远端）
	ApplyVisual(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("ty_paddy_wave")
	inst.AnimState:SetBank("ty_paddy_wave")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst.Transform:SetScale(1.2, 1.2, 1.2)

	inst:AddTag("NOBLOCK")
	inst:AddTag("ty_paddy_water")
	-- 可检查水位：不加 FX / NOCLICK，便于鼠标指向

	inst._water = net_float(inst.GUID, "ty_paddy_water._water", "waterdirty")
	inst._water:set(1)

	inst:ListenForEvent("waterdirty", OnWaterDirty)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false -- 由 ty_paddy_manager 负责重建

	inst:AddComponent("inspectable")
	inst.components.inspectable.descriptionfn = GetDescribe

	inst.SetPaddyWater = SetPaddyWater

	inst:DoTaskInTime(0, ApplyVisual)

	return inst
end

return Prefab("ty_paddy_water", fn, assets)
