--[[
	犁：Action（右键自己收起）+ 玩家 StateGraph（取出 / 手持 / 犁地移动）

	移动动画参考官方 pushing_walk（滚雪球）：
	- pre + loop 同状态队列：PlayAnimation(pre) → PushAnimation(loop)
	- 起步后短时不可停（canstop），保证 pre 能看完
	- 停下时同状态播 pst，再 soft 进 holding idle（不冲掉 pst）
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

-- 与 anim/player_acitons_ty_plough.zip 中帧数一致（30fps）
local PLOUGH_PRE_FRAMES = 20
local PLOUGH_PST_FRAMES = 20

local function GetPloughAnimTimeout(inst, fallback_frames)
	local len = inst.AnimState:GetCurrentAnimationLength()
	if len == nil or len <= 0 then
		return fallback_frames * FRAMES
	end
	return len
end

local function SetLocomotorDirFromData(inst, data)
	if data == nil or data.dir == nil then
		return
	end
	if inst.components.locomotor ~= nil then
		inst.components.locomotor:SetMoveDir(data.dir)
	else
		inst.Transform:SetRotation(data.dir)
	end
end

-- 鼹鼠地下钻行循环音
local PLOUGH_DIG_SOUND = "dontstarve_DLC001/creatures/mole/move"
local PLOUGH_DIG_SOUND_NAME = "ty_plough_dig"

local function StartPloughDigSound(inst)
	if inst.SoundEmitter ~= nil and not inst.SoundEmitter:PlayingSound(PLOUGH_DIG_SOUND_NAME) then
		inst.SoundEmitter:PlaySound(PLOUGH_DIG_SOUND, PLOUGH_DIG_SOUND_NAME)
	end
end

local function StopPloughDigSound(inst)
	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:KillSound(PLOUGH_DIG_SOUND_NAME)
	end
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
			StopPloughDigSound(inst)
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
					if not EnsurePloughing(inst) then
						inst.sg:GoToState("idle")
					elseif inst.components.locomotor:WantsToMoveForward() then
						inst.sg:GoToState("ty_plough_move")
					else
						inst.sg:GoToState("ty_plough_idle")
					end
				end
			end),
		},
	}

	local plough_idle = State{
		name = "ty_plough_idle",
		tags = { "idle", "canrotate", "ty_plough" },

		-- soft=true：从 move 收步过来，Push holding，让 pst 播完（对齐 idle(..., true)）
		onenter = function(inst, soft)
			if inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("ty_plough_move")
				return
			end
			StopPloughDigSound(inst)
			inst.components.locomotor:Stop()
			if soft then
				inst.AnimState:PushAnimation("ty_holding_plough", true)
			elseif not inst.AnimState:IsCurrentAnimation("ty_holding_plough") then
				inst.AnimState:PlayAnimation("ty_holding_plough", true)
			end
			if inst.sg.mem.ty_plough_tx == nil then
				InitPloughTileMem(inst)
			end
		end,
	}

	-- 合并 pre/loop/pst：参考 pushing_walk
	local plough_move = State{
		name = "ty_plough_move",
		tags = { "moving", "running", "canrotate", "ty_plough", "autopredict" },

		onenter = function(inst)
			if not EnsurePloughing(inst) then
				StopPloughDigSound(inst)
				inst.sg:GoToState("run_start")
				return
			end
			inst.components.locomotor:RunForward()
			-- 同状态队列：pre 播完自动接 loop，不依赖状态切换
			inst.AnimState:PlayAnimation("ty_plow_pre")
			inst.AnimState:PushAnimation("ty_plow_loop", true)
			StartPloughDigSound(inst)
			inst.sg.statemem.canstop = false
			inst.sg.statemem.stopping = false
			-- 至少等 pre 时长才允许停，避免点按看不到起步
			inst.sg:SetTimeout(PLOUGH_PRE_FRAMES * FRAMES)
		end,

		onupdate = function(inst, dt)
			if not EnsurePloughing(inst) then
				StopPloughDigSound(inst)
				inst.sg:GoToState("run")
				return
			end

			-- 收步中：等 pst 播完再 soft 进 holding
			if inst.sg.statemem.stopping then
				if inst.sg.statemem.exitdelay ~= nil then
					if inst.sg.statemem.exitdelay > dt then
						inst.sg.statemem.exitdelay = inst.sg.statemem.exitdelay - dt
					else
						inst.sg.statemem.exitdelay = nil
						if EnsurePloughing(inst) then
							inst.sg:GoToState("ty_plough_idle", true)
						else
							inst.sg:GoToState("idle", true)
						end
					end
				end
				return
			end

			-- 可停且松键 → 播 pst（仍留在本状态，对齐 pushing_walk）
			if inst.sg.statemem.canstop
				and not inst.components.locomotor:WantsToMoveForward() then
				StopPloughDigSound(inst)
				inst.AnimState:PlayAnimation("ty_plow_pst")
				inst.components.locomotor:Stop()
				inst.sg:RemoveStateTag("moving")
				inst.sg:RemoveStateTag("running")
				inst.sg:AddStateTag("idle")
				inst.sg.statemem.stopping = true
				inst.sg.statemem.exitdelay = GetPloughAnimTimeout(inst, PLOUGH_PST_FRAMES)
				return
			end

			inst.components.locomotor:RunForward()
			TryPloughFootstep(inst)
		end,

		ontimeout = function(inst)
			inst.sg.statemem.canstop = true
		end,

		onexit = function(inst)
			StopPloughDigSound(inst)
		end,
	}

	return plough_stop, plough_start, plough_idle, plough_move
end

local function RegisterPloughStates(sg_name, is_client)
	local plough_stop, plough_start, plough_idle, plough_move = MakePloughStates(is_client)
	AddStategraphState(sg_name, plough_stop)
	AddStategraphState(sg_name, plough_start)
	AddStategraphState(sg_name, plough_idle)
	AddStategraphState(sg_name, plough_move)
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
	StopPloughDigSound(inst)
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
				-- idle / 收步中再按住：重新起步
				SetLocomotorDirFromData(inst, data)
				inst.sg:GoToState("ty_plough_move")
				return
			end
			-- 移动中松键：交给 ty_plough_move.onupdate 播 pst（不在这里切状态）
			if is_moving and should_move then
				SetLocomotorDirFromData(inst, data)
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
