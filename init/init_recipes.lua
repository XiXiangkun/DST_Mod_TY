--[[
	渔夫小屋 / 铺面配方
]]

local function FindExistingFishermanHouse()
	return TheSim:FindFirstEntityWithTag("ty_fisherman_house")
end

local function CanBuildFishermanHouse(recipe, builder, pt, rotation, prototyper, skin)
	if FindExistingFishermanHouse() ~= nil then
		return false, "TY_FISHERMAN_HOUSE_EXISTS"
	end
	local mgr = TheWorld.components ~= nil and TheWorld.components.ty_fisherman_manager or nil
	if mgr ~= nil and mgr:HasHouse() then
		return false, "TY_FISHERMAN_HOUSE_EXISTS"
	end
	return true
end

local function FishermanHousePlacerTest(pt, rot)
	return FindExistingFishermanHouse() == nil
end

AddRecipe2(
	"ty_fisherman_house",
	{
		Ingredient("boards", 4),
		Ingredient("cutstone", 2),
	},
	TECH.SCIENCE_ONE,
	{
		placer = "ty_fisherman_house_placer",
		min_spacing = 2,
		canbuild = CanBuildFishermanHouse,
		testfn = FishermanHousePlacerTest,
	},
	{ "STRUCTURES" }
)

AddRecipe2(
	"ty_fisherman_shop",
	{
		Ingredient("boards", 3),
		Ingredient("rope", 1),
	},
	TECH.SCIENCE_ONE,
	{
		placer = "ty_fisherman_shop_placer",
		min_spacing = 1.5,
	},
	{ "STRUCTURES" }
)
