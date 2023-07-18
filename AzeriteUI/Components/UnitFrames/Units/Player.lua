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
local oUF = ns.oUF

local PlayerFrameMod = ns:NewModule("PlayerFrame", ns.UnitFrameModule, "LibMoreEvents-1.0")

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- GLOBALS: Enum, PlayerPowerBarAlt
-- GLOBALS: CreateFrame, GetSpecialization, IsXPUserDisabled, IsLevelAtEffectiveMaxLevel
-- GLOBALS: UnitFactionGroup, UnitLevel, UnitPowerType, UnitHasVehicleUI, UnitIsMercenary, UnitIsPVP, UnitIsPVPFreeForAll

-- Addon API
local Colors = ns.Colors

-- Constants
local playerClass = ns.PlayerClass
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()
local SPEC_PALADIN_RETRIBUTION = SPEC_PALADIN_RETRIBUTION or 3
local playerIsRetribution = playerClass == "PALADIN" and (ns.IsRetail and GetSpecialization() == SPEC_PALADIN_RETRIBUTION)

local defaults = { profile = ns:Merge({
	showAuras = true,
	showCastbar = true,
	aurasBelowFrame = false
}, ns.Module.defaults) }

PlayerFrameMod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOMLEFT",
		[2] = 46 * ns.API.GetEffectiveScale(),
		[3] = 100 * ns.API.GetEffectiveScale()
	}
	return defaults
end

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
	if (preview and g) then
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
		local _,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()
		local isFlipped = preview:IsFlippedHorizontally()

		if (growth == "RIGHT") then

			local texValue, texChange = value, change
			local rangeH

			rangeH = right - left
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
			local rangeH

			rangeH = right - left
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

	if (element.absorbBar) then
		if (hasOverAbsorb and curHealth >= maxHealth) then
			absorb = UnitGetTotalAbsorbs(unit)
			if (absorb > maxHealth * .4) then
				absorb = maxHealth * .4
			end
			element.absorbBar:SetValue(absorb)
		end
	end

end

-- Only show mana orb when mana is the primary resource.
local Mana_UpdateVisibility = function(self, event, unit)
	local element = self.AdditionalPower

	local shouldEnable = not playerIsRetribution and not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana
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
	if (playerIsRetribution) then
		element:Show()
	else
		local powerType = UnitPowerType(unit)
		if (powerType == Enum.PowerType.Mana and not UnitHasVehicleUI("player")) then
			element:Hide()
		else
			element:Show()
		end
	end
end

-- Use custom colors for our power crystal. Does not apply to Wrath.
local Power_PostUpdateColor = function(element, unit, r, g, b)
	local config = ns.GetConfig("PlayerFrame")

	local _, pToken = UnitPowerType(unit)
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
			if (ns.IsRetail and unit == "player" and UnitIsMercenary(unit)) then
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
	local playerLevel = playerLevel or UnitLevel("player")
	local key = (playerXPDisabled or IsLevelAtEffectiveMaxLevel(playerLevel)) and "Seasoned" or playerLevel < 10 and "Novice" or "Hardened"
	local config = ns.GetConfig("PlayerFrame")
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
	healthPreview:SetOrientation(db.HealthBarOrientation)

	local healthBackdrop = self.Health.Backdrop
	healthBackdrop:ClearAllPoints()
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)
	healthBackdrop:SetVertexColor(unpack(db.HealthBackdropColor))

	local healPredict = self.HealthPrediction
	healPredict:SetTexture(db.HealthBarTexture)

	local absorb = self.HealthPrediction.absorbBar
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

	local threat = self.ThreatIndicator
	if (threat) then
		for key,texture in next,threat.textures do
			texture:ClearAllPoints()
			texture:SetPoint(unpack(db[key.."ThreatPosition"]))
			texture:SetSize(unpack(db[key.."ThreatSize"]))
			texture:SetTexture(db[key.."ThreatTexture"])
		end
	end

end

local UnitFrame_PostUpdate = function(self)
	UnitFrame_UpdateTextures(self)
end

-- Frame Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		playerXPDisabled = IsXPUserDisabled()
		playerLevel = UnitLevel("player")
		playerIsRetribution = playerClass == "PALADIN" and (ns.IsRetail and GetSpecialization() == SPEC_PALADIN_RETRIBUTION)

		self.Power:ForceUpdate()
		self.AdditionalPower:ForceUpdate()

	elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
		playerIsRetribution = playerClass == "PALADIN" and (ns.IsRetail and GetSpecialization() == SPEC_PALADIN_RETRIBUTION)

		self.Power:ForceUpdate()
		self.AdditionalPower:ForceUpdate()

	elseif (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED") then
		self.Auras:ForceUpdate()

	elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED") then


	elseif (event == "ENABLE_XP_GAIN") then
		playerXPDisabled = nil

	elseif (event == "DISABLE_XP_GAIN") then
		playerXPDisabled = true

	elseif (event == "PLAYER_LEVEL_UP") then
		playerLevel = UnitLevel("player")
	end

	UnitFrame_PostUpdate(self)
end

local style = function(self, unit)

	local config = ns.GetConfig("PlayerFrame")

	self:SetSize(unpack(config.Size))
	self:SetHitRectInsets(unpack(config.HitRectInsets))
	self:SetFrameLevel(self:GetFrameLevel() + 2)
	self:SetIgnoreParentAlpha(true)

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
	self.Health.PostUpdateColor = Health_PostUpdateColor

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
	castText:SetPoint(unpack(config.HealthValuePosition))
	castText:SetFontObject(config.HealthValueFont)
	castText:SetTextColor(unpack(config.CastBarTextColor))
	castText:SetJustifyH(config.HealthValueJustifyH)
	castText:SetJustifyV(config.HealthValueJustifyV)
	castText:Hide()
	castText.color = config.CastBarTextColor
	castText.colorProtected = Colors.CastBarTextProtectedColor

	self.Castbar.Text = castText
	self.Castbar.PostCastInterruptible = Cast_PostCastInterruptible

	-- Cast Time
	--------------------------------------------
	local castTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castTime:SetPoint(unpack(config.CastBarValuePosition))
	castTime:SetFontObject(config.CastBarValueFont)
	castTime:SetTextColor(unpack(config.CastBarTextColor))
	castTime:SetJustifyH(config.CastBarValueJustifyH)
	castTime:SetJustifyV(config.CastBarValueJustifyV)
	castTime:Hide()

	self.Castbar.Time = castTime

	self.Castbar:HookScript("OnShow", Cast_UpdateTexts)
	self.Castbar:HookScript("OnHide", Cast_UpdateTexts)

	-- Health Value
	--------------------------------------------
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint(unpack(config.HealthValuePosition))
	healthValue:SetFontObject(config.HealthValueFont)
	healthValue:SetTextColor(unpack(config.HealthValueColor))
	healthValue:SetJustifyH(config.HealthValueJustifyH)
	healthValue:SetJustifyV(config.HealthValueJustifyV)
	if (ns.IsRetail) then
		self:Tag(healthValue, prefix("[*:Health]  [*:Absorb]"))
	else
		self:Tag(healthValue, prefix("[*:Health]"))
	end

	self.Health.Value = healthValue

	-- Absorb Bar
	--------------------------------------------
	if (ns.IsRetail) then
		local absorb = self:CreateBar()
		absorb:SetAllPoints(health)
		absorb:SetFrameLevel(health:GetFrameLevel() + 3)

		--self.Health.absorbBar = absorb
		self.HealthPrediction.absorbBar = absorb
	end

	-- Power Crystal
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(self:GetFrameLevel() - 2)
	power.frequentUpdates = true
	power.displayAltPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility
	self.Power.PostUpdateColor = not ns.IsWrath and Power_PostUpdateColor

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -2)
	local powerCase = power:CreateTexture(nil, "ARTWORK", nil, 2)

	self.Power.Backdrop = powerBackdrop
	self.Power.Case = powerCase

	-- Power Value
	--------------------------------------------
	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 1)
	powerValue:SetPoint(unpack(config.PowerValuePosition))
	powerValue:SetFontObject(config.PowerValueFont)
	powerValue:SetTextColor(unpack(config.PowerValueColor))
	powerValue:SetJustifyH(config.PowerValueJustifyH)
	powerValue:SetJustifyV(config.PowerValueJustifyV)
	self:Tag(powerValue, prefix("[*:Power]"))

	self.Power.Value = powerValue

	-- ManaText Value
	-- *when mana isn't primary resource
	--------------------------------------------
	local manaText = power:CreateFontString(nil, "OVERLAY", nil, 1)
	manaText:SetPoint(unpack(config.ManaTextPosition))
	manaText:SetFontObject(config.ManaTextFont)
	manaText:SetTextColor(unpack(config.ManaTextColor))
	manaText:SetJustifyH(config.ManaTextJustifyH)
	manaText:SetJustifyV(config.ManaTextJustifyV)
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
	manaValue:SetPoint(unpack(config.ManaValuePosition))
	manaValue:SetFontObject(config.ManaValueFont)
	manaValue:SetTextColor(unpack(config.ManaValueColor))
	manaValue:SetJustifyH(config.ManaValueJustifyH)
	manaValue:SetJustifyV(config.ManaValueJustifyV)
	self:Tag(manaValue, prefix("[*:Mana]"))

	self.AdditionalPower.Value = manaValue

	-- CombatFeedback Text
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint(config.CombatFeedbackPosition[1], self[config.CombatFeedbackAnchorElement], unpack(config.CombatFeedbackPosition))
	feedbackText:SetFontObject(config.CombatFeedbackFont)
	feedbackText.feedbackFont = config.CombatFeedbackFont
	feedbackText.feedbackFontLarge = config.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = config.CombatFeedbackFontSmall

	self.CombatFeedback = feedbackText

	-- Combat Indicator
	--------------------------------------------
	local combatIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	combatIndicator:SetSize(unpack(config.CombatIndicatorSize))
	combatIndicator:SetPoint(unpack(config.CombatIndicatorPosition))
	combatIndicator:SetTexture(config.CombatIndicatorTexture)
	combatIndicator:SetVertexColor(unpack(config.CombatIndicatorColor))

	self.CombatIndicator = combatIndicator
	self.CombatIndicator.PostUpdate = CombatIndicator_PostUpdate

	-- PvP Indicator
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(unpack(config.PvPIndicatorSize))
	PvPIndicator:SetPoint(unpack(config.PvPIndicatorPosition))
	PvPIndicator.Alliance = config.PvPIndicatorAllianceTexture
	PvPIndicator.Horde = config.PvPIndicatorHordeTexture

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Threat Indicator
	--------------------------------------------
	local threatIndicator = CreateFrame("Frame", nil, self)
	threatIndicator:SetFrameLevel(self:GetFrameLevel() - 2)
	threatIndicator:SetAllPoints()

	threatIndicator.textures = {
		Health = threatIndicator:CreateTexture(nil, "BACKGROUND", nil, -3),
		PowerBar = power:CreateTexture(nil, "BACKGROUND", nil, -3),
		PowerBackdrop = power:CreateTexture(nil, "ARTWORK", nil, 1),
		ManaOrb = mana:CreateTexture(nil, "BACKGROUND", nil, -3),
	}
	threatIndicator.Show = function(self)
		self.isShown = true
		for key,texture in next,self.textures do
			texture:Show()
		end
	end
	threatIndicator.Hide = function(self)
		self.isShown = nil
		for key,texture in next,self.textures do
			texture:Hide()
		end
	end
	threatIndicator.PostUpdate = function(self, unit, status, r, g, b)
		if (self.isShown) then
			for key,texture in next,self.textures do
				texture:SetVertexColor(r, g, b)
			end
		end
	end

	self.ThreatIndicator = threatIndicator

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(unpack(config.AurasSize))
	auras:SetPoint(unpack(config.AurasPosition))
	auras.size = config.AuraSize
	auras.spacing = config.AuraSpacing
	auras.numTotal = config.AurasNumTotal
	auras.disableMouse = config.AurasDisableMouse
	auras.disableCooldown = config.AurasDisableCooldown
	auras.onlyShowPlayer = config.AurasOnlyShowPlayer
	auras.showStealableBuffs = config.AurasShowStealableBuffs
	auras.initialAnchor = config.AurasInitialAnchor
	auras["spacing-x"] = config.AurasSpacingX
	auras["spacing-y"] = config.AurasSpacingY
	auras["growth-x"] = config.AurasGrowthX
	auras["growth-y"] = config.AurasGrowthY
	auras.tooltipAnchor = config.AurasTooltipAnchor
	auras.sortMethod = config.AurasSortMethod
	auras.sortDirection = config.AurasSortDirection
	auras.CreateButton = ns.AuraStyles.CreateButton
	auras.reanchorIfVisibleChanged = true
	auras.PostUpdateButton = ns.AuraStyles.PlayerPostUpdateButton
	auras.CustomFilter = ns.AuraFilters.PlayerAuraFilter -- classic
	auras.FilterAura = ns.AuraFilters.PlayerAuraFilter -- retail
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
	auras.showDebuffType = true

	self.Auras = auras

	-- Seasonal Flavors
	--------------------------------------------
	-- Feast of Winter Veil
	if (ns.API.IsWinterVeil()) then
		local winterVeilPower = power:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilPower:SetSize(unpack(config.Seasonal.WinterVeilPowerSize))
		winterVeilPower:SetPoint(unpack(config.Seasonal.WinterVeilPowerPlace))
		winterVeilPower:SetTexture(config.Seasonal.WinterVeilPowerTexture)

		self.Power.WinterVeil = winterVeilPower

		local winterVeilMana = manaCaseFrame:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilMana:SetSize(unpack(config.Seasonal.WinterVeilManaSize))
		winterVeilMana:SetPoint(unpack(config.Seasonal.WinterVeilManaPlace))
		winterVeilMana:SetTexture(config.Seasonal.WinterVeilManaTexture)

		self.AdditionalPower.WinterVeil = winterVeilMana
	end

	-- Love is in the Air
	if (ns.API.IsLoveFestival()) then
		combatIndicator:SetSize(unpack(config.Seasonal.LoveFestivalCombatIndicatorSize))
		combatIndicator:ClearAllPoints()
		combatIndicator:SetPoint(unpack(config.Seasonal.LoveFestivalCombatIndicatorPosition))
		combatIndicator:SetTexture(config.Seasonal.LoveFestivalCombatIndicatorTexture)
		combatIndicator:SetVertexColor(unpack(config.Seasonal.LoveFestivalCombatIndicatorColor))
	end

	-- Register events to handle texture updates.
	self:RegisterEvent("PLAYER_ALIVE", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("DISABLE_XP_GAIN", UnitFrame_OnEvent, true)
	self:RegisterEvent("ENABLE_XP_GAIN", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", UnitFrame_OnEvent, true)

	if (ns.IsRetail) then
		--self:RegisterEvent("UNIT_HEALTH", UnitFrame_OnEvent)
		--self:RegisterEvent("UNIT_MAXHEALTH", UnitFrame_OnEvent)
		--self:RegisterEvent("UNIT_HEAL_PREDICTION", UnitFrame_OnEvent)
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", UnitFrame_OnEvent)
		--self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", UnitFrame_OnEvent)

		if (playerClass == "PALADIN") then
			self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", UnitFrame_OnEvent)
		end
	end

	-- Textures need an update when frame is displayed.
	self.PostUpdate = UnitFrame_PostUpdate

end

PlayerFrameMod.CreateUnitFrames = function(self)

	local unit, name = "player", "Player"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = ns.UnitFrame.Spawn(unit, ns.Prefix.."UnitFrame"..name)

	-- Vehicle switching is currently broken in Wrath.
	-- EDIT: Is it still?
	if (ns.IsWrath) then
		self.frame:SetAttribute("toggleForVehicle", false)
		RegisterAttributeDriver(self.frame, "unit", "[vehicleui] vehicle; player")
	end

end

PlayerFrameMod.Update = function(self)

	if (self.db.profile.showAuras) then
		self.frame:EnableElement("Auras")
		self.frame.Auras:ForceUpdate()
	else
		self.frame:DisableElement("Auras")
	end

	if (self.db.profile.showCastbar) then
		self.frame:EnableElement("Castbar")
		self.frame.Castbar:ForceUpdate()
	else
		self.frame:DisableElement("Castbar")
	end

end

PlayerFrameMod.OnEnable = function(self)

	-- Disable Blizzard player alternate power bar,
	-- as we're integrating this into the standard power crystal.
	if (PlayerPowerBarAlt) then
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
		PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end

	self:CreateUnitFrames()
	self:CreateAnchor(HUD_EDIT_MODE_PLAYER_FRAME_LABEL or PLAYER)

	ns.Module.OnEnable(self)
end
