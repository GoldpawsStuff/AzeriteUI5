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
local oUF = ns.oUF

local UnitFrameMod = ns:NewModule("UnitFrames", "LibMoreEvents-1.0")

local MFM = ns:GetModule("MovableFramesManager")
local GUI = ns:GetModule("Options")

local LibSmoothBar = LibStub("LibSmoothBar-1.0")
local LibSpinBar = LibStub("LibSpinBar-1.0")
local LibOrb = LibStub("LibOrb-1.0")

-- Lua API
local next = next

-- Private API
local Colors = ns.Colors

local defaults = { profile = ns:Merge({
	enabled = true,
	disableAuraSorting = false
}, ns.moduleDefaults) }

-- UnitFrame Callbacks
---------------------------------------------------
local UnitFrame_CreateBar = function(self, name, parent, ...)
	return LibSmoothBar:CreateSmoothBar(name, parent or self, ...)
end

local UnitFrame_CreateRing = function(self, name, parent, ...)
	return LibSpinBar:CreateSpinBar(name, parent or self, ...)
end

local UnitFrame_CreateOrb = function(self, name, parent, ...)
	return LibOrb:CreateOrb(name, parent or self, ...)
end

local UnitFrame_OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
	return _G.UnitFrame_OnEnter(self, ...)
end

local UnitFrame_OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
	return _G.UnitFrame_OnLeave(self, ...)
end

local UnitFrame_OnHide = function(self, ...)
	self.isMouseOver = nil
	if (self.OnHide) then
		self:OnHide(...)
	end
end

-- UnitFrame Module Defauts
local unitFrameDefaults = {
	enabled = true,
	scale = 1
}

-- UnitFrame Prototype
---------------------------------------------------
oUF:RegisterMetaFunction("CreateBar", UnitFrame_CreateBar)
oUF:RegisterMetaFunction("CreateRing", UnitFrame_CreateRing)
oUF:RegisterMetaFunction("CreateOrb", UnitFrame_CreateOrb)

ns.UnitFrames = {}
ns.UnitFrame = {}
ns.UnitFrame.defaults = unitFrameDefaults

ns.UnitFrame.InitializeUnitFrame = function(self)

	self.isUnitFrame = true
	self.colors = ns.Colors

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:SetScript("OnHide", UnitFrame_OnHide)

end

ns.UnitFrame.Spawn = function(unit, overrideName, ...)

	local frame = oUF:Spawn(unit, overrideName)

	ns.UnitFrame.InitializeUnitFrame(frame)
	ns.UnitFrames[frame] = true

	return frame
end

-- UnitFrame Module Prototype
---------------------------------------------------
ns.UnitFrame.modulePrototype = {
	OnEnable = function(self)
		if (self.UpdateDefaults) then
			self:UpdateDefaults()
		end

		local frame = self.frame
		if (frame and frame.Enable) then
			frame:Enable()
		else
			if (self.Spawn) then
				self:Spawn()

				if (self.anchor) then
					local r, g, b = unpack(Colors.anchor.unitframes)
					self.anchor.Overlay:SetBackdropColor(r, g, b, .75)
					self.anchor.Overlay:SetBackdropBorderColor(r, g, b, 1)
				end
			end
		end

		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

		ns.RegisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
		ns.RegisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
		ns.RegisterCallback(self, "MFM_PositionUpdated", "OnEvent")
		ns.RegisterCallback(self, "MFM_AnchorShown", "OnEvent")
		ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
		ns.RegisterCallback(self, "MFM_Dragging", "OnEvent")
	end,

	OnDisable = function(self)
		local frame = self.frame
		if (frame and frame.Disable) then
			frame:Disable()
		end

		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

		ns.UnregisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
		ns.UnregisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
		ns.UnregisterCallback(self, "MFM_PositionUpdated", "OnEvent")
		ns.UnregisterCallback(self, "MFM_AnchorShown", "OnEvent")
		ns.UnregisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
		ns.UnregisterCallback(self, "MFM_Dragging", "OnEvent")
	end,

	OnEvent = function(self, event, ...)
		if (event == "PLAYER_ENTERING_WORLD") then
			self.incombat = nil
			self:UpdatePositionAndScale()

		elseif (event == "PLAYER_REGEN_ENABLED") then
			if (InCombatLockdown()) then return end
			self.incombat = nil
			if (self.needupdate) then
				self:UpdatePositionAndScale()
			end

		elseif (event == "PLAYER_REGEN_DISABLED") then
			self.incombat = true

		elseif (event == "MFM_LayoutsUpdated") then
			local LAYOUT = ...

			if (not self.db.profile.savedPosition[LAYOUT]) then
				self.db.profile.savedPosition[LAYOUT] = ns:Merge({}, unitFrameDefaults.profile.savedPosition[MFM:GetDefaultLayout()])
			end

			self:UpdatePositionAndScale()
			self:UpdateAnchor()

			GUI:Refresh("unitframes")

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

			GUI:Refresh("unitframes")

		elseif (event == "MFM_AnchorShown") then
			local LAYOUT, anchor, point, x, y = ...

			if (anchor ~= self.anchor) then return end

		elseif (event == "MFM_ScaleUpdated") then
			local LAYOUT, anchor, scale = ...

			if (anchor ~= self.anchor) then return end

			self.db.profile.savedPosition[LAYOUT].scale = scale
			self:UpdatePositionAndScale()

			GUI:Refresh("unitframes")

		elseif (event == "MFM_Dragging") then
			if (not self.incombat) then
				if (select(2, ...) ~= self.anchor) then return end

				self:OnEvent("MFM_PositionUpdated", ...)
			end
		end
	end,

	UpdatePositionAndScale = function(self)
		if (InCombatLockdown()) then
			self.needupdate = true
			return
		end
		if (not self.frame) then return end

		local config = self.db.profile.savedPosition[MFM:GetLayout()]

		self.frame:SetScale(config.scale)
		self.frame:ClearAllPoints()
		self.frame:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
	end,

	UpdateAnchor = function(self)
		if (not self.anchor) then return end

		local config = self.db.profile.savedPosition[MFM:GetLayout()]

		self.anchor:SetSize(self.frame:GetSize())
		self.anchor:SetScale(config.scale)
		self.anchor:ClearAllPoints()
		self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
	end,

	UpdateDefaults = function(self)
		if (not self.anchor or not self.db) then return end

		local defaults = self.db.defaults.profile.savedPosition[MFM:GetDefaultLayout()]
		if (not defaults) then return end

		defaults.scale = self.anchor:GetDefaultScale()
		defaults[1], defaults[2], defaults[3] = self.anchor:GetDefaultPosition()
	end,

	UpdateSettings = function(self)
		self:UpdatePositionAndScale()
	end

}

UnitFrameMod.UpdateSettings = function(self)

	if (self.db.profile.disableAuraSorting) then

		-- Iterate through unitframes.
		for frame in next,ns.UnitFrames do
			local auras = frame.Auras
			if (auras) then
				auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
				auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
				auras:ForceUpdate()
			end
		end

		-- Iterate through nameplates.
		for frame in next,ns.NamePlates do
			local auras = frame.Auras
			if (auras) then
				auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
				auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
				auras:ForceUpdate()
			end
		end
	else

		-- Iterate through unitframes.
		for frame in next,ns.UnitFrames do
			local auras = frame.Auras
			if (auras) then
				auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
				auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
				auras:ForceUpdate()
			end
		end

		-- Iterate through nameplates.
		for frame in next,ns.NamePlates do
			local auras = frame.Auras
			if (auras) then
				auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
				auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
				auras:ForceUpdate()
			end
		end

	end

end

UnitFrameMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("UnitFrames", defaults)

	self:SetEnabledState(self.db.profile.enabled)
end

UnitFrameMod.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSettings")
end
