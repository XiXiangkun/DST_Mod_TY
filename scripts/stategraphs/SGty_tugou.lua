--[[
	大黄狗 stategraph
	动画名对齐官方 hound / warglet（idle / atk / hit / death / run_* / sleep_*）。
]]

require("stategraphs/commonstates")

local events =
{
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnLocomote(true, false),
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
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("atk")
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end,

		timeline =
		{
			TimeEvent(14 * FRAMES, function(inst)
				inst.components.combat:DoAttack()
				inst.SoundEmitter:PlaySound(inst.sounds.bite)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
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
