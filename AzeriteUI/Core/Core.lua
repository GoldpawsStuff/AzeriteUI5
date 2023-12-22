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

-- GLOBALS: CreateFrame, EnableAddOn, DisableAddOn, ReloadUI

local Addon, ns = ...

local LibDeflate = LibStub("LibDeflate")
local LEMO = LibStub("LibEditModeOverride-1.0", true)

ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "LibMoreEvents-1.0", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end

-- Increasing this number forces a full settings reset.
ns.SETTINGS_VERSION = 22

-- Tinkerers rejoyce!
_G[Addon] = ns

-- Lua API
local next = next
local select = select

local defaults = {
	char = {
		profile = ns.Prefix,
		showStartupMessage = true
	},
	global = {
		version = -1
	},
	profile = {
		autoLoadEditModeLayout = true,
		editModeLayout = ns.Prefix
	}
}

ns.exportableSettings, ns.exportableLayouts = {}, {}

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

ns.ResetSettings = function(self, noreload)
	self.db:ResetDB(self:GetDefaultProfile())
	self.db.global.version = ns.SETTINGS_VERSION
	if (not noreload) then
		ReloadUI()
	end
end

ns.ProfileExists = function(self, targetProfileKey)
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == targetProfileKey) then
			return true
		end
	end
end

ns.DuplicateProfile = function(self, newProfileKey, sourceProfileKey)
	if (not sourceProfileKey) then
		sourceProfileKey = self.db:GetCurrentProfile()
	end
	if (self:ProfileExists(newProfileKey) or not self:ProfileExists(sourceProfileKey)) then
		return
	end
	self.db:SetProfile(newProfileKey)
	self.db:CopyProfile(sourceProfileKey)
end

ns.CopyProfile = function(self, sourceProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (sourceProfileKey == currentProfileKey) then
		return
	end
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == sourceProfileKey) then
			self.db:CopyProfile(sourceProfileKey)
			return
		end
	end
end

ns.DeleteProfile = function(self, targetProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (targetProfileKey == "Default") then
		return
	end
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == targetProfileKey) then
			if (profileKey == currentProfileKey) then
				self.db:SetProfile("Default")
			end
			self.db:DeleteProfile(targetProfileKey)
			return
		end
	end
end

ns.ResetProfile = function(self)
	self.db:ResetProfile()
end

ns.SetProfile = function(self, newProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (newProfileKey == currentProfileKey) then
		return
	end
	self.db:SetProfile(newProfileKey)
end

ns.GetProfile = function(self)
	return self.db:GetCurrentProfile()
end

ns.GetProfiles = function(self)
	local profiles = self.db:GetProfiles()
	return profiles
end

ns.GetDefaultProfile = function(self)
	return ns.Prefix
end

ns.Export = function(self, ...)

	-- Decide which modules to export.
	local numModules = select("#", ...)
	local moduleList

	if (numModules > 0) then
		moduleList = {}

		for i = 1, numModules do
			moduleList[(select(i, ...))] = true
		end
	end

	for moduleName in next,ns.exportableSettings do
		if (not moduleList or moduleList[moduleName]) then

			-- serialize, compress and encode
			local module = self:GetModule(moduleName, true)
			if (module) then
				local data
			end

			-- prefix and add to export table
		end
	end

	for moduleName in next,ns.exportableLayouts do
		if (not moduleList or moduleList[moduleName]) then

			-- serialize, compress and encode
			local module = self:GetModule(moduleName, true)
			if (module) then

			end

			-- prefix and add to export table
		end
	end

end

ns.ExportLayouts = function(self, ...)
	local modules = {}

end

ns.Import = function(self, encoded)

	local compressed = LibDeflate:DecodeForPrint(encoded)
	local serialized = LibDeflate:DecompressDeflate(compressed)
	local success, table = self:Deserialize(serialized)

	if (success) then


		local currentProfileKey = self.db:GetCurrentProfile()

	end

end

ns.RefreshConfig = function(self, event, ...)
	if (event == "OnNewProfile") then
		--local db, profileKey = ...

	elseif (event == "OnProfileChanged") then
		local db, newProfileKey = ...

		db.char.profile = newProfileKey

	elseif (event == "OnProfileCopied") then
		--local db, sourceProfileKey = ...

	elseif (event == "OnProfileReset") then
		--local db = ...

	end
end

ns.ApplyEditModeLayout = function(self)
	if (not LEMO:IsReady()) then
		return self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
	end
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	LEMO:LoadLayouts()

	if (LEMO:DoesLayoutExist(self.db.profile.editModeLayout)) then
		if (LEMO:GetActiveLayout() ~= self.db.profile.editModeLayout) then
			LEMO:SetActiveLayout(self.db.profile.editModeLayout)
			LEMO:ApplyChanges()
		end
	end
end

ns.OnEvent = function(self, event, ...)
	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
		self:ApplyEditModeLayout()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:ApplyEditModeLayout()
	end
end

ns.OnEnable = function(self)
	self.db:SetProfile(self.db.char.profile)

	if (ns.WoW10) then
		self:ApplyEditModeLayout()
	end
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0-GE"):New("AzeriteUI5_DB", defaults, self:GetDefaultProfile())

	if (self.db.global.version < ns.SETTINGS_VERSION) then
		self:ResetSettings(true)
	end

	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterChatCommand("resetsettings", function() self:ResetSettings() end)
end
