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
local ExplorerMode = ns:NewModule("ExplorerMode", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceTimer-3.0")

local LFF = LibStub("LibFadingFrames-1.0")

-- Lua API
local next = next
local pairs = pairs

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local POWER_TYPE_MANA = Enum.PowerType.Mana

-- Player Constants
local _,playerClass = UnitClass("player")
local playerLevel = UnitLevel("player")

-- Default settings, don't modify these.
local defaults = { profile = ns:Merge({
	enabled = false,

	-- How long to wait before initiating
	-- Explorer Mode after a loading screen.
	delayOnLogin = 15,
	delayOnReload = 0,
	delayOnZoning = 0,
	delayOnCombatEnd = 0,

	-- These options are kind of backwards,
	-- as they set when to EXIT the Explorer Mode.
	fadeInCombat = false,
	fadeInGroups = false,
	fadeInInstances = false,
	fadeWithFriendlyTarget = false,
	fadeWithHostileTarget = false,
	fadeWithDeadTarget = true,
	fadeWithFocusTarget = false,
	fadeInVehicles = false,
	fadeWithLowMana = false,
		fadeThresholdMana = .75,
		fadeThresholdManaInForms = .5,
		fadeThresholdEnergy = .5,
	fadeWithLowHealth = false,
		fadeThresholdHealth = .9,

	-- Which elements to fade out
	-- while in Explorer Mode.
	fadeActionBars = true,
	fadePetBar = true,
	fadeStanceBar = true,
	fadePlayerFrame = true,
	fadePlayerClassPower = true,
	fadePetFrame = true,
	fadeFocusFrame = true,
	fadeTracker = true,
	fadeChatFrames = true

}, ns.MovableModulePrototype.defaults) }

ExplorerMode.GenerateDefaults = function(self)
	return defaults
end

ExplorerMode.UpdateSettings = function(self)

	local db = self.db.profile

	if (db.enabled and not self.enabled) then
		self:EnableExplorerMode()
	elseif (not db.enabled and self.enabled) then
		self:DisableExplorerMode()
	end

	self.FORCED = not db.enabled and self:CheckForForcedState()

	-- Action Bars
	--------------------------------------------
	local ActionBars = ns:GetModule("ActionBars", true)
	if (ActionBars) then
		local fade = not self.FORCED and ActionBars:IsEnabled() and db.enabled and db.fadeActionBars
		for id,bar in next,ActionBars.bars do

			-- Exempt bars that are fully set to fade
			-- in their own actionbar settings.
			local db = bar.config
			local fullyFaded = db.enableBarFading and db.fadeAlone and db.fadeFrom == 1
			if (fade and not fullyFaded) then

				-- Register the bar for fading
				LFF:RegisterFrameForFading(bar, self:GetName())
			else
				-- Unregister the bar for fading, does not affect button fading.
				LFF:UnregisterFrameForFading(bar)
			end

			-- Update the bar's button fading.
			if (db.enableBarFading) then
				bar:UpdateFading() -- is this still needed?
			end
		end
	end

	local PetBar = ns:GetModule("PetBar", true)
	if (PetBar) then
		local fade = not self.FORCED and PetBar:IsEnabled() and db.enabled and db.fadePetBar
		local petBar = PetBar.bar
		if (petBar) then
			local db = petBar.config
			local fullyFaded = db.enableBarFading and db.fadeAlone and db.fadeFrom == 1
			if (fade and not fullyFaded) then
				LFF:RegisterFrameForFading(petBar, self:GetName())
			else
				LFF:UnregisterFrameForFading(petBar)
			end
		end
	end

	local StanceBar = ns:GetModule("StanceBar", true)
	if (StanceBar) then
		local fade = not self.FORCED and StanceBar:IsEnabled() and db.enabled and db.fadeStanceBar
		local stanceBar = StanceBar.bar
		if (stanceBar) then
			local db = stanceBar.config
			local fullyFaded = db.enableBarFading and db.fadeAlone and db.fadeFrom == 1
			if (fade and not fullyFaded) then
				LFF:RegisterFrameForFading(stanceBar, self:GetName())
			else
				LFF:UnregisterFrameForFading(stanceBar)
			end
		end
	end

	-- Unit Frames
	--------------------------------------------
	local PlayerFrame = ns:GetModule("PlayerFrame", true)
	if (PlayerFrame) then
		local fade = not self.FORCED and PlayerFrame:IsEnabled() and db.enabled and db.fadePlayerFrame
		local playerFrame = PlayerFrame:GetFrame()
		if (playerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(playerFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(playerFrame)
			end
		end
	end

	local PlayerFrameAlternate = ns:GetModule("PlayerFrameAlternate", true)
	if (PlayerFrameAlternate) then
		local fade = not self.FORCED and PlayerFrameAlternate:IsEnabled() and db.enabled and db.fadePlayerFrame
		local playerFrame = PlayerFrameAlternate:GetFrame()
		if (playerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(playerFrame, self:GetName())
				LFF:RegisterFrameForFading(playerFrame.Portrait, self:GetName())
			else
				LFF:UnregisterFrameForFading(playerFrame)
				LFF:UnregisterFrameForFading(playerFrame.Portrait)
			end
		end
	end

	local PlayerClassPowerFrame = ns:GetModule("PlayerClassPowerFrame", true)
	if (PlayerClassPowerFrame) then
		local fade = not self.FORCED and PlayerClassPowerFrame:IsEnabled() and db.enabled and db.fadePlayerClassPower
		local playerClassPowerFrame = PlayerClassPowerFrame:GetFrame()
		if (playerClassPowerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(playerClassPowerFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(playerClassPowerFrame)
			end
		end
	end

	local PetFrame = ns:GetModule("PetFrame", true)
	if (PetFrame) then
		local fade = not self.FORCED and PetFrame:IsEnabled() and db.enabled and db.fadePetFrame
		local petFrame = PetFrame:GetFrame()
		if (petFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(petFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(petFrame)
			end
		end
	end

	local FocusFrame = ns:GetModule("FocusFrame", true)
	if (FocusFrame) then
		local fade = not self.FORCED and FocusFrame:IsEnabled() and db.enabled and db.fadeFocusFrame
		local focusFrame = FocusFrame:GetFrame()
		if (focusFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(focusFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(focusFrame)
			end
		end
	end

	-- Objectives Tracker
	--------------------------------------------
	local Tracker = ns:GetModule("Tracker", true)
	if (Tracker) then
		local fade = not self.FORCED and Tracker:IsEnabled() and db.enabled and db.fadeTracker
		local tracker = Tracker:GetFrame()
		if (tracker) then
			if (fade) then
				LFF:RegisterFrameForFading(tracker, Tracker:GetName())
			else
				LFF:UnregisterFrameForFading(tracker)
			end
		end
	end

	-- Chat Windows
	--------------------------------------------
	local fadeChat = not self.FORCED and db.enabled and db.fadeChatFrames
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local chatFrame = _G[frameName]
		if (chatFrame) then
			if (fadeChat) then
				LFF:RegisterFrameForFading(chatFrame, "ChatFrames")
			else
				LFF:UnregisterFrameForFading(chatFrame)
			end
		end
	end

end

ExplorerMode.CheckForForcedState = function(self)
	local db = self.db.profile

	if (self.delayTimer) then
		return true
	end

	if (self.inCombat and not db.fadeInCombat) then
		return true
	end

	-- Check for the various targeting options.
	if (self.hasTarget) then

		-- Only check for hostile/friendly targets if the target is living
		-- and the option to keep faded with dead targets isn't selected.
		if not(self.hasDeadTarget and db.fadeWithDeadTarget) then

			-- Hostile target and no hostile target fade selected.
			if (self.hasAttackableTarget and not db.fadeWithHostileTarget) then
				return true

			-- Non-attackable target an no friendly fade selected.
			elseif (not self.hasAttackableTarget and not db.fadeWithFriendlyTarget) then
				return true
			end
		end
	end

	if (self.hasFocus and not db.fadeWithFocusTarget)
	or (self.inGroup and not db.fadeInGroups)
	or (self.hasOverride and not db.fadeInVehicles)
	or (self.hasPossess and not db.fadeInVehicles)
	or (self.isDragonRiding and not db.fadeInVehicles)
	or (self.inVehicle and not db.fadeInVehicles)
	or (self.inInstance and not db.fadeInInstances)
	or (self.lowHealth and not db.fadeWithLowMana)
	or (self.lowPower and not db.fadeWithLowHealth)
	--or (self.badAura)
	or (self.busyCursor) then
		return true
	end

	return nil
end

ExplorerMode.CheckCursor = function(self)
	--if (CursorHasSpell() or CursorHasItem()) then
	--	self.busyCursor = true
	--	return
	--end

	-- other values: money, merchant
	local cursor = GetCursorInfo()
	if (cursor == "petaction")
	or (cursor == "spell")
	or (cursor == "macro")
	or (cursor == "mount")
	or (cursor == "item") then
		self.busyCursor = true
		return
	end

	self.busyCursor = nil
end

ExplorerMode.CheckHealth = function(self)
	local min = UnitHealth("player") or 0
	local max = UnitHealthMax("player") or 0
	if (max > 0) and (min/max < self.db.profile.fadeThresholdHealth) then
		self.lowHealth = true
		return
	end
	self.lowHealth = nil
end

ExplorerMode.CheckPower = function(self)
	local powerID, powerType = UnitPowerType("player")
	if (powerType == "MANA") then
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < self.db.profile.fadeThresholdMana) then
			self.lowPower = true
			return
		end
	elseif (powerType == "ENERGY" or powerType == "FOCUS") then
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < self.db.profile.fadeThresholdEnergy) then
			self.lowPower = true
			return
		end
		if (playerClass == "DRUID") then
			min = UnitPower("player", POWER_TYPE_MANA) or 0
			max = UnitPowerMax("player", POWER_TYPE_MANA) or 0
			if (max > 0) and (min/max < self.db.profile.fadeThresholdManaInForms) then
				self.lowPower = true
				return
			end
		end
	end
	self.lowPower = nil
end

ExplorerMode.CheckVehicle = function(self)
	-- Only check for vehicle bars where you have actions,
	-- ignore vehicles you're just riding in like the
	-- alliance/horde chopper mounts where you're a passenger.
	if (HasVehicleActionBar()) then
		self.inVehicle = true
		return
	end
	self.inVehicle = nil
end

ExplorerMode.CheckOverride = function(self)
	if (HasOverrideActionBar() or HasTempShapeshiftActionBar()) then
		self.hasOverride = true
		return
	end
	self.hasOverride = nil
end

ExplorerMode.CheckPossess = function(self)
	if (IsPossessBarVisible()) then
		self.hasPossess = true
		return
	end
	self.hasPossess = nil
end

ExplorerMode.CheckDragonRiding = function(self)
	if (HasBonusActionBar()) then
		if (GetBonusBarOffset() == 5) then
			if (IsMounted()) then
				self.isDragonRiding = true
				return
			end
		end
	end
	self.isDragonRiding = nil
end

ExplorerMode.CheckTarget = function(self)
	if (UnitExists("target")) then
		self.hasTarget = true
		self.hasAttackableTarget = UnitCanAttack("player", "target")
		self.hasDeadTarget = UnitIsDeadOrGhost("target")
		return
	end
	self.hasTarget = nil
	self.hasAttackableTarget = nil
	self.hasDeadTarget = nil
end

ExplorerMode.CheckFocus = function(self)
	if (UnitExists("focus")) then
		self.hasFocus = true
		return
	end
	self.hasFocus = nil
end

ExplorerMode.CheckGroup = function(self)
	if (IsInGroup()) then
		self.inGroup = true
		return
	end
	self.inGroup = nil
end

ExplorerMode.CheckInstance = function(self)
	if (IsInInstance()) then
		self.inInstance = true
		return
	end
	self.inInstance = nil
end

ExplorerMode.OnTimedForcedStateEnd = function(self)
	if (self.delayTimer) then
		self:CancelTimer(self.delayTimer)
		self.delayTimer = nil
	end

	-- Restore the library's default fade out duration.
	if (self.restoreFadeOutDuration) then
		LFF:SetFadeOutDuration(nil)
		self.restoreFadeOutDuration = nil
	end

	self:UpdateSettings()
end

ExplorerMode.SetTimedForcedState = function(self, duration)
	if (self.delayTimer) then
		self:CancelTimer(self.delayTimer)
		self.delayTimer = nil
	end

	self.delayTimer = self:ScheduleTimer("OnTimedForcedStateEnd", duration)
end

ExplorerMode.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...

		-- Kill off remnant timers
		-- from pure loading screens.
		if (self.delayTimer) then
			self:CancelTimer(self.delayTimer)
			self.delayTimer = nil
		end

		local db = self.db.profile

		-- Initiate a delay according to settings.
		if (isInitialLogin) then
			if (db.delayOnLogin > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnLogin)
			end
		elseif (isReloadingUi) then
			if (db.delayOnReload > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnReload)
			end
		else
			if (db.delayOnZoning > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnZoning)
			end
		end

		if (self.delayTimer) then
			-- Restore the library's default fade out duration.
			LFF:SetFadeOutDuration(nil)
		else
			-- Hack to bypass the initial fadeout.
			-- Without it we'll have half a second of frame visibility.
			LFF:SetFadeOutDuration(0)
			self.restoreFadeOutDuration = true
		end

		self.inCombat = InCombatLockdown()

		self:CheckInstance()
		self:CheckGroup()
		self:CheckTarget()

		if (ns.IsRetail or ns.IsWrath) then
			self:CheckFocus()
			self:CheckVehicle()
			self:CheckOverride()
			self:CheckPossess()
			self:CheckDragonRiding()
		end

		self:CheckHealth()
		self:CheckPower()
		--self:CheckAuras()
		self:CheckCursor()

	elseif (event == "PLAYER_LEVEL_UP") then
			local level = ...
			if (level and (level ~= playerLevel)) then
				playerLevel = level
			else
				local level = UnitLevel("player")
				if (not playerLevel) or (playerLevel < level) then
					playerLevel = level
				end
			end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = false

		if (self.db.profile.delayOnCombatEnd > 0) then
			self:SetTimedForcedState(self.db.profile.delayOnCombatEnd)
		end

	elseif (event == "CURSOR_CHANGED") then
		self:CheckCursor()

	elseif (event == "PLAYER_TARGET_CHANGED") then
		self:CheckTarget()

	elseif (event == "PLAYER_FOCUS_CHANGED") then
		self:CheckFocus()

	elseif (event == "GROUP_ROSTER_UPDATE") then
		self:CheckGroup()

	elseif (event == "UPDATE_POSSESS_BAR") then
		self:CheckPossess()

	elseif (event == "UPDATE_OVERRIDE_ACTIONBAR") then
		self:CheckOverride()

	elseif (event == "UPDATE_BONUS_ACTIONBAR") then
		self:CheckDragonRiding()

	elseif (event == "UNIT_ENTERING_VEHICLE")
		or (event == "UNIT_ENTERED_VEHICLE")
		or (event == "UNIT_EXITING_VEHICLE")
		or (event == "UNIT_EXITED_VEHICLE")
		or (event == "UPDATE_VEHICLE_ACTIONBAR") then
		self:CheckVehicle()

	elseif (event == "UNIT_POWER_FREQUENT")
		or (event == "UNIT_DISPLAYPOWER") then
			self:CheckPower()

	elseif (event == "UNIT_HEALTH_FREQUENT") or (event == "UNIT_HEALTH") then
		self:CheckHealth()

	--elseif (event == "UNIT_AURA") then
		--self:CheckAuras()

	elseif (event == "ZONE_CHANGED_NEW_AREA") then
		self:CheckInstance()
	end

	self:UpdateSettings()
end

ExplorerMode.EnableExplorerMode = function(self)
	self:RegisterEvent("CURSOR_CHANGED", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
	self:RegisterUnitEvent("UNIT_HEALTH", "OnEvent", "player")
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "OnEvent", "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "OnEvent", "player")
	self:RegisterUnitEvent("UNIT_AURA", "OnEvent", "player", "vehicle")

	if (ns.IsRetail or ns.IsWrath or ns.IsCata) then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
		self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
		self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")
		self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
		self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player")
	end

	-- This is needed to put actionbars that were exempt from Explorer Mode fading
	-- back into it when their own full fading has been disabled.
	ns.RegisterCallback(self, "ActionBarSettings_Changed", "UpdateSettings")

	self.enabled = true
end

ExplorerMode.DisableExplorerMode = function(self)
	self:UnregisterEvent("CURSOR_CHANGED", "OnEvent")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
	self:UnregisterEvent("UNIT_HEALTH", "OnEvent", "player")
	self:UnregisterEvent("UNIT_POWER_FREQUENT", "OnEvent", "player")
	self:UnregisterEvent("UNIT_DISPLAYPOWER", "OnEvent", "player")
	self:UnregisterEvent("UNIT_AURA", "OnEvent", "player", "vehicle")

	if (ns.IsRetail or ns.IsWrath or ns.IsCata) then
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
		self:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
		self:UnregisterEvent("UPDATE_POSSESS_BAR", "OnEvent")
		self:UnregisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
		self:UnregisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent", "player")
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player")
	end

	-- This is needed to put actionbars that were exempt from Explorer Mode fading
	-- back into it when their own full fading has been disabled.
	ns.UnregisterCallback(self, "ActionBarSettings_Changed", "UpdateSettings")

	self.enabled = nil
end

ExplorerMode.OnEnable = function(self)
end
