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
if (not UIWidgetTopCenterContainerFrame) then return end

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local UIWidgetTopCenter = ns:NewModule("UIWidgetTopCenter", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: CreateFrame, UnitExists, UIParent, UIWidgetTopCenterContainerFrame

local defaults = { profile = ns:Merge({
	hideWithTarget =  true
}, ns.Module.defaults) }

UIWidgetTopCenter.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = 14/12 * ns.API.GetEffectiveScale(),
		[1] = "TOP",
		[2] = 0,
		[3] = -10 * ns.API.GetEffectiveScale()
	}
	return defaults
end

UIWidgetTopCenter.UpdateContentPosition = function(self)
	local _,anchor = self.frame.contents:GetPoint()
	if (anchor ~= self.frame) then
		self:Unhook(self.frame.contents, "SetPoint")
		self.frame.contents:SetParent(self.frame)
		self.frame.contents:ClearAllPoints()
		self.frame.contents:SetPoint("TOP", self.frame)
		self:SecureHook(self.frame.contents, "SetPoint", "UpdateContentPosition")
	end
end

UIWidgetTopCenter.PrepareFrames = function(self)

	local frame = CreateFrame("Frame", ns.Prefix.."TopCenterWidgets", UIParent)
	frame:SetFrameStrata("BACKGROUND")
	frame:SetFrameLevel(10)
	frame:SetSize(58,58)

	local contents = UIWidgetTopCenterContainerFrame
	contents:ClearAllPoints()
	contents:SetParent(UIParent)
	contents:SetFrameStrata("BACKGROUND")

	-- This will prevent UIParent_ManageFramePositions() from being executed
	-- *for some reason it's not working? Why not?
	contents.IsShown = function() return false end

	self.frame = frame
	self.frame.contents = contents

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:SecureHook(frame.contents, "SetPoint", "UpdateContentPosition")
end

UIWidgetTopCenter.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED") then
		if (self.db.profile.hideWithTarget and UnitExists("target")) then
			self.frame:Hide()
		else
			self.frame:Show()
		end
	end
end

UIWidgetTopCenter.OnEnable = function(self)

	self:PrepareFrames()
	self:CreateAnchor(L["Widgets: Top"])

	ns.Module.OnEnable(self)
end
