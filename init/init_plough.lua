--[[
	犁：Action（右键自己收起）+ 玩家 StateGraph（取出 / 手持 / 犁地移动）
]]

local function InitPloughTileMem(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	inst.sg.mem.ty_plough_tx = tx
	inst.sg.mem.ty_plough_ty = ty
end

local function TryPloughFootstep(inst)
	if not TheWorld.ismastersim then
		return
	end
	local mgr = TheWorld.components.ty_paddy_manager
	if mgr == nil then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
	if tx == inst.sg.mem.ty_plough_tx and ty == inst.sg.mem.ty_plough_ty then
		return
	end
	inst.sg.mem.ty_plough_tx = tx
	inst.sg.mem.ty_plough_ty = ty
	mgr:TillPlough(tx, ty)
end

local function EnsurePloughing(inst)
	return inst:HasTag("ty_ploughing")
end

--------------------------------------------------------------------------
-- Action：右键自己结束犁地（卸下手部犁）

AddAction("TY_STOP_PLOUGH", STRINGS.ACTIONS.TY_STOP_PLOUGH or "Put Away", function(act)
	local doer = act.doer
	if doer == nil or doer.components.inventory == nil then
		return false
	end
	local item = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if item == nil or not item:HasTag("ty_plough") then
		return false
	end
	doer.components.inventory:Unequip(EQUIPSLOTS.HANDS)
	return true
end)

ACTIONS.TY_STOP_PLOUGH.priority = 12
ACTIONS.TY_STOP_PLOUGH.distance = 1
ACTIONS.TY_STOP_PLOUGH.mount_valid = false

-- 用 equippable（客户端必有）+ tag，避免自定义组件未复制导致收不起
AddComponentAction("EQUIPPED", "equippable", function(inst, doer, target, actions, right)
	if right
		and inst:HasTag("ty_plough")
		and doer ~= nil
		and target == doer
		and doer:HasTag("ty_ploughing") then
		table.insert(actions, ACTIONS.TY_STOP_PLOUGH)
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TY_STOP_PLOUGH, "ty_plough_stop"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TY_STOP_PLOUGH, "ty_plough_stop"))

--------------------------------------------------------------------------
-- StateGraph

local function MakePloughStates(is_client)
	local plough_stop = State{
		name = "ty_plough_stop",
		tags = { "busy", "doing", "ty_plough" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst:PerformBufferedAction()
			-- Unequip 会清 tag 并切 idle；若仍在犁地则回手持
			if inst:HasTag("ty_ploughing") then
				inst.sg:GoToState("ty_plough_idle")
			elseif not inst.sg:HasStateTag("dead") then
				inst.sg:GoToState("idle")
			end
		end,
	}

	local plough_start = State{
		name = "ty_plough_start",
		tags = { "busy", "doing", "ty_plough", "pausepredict" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("ty_use_plough")
			InitPloughTileMem(inst)
			if not is_client and inst.components.playercontroller ~= nil then
				inst.components.playercontroller:RemotePausePrediction()
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if EnsurePloughing(inst) then
						inst.sg:GoToState("ty_plough_idle")
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
	}

	local plough_idle = State{
		name = "ty_plough_idle",
		tags = { "idle", "canrotate", "ty_plough" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			if not inst.AnimState:IsCurrentAnimation("ty_holding_plough") then
				inst.AnimState:PlayAnimation("ty_holding_plough", true)
			end
			if inst.sg.mem.ty_plough_tx == nil then
				InitPloughTileMem(inst)
			end
		end,
	}

	local plough_pre = State{
		name = "ty_plough_pre",
		tags = { "moving", "running", "canrotate", "ty_plough", "autopredict" },

		onenter = function(inst)
			if not EnsurePloughing(inst) then
				inst.sg:GoToState("run_start")
				return
			end
			inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("ty_plow_pre")
		end,

		onupdate = function(inst)
			if not EnsurePloughing(inst) then
				inst.sg:GoToState("run")
				return
			end
			inst.components.locomotor:RunForward()
			TryPloughFootstep(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("ty_plough_loop")
				end
			end),
		},
	}

	local plough_loop = State{
		name = "ty_plough_loop",
		tags = { "moving", "running", "canrotate", "ty_plough", "autopredict" },

		onenter = function(inst)
			if not EnsurePloughing(inst) then
				inst.sg:GoToState("run")
				return
			end
			inst.components.locomotor:RunForward()
			if not inst.AnimState:IsCurrentAnimation("ty_plow_loop") then
				inst.AnimState:PlayAnimation("ty_plow_loop", true)
			end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
		end,

		onupdate = function(inst)
			if not EnsurePloughing(inst) then
				inst.sg:GoToState("run")
				return
			end
			inst.components.locomotor:RunForward()
			TryPloughFootstep(inst)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("ty_plough_loop")
		end,
	}

	local plough_pst = State{
		name = "ty_plough_pst",
		tags = { "canrotate", "ty_plough", "autopredict" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("ty_plow_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if EnsurePloughing(inst) then
						inst.sg:GoToState("ty_plough_idle")
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
	}

	return plough_stop, plough_start, plough_idle, plough_pre, plough_loop, plough_pst
end

local function RegisterPloughStates(sg_name, is_client)
	local plough_stop, plough_start, plough_idle, plough_pre, plough_loop, plough_pst = MakePloughStates(is_client)
	AddStategraphState(sg_name, plough_stop)
	AddStategraphState(sg_name, plough_start)
	AddStategraphState(sg_name, plough_idle)
	AddStategraphState(sg_name, plough_pre)
	AddStategraphState(sg_name, plough_loop)
	AddStategraphState(sg_name, plough_pst)
end

RegisterPloughStates("wilson", false)
RegisterPloughStates("wilson_client", true)

-- 客户端：装备事件补状态机 / 覆盖动画（服务端 OnEquip 不在客户端跑）
local PLAYER_BUILD = "player_acitons_ty_plough"

local function ClientApplyPlough(inst)
	inst.AnimState:AddOverrideBuild(PLAYER_BUILD)
	inst.AnimState:ClearOverrideSymbol("swap_object")
	inst.AnimState:Hide("ARM_carry")
	inst.AnimState:Show("ARM_normal")
	inst:AddTag("ty_ploughing")
	if inst.sg ~= nil then
		local name = inst.sg.currentstate ~= nil and inst.sg.currentstate.name or ""
		if string.sub(name, 1, 9) ~= "ty_plough" then
			inst.sg:GoToState("ty_plough_start")
		end
	end
end

local function ClientClearPlough(inst)
	inst:RemoveTag("ty_ploughing")
	inst.AnimState:ClearOverrideBuild(PLAYER_BUILD)
	inst.AnimState:ClearOverrideSymbol("swap_object")
	inst.AnimState:Hide("ARM_carry")
	inst.AnimState:Show("ARM_normal")
	if inst.sg ~= nil and inst.sg:HasStateTag("ty_plough") and not inst.sg:HasStateTag("dead") then
		inst.sg:GoToState("idle")
	end
end

AddPlayerPostInit(function(inst)
	inst:ListenForEvent("equip", function(player, data)
		if TheWorld.ismastersim then
			return
		end
		if data ~= nil and data.item ~= nil and data.item:HasTag("ty_plough") then
			ClientApplyPlough(player)
		end
	end)
	inst:ListenForEvent("unequip", function(player, data)
		if TheWorld.ismastersim then
			return
		end
		if data ~= nil and data.item ~= nil and data.item:HasTag("ty_plough") then
			ClientClearPlough(player)
		end
	end)
end)

local function HookLocomote(sg)
	if sg.events == nil or sg.events.locomote == nil then
		return
	end
	local old_fn = sg.events.locomote.fn
	sg.events.locomote.fn = function(inst, data)
		if inst:HasTag("ty_ploughing") and not inst.sg:HasStateTag("busy") then
			local is_moving = inst.sg:HasStateTag("moving")
			local should_move = inst.components.locomotor:WantsToMoveForward()
			if not is_moving and should_move then
				inst.sg:GoToState("ty_plough_pre")
				return
			elseif is_moving and not should_move then
				inst.sg:GoToState("ty_plough_pst")
				return
			end
			return
		end
		if old_fn ~= nil then
			return old_fn(inst, data)
		end
	end
end

AddStategraphPostInit("wilson", HookLocomote)
AddStategraphPostInit("wilson_client", HookLocomote)
