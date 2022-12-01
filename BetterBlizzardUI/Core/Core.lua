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
ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "AceConsole-3.0", "LibMoreEvents-1.0")
ns.L = LibStub("AceLocale-3.0"):GetLocale(Addon) -- Addon localization
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false) -- Addon callback handler
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end
_G[Addon] = ns

-- Default settings
local defaults = {
	char = {
	},
	global = {
		core = {
			enableDevelopmentMode = false,
			relativeScale = 1
		},
		actionbars = {
			enableBarFading = true,
			enableBar1 = true, numButtonsBar1 = 12, -- accepts 7-12
			enableBar2 = false, numButtonsBar2 = 12, -- accepts 1-12
			enablePetBar = true,
			enableStanceBar = true
		},
		chat = {
			storedFrames = {}
		},
		chatbubbles = {
			enableChatBubbles = true,
			visibility = {
				world = true,
				worldcombat = true,
				instance = true,
				instancecombat = false
			}
		},
		minimap = {
			useServerTime = false,
			useHalfClock = true
		},
		unitframes = {
			storedFrames = {},
			enablePlayer = true,
			enablePlayerHUD = true,
			enableTarget = true,
			enableToT = true,
			enableFocus = true,
			enablePet = true,
			enableBoss = true,
			enableParty = true,
			enableRaid = true
		}
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
local EnableAddOn = EnableAddOn
local DisableAddOn = DisableAddOn
local InCombatLockdown = InCombatLockdown
local LoadAddOn = LoadAddOn
local ReloadUI = ReloadUI

-- Private API
local IsAddOnAvailable = ns.API.IsAddOnAvailable
local SetRelativeScale = ns.API.SetRelativeScale
local UpdateObjectScales = ns.API.UpdateObjectScales
local ShowMovableFrameAnchors = ns.Widgets.ShowMovableFrameAnchors
local HideMovableFrameAnchors = ns.Widgets.HideMovableFrameAnchors
local ToggleMovableFrameAnchors = ns.Widgets.ToggleMovableFrameAnchors

-- Purge deprecated settings,
-- translate to new where applicable,
-- make sure important ones are within bounds.
local SanitizeSettings = function(db)
	if (not db) then
		return
	end
	local scale = db.global.core.relativeScale
	if (scale) then
		scale = math_min(1.25, math_max(.75, scale))
		db.global.core.relativeScale = scale
	end
	return db
end

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	ns.callbacks:Fire(name, ...)
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
		scale = math_min(1.25, math_max(.75, scale))
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

ns.SwitchUI = function(self, input)
	if (not self._ui_list) then
		-- Create a list of currently installed UIs.
		self._ui_list = {}
		for ui,cmds in next,{
			["AzeriteUI"] 	= { "azerite", "azui" },
			["DiabolicUI2"] = { "diabolic", "diablo", "dui" },
			["GoldpawUI"] 	= { "goldpaw", "gui" },
			["JourneyUI"] 	= { "journey", "jui" }
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
	print(event, ...)

	-- Fire callbacks to submodules.
	ns.callbacks:Fire("Saved_Settings_Updated")
end

ns.OnInitialize = function(self)

	self.db = SanitizeSettings(LibStub("AceDB-3.0"):New("AzeriteUI4_DB", defaults, true))
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	-- Apply user scale to all elements
	if (self.db.global.core.relativeScale) then
		SetRelativeScale(self.db.global.core.relativeScale)
	end

	-- Add a command to clear all chat frames.
	-- I mainly use this to remove clutter before taking screenshots.
	-- You could theoretically put this in a macro and clear chat then screenshot.
	self:RegisterChatCommand("clear", function()
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame and frame:IsShown()) then
				frame:Clear()
			end
		end
	end)

	-- Our UI switcher. Because I have many. And use them all.
	self:RegisterChatCommand("go", "SwitchUI")
	self:RegisterChatCommand("switchto", "SwitchUI")

	-- Fully experimental
	self:RegisterChatCommand("setscale", "SetScale")
	self:RegisterChatCommand("resetscale", "ResetScale")
	self:RegisterChatCommand("lock", "LockMovableFrames")
	self:RegisterChatCommand("unlock", "UnlockMovableFrames")
	self:RegisterChatCommand("togglelock", "ToggleMovableFrames")

	-- In case some other jokers have disabled these, we add them back to avoid a World of Bugs.
	-- RothUI used to remove the two first, and a lot of people missed his documentation on how to get them back.
	-- I personally removed the objective's tracker for a while in DiabolicUI, which led to pain. Lots of pain.
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end

end
