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
ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "LibMoreEvents-1.0", "AceConsole-3.0")
ns.L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end

ns.SETTINGS_VERSION = 18

_G[Addon] = ns

local defaults = {
	global = {},
	profile = {
		relativeScale = 1
	}
}

local moduleDefaults = {
	enabled = true
}
ns.moduleDefaults = moduleDefaults

-- Lua API
local next = next
local string_lower = string.lower

-- Addon API
local IsAddOnAvailable = ns.API.IsAddOnAvailable

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

ns.SwitchUI = function(self, input)
	if (not self.IsDevelopment) then return end
	if (not self._ui_list) then
		-- Create a list of currently installed UIs.
		self._ui_list = {}
		for ui,cmds in next,{
			["AzeriteUI"] = { "azerite", "azui" },
			["DiabolicUI"] = { "diabolic", "diablo", "dui" }
		} do
			-- Only include existing UIs that can be switched to.
			if (ui ~= Addon) and (IsAddOnAvailable(ui)) then
				for _,cmd in next,cmds do
					self._ui_list[cmd] = ui
				end
			end
		end
	end
	local arg = self:GetArgs(string_lower(input))
	local target = arg and self._ui_list[arg]
	if (target) then
		EnableAddOn(target) -- Enable the desired UI
		for cmd,ui in next,self._ui_list do
			if (ui and ui ~= target) then -- Don't disable target UI
				DisableAddOn(ui) -- Disable all other UIs
			end
		end
		DisableAddOn(Addon) -- Disable the current UI
		ReloadUI() -- Reload interface to the selected UI
	end
end

ns.UpdateSettings = function(self, event, ...)
	-- Fire callbacks to submodules.
	self.callbacks:Fire("Saved_Settings_Updated")
end

ns.ResetSettings = function(self, noreload)
	--local profiles, count = self.db:GetProfiles()
	--local current = self.db:GetCurrentProfile()
	self.db:ResetDB() -- Full db reset of all profiles. Destructive operation.
	self.db.global.version = ns.SETTINGS_VERSION -- Store version in default profile.

	-- We haven't connected the wires to all the modules yet,
	-- so at this point a forced reload is the only way.
	if (not noreload) then
		ReloadUI()
	end
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0"):New("AzeriteUI5_DB", defaults, true)

	-- Force a settings reset on backwards incompatible changes.
	if (self.db.global.version ~= ns.SETTINGS_VERSION) then
		self:ResetSettings(true) -- no reload needed yet
	end

	-- Setup the profile and register the callbacks.
	self.db:SetProfile("Azerite")
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	-- Create a command to force a full settings reset manually.
	self:RegisterChatCommand("resetsettings", function() self:ResetSettings() end)

	-- At this point only I need this one.
	if (ns.IsDevelopment) then
		self:RegisterChatCommand("goto", "SwitchUI")
	end
end
