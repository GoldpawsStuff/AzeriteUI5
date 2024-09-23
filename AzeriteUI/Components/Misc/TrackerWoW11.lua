--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

if (not ns.WoW11) then return end

local Tracker = ns:NewModule("Tracker", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0")

-- GLOBALS: IsAddOnLoaded, SetOverrideBindingClick

-- Addon API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local UIHider = ns.Hider

local DEFAULT_THEME = "Blizzard"
local CURRENT_THEME = DEFAULT_THEME

local Cache = {}
local Custom = {}

-- Will move data to the skins,
-- currently just the keys need to exist though.
local Skins = {
	Blizzard = {},
	Azerite = {}
}

local defaults = { profile = ns:Merge({

	theme = "Azerite",
	disableBlizzardTracker = false

}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Tracker.GenerateDefaults = function(self)
	return defaults
end

Tracker.PrepareFrames = function(self)

	ObjectiveTrackerFrame.autoHider = CreateFrame("Frame", nil, ObjectiveTrackerFrame, "SecureHandlerStateTemplate")
	ObjectiveTrackerFrame.autoHider:SetAttribute("_onstate-vis", [[ if (newstate == "hide") then self:Hide() else self:Show() end ]])
	ObjectiveTrackerFrame.autoHider:SetScript("OnHide", function() ObjectiveTrackerFrame:SetAlpha(0) end)
	ObjectiveTrackerFrame.autoHider:SetScript("OnShow", function() ObjectiveTrackerFrame:SetAlpha(.9) end)

	local driver = "hide;show"
	driver = "[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists]" .. driver
	driver = "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists][@boss5,exists]" .. driver
	--driver = "[@target,exists]" .. driver -- For testing purposes

	RegisterStateDriver(ObjectiveTrackerFrame.autoHider, "vis", driver)

	ObjectiveTrackerUIWidgetContainer:SetFrameStrata("BACKGROUND")
	ObjectiveTrackerFrame:SetFrameStrata("BACKGROUND")
	ObjectiveTrackerFrame:SetFrameLevel(50)
	ObjectiveTrackerFrame:SetClampedToScreen(false)
	ObjectiveTrackerFrame:SetAlpha(.9)

	self.GetFrame = function() return ObjectiveTrackerFrame end

end

Tracker.UpdateSettings = function(self)

	if (self.db.profile.disableBlizzardTracker) then

		if (not self:IsHooked(ObjectiveTrackerFrame, "Show")) then
			self:SecureHook(ObjectiveTrackerFrame, "Show", function(this)
				if (self.db.profile.disableBlizzardTracker) then
					this:Hide()
				end
			end)
		end

		if (not self:IsHooked(ObjectiveTrackerFrame, "SetShown")) then
			self:SecureHook(ObjectiveTrackerFrame, "SetShown", function(this, show)
				if (self.db.profile.disableBlizzardTracker) then
					if (show) then
						this:Hide()
					end
				end
			end)
		end

		if (ObjectiveTrackerFrame:IsShown()) then
			ObjectiveTrackerFrame:Hide()
		end
	else

		if (not ObjectiveTrackerFrame:IsShown()) then
			ObjectiveTrackerFrame:Show()
		end
	end
end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "SETTINGS_LOADED") then
		ObjectiveTrackerFrame:SetAlpha(.9)
		self:UpdateSettings()
	end
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			if (ImmersionFrame) then
				if (not self:IsHooked(ImmersionFrame, "OnShow")) then
					self:SecureHookScript(ImmersionFrame, "OnShow", function() ObjectiveTrackerFrame:SetAlpha(0) end)
				end
				if (not self:IsHooked(ImmersionFrame, "OnHide")) then
					self:SecureHookScript(ImmersionFrame, "OnHide", function() ObjectiveTrackerFrame:SetAlpha(.9) end)
				end
			end
		end
	end
end

Tracker.OnEnable = function(self)

	LoadAddOn("Blizzard_ObjectiveTracker")

	self:PrepareFrames()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("SETTINGS_LOADED", "OnEvent")
end
