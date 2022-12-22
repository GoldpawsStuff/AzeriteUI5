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

local ActionBarMod = ns:NewModule("ActionBars", "LibMoreEvents-1.0", "AceConsole-3.0")

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

local defaults = { profile = ns:Merge({
	enabled = true,
	bars = {
		["**"] = ns:Merge({
		}, ns.ActionBar.defaults),
		[1] = { --[[ primary action bar ]]
			layout = "map",
			maptype = "azerite",
			visibility = {
				dragon = true,
				possess = true,
				overridebar = true,
				vehicleui = true
			}
		},
		[2] = { --[[ bottomleft multibar ]]
			enabled = false,
			layout = "map",
			maptype = "zigzag",
		},
		[3] = { --[[ bottomright multibar ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			}
		},
		[4] = { --[[ right multibar 1 ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			}
		},
		[5] = { --[[ right multibar 2 ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			}
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
}, ns.moduleDefaults) }

-- Returns a localized named usable for our movable frame anchor.
ActionBarMod.GetBarDisplayName = function(self, id)
	local barID = tonumber(id)
	if (barID == RIGHT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR3_TEXT -- "Right Action Bar 1"
	elseif (barID == LEFT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR4_TEXT -- "Right Action Bar 2"
	else
		return HUD_EDIT_MODE_ACTION_BAR_LABEL:format(barID) -- "Action Bar %d"
	end
end

ActionBarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ActionBars", defaults)

	self.bars = {}

	self:SetEnabledState(self.db.profile.enabled)

end

ActionBarMod.OnEnable = function(self)
	if (next(self.bars)) then
		for i,bar in ipairs(self.bars) do
			bar:SetEnabled(bar.config.enabled)
		end
		return
	end

	for i = 1,8 do
		local bar = ns.ActionBar:Create(BAR_TO_ID[i], ns.Prefix.."ActionBar"..i, self.db.profile.bars[i])

		self.bars[i] = bar
	end
end

ActionBarMod.OnDisable = function(self)
	if (not next(self.bars)) then return end

	for i,bar in ipairs(self.bars) do
		bar:Disable()
	end
end
