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

ns.SETTINGS_VERSION = -9999

_G[Addon] = ns

local defaults = {
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
local ShowMovableFrameAnchors = ns.Widgets.ShowMovableFrameAnchors
local HideMovableFrameAnchors = ns.Widgets.HideMovableFrameAnchors
local ToggleMovableFrameAnchors = ns.Widgets.ToggleMovableFrameAnchors

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

ns.LockMovableFrames = function(self)
	HideMovableFrameAnchors()
end

ns.UnlockMovableFrames = function(self)
	ShowMovableFrameAnchors()
end

ns.ToggleMovableFrames = function(self)
	ToggleMovableFrameAnchors()
end

ns.ResetBlizzardScale = function(self)
	if (InCombatLockdown()) then return end
	SetCVar("uiScale", ns.API.GetDefaultScale())
	ReloadUI()
end

ns.ResetScale = function(self)
	if (InCombatLockdown()) then return end

	local scale = self.db.profile.relativeScale
	local defaultScale = defaults.profile.relativeScale

	if (scale ~= defaultScale) then
		self.db.profile.relativeScale = defaultScale -- Store the saved setting

		SetRelativeScale(defaultScale) -- Store it in the addon namespace
		UpdateObjectScales() -- Apply it to existing objects

		-- Fire callbacks to submodules.
		ns.callbacks:Fire("Relative_Scale_Updated", self.db.profile.relativeScale)
	end
end

ns.SetScale = function(self, input)
	if (InCombatLockdown()) then return end

	local scale = tonumber((self:GetArgs(string_lower(input))))
	if (scale) then
		local oldScale = self.db.profile.relativeScale

		-- Sanitize it, don't want crazy values
		scale = math_min(1.5, math_max(.5, scale))
		if (oldScale ~= scale) then

			-- Store and apply new relative user scale
			self.db.profile.relativeScale = scale -- Store the saved setting
			SetRelativeScale(scale) -- Store it in the addon namespace
			UpdateObjectScales() -- Apply it to existing objects

			-- Fire callbacks to submodules.
			ns.callbacks:Fire("Relative_Scale_Updated", self.db.profile.relativeScale)
		end
	end
end

ns.UpdateSettings = function(self, event, ...)
	-- Fire callbacks to submodules.
	self.callbacks:Fire("Saved_Settings_Updated")
end

ns.OnInitialize = function(self)

	self.db = LibStub("AceDB-3.0"):New("AzeriteUI5_DB", defaults, true)

	-- Force reset settings on backwards incompatible changes.
	if (self.db.profile.version ~= ns.SETTINGS_VERSION) then
		self.db:ResetDB() -- Full db reset of all profiles. Destructive operation.
		self.db.profile.version = ns.SETTINGS_VERSION -- Store version in default profile.
	end

	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	-- Apply user scale to all elements
	if (self.db.profile.relativeScale) then
		self.API.SetRelativeScale(self.db.profile.relativeScale)
	end

	self:RegisterChatCommand("resetscale", "ResetBlizzardScale")

	--self:RegisterChatCommand("lock", "LockMovableFrames")
	--self:RegisterChatCommand("unlock", "UnlockMovableFrames")
	--self:RegisterChatCommand("togglelock", "ToggleMovableFrames")

	if (EditModeManagerFrame) then
		hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() self:UnlockMovableFrames() end)
		hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() self:LockMovableFrames() end)
	end

end
