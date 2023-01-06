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

LoadAddOn("Blizzard_NamePlates")

local NamePlatesMod = ns:NewModule("NamePlates", "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0")

-- Lua API
local math_floor = math.floor
local select = select
local string_gsub = string.gsub
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Constants
local playerClass = ns.PlayerClass

ns.ActiveNamePlates = {}
ns.NamePlates = {}

local defaults = {
	profile = {
		enabled = true,
		scale = 1
	}
}

local barSparkMap = {
	top = {
		{ keyPercent =   0/256, offset = -16/32 },
		{ keyPercent =   4/256, offset = -16/32 },
		{ keyPercent =  19/256, offset =   0/32 },
		{ keyPercent = 236/256, offset =   0/32 },
		{ keyPercent = 256/256, offset = -16/32 }
	},
	bottom = {
		{ keyPercent =   0/256, offset = -16/32 },
		{ keyPercent =   4/256, offset = -16/32 },
		{ keyPercent =  19/256, offset =   0/32 },
		{ keyPercent = 236/256, offset =   0/32 },
		{ keyPercent = 256/256, offset = -16/32 }
	}
}

local config = {

	Size = { 80, 32 },
	Orientation = "LEFT",
	OrientationReversed = "RIGHT",

	-- Health
	-----------------------------------------
	HealthBarPosition = { "TOP", 0, -2 },
	HealthBarSize = { 84, 14 },
	HealthBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	HealthBarTexture = GetMedia("nameplate_bar"),
	HealthBarSparkMap = barSparkMap,
	HealthAbsorbColor = { 1, 1, 1, .35 },
	HealthCastOverlayColor = { 1, 1, 1, .35 },

	HealthBackdropPosition = { "CENTER", 0, 0 },
	HealthBackdropSize = { 94.315789474, 24.888888889 },
	HealthBackdropTexture = GetMedia("nameplate_backdrop"),

	HealthValuePosition = { "TOP", 0, -18 },
	HealthValueJustifyH = "CENTER",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(12,true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- CastBar
	-----------------------------------------
	CastBarPosition = { "TOP", 0, -20 },
	CastBarPositionPlayer = { "TOP", 0, -(2 + 18 + 18) },
	CastBarSize = { 84, 14 },
	CastBarSparkMap = barSparkMap,
	CastBarOrientation = "LEFT",
	CastBarOrientationPlayer = "RIGHT",
	CastBarTexture = GetMedia("nameplate_bar"),
	CastBarTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
	CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], 1 },

	CastBarBackdropPosition = { "CENTER", 0, 0 },
	CastBarBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
	CastBarBackdropTexture = GetMedia("nameplate_backdrop"),

	CastBarShieldPosition = { "CENTER", 0, -1 },
	CastBarShieldSize = { 124, 69 },
	CastBarShieldTexture = GetMedia("cast_back_spiked"),
	CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	CastBarNamePosition = { "TOP", 0, -18 },
	CastBarNameJustifyH = "CENTER",
	CastBarNameJustifyV = "MIDDLE",
	CastBarNameFont = GetFont(12, true),
	CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- PRD Power Bar
	-----------------------------------------
	PowerBarPosition = { "TOP", 0, -20 },
	PowerBarSize = { 84, 14 },
	PowerBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	PowerBarTexture = GetMedia("nameplate_bar"),
	PowerBarSparkMap = barSparkMap,
	PowerBarBackdropPosition = { "CENTER", 0, 0 },
	PowerBarBackdropSize = { 94.315789474, 24.888888889 },
	PowerBarBackdropTexture = GetMedia("nameplate_backdrop"),

	-- Unit Name
	-----------------------------------------
	NamePosition = { "TOP", 0, 16 },
	NameJustifyH = "CENTER",
	NameJustifyV = "MIDDLE",
	NameFont = GetFont(12,true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- Auras
	-----------------------------------------
	AurasPosition = { "BOTTOM", 0, 40 },
	AurasSize = { 30*3 - 4, 30*2 - 4 },
	AuraSize = 26,
	AuraSpacing = 4,
	AurasNumTotal = 6,
	AurasNumPerRow = 3,
	AurasDisableMouse = true,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = true,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "BOTTOMLEFT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "RIGHT",
	AurasGrowthY = "UP",
	AurasTooltipAnchor = "ANCHOR_TOPLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- NPC Classification
	-----------------------------------------
	ClassificationPosition = { "RIGHT", 18, -1 },
	ClassificationSize = { 40, 40 },
	ClassificationIndicatorBossTexture = GetMedia("icon_badges_boss"),
	ClassificationIndicatorEliteTexture = GetMedia("icon_classification_elite"),
	ClassificationIndicatorRareTexture = GetMedia("icon_classification_rare"),

	-- Raid Target Indicator
	-----------------------------------------
	RaidTargetPosition = { "BOTTOM", 0, 38 },
	RaidTargetSize = { 64, 64 },
	RaidTargetTexture = GetMedia("raid_target_icons"),

	-- Target Highlight
	-----------------------------------------
	TargetHighlightPosition = { "CENTER", 0, 0 },
	TargetHighlightSize = { 99.031578947, 29.866666667 },
	TargetHighlightTexture = GetMedia("nameplate_outline"),
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },

	-- Threat Glow
	-----------------------------------------
	ThreatPosition = { "CENTER", 0, 0 },
	ThreatSize = { 94.315789474, 24.888888889 },
	ThreatTexture = GetMedia("nameplate_glow")

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

-- Update power bar visibility if a frame
-- is the perrsonal resource display.
-- This callback only handles elements below the health bar.
local Power_PostUpdate = function(element, unit, cur, min, max)
	local self = element.__owner

	unit = unit or self.unit
	if (not unit) then
		return
	end

	local db = config
	local shouldShow

	if (self.isPRD) then
		if (not cur) then
			cur, max = UnitPower(unit), UnitPowerMax(unit)
		end
		if (cur and cur == 0) and (max and max == 0) then
			shouldShow = nil
		else
			shouldShow = true
		end
	end

	local power = self.Power

	if (shouldShow) then
		if (power.isHidden) then
			power:SetAlpha(1)
			power.isHidden = false

			local cast = self.Castbar
			cast:ClearAllPoints()
			cast:SetPoint(unpack(db.CastBarPositionPlayer))
		end
	else
		if (not power.isHidden) then
			power:SetAlpha(0)
			power.isHidden = true

			local cast = self.Castbar
			cast:ClearAllPoints()
			cast:SetPoint(unpack(db.CastBarPosition))
		end
	end
end

-- Update targeting highlight outline
local TargetHighlight_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.TargetHighlight

	if (self.isFocus or self.isTarget) then
		element:SetVertexColor(unpack(self.isFocus and element.colorFocus or element.colorTarget))
		element:Show()
	else
		element:Hide()
	end
end

-- Messy callback that handles positions
-- of elements above the health bar.
local NamePlate_PostUpdatePositions = function(self)
	local db = config

	local auras = self.Auras
	local name = self.Name
	local raidTarget = self.RaidTargetIndicator

	if (self.isPRD) then

		--if (auras.numRows or auras.usingNameOffset ~= nil) then
		--	auras:ClearAllPoints()
		--	auras:SetPoint(unpack(db.AurasPosition))
		--	auras.numRows = nil
		--	auras.usingNameOffset = nil
		--end

	else

		local hasName = not self.isTarget and (self.isMouseOver or self.inCombat) or false
		local nameOffset = hasName and (select(2, name:GetFont()) + auras.spacing) or 0

		if (hasName ~= auras.usingNameOffset or auras.usingNameOffset == nil) then
			if (hasName) then
				local point, x, y = unpack(db.AurasPosition)
				auras:ClearAllPoints()
				auras:SetPoint(point, x, y + nameOffset)
			else
				auras:ClearAllPoints()
				auras:SetPoint(unpack(db.AurasPosition))
			end
		end

		local numAuras = #auras.sortedBuffs + #auras.sortedDebuffs
		local numRows = (numAuras > 0) and (math_floor(numAuras / auras.numPerRow)) or 0

		if (numRows ~= auras.numRows or hasName ~= auras.usingNameOffset or auras.usingNameOffset == nil) then
			if (hasName or numRows > 0) then
				local auraOffset = (numAuras > 0) and (numRows * (auras.size + auras.spacing)) or 0
				local point, x, y = unpack(db.RaidTargetPosition)
				raidTarget:ClearAllPoints()
				raidTarget:SetPoint(point, x, y + nameOffset + auraOffset)
			else
				raidTarget:ClearAllPoints()
				raidTarget:SetPoint(unpack(db.RaidTargetPosition))
			end
		end

		auras.numRows = numRows
		auras.usingNameOffset = hasName
	end
end

-- Element proxy for the position updater above.
local Auras_PostUpdate = function(element, unit)
	NamePlate_PostUpdatePositions(element.__owner)
end

-- Callback that handles positions of elements
-- that change position within their frame.
local NamePlate_PostUpdateElements = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	if (self.isPRD) then
		self:SetIgnoreParentAlpha(false)
		self.Health.Value:Hide()
		self.Name:Hide()
		if (self:IsElementEnabled("Auras")) then
			self:DisableElement("Auras")
		end
	else
		if (not self:IsElementEnabled("Auras")) then
			self:EnableElement("Auras")
			self.Auras:ForceUpdate()
		end
		if (self.isMouseOver or self.isTarget or self.inCombat) then
			-- SetIgnoreParentAlpha requires explicit true/false, or it'll bug out.
			self:SetIgnoreParentAlpha((self.isMouseOver and not self.isTarget) and true or false)
			if (self.isTarget) then
				self.Health.Value:Hide()
				self.Name:Hide()
			else
				self.Health.Value:Show()
				self.Name:Show()
			end
		else
			self:SetIgnoreParentAlpha(false)
			self.Health.Value:Hide()
			self.Name:Hide()
		end
	end

	NamePlate_PostUpdatePositions(self)
end

-- This is called on UpdateAllElements,
-- which is called when a frame is shown or its unit changed.
local NamePlate_PostUpdate = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	unit = unit or self.unit

	self.inCombat = InCombatLockdown()
	self.isFocus = UnitIsUnit(unit, "focus")
	self.isTarget = UnitIsUnit(unit, "target")

	local db = config
	local main, reverse = db.Orientation, db.OrientationReversed

	if (self.isPRD) then
		main, reverse = reverse, main
		self:DisableElement("RaidTargetIndicator")
	else
		self:EnableElement("RaidTargetIndicator")
		self.RaidTargetIndicator:ForceUpdate()
	end

	self.Castbar:SetOrientation(main)
	self.Power:SetOrientation(main)
	self.Health:SetOrientation(main)
	self.Health.Preview:SetOrientation(main)
	self.Health.Absorb:SetOrientation(reverse)

	TargetHighlight_Update(self, event, unit, ...)
	NamePlate_PostUpdateElements(self, event, unit, ...)
end

local NamePlate_OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
end

local NamePlate_OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
end

local NamePlate_OnHide = function(self)
	self.inCombat = nil
	self.isFocus = nil
	self.isTarget = nil
end

local NamePlate_OnEvent = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	unit = unit or self.unit

	if (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

		NamePlate_PostUpdateElements(self, event, unit, ...)

		return

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

		NamePlate_PostUpdateElements(self, event, unit, ...)

		return

	elseif (event == "PLAYER_TARGET_CHANGED") then
		self.isTarget = UnitIsUnit(unit, "target")

		TargetHighlight_Update(self, event, unit, ...)
		NamePlate_PostUpdateElements(self, event, unit, ...)

		return

	elseif (event == "PLAYER_FOCUS_CHANGED") then
		self.isFocus = UnitIsUnit(unit, "focus")

		TargetHighlight_Update(self, event, unit, ...)
		NamePlate_PostUpdateElements(self, event, unit, ...)

		return
	end

	NamePlate_PostUpdate(self, event, unit, ...)
end

local style = function(self, unit, id)

	local db = config

	self.colors = ns.Colors

	self:SetPoint("CENTER",0,0)
	self:SetSize(unpack(db.Size))
	self:SetFrameLevel(self:GetFrameLevel() + 2)

	self:SetScript("OnHide", NamePlate_OnHide)

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
	health:SetPoint(unpack(db.HealthBarPosition))
	health:SetSize(unpack(db.HealthBarSize))
	health:SetStatusBarTexture(db.HealthBarTexture)
	health:SetTexCoord(unpack(db.HealthBarTexCoord))
	health:SetSparkMap(db.HealthBarSparkMap)
	health.predictThreshold = .01
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = true
	health.colorClassPet = true
	health.colorHappiness = true
	health.colorReaction = true

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)

	self.Health.Backdrop = healthBackdrop

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetFrameLevel(overlay:GetFrameLevel())
	healthOverlay:SetAllPoints()

	self.Health.Overlay = healthOverlay

	local healthPreview = self:CreateBar(nil, health)
	healthPreview:SetAllPoints(health)
	healthPreview:SetFrameLevel(health:GetFrameLevel() - 1)
	healthPreview:SetStatusBarTexture(db.HealthBarTexture)
	healthPreview:SetSparkTexture("")
	healthPreview:SetAlpha(.5)
	healthPreview:DisableSmoothing(true)

	self.Health.Preview = healthPreview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)

	local healPredict = healPredictFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	healPredict:SetTexture(db.HealthBarTexture)
	healPredict.health = health
	healPredict.preview = healthPreview
	healPredict.maxOverflow = 1

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- Cast Overlay
	--------------------------------------------
	local castbar = self:CreateBar()
	castbar:SetAllPoints(health)
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:SetSparkMap(db.HealthBarSparkMap)
	castbar:SetStatusBarTexture(db.HealthBarTexture)
	castbar:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	castbar:SetTexCoord(unpack(db.HealthBarTexCoord))
	castbar:DisableSmoothing(true)

	self.Castbar = castbar

	-- Health Value
	--------------------------------------------
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint(unpack(db.HealthValuePosition))
	healthValue:SetFontObject(db.HealthValueFont)
	healthValue:SetTextColor(unpack(db.HealthValueColor))
	healthValue:SetJustifyH(db.HealthValueJustifyH)
	healthValue:SetJustifyV(db.HealthValueJustifyV)
	self:Tag(healthValue, prefix("[*:Health(true)]"))

	self.Health.Value = healthValue

	-- Power
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(health:GetFrameLevel() + 2)
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetTexCoord(unpack(db.PowerBarTexCoord))
	power:SetSparkMap(db.PowerBarSparkMap)
	power:SetAlpha(0)
	power.isHidden = true
	power.frequentUpdates = true
	power.displayAltPower = true
	power.colorPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_PostUpdate

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -1)
	powerBackdrop:SetPoint(unpack(db.PowerBarBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBarBackdropSize))
	powerBackdrop:SetTexture(db.PowerBarBackdropTexture)

	self.Power.Backdrop = powerBackdrop

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint(unpack(db.NamePosition))
	name:SetFontObject(db.NameFont)
	name:SetTextColor(unpack(db.NameColor))
	name:SetJustifyH(db.NameJustifyH)
	name:SetJustifyV(db.NameJustifyV)
	self:Tag(name, prefix("[*:Name(32,nil,nil,true)]"))

	self.Name = name

	-- Absorb Bar
	--------------------------------------------
	local absorb = self:CreateBar()
	absorb:SetAllPoints(health)
	absorb:SetFrameLevel(health:GetFrameLevel() + 3)
	absorb:SetStatusBarTexture(db.HealthBarTexture)
	absorb:SetStatusBarColor(unpack(db.HealthAbsorbColor))
	absorb:SetSparkMap(db.HealthBarSparkMap)

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

	self.Health.Absorb = absorb

	-- Target Highlight
	--------------------------------------------
	local targetHighlight = healthOverlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:SetPoint(unpack(db.TargetHighlightPosition))
	targetHighlight:SetSize(unpack(db.TargetHighlightSize))
	targetHighlight:SetTexture(db.TargetHighlightTexture)
	targetHighlight.colorTarget = db.TargetHighlightTargetColor
	targetHighlight.colorFocus = db.TargetHighlightFocusColor

	self.TargetHighlight = targetHighlight

	-- Raid Target Indicator
	--------------------------------------------
	local raidTarget = self:CreateTexture(nil, "OVERLAY", nil, 1)
	raidTarget:SetSize(unpack(db.RaidTargetSize))
	raidTarget:SetPoint(unpack(db.RaidTargetPosition))
	raidTarget:SetTexture(db.RaidTargetTexture)

	self.RaidTargetIndicator = raidTarget

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(unpack(db.AurasSize))
	auras:SetPoint(unpack(db.AurasPosition))
	auras.size = db.AuraSize
	auras.spacing = db.AuraSpacing
	auras.numTotal = db.AurasNumTotal
	auras.numPerRow = db.AurasNumPerRow -- for our raid target indicator callback
	auras.disableMouse = db.AurasDisableMouse
	auras.disableCooldown = db.AurasDisableCooldown
	auras.onlyShowPlayer = db.AurasOnlyShowPlayer
	auras.showStealableBuffs = db.AurasShowStealableBuffs
	auras.initialAnchor = db.AurasInitialAnchor
	auras["spacing-x"] = db.AurasSpacingX
	auras["spacing-y"] = db.AurasSpacingY
	auras["growth-x"] = db.AurasGrowthX
	auras["growth-y"] = db.AurasGrowthY
	auras.sortMethod = db.AurasSortMethod
	auras.sortDirection = db.AurasSortDirection
	auras.reanchorIfVisibleChanged = true
	auras.CustomFilter = ns.AuraFilters.NameplateAuraFilter
	auras.CreateButton = ns.AuraStyles.CreateSmallButton
	auras.PostUpdateButton = ns.AuraStyles.NameplatePostUpdateButton
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail

	self.Auras = auras
	self.Auras.PostUpdate = Auras_PostUpdate

	self.PostUpdate = NamePlate_PostUpdate
	self.OnEnter = NamePlate_PostUpdateElements
	self.OnLeave = NamePlate_PostUpdateElements
	--self.OnHide = NamePlate_OnHide

	-- Register events to handle additional texture updates.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", NamePlate_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", NamePlate_OnEvent, true)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", NamePlate_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", NamePlate_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", NamePlate_OnEvent, true)

end

local cvars = {
	-- If these are enabled the GameTooltip will become protected,
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these.
	["nameplateShowDebuffsOnFriendly"] = 0,

	["nameplateLargeTopInset"] = .15, -- default .1
	["nameplateOtherTopInset"] = .15, -- default .08
	["nameplateLargeBottomInset"] = .15, -- default .15
	["nameplateOtherBottomInset"] = .15, -- default .1
	["nameplateClassResourceTopInset"] = 0,

	-- new CVar July 14th 2020. Wohoo! Thanks torhaala for telling me! :)
	-- *has no effect in retail. probably for the classics only.
	--["clampTargetNameplateToScreen"] = 1,

	-- Nameplate scale
	["nameplateMinScale"] = .6, -- .8
	["nameplateMaxScale"] = 1,
	["nameplateLargerScale"] = 1, -- Scale modifier for large plates, used for important monsters
	["nameplateGlobalScale"] = 1,
	["NamePlateHorizontalScale"] = 1,
	["NamePlateVerticalScale"] = 1,

	["nameplateOccludedAlphaMult"] = .15, -- .4
	["nameplateSelectedAlpha"] = 1, -- 1

	-- The maximum distance from the camera where plates will still have max scale and alpha
	["nameplateMaxScaleDistance"] = 10, -- 10

	-- The distance from the max distance that nameplates will reach their minimum scale.
	-- *seems to be a limit on how big this can be, too big resets to 1 it seems?
	["nameplateMinScaleDistance"] = 10, -- 10

	-- The minimum alpha of nameplates.
	["nameplateMinAlpha"] = .4, -- 0.6

	-- The distance from the max distance that nameplates will reach their minimum alpha.
	["nameplateMinAlphaDistance"] = 10, -- 10

	-- 	The max alpha of nameplates.
	["nameplateMaxAlpha"] = 1, -- 1

	-- The distance from the camera that nameplates will reach their maximum alpha.
	["nameplateMaxAlphaDistance"] = 30, -- 40

	-- Show nameplates above heads or at the base (0 or 2,
	["nameplateOtherAtBase"] = 0,

	-- Scale and Alpha of the selected nameplate (current target,
	["nameplateSelectedScale"] = 1, -- 1.2

	-- The max distance to show nameplates.
	--["nameplateMaxDistance"] = 60, -- 20 is classic upper limit, 60 is BfA default

	-- The max distance to show the target nameplate when the target is behind the camera.
	["nameplateTargetBehindMaxDistance"] = 15, -- 15

	-- Don't show this crap.
	["nameplateResourceOnTarget"] = 0,
}

local callback = function(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
	elseif (event == "NAME_PLATE_UNIT_ADDED") then

		self.isPRD = UnitIsUnit(unit, "player")

		ns.NamePlates[self] = true
		ns.ActiveNamePlates[self] = true

	elseif (event == "NAME_PLATE_UNIT_REMOVED") then

		self.isPRD = nil
		self.inCombat = nil
		self.isFocus = nil
		self.isTarget = nil

		ns.ActiveNamePlates[self] = nil
	end
end

local MOUSEOVER
local checkMouseOver = function()
	if (UnitExists("mouseover")) then
		if (MOUSEOVER) then
			if (UnitIsUnit(MOUSEOVER.unit, "mouseover")) then
				return
			end
			NamePlate_OnLeave(MOUSEOVER)
			MOUSEOVER = nil
		end
		for frame in next,ns.ActiveNamePlates do
			if (UnitIsUnit(frame.unit, "mouseover")) then
				MOUSEOVER = frame
				return NamePlate_OnEnter(MOUSEOVER)
			end
		end
	elseif (MOUSEOVER) then
		NamePlate_OnLeave(MOUSEOVER)
		MOUSEOVER = nil
	end
end

NamePlatesMod.CheckForConflicts = function(self)
	for i,addon in next,{ Kui_Nameplates, NamePlateKAI, NeatPlates, Plater, SimplePlates, TidyPlates, TidyPlates_ThreatPlates, TidyPlatesContinued } do
		if (ns.API.IsAddOnEnabled(addon)) then
			return true
		end
	end
end

NamePlatesMod.HookNamePlates = function(self)

	local classNameplateManaBar = NamePlateDriverFrame.classNamePlatePowerBar
	if (classNameplateManaBar) then
		classNameplateManaBar:Hide()
		classNameplateManaBar:UnregisterAllEvents()
	end

	local classNamePlateMechanicFrame = NamePlateDriverFrame.classNamePlateMechanicFrame
	if (classNamePlateMechanicFrame) then
		classNamePlateMechanicFrame:Hide()
	end

	hooksecurefunc(NamePlateDriverFrame, "SetupClassNameplateBars", function(frame)
		if (not frame or frame:IsForbidden()) then
			return
		end
		if (frame.classNamePlateMechanicFrame) then
			frame.classNamePlateMechanicFrame:Hide()
		end
		if (frame.classNamePlatePowerBar) then
			frame.classNamePlatePowerBar:Hide()
			frame.classNamePlatePowerBar:UnregisterAllEvents()
		end
	end)

	hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", function()
		if (InCombatLockdown()) then return end
		C_NamePlate.SetNamePlateFriendlySize(unpack(config.Size))
		C_NamePlate.SetNamePlateEnemySize(unpack(config.Size))
		C_NamePlate.SetNamePlateSelfSize(unpack(config.Size))
	end)

end

NamePlatesMod.OnInitialize = function(self)
	if (self:CheckForConflicts()) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("NamePlates", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	oUF:RegisterStyle(ns.Prefix.."NamePlates", style)

	self:HookNamePlates()
end

NamePlatesMod.OnEnable = function(self)
	oUF:SetActiveStyle(ns.Prefix.."NamePlates")
	oUF:SpawnNamePlates(ns.Prefix, callback, cvars)

	self.mouseTimer = self:ScheduleRepeatingTimer(checkMouseOver, 1/20)
end
