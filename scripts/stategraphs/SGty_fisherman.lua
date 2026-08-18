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
		end,
	},
}

CommonStates.AddWalkStates(states,
{
	walktimeline =
	{
		TimeEvent(0, PlayFootstep),
		TimeEvent(12 * FRAMES, PlayFootstep),
	},
})

CommonStates.AddRunStates(states,
{
	runtimeline =
	{
		TimeEvent(0, PlayFootstep),
		TimeEvent(10 * FRAMES, PlayFootstep),
	},
})

CommonStates.AddSimpleActionState(states, "gohome", "pig_pickup", 4 * FRAMES, { "busy" })

return StateGraph("ty_fisherman", states, events, "idle", actionhandlers)
