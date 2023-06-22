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

local VehicleExit = ns:NewModule("VehicleExit", "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: GameTooltip, GameTooltip_SetDefaultAnchor, Minimap
-- GLOBALS: CreateFrame, InCombatLockdown, RegisterStateDriver
-- GLOBALS: UnitOnTaxi, IsMounted, IsPossessBarVisible, PetCanBeDismissed, PetDismiss, TaxiRequestEarlyLanding
-- GLOBALS: TAXI_CANCEL, TAXI_CANCEL_DESCRIPTION
-- GLOBALS: PET_DISMISS, NEWBIE_TOOLTIP_UNIT_PET_DISMISS
-- GLOBALS: BINDING_NAME_VEHICLEEXIT

-- Lua API
local unpack = unpack

-- Addon API
local Colors = ns.Colors

local ExitButton_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	if (UnitOnTaxi("player")) then
		GameTooltip:AddLine(TAXI_CANCEL)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, unpack(Colors.green))
	elseif (IsMounted()) then
		GameTooltip:AddLine(BINDING_NAME_DISMOUNT)
	elseif (not ns.IsClassic) then
		if (IsPossessBarVisible() and PetCanBeDismissed()) then
			GameTooltip:AddLine(PET_DISMISS)
			GameTooltip:AddLine(NEWBIE_TOOLTIP_UNIT_PET_DISMISS, unpack(Colors.green))
		else
			GameTooltip:AddLine(BINDING_NAME_VEHICLEEXIT)
		end
	end
	GameTooltip:Show()
end

local ExitButton_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local ExitButton_PostClick = function(self, button)
	if (UnitOnTaxi("player") and (not InCombatLockdown())) then
		TaxiRequestEarlyLanding()
	elseif (not ns.IsClassic and IsPossessBarVisible() and PetCanBeDismissed()) then
		PetDismiss()
	end
end

VehicleExit.UpdateScale = function(self)
	if (InCombatLockdown()) then
		self.updateneeded = true
		return
	end
	if (self.Button) then
		local config = ns.GetConfig("VehicleExitButton")
		local point, anchor, rpoint, x, y = unpack(config.VehicleExitButtonPosition)

		if (ns.IsRetail) then
			local scale = Minimap:GetScale()
			local escale = scale / Minimap:GetEffectiveScale()

			self.Button:SetScale(scale)
			self.Button:ClearAllPoints()
			self.Button:SetPoint(point, anchor, rpoint, x / escale, y / escale)
		else
			self.Button:SetScale(Minimap:GetScale() * 768/1080)
			self.Button:ClearAllPoints()
			self.Button:SetPoint(point, anchor, rpoint, x, y)
		end

	end
end

VehicleExit.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.incombat = nil
		self:UpdateScale()
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		if (self.updateneeded) then
			self.updateneeded = nil
			self:UpdateScale()
		end
		self.incombat = nil
	elseif (event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED") then
		self:UpdateScale()
	end
end

VehicleExit.OnEnable = function(self)

	local config = ns.GetConfig("VehicleExitButton")

	local button = CreateFrame("CheckButton", ns.Prefix.."VehicleExitButton", UIParent, "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:SetPoint(unpack(config.VehicleExitButtonPosition))
	button:SetSize(unpack(config.VehicleExitButtonSize))
	button:SetScript("OnEnter", ExitButton_OnEnter)
	button:SetScript("OnLeave", ExitButton_OnLeave)
	button:SetScript("PostClick", ExitButton_PostClick)
	button:SetAttribute("type", "macro")

	self.Button = button

	if (ns.IsClassic) then
		button:SetAttribute("macrotext", "/dismount [mounted]\n")
		RegisterStateDriver(button, "visibility", "[mounted]show;hide")
	elseif (ns.IsWrath) then
		button:SetAttribute("macrotext", "/dismount [mounted]\n/run if CanExitVehicle() then VehicleExit() end")
		RegisterStateDriver(button, "visibility", "[@vehicle,canexitvehicle][possessbar][mounted]show;hide")
	else
		button:SetAttribute("macrotext", "/leavevehicle [@vehicle,exists,canexitvehicle]\n/dismount [mounted]")
		button:RegisterForClicks("AnyUp", "AnyDown") -- required in 10.0.0
		RegisterStateDriver(button, "visibility", "[@vehicle,exists,canexitvehicle][possessbar][mounted]show;hide")
	end

	local texture = button:CreateTexture(nil, "ARTWORK", nil, 1)
	texture:SetPoint(unpack(config.VehicleExitButtonTexturePosition))
	texture:SetSize(unpack(config.VehicleExitButtonTextureSize))
	texture:SetTexture(config.VehicleExitButtonTexture)

	button.Texture = texture

	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")

	self:SecureHook(Minimap, "SetScale", "UpdateScale")
end
