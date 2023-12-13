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
if (ns.IsClassic) then return end

if (ns.API.IsAddOnEnabled("ConsolePort_Bar")) then return end

local BlizzardABDisabler = ns:NewModule("BlizzardABDisabler", "LibMoreEvents-1.0", "AceHook-3.0")

local purgeKey = function(t, k)
	t[k] = nil
	local c = 42
	repeat
		if t[c] == nil then
			t[c] = nil
		end
		c = c + 1
	until issecurevariable(t, k)
end

local hideActionBarFrame = function(frame, clearEvents)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end

		-- Remove some EditMode hooks
		if (frame.system) then
			-- Purge the show state to avoid any taint concerns
			purgeKey(frame, "isShownExternal")
		end

		-- EditMode overrides the Hide function, avoid calling it as it can taint
		if (frame.HideBase) then
			frame:HideBase()
		else
			frame:Hide()
		end
		frame:SetParent(ns.Hider)
	end
end

local hideActionButton = function(button)
	if (not button) then return end

	button:Hide()
	button:UnregisterAllEvents()
	button:SetAttribute("statehidden", true)
end

BlizzardABDisabler.NPE_LoadUI = function(self)
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end

BlizzardABDisabler.HideBlizzard = function(self)

	hideActionBarFrame(MainMenuBar, false)
	hideActionBarFrame(MultiBarBottomLeft, true)
	hideActionBarFrame(MultiBarBottomRight, true)
	hideActionBarFrame(MultiBarLeft, true)
	hideActionBarFrame(MultiBarRight, true)
	hideActionBarFrame(MultiBar5, true)
	hideActionBarFrame(MultiBar6, true)
	hideActionBarFrame(MultiBar7, true)

	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		hideActionButton(_G["ActionButton" .. i])
		hideActionButton(_G["MultiBarBottomLeftButton" .. i])
		hideActionButton(_G["MultiBarBottomRightButton" .. i])
		hideActionButton(_G["MultiBarRightButton" .. i])
		hideActionButton(_G["MultiBarLeftButton" .. i])
		hideActionButton(_G["MultiBar5Button" .. i])
		hideActionButton(_G["MultiBar6Button" .. i])
		hideActionButton(_G["MultiBar7Button" .. i])
	end

	hideActionBarFrame(BagsBar, false) -- 10.0.5
	hideActionBarFrame(MicroMenu, false) -- 10.0.5
	hideActionBarFrame(MicroButtonAndBagsBar, false)
	hideActionBarFrame(StanceBar, true)
	hideActionBarFrame(PossessActionBar, true)
	hideActionBarFrame(MultiCastActionBarFrame, false)
	hideActionBarFrame(PetActionBar, true)
	hideActionBarFrame(StatusTrackingBarManager, false)
	hideActionBarFrame(OverrideActionBar, true)

	-- these events drive visibility, we want the MainMenuBar to remain invisible
	MainMenuBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
	MainMenuBar:UnregisterEvent("PLAYER_REGEN_DISABLED")
	MainMenuBar:UnregisterEvent("ACTIONBAR_SHOWGRID")
	MainMenuBar:UnregisterEvent("ACTIONBAR_HIDEGRID")

	ActionBarController:UnregisterAllEvents()
	if (ns.WoW10) then
		ActionBarController:RegisterEvent("SETTINGS_LOADED") -- needed to update paging
	end
	if (ns.IsRetail) then
		ActionBarController:RegisterEvent("UPDATE_EXTRA_ACTIONBAR") -- needed to update extrabuttons
	end

	if IsAddOnLoaded("Blizzard_NewPlayerExperience") then
		self:NPE_LoadUI()
	elseif NPE_LoadUI ~= nil then
		self:SecureHook("NPE_LoadUI")
	end

	local HideAlerts = function()
		if (HelpTip) then
			HelpTip:HideAllSystem("MicroButtons")
		end
	end
	hooksecurefunc("MainMenuMicroButton_ShowAlert", HideAlerts)

end

BlizzardABDisabler.OnInitialize = function(self)
	if (ns.API.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end
end

BlizzardABDisabler.OnEnable = function(self)
	self:HideBlizzard()
end
