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

ns.RegisterConfig("MirrorTimers", {
	MirrorTimerPosition = { "TOP", UIParent, "TOP", 0, -370 },
	MirrorTimerTimerSize = { 111 + 32, 12 + 28 },

	MirrorTimerBarPosition = { "CENTER", 0, 1 },
	MirrorTimerBarSize = { 111, 12 },
	MirrorTimerBarPadding = 20,
	MirrorTimerBarTexture = GetMedia("cast_bar"),
	MirrorTimerBarColor = { Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3] },

	MirrorTimerLabelPosition = { "CENTER", 0, 0 },
	MirrorTimerLabelFont = GetFont(14, true),
	MirrorTimerLabelColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .7 },

	MirrorTimerBackdropPosition = { "CENTER", 1, -2 },
	MirrorTimerBackdropSize = { 193,93 },
	MirrorTimerBackdropTexture = GetMedia("cast_back"),
	MirrorTimerBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] }
})
