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

ns.SETTINGS_VERSION = 13

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
local ipairs = ipairs
local math_max = math.max
local math_min = math.min
local next = next
local string_lower = string.lower
local tonumber = tonumber

-- Addon API
local SetRelativeScale = ns.API.SetRelativeScale
local UpdateObjectScales = ns.API.UpdateObjectScales

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

-- Hard table merging without metatables.
ns.Merge = function(self, target, source)
	if (type(target) ~= "table") then target = {} end
	for k,v in pairs(source) do
		if (type(v) == "table") then
			target[k] = self:Merge(target[k], v)
		elseif (target[k] == nil) then
			target[k] = v
		end
	end
	return target
end

ns.ResetBlizzardScale = function(self)
	if (InCombatLockdown()) then return end
	SetCVar("useUIScale", 1)
	SetCVar("uiScale", ns.API.GetDefaultBlizzardScale())
	ReloadUI() -- need a reset as the above can taint
end

ns.UpdateSettings = function(self, event, ...)
	-- Fire callbacks to submodules.
	self.callbacks:Fire("Saved_Settings_Updated")
end

ns.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		--print("Type |cff4488ff/resetscale|r to set the ui scale to AzeriteUI default.")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") -- once is enough.
	end
end

ns.OnInitialize = function(self)

	self.db = LibStub("AceDB-3.0"):New("AzeriteUI5_DB", defaults, true)

	-- Force a settings reset on backwards incompatible changes.
	if (self.db.global.version ~= ns.SETTINGS_VERSION) then
		--local profiles, count = self.db:GetProfiles()
		--local current = self.db:GetCurrentProfile()
		self.db:ResetDB() -- Full db reset of all profiles. Destructive operation.
		self.db.global.version = ns.SETTINGS_VERSION -- Store version in default profile.
	end

	self.db:SetProfile("Azerite")
	self.db.profile.layoutversion = nil


	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	self:RegisterChatCommand("resetscale", "ResetBlizzardScale")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

end
