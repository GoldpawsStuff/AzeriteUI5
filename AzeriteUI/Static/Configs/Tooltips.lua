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

ns.RegisterConfig("Tooltips", {

	themes = {
		Classic = {
			barStyle = {
				texture = GetMedia("bar-progress"),
				offsetLeft = -1,
				offsetRight = -1,
				offsetBottom = -4,
				height = 4,
				valuePosition = { "CENTER", 0, 0 },
				valueFont = GetFont(13, true),
				valueColor = Colors.offwhite
			},
			backdropStyle = {
				offsetLeft = -6,
				offsetRight = 6,
				offsetTop = 6,
				offsetBottom = -6,
				offsetBar = 0,
				offsetBarBottom = -2,
				backdropColor = { .05, .05, .05, .95 },
				backdropBorderColor = { .6, .6, .6, 1 },
				backdrop = {
					bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					edgeSize = 16, edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
					tile = true,
					insets = { left = 4, right = 4, top = 4, bottom = 4 }
				}
			}
		},
		Azerite = {
			barStyle = {
				texture = GetMedia("bar-progress"),
				offsetLeft = -1,
				offsetRight = -1,
				offsetBottom = -4,
				height = 4,
				valuePosition = { "CENTER", 0, 0 },
				valueFont = GetFont(13, true),
				valueColor = Colors.offwhite
			},
			backdropStyle = {
				offsetLeft = -10,
				offsetRight = 10,
				offsetTop = 18,
				offsetBottom = -18,
				offsetBar = 0,
				offsetBarBottom = -6,
				backdropColor = { .05, .05, .05, .95 },
				backdropBorderColor = { 1, 1, 1, 1 },
				backdrop = {
					bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
					tile = true,
					insets = { left = 8, right = 8, top = 16, bottom = 16 }
				}
			}
		}
	}

})