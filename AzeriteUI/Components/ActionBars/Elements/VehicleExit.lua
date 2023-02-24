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

local VehicleExit = ns:NewModule("VehicleExit", "LibMoreEvents-1.0")

-- Lua API
local math_cos = math.cos
local math_floor = math.floor
local math_sin = math.sin
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local deg2rad = math.pi / 180

local config = {
	VehicleExitButtonPosition = { "CENTER", Minimap, "CENTER", -math_floor(math_cos(45*deg2rad) * 116.5), math_floor(math_sin(45*deg2rad) * 116.5) },
	VehicleExitButtonSize = { 32, 32 },
	VehicleExitButtonTexturePosition = { "CENTER", 0, 0 },
	VehicleExitButtonTextureSize = { 80, 80 },
	VehicleExitButtonTexture = GetMedia("icon_exit_flight")
}

local ExitButton_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	if (UnitOnTaxi("player")) then
		GameTooltip:AddLine(TAXI_CANCEL)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, unpack(Colors.green))
	elseif (IsMounted()) then
		GameTooltip:AddLine(BINDING_NAME_DISMOUNT)
	else
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
	elseif (IsPossessBarVisible() and PetCanBeDismissed()) then
		PetDismiss()
	end
end

VehicleExit.OnInitialize = function(self)

	local button = CreateFrame("CheckButton", ns.Prefix.."VehicleExitButton", UIParent, "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:SetPoint(unpack(config.VehicleExitButtonPosition))
	button:SetSize(unpack(config.VehicleExitButtonSize))
	button:SetScript("OnEnter", ExitButton_OnEnter)
	button:SetScript("OnLeave", ExitButton_OnLeave)
	button:SetScript("PostClick", ExitButton_PostClick)
	button:SetAttribute("type", "macro")

	if (ns.IsWrath) then
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

end
