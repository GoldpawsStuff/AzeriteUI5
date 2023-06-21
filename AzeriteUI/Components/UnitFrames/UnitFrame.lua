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
local oUF = ns.oUF

local UnitFrameMod = ns:NewModule("UnitFrames", "LibMoreEvents-1.0")

local LibSmoothBar = LibStub("LibSmoothBar-1.0")
local LibSpinBar = LibStub("LibSpinBar-1.0")
local LibOrb = LibStub("LibOrb-1.0")

-- Lua API
local next = next


-- GLOBALS: UIParent
-- GLOBALS: InCombatLockdown, UnitFrame_OnEnter, UnitFrame_OnLeave

local defaults = { profile = ns:Merge({
	enabled = true,
	disableAuraSorting = false
}, ns.Module.defaults) }

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

-- UnitFrame Prototype
---------------------------------------------------
oUF:RegisterMetaFunction("CreateBar", UnitFrame_CreateBar)
oUF:RegisterMetaFunction("CreateRing", UnitFrame_CreateRing)
oUF:RegisterMetaFunction("CreateOrb", UnitFrame_CreateOrb)

-- UnitFrame Module Defauts
local unitFrameDefaults = {
	enabled = true,
	scale = 1
}

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

ns.UnitFrameModule = ns:Merge({
	OnEnabledEvent = function(self, event, ...)
		if (event == "PLAYER_REGEN_ENABLED") then
			if (InCombatLockdown()) then return end
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnConfigEvent")
			self:UpdateEnabled()
		end
	end,

	UpdateEnabled = function(self)
		local config = self.db.profile
		if (config.enabled and not self.frame:IsEnabled()) or (not config.enabled and self.frame:IsEnabled()) then

			if (InCombatLockdown()) then
				return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEnabledEvent")
			end

			if (config.enabled) then
				self.frame:Enable()
			else
				self.frame:Disable()
			end
		end
	end,

	UpdateSettings = function(self)
		self:UpdateEnabled()

		if (self.db.profile.enabled) then
			self:Update()
			self:UpdatePositionAndScale()
			self:UpdateAnchor()
		end
	end,

	Update = function(self)
		-- Placeholder. Update unitframe settings here.
	end,

	CreateAnchor = function(self, label, watchVariables, colorGroup)
		return ns.Module.CreateAnchor(self, label, watchVariables, colorGroup or "unitframes")
	end

}, ns.Module)

UnitFrameMod.UpdateSettings = function(self)

	if (self.db.profile.disableAuraSorting) then

		-- Iterate through unitframes.
		if (ns.UnitFrames) then
			for frame in next,ns.UnitFrames do
				local auras = frame.Auras
				if (auras) then
					auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
					auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
					auras:ForceUpdate()
				end
			end
		end

		-- Iterate through nameplates.
		if (ns.NamePlates) then
			for frame in next,ns.NamePlates do
				local auras = frame.Auras
				if (auras) then
					auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
					auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
					auras:ForceUpdate()
				end
			end
		end
	else

		-- Iterate through unitframes.
		if (ns.UnitFrames) then
			for frame in next,ns.UnitFrames do
				local auras = frame.Auras
				if (auras) then
					auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
					auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
					auras:ForceUpdate()
				end
			end
		end

		-- Iterate through nameplates.
		if (ns.NamePlates) then
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

end

UnitFrameMod.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSettings")
end

UnitFrameMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("UnitFrames", defaults)
end
