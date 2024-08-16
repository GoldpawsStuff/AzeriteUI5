--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

--if (not ns.IsDevelopment) then return end

local PlayerFrameAltMod = ns:NewModule("PlayerFrameAlternate", ns.UnitFrameModule, "LibMoreEvents-1.0")

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors

-- Constants
local playerLevel = UnitLevel("player")

local defaults = { profile = ns:Merge({
	enabled = false,
	showAuras = true,
	showCastbar = true,
	showName = true,
	aurasBelowFrame = false
}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
PlayerFrameAltMod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = 38 * ns.API.GetEffectiveScale(),
		[3] = 42 * ns.API.GetEffectiveScale()
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

		if (growth == "RIGHT") then

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(curHealth/maxHealth, curHealth/maxHealth + change, 0, 1)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				element:SetTexCoord(curHealth/maxHealth, curHealth/maxHealth + change, 0, 1)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end

		elseif (growth == "LEFT") then

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("TOPRIGHT", previewTexture, "TOPLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(1 - (1 - (curHealth/maxHealth + change)), 1 - (1 - curHealth/maxHealth), 0, 1)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("TOPLEFT", previewTexture, "TOPLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(1 - (1 - (curHealth/maxHealth + change)), 1 - (1 - curHealth/maxHealth), 0, 1)
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

-- Use custom colors for our power crystal. Does not apply to the Wrath crystal.
local Power_PostUpdateColor = function(element, unit, r, g, b)
	local config = ns.GetConfig("PlayerFrameAlternate")

	local _, pToken = UnitPowerType(unit)
	local color = pToken and config.PowerBarColors[pToken]
	if (color) then
		element:SetStatusBarColor(color[1], color[2], color[3])
	end
end

-- Hide power crystal when no power exists.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	if (UnitIsDeadOrGhost(unit) or max == 0 or cur == 0) then
		element:Hide()
		element.Backdrop:Hide()
		element.Value:Hide()
	else
		element:Show()
		element.Backdrop:Show()
		element.Value:Show()
	end
end

-- Make the portrait look better for offline or invisible units.
local Portrait_PostUpdate = function(element, unit, hasStateChanged)
	if (not element.state) then
		element:ClearModel()
		if (not element.fallback2DTexture) then
			element.fallback2DTexture = element:CreateTexture()
			element.fallback2DTexture:SetDrawLayer("ARTWORK")
			element.fallback2DTexture:SetAllPoints()
			element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
		end
		SetPortraitTexture(element.fallback2DTexture, unit)
		element.fallback2DTexture:Show()
	else
		if (element.fallback2DTexture) then
			element.fallback2DTexture:Hide()
		end
		element:SetCamDistanceScale(element.distanceScale or 1)
		element:SetPortraitZoom(1)
		element:SetPosition(element.positionX or 0, element.positionY or 0, element.positionZ or 0)
		element:SetRotation(element.rotation and element.rotation*degToRad or 0)
		element:ClearModel()
		element:SetUnit(unit)
		element.guid = guid
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
	local currentStyle = element.__owner.currentStyle

	if (currentStyle == "Critter") then
		element.Text:Hide()
		element.Time:Hide()
		health.Value:Hide()
		health.Percent:Hide()
	elseif (element:IsShown()) then
		element.Text:Show()
		element.Time:Show()
		health.Value:Hide()
		health.Percent:Hide()
	else
		element.Text:Hide()
		element.Time:Hide()
		health.Value:Show()
		health.Percent:Show()
	end
end

-- Only show Horde/Alliance badges,
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.unit

	local l = UnitEffectiveLevel(unit)

	local status
	local factionGroup = UnitFactionGroup(unit) or "Neutral"
	if (factionGroup ~= "Neutral") then
		if (UnitIsPVPFreeForAll(unit)) then
		elseif (UnitIsPVP(unit)) then
			if (ns.IsRetail and UnitIsMercenary(unit)) then
				if (factionGroup == "Horde") then
					factionGroup = "Alliance"
				elseif (factionGroup == "Alliance") then
					factionGroup = "Horde"
				end
			end
			status = factionGroup
		end
	end

	if (status) then
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
	local config = ns.GetConfig("PlayerFrameAlternate")
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

	local portraitBorder = self.Portrait.Border
	portraitBorder:SetTexture(db.PortraitBorderTexture)
	portraitBorder:SetVertexColor(unpack(db.PortraitBorderColor))

	ns:Fire("UnitFrame_Target_Updated", unit, key)
end

local UnitFrame_UpdateAuraPosition = function(self)
	local config = PlayerFrameAltMod.db.profile
	local db = ns.GetConfig("PlayerFrameAlternate")

	local auras = self.Auras
	auras:ClearAllPoints()

	if (config.aurasBelowFrame) then
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

	else
		auras:SetSize(unpack(db.AurasSizeAlternate))
		auras:SetPoint(unpack(db.AurasPositionAlternate))
		auras.size = db.AuraSizeAlternate
		auras.spacing = db.AuraSpacingAlternate
		auras.numTotal = db.AurasNumTotalAlternate
		auras.disableMouse = db.AurasDisableMouseAlternate
		auras.disableCooldown = db.AurasDisableCooldownAlternate
		auras.onlyShowPlayer = db.AurasOnlyShowPlayerAlternate
		auras.showStealableBuffs = db.AurasShowStealableBuffsAlternate
		auras.initialAnchor = db.AurasInitialAnchorAlternate
		auras["spacing-x"] = db.AurasSpacingXAlternate
		auras["spacing-y"] = db.AurasSpacingYAlternate
		auras["growth-x"] = db.AurasGrowthXAlternate
		auras["growth-y"] = db.AurasGrowthYAlternate
		auras.tooltipAnchor = db.AurasTooltipAnchorAlternate
		auras.sortMethod = db.AurasSortMethodAlternate
		auras.sortDirection = db.AurasSortDirectionAlternate

	end

end

local UnitFrame_PostUpdate = function(self)
	UnitFrame_UpdateTextures(self)
	UnitFrame_UpdateAuraPosition(self)
end

-- Frame Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		playerLevel = UnitLevel("player")

	elseif (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED") then
		self.Auras:ForceUpdate()

	elseif (event == "PLAYER_LEVEL_UP") then
		playerLevel = UnitLevel("player")
	end
	UnitFrame_PostUpdate(self)
end

local style = function(self, unit, id)

	local db = ns.GetConfig("PlayerFrameAlternate")

	self:SetSize(unpack(db.Size))
	self:SetHitRectInsets(unpack(db.HitRectInsets))
	self:SetFrameLevel(self:GetFrameLevel() + 2)

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
	--health.colorDisconnected = true
	--health.colorTapping = true
	--health.colorThreat = true
	--health.colorClass = true
	--health.colorHappiness = true
	--health.colorReaction = true

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
	castText:SetPoint(unpack(db.HealthValuePosition))
	castText:SetFontObject(db.HealthValueFont)
	castText:SetTextColor(unpack(db.CastBarTextColor))
	castText:SetJustifyH(db.HealthValueJustifyH)
	castText:SetJustifyV(db.HealthValueJustifyV)
	castText:Hide()
	castText.color = db.CastBarTextColor
	castText.colorProtected = db.CastBarTextProtectedColor

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
	if (ns.IsRetail) then
		self:Tag(healthValue, prefix("[*:Health]  [*:Absorb]"))
	else
		self:Tag(healthValue, prefix("[*:Health]"))
	end

	self.Health.Value = healthValue

	-- Health Percentage
	--------------------------------------------
	local healthPerc = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthPerc:SetPoint(unpack(db.HealthPercentagePosition))
	healthPerc:SetFontObject(db.HealthPercentageFont)
	healthPerc:SetTextColor(unpack(db.HealthPercentageColor))
	healthPerc:SetJustifyH(db.HealthPercentageJustifyH)
	healthPerc:SetJustifyV(db.HealthPercentageJustifyV)
	self:Tag(healthPerc, prefix("[*:HealthPercent]"))

	self.Health.Percent = healthPerc

	-- Absorb Bar
	--------------------------------------------
	if (ns.IsRetail) then
		local absorb = self:CreateBar()
		absorb:SetAllPoints(health)
		absorb:SetFrameLevel(health:GetFrameLevel() + 3)

		self.HealthPrediction.absorbBar = absorb
	end

	-- Portrait
	--------------------------------------------
	local portraitFrame = CreateFrame("Frame", nil, self)
	portraitFrame:SetFrameLevel(self:GetFrameLevel() - 2)
	portraitFrame:SetAllPoints()

	local portrait = CreateFrame("PlayerModel", nil, portraitFrame)
	portrait:SetFrameLevel(portraitFrame:GetFrameLevel())
	portrait:SetPoint(unpack(db.PortraitPosition))
	portrait:SetSize(unpack(db.PortraitSize))
	portrait:SetAlpha(db.PortraitAlpha)
	portrait.distanceScale = db.PortraitDistanceScale
	portrait.positionX = db.PortraitPositionX
	portrait.positionY = db.PortraitPositionY
	portrait.positionZ = db.PortraitPositionZ
	portrait.rotation = db.PortraitRotation
	portrait.showFallback2D = db.PortraitShowFallback2D

	self.Portrait = portrait
	self.Portrait.PostUpdate = Portrait_PostUpdate

	local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBg:SetPoint(unpack(db.PortraitBackgroundPosition))
	portraitBg:SetSize(unpack(db.PortraitBackgroundSize))
	portraitBg:SetTexture(db.PortraitBackgroundTexture)
	portraitBg:SetVertexColor(unpack(db.PortraitBackgroundColor))

	self.Portrait.Bg = portraitBg

	local portraitOverlayFrame = CreateFrame("Frame", nil, self)
	portraitOverlayFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	portraitOverlayFrame:SetAllPoints()

	local portraitShade = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetPoint(unpack(db.PortraitShadePosition))
	portraitShade:SetSize(unpack(db.PortraitShadeSize))
	portraitShade:SetTexture(db.PortraitShadeTexture)

	self.Portrait.Shade = portraitShade

	local portraitBorder = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetPoint(unpack(db.PortraitBorderPosition))
	portraitBorder:SetSize(unpack(db.PortraitBorderSize))

	self.Portrait.Border = portraitBorder

	-- Power Crystal
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(self:GetFrameLevel() + 5)
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetSparkTexture(db.PowerBarSparkTexture)
	power:SetOrientation(db.PowerBarOrientation)
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetAlpha(db.PowerBarAlpha or 1)
	power.frequentUpdates = true
	power.displayAltPower = true
	--power.colorPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility
	self.Power.PostUpdateColor = Power_PostUpdateColor

	local powerBackdropGroup = CreateFrame("Frame", nil, self)
	powerBackdropGroup:SetAllPoints(power)
	powerBackdropGroup:SetFrameLevel(power:GetFrameLevel())

	local powerBackdrop = powerBackdropGroup:CreateTexture(nil, "BACKGROUND", nil, -2)
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetTexture(db.PowerBackdropTexture)
	powerBackdrop:SetVertexColor(unpack(db.PowerBackdropColor))

	self.Power.Backdrop = powerBackdrop

	-- Power Value Text
	--------------------------------------------
	local powerOverlayGroup = CreateFrame("Frame", nil, self)
	powerOverlayGroup:SetAllPoints(power)
	powerOverlayGroup:SetFrameLevel(power:GetFrameLevel() + 1)

	local powerValue = powerOverlayGroup:CreateFontString(nil, "OVERLAY", nil, 1)
	powerValue:SetPoint(unpack(db.PowerValuePosition))
	powerValue:SetJustifyH(db.PowerValueJustifyH)
	powerValue:SetJustifyV(db.PowerValueJustifyV)
	powerValue:SetFontObject(db.PowerValueFont)
	powerValue:SetTextColor(unpack(db.PowerValueColor))
	self:Tag(powerValue, prefix("[*:Power]"))

	self.Power.Value = powerValue

	-- CombatFeedback Text
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	feedbackText:SetFontObject(db.CombatFeedbackFont)
	feedbackText.feedbackFont = db.CombatFeedbackFont
	feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

	self.CombatFeedback = feedbackText

	-- PvP Indicator
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(unpack(db.PvPIndicatorSize))
	PvPIndicator:SetPoint(unpack(db.PvPIndicatorPosition))
	PvPIndicator.Alliance = db.PvPIndicatorAllianceTexture
	PvPIndicator.Horde = db.PvPIndicatorHordeTexture

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Threat Indicator
	--------------------------------------------
	local threatIndicator = CreateFrame("Frame", nil, self)
	threatIndicator:SetFrameLevel(self:GetFrameLevel() - 2)
	threatIndicator:SetAllPoints()
	threatIndicator.feedbackUnit = "player"

	threatIndicator.textures = {
		Health = threatIndicator:CreateTexture(nil, "BACKGROUND", nil, -3),
		Portrait = portrait:CreateTexture(nil, "BACKGROUND", nil, -1)
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

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint(unpack(db.NamePosition))
	name:SetFontObject(db.NameFont)
	name:SetTextColor(unpack(db.NameColor))
	name:SetJustifyH(db.NameJustifyH)
	name:SetJustifyV(db.NameJustifyV)
	name.tag = prefix("[*:Name(64,true,nil,true)]")
	self:Tag(name, name.tag)

	self.Name = name

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras.reanchorIfVisibleChanged = true
	auras.CreateButton = ns.AuraStyles.CreateButton
	auras.PostUpdateButton = ns.AuraStyles.PlayerPostUpdateButton
	auras.CustomFilter = ns.AuraFilters.PlayerAuraFilter -- classic
	auras.FilterAura = ns.AuraFilters.PlayerAuraFilter -- retail
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail

	self.Auras = auras

	-- Seasonal Flavors
	--------------------------------------------
	-- Love is in the Air
	if (ns.API.IsLoveFestival()) then


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

	-- Fix unresponsive alpha on 3D Portrait.
	hooksecurefunc(UIParent, "SetAlpha", function() self.Portrait:SetAlpha(self:GetEffectiveAlpha()) end)

	-- this won't work with the explorer mode, need a different solution
	--hooksecurefunc(self, "SetAlpha", function() self.Portrait:SetAlpha(self:GetEffectiveAlpha()) end)


	-- Textures need an update when frame is displayed.
	self.PostUpdate = UnitFrame_PostUpdate

end

PlayerFrameAltMod.CreateUnitFrames = function(self)

	local unit, name = "player", "PlayerAlternate"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = ns.UnitFrame.Spawn(unit, ns.Prefix.."UnitFrame"..name)

	local enabled = true

	self.frame.Enable = function(self)
		enabled = true
		RegisterAttributeDriver(self, "unit", "[vehicleui]vehicle; player")
		self:Show()
	end

	self.frame.Disable = function(self)
		enabled = false
		UnregisterAttributeDriver(self, "unit")
		self:Hide()
	end

	self.frame.IsEnabled = function(self)
		return enabled
	end

	UnregisterUnitWatch(self.frame)
	self.frame:SetAttribute("toggleForVehicle", false)
end

PlayerFrameAltMod.Update = function(self)

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

	self.frame.Name:SetShown(self.db.profile.showName)
	self.frame:PostUpdate()
end

PlayerFrameAltMod.PreInitialize = function(self)
	if (not ns.db.global.enableDevelopmentMode) then
		return self:Disable()
	end
end

PlayerFrameAltMod.PostInitialize = function(self)

	-- Forcedisable this unitframe
	-- if the standard playerframe is enabled.
	local PlayerFrame = ns:GetModule("PlayerFrame", true)
	if (PlayerFrame and PlayerFrame.db and PlayerFrame.db.profile.enabled) then
		self.db.profile.enabled = false
	end
end

PlayerFrameAltMod.OnEnable = function(self)

	-- Disable Blizzard player alternate power bar,
	-- as we're integrating this into the standard power crystal.
	if (PlayerPowerBarAlt) then
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
		PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end

	self:CreateUnitFrames()
	self:CreateAnchor("PlayerFrame (Alternate)")

	ns.MovableModulePrototype.OnEnable(self)
end
