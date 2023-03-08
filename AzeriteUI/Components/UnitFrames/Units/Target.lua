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

local TargetFrameMod = ns:Merge(ns:NewModule("TargetFrame", "LibMoreEvents-1.0"), ns.UnitFrame.modulePrototype)
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Constants
local playerLevel = UnitLevel("player")

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "TOPRIGHT",
			[2] = -40,
			[3] = -40
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

local bigBarSparkMap = {
	top = {
		{ keyPercent =    0/1024, offset = -24/64 },
		{ keyPercent =   13/1024, offset =   0/64 },
		{ keyPercent = 1018/1024, offset =   0/64 },
		{ keyPercent = 1024/1024, offset = -10/64 }
	},
	bottom = {
		{ keyPercent =    0/1024, offset = -39/64 },
		{ keyPercent =   13/1024, offset = -16/64 },
		{ keyPercent =  949/1024, offset = -16/64 },
		{ keyPercent =  977/1024, offset =  -1/64 },
		{ keyPercent =  984/1024, offset =  -2/64 },
		{ keyPercent = 1024/1024, offset = -52/64 }
	}
}

local tinyBarSparkMap = {
	top = {
		{ keyPercent =  0/64, offset = -30/64 },
		{ keyPercent = 14/64, offset =  -1/64 },
		{ keyPercent = 49/64, offset =  -1/64 },
		{ keyPercent = 64/64, offset = -34/64 }
	},
	bottom = {
		{ keyPercent =  0/64, offset = -30/64 },
		{ keyPercent = 15/64, offset =   0/64 },
		{ keyPercent = 32/64, offset =  -1/64 },
		{ keyPercent = 50/64, offset =  -4/64 },
		{ keyPercent = 64/64, offset = -27/64 }
	}
}

local config = {

	-- General Settings
	-----------------------------------------
	Size = { 439, 93 },
	--Position = { "TOPRIGHT", -153, -79 },
	HitRectInsets = { 0, -110, -40, -26 },
	IsFlippedHorizontally = true,

	-- Health Value Text
	HealthValuePosition = { "RIGHT", -27, 4 },
	HealthValueJustifyH = "RIGHT",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(18, true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- Health Percentage Text
	HealthPercentagePosition = { "LEFT", 27, 4 },
	HealthPercentageJustifyH = "CENTER",
	HealthPercentageJustifyV = "MIDDLE",
	HealthPercentageFont = GetFont(18, true),
	HealthPercentageColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

	-- Power Crystal
	PowerBarPosition = { "CENTER", 439/2 + 79 +2, -6+ 93/2 -62 + 4 +6 },
	PowerBarSize = { 80, 80 },
	PowerBarAlpha = .75,
	PowerBarTexture = GetMedia("power_crystal_small_front"),
	PowerBarSparkTexture = GetMedia("blank"),
	PowerBarOrientation = "UP",
	PowerBackdropSize = { 80, 80 },
	PowerBackdropPosition = { "CENTER", 0, 0 },
	PowerBackdropTexture = GetMedia("power_crystal_small_back"),
	PowerBackdropColor = { 1, 1, 1, .85 },

	-- Power Value Text
	PowerValuePosition = { "CENTER", 0, -5 },
	PowerValueJustifyH = "CENTER",
	PowerValueJustifyV = "MIDDLE",
	PowerValueFont = GetFont(14, true),
	PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- Castbar Name Text
	CastBarTextPosition = { "RIGHT", -27, 4 },
	CastBarTextSize = { 250, 40 },
	CastBarTextFont = GetFont(16, true),
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
	CastBarTextProtectedColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 },

	-- Castbar Value Text
	CastBarValuePosition = { "LEFT", 27, 4 },
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

	-- Unit Name
	NamePosition = { "BOTTOMRIGHT", -40, -12 },
	NameSize = { 250, 18 },
	NameJustifyH = "RIGHT",
	NameJustifyV = "TOP",
	NameFont = GetFont(18, true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Portrait
	PortraitPosition = { "TOPRIGHT", 73, 8 },
	PortraitSize = { 85, 85 },
	PortraitAlpha = .85,
	PortraitBackgroundPosition = { "TOPRIGHT", 116, 55 },
	PortraitBackgroundSize = { 173, 173 },
	PortraitBackgroundTexture = GetMedia("party_portrait_back"),
	PortraitBackgroundColor = { .5, .5, .5 },
	PortraitShadePosition = { "TOPRIGHT", 83, 21 },
	PortraitShadeSize = { 107, 107 },
	PortraitShadeTexture = GetMedia("shade-circle"),
	PortraitBorderPosition = { "TOPRIGHT", 123, 61 },
	PortraitBorderSize = { 187, 187 },

	-- PvP Indicator
	PvPIndicatorPosition = { "BOTTOMRIGHT", 72, -43 },
	PvPIndicatorSize = { 84, 84 },
	PvPIndicatorAllianceTexture = GetMedia("icon_badges_alliance"),
	PvPIndicatorHordeTexture = GetMedia("icon_badges_horde"),

	-- Classification
	ClassificationPosition = { "BOTTOMRIGHT", 72, -43 },
	ClassificationSize = { 84, 84 },
	ClassificationAllianceTexture = GetMedia("icon_badges_alliance"),
	ClassificationBossTexture = GetMedia("icon_badges_boss"),
	ClassificationEliteTexture = GetMedia("icon_classification_elite"),
	ClassificationHordeTexture = GetMedia("icon_badges_horde"),
	ClassificationRareTexture = GetMedia("icon_classification_rare"),

	-- Target Indicator
	TargetIndicatorPosition = { "TOPRIGHT", 38, 36 },
	TargetIndicatorSize = { 96, 48 },
	TargetIndicatorColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	TargetIndicatorPetByEnemyTexture = GetMedia("icon_target_blue"),
	TargetIndicatorYouByEnemyTexture = GetMedia("icon_target_red"),
	TargetIndicatorYouByFriendTexture = GetMedia("icon_target_green"),

	-- Auras
	-----------------------------------------
	AurasPosition = { "TOPRIGHT", -42, 36 },
	AurasSize = { 40*8 - 4, 40*2 - 4 },
	AurasSizeBoss = { 40*10 - 4, 40*2 - 4 },
	AuraSize = 36,
	AuraSpacing = 4,
	AurasNumTotal = 16,
	AurasNumTotalBoss = 20,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "TOPRIGHT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "LEFT",
	AurasGrowthY = "UP",
	AurasTooltipAnchor = "ANCHOR_BOTTOMLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Seasonal Overrides & Additions
	-----------------------------------------
	Seasonal = {
		-- Love Festival Target Eye
		LoveFestivalCombatIndicatorPosition = { "TOPRIGHT", 14, 36 },
		LoveFestivalTargetIndicatorSize = { 48, 48 },
		LoveFestivalTargetIndicatorPetByEnemyTexture = GetMedia("icon-heart-blue"),
		LoveFestivalTargetIndicatorYouByEnemyTexture = GetMedia("icon-heart-red"),
		LoveFestivalTargetIndicatorYouByFriendTexture = GetMedia("icon-heart-green"),
		LoveFestivalTargetIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },
	},

	-- Orb and Crystal Colors
	-----------------------------------------
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
	Critter = {

		-- Health Bar
		HealthBarSize = { 40, 36 },
		HealthBarPosition = { "TOPRIGHT", -24, -24 },
		HealthBarTexture = GetMedia("hp_critter_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = tinyBarSparkMap,
		HealthBackdropSize = { 98,96 },
		HealthBackdropPosition = { "CENTER", 0, 1 },
		HealthBackdropTexture = GetMedia("hp_critter_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_critter_case_glow"),

		PortraitBorderTexture = GetMedia("portrait_frame_lo"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	},
	Novice = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -27, -27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", -1, -.5 },
		HealthBackdropTexture = GetMedia("hp_low_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Portrait
		PortraitBorderTexture = GetMedia("portrait_frame_lo"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	},
	Hardened = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -27, -27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", -2, -1 },
		HealthBackdropTexture = GetMedia("hp_mid_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_mid_case_glow"),

		-- Portrait
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	},
	Seasoned = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -27, -27 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", -2, -1 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

		-- Portrait
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	},
	Boss = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -27, -27 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", -2, -1 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

		-- Portrait
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
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
		local min,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()

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

-- Use custom colors for our power crystal. Does not apply to Wrath.
local Power_UpdateColor = function(self, event, unit)
	if (self.unit ~= unit) then
		return
	end
	local element = self.Power
	local pType, pToken, altR, altG, altB = UnitPowerType(unit)
	if (pToken) then
		local color = config.PowerBarColors[pToken] or Colors.power[pToken]
		if (color) then
			element:SetStatusBarColor(unpack(color))
		end
	end
end

-- Hide power crystal when no power exists.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) or max == 0 or min == 0) then
		element:Hide()
	else
		element:Show()
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

-- Update NPC classification badge for rares, elites and bosses.
local Classification_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.Classification
	unit = unit or self.unit

	if (UnitIsPlayer(unit)) then
		return element:Hide()
	end
	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss") then
		element:SetTexture(element.bossTexture)
		element:Show()

	elseif (c == "elite") then
		element:SetTexture(element.eliteTexture)
		element:Show()

	elseif (c == "rare" or c == "rareelite") then
		element:SetTexture(element.rareTexture)
		element:Show()
	else
		element:Hide()
	end
end

-- Toggle name size based on ToT visibility
local Name_PostUpdate = function(self)
	local name = self.Name
	if (not name) then return end

	if (UnitExists("targettarget") and not UnitIsUnit("targettarget", "target") and not UnitIsUnit("targettarget","player")) then
		if (not name.usingSmallWidth) then
			name.usingSmallWidth = true
			self:Untag(name)
			self:Tag(name, prefix("[*:Name(30,true,nil,true)]"))
		end
	else
		if (name.usingSmallWidth) then
			name.usingSmallWidth = nil
			self:Untag(name)
			self:Tag(name, prefix("[*:Name(64,true,nil,true)]"))
		end
	end
end

-- Update target indicator texture.
local TargetIndicator_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.TargetIndicator
	unit = unit or self.unit

	local target = unit .. "target"
	if (not UnitExists(target) or UnitIsUnit(unit, "player")) then
		return element:Hide()
	end

	if (UnitCanAttack("player", unit)) then
		if (UnitIsUnit(target, "player")) then
			element:SetTexture(element.enemyTexture)
		elseif (UnitIsUnit(target, "pet")) then
			element:SetTexture(element.petTexture)
		else
			return element:Hide()
		end
	elseif (UnitIsUnit(target, "player")) then
		element:SetTexture(element.friendTexture)
	else
		return element:Hide()
	end

	element:Show()
end

local TargetIndicator_Start = function(self)
	local targetIndicator = self.TargetIndicator
	if (not targetIndicator.Ticker) then
		targetIndicator.Ticker = C_Timer.NewTicker(.1, function() TargetIndicator_Update(self) end)
	end
end

local TargetIndicator_Stop = function(self)
	local targetIndicator = self.TargetIndicator
	if (targetIndicator.Ticker) then
		targetIndicator.Ticker:Cancel()
		targetIndicator.Ticker = nil
		targetIndicator:Hide()
	end
end

-- Only show Horde/Alliance badges,
-- keep this hidding for rare-, elite- and boss NPCs.
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.unit

	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss" or c == "elite" or c == "rare") then
		return element:Hide()
	end

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
	local unit = self.unit
	if (not unit or not UnitExists(unit)) then
		return
	end

	local currentStyle = self.currentStyle
	local level = UnitIsUnit(unit, "player") and playerLevel or UnitEffectiveLevel(unit)

	local key
	if (UnitIsPlayer(unit)) then
		key = IsLevelAtEffectiveMaxLevel(level) and "Seasoned" or level < 10 and "Novice" or "Hardened"
	else
		if (UnitClassification(unit) == "worldboss") or (level < 1 and IsLevelAtEffectiveMaxLevel(playerLevel)) then
			key = "Boss"
		elseif (UnitCreatureType("target") == "Critter") or (level == 1 and UnitHealthMax(unit) < 30) then
			key = "Critter"
		else
			key = (level < 1 or IsLevelAtEffectiveMaxLevel(level)) and "Seasoned" or level < 10 and "Novice" or "Hardened"
		end
	end

	self.currentStyle = key

	if (key == currentStyle) then
		return
	end

	local isFlipped = config.IsFlippedHorizontally
	local db = config[key]

	local health = self.Health
	health:ClearAllPoints()
	health:SetPoint(unpack(db.HealthBarPosition))
	health:SetSize(unpack(db.HealthBarSize))
	health:SetStatusBarTexture(db.HealthBarTexture)
	health:SetOrientation(db.HealthBarOrientation)
	health:SetSparkMap(db.HealthBarSparkMap)
	health:SetFlippedHorizontally(isFlipped)

	local healthPreview = self.Health.Preview
	healthPreview:SetStatusBarTexture(db.HealthBarTexture)
	healthPreview:SetFlippedHorizontally(isFlipped)

	local healthBackdrop = self.Health.Backdrop
	healthBackdrop:ClearAllPoints()
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)
	healthBackdrop:SetVertexColor(unpack(db.HealthBackdropColor))
	healthBackdrop:SetTexCoord(isFlipped and 1 or 0, isFlipped and 0 or 1, 0, 1)

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
		absorb:SetFlippedHorizontally(isFlipped)
	end

	local cast = self.Castbar
	cast:ClearAllPoints()
	cast:SetPoint(unpack(db.HealthBarPosition))
	cast:SetSize(unpack(db.HealthBarSize))
	cast:SetStatusBarTexture(db.HealthBarTexture)
	cast:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	cast:SetOrientation(db.HealthBarOrientation)
	cast:SetSparkMap(db.HealthBarSparkMap)
	cast:SetFlippedHorizontally(isFlipped)

	local portraitBorder = self.Portrait.Border
	portraitBorder:SetTexture(db.PortraitBorderTexture)
	portraitBorder:SetVertexColor(unpack(db.PortraitBorderColor))

	if (key == "Critter" and currentStyle ~= "Critter") then
		health.Value:Hide()
		health.Percent:Hide()
		cast:ForceUpdate()
	elseif (key ~= "Critter" and currentStyle == "Critter") then
		health.Value:Show()
		health.Percent:Show()
		cast:ForceUpdate()
	end

	if (key == "Boss" and currentStyle ~= "Boss") then
		local db = config
		local auras = self.Auras
		auras.numTotal = db.AurasNumTotalBoss
		auras:SetSize(unpack(db.AurasSizeBoss))
		auras:ForceUpdate()

	elseif (key ~= "Boss" and currentStyle == "Boss") then
		local db = config
		local auras = self.Auras
		auras.numTotal = db.AurasNumTotal
		auras:SetSize(unpack(db.AurasSize))
		auras:ForceUpdate()
	end

end

local UnitFrame_PostUpdate = function(self)
	UnitFrame_UpdateTextures(self)
	Classification_Update(self)
	TargetIndicator_Update(self)
	TargetIndicator_Start(self)
end

-- Frame Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		playerLevel = UnitLevel("player")

	elseif (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED") then
		self.Auras:ForceUpdate()

	elseif (event == "PLAYER_LEVEL_UP") then
		local level = ...
		if (level and (level ~= playerLevel)) then
			playerLevel = level
		else
			local level = UnitLevel("player")
			if (level ~= playerLevel) then
				playerLevel = level
			end
		end
	end
	UnitFrame_PostUpdate(self)
end

local style = function(self, unit, id)

	local db = config

	self:SetSize(unpack(db.Size))
	self:SetHitRectInsets(unpack(db.HitRectInsets))
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
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = true
	--health.colorClassPet = true
	health.colorHappiness = true
	health.colorReaction = true

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)

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

		self.Health.Absorb = absorb
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
	power.colorPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility
	self.Power.UpdateColor = Power_UpdateColor

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -2)
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetIgnoreParentAlpha(true)
	powerBackdrop:SetTexture(db.PowerBackdropTexture)
	powerBackdrop:SetVertexColor(unpack(db.PowerBackdropColor))

	self.Power.Backdrop = powerBackdrop

	-- Power Value Text
	--------------------------------------------
	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 1)
	powerValue:SetPoint(unpack(db.PowerValuePosition))
	powerValue:SetJustifyH(db.PowerValueJustifyH)
	powerValue:SetJustifyV(db.PowerValueJustifyV)
	powerValue:SetIgnoreParentAlpha(true)
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

	-- Classification Badge
	--------------------------------------------
	local classification = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	classification:SetSize(unpack(db.ClassificationSize))
	classification:SetPoint(unpack(db.ClassificationPosition))
	classification.bossTexture = db.ClassificationBossTexture
	classification.eliteTexture = db.ClassificationEliteTexture
	classification.rareTexture = db.ClassificationRareTexture

	self.Classification = classification

	-- Target Indicator
	--------------------------------------------
	local targetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	targetIndicator:SetPoint(unpack(db.TargetIndicatorPosition))
	targetIndicator:SetSize(unpack(db.TargetIndicatorSize))
	targetIndicator:SetVertexColor(unpack(db.TargetIndicatorColor))
	targetIndicator.petTexture = db.TargetIndicatorPetByEnemyTexture
	targetIndicator.enemyTexture = db.TargetIndicatorYouByEnemyTexture
	targetIndicator.friendTexture = db.TargetIndicatorYouByFriendTexture

	self.TargetIndicator = targetIndicator

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint(unpack(db.NamePosition))
	name:SetFontObject(db.NameFont)
	name:SetTextColor(unpack(db.NameColor))
	name:SetJustifyH(db.NameJustifyH)
	name:SetJustifyV(db.NameJustifyV)
	self:Tag(name, prefix("[*:Name(64,true,nil,true)]"))

	self.Name = name

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
	auras.reanchorIfVisibleChanged = true
	auras.CreateButton = ns.AuraStyles.CreateButton
	auras.PostUpdateButton = ns.AuraStyles.TargetPostUpdateButton
	auras.CustomFilter = ns.AuraFilters.TargetAuraFilter -- classic
	auras.FilterAura = ns.AuraFilters.TargetAuraFilter -- retail
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail

	self.Auras = auras

	-- Seasonal Flavors
	--------------------------------------------
	-- Love is in the Air
	if (ns.API.IsLoveFestival()) then

		-- Target Indicator
		targetIndicator:ClearAllPoints()
		targetIndicator:SetPoint(unpack(db.Seasonal.LoveFestivalCombatIndicatorPosition))
		targetIndicator:SetSize(unpack(db.Seasonal.LoveFestivalTargetIndicatorSize))
		targetIndicator.petTexture = db.Seasonal.LoveFestivalTargetIndicatorPetByEnemyTexture
		targetIndicator.enemyTexture = db.Seasonal.LoveFestivalTargetIndicatorYouByEnemyTexture
		targetIndicator.friendTexture = db.Seasonal.LoveFestivalTargetIndicatorYouByFriendTexture
	end

	-- Textures need an update when frame is displayed.
	self.PostUpdate = UnitFrame_PostUpdate
	self.OnHide = TargetIndicator_Stop

	-- Register events to handle additional texture updates.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame_OnEvent, true)
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UnitFrame_OnEvent)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", UnitFrame_OnEvent, true)

	-- Toggle name size based on ToT frame.
	ns.RegisterCallback(self, "UnitFrame_ToT_Updated", Name_PostUpdate)

end

TargetFrameMod.Spawn = function(self)

	-- UnitFrame
	---------------------------------------------------
	local unit, name = "target", "Target"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = ns.UnitFrame.Spawn(unit, ns.Prefix.."UnitFrame"..name)

	-- Movable Frame Anchor
	---------------------------------------------------
	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(HUD_EDIT_MODE_TARGET_FRAME_LABEL or TARGET)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(550, 210)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor:SetEditModeAccountSetting(ns.IsRetail and Enum.EditModeAccountSetting.ShowTargetAndFocus)
	anchor.frameOffsetX = -113
	anchor.frameOffsetY = -39
	anchor.framePoint = "TOPRIGHT"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

TargetFrameMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("TargetFrame", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	if (MFM) then
		MFM:RegisterPresets(self.db.profile.savedPosition)
	end

	-- Disable Blizzard target frame.
	oUF:DisableBlizzard("target")
end
