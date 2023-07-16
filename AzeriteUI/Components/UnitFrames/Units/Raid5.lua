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

local RaidFrame5Mod = ns:NewModule("RaidFrame5", ns.UnitFrameModule, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: UIParent, Enum
-- GLOBALS: LoadAddOn, InCombatLockdown, RegisterAttributeDriver, UnregisterAttributeDriver
-- GLOBALS: UnitHasVehicleUI, UnitIsUnit, UnitPowerType
-- GLOBALS: CompactRaidFrameContainer, CompactRaidFrameManager, CompactRaidFrameManager_SetSetting

-- Lua API
local math_abs = math.abs
local next = next
local select = select
local string_gsub = string.gsub
local type = type
local unpack = unpack

local defaults = { profile = ns:Merge({

	enabled = true,

	point = "TOP", -- anchor point of unitframe, group members within column grow opposite
	xOffset = 0, -- horizontal offset within the same column
	yOffset = -12, -- vertical offset within the same column

	groupBy = "GROUP", -- GROUP, CLASS, ROLE
	groupingOrder = "1,2,3,4,5,6,7,8", -- must match choice in groupBy

	unitsPerColumn = 5, -- maximum units per column
	maxColumns = 1, -- should be 40/unitsPerColumn
	columnSpacing = 10, -- spacing between columns
	columnAnchorPoint = "LEFT" -- anchor point of column, columns grow opposite

}, ns.Module.defaults) }

RaidFrame5Mod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = -300 * ns.API.GetEffectiveScale(),
		[3] = 0 * ns.API.GetEffectiveScale()
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
			if (absorb > maxHealth * .3) then
				absorb = maxHealth * .3
			end
			element.absorbBar:SetValue(absorb)
		end
	end

end

local Power_PostUpdate = function(element, unit, cur, min, max)

	local shouldShow = not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana

	if (not shouldShow or cur == 0 or max == 0) then
		element:SetAlpha(0)
	else
		local _,class = UnitClass(unit)
		if (class == "DRUID" or class == "PALADIN" or class == "PRIEST" or class == "SHAMAN") then
			if (cur/max < .9) then
				element:SetAlpha(.75)
			else
				element:SetAlpha(0)
			end
		elseif (class == "MAGE" or class == "WARLOCK") then
			if (cur/max < .5) then
				element:SetAlpha(.75)
			else
				element:SetAlpha(0)
			end
		else
			-- The threshold for the "oom" message is .25 (not yet added!)
			if (cur/max < .25) then
				element:SetAlpha(.75)
			else
				element:SetAlpha(0)
			end
		end
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
		element:SetRotation(element.rotation and element.rotation*(2*math_pi)/180 or 0)
		element:ClearModel()
		element:SetUnit(unit)
		element.guid = UnitGUID(unit)
	end
end

-- Update targeting highlight outline
local TargetHighlight_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.TargetHighlight
	unit = unit or self.unit

	if (UnitIsUnit(unit, "target")) then
		element:SetVertexColor(unpack(element.colorTarget))
		element:Show()
	elseif (UnitIsUnit(unit, "focus")) then
		element:SetVertexColor(unpack(element.colorFocus))
		element:Show()
	else
		element:Hide()
	end
end

local UnitFrame_PostUpdate = function(self)
	--TargetHighlight_Update(self)
end

local UnitFrame_OnEvent = function(self, event, unit, ...)
	UnitFrame_PostUpdate(self)
end

local style = function(self, unit)

	local db = ns.GetConfig("Raid5Frames")

	-- Apply common scripts and member values.
	ns.UnitFrame.InitializeUnitFrame(self)
	ns.UnitFrames[self] = true -- add to our registry

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
	health:SetOrientation(db.HealthBarOrientation)
	health:SetSparkMap(db.HealthBarSparkMap)
	health.predictThreshold = .01
	health.colorDisconnected = true
	health.colorClass = true
	health.colorClassPet = true
	health.colorReaction = true
	health.colorHealth = true

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetFrameLevel(overlay:GetFrameLevel() - 1)
	healthOverlay:SetAllPoints()

	self.Health.Overlay = healthOverlay

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)
	healthBackdrop:SetVertexColor(unpack(db.HealthBackdropColor))

	self.Health.Backdrop = healthBackdrop

	local healthPreview = self:CreateBar(nil, health)
	healthPreview:SetAllPoints(health)
	healthPreview:SetFrameLevel(health:GetFrameLevel() - 1)
	healthPreview:SetStatusBarTexture(db.HealthBarTexture)
	healthPreview:SetOrientation(db.HealthBarOrientation)
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
	self:Tag(healthValue, prefix("[*:Health(true,false,false,true)]"))

	self.Health.Value = healthValue

	-- Power
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(health:GetFrameLevel() + 2)
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetOrientation(db.PowerBarOrientation)
	power:SetAlpha(db.PowerBarAlpha)
	power.frequentUpdates = true
	power.colorPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	--self.Power.PostUpdate = Power_PostUpdate

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -5)
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetTexture(db.PowerBackdropTexture)
	powerBackdrop:SetVertexColor(unpack(db.PowerBackdropColor))

	self.Power.Backdrop = powerBackdrop

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
	portraitOverlayFrame:SetFrameLevel(portraitFrame:GetFrameLevel() + 1)
	portraitOverlayFrame:SetAllPoints()

	local portraitShade = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetPoint(unpack(db.PortraitShadePosition))
	portraitShade:SetSize(unpack(db.PortraitShadeSize))
	portraitShade:SetTexture(db.PortraitShadeTexture)

	self.Portrait.Shade = portraitShade

	local portraitBorder = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetPoint(unpack(db.PortraitBorderPosition))
	portraitBorder:SetSize(unpack(db.PortraitBorderSize))
	portraitBorder:SetTexture(db.PortraitBorderTexture)
	portraitBorder:SetVertexColor(unpack(db.PortraitBorderColor))

	self.Portrait.Border = portraitBorder

	-- Absorb Bar (Retail)
	--------------------------------------------
	if (ns.IsRetail) then
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

		self.HealthPrediction.absorbBar = absorb
	end

	-- Dispellable Debuffs
	--------------------------------------------
	if (ns.IsDevelopment) then

		local Colors = ns.Colors
		local GetMedia = ns.API.GetMedia
		local GetFont = ns.API.GetFont

		local dispellable = {}
		dispellable.disableMouse = true

		local dispelIcon = CreateFrame("Button", self:GetName().."DispellableButton", healthOverlay)
		dispelIcon:Hide()
		dispelIcon:SetFrameLevel(overlay:GetFrameLevel() + 2)
		dispelIcon:SetSize(30,30)
		dispelIcon:SetPoint("RIGHT", 50, -2)
		dispellable.dispellIcon = dispelIcon

		local dispelIconBorder = CreateFrame("Frame", nil, dispelIcon, ns.BackdropTemplate)
		dispelIconBorder:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
		dispelIconBorder:SetBackdropBorderColor(Colors.aura[1], Colors.aura[2], Colors.aura[3])
		dispelIconBorder:SetPoint("TOPLEFT", -6, 6)
		dispelIconBorder:SetPoint("BOTTOMRIGHT", 6, -6)
		dispelIconBorder:SetFrameLevel(dispelIcon:GetFrameLevel() + 2)
		--dispelIcon.overlay = dispelIconBorder

		local dispelIconTexture = dispelIcon:CreateTexture(nil, "BACKGROUND", nil, 1)
		dispelIconTexture:SetAllPoints()
		dispelIconTexture:SetMask(GetMedia("actionbutton-mask-square"))
		dispelIcon.icon = dispelIconTexture

		local dispelIconTime = dispelIconBorder:CreateFontString(nil, "OVERLAY")
		dispelIconTime:SetFontObject(GetFont(14,true))
		dispelIconTime:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		dispelIconTime:SetPoint("TOPLEFT", dispelIcon, "TOPLEFT", -4, 4)
		dispelIcon.time = dispelIconTime

		local dispelIconCount = dispelIconBorder:CreateFontString(nil, "OVERLAY")
		dispelIconCount:SetFontObject(GetFont(12,true))
		dispelIconCount:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		dispelIconCount:SetPoint("BOTTOMRIGHT", dispelIcon, "BOTTOMRIGHT", -2, 3)
		dispelIcon.count = dispelIconCount

		-- Using a virtual cooldown element with the timer attached,
		-- allowing them to piggyback on the back-end's cooldown updates.
		dispelIcon.cd = ns.Widgets.RegisterCooldown(dispelIcon.time)

		local dispelTexture = {
			UpdateColor = function(dispelTexture, debuffType, r, g, b, a)
				dispelIconBorder:SetBackdropBorderColor(r, g, b)
			end
		}
		dispellable.dispelTexture = dispelTexture

		self.Dispellable = dispellable

	end

	-- Readycheck
	--------------------------------------------
	local readyCheckIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
	readyCheckIndicator:SetSize(unpack(db.ReadyCheckSize))
	readyCheckIndicator:SetPoint(unpack(db.ReadyCheckPosition))
	readyCheckIndicator.readyTexture = db.ReadyCheckReadyTexture
	readyCheckIndicator.notReadyTexture = db.ReadyCheckNotReadyTexture
	readyCheckIndicator.waitingTexture = db.ReadyCheckWaitingTexture

	self.ReadyCheckIndicator = readyCheckIndicator

	-- CombatFeedback Text
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	feedbackText:SetFontObject(db.CombatFeedbackFont)
	feedbackText.feedbackFont = db.CombatFeedbackFont
	feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

	self.CombatFeedback = feedbackText

	-- Target Highlight
	--------------------------------------------
	--local targetHighlight = healthOverlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	--targetHighlight:SetPoint(unpack(db.TargetHighlightPosition))
	--targetHighlight:SetSize(unpack(db.TargetHighlightSize))
	--targetHighlight:SetTexture(db.TargetHighlightTexture)
	--targetHighlight.colorTarget = db.TargetHighlightTargetColor
	--targetHighlight.colorFocus = db.TargetHighlightFocusColor

	--self.TargetHighlight = targetHighlight

	-- Unit Name
	--------------------------------------------
	local name = overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint(unpack(db.NamePosition))
	name:SetFontObject(db.NameFont)
	name:SetTextColor(unpack(db.NameColor))
	name:SetJustifyH(db.NameJustifyH)
	name:SetJustifyV(db.NameJustifyV)
	self:Tag(name, prefix("[*:Name(12,nil,nil,true)]"))

	self.Name = name

	-- Trinket Icon
	--------------------------------------------
	local trinket = CreateFrame("Frame", nil, self)
	trinket:SetSize(unpack(db.TrinketFrameSize))
	trinket:SetPoint(unpack(db.TrinketFramePosition))
	trinket:SetFrameLevel(portraitOverlayFrame:GetFrameLevel())

	local trinketIcon = trinket:CreateTexture(nil, "BACKGROUND", nil, -2)
	trinketIcon:SetPoint(unpack(db.TrinketIconPositon))
	trinketIcon:SetSize(unpack(db.TrinketIconSize))
	trinketIcon:SetMask(db.TrinketIconMask)

	local b,m = ns.API.GetMedia("blank"), db.TrinketIconMask
	local trinketCooldown = CreateFrame("Cooldown", nil, trinket)
	trinketCooldown:SetFrameLevel(portraitOverlayFrame:GetFrameLevel() + 1)
	trinketCooldown:SetAllPoints(trinketIcon)
	trinketCooldown:SetUseCircularEdge(true)
	trinketCooldown:SetReverse(false)
	trinketCooldown:SetSwipeTexture(m)
	trinketCooldown:SetDrawSwipe(true)
	trinketCooldown:SetBlingTexture(b, 0, 0, 0, 0)
	trinketCooldown:SetDrawBling(false)
	trinketCooldown:SetEdgeTexture(b)
	trinketCooldown:SetDrawEdge(false)
	trinketCooldown:SetHideCountdownNumbers(true)

	ns.Widgets.RegisterCooldown(trinketCooldown)

	hooksecurefunc(trinketCooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(trinketCooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(trinketCooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	hooksecurefunc(trinketCooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(trinketCooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(trinketCooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(trinketCooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(trinketCooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	self.Trinket = trinket
	self.Trinket.cc = trinketCooldown
	self.Trinket.icon = trinketIcon

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
	auras.PostUpdateButton = ns.AuraStyles.ArenaPostUpdateButton
	auras.CustomFilter = ns.AuraFilters.ArenaAuraFilter -- classic
	auras.FilterAura = ns.AuraFilters.ArenaAuraFilter -- retail

	if (ns:GetModule("UnitFrames").db.global.disableAuraSorting) then
		auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
		auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
	else
		auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
		auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
	end

	self.Auras = auras

	-- Range Opacity
	-----------------------------------------------------------
	self.Range = { outsideAlpha = .6 }

	-- Textures need an update when frame is displayed.
	self.PostUpdate = UnitFrame_PostUpdate

	-- Register events to handle additional texture updates.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame_OnEvent, true)

end

-- GroupHeader Template
---------------------------------------------------
local GroupHeader = {}

GroupHeader.ForAll = function(self, methodOrFunc, ...)
	for i = 1, self:GetNumChildren() do
		local frame = select(i, self.frame:GetChildren())
		if (type(methodOrFunc) == "string") then
			frame[methodOrFunc](frame, ...)
		else
			methodOrFunc(frame, ...)
		end
	end
end

GroupHeader.Enable = function(self)
	if (InCombatLockdown()) then return end

	local visibility = RaidFrame5Mod:GetVisibilityDriver()

	UnregisterAttributeDriver(self, "state-visibility")
	RegisterAttributeDriver(self, "state-visibility", visibility)

	self.visibility = visibility
end

GroupHeader.Disable = function(self)
	if (InCombatLockdown()) then return end

	UnregisterAttributeDriver(self, "state-visibility")
	RegisterAttributeDriver(self, "state-visibility", "hide")

	self.visibility = nil
end

GroupHeader.IsEnabled = function(self)
	return self.visibility and true or false
end

RaidFrame5Mod.DisableBlizzard = function(self)
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	CompactRaidFrameManager_SetSetting("IsShown", "0")

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:SetParent(ns.Hider)
end

RaidFrame5Mod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		if (self.needHeaderUpdate) then
			self.needHeaderUpdate = nil
			self:UpdateHeader()
		end
	end
end

RaidFrame5Mod.GetHeaderAttributes = function(self)
	local db = self.db.profile

	return ns.Prefix.."Raid", nil, nil,
	"initial-width", ns.GetConfig("Raid5Frames").UnitSize[1],
	"initial-height", ns.GetConfig("Raid5Frames").UnitSize[2],
	"oUF-initialConfigFunction", [[
		local header = self:GetParent();
		self:SetWidth(header:GetAttribute("initial-width"));
		self:SetHeight(header:GetAttribute("initial-height"));
		self:SetFrameLevel(self:GetFrameLevel() + 10);
	]],

	--'https://wowprogramming.com/docs/secure_template/Group_Headers.html
	"sortMethod", "INDEX", -- INDEX, NAME -- Member sorting within each group
	"sortDir", "ASC", -- ASC, DESC
	"groupFilter", "1,2,3,4,5,6,7,8", -- Group filter
	"showSolo", false, -- show while non-grouped
	"showPlayer", true, -- show the player while in a party
	"showRaid", true, -- show while in a raid group
	"showParty", true, -- show while in a party
	"point", db.point, -- Unit anchoring within each column
	"xOffset", db.xOffset,
	"yOffset", db.yOffset,
	"groupBy", db.groupBy, -- ROLE, CLASS, GROUP -- Grouping order and type
	"groupingOrder", db.groupingOrder,
	"unitsPerColumn", db.unitsPerColumn, -- Column setup and growth
	"maxColumns", db.maxColumns,
	"columnSpacing", db.columnSpacing,
	"columnAnchorPoint", db.columnAnchorPoint

end

RaidFrame5Mod.GetVisibilityDriver = function(self)
	local party = ns:GetModule("PartyFrames").db.profile.enabled
	local raid5 = ns:GetModule("RaidFrame5").db.profile.enabled
	local raid25 = ns:GetModule("RaidFrame25").db.profile.enabled
	local raid40 = ns:GetModule("RaidFrame40").db.profile.enabled

	-- Hide in groups of 6 or more.
	local driver = "custom [@raid6,exists]hide;"

	-- Show in raids of 1-5 and in parties if party frames are disabled..
	if (party) then
		driver = driver .. "[group:raid]show;"
	else
		driver = driver .. "[group]show;"
	end

	driver = driver.."hide"

	return driver
end

RaidFrame5Mod.UpdateHeader = function(self)
	if (not self.frame) then return end
	if (InCombatLockdown()) then
		self.needHeaderUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		return
	end
	for _,attrib in next,{
		"point",
		"xOffset",
		"yOffset",
		"groupBy",
		"groupingOrder",
		"unitsPerColumn",
		"maxColumns",
		"columnSpacing",
		"columnAnchorPoint"
	} do
		self.frame:SetAttribute(attrib, self.db.profile[attrib])
	end

	self.frame:SetSize(self:GetHeaderSize())
	self.frame.content:ClearAllPoints()
	self.frame.content:SetPoint(self.db.profile.columnAnchorPoint, self.frame, self.db.profile.columnAnchorPoint)

	self:UpdateAnchor()
end

RaidFrame5Mod.GetHeaderSize = function(self)
	local config = ns.GetConfig("Raid5Frames")
	return
		config.UnitSize[1]*1 + math_abs(self.db.profile.columnSpacing * 0),
		config.UnitSize[2]*5 + math_abs(self.db.profile.yOffset * 4)
end

RaidFrame5Mod.UpdateUnits = function(self)
	if (not self.frame) then return end
	for i = 1, self.frame:GetNumChildren() do
		local frame = select(i, self.frame:GetChildren())
		frame:UpdateAllElements("RefreshUnit")
	end
end

RaidFrame5Mod.Update = function(self)
	self:UpdateHeader()
	self:UpdateUnits()
end

RaidFrame5Mod.CreateUnitFrames = function(self)

	local name = "Raid5"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetSize(self:GetHeaderSize())

	self.frame.content = oUF:SpawnHeader(self:GetHeaderAttributes())
	self.frame.content:SetPoint(self.db.profile.columnAnchorPoint, self.frame, self.db.profile.columnAnchorPoint)

	-- Embed our custom methods
	for method,func in next,GroupHeader do
		self.frame[method] = function(self, ...)
			func(self.content, ...)
		end
	end

	-- Sometimes some elements are wrong or "get stuck" upon exiting the editmode.
	if (ns.WoW10) then
		self:SecureHook(EditModeManagerFrame, "ExitEditMode", "UpdateUnits")
	end

	-- Sometimes when changing group leader, only the group leader is updated,
	-- leaving other units with a lot of wrong information displayed.
	-- Should think that GROUP_ROSTER_UPDATE handled this, but it doesn't.
	-- *Only experienced this is Wrath.But adding it as a general update anyway.
	self:RegisterEvent("PARTY_LEADER_CHANGED", "UpdateUnits")

end

RaidFrame5Mod.OnEnable = function(self)
	LoadAddOn("Blizzard_CUFProfiles")
	LoadAddOn("Blizzard_CompactRaidFrames")

	-- Leave these enabled for now.
	self:DisableBlizzard()
	self:CreateUnitFrames()
	self:CreateAnchor(RAID .. " (5)") --[[PARTYRAID_LABEL RAID_AND_PARTY]]

	ns.Module.OnEnable(self)
end
