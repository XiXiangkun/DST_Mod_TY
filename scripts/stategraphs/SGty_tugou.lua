--[[
	大黄狗 stategraph
	动画名对齐官方 hound / warglet（idle / atk / hit / death / run_* / sleep_*）。
	游荡走 walk；追击跑 run_pre / run_loop / run_pst。
]]

require("stategraphs/commonstates")

local HIT_RECOVERY = TUNING.TY_TUGOU_HIT_RECOVERY or 1

local events =
{
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnLocomote(true, true),
	EventHandler("attacked", function(inst)
		if inst.components.health ~= nil and inst.components.health:IsDead() then
			return
		end
		if inst.sg:HasStateTag("busy") then
			return
		end
		local t = GetTime()
		if inst.sg.mem.last_hit_time ~= nil and t - inst.sg.mem.last_hit_time < HIT_RECOVERY then
			return
		end
		inst.sg.mem.last_hit_time = t
		inst.sg:GoToState("hit")
	end),
}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
		end,
	},

	State{
		name = "attack",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst:FacePoint(target.Transform:GetWorldPosition())
			end
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			-- 官方 SGhound：atk_pre + atk，咬合约在 14 帧。只播 atk 会在 DoAttack 前 animover。
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk", false)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end,

		timeline =
		{
			TimeEvent(14 * FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst.SoundEmitter:PlaySound(inst.sounds.bite)
			end),
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle", "atk_pst")
			end),
		},
	},

	State{
		name = "hit",
		tags = { "busy", "hit" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound(inst.sounds.hurt)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "death",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("death")
			inst.SoundEmitter:PlaySound(inst.sounds.death)
			RemovePhysicsColliders(inst)
			if inst.components.lootdropper ~= nil then
				inst.components.lootdropper:DropLoot()
			end
		end,
	},
}

CommonStates.AddSleepStates(states,
{
	starttimeline =
	{
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
	},
})

-- bank 只有一段循环 walk，没有 walk_pst。
-- 不能 softstop / 把 walk 当 stop：Wander 停下后会原地踏步把这一段播完。
CommonStates.AddWalkStates(states,
{
	walktimeline =
	{
		TimeEvent(0, PlayFootstep),
		TimeEvent(12 * FRAMES, PlayFootstep),
	},
},
{
	startwalk = "walk",
	walk = "walk",
	stopwalk = "idle",
})

CommonStates.AddRunStates(states,
{
	runtimeline =
	{
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.growl, nil, .25)
		end),
	},
})

CommonStates.AddFrozenStates(states)

return StateGraph("ty_tugou", states, events, "idle")
