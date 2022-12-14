--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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
ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "AceConsole-3.0")
ns.L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end

_G[Addon] = ns

-- Version flag to force full setting resets.
local SETTINGS_VERSION = 1

-- Default settings
local defaults = {
	profile = {
	}
}

-- Lua API
local ipairs = ipairs
local math_max = math.max
local math_min = math.min
local next = next
local string_lower = string.lower
local tonumber = tonumber

-- WoW API
local InCombatLockdown = InCombatLockdown

-- Addon API
local SetRelativeScale = ns.API.SetRelativeScale
local UpdateObjectScales = ns.API.UpdateObjectScales
local ShowMovableFrameAnchors = ns.Widgets.ShowMovableFrameAnchors
local HideMovableFrameAnchors = ns.Widgets.HideMovableFrameAnchors
local ToggleMovableFrameAnchors = ns.Widgets.ToggleMovableFrameAnchors

-- Keep custom scales within limits.
local LimitScale = function(scale)
	return math_min(1.5, math_max(.5, scale))
end

-- Purge deprecated settings,
-- translate to new where applicable,
-- make sure important ones are within bounds.
local SanitizeSettings = function(db)
	if (not db) then
		return
	end
	local scale = db.global.core.relativeScale
	if (scale) then
		db.global.core.relativeScale = LimitScale(scale)
	end
	return db
end

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

ns.LockMovableFrames = function(self)
	HideMovableFrameAnchors()
end

ns.UnlockMovableFrames = function(self)
	ShowMovableFrameAnchors()
end

ns.ToggleMovableFrames = function(self)
	ToggleMovableFrameAnchors()
end

ns.ResetScale = function(self)
	if (InCombatLockdown()) then
		return
	end
	local db = self.db
	local scale = db.global.core.relativeScale
	local defaultScale = defaults.global.core.relativeScale
	if (scale and scale ~= defaultScale) then
		db.global.core.relativeScale = defaultScale -- Store the saved setting
		SetRelativeScale(defaultScale) -- Store it in the addon namespace
		UpdateObjectScales() -- Apply it to existing objects
		-- Fire callbacks to submodules.
		ns.callbacks:Fire("Relative_Scale_Updated", db.global.core.relativeScale)
	end
end

ns.SetScale = function(self, input)
	if (InCombatLockdown()) then
		return
	end
	local scale = tonumber((self:GetArgs(string_lower(input))))
	if (scale) then
		local db = self.db
		local oldScale = db.global.core.relativeScale
		-- Sanitize it, don't want crazy values
		scale = LimitScale(scale)
		if (oldScale ~= scale) then
			-- Store and apply new relative user scale
			db.global.core.relativeScale = scale -- Store the saved setting
			SetRelativeScale(scale) -- Store it in the addon namespace
			UpdateObjectScales() -- Apply it to existing objects
			-- Fire callbacks to submodules.
			ns.callbacks:Fire("Relative_Scale_Updated", db.global.core.relativeScale)
		end
	end
end

ns.UpdateSettings = function(self, event, ...)
	-- Fire callbacks to submodules.
	self.callbacks:Fire("Saved_Settings_Updated")
end

ns.OnInitialize = function(self)

	self.db = SanitizeSettings(LibStub("AceDB-3.0"):New("AzeriteUI5_DB", defaults, true))

	-- Forcereset settings on version changes.
	local settings_version = self.db.global.version
	if (settings_version ~= SETTINGS_VERSION) then
		self.db:ResetDB()

		self.db.global.version = SETTINGS_VERSION
	end

	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	-- Apply user scale to all elements
	--if (self.db.global.core.relativeScale) then
	--	self.API.SetRelativeScale(self.db.global.core.relativeScale)
	--end

	--self:RegisterChatCommand("setscale", "SetScale")
	--self:RegisterChatCommand("resetscale", "ResetScale")
	self:RegisterChatCommand("lock", "LockMovableFrames")
	self:RegisterChatCommand("unlock", "UnlockMovableFrames")
	self:RegisterChatCommand("togglelock", "ToggleMovableFrames")

	if (EditModeManagerFrame) then
		hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() self:UnlockMovableFrames() end)
		hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() self:LockMovableFrames() end)
	end

end
