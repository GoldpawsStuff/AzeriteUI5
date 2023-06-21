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

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local Options = ns:GetModule("Options")
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local string_format = string.format

local getmodule = function()
	return ns:GetModule("Minimap", true)
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
		name = L["Minimap Settings"],
		type = "group",
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Clock Settings"]
			},
			useHalfClock = {
				name = L["24 Hour Mode"],
				desc = string_format(L["Enable to use a 24 hour clock, disable to show a 12 hour clock with %s/%s suffixes."], TIMEMANAGER_AM, TIMEMANAGER_PM),
				order = 10,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = function(info,val) setter(info, not val) end,
				get = function(info) return not getter(info) end
			},
			useServerTime = {
				name = L["Use Local Time"],
				desc = L["Set the clock to your computer's local time, disable to show the server time instead."],
				order = 11,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = function(info,val) setter(info, not val) end,
				get = function(info) return not getter(info) end
			}
		}
	}

	return options
end

Options:AddGroup(L["Minimap"], GenerateOptions)
