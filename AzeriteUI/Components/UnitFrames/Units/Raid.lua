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

local RaidFrameMod = ns:NewModule("RaidFrames", ns.UnitFrameModule, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Constants
local playerClass = ns.PlayerClass

local defaults = { profile = ns:Merge({

	showRaid = true,
	showParty = false,

	useRaidStylePartyFrames = false,
	showInPartySizedRaidGroups = false,

	point = "LEFT", -- anchor point of unitframe, group members within column grow opposite
	xOffset = 10, -- horizontal offset within the same column
	yOffset = 0, -- vertical offset within the same column

	groupBy = "ROLE", -- GROUP, CLASS, ROLE
	groupingOrder = "TANK,HEALER,DAMAGER", -- must match choice in groupBy

	unitsPerColumn = 5, -- maximum units per column
	maxColumns = 8, -- should be 40/unitsPerColumn
	columnSpacing = -12, -- spacing between columns
	columnAnchorPoint = "TOP" -- anchor point of column, columns grow opposite

	--[[
	point = "TOP", -- anchor point of unitframe, group members within column grow opposite
	xOffset = 0, -- horizontal offset within the same column
	yOffset = 16, -- vertical offset within the same column

	groupBy = "ROLE", -- GROUP, CLASS, ROLE
	groupingOrder = "TANK,HEALER,DAMAGER,NONE", -- must match choice in groupBy

	unitsPerColumn = 5, -- maximum units per column
	maxColumns = 8, -- should be 40/unitsPerColumn
	columnSpacing = 0, -- spacing between columns
	columnAnchorPoint = "LEFT" -- anchor point of column, columns grow opposite
	]]
}, ns.Module.defaults) }

RaidFrameMod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOPLEFT",
		[2] = 50 * ns.API.GetEffectiveScale(),
		[3] = -42 * ns.API.GetEffectiveScale()
	}
	return defaults
end

local config = {

	-- Header Position & Layut
	-----------------------------------------
	Position = { "TOPLEFT", UIParent, "TOPLEFT", 50, -42 }, -- raid header position
	Size = { 103*5, 56*8 }, -- size of the entire header frame area (must adjust to raid size?)
	--Anchor = "LEFT", -- raid member frame anchor
	--GrowthX = 0, -- raid member horizontal offset
	--GrowthY = 0, -- raid member vertical offset
	--Sorting = "INDEX", -- sort method
	--SortDirection = "ASC", -- sort direction

	UnitSize = { 103, 30 + 16 + 10 }, -- raid member size
	PartyHitRectInsets = { 0, 0, 0, -10 }, -- raid member mouseover hit box
	OutOfRangeAlpha = .6, -- Alpha of out of range raid members

	-- Health
	-----------------------------------------
	HealthBarPosition = { "BOTTOM", 0, 0 + 16 },
	HealthBarSize = { 75, 13 }, -- 80, 14
	HealthBarTexture = GetMedia("cast_bar"),
	HealthBarOrientation = "RIGHT",
	HealthBarSparkMap = barSparkMap,
	HealthAbsorbColor = { 1, 1, 1, .5 },
	HealthCastOverlayColor = { 1, 1, 1, .5 },

	HealthBackdropPosition = { "CENTER", 1, -2 },
	HealthBackdropSize = { 132, 85 }, -- 140,90
	HealthBackdropTexture = GetMedia("cast_back"),
	HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	--HealthValuePosition = { "CENTER", 0, 0 },
	--HealthValueJustifyH = "CENTER",
	--HealthValueJustifyV = "MIDDLE",
	--HealthValueFont = GetFont(13, true),
	--HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },

	-- Player Status
	-----------------------------------------
	StatusPosition = { "CENTER", 0, 0 },
	StatusJustifyH = "CENTER",
	StatusJustifyV = "MIDDLE",
	StatusFont = GetFont(13, true),
	StatusColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },

	-- Power
	-----------------------------------------
	PowerBarSize = { 72 -5, 1 },
	PowerBarPosition = { "BOTTOM", 0, -1.5  + 16 },
	PowerBarTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBarOrientation = "RIGHT",
	PowerBackdropSize = { 74 -5, 3 },
	PowerBackdropPosition = { "CENTER", 0, 0 },
	PowerBackdropTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBackdropColor = { 0, 0, 0, .75 },

	-- Target Highlight Outline
	-----------------------------------------
	TargetHighlightPosition = { "CENTER", 1, -2 },
	TargetHighlightSize = { 140, 90 },
	TargetHighlightTexture = GetMedia("cast_back_outline"),
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },

	-- Unit Name
	-----------------------------------------
	NamePosition = { "TOP", 0, -10 },
	NameJustifyH = "CENTER",
	NameJustifyV = "TOP",
	NameFont = GetFont(11, true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Ready Check
	-----------------------------------------
	ReadyCheckPosition = { "CENTER", 0, 0 },
	ReadyCheckSize = { 32, 32 },
	ReadyCheckReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-Ready]],
	ReadyCheckNotReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-NotReady]],
	ReadyCheckWaitingTexture = [[Interface/RAIDFRAME/ReadyCheck-Waiting]],

	-- Resurrection Indicator
	-----------------------------------------
	ResurrectIndicatorPosition = { "CENTER", 0, 0 },
	ResurrectIndicatorSize = { 32, 32 },
	ResurrectIndicatorTexture = [[Interface\RaidFrame\Raid-Icon-Rez]],

	-- Group Role
	-----------------------------------------
	GroupRolePosition = { "RIGHT", 25, 0 },
	GroupRoleSize = { 28, 28 },
	GroupRoleBackdropPosition = { "CENTER", 0, 0 },
	GroupRoleBackdropSize = { 54, 54 },
	GroupRoleBackdropTexture = GetMedia("point_plate"),
	GroupRoleBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	GroupRoleIconPositon = { "CENTER", 0, 0 },
	GroupRoleIconSize = { 24, 24 },
	GroupRoleDPSTexture = GetMedia("grouprole-icons-dps"),
	GroupRoleHealerTexture = GetMedia("grouprole-icons-heal"),
	GroupRoleTankTexture = GetMedia("grouprole-icons-tank"),

	-- Combat Feedback Text
	-----------------------------------------
	CombatFeedbackAnchorElement = "Health",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true) -- glancing blow font

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

local MasterLooterIndicator_PostUpdate = function(self, isShown)
	local leaderIndicator = self.__owner.LeaderIndicator
	leaderIndicator:ClearAllPoints()

	if (isShown) then
		if (not leaderIndicator.points) then
			leaderIndicator.points = { leaderIndicator:GetPoint() }
		end
		leaderIndicator:SetPoint("RIGHT", self, "LEFT")
	elseif (leaderIndicator.points) then
		leaderIndicator:SetPoint(unpack(leaderIndicator.points))
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
	TargetHighlight_Update(self)
end

local UnitFrame_OnEvent = function(self, event, unit, ...)
	UnitFrame_PostUpdate(self)
end

local style = function(self, unit)

	local db = config

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
	--local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	--healthValue:SetPoint(unpack(db.HealthValuePosition))
	--healthValue:SetFontObject(db.HealthValueFont)
	--healthValue:SetTextColor(unpack(db.HealthValueColor))
	--healthValue:SetJustifyH(db.HealthValueJustifyH)
	--healthValue:SetJustifyV(db.HealthValueJustifyV)
	--self:Tag(healthValue, prefix("[*:Health(true, nil, nil, true)]"))

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

		self.Health.Absorb = absorb
	end

	-- Dispellable Debuffs
	--------------------------------------------
	--[[
	local dispellable = {}
	dispellable.disableMouse = true

	local dispelIcon = CreateFrame("Button", dispellable:GetDebugName() .. "Button", healthOverlay)
	--dispelIcon:Hide()
	dispelIcon:SetFrameLevel(overlay:GetFrameLevel() + 2)
	dispelIcon:SetSize(24,24)
	dispelIcon:SetPoint("CENTER")
	dispellable.dispellIcon = dispelIcon

	local dispelIconTexture = dispelIcon:CreateTexture(nil, "BACKGROUND", nil, 1)
	dispelIconTexture:SetAllPoints()
	dispelIconTexture:SetMask(GetMedia("actionbutton-mask-square"))
	dispelIcon.icon = dispelIconTexture

	local dispelIconCount = dispelIcon.Border:CreateFontString(nil, "OVERLAY")
	dispelIconCount:SetFontObject(GetFont(12,true))
	dispelIconCount:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	dispelIconCount:SetPoint("BOTTOMRIGHT", dispelIcon, "BOTTOMRIGHT", -2, 3)
	dispelIcon.count = dispelIconCount

	local dispelIconBorder = CreateFrame("Frame", nil, dispelIcon, ns.BackdropTemplate)
	dispelIconBorder:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	dispelIconBorder:SetBackdropBorderColor(Colors.aura[1], Colors.aura[2], Colors.aura[3])
	dispelIconBorder:SetPoint("TOPLEFT", -6, 6)
	dispelIconBorder:SetPoint("BOTTOMRIGHT", 6, -6)
	dispelIconBorder:SetFrameLevel(dispelIcon:GetFrameLevel() + 2)
	dispelIcon.overlay = dispelIconBorder

	local dispelIconTime = dispelIcon.overlay:CreateFontString(nil, "OVERLAY")
	dispelIconTime:SetFontObject(GetFont(14,true))
	dispelIconTime:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	dispelIconTime:SetPoint("TOPLEFT", dispelIcon, "TOPLEFT", -4, 4)
	dispelIcon.time = dispelIconTime

	-- Using a virtual cooldown element with the timer attached,
	-- allowing them to piggyback on the back-end's cooldown updates.
	dispelIcon.cd = ns.Widgets.RegisterCooldown(dispelIcon.time)

	--self.Dispellable = dispellable
	--]]

	-- Readycheck
	--------------------------------------------
	local readyCheckIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
	readyCheckIndicator:SetSize(unpack(db.ReadyCheckSize))
	readyCheckIndicator:SetPoint(unpack(db.ReadyCheckPosition))
	readyCheckIndicator.readyTexture = db.ReadyCheckReadyTexture
	readyCheckIndicator.notReadyTexture = db.ReadyCheckNotReadyTexture
	readyCheckIndicator.waitingTexture = db.ReadyCheckWaitingTexture

	self.ReadyCheckIndicator = ReadyCheckIndicator

	-- Ressurection Indicator
	--------------------------------------------
	local resurrectIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 6)
	resurrectIndicator:SetSize(unpack(db.ResurrectIndicatorSize))
	resurrectIndicator:SetPoint(unpack(db.ResurrectIndicatorPosition))
	resurrectIndicator:SetTexture(ResurrectIndicatorTexture)

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
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	feedbackText:SetFontObject(db.CombatFeedbackFont)
	feedbackText.feedbackFont = db.CombatFeedbackFont
	feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

	self.CombatFeedback = feedbackText

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
	local leaderIndicator = overlay:CreateFontString(nil, "OVERLAY", nil, 2)
	leaderIndicator:SetSize(16, 16)
	leaderIndicator:SetPoint("RIGHT", self.Name, "LEFT")

	self.LeaderIndicator = leaderIndicator

	-- MasterLooter Indicator
	--------------------------------------------
	local masterLooterIndicator = overlay:CreateFontString(nil, "OVERLAY", nil, 2)
	masterLooterIndicator:SetSize(16, 16)
	masterLooterIndicator:SetPoint("RIGHT", self.Name, "LEFT")

	self.MasterLooterIndicator = masterLooterIndicator
	self.MasterLooterIndicator.PostUpdate = MasterLooterIndicator_PostUpdate

	--local threatIndicator = health:CreateTexture(nil, "BACKGROUND", nil, -2)
	--threatIndicator:SetPoint(unpack(db.HealthBackdropPosition))
	--threatIndicator:SetSize(unpack(db.HealthBackdropSize))
	--threatIndicator:SetTexture(db.HealthBackdropTexture)

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

	local visibility = RaidFrameMod:GetVisibilityDriver()

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

RaidFrameMod.DisableBlizzard = function(self)
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	CompactRaidFrameManager_SetSetting("IsShown", "0")

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:SetParent(ns.Hider)
end

RaidFrameMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		if (self.needHeaderUpdate) then
			self.needHeaderUpdate = nil
			self:UpdateHeader()
		end
	end
end

RaidFrameMod.GetHeaderAttributes = function(self)
	local db = self.db.profile

	return ns.Prefix.."Raid", nil, nil,
	"initial-width", config.UnitSize[1],
	"initial-height", config.UnitSize[2],
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
	"showRaid", db.showRaid, -- show while in a raid group
	"showParty", db.showParty, -- show while in a party
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

RaidFrameMod.GetVisibilityDriver = function(self)
	local db = self.db.profile

	local driver = "custom "

	if (self.db.profile.useRaidStylePartyFrames) then
		driver = driver.."[group:party,nogroup:raid]show;"
	end

	if (self.db.profile.showInPartySizedRaidGroups) then
		driver = driver.."[group:raid,@raid6,noexists]show;"
	end

	if (self.db.profile.showRaid) then
		driver = driver.."[group:raid,@raid6,exists]show;"
	else
	end

	driver = driver.."hide"

	return driver
end

RaidFrameMod.UpdateHeader = function(self)
	if (not self.frame) then return end
	if (InCombatLockdown()) then
		self.needHeaderUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		return
	end
	for _,attrib in next,{
		"showRaid",
		"showParty",
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
end

RaidFrameMod.UpdateUnits = function(self)
	if (not self.frame) then return end
	for i = 1, self.frame:GetNumChildren() do
		local frame = select(i, self.frame:GetChildren())
		frame:UpdateAllElements("RefreshUnit")
	end
end

RaidFrameMod.Update = function(self)
	self:UpdateHeader()
	self:UpdateUnits()
end

RaidFrameMod.CreateUnitFrames = function(self)

	local unit, name = "raid", "Raid"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = oUF:SpawnHeader(self:GetHeaderAttributes())
	self.frame:SetSize(unpack(config.Size))

	-- Embed our custom methods
	for method,func in next,GroupHeader do
		self.frame[method] = func
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

RaidFrameMod.OnEnable = function(self)
	LoadAddOn("Blizzard_CUFProfiles")
	LoadAddOn("Blizzard_CompactRaidFrames")

	-- Leave these enabled for now.
	self:DisableBlizzard()
	self:CreateUnitFrames()
	self:CreateAnchor(RAID) --[[PARTYRAID_LABEL RAID_AND_PARTY]]

	ns.Module.OnEnable(self)
end
