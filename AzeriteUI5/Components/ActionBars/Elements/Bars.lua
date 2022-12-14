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

local BarMod = ActionBars:NewModule("Bars", "LibMoreEvents-1.0", "AceConsole-3.0")

local LAB10 = LibStub("LibActionButton-1.0")

-- Return blizzard barID by barnum.
local BAR_TO_ID = {
	[1] = 1,
	[2] = BOTTOMLEFT_ACTIONBAR_PAGE,
	[3] = BOTTOMRIGHT_ACTIONBAR_PAGE,
	[4] = RIGHT_ACTIONBAR_PAGE,
	[5] = LEFT_ACTIONBAR_PAGE,
	[6] = MULTIBAR_5_ACTIONBAR_PAGE,
	[7] = MULTIBAR_6_ACTIONBAR_PAGE,
	[8] = MULTIBAR_7_ACTIONBAR_PAGE
}

-- Return bindaction by blizzard barID.
local BINDTEMPLATE_BY_ID = {
	[BAR_TO_ID[1]] = "ACTIONBUTTON%d",
	[BAR_TO_ID[2]] = "MULTIACTIONBAR1BUTTON%d",
	[BAR_TO_ID[3]] = "MULTIACTIONBAR2BUTTON%d",
	[BAR_TO_ID[4]] = "MULTIACTIONBAR3BUTTON%d",
	[BAR_TO_ID[5]] = "MULTIACTIONBAR4BUTTON%d",
	[BAR_TO_ID[6]] = "MULTIACTIONBAR5BUTTON%d",
	[BAR_TO_ID[7]] = "MULTIACTIONBAR6BUTTON%d",
	[BAR_TO_ID[8]] = "MULTIACTIONBAR7BUTTON%d"
}

-- Return barnum by blizzard barID.
local ID_TO_BAR = {}
do
	for bar,id in next,BAR_TO_ID do
		ID_TO_BAR[id] = bar
	end
end

local defaults = {
	profile = {
		enabled = true,
		bars = {
			["**"] = {
				enabled = false,
				layout = "standard",
				buttons = 12,
				columns = 12,
				rows = 1,
				visibility = {
					overridebar = false,
					vehicleui = false
				}
			},
			[1] = { --[[ primary action bar ]]
				enabled = true,
				layout = "map",
				visibility = {
					overridebar = true,
					vehicleui = true
				}
			},
			[2] = { --[[ bottomleft multibar ]]
				enabled = false,
				layout = "map"
			},
			[3] = { --[[ bottomright multibar ]]
				enabled = false,
				colums = 1,
				rows = 12
			},
			[4] = { --[[ right multibar ]]
				enabled = false,
				colums = 1,
				rows = 12
			},
			[5] = { --[[ left multibar ]]
				enabled = false,
				colums = 1,
				rows = 12
			},
			[6] = { --[[]]
				enabled = false,
			},
			[7] = { --[[]]
				enabled = false,
			},
			[8] = { --[[]]
				enabled = false,
			}
		}
	}
}

BarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ActionBars", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

BarMod.OnEnable = function(self)
end

BarMod.OnDisable = function(self)
end