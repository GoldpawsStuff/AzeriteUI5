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

local ArcheologyBar = ns:NewModule("ArcheologyBar", "LibMoreEvents-1.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local pairs, unpack = pairs, unpack

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = {
			scale = ns.API.GetEffectiveScale(),
			[1] = "BOTTOM",
			[2] = 0 * ns.API.GetEffectiveScale(),
			[3] = 390 * ns.API.GetEffectiveScale()
		}
	}
}, ns.moduleDefaults) }

ArcheologyBar.InitializeArcheologyBar = function(self)
	self.frame = ArcheologyDigsiteProgressBar
end

ArcheologyBar.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(PROFESSIONS_ARCHAEOLOGY)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.25, 2.5, .05)
	anchor:SetSize(240, 24)
	anchor:SetPoint(unpack(defaults.profile.savedPosition[MFM:GetDefaultLayout()]))
	anchor:SetScale(defaults.profile.savedPosition[MFM:GetDefaultLayout()].scale)
	anchor:SetDefaultScale(ns.API.GetEffectiveScale)
	anchor.PreUpdate = function() self:UpdateAnchor() end
	anchor.UpdateDefaults = function() self:UpdateDefaults() end

	self.anchor = anchor
end

ArcheologyBar.UpdateDefaults = function(self)
	if (not self.anchor or not self.db) then return end

	local defaults = self.db.defaults.profile.savedPosition[MFM:GetDefaultLayout()]
	if (not defaults) then return end

	defaults.scale = self.anchor:GetDefaultScale()
	defaults[1], defaults[2], defaults[3] = self.anchor:GetDefaultPosition()
end

ArcheologyBar.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]

	self.frame:SetScale(config.scale)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
end

ArcheologyBar.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition[MFM:GetLayout()]
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

ArcheologyBar.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addon = ...

		if (addon ~= "Blizzard_ArchaeologyUI") then return end

		self:InitializeArcheologyBar()
		self:UpdatePositionAndScale()
		self:UnregisterEvent("ADDON_LOADED", "OnEvent")

	elseif (event == "PLAYER_ENTERING_WORLD") then
		self.incombat = nil
		self:UpdatePositionAndScale()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_LayoutsUpdated") then
		local LAYOUT = ...

		if (not self.db.profile.savedPosition[LAYOUT]) then
			self.db.profile.savedPosition[LAYOUT] = ns:Merge({}, defaults.profile.savedPosition[MFM:GetDefaultLayout()])
		end

		self:UpdatePositionAndScale()
		self:UpdateAnchor()

	elseif (event == "MFM_LayoutDeleted") then
		local LAYOUT = ...

		self.db.profile.savedPosition[LAYOUT] = nil

	elseif (event == "MFM_PositionUpdated") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT][1] = point
		self.db.profile.savedPosition[LAYOUT][2] = x
		self.db.profile.savedPosition[LAYOUT][3] = y

		self:UpdatePositionAndScale()

	elseif (event == "MFM_AnchorShown") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

	elseif (event == "MFM_ScaleUpdated") then
		local LAYOUT, anchor, scale = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT].scale = scale
		self:UpdatePositionAndScale()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			if (select(2, ...) ~= self.anchor) then return end

			self:OnEvent("MFM_PositionUpdated", ...)
		end
	end
end

ArcheologyBar.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ArcheologyBar", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	MFM:RegisterPresets(self.db.profile.savedPosition)

	self:InitializeArcheologyBar()
	self:InitializeMovableFrameAnchor()

	if (not self.frame) then
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end
end

ArcheologyBar.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

	ns.RegisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
	ns.RegisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnEvent")
end