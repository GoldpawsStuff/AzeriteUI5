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

local castBarSparkMap = {
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

ns.RegisterConfig("PlayerCastBar", {
	CastBarSize = { 112, 11 },
	CastBarTexture = GetMedia("cast_bar"),
	CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], .69 },
	CastBarOrientation = "RIGHT",
	CastBarSparkMap = castBarSparkMap,
	CastBarTimeToHoldFailed = .5,

	CastBarSpellQueueTexture = GetMedia("cast_bar"),
	CastBarSpellQueueColor = { 1, 1, 1, .5 },

	CastBarBackgroundPosition = { "CENTER", 1, -1 },
	CastBarBackgroundSize = { 193,93 },
	CastBarBackgroundTexture = GetMedia("cast_back"),
	CastBarBackgroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	CastBarTextPosition = { "TOP", 0, -26 },
	CastBarTextJustifyH = "CENTER",
	CastBarTextJustifyV = "MIDDLE",
	CastBarTextFont = GetFont(15, true),
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarValuePosition = { "CENTER", 0, 0 },
	CastBarValueJustifyH = "CENTER",
	CastBarValueJustifyV = "MIDDLE",
	CastBarValueFont = GetFont(14, true),
	CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarShieldPosition = { "CENTER", 1, -2 },
	CastBarShieldSize = { 193, 93 },
	CastBarShieldTexture = GetMedia("cast_back_spiked"),
	CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] }
})
