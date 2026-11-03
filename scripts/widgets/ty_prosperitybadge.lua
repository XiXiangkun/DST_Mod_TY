--[[
	左上角繁荣度 HUD。
	数字滚动对齐原版农产品秤：播 placeveg/replaceveg，5 帧后 OverrideSymbol 定格。
	OnUpdate 轮询数值，避免只靠 net dirty 漏刷新。
]]

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"

local DIGITS = 5
local DISPLAY_MAX = 99999
local BUILD = "trophyscale_oversizedveggies"
local FRAME = 1 / 30

local DIGIT_COLORS = {
	"_black",
	"_black",
	"_black",
	"_white",
	"_white",
}

local SOUND_SPIN = "hookline/common/trophyscale_fish/ticker_LP"
local SOUND_BELL = "hookline/common/trophyscale_fish/bell"

-- 对齐 trophyscale_oversizedveggies 的 replace 时机
local SOUND_DELAY = {
	spin = 4,
	spin_stop = 46,
	bell = 48,
}

local PANEL_SHOWN = Vector3(0, 0, 0)
local PANEL_HIDDEN = Vector3(-240, 0, 0)
local SLIDE_TIME = 0.35

local function FrameTime()
	return (FRAMES ~= nil and FRAMES) or FRAME
end

local function FormatDigits(value)
	value = math.floor(tonumber(value) or 0)
	if value < 0 then
		value = 0
	elseif value > DISPLAY_MAX then
		value = DISPLAY_MAX
	end
	return string.format("%0"..DIGITS.."d", value)
end

local function GetProsperityNet()
	if TheWorld == nil then
		return nil
	end
	if TheWorld.net ~= nil and TheWorld.net._ty_prosperity ~= nil then
		return TheWorld.net._ty_prosperity
	end
	return TheWorld._ty_prosperity
end

local function GetWorldProsperity()
	if TheWorld ~= nil
		and TheWorld.ismastersim
		and TheWorld.components.ty_prosperity ~= nil then
		return TheWorld.components.ty_prosperity:Get()
	end
	local netvar = GetProsperityNet()
	if netvar ~= nil then
		return netvar:value() or 0
	end
	return 0
end

local function GetNextUnlockThreshold(value)
	local list = TUNING.TY_PROSPERITY_UNLOCKS
	if list == nil then
		return nil
	end
	local best = nil
	for _, entry in ipairs(list) do
		local th = entry ~= nil and entry.threshold or nil
		if th ~= nil and value < th then
			if best == nil or th < best then
				best = th
			end
		end
	end
	return best
end

local TyProsperityBadge = Class(Widget, function(self, owner)
	Widget._ctor(self, "TyProsperityBadge")
	self:UpdateWhilePaused(false)
	self.owner = owner

	self.value = 0
	self.expanded = true
	self._spinning = false
	self._spin_elapsed = 0
	self._spin_final = 0
	self._had_nonzero = false
	self._digits_applied = false
	self._spin_sound_started = false
	self._spin_sound_stopped = false
	self._bell_played = false
	self._slide_busy = false

	self.root = self:AddChild(Widget("ty_prosperity_root"))

	self.panel = self.root:AddChild(Widget("ty_prosperity_panel"))
	self.panel:SetPosition(PANEL_SHOWN:Get())

	self.scale = self.panel:AddChild(UIAnim())
	local anim = self.scale:GetAnimState()
	anim:SetBank(BUILD)
	anim:SetBuild(BUILD)
	anim:PlayAnimation("noveg_idle", true)
	anim:AnimateWhilePaused(false)
	self.scale:SetScale(0.42)
	self.scale:SetPosition(0, -10)
	self.scale:SetClickable(false)

	self.title = self.panel:AddChild(Text(HEADERFONT, 22))
	self.title:SetString(STRINGS.TY_PROSPERITY_TITLE or "Prosperity")
	self.title:SetPosition(0, 58)
	self.title:SetColour(1, 0.95, 0.8, 1)
	self.title:SetClickable(false)

	self.next_label = self.panel:AddChild(Text(BODYTEXTFONT, 18))
	self.next_label:SetPosition(0, -58)
	self.next_label:SetColour(0.85, 0.85, 0.75, 1)
	self.next_label:SetClickable(false)

	self.arrow = self.root:AddChild(ImageButton(
		"images/quagmire_recipebook.xml",
		"arrow2_left.tex",
		"arrow2_left_over.tex",
		"arrow_left_disabled.tex",
		"arrow2_left.tex"
	))
	self.arrow:SetPosition(95, 0)
	self.arrow:SetScale(0.55)
	self.arrow:SetOnClick(function()
		self:Toggle()
	end)

	self:SetDigits(0)
	self:RefreshNextLabel(0)

	self._on_dirty = function()
		self:OnProsperityDirty()
	end
	self._on_changed = function(_, value)
		self:SetProsperity(value or GetWorldProsperity(), self.expanded)
	end

	self:_BindListeners()
	self.inst:DoTaskInTime(0, function()
		self:_BindListeners()
		self:SetProsperity(GetWorldProsperity(), false)
	end)

	-- 常驻 OnUpdate：转轮时间轴 + 数值轮询（防止事件漏接导致一直 00000）
	self:StartUpdating()
end)

function TyProsperityBadge:_UnbindListeners()
	if TheWorld ~= nil then
		self.inst:RemoveEventCallback("ty_prosperity_changed", self._on_changed, TheWorld)
		self.inst:RemoveEventCallback("ty_prosperity_dirty", self._on_dirty, TheWorld)
		if TheWorld.net ~= nil then
			self.inst:RemoveEventCallback("ty_prosperity_dirty", self._on_dirty, TheWorld.net)
		end
	end
end

function TyProsperityBadge:_BindListeners()
	self:_UnbindListeners()
	if TheWorld == nil then
		return
	end
	self.inst:ListenForEvent("ty_prosperity_changed", self._on_changed, TheWorld)
	self.inst:ListenForEvent("ty_prosperity_dirty", self._on_dirty, TheWorld)
	if TheWorld.net ~= nil then
		self.inst:ListenForEvent("ty_prosperity_dirty", self._on_dirty, TheWorld.net)
	end
end

function TyProsperityBadge:OnRemoveEntity()
	self:CancelSpin()
	self:_UnbindListeners()
	self:StopUpdating()
end

function TyProsperityBadge:CancelSpin()
	if TheFrontEnd ~= nil then
		TheFrontEnd:GetSound():KillSound("ty_pros_spin")
	end
	self._spinning = false
	self._spin_elapsed = 0
	self._digits_applied = false
	self._spin_sound_started = false
	self._spin_sound_stopped = false
	self._bell_played = false
end

function TyProsperityBadge:SetDigits(value)
	local formatted = FormatDigits(value)
	local anim = self.scale:GetAnimState()
	for i = 1, DIGITS do
		local digit = string.sub(formatted, i, i)
		anim:OverrideSymbol("column"..i, BUILD, "number"..digit..(DIGIT_COLORS[i] or "_black"))
	end
end

function TyProsperityBadge:RefreshNextLabel(value)
	local next_th = GetNextUnlockThreshold(value)
	if next_th == nil then
		self.next_label:SetString(STRINGS.TY_PROSPERITY_MAXED or "")
	else
		local fmt = STRINGS.TY_PROSPERITY_NEXT or "Next: %d"
		self.next_label:SetString(string.format(fmt, next_th))
	end
end

function TyProsperityBadge:PlaySpin(final_value, from_zero)
	self:CancelSpin()
	self._spinning = true
	self._spin_elapsed = 0
	self._spin_final = final_value
	self._digits_applied = false
	self._spin_sound_started = false
	self._spin_sound_stopped = false
	self._bell_played = false

	local anim = self.scale:GetAnimState()
	-- 不挂作物，只要转轮
	anim:ClearOverrideSymbol("swap_body")
	anim:ClearOverrideSymbol("swap_normal")

	-- 与原版一致：从空/0 用 placeveg，已有值用 replaceveg
	if from_zero then
		anim:PlayAnimation("placeveg")
	else
		anim:PlayAnimation("replaceveg")
	end
	anim:PushAnimation("noveg_idle", true)
end

function TyProsperityBadge:OnUpdate(dt)
	if TheNet ~= nil and TheNet:IsServerPaused() then
		return
	end

	local ft = FrameTime()

	if self._spinning then
		self._spin_elapsed = self._spin_elapsed + dt
		local frames = self._spin_elapsed / ft

		-- 5 帧后写入最终数字（转轮动画已开始，对齐原版 SetDigits 时机）
		if not self._digits_applied and frames >= 5 then
			self._digits_applied = true
			self:SetDigits(self._spin_final)
		end

		if not self._spin_sound_started and frames >= SOUND_DELAY.spin then
			self._spin_sound_started = true
			if TheFrontEnd ~= nil then
				TheFrontEnd:GetSound():PlaySound(SOUND_SPIN, "ty_pros_spin")
			end
		end

		if self._spin_sound_started and not self._spin_sound_stopped and frames >= SOUND_DELAY.spin_stop then
			self._spin_sound_stopped = true
			if TheFrontEnd ~= nil then
				TheFrontEnd:GetSound():KillSound("ty_pros_spin")
			end
		end

		if not self._bell_played and frames >= SOUND_DELAY.bell then
			self._bell_played = true
			if TheFrontEnd ~= nil then
				TheFrontEnd:GetSound():PlaySound(SOUND_BELL)
			end
		end

		-- 动画播完：定格并结束滚动状态
		local anim = self.scale:GetAnimState()
		if anim:IsCurrentAnimation("noveg_idle") then
			self:SetDigits(self._spin_final)
			self:CancelSpin()
		end
		return
	end

	-- 非滚动时轮询：主机组件 / net 值变化则刷新
	local current = GetWorldProsperity()
	if current ~= self.value then
		self:SetProsperity(current, self.expanded)
	end
end

function TyProsperityBadge:SetProsperity(value, animate)
	value = math.floor(tonumber(value) or 0)
	if value < 0 then
		value = 0
	end

	local old = self.value
	if old == value and not self._spinning then
		self:RefreshNextLabel(value)
		return
	end

	self.value = value
	self:RefreshNextLabel(value)

	if animate and self.expanded and old ~= value then
		local from_zero = not self._had_nonzero
		self._had_nonzero = value > 0 or self._had_nonzero
		self:PlaySpin(value, from_zero)
	else
		self:CancelSpin()
		self:SetDigits(value)
		if value > 0 then
			self._had_nonzero = true
		end
		local anim = self.scale:GetAnimState()
		if not anim:IsCurrentAnimation("noveg_idle") then
			anim:PlayAnimation("noveg_idle", true)
		end
	end
end

function TyProsperityBadge:OnProsperityDirty()
	self:SetProsperity(GetWorldProsperity(), self.expanded)
end

function TyProsperityBadge:IsExpanded()
	return self.expanded
end

function TyProsperityBadge:Expand()
	if self.expanded or self._slide_busy then
		return
	end
	self.expanded = true
	self._slide_busy = true
	self.arrow:SetTextures(
		"images/quagmire_recipebook.xml",
		"arrow2_left.tex",
		"arrow2_left_over.tex",
		"arrow_left_disabled.tex",
		"arrow2_left.tex"
	)
	local from = self.panel:GetPosition()
	self.panel:MoveTo(from, PANEL_SHOWN, SLIDE_TIME, function()
		self._slide_busy = false
	end)
	self:SetProsperity(GetWorldProsperity(), false)
end

function TyProsperityBadge:Collapse()
	if not self.expanded or self._slide_busy then
		return
	end
	self.expanded = false
	self._slide_busy = true
	self:CancelSpin()
	self.arrow:SetTextures(
		"images/quagmire_recipebook.xml",
		"arrow2_right.tex",
		"arrow2_right_over.tex",
		"arrow_right_disabled.tex",
		"arrow2_right.tex"
	)
	local from = self.panel:GetPosition()
	self.panel:MoveTo(from, PANEL_HIDDEN, SLIDE_TIME, function()
		self._slide_busy = false
	end)
end

function TyProsperityBadge:Toggle()
	if self.expanded then
		self:Collapse()
	else
		self:Expand()
	end
end

return TyProsperityBadge
