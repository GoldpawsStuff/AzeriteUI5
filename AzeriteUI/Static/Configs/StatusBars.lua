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

local mapScale = ns.WoW10 and 1 or 198/140

ns.RegisterConfig("StatusBars", {

	-- Toggle Button
	ButtonPosition = (not ns.IsRetail) and { "CENTER", Minimap, "BOTTOM", 0, -6 } or { "CENTER", Minimap, "BOTTOM", 2, -6 },
	ButtonSize = { 56, 56 },
	ButtonTexturePosition = { "CENTER", 0, 0 },
	ButtonTextureSize = { 100, 100 },
	ButtonTexturePath = GetMedia("point_plate"),
	ButtonTextureColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	-- Frame
	RingFramePosition = { "CENTER", Minimap, "CENTER", 0, 0 },
	RingFrameSize = { 213, 213 },
	RingFrameBackdropPosition = { "CENTER", 0, 0 },
	RingFrameBackdropSize = { 410, 410 },
	RingFrameBackdropTexture = GetMedia("minimap-onebar-backdrop"),
	RingFrameBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	-- Ring
	RingPosition = { "CENTER", 0, 2 },
	RingSize = { 208, 208 },
	RingTexture = GetMedia("minimap-bars-single"),
	RingSparkOffset = -1/10, -- offset in degrees from the end of the bar to the spark
	RingSparkInset = (24 * 208/256)/mapScale, -- distance from outer diameter to start of spark
	RingSparkFlash = { nil, nil, 1, 1 },
	RingSparkSize = { 34 * 208/256, 30/mapScale }, -- width = thickness along ring bar, height = length across
	RingDegreeOffset = 90*3 - 14, -- offset from top center in degrees to the start of the ring bar
	RingDegreeSpan = 360 - 14*2, -- degrees of the circle covered by the bar

	-- Ring Value Text
	RingValuePosition = { "CENTER", 0, 1 },
	RingValueJustifyH = "CENTER",
	RingValueJustifyV = "MIDDLE",
	RingValueFont = GetFont(24, true),

	-- Ring Value Description
	RingValueDescriptionPosition = { "CENTER", 0, -16 },
	RingValueDescriptionJustifyH = "CENTER",
	RingValueDescriptionJustifyV = "MIDDLE",
	RingValueDescriptionWidth = 100,
	RingValueDescriptionFont = GetFont(12, true),
	RingValueDescriptionColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3] },

	-- Button Percentage Text
	RingPercentPosition = { "CENTER", 0, 0 },
	RingPercentJustifyH = "CENTER",
	RingPercentJustifyV = "MIDDLE",
	RingPercentFont = GetFont(15, true)
})
