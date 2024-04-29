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
local _, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Options = ns:GetModule("Options")

local getmodule = function()
	local module = ns:GetModule("ChatFrames", true)
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
		name = L["Chat Settings"],
		type = "group",
		args = {
			fadeOnInActivity = {
				name = L["Fade Chat"],
				desc = L["Fade chat after a period of inactiviy."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			timeVisible = {
				name = L["Time Visible"],
				desc = L["Sets the time visible before initiating the fade."],
				order = 51,
				type = "range", width = "full", min = 5, max = 120, step = 1,
				hidden = function(info) return isdisabled(info) or not getoption(info, "fadeOnInActivity") end,
				set = setter,
				get = getter
			},
			timeFading = {
				name = L["Time Fading"],
				desc = L["Sets the time spent fading before hiding the chat."],
				order = 51,
				type = "range", width = "full", min = 1, max = 5, step = 1,
				hidden = function(info) return isdisabled(info) or not getoption(info, "fadeOnInActivity") end,
				set = setter,
				get = getter
			},
			clearOnReload = {
				name = "Clear Chat Reload",
				desc = L["Keeps the chat window clear for a period after logging in or relaoding the user interface. Note that you can still show all chat if you hold down the SHIFT key while reloading or logging in."],
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			timeClearing = {
				name = "Sets the time after logon or reload until chat is allowed to pass through.",
				type = "range", width = "full", min = 1, max = 10, step = 1,
				hidden = function(info) return isdisabled(info) or not getoption(info, "clearOnReload") end,
				set = setter,
				get = getter
			}
		}
	}

	return options
end

Options:AddGroup(L["Chat"], GenerateOptions)
