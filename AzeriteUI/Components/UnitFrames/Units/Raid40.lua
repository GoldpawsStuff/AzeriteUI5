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

local RaidFrame40Mod = ns:NewModule("RaidFrame40", ns.UnitFrameModule, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: UIParent, Enum
-- GLOBALS: LoadAddOn, InCombatLockdown, RegisterAttributeDriver, UnregisterAttributeDriver
-- GLOBALS: UnitGroupRolesAssigned, UnitHasVehicleUI, UnitIsUnit, UnitPowerType
-- GLOBALS: CompactRaidFrameContainer, CompactRaidFrameManager, CompactRaidFrameManager_SetSetting

-- Lua API
local math_abs = math.abs
local next = next
local select = select
local string_gsub = string.gsub
local table_concat = table.concat
local table_insert = table.insert
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
local GetFont = ns.API.GetFont

local Units = {}

local defaults = { profile = ns:Merge({

	enabled = true,

	useInParties = false, -- show in non-raid parties
	useInRaid5 = false, -- show in raid groups of 1-5 players
	useInRaid10 = false, -- show in raid groups of 6-10 players
	useInRaid25 = false, -- show in raid groups of 11-25 players
	useInRaid40 = true, -- show in raid groups of 26-40 players

	useRangeIndicator = true,

	point = "LEFT", -- anchor point of unitframe, group members within column grow opposite
	xOffset = 10, -- horizontal offset within the same column
	yOffset = 0, -- vertical offset within the same column

	groupBy = "ROLE", -- GROUP, CLASS, ROLE
	groupingOrder = "TANK,HEALER,DAMAGER", -- must match choice in groupBy

	unitsPerColumn = 5, -- maximum units per column
	maxColumns = 8, -- should be 40/unitsPerColumn
	columnSpacing = -12, -- spacing between columns
	columnAnchorPoint = "TOP" -- anchor point of column, columns grow opposite

}, ns.MovableModulePrototype.defaults) }

RaidFrame40Mod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOPLEFT",
		[2] = 50 * ns.API.GetEffectiveScale(),
		[3] = -42 * ns.API.GetEffectiveScale()
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

	local shouldShow = UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and element.displayType == Enum.PowerType.Mana

	if (not shouldShow or cur == 0 or max == 0) then
		element:SetAlpha(0)
	else
		element:SetAlpha(.75)
	end
end

-- Custom Group Role updater
local GroupRoleIndicator_Override = function(self, event)
	local element = self.GroupRoleIndicator

	--[[ Callback: GroupRoleIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the GroupRoleIndicator element
	--]]
	if (element.PreUpdate) then
		element:PreUpdate()
	end

	local role = UnitGroupRolesAssigned(self.unit)
	if (role and element[role]) then
		element.Icon:SetTexture(element[role])
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: GroupRoleIndicator:PostUpdate(role)
	Called after the element has been updated.

	* self - the GroupRoleIndicator element
	* role - the role as returned by [UnitGroupRolesAssigned](http://wowprogramming.com/docs/api/UnitGroupRolesAssigned.html)
	--]]
	if (element.PostUpdate) then
		return element:PostUpdate(role)
	end
end

-- Update leader indicator position
-- when master looter indicator is shown or hidden.
local MasterLooterIndicator_PostUpdate = function(self, isShown)
	local leaderIndicator = self.__owner.LeaderIndicator
	leaderIndicator:ClearAllPoints()
	leaderIndicator:SetPoint("RIGHT", isShown and self or self.__owner.Name, "LEFT")
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

-- Update the border color of priority debuffs.
local PriorityDebuff_PostUpdate = function(element, event, isVisible, name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom)
	if (isVisible) then
		local color = debuffType and Colors.debuff[debuffType] or Colors.debuff.none
		element.border:SetBackdropBorderColor(color[1], color[2], color[3])
	end
end

local UnitFrame_PostUpdate = function(self)
	TargetHighlight_Update(self)
end

local UnitFrame_OnEvent = function(self, event, unit, ...)
	UnitFrame_PostUpdate(self)
end

local style = function(self, unit)

	local db = ns.GetConfig("RaidFrames")

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
	--local castbar = self:CreateBar()
	--castbar:SetAllPoints(health)
	--castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	--castbar:SetSparkMap(db.HealthBarSparkMap)
	--castbar:SetStatusBarTexture(db.HealthBarTexture)
	--castbar:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	--castbar:DisableSmoothing(true)

	--self.Castbar = castbar

	-- Health Value
	--------------------------------------------
	--local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	--healthValue:SetPoint(unpack(db.HealthValuePosition))
	--healthValue:SetFontObject(db.HealthValueFont)
	--healthValue:SetTextColor(unpack(db.HealthValueColor))
	--healthValue:SetJustifyH(db.HealthValueJustifyH)
	--healthValue:SetJustifyV(db.HealthValueJustifyV)
	--self:Tag(healthValue, prefix("[*:Health(true,false,false,true)]"))

	--self.Health.Value = healthValue

	-- Player Status
	--------------------------------------------
	local status = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	status:SetPoint(unpack(db.StatusPosition))
	status:SetFontObject(db.StatusFont)
	status:SetTextColor(unpack(db.StatusColor))
	status:SetJustifyH(db.StatusJustifyH)
	status:SetJustifyV(db.StatusJustifyV)
	self:Tag(status, prefix("[*:DeadOrOffline]"))

	self.Health.Status = status

	-- Power
	--------------------------------------------
	local power = self:CreateBar()
	power:SetFrameLevel(health:GetFrameLevel() + 2)
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetOrientation(db.PowerBarOrientation)
	power.frequentUpdates = true
	power.colorPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_PostUpdate

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -2)
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetTexture(db.PowerBackdropTexture)
	powerBackdrop:SetVertexColor(unpack(db.PowerBackdropColor))

	self.Power.Backdrop = powerBackdrop

	-- Priority Debuff
	--------------------------------------------
	local priorityDebuff = CreateFrame("Frame", nil, overlay)
	priorityDebuff:SetSize(40,40)
	priorityDebuff:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
	priorityDebuff.forceShow = nil

	local priorityDebuffIcon = priorityDebuff:CreateTexture(nil, "BACKGROUND", nil, 1)
	priorityDebuffIcon:SetPoint("CENTER")
	priorityDebuffIcon:SetSize(priorityDebuff:GetSize())
	priorityDebuffIcon:SetMask(GetMedia("actionbutton-mask-square"))
	priorityDebuff.icon = priorityDebuffIcon

	local priorityDebuffBorder = CreateFrame("Frame", nil, priorityDebuff, ns.BackdropTemplate)
	priorityDebuffBorder:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	priorityDebuffBorder:SetBackdropBorderColor(Colors.verydarkgray[1], Colors.verydarkgray[2], Colors.verydarkgray[3])
	priorityDebuffBorder:SetPoint("TOPLEFT", -4, 4)
	priorityDebuffBorder:SetPoint("BOTTOMRIGHT", 4, -4)
	priorityDebuffBorder:SetFrameLevel(priorityDebuff:GetFrameLevel() + 2)
	priorityDebuff.border = priorityDebuffBorder

	local priorityDebuffCount = priorityDebuff.border:CreateFontString(nil, "OVERLAY")
	priorityDebuffCount:SetFontObject(GetFont(14, true))
	priorityDebuffCount:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	priorityDebuffCount:SetPoint("BOTTOMRIGHT", priorityDebuff, "BOTTOMRIGHT", -2, 3)
	priorityDebuff.count = priorityDebuffCount

	self.PriorityDebuff = priorityDebuff
	self.PriorityDebuff.PostUpdate = PriorityDebuff_PostUpdate

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

	-- Ressurection Indicator
	--------------------------------------------
	local resurrectIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 6)
	resurrectIndicator:SetSize(unpack(db.ResurrectIndicatorSize))
	resurrectIndicator:SetPoint(unpack(db.ResurrectIndicatorPosition))
	resurrectIndicator:SetTexture(db.ResurrectIndicatorTexture)

	self.ResurrectIndicator = resurrectIndicator

	-- Group Role
	-----------------------------------------
    local groupRoleIndicator = CreateFrame("Frame", nil, healthOverlay)
	groupRoleIndicator:SetSize(unpack(db.GroupRoleSize))
	groupRoleIndicator:SetPoint(unpack(db.GroupRolePosition))
	groupRoleIndicator.HEALER = db.GroupRoleHealerTexture
	groupRoleIndicator.TANK = db.GroupRoleTankTexture

	local groupRoleBackdrop = groupRoleIndicator:CreateTexture(nil, "BACKGROUND", nil, 1)
	groupRoleBackdrop:SetSize(unpack(db.GroupRoleBackdropSize))
	groupRoleBackdrop:SetPoint(unpack(db.GroupRoleBackdropPosition))
	groupRoleBackdrop:SetTexture(db.GroupRoleBackdropTexture)
	groupRoleBackdrop:SetVertexColor(unpack(db.GroupRoleBackdropColor))

	groupRoleIndicator.Backdrop = groupRoleBackdrop

	local groupRoleIcon = groupRoleIndicator:CreateTexture(nil, "ARTWORK", nil, 1)
	groupRoleIcon:SetSize(unpack(db.GroupRoleIconSize))
	groupRoleIcon:SetPoint(unpack(db.GroupRoleIconPositon))

	groupRoleIndicator.Icon = groupRoleIcon

    self.GroupRoleIndicator = groupRoleIndicator
	self.GroupRoleIndicator.Override = GroupRoleIndicator_Override

	-- CombatFeedback Text
	--------------------------------------------
	--local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	--feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	--feedbackText:SetFontObject(db.CombatFeedbackFont)
	--feedbackText.feedbackFont = db.CombatFeedbackFont
	--feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	--feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

	--self.CombatFeedback = feedbackText

	-- Target Highlight
	--------------------------------------------
	local targetHighlight = healthOverlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:SetPoint(unpack(db.TargetHighlightPosition))
	targetHighlight:SetSize(unpack(db.TargetHighlightSize))
	targetHighlight:SetTexture(db.TargetHighlightTexture)
	targetHighlight.colorTarget = db.TargetHighlightTargetColor
	targetHighlight.colorFocus = db.TargetHighlightFocusColor

	self.TargetHighlight = targetHighlight

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

	-- Leader Indicator
	--------------------------------------------
	local leaderIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	leaderIndicator:SetSize(16, 16)
	leaderIndicator:SetPoint("RIGHT", self.Name, "LEFT")

	self.LeaderIndicator = leaderIndicator

	-- MasterLooter Indicator
	--------------------------------------------
	local masterLooterIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	masterLooterIndicator:SetSize(16, 16)
	masterLooterIndicator:SetPoint("RIGHT", self.Name, "LEFT")

	self.MasterLooterIndicator = masterLooterIndicator
	self.MasterLooterIndicator.PostUpdate = MasterLooterIndicator_PostUpdate

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
	for frame in next,Units do
		if (type(methodOrFunc) == "string") then
			frame[methodOrFunc](frame, ...)
		else
			methodOrFunc(frame, ...)
		end
	end
end

GroupHeader.OverrideEnable = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateVisibilityDriver()
	self.enabled = true
end

GroupHeader.OverrideDisable = function(self)
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

	local db = RaidFrame40Mod.db.profile
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

RaidFrame40Mod.DisableBlizzard = function(self)
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	CompactRaidFrameManager_SetSetting("IsShown", "0")

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:SetParent(ns.Hider)
end

RaidFrame40Mod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		if (self.needHeaderUpdate) then
			self.needHeaderUpdate = nil
			self:UpdateHeader()
		end
	end
end

RaidFrame40Mod.GetHeaderAttributes = function(self)
	local db = self.db.profile

	return ns.Prefix.."Raid40", nil, nil,
	"initial-width", ns.GetConfig("RaidFrames").UnitSize[1],
	"initial-height", ns.GetConfig("RaidFrames").UnitSize[2],
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
	"point", db.point, -- Unit anchoring within each column
	"xOffset", db.xOffset,
	"yOffset", db.yOffset,
	"groupBy", "GROUP", -- db.groupBy, -- ROLE, CLASS, GROUP -- Grouping order and type
	"groupingOrder", "1,2,3,4,5,6,7,8", -- db.groupingOrder,
	"unitsPerColumn", db.unitsPerColumn, -- Column setup and growth
	"maxColumns", db.maxColumns,
	"columnSpacing", db.columnSpacing,
	"columnAnchorPoint", db.columnAnchorPoint

end

RaidFrame40Mod.GetHeaderSize = function(self)
	local config = ns.GetConfig("RaidFrames")
	return
		config.UnitSize[1]*5 + math_abs(self.db.profile.xOffset * 4),
		config.UnitSize[2]*8 + math_abs(self.db.profile.columnSpacing * 7)
end

RaidFrame40Mod.UpdateHeader = function(self)
	local header = self:GetUnitFrameOrHeader()
	if (not header) then return end

	if (InCombatLockdown()) then
		self.needHeaderUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		return
	end

	header:UpdateVisibilityDriver()
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

	self:UpdateHeaderAnchorPoint() -- update where the group header is anchored to our anchorframe.
	self:UpdateAnchor() -- the general update does this too, but we need it in case nothing but this function has been called.
end

RaidFrame40Mod.UpdateHeaderAnchorPoint = function(self)
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

RaidFrame40Mod.UpdateUnits = function(self)
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

RaidFrame40Mod.Update = function(self)
	self:UpdateHeader()
	self:UpdateUnits()
end

RaidFrame40Mod.CreateUnitFrames = function(self)

	local name = "Raid40"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetSize(self:GetHeaderSize())

	self.frame.content = oUF:SpawnHeader(self:GetHeaderAttributes())
	self:UpdateHeaderAnchorPoint()

	-- Embed our custom methods
	for method,func in next,GroupHeader do
		self.frame.content[method] = func
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

RaidFrame40Mod.OnEnable = function(self)
	LoadAddOn("Blizzard_CUFProfiles")
	LoadAddOn("Blizzard_CompactRaidFrames")

	-- Leave these enabled for now.
	self:DisableBlizzard()
	self:CreateUnitFrames()
	self:CreateAnchor(RAID .. " (40)") --[[PARTYRAID_LABEL RAID_AND_PARTY]]

	ns.MovableModulePrototype.OnEnable(self)
end
