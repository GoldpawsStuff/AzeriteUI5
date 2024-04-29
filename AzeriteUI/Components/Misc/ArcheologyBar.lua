--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

if (ns.IsClassic or ns.IsWrath) then return end

local ArcheologyBar = ns:NewModule("ArcheologyBar", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0")

local defaults = { profile = ns:Merge({}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
ArcheologyBar.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOM",
		[2] = 0,
		[3] = 390 * ns.API.GetEffectiveScale()
	}
	return defaults
end

ArcheologyBar.PrepareFrames = function(self)
	LoadAddOn("Blizzard_ArchaeologyUI")

	self.frame = ArcheologyDigsiteProgressBar

	self.frame:SetScript("OnShow", function(self)
		self.timeSinceLeftDigsiteCheck = 0;
		self:SetScript("OnUpdate", ArcheologyDigsiteProgressBar_OnUpdate)
		self:UnregisterEvent("ARCHAEOLOGY_SURVEY_CAST")
		self:RegisterEvent("ARCHAEOLOGY_FIND_COMPLETE")
		self:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE")
	end)

	self.frame:SetScript("OnHide", function(self)
		self:SetScript("OnUpdate", nil)
		self:RegisterEvent("ARCHAEOLOGY_SURVEY_CAST")
		self:UnregisterEvent("ARCHAEOLOGY_FIND_COMPLETE")
		self:UnregisterEvent("ARTIFACT_DIGSITE_COMPLETE")
	end)

end

ArcheologyBar.UpdateAnchor = function(self)
	if (not self.anchor) then return end

	local config = self.db.profile.savedPosition
	self.anchor:SetSize(240 / config.scale, 24 / config.scale)
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

ArcheologyBar.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(PROFESSIONS_ARCHAEOLOGY)

	ns.MovableModulePrototype.OnEnable(self)
end
