--[[
	水田波纹
	- 会沉掉落物：各 replica 0.5s 刷新（见 inventoryitem postinit）
	- 地面生物：本机围着玩家扫，只给湿田上的对象挂本地 float_fx
]]

local Ripple = {}

local PaddyTiles = require("ty_paddy_tiles")

local TAG_SINKABLE = "ty_paddy_sinkable"

local function IsWetPaddyAt(x, y, z)
	return PaddyTiles.IsWetPaddyAtPoint(x, y, z)
end

function Ripple.IsWetPaddyAt(x, y, z)
	return IsWetPaddyAt(x, y, z)
end

-- 会沉物是否正泡在湿田里（未持有）
function Ripple.IsSoakingInPaddy(inst)
	if not Ripple.IsSinkableItem(inst) then
		return false
	end
	local inv = inst.components.inventoryitem
	if inv == nil or inv:IsHeld() or inst:IsInLimbo() then
		return false
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	return IsWetPaddyAt(x, y, z)
end

function Ripple.MarkSinkable(inst, should_sink)
	if inst == nil or not inst:IsValid() then
		return
	end
	if should_sink then
		inst:AddTag(TAG_SINKABLE)
	else
		inst:RemoveTag(TAG_SINKABLE)
		Ripple.Clear(inst)
	end
end

function Ripple.IsSinkableItem(inst)
	if inst == nil or not inst:IsValid() then
		return false
	end
	if inst.components.floater ~= nil then
		return false
	end
	if inst:HasTag(TAG_SINKABLE) then
		return true
	end
	local inv = inst.components.inventoryitem
	return inv ~= nil and inv.sinks == true
end

local function AttachFx(inst, prefab, anim)
	local fx = SpawnPrefab(prefab)
	if fx == nil then
		return nil
	end
	fx.entity:SetParent(inst.entity)
	fx.Transform:SetPosition(0, 0, 0)
	-- 不改 OceanBlend：与 floater 官方 float_fx 同色
	if anim ~= nil and fx.AnimState ~= nil then
		fx.AnimState:PlayAnimation(anim, true)
	end
	return fx
end

function Ripple.Clear(inst)
	if inst == nil then
		return
	end
	if inst._ty_ripple_front ~= nil then
		if inst._ty_ripple_front:IsValid() then
			inst._ty_ripple_front:Remove()
		end
		inst._ty_ripple_front = nil
	end
	if inst._ty_ripple_back ~= nil then
		if inst._ty_ripple_back:IsValid() then
			inst._ty_ripple_back:Remove()
		end
		inst._ty_ripple_back = nil
	end
end

function Ripple.Show(inst, size)
	size = size or "small"
	if inst._ty_ripple_front == nil or not inst._ty_ripple_front:IsValid() then
		inst._ty_ripple_front = AttachFx(inst, "float_fx_front", "idle_front_" .. size)
	end
	if inst._ty_ripple_back == nil or not inst._ty_ripple_back:IsValid() then
		inst._ty_ripple_back = AttachFx(inst, "float_fx_back", "idle_back_" .. size)
	end
end

-- 客户端/主机本地：按地皮决定是否显示波纹（不改物品 AnimState）
function Ripple.Update(inst)
	if inst == nil or not inst:IsValid() then
		return
	end

	if inst.components.floater ~= nil then
		Ripple.Clear(inst)
		return
	end

	local inv = inst.replica.inventoryitem
	if inv == nil or inv:IsHeld() or inst:IsInLimbo() then
		Ripple.Clear(inst)
		return
	end

	if not Ripple.IsSinkableItem(inst) then
		Ripple.Clear(inst)
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	if IsWetPaddyAt(x, y, z) then
		Ripple.Show(inst)
	else
		Ripple.Clear(inst)
	end
end

-- 地面生物：本机扫玩家附近，不给每只生物挂定时器
local CREATURE_SCAN_RADIUS = 40
local CREATURE_MUST_TAGS = { "_health" }
local CREATURE_CANT_TAGS = {
	"FX",
	"INLIMBO",
	"DECOR",
	"CLASSIFIED",
	"flying",
	"playerghost",
	"ghost",
	"structure",
	"wall",
}

-- [inst] = true，本机当前挂着生物波纹的对象
local tracked_creatures = {}

local function CreatureFxSize(inst)
	if inst:HasTag("largecreature") or inst:HasTag("epic") then
		return "large"
	end
	if inst:HasTag("player") then
		return "small"
	end
	return "med"
end

local function IsRiding(inst)
	local rider = inst.replica ~= nil and inst.replica.rider or nil
	return rider ~= nil and rider.IsRiding ~= nil and rider:IsRiding()
end

function Ripple.ShouldCreatureRipple(inst)
	if inst == nil or not inst:IsValid() or inst:IsAsleep() then
		return false
	end
	if inst:HasTag("flying") then
		return false
	end
	-- 坐骑上只给坐骑脚下波纹，避免人牛各一圈
	if IsRiding(inst) then
		return false
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	return IsWetPaddyAt(x, y, z)
end

function Ripple.ScanCreatures()
	if TUNING.TY_PADDY_CREATURE_RIPPLE == false then
		for inst in pairs(tracked_creatures) do
			if inst:IsValid() then
				Ripple.Clear(inst)
			end
			tracked_creatures[inst] = nil
		end
		return
	end

	if ThePlayer == nil or not ThePlayer:IsValid() then
		return
	end

	local x, y, z = ThePlayer.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, CREATURE_SCAN_RADIUS, CREATURE_MUST_TAGS, CREATURE_CANT_TAGS)
	local seen = {}

	for i = 1, #ents do
		local inst = ents[i]
		if Ripple.ShouldCreatureRipple(inst) then
			seen[inst] = true
			tracked_creatures[inst] = true
			Ripple.Show(inst, CreatureFxSize(inst))
		end
	end

	for inst in pairs(tracked_creatures) do
		if seen[inst] == nil then
			if inst:IsValid() then
				Ripple.Clear(inst)
			end
			tracked_creatures[inst] = nil
		end
	end
end

return Ripple
