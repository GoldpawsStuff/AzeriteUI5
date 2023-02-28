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
if (not ns.IsClassic) then return end

local BlizzardABDisabler = ns:NewModule("BlizzardABDisabler", "LibMoreEvents-1.0", "AceHook-3.0")

local hideActionBarFrame = function(frame, clearEvents, reanchor, noAnchorChanges)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end

		frame:Hide()
		frame:SetParent(ns.Hider)

		-- setup faux anchors so the frame position data returns valid
		if (reanchor and not noAnchorChanges) then
			local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
			frame:ClearAllPoints()
			if (left and right and top and bottom) then
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)
			else
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 10, 10)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", 20, 20)
			end
		elseif (not noAnchorChanges) then
			frame:ClearAllPoints()
		end
	end
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


	MultiBarBottomLeft:SetParent(ns.Hider)
	MultiBarBottomRight:SetParent(ns.Hider)
	MultiBarLeft:SetParent(ns.Hider)
	MultiBarRight:SetParent(ns.Hider)


	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		_G["ActionButton" .. i]:Hide()
		_G["ActionButton" .. i]:UnregisterAllEvents()
		_G["ActionButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomLeftButton" .. i]:Hide()
		_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomRightButton" .. i]:Hide()
		_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarRightButton" .. i]:Hide()
		_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarLeftButton" .. i]:Hide()
		_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)
	end
	UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["StanceBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PETACTIONBAR_YPOS"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["ExtraAbilityContainer"] = nil

	--MainMenuBar:UnregisterAllEvents()
	--MainMenuBar:SetParent(ns.Hider)
	--MainMenuBar:Hide()
	MainMenuBar:EnableMouse(false)
	MainMenuBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
	MainMenuBar:UnregisterEvent("UI_SCALE_CHANGED")


	local animations = {MainMenuBar.slideOut:GetAnimations()}
	animations[1]:SetOffset(0,0)

	if (OverrideActionBar) then -- classic doesn't have this
		animations = {OverrideActionBar.slideOut:GetAnimations()}
		animations[1]:SetOffset(0,0)

		-- when blizzard vehicle is turned off, we need to manually fix the state since the OverrideActionBar animation wont run
		hooksecurefunc("BeginActionBarTransition", function(bar, animIn)
			if bar == OverrideActionBar and not self.db.profile.blizzardVehicle then
				OverrideActionBar.slideOut:Stop()
				MainMenuBar:Show()
			end
		end)
	end

	hideActionBarFrame(MainMenuBarArtFrame, false, true)
	hideActionBarFrame(MainMenuBarArtFrameBackground)
	hideActionBarFrame(MicroButtonAndBagsBar, false, false, true)

	if (StatusTrackingBarManager) then
		StatusTrackingBarManager:Hide()
		--StatusTrackingBarManager:SetParent(ns.Hider)
	end

	hideActionBarFrame(StanceBarFrame, true, true)
	hideActionBarFrame(PossessBarFrame, false, true)
	hideActionBarFrame(MultiCastActionBarFrame, false, true)
	hideActionBarFrame(PetActionBarFrame, true, true)
	ShowPetActionBar = function() end

	--BonusActionBarFrame:UnregisterAllEvents()
	--BonusActionBarFrame:Hide()
	--BonusActionBarFrame:SetParent(ns.Hider)

	if (not ns.IsClassic) then
		if (PlayerTalentFrame) then
			PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		else
			hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
		end
	end

	hideActionBarFrame(MainMenuBarPerformanceBarFrame, false, false, true)
	hideActionBarFrame(MainMenuExpBar, false, false, true)
	hideActionBarFrame(ReputationWatchBar, false, false, true)
	hideActionBarFrame(MainMenuBarMaxLevelBar, false, false, true)

	if (IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
		self:NPE_LoadUI()
	elseif (NPE_LoadUI ~= nil) then
		self:SecureHook("NPE_LoadUI")
	end

	local HideAlerts = function()
		if (HelpTip) then
			HelpTip:HideAllSystem("MicroButtons")
		end
	end
	hooksecurefunc("MainMenuMicroButton_ShowAlert", HideAlerts)

end

BlizzardABDisabler.OnEnable = function(self)
	self:HideBlizzard()
end
