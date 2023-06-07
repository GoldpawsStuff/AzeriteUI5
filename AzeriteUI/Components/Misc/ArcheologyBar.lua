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

if (ns.IsClassic) then return end

local ArcheologyBar = ns:NewModule("ArcheologyBar", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local pairs, unpack = pairs, unpack

local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

ArcheologyBar.GenerateDefaults = function(self)
	if (not ns.WoW10) then
		defaults.profile.savedPosition = {
			scale = ns.API.GetEffectiveScale(),
			[1] = "BOTTOM",
			[2] = 0,
			[3] = 390 * ns.API.GetEffectiveScale()
		}
	end
	return defaults
end

ArcheologyBar.PrepareFrames = function(self)
	self.frame = ArcheologyDigsiteProgressBar
end

ArcheologyBar.UpdateAnchor = function(self)
	if (not self.anchor) then return end

	local config = self.db.profile.savedPosition
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

ArcheologyBar.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then
		if (... ~= "Blizzard_ArchaeologyUI") then return end

		self:UnregisterEvent("ADDON_LOADED", "OnEvent")
		self:PrepareFrames()
		self:OnRefreshConfig()
	end
end

ArcheologyBar.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(PROFESSIONS_ARCHAEOLOGY)

	if (not self.frame) then
		return self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end

	ns.Module.OnEnable(self)
end
