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
local _, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Options = ns:GetModule("Options")

local getmodule = function()
	local module = ns:GetModule("Tooltips", true)
	if (module and module:IsEnabled()) then
		return module
	end
end

local setter = function(info,val)
	getmodule().db.profile[info[#info]] = val
	getmodule():UpdateSettings()
end

local getter = function(info)
	return getmodule().db.profile[info[#info]]
end

local isdisabled = function(info)
	return info[#info] ~= "enabled" and not getmodule().db.profile.enabled
end

local setoption = function(info,option,val)
	getmodule().db.profile[option] = val
	getmodule():UpdateSettings()
end

local getoption = function(info,option)
	return getmodule().db.profile[option]
end

local GenerateOptions = function()
	if (not getmodule()) then return end

	local options = {
		name = L["Tooltip Settings"],
		type = "group",
		args = {
			elementsHeader = {
				name = L["Elements"],
				order = 1,
				type = "header", width = "full"
			},
			showItemID = {
				name = L["Show itemID"],
				desc = L["Toggle whether to add itemID to item tooltips or not."],
				order = 10,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			showSpellID = {
				name = L["Show spellID"],
				desc = L["Toggle whether to add spellIDs and auraIDs in tooltips containing actions, spells or auras."],
				order = 11,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			anchorHeader = {
				name = L["Position"],
				order = 19,
				type = "header", width = "full"
			},
			anchor = {
				name = L["Enable Anchoring"],
				desc = L["Control where the tooltips appear when put in the default position. Disable to let blizzard or other addons handle this."],
				order = 20,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			anchorToCursor = {
				name = L["Anchor to Cursor"],
				desc = L["Anchor tooltips that normally would appear in the default tooltip location to your cursor instead."],
				order = 21,
				type = "toggle", width = "full",
				disabled = function(info) return not getoption(info, "anchor") end,
				set = setter,
				get = getter
			}
		}
	}

	return options
end

Options:AddGroup(L["Tooltips"], GenerateOptions)
