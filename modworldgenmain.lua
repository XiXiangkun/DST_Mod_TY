GLOBAL.setmetatable(env, {
	__index = function(t, k)
		return GLOBAL.rawget(GLOBAL, k)
	end,
})

-- 世界生成阶段也需要注册自定义地皮
modimport("init/init_tiles")
