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
local oUF = ns.oUF

local PlayerMod = ns:NewModule("PlayerFrame", "LibMoreEvents-1.0")

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local Config = ns.Config
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- Constants
local playerClass = ns.PlayerClass
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOMLEFT",
			[2] = 46,
			[3] = 100
		},
		Classic = {
			scale = 1,
			[1] = "TOPLEFT",
			[2] = 46,
			[3] = -46
		},
		Modern = {
			scale = 1,
			[1] = "TOPLEFT",
			[2] = 46,
			[3] = -46
		}
	}
}, ns.UnitFrame.defaults) }

local barSparkMap = {
	{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 },
	{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 },
	{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 },
	{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 },
	{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 },
	{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 },
	{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }
}

local crystalSparkMap = {
	top = {
		{ keyPercent =   0/256, offset =  -65/256 },
		{ keyPercent =  72/256, offset =    0/256 },
		{ keyPercent = 116/256, offset =  -16/256 },
		{ keyPercent = 128/256, offset =  -28/256 },
		{ keyPercent = 256/256, offset =  -84/256 },
	},
	bottom = {
		{ keyPercent =   0/256, offset =  -47/256 },
		{ keyPercent =  84/256, offset =    0/256 },
		{ keyPercent = 135/256, offset =  -24/256 },
		{ keyPercent = 142/256, offset =  -32/256 },
		{ keyPercent = 225/256, offset =  -79/256 },
		{ keyPercent = 256/256, offset = -168/256 },
	}
}

local config = {

	-- General Settings
	-----------------------------------------
	Size = { 439, 93 },
	Position = { "BOTTOMLEFT", 167, 100 },
	HitRectInsets = { 0, 0, 0, 6 },

	-- Health Value Text
	HealthValuePosition = { "LEFT", 27, 4 },
	HealthValueJustifyH = "LEFT",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(18, true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- Mana Value Text (when mana is not primary resource)
	ManaTextPosition = { "CENTER", 1, -34 },
	ManaTextFont = GetFont(15, true),
	ManaTextColor = { Colors.red[1], Colors.red[2], Colors.red[3], .75 },
	ManaTextJustifyH = "CENTER",
	ManaTextJustifyV = "MIDDLE",

	-- Power Value Text
	PowerValuePosition = { "CENTER", 0, -16 },
	PowerValueJustifyH = "CENTER",
	PowerValueJustifyV = "MIDDLE",
	PowerValueFont = GetFont(18, true),
	PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

	-- Mana Orb Value Text
	ManaValuePosition = { "CENTER", 3, 0 },
	ManaValueJustifyH = "CENTER",
	ManaValueJustifyV = "MIDDLE",
	ManaValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },
	ManaValueFont = GetFont(18, true),

	-- Castbar Name Text
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
	CastBarTextProtectedColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 },

	-- Castbar Value Text
	CastBarValuePosition = { "RIGHT", -27, 4 },
	CastBarValueJustifyH = "CENTER",
	CastBarValueJustifyV = "MIDDLE",
	CastBarValueFont = GetFont(18, true),
	CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

	-- Combat Feedback Text
	CombatFeedbackAnchorElement = "Health",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	-- Combat Indicator
	CombatIndicatorPosition = { "BOTTOMLEFT", -81, -18 },
	CombatIndicatorSize = { 80,80 },
	CombatIndicatorTexture = GetMedia("icon-combat"),
	CombatIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },

	-- PvP Indicator
	PvPIndicatorPosition = { "BOTTOMLEFT", -81, -18 },
	PvPIndicatorSize = { 84, 84 },
	PvPIndicatorAllianceTexture = GetMedia("icon_badges_alliance"),
	PvPIndicatorHordeTexture = GetMedia("icon_badges_horde"),

	-- Auras
	-----------------------------------------
	AurasPosition = { "BOTTOMLEFT", 37, 91 },
	AurasSize = { 40*8 - 4, 40*2 - 4 },
	AuraSize = 36,
	AuraSpacing = 4,
	AurasNumTotal = 16,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "BOTTOMLEFT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "RIGHT",
	AurasGrowthY = "UP",
	AurasTooltipAnchor = "ANCHOR_TOPLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Seasonal Overrides & Additions
	-----------------------------------------
	Seasonal = {
		-- Love Festival Combat Indicator
		LoveFestivalCombatIndicatorPosition = { "BOTTOMLEFT", -61, 2 },
		LoveFestivalCombatIndicatorSize = { 48, 48 },
		LoveFestivalCombatIndicatorTexture = GetMedia("icon-heart-red"),
		LoveFestivalCombatIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },

		-- Winter Veil Power Crystal Decorations
		WinterVeilPowerSize = { 197, 197 },
		WinterVeilPowerPlace = { "CENTER", -2, 24 },
		WinterVeilPowerTexture = GetMedia("seasonal_winterveil_crystal"),

		-- Winter Veil Mana Orb Decorations
		WinterVeilManaSize = { 188, 188 },
		WinterVeilManaPlace = { "CENTER", 0, 0 },
		WinterVeilManaTexture = GetMedia("seasonal_winterveil_orb")
	},

	-- Orb and Crystal Colors
	-----------------------------------------
	ManaOrbColor = { 135/255, 125/255, 255/255 },
	PowerBarColors = {
		ENERGY = { 0/255, 208/255, 176/255 },
		FOCUS = { 116/255, 156/255, 255/255 },
		LUNAR_POWER = { 116/255, 156/255, 255/255 },
		MAELSTROM = { 116/255, 156/255, 255/255 },
		RUNIC_POWER = { 116/255, 156/255, 255/255 },
		FURY = { 156/255, 116/255, 255/255 },
		INSANITY = { 156/255, 116/255, 255/255 },
		PAIN = { 156/255, 116/255, 255/255 },
		RAGE = { 156/255, 116/255, 255/255 },
		MANA = { 101/255, 93/255, 191/255 }
	},

	-- Level Specific Settings
	-----------------------------------------
	Novice = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_low_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case_low"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_low"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },


	},
	Hardened = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_mid_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_mid_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	},
	Seasoned = {

		-- Health Bar
		HealthBarSize = { 385, 40 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	}
}

-- Utility Functions
--------------------------------------------
-- Simplify the tagging process a little.
local prefix = function(msg)
	return string_gsub(msg, "*", ns.Prefix)
end

-- Element Callbacks
--------------------------------------------
-- Forceupdate health prediction on health updates,
-- to assure our smoothed elements are properly aligned.
local Health_PostUpdate = function(element, unit, cur, max)
	local predict = element.__owner.HealthPrediction
	if (predict) then
		predict:ForceUpdate()
	end
end

-- Update the health preview color on health color updates.
local Health_PostUpdateColor = function(element, unit, r, g, b)
	local preview = element.Preview
	if (preview) then
		preview:SetStatusBarColor(r * .7, g * .7, b * .7)
	end
end

-- Align our custom health prediction texture
-- based on the plugin's provided values.
local HealPredict_PostUpdate = function(element, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, curHealth, maxHealth)

	local allIncomingHeal = myIncomingHeal + otherIncomingHeal
	local allNegativeHeals = healAbsorb
	local showPrediction, change

	if ((allIncomingHeal > 0) or (allNegativeHeals > 0)) and (maxHealth > 0) then
		local startPoint = curHealth/maxHealth

		-- Dev switch to test absorbs with normal healing
		--allIncomingHeal, allNegativeHeals = allNegativeHeals, allIncomingHeal

		-- Hide predictions if the change is very small, or if the unit is at max health.
		change = (allIncomingHeal - allNegativeHeals)/maxHealth
		if ((curHealth < maxHealth) and (change > (element.health.predictThreshold or .05))) then
			local endPoint = startPoint + change

			-- Crop heal prediction overflows
			if (endPoint > 1) then
				endPoint = 1
				change = endPoint - startPoint
			end

			-- Crop heal absorb overflows
			if (endPoint < 0) then
				endPoint = 0
				change = -startPoint
			end

			-- This shouldn't happen, but let's do it anyway.
			if (startPoint ~= endPoint) then
				showPrediction = true
			end
		end
	end

	if (showPrediction) then

		local preview = element.preview
		local growth = preview:GetGrowth()
		local min,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()
		local isFlipped = preview:IsFlippedHorizontally()

		if (growth == "RIGHT") then

			local texValue, texChange = value, change
			local rangeH, rangeV

			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				if (isFlipped) then
					element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				else
					element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				end
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				if (isFlipped) then
					element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				else
					element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				end
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end

		elseif (growth == "LEFT") then
			local texValue, texChange = value, change
			local rangeH, rangeV
			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				if (isFlipped) then
					element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				else
					element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				end
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				if (isFlipped) then
					element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				else
					element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				end
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end
		end
	else
		element:Hide()
	end

	local absorb = element.Absorb
	if (absorb) then
		local fraction = absorb/maxHealth
		if (fraction > .6) then
			absorb = maxHealth * .6
		end
		absorb:SetMinMaxValues(0, maxHealth)
		absorb:SetValue(absorb)
	end

end

-- Only show mana orb when mana is the primary resource.
local Mana_UpdateVisibility = function(self, event, unit)
	local element = self.AdditionalPower

	local shouldEnable = not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana
	local isEnabled = element.__isEnabled

	if (shouldEnable and not isEnabled) then

		if (element.frequentUpdates) then
			self:RegisterEvent("UNIT_POWER_FREQUENT", element.Override)
		else
			self:RegisterEvent("UNIT_POWER_UPDATE", element.Override)
		end

		self:RegisterEvent("UNIT_MAXPOWER", element.Override)

		element:Show()

		element.__isEnabled = true
		element.Override(self, "ElementEnable", "player", "MANA")

		--[[ Callback: AdditionalPower:PostVisibility(isVisible)
		Called after the element's visibility has been changed.

		* self      - the AdditionalPower element
		* isVisible - the current visibility state of the element (boolean)
		--]]
		if (element.PostVisibility) then
			element:PostVisibility(true)
		end

	elseif (not shouldEnable and (isEnabled or isEnabled == nil)) then

		self:UnregisterEvent("UNIT_MAXPOWER", element.Override)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", element.Override)
		self:UnregisterEvent("UNIT_POWER_UPDATE", element.Override)

		element:Hide()

		element.__isEnabled = false
		element.Override(self, "ElementDisable", "player", "MANA")

		if (element.PostVisibility) then
			element:PostVisibility(false)
		end

	elseif (shouldEnable and isEnabled) then
		element.Override(self, event, unit, "MANA")
	end
end

-- Hide power crystal when mana is the primary resource.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	local powerType = UnitPowerType(unit)
	if (powerType == Enum.PowerType.Mana) then
		element:Hide()
	else
		element:Show()
	end
end

-- Use custom colors for our power crystal. Does not apply to Wrath.
local Power_PostUpdateColor = function(element, unit, r, g, b)

	local pType, pToken, altR, altG, altB = UnitPowerType(unit)
	local color = pToken and config.PowerBarColors[pToken]
	if (color) then
		element:SetStatusBarColor(color[1], color[2], color[3])
	end
end

-- Toggle cast text color on protected casts.
local Cast_PostCastInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element.Text:SetTextColor(unpack(element.Text.colorProtected))
	else
		element.Text:SetTextColor(unpack(element.Text.color))
	end
end

-- Toggle cast info and health info when castbar is visible.
local Cast_UpdateTexts = function(element)
	local health = element.__owner.Health

	if (element:IsShown()) then
		element.Text:Show()
		element.Time:Show()
		health.Value:Hide()
	else
		element.Text:Hide()
		element.Time:Hide()
		health.Value:Show()
	end
end

-- Trigger PvPIndicator post update when combat status is toggled.
local CombatIndicator_PostUpdate = function(element, inCombat)
	element.__owner.PvPIndicator:ForceUpdate()
end

-- Only show Horde/Alliance badges, and hide them in combat.
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.unit

	local status
	local factionGroup = UnitFactionGroup(unit) or "Neutral"

	if (factionGroup ~= "Neutral") then
		if (UnitIsPVPFreeForAll(unit)) then
		elseif (UnitIsPVP(unit)) then
			if (unit == "player" and UnitIsMercenary(unit)) then
				if (factionGroup == "Horde") then
					factionGroup = "Alliance"
				elseif (factionGroup == "Alliance") then
					factionGroup = "Horde"
				end
			end
			status = factionGroup
		end
	end

	if (status and not self.CombatIndicator:IsShown()) then
		element:SetTexture(element[status])
		element:Show()
	else
		element:Hide()
	end

end

-- Update player frame based on player level.
local UnitFrame_UpdateTextures = function(self)
	local key = (playerXPDisabled or IsLevelAtEffectiveMaxLevel(playerLevel)) and "Seasoned" or playerLevel < 10 and "Novice" or "Hardened"
	local db = config[key]

	local health = self.Health
	health:ClearAllPoints()
	health:SetPoint(unpack(db.HealthBarPosition))
	health:SetSize(unpack(db.HealthBarSize))
	health:SetStatusBarTexture(db.HealthBarTexture)
	health:SetStatusBarColor(unpack(db.HealthBarColor))
	health:SetOrientation(db.HealthBarOrientation)
	health:SetSparkMap(db.HealthBarSparkMap)

	local healthPreview = self.Health.Preview
	healthPreview:SetStatusBarTexture(db.HealthBarTexture)

	local healthBackdrop = self.Health.Backdrop
	healthBackdrop:ClearAllPoints()
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)
	healthBackdrop:SetVertexColor(unpack(db.HealthBackdropColor))

	local healPredict = self.HealthPrediction
	healPredict:SetTexture(db.HealthBarTexture)

	local absorb = self.Health.Absorb
	if (absorb) then
		absorb:SetStatusBarTexture(db.HealthBarTexture)
		absorb:SetStatusBarColor(unpack(db.HealthAbsorbColor))
		local orientation
		if (db.HealthBarOrientation == "UP") then
			orientation = "DOWN"
		elseif (db.HealthBarOrientation == "DOWN") then
			orientation = "UP"
		elseif (db.HealthBarOrientation == "LEFT") then
			orientation = "RIGHT"
		else
			orientation = "LEFT"
		end
		absorb:SetOrientation(orientation)
		absorb:SetSparkMap(db.HealthBarSparkMap)
	end

	local power = self.Power
	power:ClearAllPoints()
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetTexCoord(unpack(db.PowerBarTexCoord))
	power:SetOrientation(db.PowerBarOrientation)
	power:SetSparkMap(db.PowerBarSparkMap)

	local powerBackdrop = self.Power.Backdrop
	powerBackdrop:ClearAllPoints()
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetTexture(db.PowerBackdropTexture)

	local powerCase = self.Power.Case
	powerCase:ClearAllPoints()
	powerCase:SetPoint(unpack(db.PowerBarForegroundPosition))
	powerCase:SetSize(unpack(db.PowerBarForegroundSize))
	powerCase:SetTexture(db.PowerBarForegroundTexture)
	powerCase:SetVertexColor(unpack(db.PowerBarForegroundColor))

	local mana = self.AdditionalPower
	mana:ClearAllPoints()
	mana:SetPoint(unpack(db.ManaOrbPosition))
	mana:SetSize(unpack(db.ManaOrbSize))
	if (type(db.ManaOrbTexture) == "table") then
		mana:SetStatusBarTexture(unpack(db.ManaOrbTexture))
	else
		mana:SetStatusBarTexture(db.ManaOrbTexture)
	end
	mana:SetStatusBarColor(unpack(config.ManaOrbColor))

	local manaBackdrop = self.AdditionalPower.Backdrop
	manaBackdrop:ClearAllPoints()
	manaBackdrop:SetPoint(unpack(db.ManaOrbBackdropPosition))
	manaBackdrop:SetSize(unpack(db.ManaOrbBackdropSize))
	manaBackdrop:SetTexture(db.ManaOrbBackdropTexture)
	manaBackdrop:SetVertexColor(unpack(db.ManaOrbBackdropColor))

	local manaShade = self.AdditionalPower.Shade
	manaShade:ClearAllPoints()
	manaShade:SetPoint(unpack(db.ManaOrbShadePosition))
	manaShade:SetSize(unpack(db.ManaOrbShadeSize))
	manaShade:SetTexture(db.ManaOrbShadeTexture)
	manaShade:SetVertexColor(unpack(db.ManaOrbShadeColor))

	local manaCase = self.AdditionalPower.Case
	manaCase:ClearAllPoints()
	manaCase:SetPoint(unpack(db.ManaOrbForegroundPosition))
	manaCase:SetSize(unpack(db.ManaOrbForegroundSize))
	manaCase:SetTexture(db.ManaOrbForegroundTexture)
	manaCase:SetVertexColor(unpack(db.ManaOrbForegroundColor))

	local cast = self.Castbar
	cast:ClearAllPoints()
	cast:SetPoint(unpack(db.HealthBarPosition))
	cast:SetSize(unpack(db.HealthBarSize))
	cast:SetStatusBarTexture(db.HealthBarTexture)
	cast:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	cast:SetOrientation(db.HealthBarOrientation)
	cast:SetSparkMap(db.HealthBarSparkMap)

end

-- Frame Script Handlers
--------------------------------------------
local OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		playerXPDisabled = IsXPUserDisabled()
		playerLevel = UnitLevel("player")

	elseif (event == "ENABLE_XP_GAIN") then
		playerXPDisabled = nil

	elseif (event == "DISABLE_XP_GAIN") then
		playerXPDisabled = true

	elseif (event == "PLAYER_LEVEL_UP") then
		local level = ...
		if (level and (level ~= playerLevel)) then
			playerLevel = level
		else
			local level = UnitLevel("player")
			if (level ~= self.playerLevel) then
				playerLevel = level
			end
		end
	end
	UnitFrame_UpdateTextures(self)
end

local style = function(self, unit)

	local db = config
	self:SetSize(unpack(db.Size))
	self:SetPoint(unpack(db.Position))
	self:SetHitRectInsets(unpack(db.HitRectInsets))

	-- Overlay for icons and text
	--------------------------------------------
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	self.Overlay = overlay

	-- Health
	--------------------------------------------
	local health = self:CreateBar()
	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health.predictThreshold = .01

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate

	local healthBackdrop = self:CreateTexture(nil, "BACKGROUND", nil, -1)

	self.Health.Backdrop = healthBackdrop

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetFrameLevel(overlay:GetFrameLevel())
	healthOverlay:SetAllPoints()

	self.Health.Overlay = healthOverlay

	local healthPreview = self:CreateBar(nil, health)
	healthPreview:SetAllPoints(health)
	healthPreview:SetFrameLevel(health:GetFrameLevel() - 1)
	healthPreview:DisableSmoothing(true)
	healthPreview:SetSparkTexture("")
	healthPreview:SetAlpha(.5)

	self.Health.Preview = healthPreview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)

	local healPredict = healPredictFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	healPredict.health = health
	healPredict.preview = healthPreview
	healPredict.maxOverflow = 1

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- Cast Overlay
	--------------------------------------------
	local castbar = self:CreateBar()
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:DisableSmoothing(true)

	self.Castbar = castbar

	-- Cast Name
	--------------------------------------------
	local castText = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castText:SetPoint(unpack(db.HealthValuePosition))
	castText:SetFontObject(db.HealthValueFont)
	castText:SetTextColor(unpack(db.CastBarTextColor))
	castText:SetJustifyH(db.HealthValueJustifyH)
	castText:SetJustifyV(db.HealthValueJustifyV)
	castText:Hide()
	castText.color = db.CastBarTextColor
	castText.colorProtected = Colors.CastBarTextProtectedColor

	self.Castbar.Text = castText
	self.Castbar.PostCastInterruptible = Cast_PostCastInterruptible

	-- Cast Time
	--------------------------------------------
	local castTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castTime:SetPoint(unpack(db.CastBarValuePosition))
	castTime:SetFontObject(db.CastBarValueFont)
	castTime:SetTextColor(unpack(db.CastBarTextColor))
	castTime:SetJustifyH(db.CastBarValueJustifyH)
	castTime:SetJustifyV(db.CastBarValueJustifyV)
	castTime:Hide()

	self.Castbar.Time = castTime

	self.Castbar:HookScript("OnShow", Cast_UpdateTexts)
	self.Castbar:HookScript("OnHide", Cast_UpdateTexts)

	-- Health Value
	--------------------------------------------
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint(unpack(db.HealthValuePosition))
	healthValue:SetFontObject(db.HealthValueFont)
	healthValue:SetTextColor(unpack(db.HealthValueColor))
	healthValue:SetJustifyH(db.HealthValueJustifyH)
	healthValue:SetJustifyV(db.HealthValueJustifyV)
	self:Tag(healthValue, prefix("[*:Health]  [*:Absorb]"))

	self.Health.Value = healthValue

	-- Absorb Bar
	--------------------------------------------
	local absorb = self:CreateBar()
	absorb:SetAllPoints(health)
	absorb:SetFrameLevel(health:GetFrameLevel() + 3)

	self.Health.Absorb = absorb

	-- Power Crystal
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(self:GetFrameLevel() - 2)
	power.frequentUpdates = true
	power.displayAltPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility
	self.Power.PostUpdateColor = Power_PostUpdateColor

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -2)
	local powerCase = power:CreateTexture(nil, "ARTWORK", nil, 1)

	self.Power.Backdrop = powerBackdrop
	self.Power.Case = powerCase

	-- Power Value
	--------------------------------------------
	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 1)
	powerValue:SetPoint(unpack(db.PowerValuePosition))
	powerValue:SetFontObject(db.PowerValueFont)
	powerValue:SetTextColor(unpack(db.PowerValueColor))
	powerValue:SetJustifyH(db.PowerValueJustifyH)
	powerValue:SetJustifyV(db.PowerValueJustifyV)
	self:Tag(powerValue, prefix("[*:Power]"))

	self.Power.Value = powerValue

	-- ManaText Value
	-- *when mana isn't primary resource
	--------------------------------------------
	local manaText = power:CreateFontString(nil, "OVERLAY", nil, 1)
	manaText:SetPoint(unpack(db.ManaTextPosition))
	manaText:SetFontObject(db.ManaTextFont)
	manaText:SetTextColor(unpack(db.ManaTextColor))
	manaText:SetJustifyH(db.ManaTextJustifyH)
	manaText:SetJustifyV(db.ManaTextJustifyV)
	self:Tag(manaText, prefix("[*:ManaText:Low]"))

	self.Power.ManaText = manaText

	-- Mana Orb
	--------------------------------------------
	local mana = self:CreateOrb()
	mana:SetFrameLevel(self:GetFrameLevel() - 2)
	mana.displayPairs = {}
	mana.frequentUpdates = true

	self.AdditionalPower = mana
	self.AdditionalPower.Override = ns.API.UpdateAdditionalPower
	self.AdditionalPower.OverrideVisibility = Mana_UpdateVisibility

	local manaCaseFrame = CreateFrame("Frame", nil, mana)
	manaCaseFrame:SetFrameLevel(mana:GetFrameLevel() + 1)
	manaCaseFrame:SetAllPoints()

	local manaBackdrop = mana:CreateTexture(nil, "BACKGROUND", nil, -2)
	local manaShade = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 1)
	local manaCase = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 2)

	self.AdditionalPower.Backdrop = manaBackdrop
	self.AdditionalPower.Shade = manaShade
	self.AdditionalPower.Case = manaCase

	-- Mana Orb Value
	--------------------------------------------
	local manaValue = manaCaseFrame:CreateFontString(nil, "OVERLAY", nil, 1)
	manaValue:SetPoint(unpack(db.ManaValuePosition))
	manaValue:SetFontObject(db.ManaValueFont)
	manaValue:SetTextColor(unpack(db.ManaValueColor))
	manaValue:SetJustifyH(db.ManaValueJustifyH)
	manaValue:SetJustifyV(db.ManaValueJustifyV)
	self:Tag(manaValue, prefix("[*:Mana]"))

	self.AdditionalPower.Value = manaValue

	-- CombatFeedback Text
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	feedbackText:SetFontObject(db.CombatFeedbackFont)
	feedbackText.feedbackFont = db.CombatFeedbackFont
	feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

	self.CombatFeedback = feedbackText

	-- Combat Indicator
	--------------------------------------------
	local combatIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	combatIndicator:SetSize(unpack(db.CombatIndicatorSize))
	combatIndicator:SetPoint(unpack(db.CombatIndicatorPosition))
	combatIndicator:SetTexture(db.CombatIndicatorTexture)
	combatIndicator:SetVertexColor(unpack(db.CombatIndicatorColor))

	self.CombatIndicator = combatIndicator
	self.CombatIndicator.PostUpdate = CombatIndicator_PostUpdate

	-- PvP Indicator
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(unpack(db.PvPIndicatorSize))
	PvPIndicator:SetPoint(unpack(db.PvPIndicatorPosition))
	PvPIndicator.Alliance = db.PvPIndicatorAllianceTexture
	PvPIndicator.Horde = db.PvPIndicatorHordeTexture

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(unpack(db.AurasSize))
	auras:SetPoint(unpack(db.AurasPosition))
	auras.size = db.AuraSize
	auras.spacing = db.AuraSpacing
	auras.numTotal = db.AurasNumTotal
	auras.disableMouse = db.AurasDisableMouse
	auras.disableCooldown = db.AurasDisableCooldown
	auras.onlyShowPlayer = db.AurasOnlyShowPlayer
	auras.showStealableBuffs = db.AurasShowStealableBuffs
	auras.initialAnchor = db.AurasInitialAnchor
	auras["spacing-x"] = db.AurasSpacingX
	auras["spacing-y"] = db.AurasSpacingY
	auras["growth-x"] = db.AurasGrowthX
	auras["growth-y"] = db.AurasGrowthY
	auras.tooltipAnchor = db.AurasTooltipAnchor
	auras.sortMethod = db.AurasSortMethod
	auras.sortDirection = db.AurasSortDirection
	auras.CreateButton = ns.AuraStyles.CreateButton
	auras.reanchorIfVisibleChanged = true
	auras.PostUpdateButton = ns.AuraStyles.PlayerPostUpdateButton
	auras.CustomFilter = ns.AuraFilters.PlayerAuraFilter
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail

	self.Auras = auras

	-- Seasonal Flavors
	--------------------------------------------
	-- Feast of Winter Veil
	if (ns.API.IsWinterVeil()) then
		local winterVeilPower = power:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilPower:SetSize(unpack(db.Seasonal.WinterVeilPowerSize))
		winterVeilPower:SetPoint(unpack(db.Seasonal.WinterVeilPowerPlace))
		winterVeilPower:SetTexture(db.Seasonal.WinterVeilPowerTexture)

		self.Power.WinterVeil = winterVeilPower

		local winterVeilMana = manaCaseFrame:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilMana:SetSize(unpack(db.Seasonal.WinterVeilManaSize))
		winterVeilMana:SetPoint(unpack(db.Seasonal.WinterVeilManaPlace))
		winterVeilMana:SetTexture(db.Seasonal.WinterVeilManaTexture)

		self.AdditionalPower.WinterVeil = winterVeilMana
	end

	-- Love is in the Air
	if (ns.API.IsLoveFestival()) then
		combatIndicator:SetSize(unpack(db.Seasonal.LoveFestivalCombatIndicatorSize))
		combatIndicator:ClearAllPoints()
		combatIndicator:SetPoint(unpack(db.Seasonal.LoveFestivalCombatIndicatorPosition))
		combatIndicator:SetTexture(db.Seasonal.LoveFestivalCombatIndicatorTexture)
		combatIndicator:SetVertexColor(unpack(db.Seasonal.LoveFestivalCombatIndicatorColor))
	end

	-- Register events to handle texture updates.
	self:RegisterEvent("PLAYER_ALIVE", OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", OnEvent, true)
	self:RegisterEvent("DISABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("ENABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", OnEvent, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", OnEvent, true)

end

PlayerMod.DisableBlizzard = function(self)
	oUF:DisableBlizzard("player")

	-- Disable Player Alternate Power Bar
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
	PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")

	-- Move to PlayerHUD!
	-- Disable player cast bar
	-- Disable class powers
	-- Disable monk stagger
	-- Disable death knight runes
end

PlayerMod.GetAnchor = function(self)
	if (not self.Anchor) then

		local anchor = ns.Widgets.RequestMovableFrameAnchor()
		anchor:SetScalable(true)
		anchor:SetMinMaxScale(.75, 1.25, .05)
		anchor:SetSize(560, 160)
		anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
		anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
		anchor:SetTitle(ns.Prefix.."PlayerFrame")
		anchor.Callback = function(_, ...) self:OnAnchorUpdate(...) end

		self.Anchor = anchor
	end
	return self.Anchor
end

PlayerMod.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = PlayerMod.db.profile.savedPosition

	if (reason == "LayoutsUpdated") then
		if (savedPosition[layoutName]) then

			self.Anchor:SetScale(savedPosition[layoutName].scale or self.Anchor:GetScale())
			self.Anchor:ClearAllPoints()
			self.Anchor:SetPoint(unpack(savedPosition[layoutName]))

			local defaultPosition = defaults.profile.savedPosition[layoutName]
			if (defaultPosition) then
				self.Anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			self.currentLayout = layoutName

		else
			savedPosition[layoutName] = { self.Anchor:GetPosition() }
			savedPosition[layoutName].scale = self.Anchor:GetScale()
		end

		-- Purge layouts not matching editmode themes or our defaults.
		for name in pairs(savedPosition) do
			if (not defaults.profile.savedPosition[name]) then
				local found
				for lname in pairs(C_EditMode.GetLayouts().layouts) do
					if (lname == name) then
						found = true
						break
					end
				end
				if (not found) then
					savedPosition[name] = nil
				end
			end
		end

		self:UpdatePositionAndScale()

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPosition[layoutName] = { point, x, y }
		savedPosition[layoutName].scale = self.Anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.
		self.positionNeedsFix = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end

PlayerMod.UpdatePositionAndScale = function(self)
	if (ns.UnitFrames.Player) then
		local savedPosition = PlayerMod.db.profile.savedPosition
		if (self.currentLayout and savedPosition[self.currentLayout]) then
			--ns.UnitFrames.Player:SetPoint(unpack(savedPosition[self.currentLayout]))
			ns.UnitFrames.Player:SetScale(savedPosition[self.currentLayout].scale)
			ns.UnitFrames.Player:ClearAllPoints()
			ns.UnitFrames.Player:SetPoint("BOTTOMLEFT", self.Anchor, "BOTTOMLEFT", 121, 0)
		end
	end
	self.positionNeedsFix = nil
end

--local Player = ns.UnitFrames.Player
--if (Player) then
--	if (db.enablePlayer and not Player:IsEnabled()) then
--		Player:Enable()
--	elseif (not db.enablePlayer and Player:IsEnabled()) then
--		Player:Disable()
--	end
--end

PlayerMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		--self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self.incombat = nil
		if (self.positionNeedsFix) then
			self:UpdatePositionAndScale()
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true
	end
end

PlayerMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("PlayerFrame", defaults)
	self:SetEnabledState(self.db.profile.enabled)
	self:DisableBlizzard()

	oUF:RegisterStyle(ns.Prefix.."Player", style)
end

PlayerMod.OnEnable = function(self)
	if (ns.UnitFrames.Player) then
		ns.UnitFrames.Player:Enable()
	else
		oUF:SetActiveStyle(ns.Prefix.."Player")
		ns.UnitFrames.Player = oUF:Spawn("player", ns.Prefix.."UnitFramePlayer")
		ns.UnitFrames.Player.Anchor = self:GetAnchor()
	end
end

PlayerMod.OnDisable = function(self)
	if (ns.UnitFrames.Player) then
		ns.UnitFrames.Player:Disable()
	end
end