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
if (ns.IsRetail) then
	return
end

local ActionBars = ns:GetModule("ActionBars", true)
if (not ActionBars) then return end

local Blizzard = ActionBars:NewModule("Blizzard", "LibMoreEvents-1.0")
local UIHider = ns.Hider

local hideActionBar = function(frame, clearEvents, reanchor, noAnchorChanges)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end
		frame:Hide()
		frame:SetParent(UIHider)

		-- Setup faux anchors so the frame position data returns valid
		if (reanchor) and (not noAnchorChanges) then
			local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
			frame:ClearAllPoints()
			if (left) and (right) and (top) and (bottom) then
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

Blizzard.NPE_LoadUI = function(self)
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end

Blizzard.HideBlizzard = function(self)

	MultiBarBottomLeft:SetParent(UIHider)
	MultiBarBottomRight:SetParent(UIHider)
	MultiBarLeft:SetParent(UIHider)
	MultiBarRight:SetParent(UIHider)

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

	MainMenuBar:EnableMouse(false)
	MainMenuBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
	MainMenuBar:UnregisterEvent("UI_SCALE_CHANGED")

	local animations = {MainMenuBar.slideOut:GetAnimations()}
	animations[1]:SetOffset(0,0)

	if (OverrideActionBar) then -- classic doesn't have this
		animations = {OverrideActionBar.slideOut:GetAnimations()}
		animations[1]:SetOffset(0,0)
	end

	hideActionBar(MainMenuBarArtFrame, false, true)
	hideActionBar(MainMenuBarArtFrameBackground)
	hideActionBar(MicroButtonAndBagsBar, false, false, true)

	if StatusTrackingBarManager then
		StatusTrackingBarManager:Hide()
	end

	hideActionBar(StanceBarFrame, true, true)
	hideActionBar(PossessBarFrame, false, true)
	hideActionBar(MultiCastActionBarFrame, false, false, true)
	hideActionBar(PetActionBarFrame, true, true)
	hideActionBar(OverrideActionBar, true)

	ShowPetActionBar = function() end

	if (not ns.IsClassic) then
		if (PlayerTalentFrame) then
			PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		else
			hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
		end
	end

	hideActionBar(MainMenuBarVehicleLeaveButton, true)
	hideActionBar(MainMenuBarPerformanceBarFrame, false, false, true)
	hideActionBar(MainMenuExpBar, false, false, true)
	hideActionBar(ReputationWatchBar, false, false, true)
	hideActionBar(MainMenuBarMaxLevelBar, false, false, true)

	if (IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
		self:NPE_LoadUI()
	elseif (NPE_LoadUI ~= nil) then
		self:SecureHook("NPE_LoadUI")
	end

end

Blizzard.OnEnable = function(self)
	self:HideBlizzard()
end
