--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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
local ActionBars = ns:GetModule("ActionBars", true)
if (not ActionBars) then return end

local BAR_ORDER = {
	1, BOTTOMLEFT_ACTIONBAR_PAGE, BOTTOMRIGHT_ACTIONBAR_PAGE, RIGHT_ACTIONBAR_PAGE, LEFT_ACTIONBAR_PAGE,
	MULTIBAR_5_ACTIONBAR_PAGE, MULTIBAR_6_ACTIONBAR_PAGE, MULTIBAR_7_ACTIONBAR_PAGE
}

local BAR_BINDS = {
	[BAR_ORDER[1]] = "ACTIONBUTTON%d",
	[BAR_ORDER[2]] = "MULTIACTIONBAR1BUTTON%d",
	[BAR_ORDER[3]] = "MULTIACTIONBAR2BUTTON%d",
	[BAR_ORDER[4]] = "MULTIACTIONBAR3BUTTON%d",
	[BAR_ORDER[5]] = "MULTIACTIONBAR4BUTTON%d",
	[BAR_ORDER[6]] = "MULTIACTIONBAR5BUTTON%d",
	[BAR_ORDER[7]] = "MULTIACTIONBAR6BUTTON%d",
	[BAR_ORDER[8]] = "MULTIACTIONBAR7BUTTON%d"
}
