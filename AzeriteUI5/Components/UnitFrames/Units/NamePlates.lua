--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local Addon, ns = ...
local oUF = ns.oUF

local NamePlates = ns:NewModule("NamePlates", "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0")

local defaults = { profile = ns:Merge({
	enabled = true
}, ns.NamePlate.defaults) }

local style = function(self, unit)
end

local cvars = {
	-- If these are enabled the GameTooltip will become protected,
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these.
	["nameplateShowDebuffsOnFriendly"] = 0,

	["nameplateLargeTopInset"] = .15, -- default .1
	["nameplateOtherTopInset"] = .15, -- default .08
	["nameplateLargeBottomInset"] = .15, -- default .15
	["nameplateOtherBottomInset"] = .15, -- default .1
	["nameplateClassResourceTopInset"] = 0,

	-- new CVar July 14th 2020. Wohoo! Thanks torhaala for telling me! :)
	-- *has no effect in retail. probably for the classics only.
	["clampTargetNameplateToScreen"] = 1,

	-- Nameplate scale
	["nameplateMinScale"] = .6, -- .8
	["nameplateMaxScale"] = 1,
	["nameplateLargerScale"] = 1, -- Scale modifier for large plates, used for important monsters
	["nameplateGlobalScale"] = 1,
	["NamePlateHorizontalScale"] = 1,
	["NamePlateVerticalScale"] = 1,

	["nameplateOccludedAlphaMult"] = .15, -- .4
	["nameplateSelectedAlpha"] = 1, -- 1

	-- The maximum distance from the camera where plates will still have max scale and alpha
	["nameplateMaxScaleDistance"] = 10, -- 10

	-- The distance from the max distance that nameplates will reach their minimum scale.
	-- *seems to be a limit on how big this can be, too big resets to 1 it seems?
	["nameplateMinScaleDistance"] = 10, -- 10

	-- The minimum alpha of nameplates.
	["nameplateMinAlpha"] = .4, -- 0.6

	-- The distance from the max distance that nameplates will reach their minimum alpha.
	["nameplateMinAlphaDistance"] = 10, -- 10

	-- 	The max alpha of nameplates.
	["nameplateMaxAlpha"] = 1, -- 1

	-- The distance from the camera that nameplates will reach their maximum alpha.
	["nameplateMaxAlphaDistance"] = 30, -- 40

	-- Show nameplates above heads or at the base (0 or 2,
	["nameplateOtherAtBase"] = 0,

	-- Scale and Alpha of the selected nameplate (current target,
	["nameplateSelectedScale"] = 1, -- 1.2

	-- The max distance to show nameplates.
	--["nameplateMaxDistance"] = 60, -- 20 is classic upper limit, 60 is BfA default

	-- The max distance to show the target nameplate when the target is behind the camera.
	["nameplateTargetBehindMaxDistance"] = 15 -- 15
}

local callback = function(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
	elseif (event == "NAME_PLATE_UNIT_ADDED") then

		self.isPRD = UnitIsUnit(unit, "player")

		ns.NamePlates[self] = nameplate
		ns.ActiveNamePlates[self] = nameplate

	elseif (event == "NAME_PLATE_UNIT_REMOVED") then

		self.isPRD = nil

		ns.ActiveNamePlates[self] = nil
	end
end

local MOUSEOVER
local checkMouseOver = function()
	local hasMouseOver = UnitExists("mouseover")
	if (hasMouseOver) then
		if (MOUSEOVER) then
			if (UnitIsUnit(MOUSEOVER.unit, "mouseover")) then
				return
			end
			ns.NamePlate.OnLeave(MOUSEOVER)
			MOUSEOVER = nil
		end
		local isMouseOver
		for frame in next,ns.ActiveNamePlates do
			isMouseOver = UnitIsUnit(frame.unit, "mouseover")
			if (isMouseOver) then
				MOUSEOVER = frame
				return ns.NamePlate.OnEnter(frame)
			end
		end
	elseif (MOUSEOVER) then
		ns.NamePlate.OnLeave(MOUSEOVER)
		MOUSEOVER = nil
	end
end

NamePlates.CheckForConflicts = function(self)
	for i,addon in next,{ Kui_Nameplates, NamePlateKAI, NeatPlates, Plater, SimplePlates, TidyPlates, TidyPlates_ThreatPlates, TidyPlatesContinued } do
		if (ns.API.IsAddOnEnabled(addon)) then
			return true
		end
	end
end

NamePlates.OnInitialize = function(self)
	if (self:CheckForConflicts()) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("NamePlates", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	oUF:RegisterStyle(ns.Prefix.."NamePlates", style)
end

NamePlates.OnEnable = function(self)
	oUF:SetActiveStyle(ns.Prefix.."NamePlates")
	oUF:SpawnNamePlates(ns.Prefix, callback--[[, cvars]])

	self.mouseTimer = self:ScheduleRepeatingTimer(checkMouseOver, 1/20)
end

LoadAddOn("Blizzard_NamePlates")
