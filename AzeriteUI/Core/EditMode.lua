--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

-- Something is tainted or broken in 11.0.0.
if (not ns.WoW10 or ns.WoW11) then return end

local EditModeManager = ns:NewModule("EditModeManager", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local next = next

-- GLOBALS: C_EditMode
-- GLOBALS: EditModeManagerFrame, EditModeUnsavedChangesDialog, GameMenuButtonEditMode
-- GLOBALS: InCombatLockdown, HideUIPanel, StaticPopupSpecial_Hide

EditModeManager.OnEvent = function(self, event, ...)
	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then

		if (not EditModeManagerFrame:IsEventRegistered(event)) then
			self.needsUpdate = true
		end

	elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then

		local arg = ...
		if (arg == "player" and not EditModeManagerFrame:IsEventRegistered(event)) then
			self.needsUpdate = true
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then

		GameMenuButtonEditMode:SetEnabled(false)

		EditModeManagerFrame:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
		EditModeManagerFrame:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	elseif (event == "PLAYER_REGEN_ENABLED") then

		GameMenuButtonEditMode:SetEnabled(true)

		if (next(self.hideFrames)) then
			for frame in next,hideFrames do
				HideUIPanel(frame)
				frame:SetScale(1)
				self.hideFrames[frame] = nil
			end
		end

		if (self.needsUpdate) then
			EditModeManagerFrame:UpdateLayoutInfo(C_EditMode.GetLayouts())
			self.needsUpdate = false
		end

		EditModeManagerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
		EditModeManagerFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	end

end

EditModeManager.OnEnable = function(self)
	--if (not ObjectiveTrackerFrame:IsInDefaultPosition()) then
	--	ShowUIPanel(EditModeManagerFrame)
	--	ObjectiveTrackerFrame:ResetToDefaultPosition()
	--	MicroMenuContainer:ResetToDefaultPosition()
	--	C_Timer.After(.1, function()
	--		EditModeManagerFrame:SaveLayouts()
	--		HideUIPanel(EditModeManagerFrame)
	--	end)
	--end

	--GameMenuButtonEditMode:HookScript("PreClick", function()
	--	local dropdown = LFDQueueFrameTypeDropDown
	--	local parent = dropdown:GetParent()
	--	dropdown:SetParent(nil)
	--	dropdown:SetParent(parent)
	--end)

	--hooksecurefunc(ObjectiveTrackerFrame, "Show", function(self)
	--	self:Hide()
	--end)

	--hooksecurefunc(ObjectiveTrackerFrame, "SetShown", function(self, show)
	--	if (show) then
	--		self:Hide()
	--	end
	--end)

	--ObjectiveTrackerFrame:Hide()

	--EncounterBar.HighlightSystem = ns.Noop
	--EncounterBar.ClearHighlight = ns.Noop

	--GameTooltipDefaultContainer.HighlightSystem = ns.Noop
	--GameTooltipDefaultContainer.ClearHighlight = ns.Noop

	--MinimapCluster.HighlightSystem = ns.Noop
	--MinimapCluster.ClearHighlight = ns.Noop

end

EditModeManager.OnInitialize = function(self)
	LoadAddOn("Blizzard_ObjectiveTracker")

	--EditModeManagerFrame:UnregisterAllEvents()
	--EditModeManagerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	--hooksecurefunc(EditModeManagerFrame, "EnterEditMode", HideUIPanel)


	self.hideFrames = {}

	local canEnterEditMode = EditModeManagerFrame.CanEnterEditMode
	EditModeManagerFrame.CanEnterEditMode = function(self)
		return not InCombatLockdown() and canEnterEditMode(self)
	end

	EditModeUnsavedChangesDialog.ProceedButton:SetScript("OnClick", function()
		if (EditModeUnsavedChangesDialog.selectedLayoutIndex) then
			EditModeManagerFrame:SelectLayout(EditModeUnsavedChangesDialog.selectedLayoutIndex)
		else
			local combat = InCombatLockdown()
			if (combat) then
				self.hideFrames[EditModeManagerFrame] = true
				for _, child in next, EditModeManagerFrame.registeredSystemFrames do
					child:ClearHighlight()
				end
			end
			HideUIPanel(EditModeManagerFrame, not combat)
			EditModeManagerFrame:SetScale(combat and .00001 or 1)
		end
		StaticPopupSpecial_Hide(EditModeUnsavedChangesDialog)
	end)

	EditModeUnsavedChangesDialog.SaveAndProceedButton:SetScript("OnClick", function()
		EditModeManagerFrame:SaveLayoutChanges()
		EditModeUnsavedChangesDialog.ProceedButton:GetScript("OnClick")()
	end)

	EditModeManagerFrame.onCloseCallback = function()
		if (EditModeManagerFrame:HasActiveChanges()) then
			EditModeManagerFrame:ShowRevertWarningDialog()
		else
			local combat = InCombatLockdown()
			if (combat) then
				self.hideFrames[EditModeManagerFrame] = true
				for _, child in next, EditModeManagerFrame.registeredSystemFrames do
					child:ClearHighlight()
				end
			end
			HideUIPanel(EditModeManagerFrame, not combat)
			EditModeManagerFrame:SetScale(combat and .00001 or 1)
		end
	end

	EditModeManagerFrame.AccountSettings.RefreshCastBar = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshAuraFrame = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshBossFrames = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshArenaFrames = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshRaidFrames = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshPartyFrames = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshTargetAndFocus = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshVehicleLeaveButton = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshActionBarShown = ns.Noop
	EditModeManagerFrame.AccountSettings.RefreshEncounterBar = ns.Noop

	MainStatusTrackingBarContainer.OnEditModeEnter = ns.Noop
	MicroMenuContainer.OnEditModeEnter = ns.Noop

	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")

	-- Function removed in 11.0.0
	if (GameMenuButtonEditMode) then
		self:SecureHook(GameMenuButtonEditMode, "SetEnabled", function(self, enabled)
			if (InCombatLockdown() and enabled) then
				self:Disable()
			end
		end)
	end

end
