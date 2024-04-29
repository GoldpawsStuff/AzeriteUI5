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
		{ keyPercent =   4/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 126/128, offset = -16/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	},
	bottom = {
		{ keyPercent =   0/128, offset = -16/32 },
		{ keyPercent =   4/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 126/128, offset = -16/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	}
}

ns.RegisterConfig("ArenaFrames", {

	-- General
	-----------------------------------------
	UnitSize = { 210, 86 }, -- raid member size
	OutOfRangeAlpha = .6, -- Alpha of out of range raid members

	-- Health
	-----------------------------------------
	HealthBarPosition = { "LEFT", 26, -13 },
	HealthBarSize = { 112, 11 },
	HealthBarTexture = GetMedia("cast_bar"),
	HealthBarOrientation = "LEFT",
	HealthBarSparkMap = barSparkMap,
	HealthAbsorbColor = { 1, 1, 1, .5 },
	HealthCastOverlayColor = { 1, 1, 1, .5 },

	HealthBackdropPosition = { "CENTER", 1, -2 },
	HealthBackdropSize = { 193,93 },
	HealthBackdropTexture = GetMedia("cast_back"),
	HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	HealthValuePosition = { "CENTER", 0, 0 },
	HealthValueJustifyH = "CENTER",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(12, true),
	HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },

	-- Power
	-----------------------------------------
	PowerBarSize = { 92, 1.1 },
	PowerBarPosition = { "LEFT", 36, -21 },
	PowerBarTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBarOrientation = "LEFT",
	PowerBarAlpha = .65,
	PowerBackdropSize = { 96.4, 3.3 },
	PowerBackdropPosition = { "CENTER", 0, 0 },
	PowerBackdropTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBackdropColor = { 0, 0, 0, 1 },

	-- Portrait
	-----------------------------------------
	PortraitPosition = { "LEFT", 146, 0 },
	PortraitSize = { 46, 47 },
	PortraitAlpha = .85,
	PortraitBackgroundPosition = { "LEFT", 128, 0 },
	PortraitBackgroundSize = { 87, 87 },
	PortraitBackgroundTexture = GetMedia("party_portrait_back"),
	PortraitBackgroundColor = { .5, .5, .5, .75 },
	PortraitShadePosition = { "LEFT", 142, 0 },
	PortraitShadeSize = { 58, 58 },
	PortraitShadeTexture = GetMedia("shade-circle"),
	PortraitBorderPosition = { "LEFT", 106, 0 },
	PortraitBorderSize = { 130, 130 },
	PortraitBorderTexture = GetMedia("party_portrait_border"),
	PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3], 1 },

	-- Trinket Icon
	-----------------------------------------
	TrinketFramePosition = { "LEFT", 106, 0 },
	TrinketFrameSize = { 130, 130 },
	TrinketIconPositon = { "CENTER", 0, 0 },
	TrinketIconSize = { 58, 58 },
	TrinketIconMask = GetMedia("actionbutton-mask-circular"),

	-- PvP Specialization Icon
	-----------------------------------------
	PvPSpecIconFramePosition = { "RIGHT", 22 - 1, -14 },
	PvPSpecIconFrameSize = { 58, 58 },
	PvPSpecIconBackdropPosition = { "CENTER", 0, 0 },
	PvPSpecIconBackdropSize = { 44, 44 },
	PvPSpecIconBackdropTexture = GetMedia("group-finder-eye-orange"),
	PvPSpecIconBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	PvPSpecIconIconPositon = { "CENTER", 0, 0 },
	PvPSpecIconIconSize = { 24, 24 },
	PvPSpecIconIconMask = GetMedia("actionbutton-mask-circular"),

	-- Target Highlighting
	-----------------------------------------
	TargetHighlightPosition = { "CENTER", 1, -2 },
	TargetHighlightSize = { 193,93 },
	TargetHighlightTexture = GetMedia("cast_back_outline"),
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },

	-- Unit Name
	-----------------------------------------
	NamePosition = { "RIGHT", -82, 13 },
	NameJustifyH = "RIGHT",
	NameJustifyV = "BOTTOM",
	NameFont = GetFont(11, true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Ready Check
	-----------------------------------------
	ReadyCheckPosition = { "CENTER", 64, 0 },
	ReadyCheckSize = { 32, 32 },
	ReadyCheckReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-Ready]],
	ReadyCheckNotReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-NotReady]],
	ReadyCheckWaitingTexture = [[Interface/RAIDFRAME/ReadyCheck-Waiting]],

	-- Auras
	-----------------------------------------
	AurasPosition = { "LEFT", 216 + 1, 2 },
	AurasSize = { 30*3 + 4*2, 30*2 + 4  },
	AuraSize = 30,
	AuraSpacing = 4,
	AurasNumBuffs = 3,
	AurasNumDebuffs = 3,
	AurasNumTotal = 6,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = true,
	AurasInitialAnchor = "BOTTOMLEFT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "RIGHT",
	AurasGrowthY = "UP",
	AurasTooltipAnchor = "ANCHOR_BOTTOMRIGHT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Combat Feedback Text
	-----------------------------------------
	CombatFeedbackAnchorElement = "Portrait",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true) -- glancing blow font

})
