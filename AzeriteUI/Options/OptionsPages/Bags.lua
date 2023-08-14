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
	local module = ns:GetModule("Containers", true)
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
		name = L["Bag Settings"],
		type = "group",
		args = {}
	}

	if (C_Container.SetSortBagsRightToLeft) then
		options.args["sort"] = {
			name = L["Sort Direction"],
			desc = L["Choose in which direction items in your bags are sorted."],
			type = "select", style = "dropdown",
			order = 1,
			values = {
				["ltr"] = L["Left to Right"],
				["rtl"] = L["Right to Left"]
			},
			set = setter,
			get = getter
		}
		options.args.space1 = {
			name = "", order = 2, type = "description", hidden = isdisabled
		}

	end

	if (C_Container.SetInsertItemsLeftToRight) then
		options.args["insert"] = {
			name = L["Insert Point"],
			desc = L["Choose from which side new items are inserted into your bags."],
			type = "select", style = "dropdown",
			order = 3,
			values = {
				["rtl"] = L["Right to Left"],
				["ltr"] = L["Left to Right"]
			},
			set = setter,
			get = getter
		}
		options.args.space2 = {
			name = "", order = 4, type = "description", hidden = isdisabled
		}
	end

	return options
end

Options:AddGroup(L["Bags"], GenerateOptions)
