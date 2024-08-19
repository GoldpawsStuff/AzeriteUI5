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

local RaidFrame5Mod = ns:NewModule("RaidFrame5", ns.UnitFrameModule, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: UIParent, Enum
-- GLOBALS: LoadAddOn, InCombatLockdown, RegisterAttributeDriver, UnregisterAttributeDriver
-- GLOBALS: UnitHasVehicleUI, UnitIsUnit, UnitPowerType
-- GLOBALS: CompactRaidFrameContainer, CompactRaidFrameManager, CompactRaidFrameManager_SetSetting

-- Lua API
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local next = next
local select = select
local string_gsub = string.gsub
local string_upper = string.upper
local table_concat = table.concat
local table_insert = table.insert
local type = type
local unpack = unpack

local Units = {}

local defaults = { profile = ns:Merge({

	enabled = true,

	useInParties = false, -- show in non-raid parties
	useInRaid5 = true, -- show in raid groups of 1-5 players
	useInRaid10 = false, -- show in raid groups of 6-10 players
	useInRaid25 = false, -- show in raid groups of 11-25 players
	useInRaid40 = false, -- show in raid groups of 26-40 players

	useRangeIndicator = false,

	point = "TOP", -- anchor point of unitframe, group members within column grow opposite
	xOffset = 0, -- horizontal offset within the same column
	yOffset = -12, -- vertical offset within the same column

	groupBy = "GROUP", -- GROUP, CLASS, ROLE
	groupingOrder = "1,2,3,4,5,6,7,8", -- must match choice in groupBy

	unitsPerColumn = 5,
	maxColumns = 1,
	columnSpacing = 10, -- spacing between columns
	columnAnchorPoint = "LEFT" -- anchor point of column, columns grow opposite

}, ns.MovableModulePrototype.defaults) }

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

	local shouldShow = UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)

	if (not shouldShow or cur == 0 or max == 0) then
		element:SetAlpha(0)
	else
		element:SetAlpha(.75)
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

	self:SetSize(unpack(db.UnitSize))
	self:SetFrameLevel(self:GetFrameLevel() + 10)

	-- Apply common scripts and member values.
	ns.UnitFrame.InitializeUnitFrame(self)
	ns.UnitFrames[self] = true -- add to global registry
	Units[self] = true -- add to local registry

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
	--[[--
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
	--]]--

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(unpack(db.AurasSize))
	auras:SetPoint(unpack(db.AurasPosition))
	auras.size = db.AuraSize
	auras.spacing = db.AuraSpacing
	auras.numBuffs = db.AurasNumBuffs
	auras.numDebuffs = db.AurasNumDebuffs
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
	auras.filter = "RAID" -- Buffs the player can apply and debuffs the player can dispell
	auras.buffFilter = nil
	auras.debuffFilter = nil

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

-- Fake GroupHeader
---------------------------------------------------
local GroupHeader = {}

GroupHeader.ForAll = function(self, methodOrFunc, ...)
	for frame in next,Units do
		if (type(methodOrFunc) == "string") then
			frame[methodOrFunc](frame, ...)
		else
			methodOrFunc(frame, ...)
		end
	end
end

GroupHeader.Enable = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateVisibilityDriver()
	self.enabled = true
end

GroupHeader.Disable = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateVisibilityDriver()
	self.enabled = false
end

GroupHeader.IsEnabled = function(self)
	return self.enabled
end

GroupHeader.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then return end

	local driver = {}

	local db = RaidFrame5Mod.db.profile
	if (db.enabled) then
		table_insert(driver, "[group:party,nogroup:raid]"..(db.useInParties and "show" or "hide"))
		table_insert(driver, "[@raid26,exists]"..(db.useInRaid40 and "show" or "hide"))
		table_insert(driver, "[@raid11,exists]"..(db.useInRaid25 and "show" or "hide"))
		table_insert(driver, "[@raid6,exists]"..(db.useInRaid10 and "show" or "hide"))
		table_insert(driver, "[group:raid]"..(db.useInRaid5 and "show" or "hide"))
	end

	table_insert(driver, "hide")

	self.visibility = table_concat(driver, ";")

	UnregisterAttributeDriver(self, "state-visibility")
	RegisterAttributeDriver(self, "state-visibility", self.visibility)

	self:SetAttribute("showRaid", db.useInRaid5 or db.useInRaid10 or db.useInRaid25 or db.useInRaid40)
	self:SetAttribute("showParty", db.useInParties)
	self:SetAttribute("showPlayer", true)

end

-- Sourced from FrameXML\SecureGroupHeaders.lua
-- relativePoint, xMultiplier, yMultiplier = getRelativePointAnchor(point)
-- Given a point return the opposite point and which axes the point depends on.
local getRelativePointAnchor = function(point)
	point = string_upper(point)
	if (point == "TOP") then
		return "BOTTOM", 0, -1
	elseif (point == "BOTTOM") then
		return "TOP", 0, 1
	elseif (point == "LEFT") then
		return "RIGHT", 1, 0
	elseif (point == "RIGHT") then
		return "LEFT", -1, 0
	elseif (point == "TOPLEFT") then
		return "BOTTOMRIGHT", 1, -1
	elseif (point == "TOPRIGHT") then
		return "BOTTOMLEFT", -1, -1
	elseif (point == "BOTTOMLEFT") then
		return "TOPRIGHT", 1, 1
	elseif (point == "BOTTOMRIGHT") then
		return "TOPLEFT", -1, 1
	else
		return "CENTER", 0, 0
	end
end

-- Sourced from FrameXML\SecureGroupHeaders.lua > configureChildren()
RaidFrame5Mod.GetCalculatedHeaderSize = function(self, numDisplayed)

	local config = ns.GetConfig("Raid5Frames")
	local db = self.db.profile

	local header = self:GetUnitFrameOrHeader()
	local unitButtonWidth = config.UnitSize[1]
	local unitButtonHeight = config.UnitSize[2]
	local unitsPerColumn = db.unitsPerColumn
	local point = db.point or "TOP"
	local relativePoint, xOffsetMult, yOffsetMult = getRelativePointAnchor(point)
	local xMultiplier, yMultiplier =  math_abs(xOffsetMult), math_abs(yOffsetMult)
	local xOffset = db.xOffset or 0
	local yOffset = db.yOffset or 0
	local columnSpacing = db.columnSpacing or 0

	local numColumns
	if (unitsPerColumn and numDisplayed > unitsPerColumn) then
		numColumns = math_min(math_ceil(numDisplayed/unitsPerColumn), (db.maxColumns or 1))
	else
		unitsPerColumn = numDisplayed
		numColumns = 1
	end

	local columnAnchorPoint, columnRelPoint, colxMulti, colyMulti
	if (numColumns > 1) then
		columnAnchorPoint = db.columnAnchorPoint
		columnRelPoint, colxMulti, colyMulti = getRelativePointAnchor(columnAnchorPoint)
	end

	local width, height

	if (numDisplayed > 0) then
		width = xMultiplier * (unitsPerColumn - 1) * unitButtonWidth + ((unitsPerColumn - 1) * (xOffset * xOffsetMult)) + unitButtonWidth
		height = yMultiplier * (unitsPerColumn - 1) * unitButtonHeight + ((unitsPerColumn - 1) * (yOffset * yOffsetMult)) + unitButtonHeight

		if (numColumns > 1) then
			width = width + ((numColumns -1) * math_abs(colxMulti) * (width + columnSpacing))
			height = height + ((numColumns -1) * math_abs(colyMulti) * (height + columnSpacing))
		end
	else
		local minWidth = db.minWidth or (yMultiplier * unitButtonWidth)
		local minHeight = db.minHeight or (xMultiplier * unitButtonHeight)

		width = math_max(minWidth, 0.1)
		height = math_max(minHeight, 0.1)
	end

	return width, height
end

-- Sourced from FrameXML\SecureGroupHeaders.lua > configureChildren()
RaidFrame5Mod.ConfigureChildren = function(self)
	if (InCombatLockdown()) then return end

	local db = self.db.profile
	local config = ns.GetConfig("Raid5Frames")
	local header = self:GetUnitFrameOrHeader()
	local frame = self:GetFrame()

	local point = db.point or "TOP"
	local relativePoint, xOffsetMult, yOffsetMult = getRelativePointAnchor(point)
	local xMultiplier, yMultiplier =  math_abs(xOffsetMult), math_abs(yOffsetMult)
	local xOffset = db.xOffset or 0
	local yOffset = db.yOffset or 0
	local sortDir = db.sortDir or "ASC"
	local columnSpacing = db.columnSpacing or 0
	local startingIndex = db.startingIndex or 1

	local unitCount = 5

	local numDisplayed = unitCount - (startingIndex - 1)
	local unitsPerColumn = db.unitsPerColumn
	local numColumns
	if (unitsPerColumn and numDisplayed > unitsPerColumn) then
		numColumns = math_min(math_ceil(numDisplayed/unitsPerColumn), (db.maxColumns or 1))
	else
		unitsPerColumn = numDisplayed
		numColumns = 1
	end
	local loopStart = startingIndex
	local loopFinish = math_min((startingIndex - 1) + unitsPerColumn * numColumns, unitCount)
	local step = 1

	numDisplayed = loopFinish - (loopStart - 1)

	if (sortDir == "DESC") then
		loopStart = unitCount - (startingIndex - 1)
		loopFinish = loopStart - (numDisplayed - 1)
		step = -1
	end

	local columnAnchorPoint, columnRelPoint, colxMulti, colyMulti
	if (numColumns > 1) then
		columnAnchorPoint = db.columnAnchorPoint
		columnRelPoint, colxMulti, colyMulti = getRelativePointAnchor(columnAnchorPoint)
	end

	local buttonNum = 0
	local columnNum = 1
	local columnUnitCount = 0
	local currentAnchor = header
	for i = loopStart, loopFinish, step do
		buttonNum = buttonNum + 1
		columnUnitCount = columnUnitCount + 1
		if (columnUnitCount > unitsPerColumn) then
			columnUnitCount = 1
			columnNum = columnNum + 1
		end

		local unitButton = header:GetAttribute("child"..buttonNum)
		unitButton:ClearAllPoints()

		if (buttonNum == 1) then
			unitButton:SetPoint(point, currentAnchor, point, 0, 0)
			if (columnAnchorPoint) then
				unitButton:SetPoint(columnAnchorPoint, currentAnchor, columnAnchorPoint, 0, 0)
			end

		elseif (columnUnitCount == 1) then
			local columnAnchor = header:GetAttribute("child"..(buttonNum - unitsPerColumn))
			unitButton:SetPoint(columnAnchorPoint, columnAnchor, columnRelPoint, colxMulti * columnSpacing, colyMulti * columnSpacing)

		else
			unitButton:SetPoint(point, currentAnchor, relativePoint, xMultiplier * xOffset, yMultiplier * yOffset)
		end

		currentAnchor = unitButton
	end

	header:SetSize(self:GetCalculatedHeaderSize(numDisplayed))
end

RaidFrame5Mod.DisableBlizzard = function(self)
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	CompactRaidFrameManager_SetSetting("IsShown", "0")

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:SetParent(ns.Hider)
end

RaidFrame5Mod.GetHeaderSize = function(self)
	return self:GetCalculatedHeaderSize(5)
end

RaidFrame5Mod.CreateUnitFrames = function(self)

	local unit, name = "raid", "Raid5"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame.content = CreateFrame("Frame", ns.Prefix.."Raid5Frames", UIParent, "SecureHandlerStateTemplate")

	-- Embed our custom methods
	for method,func in next,GroupHeader do
		self.frame.content[method] = func
	end

	for i = 1,5 do

		-- The real unit of the frame.
		local realUnit = ns.IsInTestMode and "player" or unit..i

		-- Spawn our unit button and parent it to our visibility driver.
		local unitButton = ns.UnitFrame.Spawn(realUnit, ns.Prefix.."UnitFrame"..name..i)
		unitButton:SetParent(self.frame.content)

		-- Reference the unitbutton on our custom header frame.
		self.frame.content:SetFrameRef("child"..i, unitButton)
		self.frame.content:SetAttribute("child"..i, unitButton)

		-- Let's create a magic unit driver for this one.
		local driver = {}

		local raidUnit, partyUnit = unit..i, "party"..i
		local raidPetUnit, partyPetUnit = raidUnit.."pet", partyUnit.."pet"

		-- Vehicle toggling
		if (ns.IsCata or ns.IsRetail) then

			-- Don't automatically toggle for vehicles, we handle this one.
			unitButton:SetAttribute("toggleForVehicle", nil)

			-- Group type dependant unit replacements.
			-- *Our frames should use raid units when available, party otherwise.
			table_insert(driver, "[vehicleui,group:raid]"..raidPetUnit)
			table_insert(driver, "[vehicleui,nogroup:raid]"..partyPetUnit)
		end

		-- Group type dependant units.
		-- *Our frames should use raid units when available, party otherwise.
		table_insert(driver, "[group:raid]"..raidUnit)
		table_insert(driver, "[nogroup:raid]"..partyUnit)

		-- Use a fallback unit.
		table_insert(driver, realUnit)

		-- Apply our custom unit driver.
		RegisterAttributeDriver(unitButton, "unit", table_concat(driver, ";"))
	end

	self:UpdateHeader()

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

RaidFrame5Mod.UpdateHeader = function(self)
	local header = self:GetUnitFrameOrHeader()
	if (not header) then return end

	if (InCombatLockdown()) then
		self.needHeaderUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		return
	end

	local config = ns.GetConfig("Raid5Frames")

	header:UpdateVisibilityDriver()
	header:SetAttribute("unitWidth", config.UnitSize[1])
	header:SetAttribute("unitHeight", config.UnitSize[2])
	header:SetAttribute("point", self.db.profile["point"])
	header:SetAttribute("xOffset", self.db.profile["xOffset"])
	header:SetAttribute("yOffset", self.db.profile["yOffset"])
	header:SetAttribute("groupBy", self.db.profile["groupBy"])
	header:SetAttribute("groupingOrder", self.db.profile["groupingOrder"])
	header:SetAttribute("unitsPerColumn", self.db.profile["unitsPerColumn"])
	header:SetAttribute("maxColumns", self.db.profile["maxColumns"])
	header:SetAttribute("columnSpacing", self.db.profile["columnSpacing"])
	header:SetAttribute("columnAnchorPoint", self.db.profile["columnAnchorPoint"])

	self:GetFrame():SetSize(self:GetHeaderSize())
	self:ConfigureChildren()

	self:UpdateHeaderAnchorPoint() -- update where the group header is anchored to our anchorframe.
	self:UpdateAnchor() -- the general update does this too, but we need it in case nothing but this function has been called.
end

RaidFrame5Mod.UpdateHeaderAnchorPoint = function(self)
	local point = "TOPLEFT"
	if (self.db.profile.columnAnchorPoint == "LEFT") then
		if (self.db.profile.point == "TOP") then
			point = "TOPLEFT"
		elseif (self.db.profile.point == "BOTTOM") then
			point = "BOTTOMLEFT"
		end
	elseif (self.db.profile.columnAnchorPoint == "RIGHT") then
		if (self.db.profile.point == "TOP") then
			point = "TOPRIGHT"
		elseif (self.db.profile.point == "BOTTOM") then
			point = "BOTTOMRIGHT"
		end
	elseif (self.db.profile.columnAnchorPoint == "TOP") then
		if (self.db.profile.point == "LEFT") then
			point = "TOPLEFT"
		elseif (self.db.profile.point == "RIGHT") then
			point = "TOPRIGHT"
		end
	elseif (self.db.profile.columnAnchorPoint == "BOTTOM") then
		if (self.db.profile.point == "LEFT") then
			point = "BOTTOMLEFT"
		elseif (self.db.profile.point == "RIGHT") then
			point = "BOTTOMRIGHT"
		end
	end
	local header = self:GetUnitFrameOrHeader()
	header:ClearAllPoints()
	header:SetPoint(point, self:GetFrame(), point)
end

RaidFrame5Mod.UpdateUnits = function(self)
	if (not self:GetFrame()) then return end
	for frame in next,Units do
		if (self.db.profile.useRangeIndicator) then
			frame:EnableElement("Range")
		else
			frame:DisableElement("Range")
			frame:SetAlpha(1)
		end
		frame:UpdateAllElements("RefreshUnit")
	end
end

RaidFrame5Mod.Update = function(self)
	self:UpdateHeader()
	self:UpdateUnits()
end

RaidFrame5Mod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		if (InCombatLockdown()) then
			self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			return
		end
		self:UpdateHeader()
		self:UpdateUnits() -- needed?

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		if (self.needHeaderUpdate) then
			self.needHeaderUpdate = nil
			self:UpdateHeader()
		end
	end
end

RaidFrame5Mod.OnEnable = function(self)

	LoadAddOn("Blizzard_CUFProfiles")
	LoadAddOn("Blizzard_CompactRaidFrames")

	self:DisableBlizzard()
	self:CreateUnitFrames()
	self:CreateAnchor(RAID .. " (5)")

	ns.MovableModulePrototype.OnEnable(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
