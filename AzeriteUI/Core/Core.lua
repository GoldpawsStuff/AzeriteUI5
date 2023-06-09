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

ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "LibMoreEvents-1.0", "AceConsole-3.0")
ns.L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end
ns.SETTINGS_VERSION = 22

_G[Addon] = ns

-- Lua API
local next = next
local string_lower = string.lower
local type = type
local unpack = unpack

local defaults = {
	char = {
		profile = "Azerite"
	},
	global = {
		version = ns.SETTINGS_VERSION
	},
	profile = {}
}

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
	local profiles, count = self.db:GetProfiles()
	return profiles
end

ns.GetDefaultProfile = function(self)
	return "Azerite"
end

ns.RefreshConfig = function(self, event, ...)
	if (event == "OnNewProfile") then
		local db, profileKey = ...

	elseif (event == "OnProfileChanged") then
		local db, newProfileKey = ...

		db.char.profile = newProfileKey

	elseif (event == "OnProfileCopied") then
		local db, sourceProfileKey = ...

	elseif (event == "OnProfileReset") then
		local db = ...

	end
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0-GE"):New("AzeriteUI5_DB", defaults, self:GetDefaultProfile())

	if (self.db.global.version ~= ns.SETTINGS_VERSION) then
		self.db:ResetDB(self:GetDefaultProfile())
		self.db.global.version = ns.SETTINGS_VERSION
	end

	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterChatCommand("resetsettings", function() self:ResetSettings() end)
end

ns.OnEnable = function(self)
	self.db:SetProfile(self.db.char.profile)
end
