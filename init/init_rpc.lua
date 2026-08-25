--[[
	渔夫铺面 RPC / Action
]]

local TY_RPC = "ty"

AddAction("TY_OPEN_FISH_SHOP", STRINGS.ACTIONS.TY_OPEN_FISH_SHOP or "Browse", function(act)
	if act.target ~= nil
		and act.target.components.ty_fisherman_shop ~= nil
		and act.doer ~= nil then
		return act.target.components.ty_fisherman_shop:TryOpen(act.doer)
	end
	return false
end)

ACTIONS.TY_OPEN_FISH_SHOP.priority = 10
ACTIONS.TY_OPEN_FISH_SHOP.distance = TUNING.TY_FISHERMAN_SHOP_INTERACT_DIST or 3.5
ACTIONS.TY_OPEN_FISH_SHOP.mount_valid = true

AddComponentAction("SCENE", "ty_fisherman_shop", function(inst, doer, actions, right)
	if right then
		return
	end
	local tending = inst._tending ~= nil and inst._tending:value()
		or inst:HasTag("ty_shop_tending")
	if tending then
		table.insert(actions, ACTIONS.TY_OPEN_FISH_SHOP)
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TY_OPEN_FISH_SHOP, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TY_OPEN_FISH_SHOP, "give"))

AddModRPCHandler(TY_RPC, "FishermanShopBuy", function(player, shop, slot_index)
	if player == nil or shop == nil or not shop:IsValid() then
		return
	end
	if shop.components.ty_fisherman_shop == nil then
		return
	end
	local dist = (TUNING.TY_FISHERMAN_SHOP_INTERACT_DIST or 3.5) + 2
	if not player:IsNear(shop, dist) then
		return
	end
	shop.components.ty_fisherman_shop:TryBuy(player, slot_index)
end)

AddModRPCHandler(TY_RPC, "FishermanShopClose", function(player, shop)
	if player == nil or shop == nil or not shop:IsValid() then
		return
	end
	if shop.components.ty_fisherman_shop ~= nil then
		shop.components.ty_fisherman_shop:CloseFrom(player)
	end
end)

AddClientModRPCHandler(TY_RPC, "FishermanShopOpen", function(shop)
	if shop == nil or not shop:IsValid() then
		return
	end
	local player = ThePlayer
	if player == nil then
		return
	end
	-- 已打开则刷新
	local screen = TheFrontEnd:GetActiveScreen()
	if screen ~= nil and screen.name == "TyFishermanShopScreen" then
		screen.shop = shop
		screen:Refresh()
		return
	end
	local ShopScreen = require("screens/ty_fisherman_shopscreen")
	TheFrontEnd:PushScreen(ShopScreen(player, shop))
end)

AddClientModRPCHandler(TY_RPC, "FishermanShopForceClose", function(shop)
	local screen = TheFrontEnd:GetActiveScreen()
	if screen ~= nil and screen.name == "TyFishermanShopScreen" then
		if shop == nil or screen.shop == shop then
			screen._closing = true
			TheFrontEnd:PopScreen(screen)
		end
	end
end)
