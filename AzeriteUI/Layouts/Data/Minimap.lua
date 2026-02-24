--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

local mapScale = 198/140

ns.RegisterConfig("Minimap", {
	CompassInset = 14,
	CompassFont = GetFont(16,true),
	CompassColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 },
	CompassNorthTag = "N",

	CoordinateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
	CoordinateFont = GetFont(12, true),
	CoordinatePlace = { "BOTTOM", 3, 23 },

	MailPosition = { "BOTTOM", 0, 30 },
	MailJustifyH = "CENTER",
	MailJustifyV = "BOTTOM",
	MailFont = GetFont(15, true),
	MailColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .85 },

	EyePosition = { "CENTER", math.cos((225 / mapScale)*(math.pi/180)) * ((280 / mapScale)/2 + 10), math.sin((225 / mapScale)*(math.pi/180)) * ((280 / mapScale)/2 + 10) },
	EyeSize = { 64, 64 },
	EyeTexture = GetMedia("group-finder-eye-green"),
	EyeTextureColor = { .90, .95, 1 },
	EyeTextureSize = { 64, 64 },
	EyeGroupSizePosition = { "BOTTOMRIGHT", 0, 0 },
	EyeGroupSizeFont = GetFont(15,true),
	EyeGroupStatusFramePosition = { "TOPRIGHT", QueueStatusMinimapButton, "BOTTOMLEFT", 0, 0 }
})
