--[[
	犁：装备到手部后进入犁地模式（取出动画 → 手持）。
	移动时播 plow pre/loop/pst，过格开垦干田（邻接湿田则并入连通水域）。
]]

local assets =
{
	Asset("ANIM", "anim/ty_plough.zip"),
	Asset("ANIM", "anim/player_acitons_ty_plough.zip"),
}

local PLAYER_BUILD = "player_acitons_ty_plough"

local INTERRUPT_EVENTS =
{
	"attacked",
	"knockedout",
	"frozen",
	"onhop",
	"block_jump",
	"respawnfromghost",
	"death",
	"ms_playerridermount",
}

local function IsPloughEquipped(owner)
	if owner == nil or owner.components.inventory == nil then
		return false
	end
	local item = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	return item ~= nil and item:HasTag("ty_plough")
end

local function ForceUnequipPlough(owner)
	if owner == nil or not owner:IsValid() or owner.components.inventory == nil then
		return
	end
	if not IsPloughEquipped(owner) then
		return
	end
	owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
end

local function OnInterrupt(owner)
	ForceUnequipPlough(owner)
end

local function OnNewState(owner, data)
	if owner == nil or not owner:HasTag("ty_ploughing") then
		return
	end
	local name = data ~= nil and data.statename or nil
	if name ~= nil and string.sub(name, 1, 9) == "ty_plough" then
		return
	end
	-- 被其它状态抢走（攻击、受击、跳跃等）→ 强制收起
	ForceUnequipPlough(owner)
end

local function BindOwner(inst, owner)
	if owner == nil then
		return
	end
	inst._ty_plough_owner = owner
	for i = 1, #INTERRUPT_EVENTS do
		owner:ListenForEvent(INTERRUPT_EVENTS[i], OnInterrupt)
	end
	owner:ListenForEvent("newstate", OnNewState)
end

local function UnbindOwner(inst, owner)
	owner = owner or inst._ty_plough_owner
	inst._ty_plough_owner = nil
	if owner == nil or not owner:IsValid() then
		return
	end
	for i = 1, #INTERRUPT_EVENTS do
		owner:RemoveEventCallback(INTERRUPT_EVENTS[i], OnInterrupt)
	end
	owner:RemoveEventCallback("newstate", OnNewState)
end

-- 犁动画用符号 li（来自 player build）+ 普通手臂，不用 ARM_carry / swap_object
local function ApplyPloughVisuals(owner)
	owner.AnimState:AddOverrideBuild(PLAYER_BUILD)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function ClearPloughVisuals(owner)
	owner.AnimState:ClearOverrideBuild(PLAYER_BUILD)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function OnEquip(inst, owner)
	if owner == nil then
		return
	end

	if owner.components.rider ~= nil and owner.components.rider:IsRiding() then
		owner:DoTaskInTime(0, function()
			ForceUnequipPlough(owner)
		end)
		return
	end

	ApplyPloughVisuals(owner)
	owner:AddTag("ty_ploughing")
	BindOwner(inst, owner)

	if owner.sg ~= nil and not owner.sg:HasStateTag("dead") then
		owner.sg:GoToState("ty_plough_start")
	end
end

local function OnUnequip(inst, owner)
	if owner == nil then
		return
	end

	UnbindOwner(inst, owner)
	owner:RemoveTag("ty_ploughing")
	ClearPloughVisuals(owner)

	-- ty_plough_stop 会自己切状态，避免抢状态
	if owner.sg ~= nil
		and owner.sg:HasStateTag("ty_plough")
		and not owner.sg:HasStateTag("dead")
		and (owner.sg.currentstate == nil or owner.sg.currentstate.name ~= "ty_plough_stop") then
		owner.sg:GoToState("idle")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("ty_plough")
	inst.AnimState:SetBuild("ty_plough")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("ty_plough")
	inst:AddTag("weapon")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
	inst.components.equippable.walkspeedmult = TUNING.TY_PLOUGH_SPEED_MULT or 0.6

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.TY_PLOUGH_DAMAGE or 17)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("ty_plough", fn, assets)
