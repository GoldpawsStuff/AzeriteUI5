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

local VehicleExit = ns:NewModule("VehicleExit", "LibMoreEvents-1.0", "AceHook-3.0")

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
	VehicleExitButtonPosition = function()
		-- Trickery to work around the fact this cannot be parented to the Minimap,
		-- as that would cause the Minimap to be become restricted from its secure children.
		local m,w,h = ns.IsRetail and .66 or .79, ns.IsRetail and 198 or 140, ns.IsRetail and 198 or 140
		return { "CENTER", Minimap, "CENTER", -math_floor(math_cos(45*deg2rad) * w * m), math_floor(math_sin(45*deg2rad) * h * m) }
	end,
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
		local point, anchor, rpoint, x, y = unpack(config.VehicleExitButtonPosition())

		--local scaleObject = ns.IsRetail and MinimapCluster.MinimapContainer or Minimap
		local scaleObject = Minimap
		local mscale = scaleObject:GetScale()
		local escale = mscale / scaleObject:GetEffectiveScale()

		--self.Button:SetScale(ns.API.GetEffectiveScale() * mscale)
		self.Button:SetScale(--[[ns.API.GetEffectiveScale() * ]]mscale)
		self.Button:ClearAllPoints()

		--if (ns.IsRetail) then
		--	self.Button:SetPoint(point, anchor, rpoint, x * escale, y * escale) -- makes no sense
		--else
			self.Button:SetPoint(point, anchor, rpoint, x / escale, y / escale)
		--end
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
	elseif (event == "UI_SCALE_CHANGED") then
		self:UpdateScale()
	end
end

VehicleExit.OnInitialize = function(self)

	local button = CreateFrame("CheckButton", ns.Prefix.."VehicleExitButton", UIParent, "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:SetPoint(unpack(config.VehicleExitButtonPosition()))
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

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")

	-- Monitor scale changes.
	self:SecureHook(--[[ns.IsRetail and MinimapCluster.MinimapContainer or ]]Minimap, "SetScale", "UpdateScale")
end
