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

local UnitFrames = ns:GetModule("UnitFrames", true)
if (not UnitFrames) then return end

local NamePlates = UnitFrames:NewModule("NamePlates", "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0")
local oUF = ns.oUF

local MOUSEOVER

ns.NamePlates = {}
ns.ActiveNamePlates = {}

-- WoW API
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit

-- Addon API
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- NamePlate Callbacks
-----------------------------------------------------
local OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
end

local OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
end

local OnHide = function(self, ...)
	self.isMouseOver = nil
	if (self.OnHide) then
		self:OnHide(...)
	end
end

-- NamePlates
-----------------------------------------------------
local Cvars = {
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

local CheckMouseOver = function()
	local hasMouseOver = UnitExists("mouseover")
	if (hasMouseOver) then
		if (MOUSEOVER) then
			if (UnitIsUnit(MOUSEOVER.unit, "mouseover")) then
				return
			end
			OnLeave(MOUSEOVER)
			MOUSEOVER = nil
		end
		local isMouseOver
		for frame in next,ns.ActiveNamePlates do
			isMouseOver = UnitIsUnit(frame.unit, "mouseover")
			if (isMouseOver) then
				MOUSEOVER = frame
				return OnEnter(frame)
			end
		end
	elseif (MOUSEOVER) then
		OnLeave(MOUSEOVER)
		MOUSEOVER = nil
	end
end

local Callback = function(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
	elseif (event == "NAME_PLATE_UNIT_ADDED") then
		self.isPRD = UnitIsUnit(unit, "player")
		ns.NamePlates[self] = true
		ns.ActiveNamePlates[self] = true
	elseif (event == "NAME_PLATE_UNIT_REMOVED") then
		self.isPRD = nil
		ns.ActiveNamePlates[self] = nil
	end
end

NamePlates.RegisterStyles = function(self)

	oUF:RegisterStyle(ns.Prefix.."NamePlates", function(self, unit)

		self.isNamePlate = true
		self.colors = ns.Colors

		self:SetPoint("CENTER",0,0)
		self:SetScript("OnHide", OnHide)

		return UnitSpecific(self, unit)
	end)

end

NamePlates.RegisterMetaFunctions = function(self)
	oUF:RegisterMetaFunction("CreateBar", function(self, name, parent, ...)
		return LibStub("LibSmoothBar-1.0"):CreateSmoothBar(name, parent or self, ...)
	end)
	oUF:RegisterMetaFunction("CreateRing", function(self, name, parent, ...)
		return LibStub("LibSpinBar-1.0"):CreateSpinBar(name, parent or self, ...)
	end)
	oUF:RegisterMetaFunction("CreateOrb", function(self, name, parent, ...)
		return LibStub("LibOrb-1.0"):CreateOrb(name, parent or self, ...)
	end)
end

NamePlates.SpawnNamePlates = function(self)

	oUF:Factory(function(oUF)

		oUF:SetActiveStyle(ns.Prefix.."NamePlates")
		oUF:SpawnNamePlates(ns.Prefix, Callback--[[, Cvars]])

		self:ScheduleRepeatingTimer(CheckMouseOver, 1/20)

	end)
end

NamePlates.OnInitialize = function(self)
	for i,addon in next,{ Kui_Nameplates, NamePlateKAI, NeatPlates, Plater, SimplePlates, TidyPlates, TidyPlates_ThreatPlates, TidyPlatesContinued } do
		if (IsAddOnEnabled(addon)) then
			return self:Disable()
		end
	end
end

NamePlates.OnEnable = function(self)
	self:RegisterMetaFunctions()
	self:RegisterStyles()
	self:SpawnNamePlates()
end

LoadAddOn("Blizzard_NamePlates")
