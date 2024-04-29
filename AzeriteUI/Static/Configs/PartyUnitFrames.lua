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
local Addon, ns = ...

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local barSparkMap = {
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

ns.RegisterConfig("PartyFrames", {

	-- Header Position & Layut
	-----------------------------------------
	Position = { "TOPLEFT", UIParent, "TOPLEFT", 50, -42 }, -- party header position
	Size = { 130*4, 130 }, -- size of the entire header frame area
	UnitSize = { 130, 140 }, -- party member size
	OutOfRangeAlpha = .6, -- Alpha of out of range party members

	-- Health
	-----------------------------------------
	HealthBarPosition = { "BOTTOM", 0, 10 },
	HealthBarSize = { 80, 14 },
	HealthBarTexture = GetMedia("cast_bar"),
	HealthBarOrientation = "RIGHT",
	HealthBarSparkMap = barSparkMap,
	HealthAbsorbColor = { 1, 1, 1, .5 },
	HealthCastOverlayColor = { 1, 1, 1, .5 },

	HealthBackdropPosition = { "CENTER", 1, -2 },
	HealthBackdropSize = { 140,90 },
	HealthBackdropTexture = GetMedia("cast_back"),
	HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	HealthValuePosition = { "CENTER", 0, 0 },
	HealthValueJustifyH = "CENTER",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(13, true),
	HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },

	-- Power
	-----------------------------------------
	PowerBarSize = { 72, 1 },
	PowerBarPosition = { "BOTTOM", 0, -1.5 + 10 },
	PowerBarTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBarOrientation = "RIGHT",
	PowerBackdropSize = { 74, 3 },
	PowerBackdropPosition = { "CENTER", 0, 0 },
	PowerBackdropTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBackdropColor = { 0, 0, 0, .75 },

	-- Portrait
	-----------------------------------------
	PortraitPosition = { "BOTTOM", 0, 22 + 10 },
	PortraitSize = { 70, 73 },
	PortraitAlpha = .85,
	PortraitBackgroundPosition = { "BOTTOM", 0, -6 },
	PortraitBackgroundSize = { 130, 130 },
	PortraitBackgroundTexture = GetMedia("party_portrait_back"),
	PortraitBackgroundColor = { .5, .5, .5 },
	PortraitShadePosition = { "BOTTOM", 0, 16 },
	PortraitShadeSize = { 86, 86 },
	PortraitShadeTexture = GetMedia("shade-circle"),
	PortraitBorderPosition = { "BOTTOM", 0, -38 },
	PortraitBorderSize = { 194, 194 },
	PortraitBorderTexture = GetMedia("party_portrait_border"),
	PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	-- Target Highlight Outline
	-----------------------------------------
	TargetHighlightPosition = { "CENTER", 1, -2 },
	TargetHighlightSize = { 140, 90 },
	TargetHighlightTexture = GetMedia("cast_back_outline"),
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },

	-- Ready Check
	-----------------------------------------
	ReadyCheckPosition = { "CENTER", 0, -7 + 10 },
	ReadyCheckSize = { 32, 32 },
	ReadyCheckReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-Ready]],
	ReadyCheckNotReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-NotReady]],
	ReadyCheckWaitingTexture = [[Interface/RAIDFRAME/ReadyCheck-Waiting]],

	-- Resurrection Indicator
	-----------------------------------------
	ResurrectIndicatorPosition = { "CENTER", 0, -7 + 10 },
	ResurrectIndicatorSize = { 32, 32 },
	ResurrectIndicatorTexture = [[Interface\RaidFrame\Raid-Icon-Rez]],

	-- Group Role
	-----------------------------------------
	GroupRolePosition = { "TOP", 0, 0 },
	GroupRoleSize = { 40, 40 },
	GroupRoleBackdropPosition = { "CENTER", 0, 0 },
	GroupRoleBackdropSize = { 77, 77 },
	GroupRoleBackdropTexture = GetMedia("point_plate"),
	GroupRoleBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	GroupRoleIconPositon = { "CENTER", 0, 0 },
	GroupRoleIconSize = { 34, 34 },
	GroupRoleDPSTexture = GetMedia("grouprole-icons-dps"),
	GroupRoleHealerTexture = GetMedia("grouprole-icons-heal"),
	GroupRoleTankTexture = GetMedia("grouprole-icons-tank"),

	-- Combat Feedback Text
	-----------------------------------------
	CombatFeedbackAnchorElement = "Portrait",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	-- Auras
	-----------------------------------------
	AurasPosition = { "BOTTOM", 0, -(34*2 + 22) + 10 },
	AurasSize = { 34*3 - 4, 34*2 - 4 },
	AuraSize = 30,
	AuraSpacing = 4,
	AurasNumTotal = 6,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "TOPLEFT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "RIGHT",
	AurasGrowthY = "DOWN",
	AurasTooltipAnchor = "ANCHOR_TOPLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING"
})
