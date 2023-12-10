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
local ExplorerMode = ns:NewModule("ExplorerMode", ns.Module, "LibMoreEvents-1.0") --

local LFF = LibStub("LibFadingFrames-1.0")

-- Lua API
local next = next
local pairs = pairs

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local POWER_TYPE_MANA = Enum.PowerType.Mana

-- Player Constants
local _,playerClass = UnitClass("player")
local playerLevel = UnitLevel("player")

local defaults = { profile = ns:Merge({
	enabled = false,
	fadeActionBars = true,
	fadePetBar = true,
	fadeStanceBar = true,
	fadePlayerFrame = true,
	fadeTracker = true,
	fadeChatFrames = true

}, ns.Module.defaults) }

ExplorerMode.GenerateDefaults = function(self)
	return defaults
end

ExplorerMode.UpdateSettings = function(self)

	if self.inCombat
	or self.hasTarget
	--or self.hasFocus
	or (self.inGroup and self.disableGroupFade)
	or self.hasOverride
	or self.hasPossess
	or self.inVehicle
	or (self.inInstance and self.disableInstanceFade)
	or self.lowHealth
	or self.lowPower
	or self.busyCursor
	or self.badAura then
		self.FORCED = true
	else
		self.FORCED = nil
	end

	local ActionBars = ns:GetModule("ActionBars", true)
	if (ActionBars) then
		local fade = not self.FORCED and ActionBars:IsEnabled() and self.db.profile.enabled and self.db.profile.fadeActionBars
		for id,bar in next,ActionBars.bars do
			if (fade) then
				LFF:RegisterFrameForFading(bar, self:GetName())
			else
				LFF:UnregisterFrameForFading(bar)
			end
		end
	end

	local PetBar = ns:GetModule("PetBar", true)
	if (PetBar) then
		local fade = not self.FORCED and PetBar:IsEnabled() and self.db.profile.enabled and self.db.profile.fadePetBar
		local petBar = PetBar.bar
		if (petBar) then
			if (fade) then
				LFF:RegisterFrameForFading(petBar, self:GetName())
			else
				LFF:UnregisterFrameForFading(petBar)
			end
		end
	end

	local StanceBar = ns:GetModule("StanceBar", true)
	if (StanceBar) then
		local fade = not self.FORCED and StanceBar:IsEnabled() and self.db.profile.enabled and self.db.profile.fadeStanceBar
		local stanceBar = StanceBar.bar
		if (stanceBar) then
			if (fade) then
				LFF:RegisterFrameForFading(stanceBar, self:GetName())
			else
				LFF:UnregisterFrameForFading(stanceBar)
			end
		end
	end

	local PlayerFrame = ns:GetModule("PlayerFrame", true)
	if (PlayerFrame) then
		local fade = not self.FORCED and PlayerFrame:IsEnabled() and self.db.profile.enabled and self.db.profile.fadePlayerFrame
		local playerFrame = PlayerFrame:GetFrame()
		if (playerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(playerFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(playerFrame)
			end
		end
	end

	local Tracker = ns:GetModule("Tracker", true)
	if (Tracker) then
		local fade = not self.FORCED and Tracker:IsEnabled() and self.db.profile.enabled and self.db.profile.fadeTracker
		local tracker = Tracker:GetFrame()
		if (tracker) then
			if (fade) then
				LFF:RegisterFrameForFading(tracker, Tracker:GetName())
			else
				LFF:UnregisterFrameForFading(tracker)
			end
		end
	end

	local fadeChat = not self.FORCED and self.db.profile.enabled and self.db.profile.fadeChatFrames
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

ExplorerMode.CheckCursor = function(self)
	if (CursorHasSpell() or CursorHasItem()) then
		self.busyCursor = true
		return
	end

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
	if (max > 0) and (min/max < .9) then
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
		if (max > 0) and (min/max < .75) then
			self.lowPower = true
			return
		end
	elseif (powerType == "ENERGY" or powerType == "FOCUS") then
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < .5) then
			self.lowPower = true
			return
		end
		if (playerClass == "DRUID") then
			min = UnitPower("player", POWER_TYPE_MANA) or 0
			max = UnitPowerMax("player", POWER_TYPE_MANA) or 0
			if (max > 0) and (min/max < .5) then
				self.lowPower = true
				return
			end
		end
	end
	self.lowPower = nil
end

ExplorerMode.CheckVehicle = function(self)
	--if (UnitInVehicle("player") or HasVehicleActionBar()) then
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

ExplorerMode.CheckTarget = function(self)
	if UnitExists("target") then
		self.hasTarget = true
		return
	end
	self.hasTarget = nil
end

ExplorerMode.CheckFocus	 = function(self)
	if UnitExists("focus") then
		self.hasFocus = true
		return
	end
	self.hasFocus = nil
end

ExplorerMode.CheckGroup = function(self)
	if IsInGroup() then
		self.inGroup = true
		return
	end
	self.inGroup = nil
end

ExplorerMode.CheckInstance = function(self)
	if IsInInstance() then
		self.inInstance = true
		return
	end
	self.inInstance = nil
end


ExplorerMode.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...

		self.inCombat = InCombatLockdown()

		self:CheckInstance()
		self:CheckGroup()
		self:CheckTarget()

		if (ns.IsRetail or ns.IsWrath) then
			self:CheckFocus()
			self:CheckVehicle()
			self:CheckOverride()
			self:CheckPossess()
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

ExplorerMode.OnEnable = function(self)

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

	if (ns.IsRetail or ns.IsWrath) then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
		self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
		self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")
		self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player")
	end

end
