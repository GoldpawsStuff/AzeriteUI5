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

-- Raid 25, Raid 40
ns.RegisterConfig("RaidFrames", {
	-- Header Position & Layut
	-----------------------------------------
	Position = { "TOPLEFT", UIParent, "TOPLEFT", 50, -42 }, -- raid header position
	Size = { 103*5, 56*8 }, -- size of the entire header frame area (must adjust to raid size?)

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

	-- Group Number
	-----------------------------------------
	GroupNumberColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
	GroupNumberDrawLayer = { "ARTWORK", 1 },
	GroupNumberFont = GetFont(11,true),
	GroupNumberJustifyH = "RIGHT",
	GroupNumberJustifyV = "BOTTOM",
	GroupNumberPlace = { "BOTTOMLEFT", 2, 2 },

	-- RaidTarget Indicator
	-----------------------------------------
	RaidTargetTexture = GetMedia("raid_target_icons_small"),

	-- Combat Feedback Text
	-----------------------------------------
	CombatFeedbackAnchorElement = "Health",
	CombatFeedbackPosition = { "CENTER", 0, 0 },
	CombatFeedbackFont = GetFont(20, true), -- standard font
	CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
	CombatFeedbackFontSmall = GetFont(18, true) -- glancing blow font

})
