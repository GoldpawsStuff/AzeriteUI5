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

ns.RegisterConfig("ExtraActionButton", {
	ExtraButtonSize = { 64, 64 },
	ExtraButtonMask = GetMedia("actionbutton-mask-circular"),

	ExtraButtonIconPosition = { "CENTER", 0, 0 },
	ExtraButtonIconSize = { 44, 44 },

	ExtraButtonCooldownPosition = { "CENTER", 0, 0 },
	ExtraButtonCooldownSize = { 44, 44 },
	ExtraButtonCooldownColor = { 0, 0, 0, .75 },

	ExtraButtonCooldownCountPosition = { "CENTER", 0, 0 },
	ExtraButtonCooldownCountJustifyH = "CENTER",
	ExtraButtonCooldownCountJustifyV = "MIDDLE",
	ExtraButtonCooldownCountFont = GetFont(22, true),
	ExtraButtonCooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	ExtraButtonBorderPosition = { "CENTER", 0, 0 },
	ExtraButtonBorderSize = { 134.295081967, 134.295081967 },
	ExtraButtonBorderTexture = GetMedia("actionbutton-border"),
	ExtraButtonBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3], 1 },

	ExtraButtonBindPosition = { "TOPLEFT", -10, -5 },
	ExtraButtonBindJustifyH = "CENTER",
	ExtraButtonBindJustifyV = "BOTTOM",
	ExtraButtonBindFont = GetFont(15, true),
	ExtraButtonBindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	ExtraButtonCountPosition = { "BOTTOMRIGHT", -3, 3 },
	ExtraButtonCountJustifyH = "CENTER",
	ExtraButtonCountJustifyV = "BOTTOM",
	ExtraButtonCountFont = GetFont(18, true),
	ExtraButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 }
})
