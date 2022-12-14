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
local UnitFrames = ns:NewModule("UnitFrames", "LibMoreEvents-1.0", "AceHook-3.0")
local oUF = ns.oUF

-- Globally available registries
ns.UnitStyles = {}
ns.UnitFrames = {}
ns.UnitFramesByName = {}

-- Lua API
local string_match = string.match

-- WoW API
local UnitFrame_OnEnter = UnitFrame_OnEnter
local UnitFrame_OnLeave = UnitFrame_OnLeave

-- Addon API
local IsAddOnEnabled = ns.API.IsAddOnEnabled

local defaults = {
	profile = {
		units = {
			["**"] = {
				enabled = true
			},
			player = {},
			pet = {},
			focus = {},
			target = {},
			tot = {},
			boss = {},
			party = {},
			raid = {},
			arena = {}
		}
	}
}

-- Utility
-----------------------------------------------------
local Spawn = function(unit, name)
	local fullName = ns.Prefix.."UnitFrame"..name
	local frame = oUF:Spawn(unit, fullName)

	ns.UnitFramesByName[name] = frame
	ns.UnitFrames[#ns.UnitFrames + 1] = frame

	ns:Fire("UnitFrame_Created", unit, fullName)

	return frame
end

-- Styling
-----------------------------------------------------
local UnitSpecific = function(self, unit)
	local id, style
	if (unit == "player") then
		style = self:GetName():find("HUD") and "PlayerHUD" or "Player"

		if (self:GetName():find("Boss")) then
			style = "Boss"
		end

	elseif (unit == "target") then
		style = "Target"

	elseif (unit == "targettarget") then
		style = "ToT"

	elseif (unit == "pet") then
		style = "Pet"

	elseif (unit == "focus") then
		style = "Focus"

	elseif (unit == "focustarget") then
		style = "FocusTarget"

	elseif (string_match(unit, "party%d?$")) then
		id = string_match(unit, "party(%d)")
		style = "Party"

	elseif (string_match(unit, "raid%d+$")) then
		id = string_match(unit, "raid(%d+)")
		style = "Raid"

	elseif (string_match(unit, "boss%d?$")) then
		id = string_match(unit, "boss(%d)")
		style = "Boss"

	elseif (string_match(unit, "arena%d?$")) then
		id = string_match(unit, "arena(%d)")
		style = "Arena"

	end

	if (style and ns.UnitStyles[style]) then
		return ns.UnitStyles[style](self, unit, id)
	end
end

-- UnitFrame Callbacks
-----------------------------------------------------
local OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
	if (self.isUnitFrame) then
		return _G.UnitFrame_OnEnter(self, ...)
	end
end

local OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
	if (self.isUnitFrame) then
		return _G.UnitFrame_OnLeave(self, ...)
	end
end

local OnHide = function(self, ...)
	self.isMouseOver = nil
	if (self.OnHide) then
		self:OnHide(...)
	end
end

UnitFrames.RegisterStyles = function(self)

	oUF:RegisterStyle(ns.Prefix, function(self, unit)

		self.isUnitFrame = true
		self.colors = ns.Colors

		self:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		self:SetScript("OnEnter", OnEnter)
		self:SetScript("OnLeave", OnLeave)
		self:SetScript("OnHide", OnHide)

		return UnitSpecific(self, unit)
	end)

end

UnitFrames.RegisterMetaFunctions = function(self)
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

UnitFrames.SpawnUnitFrames = function(self)
	oUF:Factory(function(oUF)
		oUF:SetActiveStyle(ns.Prefix)

	end)
end

---UnitFrames.SpawnGroupFrames = function(self)
---	oUF:Factory(function(oUF)
---		oUF:SetActiveStyle(ns.Prefix)
---
---	end)
---end

UnitFrames.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("UnitFrames", defaults)
end

UnitFrames.OnEnable = function(self)
	self:RegisterMetaFunctions()
	self:RegisterStyles()
	self:SpawnUnitFrames()
	--self:SpawnGroupFrames()
end

LoadAddOn("Blizzard_CUFProfiles")
LoadAddOn("Blizzard_CompactRaidFrames")
