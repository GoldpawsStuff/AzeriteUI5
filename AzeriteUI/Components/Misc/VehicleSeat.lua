--[[

	The MIT License (MIT)

	Copyright (c) 2023 Lars Norberg

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

if (not ns.IsRetail and not ns.IsWrath) then return end

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local VehicleSeat = ns:NewModule("VehicleSeat", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local pairs, unpack = pairs, unpack

-- Frame Metamethods
local clearAllPoints = getmetatable(CreateFrame("Frame")).__index.ClearAllPoints
local setPoint = getmetatable(CreateFrame("Frame")).__index.SetPoint

-- Utility
local clearSetPoint = function(frame, ...)
	clearAllPoints(frame)
	setPoint(frame, ...)
end

local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

VehicleSeat.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOMRIGHT",
		[2] = -544 * ns.API.GetEffectiveScale(),
		[3] = 146 * ns.API.GetEffectiveScale()
	}
	return defaults
end

VehicleSeat.PrepareFrames = function(self)

	self.frame = VehicleSeatIndicator

	self.frame:ClearAllPoints()
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("BACKGROUND")

	-- This will prevent UIParent_ManageFramePositions() from being executed
	-- *for some reason it's not working? Why not?
	self.frame.IsShown = function() return false end

	self:SecureHook(self.frame, "SetPoint", "UpdatePositionAndScale")
end

VehicleSeat.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition
	local point, x, y = unpack(config)

	self.anchor:SetSize(128, 128)
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(point, UIParent, point, x, y)
end

VehicleSeat.OnEnable = function(self)

	if (ns.WoW10) then
		VehicleSeatIndicator.HighlightSystem = ns.Noop
		VehicleSeatIndicator.ClearHighlight = ns.Noop
	end

	self:PrepareFrames()
	self:CreateAnchor(L["Vehicle Seat"])

	ns.Module.OnEnable(self)
end
