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

local crystalSparkMap = {
	top = {
		{ keyPercent =   0/256, offset =  -65/256 },
		{ keyPercent =  72/256, offset =    0/256 },
		{ keyPercent = 116/256, offset =  -16/256 },
		{ keyPercent = 128/256, offset =  -28/256 },
		{ keyPercent = 256/256, offset =  -84/256 }
	},
	bottom = {
		{ keyPercent =   0/256, offset =  -47/256 },
		{ keyPercent =  84/256, offset =    0/256 },
		{ keyPercent = 135/256, offset =  -24/256 },
		{ keyPercent = 142/256, offset =  -32/256 },
		{ keyPercent = 225/256, offset =  -79/256 },
		{ keyPercent = 256/256, offset = -168/256 }
	}
}

ns.RegisterConfig("PlayerFrame", {

	-- General Settings
	-----------------------------------------
	Size = { 560, 180 },
	HitRectInsets = { 0, 0, 30, -2 },

	-- Health Value Text
	HealthValuePosition = { "LEFT", 27, 4 },
	HealthValueJustifyH = "LEFT",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(18, true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	-- Mana Value Text (when mana is not primary resource)
	ManaTextPosition = { "CENTER", 1, -34 },
	ManaTextFont = GetFont(15, true),
	ManaTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },
	ManaTextJustifyH = "CENTER",
	ManaTextJustifyV = "MIDDLE",

	-- Power Value Text
	PowerValuePosition = { "CENTER", 0, -16 },
	PowerValueJustifyH = "CENTER",
	PowerValueJustifyV = "MIDDLE",
	PowerValueFont = GetFont(18, true),
	PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Mana Orb Value Text
	ManaValuePosition = { "CENTER", 3, 0 },
	ManaValueJustifyH = "CENTER",
	ManaValueJustifyV = "MIDDLE",
	ManaValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },
	ManaValueFont = GetFont(18, true),

	-- Castbar Name Text
	CastBarTextFont = GetFont(16, true),
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
	CastBarTextProtectedColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 },

	-- Castbar Value Text
	CastBarValuePosition = { "RIGHT", -27, 4 },
	CastBarValueJustifyH = "CENTER",
	CastBarValueJustifyV = "MIDDLE",
	CastBarValueFont = GetFont(18, true),
	CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },

	-- Combat Feedback Text
	CombatFeedbackAnchorElement = "Health",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	-- Combat Indicator
	CombatIndicatorPosition = { "BOTTOMLEFT", 40, -18 },
	CombatIndicatorSize = { 80,80 },
	CombatIndicatorTexture = GetMedia("icon-combat"),
	CombatIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },

	-- PvP Indicator
	PvPIndicatorPosition = { "BOTTOMLEFT", 40, -18 },
	PvPIndicatorSize = { 84, 84 },
	PvPIndicatorAllianceTexture = GetMedia("icon_badges_alliance"),
	PvPIndicatorHordeTexture = GetMedia("icon_badges_horde"),

	-- Auras
	-----------------------------------------
	AurasPosition = { "BOTTOMLEFT", 158, 91 },
	AurasSize = { 40*8 - 4, 40*2 - 4 },
	AuraSize = 36,
	AuraSpacing = 4,
	AurasNumTotal = 16,
	AurasDisableMouse = false,
	AurasDisableCooldown = false,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "BOTTOMLEFT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "RIGHT",
	AurasGrowthY = "UP",
	AurasTooltipAnchor = "ANCHOR_TOPLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Seasonal Overrides & Additions
	-----------------------------------------
	Seasonal = {
		-- Love Festival Combat Indicator
		LoveFestivalCombatIndicatorPosition = { "BOTTOMLEFT", 60, 2 },
		LoveFestivalCombatIndicatorSize = { 48, 48 },
		LoveFestivalCombatIndicatorTexture = GetMedia("icon-heart-red"),
		LoveFestivalCombatIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },

		-- Winter Veil Power Crystal Decorations
		WinterVeilPowerSize = { 197, 197 },
		WinterVeilPowerPlace = { "CENTER", -2, 24 },
		WinterVeilPowerTexture = GetMedia("seasonal_winterveil_crystal"),

		-- Winter Veil Mana Orb Decorations
		WinterVeilManaSize = { 188, 188 },
		WinterVeilManaPlace = { "CENTER", 0, 0 },
		WinterVeilManaTexture = GetMedia("seasonal_winterveil_orb")
	},

	-- Orb and Crystal Colors
	-----------------------------------------
	-- Note that we specifically avoid red colors
	-- as this would clash horribly with our health bar.
	PowerOrbColors = {
		ENERGY = { 255/255, 208/255, 125/255 }, -- Automatic regen, fast, starts at max
		FOCUS = { 116/255, 156/255, 255/255 }, -- Dynamic regen, fast, starts low
		LUNAR_POWER = { 116/255, 156/255, 255/255 },
		MAELSTROM = { 116/255, 156/255, 255/255 },
		RUNIC_POWER = { 116/255, 156/255, 255/255 },
		FURY = { 156/255, 116/255, 255/255 }, -- Dynamic regen, slow, starts at zero
		INSANITY = { 156/255, 116/255, 255/255 },
		PAIN = { 156/255, 116/255, 255/255 },
		RAGE = { 156/255, 116/255, 255/255 },
		MANA = { 135/255, 125/255, 255/255 } -- Fantasy archetype
	},
	PowerBarColors = {
		ENERGY = { 0/255, 208/255, 176/255 }, -- Automatic regen, fast, starts at max
		FOCUS = { 116/255, 156/255, 255/255 }, -- Dynamic regen, fast, starts low
		LUNAR_POWER = { 116/255, 156/255, 255/255 },
		MAELSTROM = { 116/255, 156/255, 255/255 },
		RUNIC_POWER = { 116/255, 156/255, 255/255 },
		FURY = { 156/255, 116/255, 255/255 }, -- Dynamic regen, slow, starts at zero
		INSANITY = { 156/255, 116/255, 255/255 },
		PAIN = { 156/255, 116/255, 255/255 },
		RAGE = { 156/255, 116/255, 255/255 },
		MANA = { 101/255, 93/255, 191/255 } -- Fantasy archetype
	},

	-- Level Specific Settings
	-----------------------------------------
	Novice = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 148, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "BOTTOMLEFT", -17, -48 },
		HealthBackdropTexture = GetMedia("hp_low_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "BOTTOMLEFT", -15, -47 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Power Crystal
		-----------------------------------------
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", 20, 38 },
		PowerBarTexture = GetMedia("power_crystal_front"),
		PowerBarTextureWrath = GetMedia("power-crystal-ice-front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = GetMedia("power_crystal_back"),
		PowerBackdropTextureWrath = GetMedia("power-crystal-ice-back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case_low"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Power Crystal Threat
		PowerBarThreatSize = { 196, 196 },
		PowerBarThreatPosition = { "CENTER", 0, 1 },
		PowerBarThreatTexture = GetMedia("power_crystal_glow"),

		PowerBackdropThreatSize = { 198,98 },
		PowerBackdropThreatPosition = { "BOTTOM", 7, -51 },
		PowerBackdropThreatTexture = GetMedia("pw_crystal_case_glow"),

		-- Mana Orb
		-----------------------------------------
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", 29, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_low"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb Threat
		ManaOrbThreatSize = { 188, 188 },
		ManaOrbThreatPosition = { "CENTER", 0, 0 },
		ManaOrbThreatTexture = GetMedia("orb_case_glow")

	},
	Hardened = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 148, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "BOTTOMLEFT", -17, -48 },
		HealthBackdropTexture = GetMedia("hp_mid_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "BOTTOMLEFT", -15, -47 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Power Crystal
		-----------------------------------------
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", 20, 38 },
		PowerBarTexture = GetMedia("power_crystal_front"),
		PowerBarTextureWrath = GetMedia("power-crystal-ice-front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = GetMedia("power_crystal_back"),
		PowerBackdropTextureWrath = GetMedia("power-crystal-ice-back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Power Crystal Threat
		PowerBarThreatSize = { 196, 196 },
		PowerBarThreatPosition = { "CENTER", 0, 1 },
		PowerBarThreatTexture = GetMedia("power_crystal_glow"),

		PowerBackdropThreatSize = { 198,98 },
		PowerBackdropThreatPosition = { "BOTTOM", 7, -51 },
		PowerBackdropThreatTexture = GetMedia("pw_crystal_case_glow"),

		-- Mana Orb
		-----------------------------------------
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", 29, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb Threat
		ManaOrbThreatSize = { 188, 188 },
		ManaOrbThreatPosition = { "CENTER", 0, 0 },
		ManaOrbThreatTexture = GetMedia("orb_case_glow")

	},
	Seasoned = {

		-- Health Bar
		-----------------------------------------
		HealthBarSize = { 385, 40 },
		HealthBarPosition = { "BOTTOMLEFT", 148, 27 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = barSparkMap,
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "BOTTOMLEFT", -17, -48 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthAbsorbColor = { 1, 1, 1, .35 },
		HealthCastOverlayColor = { 1, 1, 1, .35 },

		-- Health Bar Threat
		HealthThreatSize = { 716, 188 },
		HealthThreatPosition = { "BOTTOMLEFT", -15, -47 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Power Crystal
		-----------------------------------------
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", 20, 38 },
		PowerBarTexture = GetMedia("power_crystal_front"),
		PowerBarTextureWrath = GetMedia("power-crystal-ice-front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = crystalSparkMap,

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = GetMedia("power_crystal_back"),
		PowerBackdropTextureWrath = GetMedia("power-crystal-ice-back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Power Crystal Threat
		PowerBarThreatSize = { 196, 196 },
		PowerBarThreatPosition = { "CENTER", 0, 1 },
		PowerBarThreatTexture = GetMedia("power_crystal_glow"),

		PowerBackdropThreatSize = { 198,98 },
		PowerBackdropThreatPosition = { "BOTTOM", 7, -51 },
		PowerBackdropThreatTexture = GetMedia("pw_crystal_case_glow"),

		-- Mana Orb
		-----------------------------------------
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", 29, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb Threat
		ManaOrbThreatSize = { 188, 188 },
		ManaOrbThreatPosition = { "CENTER", 0, 0 },
		ManaOrbThreatTexture = GetMedia("orb_case_glow")
	}
})
