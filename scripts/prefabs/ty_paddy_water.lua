--[[
	水田水面（第一版占位：复用官方 wave_shore）
	贴地水纹 + 可检查水位（已关闭 DynamicShadow）
]]

local assets =
{
	Asset("ANIM", "anim/wave_shore.zip"),
}

local TIER_ANIM =
{
	full = "idle_med",
	mid = "idle_small",
	shallow = "idle_small2",
	nearly_dry = "idle_small3",
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
	local anim = TIER_ANIM[tier] or "idle_small"
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

local function OnSave(inst, data)
	data.water = inst._water:value()
	data.tx = inst.ty_tile_x
	data.ty = inst.ty_tile_y
end

local function OnLoad(inst, data)
	if data == nil then
		return
	end
	inst.ty_tile_x = data.tx
	inst.ty_tile_y = data.ty
	if data.water ~= nil then
		inst:DoTaskInTime(0, function()
			if inst:IsValid() then
				inst:SetPaddyWater(data.water)
			end
		end)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("wave_shore")
	inst.AnimState:SetBank("wave_shore")
	inst.AnimState:PlayAnimation("idle_big", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	-- 不用 SetOceanBlendParams：官方岸浪会按海洋色（偏深青绿）染色，水田上会发黑
	-- 地皮本身不会改 AnimState 颜色；半透明时底下田皮透上来会显得浑一点

	inst:AddTag("NOBLOCK")
	inst:AddTag("ty_paddy_water")
	-- 第一版可检查水位：不加 FX / NOCLICK，便于鼠标指向

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
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst:DoTaskInTime(0, ApplyVisual)

	return inst
end

return Prefab("ty_paddy_water", fn, assets)
