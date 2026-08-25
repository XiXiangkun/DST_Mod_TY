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
