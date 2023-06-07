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

-- Frame Metamethods
local mt = getmetatable(CreateFrame("Frame"))
local clearAllPoints = mt.__index.ClearAllPoints
local setPoint = mt.__index.SetPoint

-- Utility
local clearSetPoint = function(frame, ...)
	clearAllPoints(frame)
	setPoint(frame, ...)
end

local Module = { defaults = { enabled = true } }

ns.Module = Module

Module.GetDefaults = function(self)
	if (self.GenerateDefaults) then
		return self:GenerateDefaults(self.defaults)
	end
	return self.defaults
end

Module.SetDefaults = function(self, defaults)
	self.db:RegisterDefaults(defaults)
end

Module.CreateAnchor = function(self, label, watchVariables)
	if (self.anchor) then return self.anchor end

	local anchor = ns:GetModule("MovableFramesManager"):RequestAnchor()
	anchor:SetScalable(true)
	anchor:SetSize(2,2)

	local defaults = self:GetDefaults()
	if (defaults.profile.savedPosition) then
		anchor:SetPoint(unpack(defaults.profile.savedPosition))
		anchor:SetScale(defaults.profile.savedPosition.scale)
		anchor:SetDefaultScale(function() return ns.API.GetEffectiveScale() end)
		anchor:SetTitle(label)
	end

	anchor.PreUpdate = function()
		if (self.UpdateAnchor) then
			self:UpdateAnchor()
		end
	end

	anchor.UpdateDefaults = function()
		if (self.UpdateDefaults) then
			self:UpdateDefaults()
		end
	end

	self.anchor = anchor

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnAnchorEvent")

	if (self.watchVariables) then
		self:RegisterEvent("VARIABLES_LOADED", "OnAnchorEvent")
	end

	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnAnchorEvent")

	return self.anchor
end

Module.UpdateAnchor = function(self)
	if (not self.anchor) then return end

	if (self.PreUpdateAnchor) then
		if (self:PreUpdateAnchor()) then return end
	end

	local config = self.db.profile.savedPosition
	if (config) then
		local point, x, y = unpack(config)

		self.anchor:SetSize(self.frame:GetSize())
		self.anchor:SetScale(config.scale)
		self.anchor:ClearAllPoints()
		self.anchor:SetPoint(point, UIParent, point, x, y)
	end

	if (self.PostUpdateAnchor) then
		self:PostUpdateAnchor()
	end
end

Module.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	if (InCombatLockdown()) then
		self.updateneeded = true
		return
	end

	if (self.PreUpdatePositionAndScale) then
		if (self:PreUpdatePositionAndScale()) then return end
	end

	self.updateneeded = nil

	local config = self.db.profile.savedPosition
	if (config) then
		local point, x, y = unpack(config)

		self.frame:SetScale(config.scale)

		clearSetPoint(self.frame, point, UIParent, point, x/config.scale, y/config.scale)
	end

	if (self.PostUpdatePositionAndScale) then
		self:PostUpdatePositionAndScale()
	end
end

Module.OnAnchorEvent = function(self, event, ...)
	if (self.PreAnchorEvent) then
		self:PreAnchorEvent(event, ...)
	end

	if (event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED") then
		self.incombat = nil

		self:UpdatePositionAndScale()
		self:UpdateAnchor()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end

		self.incombat = nil

		if (self.updateneeded) then
			self:UpdatePositionAndScale()
			self:UpdateAnchor()
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_PositionUpdated") then
		local anchor, point, x, y = ...
		if (anchor ~= self.anchor) then return end

		if (self.db.profile.savedPosition) then
			self.db.profile.savedPosition[1] = point
			self.db.profile.savedPosition[2] = x
			self.db.profile.savedPosition[3] = y

			self:UpdatePositionAndScale()
		end

	elseif (event == "MFM_ScaleUpdated") then
		local anchor, scale = ...
		if (anchor ~= self.anchor) then return end

		if (self.db.profile.savedPosition) then
			self.db.profile.savedPosition.scale = scale
			self:UpdatePositionAndScale()
		end

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			if (... ~= self.anchor) then return end
			self:OnAnchorEvent("MFM_PositionUpdated", ...)
		end
	end

	if (self.PostAnchorEvent) then
		return self:PostAnchorEvent(event, ...)
	end
end

Module.OnRefreshConfig = function(self)
	self:UpdatePositionAndScale()
	self:UpdateAnchor()

	if (self.RefreshConfig) then
		self:RefreshConfig()
	end
end

Module.OnEnable = function(self)
	if (self.PreEnable) then
		self:PreEnable()
	end

	self:OnRefreshConfig()

	if (self.PostEnable) then
		self:PostEnable()
	end
end

Module.OnInitialize = function(self)
	if (self.PreInitialize) then
		self:PreInitialize()
	end

	self.db = ns.db:RegisterNamespace(self:GetName(), self:GetDefaults())
	self:SetEnabledState(self.db.profile.enabled)

	if (not self.db.profile.enabled) then return end

	self.db.RegisterCallback(self, "OnProfileChanged", "OnRefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnRefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "OnRefreshConfig")

	if (self.PostInitialize) then
		self:PostInitialize()
	end
end
