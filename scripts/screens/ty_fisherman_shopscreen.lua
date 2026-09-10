local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local COLS = 4
local ROWS = 3
local CELL_W = 160
local CELL_H = 130
local SHOP_ATLAS = "images/ui/ty_shops.xml"
local SHOP_BG_TEX = "ty_fisherman_shop.tex"
-- atlas UV 宽高比约 0.831（竖向铺面图）
local BG_W = 1100
local BG_H = 700

local function GetItemAtlas(prefab)
	local tex = prefab .. ".tex"
	if GetInventoryItemAtlas ~= nil then
		local atlas = GetInventoryItemAtlas(tex)
		if atlas ~= nil then
			return atlas, tex
		end
	end
	return "images/inventoryimages.xml", tex
end

local function CountGoldClient(owner)
	local currency = TUNING.TY_FISHERMAN_SHOP_CURRENCY or "goldnugget"
	if owner == nil or owner.replica == nil or owner.replica.inventory == nil then
		return 0
	end
	local inv = owner.replica.inventory
	if inv.Has ~= nil then
		local _, count = inv:Has(currency, 1, true)
		return count or 0
	end
	return 0
end

local TyFishermanShopScreen = Class(Screen, function(self, owner, shop)
	self.owner = owner
	self.shop = shop
	Screen._ctor(self, "TyFishermanShopScreen")

	local black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
	black.image:SetVRegPoint(ANCHOR_MIDDLE)
	black.image:SetHRegPoint(ANCHOR_MIDDLE)
	black.image:SetVAnchor(ANCHOR_MIDDLE)
	black.image:SetHAnchor(ANCHOR_MIDDLE)
	black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
	black.image:SetTint(0, 0, 0, .55)
	black:SetOnClick(function() self:Close() end)
	black:SetHelpTextMessage("")

	self.root = self:AddChild(Widget("root"))
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetPosition(0, 20)

	self.bg = self.root:AddChild(Image(SHOP_ATLAS, SHOP_BG_TEX))
	self.bg:SetSize(BG_W, BG_H)

	self.title = self.root:AddChild(Text(HEADERFONT, 34))
	self.title:SetString(STRINGS.TY_FISHERMAN_SHOP_TITLE or "Fish Stall")
	self.title:SetPosition(0, ROWS * CELL_H * 0.5 + 20)
	self.title:SetColour(1, 0.95, 0.8, 1)

	self.cells = {}
	local origin_x = -((COLS - 1) * CELL_W) * 0.5
	local origin_y = ((ROWS - 1) * CELL_H) * 0.5 - 10

	for row = 0, ROWS - 1 do
		for col = 0, COLS - 1 do
			local idx = row * COLS + col + 1
			local cell = self.root:AddChild(Widget("cell" .. idx))
			cell:SetPosition(origin_x + col * CELL_W, origin_y - row * CELL_H)

			-- 背景方块
			cell.bg = cell:AddChild(Image("images/global.xml", "square.tex"))
			cell.bg:SetSize(100, 100)
			cell.bg:SetTint(0.22, 0.24, 0.28, 0.95)

			-- 物品图案
			cell.icon = cell:AddChild(Image())
			cell.icon:SetScale(1)
			cell.icon:SetPosition(0, 12)

			-- 库存数字
			cell.stock = cell:AddChild(Text(NUMBERFONT, 22))
			cell.stock:SetPosition(0, -25)
			cell.stock:SetColour(0.9, 0.9, 0.9, 1)

			-- 购买价格
			cell.buy = cell:AddChild(ImageButton("images/global.xml", "square.tex"))
			cell.buy:SetPosition(0, -48)
			-- 悬停略放大，但仍保持扁平条比例（勿用默认 1.2 正方形）
			local buy_sx, buy_sy = 0.9, 0.35
			local buy_fx, buy_fy = 1.0, 0.39
			cell.buy.scale_on_focus = true
			cell.buy.normal_scale = { buy_sx, buy_sy, 1 }
			cell.buy.focus_scale = { buy_fx, buy_fy, 1 }
			cell.buy.image:SetScale(buy_sx, buy_sy)
			cell.buy:SetTextSize(26)
			-- ImageButton 启用/禁用/聚焦会改字色，三态统一黑色
			local price_colour = { 0, 0, 0, 1 }
			cell.buy:SetTextColour(unpack(price_colour))
			if cell.buy.SetTextFocusColour ~= nil then
				cell.buy:SetTextFocusColour(unpack(price_colour))
			else
				cell.buy.textfocuscolour = price_colour
			end
			if cell.buy.SetTextDisabledColour ~= nil then
				cell.buy:SetTextDisabledColour(unpack(price_colour))
			else
				cell.buy.textdisabledcolour = price_colour
			end
			-- 价格数字略右移，左侧留给货币图标
			cell.buy.text:SetPosition(10, 0)

			-- 货币图标
			cell.coin = cell.buy:AddChild(Image(SHOP_ATLAS, "ty_coin.tex"))
			cell.coin:SetScale(0.35)
			cell.coin:SetPosition(-18, 0)
			cell.buy:SetOnClick(function()
				self:OnBuy(idx)
			end)

			self.cells[idx] = cell
		end
	end

	self.close_btn = self.root:AddChild(ImageButton(SHOP_ATLAS, "ty_fisherman_shop_close.tex"))
	self.close_btn:SetPosition(COLS * CELL_W * 0.5 + 10, ROWS * CELL_H * 0.5 + 20)
	self.close_btn:SetScale(0.35, 0.35)
	-- self.close_btn:SetText("X")
	-- self.close_btn:SetTextSize(32)
	self.close_btn:SetOnClick(function() self:Close() end)

	if shop ~= nil then
		self._listen = function() self:Refresh() end
		self.inst:ListenForEvent("ty_shop_ui_dirty", self._listen, shop)
		self.inst:ListenForEvent("ty_shop_stock_dirty", self._listen, shop)
	end
	if owner ~= nil then
		self._inv_listen = function() self:Refresh() end
		self.inst:ListenForEvent("itemget", self._inv_listen, owner)
		self.inst:ListenForEvent("itemlose", self._inv_listen, owner)
		self.inst:ListenForEvent("stacksizechange", self._inv_listen, owner)
	end

	self:Refresh()
	self:StartUpdating()
	SetAutopaused(true)
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
end)

function TyFishermanShopScreen:OnBuy(idx)
	if self.shop == nil or not self.shop:IsValid() then
		self:Close()
		return
	end
	SendModRPCToServer(GetModRPC("ty", "FishermanShopBuy"), self.shop, idx)
end

function TyFishermanShopScreen:Refresh()
	if self.shop == nil or not self.shop:IsValid() then
		return
	end
	local comp = self.shop.replica and self.shop.replica.ty_fisherman_shop
	-- 无 replica 时直接读组件（主机）或 net 解码
	local slots = {}
	if self.shop.components ~= nil and self.shop.components.ty_fisherman_shop ~= nil then
		slots = self.shop.components.ty_fisherman_shop:GetSlots()
	elseif self.shop._stock_str ~= nil then
		local DecodeSlots = require("components/ty_fisherman_shop").DecodeSlots
		slots = DecodeSlots(self.shop._stock_str:value())
	end

	local gold = CountGoldClient(self.owner)

	for i = 1, 12 do
		local cell = self.cells[i]
		local s = slots[i]
		if s == nil or s.prefab == nil then
			-- 从未上架的空位
			cell.icon:Hide()
			cell.stock:SetString("")
			cell.buy:Hide()
			cell.coin:Hide()
			cell.bg:SetTint(0.18, 0.18, 0.2, 0.7)
		else
			local stock = s.stock or 0
			local price = s.price or 0
			local atlas, tex = GetItemAtlas(s.prefab)
			cell.icon:SetTexture(atlas, tex)
			cell.icon:Show()
			cell.stock:SetString(string.format(STRINGS.TY_FISHERMAN_SHOP_STOCK or "x%d", stock))
			cell.bg:SetTint(0.22, 0.24, 0.28, stock > 0 and 0.95 or 0.7)

			if stock <= 0 then
				-- 售罄：保留图案与库存 0，隐藏购买
				cell.buy:Hide()
				cell.coin:Hide()
				cell.stock:SetColour(0.72, 0.38, 0.35, 1)
			else
				cell.stock:SetColour(0.9, 0.9, 0.9, 1)
				cell.buy:SetText(string.format(STRINGS.TY_FISHERMAN_SHOP_PRICE or "%d", price))
				cell.buy:Show()
				cell.coin:Show()
				local can_buy = gold >= price
				if can_buy then
					cell.buy:Enable()
				else
					cell.buy:Disable()
				end
				cell.buy.text:SetColour(0, 0, 0, 1)
				cell.buy.image:SetScale(0.9, 0.35)
			end
		end
	end
end

function TyFishermanShopScreen:Close()
	if self._closing then
		return
	end
	self._closing = true
	if self.shop ~= nil and self.shop:IsValid() then
		SendModRPCToServer(GetModRPC("ty", "FishermanShopClose"), self.shop)
	end
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
	TheFrontEnd:PopScreen(self)
end

function TyFishermanShopScreen:OnDestroy()
	if self.shop ~= nil and self._listen ~= nil then
		self.inst:RemoveEventCallback("ty_shop_ui_dirty", self._listen, self.shop)
		self.inst:RemoveEventCallback("ty_shop_stock_dirty", self._listen, self.shop)
	end
	if self.owner ~= nil and self._inv_listen ~= nil then
		self.inst:RemoveEventCallback("itemget", self._inv_listen, self.owner)
		self.inst:RemoveEventCallback("itemlose", self._inv_listen, self.owner)
		self.inst:RemoveEventCallback("stacksizechange", self._inv_listen, self.owner)
	end
	SetAutopaused(false)
	TyFishermanShopScreen._base.OnDestroy(self)
end

function TyFishermanShopScreen:OnUpdate(dt)
	if self.shop == nil or not self.shop:IsValid() then
		self:Close()
		return
	end
	local tending = self.shop._tending ~= nil and self.shop._tending:value()
		or self.shop:HasTag("ty_shop_tending")
	if not tending then
		self:Close()
		return
	end
	if self.owner ~= nil and self.owner:IsValid() then
		local dist = TUNING.TY_FISHERMAN_SHOP_INTERACT_DIST or 3.5
		if not self.owner:IsNear(self.shop, dist + 1.5) then
			self:Close()
		end
	end
end

function TyFishermanShopScreen:OnControl(control, down)
	if TyFishermanShopScreen._base.OnControl(self, control, down) then
		return true
	end
	if not down and (control == CONTROL_CANCEL or control == CONTROL_MENU_BACK) then
		self:Close()
		return true
	end
	return false
end

return TyFishermanShopScreen
