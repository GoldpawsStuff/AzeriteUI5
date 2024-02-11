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

ns.RegisterConfig("TargetFrame", {

	-- General Settings
	-----------------------------------------
	Size = { 550, 210 },
	HitRectInsets = { 0, 0, 0, 60 },
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
	PowerBarPosition = { "TOPRIGHT", 8, -58 }, -- "CENTER", 188, -51
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
	NamePosition = { "TOPRIGHT", -153, -21 },
	NameSize = { 250, 18 },
	NameJustifyH = "RIGHT",
	NameJustifyV = "TOP",
	NameFont = GetFont(18, true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

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

	-- PvP Indicator
	-----------------------------------------
	PvPIndicatorPosition = { "TOPRIGHT", -41, -91 },
	PvPIndicatorSize = { 84, 84 },
	PvPIndicatorAllianceTexture = GetMedia("icon_badges_alliance"),
	PvPIndicatorHordeTexture = GetMedia("icon_badges_horde"),

	-- Classification
	-----------------------------------------
	ClassificationPosition = { "TOPRIGHT", -41, -91 },
	ClassificationSize = { 84, 84 },
	ClassificationAllianceTexture = GetMedia("icon_badges_alliance"),
	ClassificationBossTexture = GetMedia("icon_badges_boss"),
	ClassificationEliteTexture = GetMedia("icon_classification_elite"),
	ClassificationHordeTexture = GetMedia("icon_badges_horde"),
	ClassificationRareTexture = GetMedia("icon_classification_rare"),

	-- Target Indicator
	-----------------------------------------
	TargetIndicatorPosition = { "TOPRIGHT", -75, -3 },
	TargetIndicatorSize = { 96, 48 },
	TargetIndicatorColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
	TargetIndicatorPetByEnemyTexture = GetMedia("icon_target_blue"),
	TargetIndicatorYouByEnemyTexture = GetMedia("icon_target_red"),
	TargetIndicatorYouByFriendTexture = GetMedia("icon_target_green"),

	-- Auras
	-----------------------------------------
	AurasPosition = { "TOPRIGHT", -150, -126 },
	AurasSize = { 316, 76 },
	AurasSizeBoss = { 396, 76 },
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
	AurasGrowthY = "DOWN",
	AurasTooltipAnchor = "ANCHOR_BOTTOMLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Seasonal Overrides & Additions
	-----------------------------------------
	Seasonal = {
		-- Love Festival Target Eye
		LoveFestivalCombatIndicatorPosition = { "TOPRIGHT", -99, -3 },
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
		-----------------------------------------
		HealthBarSize = { 40, 36 },
		HealthBarPosition = { "TOPRIGHT", -137, -66 },
		HealthBarTexture = GetMedia("hp_critter_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = tinyBarSparkMap,
		HealthBackdropSize = { 105, 104 },
		HealthBackdropPosition = { "TOPRIGHT", -104, -28.5 },
		HealthBackdropTexture = GetMedia("hp_critter_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 105, 104 },
		HealthThreatPosition = { "TOPRIGHT", -104, -28.5 },
		HealthThreatTexture = GetMedia("hp_critter_case_glow"),

		-- Portrait
		-----------------------------------------
		PortraitBorderTexture = GetMedia("portrait_frame_lo"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Portrait Threat
		PortraitThreatSize = { 187, 187 },
		PortraitThreatPosition = { "CENTER", -1, 3 },
		PortraitThreatTexture = GetMedia("portrait_frame_glow"),

	},
	Novice = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -140, -66 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "TOPRIGHT", 24.5, 8.5 },
		HealthBackdropTexture = GetMedia("hp_low_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "TOPRIGHT", 24.5, 8.5 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Portrait
		-----------------------------------------
		PortraitBorderTexture = GetMedia("portrait_frame_lo"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Portrait Threat
		PortraitThreatSize = { 187, 187 },
		PortraitThreatPosition = { "CENTER", -1, 3 },
		PortraitThreatTexture = GetMedia("portrait_frame_glow"),

	},
	Hardened = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -140, -66 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "TOPRIGHT", 24.5, 7.5 },
		HealthBackdropTexture = GetMedia("hp_mid_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "TOPRIGHT", 24.5, 7.5 },
		HealthThreatTexture = GetMedia("hp_mid_case_glow"),

		-- Portrait
		-----------------------------------------
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Portrait Threat
		PortraitThreatSize = { 187, 187 },
		PortraitThreatPosition = { "CENTER", -1, 3 },
		PortraitThreatTexture = GetMedia("portrait_frame_glow"),

	},
	Seasoned = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "TOPRIGHT", -140, -66 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "TOPRIGHT", 23.5, 8.5 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "TOPRIGHT", 23.5, 8.5 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

		-- Portrait
		-----------------------------------------
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Portrait Threat
		PortraitThreatSize = { 187, 187 },
		PortraitThreatPosition = { "CENTER", -1, 3 },
		PortraitThreatTexture = GetMedia("portrait_frame_glow"),

	},
	Boss = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 533, 40 },
		HealthBarPosition = { "TOPRIGHT", -140, -66 },
		HealthBarTexture = GetMedia("hp_boss_bar"),
		HealthBarOrientation = "LEFT",
		HealthBarSparkMap = bigBarSparkMap,
		HealthBackdropSize = { 697, 192 },
		HealthBackdropPosition = { "TOPRIGHT", -58, 10.5 },

		HealthBackdropTexture = GetMedia("hp_boss_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 697, 192 },
		HealthThreatPosition = { "TOPRIGHT", -58, 10.5 },
		HealthThreatTexture = GetMedia("hp_boss_case_glow"),

		-- Portrait
		-----------------------------------------
		PortraitBorderTexture = GetMedia("portrait_frame_hi"),
		PortraitBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Portrait Threat
		PortraitThreatSize = { 187, 187 },
		PortraitThreatPosition = { "CENTER", -1, 3 },
		PortraitThreatTexture = GetMedia("portrait_frame_glow"),

	}
})
