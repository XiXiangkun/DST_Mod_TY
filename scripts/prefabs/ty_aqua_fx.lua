--[[
	水田游鱼 / 游虾特效（立面动画，压在世界物体之下）
]]

local SORT_ORDER = 4 -- 高于 ty_paddy_water(3)，仍低于 LAYER_WORLD 物品

local function RandomizeAnimPhase(inst)
	if not inst:IsValid() or inst.AnimState == nil then
		return
	end
	local len = inst.AnimState:GetCurrentAnimationLength()
	if len ~= nil and len > 0 then
		inst.AnimState:SetTime(math.random() * len)
	end
end

local function MakeAquaFx(name, bank, build, extra_assets, scale)
	local assets =
	{
		Asset("ANIM", "anim/" .. bank .. ".zip"),
	}
	if extra_assets ~= nil then
		for i = 1, #extra_assets do
			assets[#assets + 1] = extra_assets[i]
		end
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(SORT_ORDER)
		if scale ~= nil then
			inst.Transform:SetScale(scale, scale, scale)
		end

		inst:AddTag("FX")
		inst:AddTag("NOCLICK")
		inst:AddTag("NOBLOCK")
		inst:AddTag("DECOR")
		inst:AddTag(name)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.persists = false
		-- 多条同屏时错开相位
		inst:DoTaskInTime(0, RandomizeAnimPhase)

		return inst
	end

	return Prefab(name, fn, assets)
end

return MakeAquaFx("ty_fish_fx", "ty_fish_fx", "ty_fish_fx"),
	MakeAquaFx("ty_shrimp_fx", "ty_shrimp_fx", "lobster_sheller", {
		Asset("ANIM", "anim/lobster_sheller.zip"),
	}, 0.7)
