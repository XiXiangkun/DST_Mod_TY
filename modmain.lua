GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end,
})

modimport("init/init_tiles")
modimport("init/init_tuning")
modimport("init/init_assets")
modimport("init/init_prefabs")
modimport("init/init_strings")
modimport("init/init_postinit")

require("debugcommands")


