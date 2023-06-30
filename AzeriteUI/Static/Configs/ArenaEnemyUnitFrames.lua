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

	Size = { 136, 47 },
	HitRectInsets = { -20, -20, -20, -10 },

	-- Health
	-----------------------------------------
	HealthBarPosition = { "CENTER", 0, 0 },
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
	HealthValueFont = GetFont(14, true),
	HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },

	-- Power
	-----------------------------------------
	PowerBarPosition = { "CENTER", 0, -1.5 },
	PowerBarSize = { 104, 1 },
	PowerBarTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBarOrientation = "LEFT",
	PowerBackdropSize = { 74, 3 },
	PowerBackdropPosition = { "CENTER", 0, 0 },
	PowerBackdropTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	PowerBackdropColor = { 0, 0, 0, .75 },

	-- Portrait
	-----------------------------------------
	PortraitPosition = { "TOPRIGHT", -40, -31 },
	PortraitSize = { 85, 85 },
	PortraitAlpha = .85,
	PortraitBackgroundPosition = { "TOPRIGHT", 3, 16 },
	PortraitBackgroundSize = { 173, 173 },
	PortraitBackgroundTexture = GetMedia("party_portrait_back"),
	PortraitBackgroundColor = { .5, .5, .5 },
	PortraitShadePosition = { "TOPRIGHT", -30, -18 },
	PortraitShadeSize = { 107, 107 },
	PortraitShadeTexture = GetMedia("shade-circle"),
	PortraitBorderPosition = { "TOPRIGHT", 10, 22 },
	PortraitBorderSize = { 187, 187 },

	-- Unit Name
	-----------------------------------------
	NamePosition = { "BOTTOMRIGHT", -12, 52 },
	NameJustifyH = "CENTER",
	NameJustifyV = "TOP",
	NameFont = GetFont(14, true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Target Highlighting
	-----------------------------------------
	TargetHighlightPosition = { "CENTER", 1, -2 },
	TargetHighlightSize = { 193,93 },
	TargetHighlightTexture = GetMedia("cast_back_outline"),
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },

	-- Combat Feedback Text
	-----------------------------------------
	CombatFeedbackAnchorElement = "Health",
	CombatFeedbackPosition = { "BOTTOM", 0, -20 }, -- must adjust this
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	-- Auras
	-----------------------------------------
	AurasPosition = { "RIGHT", -149, -1 },
	AurasSize = { 30*3 + 2*5, 30*2 + 5  },
	AuraSize = 30,
	AuraSpacing = 4,
	AurasNumTotal = 6,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "TOPRIGHT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "LEFT",
	AurasGrowthY = "DOWN",
	AurasTooltipAnchor = "ANCHOR_TOPLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING"
})
