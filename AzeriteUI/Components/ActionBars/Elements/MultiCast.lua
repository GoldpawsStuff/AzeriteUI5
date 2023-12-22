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
local _, ns = ...

-- This poorly coded blizz bar taints like no tomorrow,
-- so we'll just leave it fully to blizz for now.
do return end

if (not ns.IsWrath) or (not MultiCastActionBarFrame) or (ns.PlayerClass ~= "SHAMAN") then
	return
end

local MultiCast = ns:NewModule("MultiCast", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local unpack = unpack

-- GLOBALS: CreateFrame, MultiCastActionBarFrame

local defaults = { profile = ns:Merge({}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
MultiCast.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = 0,
		[3] = -200 * ns.API.GetEffectiveScale()
	}
	return defaults
end

MultiCast.PrepareFrames = function(self)

	local frame = CreateFrame("Frame", ns.Prefix.."MultiCastFrame", UIParent)
	frame:SetSize(230, 38)
	frame:SetPoint(unpack(defaults.profile.savedPosition))
	frame:SetScale(1.25)

	self.frame = frame

	MultiCastActionBarFrame:SetScript("OnShow", nil)
	MultiCastActionBarFrame:SetScript("OnHide", nil)
	MultiCastActionBarFrame:SetScript("OnUpdate", nil)
	MultiCastActionBarFrame:SetParent(self.frame)
	MultiCastActionBarFrame:ClearAllPoints()
	MultiCastActionBarFrame:SetPoint("CENTER", self.frame, "CENTER")

	self:SecureHook("ShowMultiCastActionBar", "UpdateMultiCastBar")
end

MultiCast.OnEnable = function(self)

	self:PrepareFrames()
	self:CreateAnchor(L["Totem Bar"])

	ns.MovableModulePrototype.OnEnable(self)

	self:UpdateMultiCastBar()
end
