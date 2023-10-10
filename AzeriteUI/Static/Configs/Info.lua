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

ns.RegisterConfig("Info", {

	ClockPosition = { "BOTTOMRIGHT", -2, 2 },
	ClockFont = GetFont(15,true),
	ClockColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },

	-- About 8px to the left of the clock.
	ZoneTextPosition = { "BOTTOMRIGHT", -60 -2, 2 },
	ZoneTextPositionHalfClock = { "BOTTOMRIGHT", -(60 + 20) -2, 2 },
	ZoneTextFont = GetFont(15,true),
	ZoneTextAlpha = .85,

	-- About 6px Above the clock, slightly indented towards the left.
	FrameRatePosition = { "BOTTOMRIGHT", -6 -2, 15 + 6 + 2 },
	FrameRateFont = GetFont(12,true),
	FrameRateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

	-- To the left of the framerate, right above the zone text.
	LatencyPosition = { "BOTTOMRIGHT", -60 -2, 15 + 6 + 2 },
	LatencyPositionHalfClock = { "BOTTOMRIGHT", -(60 + 20) -2, 15 + 6 + 2 },
	LatencyFont = GetFont(12,true),
	LatencyColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 }
})
