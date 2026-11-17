--[[
	玩家模板渔夫 SG（bank = wilson）
	- 无 walk_*，走路态映射到 run_*
	- gohome 不用 pig_pickup
	- emote_hat 来自官方 player_emotes（wilson bank）
]]

require("stategraphs/commonstates")

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events =
{
	CommonHandlers.OnStep(),
	CommonHandlers.OnLocomote(true, true),
}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, pushanim)
			inst.components.locomotor:StopMoving()
			if pushanim then
				if type(pushanim) == "string" then
					inst.AnimState:PlayAnimation(pushanim)
				end
				inst.AnimState:PushAnimation("idle_loop", true)
			else
				inst.AnimState:PlayAnimation("idle_loop", true)
			end

			if inst._tending_shop then
				inst.sg:SetTimeout(4 + math.random() * 5)
			end
		end,

		ontimeout = function(inst)
			if inst._tending_shop and not inst.sg:HasStateTag("busy") then
				inst.sg:GoToState("emote_hat")
			else
				inst.sg:GoToState("idle")
			end
		end,
	},

	State{
		name = "emote_hat",
		tags = { "idle", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("emote_hat")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "gohome",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("idle_loop", true)
			inst:PerformBufferedAction()
			inst.sg:GoToState("idle")
		end,
	},
}

-- wilson 没有常规 walk_*，走路播放 run 动画、保持 walkspeed
CommonStates.AddWalkStates(states,
{
	walktimeline =
	{
		TimeEvent(0, PlayFootstep),
		TimeEvent(10 * FRAMES, PlayFootstep),
	},
},
{
	startwalk = "run_pre",
	walk = "run_loop",
	stopwalk = "run_pst",
})

CommonStates.AddRunStates(states,
{
	runtimeline =
	{
		TimeEvent(0, PlayFootstep),
		TimeEvent(10 * FRAMES, PlayFootstep),
	},
})

return StateGraph("ty_fisherman_w", states, events, "idle", actionhandlers)
