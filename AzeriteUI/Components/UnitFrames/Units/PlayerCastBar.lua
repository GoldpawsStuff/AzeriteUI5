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
local oUF = ns.oUF

local CastBarMod = ns:Merge(ns:NewModule("PlayerCastBarFrame", "LibMoreEvents-1.0"), ns.UnitFrame.modulePrototype)
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider

-- Constants
local playerClass = ns.PlayerClass
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = {
			enabled = true,
			scale = ns.API.GetEffectiveScale(),
			[1] = "BOTTOM",
			[2] = 0 * ns.API.GetEffectiveScale(),
			[3] = (290 - 16/2) * ns.API.GetEffectiveScale()
		}
	}
}, ns.UnitFrame.defaults) }

local castBarSparkMap = {
	top = {
		{ keyPercent =   0/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	},
	bottom = {
		{ keyPercent =   0/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	}
}

local config = {

	CastBarSize = { 112, 11 },
	CastBarTexture = GetMedia("cast_bar"),
	CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], .69 },
	CastBarOrientation = "RIGHT",
	CastBarSparkMap = castBarSparkMap,
	CastBarTimeToHoldFailed = .5,

	CastBarSpellQueueTexture = GetMedia("cast_bar"),
	CastBarSpellQueueColor = { 1, 1, 1, .5 },

	CastBarBackgroundPosition = { "CENTER", 1, -1 },
	CastBarBackgroundSize = { 193,93 },
	CastBarBackgroundTexture = GetMedia("cast_back"),
	CastBarBackgroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	CastBarTextPosition = { "TOP", 0, -26 },
	CastBarTextJustifyH = "CENTER",
	CastBarTextJustifyV = "MIDDLE",
	CastBarTextFont = GetFont(15, true),
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarValuePosition = { "CENTER", 0, 0 },
	CastBarValueJustifyH = "CENTER",
	CastBarValueJustifyV = "MIDDLE",
	CastBarValueFont = GetFont(14, true),
	CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarShieldPosition = { "CENTER", 1, -2 },
	CastBarShieldSize = { 193, 93 },
	CastBarShieldTexture = GetMedia("cast_back_spiked"),
	CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] }

}

-- Element Callbacks
--------------------------------------------
local Cast_CustomDelayText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetFormattedText("|cffff0000%s%.2f|r", element.casting and "+" or "-", element.delay)
end

local Cast_CustomTimeText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetText()
end

-- Update cast bar color and backdrop to indicate protected casts.
-- *Note that the shield icon works as an alternate backdrop here,
--  which is why we're hiding the regular backdrop on protected casts.
local Cast_Update = function(element, unit)
	if (element.notInterruptible) then
		element.Backdrop:Hide()
		element:SetStatusBarColor(unpack(Colors.red))
	else
		element.Backdrop:Show()
		element:SetStatusBarColor(unpack(Colors.cast))
	end

	-- Don't show mega tiny spell queue zones, it just looks cluttered.
	-- Also, fix the tex coords. OuF does it all wrong.
	local ratio = (select(4, GetNetStats()) / 1000) / element.max
	if (ratio > 1) then ratio = 1 end
	if (ratio > .05) then

		local width, height = element:GetSize()
		element.SafeZone:SetSize(width * ratio, height)
		element.SafeZone:ClearAllPoints()

		if (element.channeling) then
			element.SafeZone:SetPoint("LEFT")
			element.SafeZone:SetTexCoord(0, ratio, 0, 1)
		else
			element.SafeZone:SetPoint("RIGHT")
			element.SafeZone:SetTexCoord(1-ratio, 1, 0, 1)
		end

		element.SafeZone:Show()
	else
		element.SafeZone:Hide()
	end

end

-- Frame Script Handlers
--------------------------------------------
local style = function(self, unit)

	local db = config

	self:SetSize(112 + 16, 11 + 16)

	-- Cast Bar
	--------------------------------------------
	local cast = self:CreateBar()
	cast:SetFrameStrata("MEDIUM")
	cast:SetPoint("CENTER")
	cast:SetSize(unpack(db.CastBarSize))
	cast:SetStatusBarTexture(db.CastBarTexture)
	cast:SetStatusBarColor(unpack(Colors.cast))
	cast:SetOrientation(db.CastBarOrientation)
	cast:SetSparkMap(db.CastBarSparkMap)
	cast:DisableSmoothing(true)
	cast.timeToHold = db.CastBarTimeToHoldFailed

	local castBackdrop = cast:CreateTexture(nil, "BORDER", nil, -2)
	castBackdrop:SetPoint(unpack(db.CastBarBackgroundPosition))
	castBackdrop:SetSize(unpack(db.CastBarBackgroundSize))
	castBackdrop:SetTexture(db.CastBarBackgroundTexture)
	castBackdrop:SetVertexColor(unpack(db.CastBarBackgroundColor))
	cast.Backdrop = castBackdrop

	local castShield = cast:CreateTexture(nil, "BORDER", nil, -1)
	castShield:SetPoint(unpack(db.CastBarShieldPosition))
	castShield:SetSize(unpack(db.CastBarShieldSize))
	castShield:SetTexture(db.CastBarShieldTexture)
	castShield:SetVertexColor(unpack(db.CastBarShieldColor))
	cast.Shield = castShield

	local castSafeZone = cast:CreateTexture(nil, "ARTWORK", nil, 0)
	castSafeZone:SetTexture(db.CastBarSpellQueueTexture)
	castSafeZone:SetVertexColor(unpack(db.CastBarSpellQueueColor))
	cast.SafeZone = castSafeZone

	local castText = cast:CreateFontString(nil, "OVERLAY", nil, 0)
	castText:SetPoint(unpack(db.CastBarTextPosition))
	castText:SetFontObject(db.CastBarTextFont)
	castText:SetTextColor(unpack(db.CastBarTextColor))
	castText:SetJustifyH(db.CastBarTextJustifyH)
	castText:SetJustifyV(db.CastBarTextJustifyV)
	cast.Text = castText

	local castTime = cast:CreateFontString(nil, "OVERLAY", nil, 0)
	castTime:SetPoint(unpack(db.CastBarValuePosition))
	castTime:SetFontObject(db.CastBarValueFont)
	castTime:SetTextColor(unpack(db.CastBarValueColor))
	castTime:SetJustifyH(db.CastBarValueJustifyH)
	castTime:SetJustifyV(db.CastBarValueJustifyV)
	cast.Time = castTime

	local castDelay = cast:CreateFontString(nil, "OVERLAY", nil, 0)
	castDelay:SetFontObject(GetFont(12,true))
	castDelay:SetTextColor(unpack(Colors.red))
	castDelay:SetPoint("LEFT", cast, "RIGHT", 12, 0)
	castDelay:SetJustifyV("MIDDLE")
	cast.Delay = castDelay

	cast.CustomDelayText = Cast_CustomDelayText
	cast.CustomTimeText = Cast_CustomTimeText
	cast.PostCastInterruptible = Cast_Update
	cast.PostCastStart = Cast_Update
	--cast.PostCastStop = Cast_Update -- needed?

	self.Castbar = cast

end

CastBarMod.Spawn = function(self)

	-- UnitFrame
	---------------------------------------------------
	local unit, name = "player", "PlayerCastBar"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = ns.UnitFrame.Spawn(unit, ns.Prefix.."UnitFrame"..name)
	self.frame:EnableMouse(false)

	-- Movable Frame Anchor
	---------------------------------------------------
	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(HUD_EDIT_MODE_CAST_BAR_LABEL or SHOW_ARENA_ENEMY_CASTBAR_TEXT)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.25, 2.5, .05)
	anchor:SetSize(112 + 16, 11 + 16)
	anchor:SetPoint(unpack(defaults.profile.savedPosition[MFM:GetDefaultLayout()]))
	anchor:SetScale(defaults.profile.savedPosition[MFM:GetDefaultLayout()].scale)
	anchor:SetEditModeAccountSetting(ns.IsRetail and Enum.EditModeAccountSetting.ShowCastBar)
	anchor.PreUpdate = function() self:UpdateAnchor() end
	anchor.UpdateDefaults = function() self:UpdateDefaults() end

	self.anchor = anchor
end

CastBarMod.UpdateVisibility = function(self, event, ...)
	if (not self.frame) then return end
	if (InCombatLockdown()) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateVisibility")
		return
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateVisibility")
	end
	if (GetCVarBool("nameplateShowSelf")) then
		self:Disable()
	else
		self:Enable()
	end
end

CastBarMod.OnInitialize = function(self)
	if (IsAddOnEnabled("Quartz")) then
		return self:Disable()
	end

	self.db = ns.db:RegisterNamespace("PlayerCastBarFrame", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	MFM:RegisterPresets(self.db.profile.savedPosition)

	if (ns.IsRetail) then

		-- How the fuck do I get this out of the editmode?
		PlayerCastingBarFrame:SetParent(UIHider)
		PlayerCastingBarFrame:UnregisterAllEvents()
		PlayerCastingBarFrame:SetUnit(nil)
		PlayerCastingBarFrame:Hide()
		PlayerCastingBarFrame:SetAlpha(0) -- will this do it? anchor still there?

		PetCastingBarFrame:SetParent(UIHider)
		PetCastingBarFrame:UnregisterAllEvents()
		PetCastingBarFrame:SetUnit(nil)
		PetCastingBarFrame:UnregisterEvent("UNIT_PET")
		PetCastingBarFrame:Hide()
	end

	self:RegisterEvent("CVAR_UPDATE", "UpdateVisibility")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateVisibility")

end
