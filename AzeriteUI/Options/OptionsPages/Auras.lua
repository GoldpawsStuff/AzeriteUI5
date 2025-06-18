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
local _, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Options = ns:GetModule("Options")

-- Lua API
local math_floor = math.floor
local string_match = string.match
local tonumber = tonumber
local tostring = tostring

local getmodule = function()
	local module = ns:GetModule("Auras", true)
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
		name = L["Aura Settings"],
		type = "group",
		args = {
			description = {
				name = L["Here you can change settings related to the aura buttons appearing by default in the top right corner of the screen. None of these settings apply to the aura buttons found at the unitframes."],
				order = 1,
				type = "description",
				fontSize = "medium"
			},
			enabled = {
				name = L["Enable"],
				desc = L["Toggle whether to show the player aura buttons or not."],
				order = 2,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			visibilityHeader = {
				name = L["Visibility"],
				order = 3,
				type = "header",
				hidden = isdisabled
			},
			visibilityDesc = {
				name = L["Choose when your auras will be visible."],
				order = 4,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			enableAuraFading = {
				name = L["Enable Aura Fading"],
				desc = L["Toggle whether to enable the player aura buttons to fade out when not moused over."],
				order = 10,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			enableModifier = {
				name = L["Enable Modifier Key"],
				desc = L["Require a modifier key to show the auras."],
				order = 20,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			modifier = {
				name = L["Modifier Key"],
				desc = L["Choose which modifier key to hold  down to show the aura buttons."],
				order = 21,
				hidden = isdisabled,
				disabled = function(info) return isdisabled(info) or not getoption(info, "enableModifier") end,
				type = "select", style = "dropdown",
				values = {
					["ALT"] = ALT_KEY_TEXT,
					["SHIFT"] = SHIFT_KEY_TEXT,
					["CTRL"] = CTRL_KEY_TEXT
				},
				set = setter,
				get = getter
			},
			ignoreTarget = {
				name = L["Ignore current target"],
				desc = L["Normally auras will be hidden when you have a target, as their position directly conflicts with the position of the target frame. By enabling this the auras will ignore your target and remain visible."],
				order = 22,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			layoutHeader = {
				name = L["Layout"],
				order = 30,
				type = "header",
				hidden = isdisabled
			},
			layoutDesc = {
				name = L["Choose how your auras are displayed."],
				order = 31,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			anchorPoint = {
				name = L["Anchor Point"],
				desc = L["Sets the anchor point."],
				order = 32,
				hidden = isdisabled,
				type = "select", style = "dropdown",
				values = {
					["TOPLEFT"] = L["Top-Left Corner"],
					["TOP"] = L["Top Center"],
					["TOPRIGHT"] = L["Top-Right Corner"],
					["RIGHT"] = L["Middle Right Side"],
					["BOTTOMRIGHT"] = L["Bottom-Right Corner"],
					["BOTTOM"] = L["Bottom Center"],
					["BOTTOMLEFT"] = L["Bottom-Left Corner"],
					["LEFT"] = L["Middle Left Side"],
					["CENTER"] = L["Center"]
				},
				set = setter,
				get = getter
			},
			anchorPointSpace = {
				name = "", order = 33, type = "description",
				hidden = isdisabled
			},
			growthX = {
				name = L["Horizontal Growth"],
				desc = L["Choose which horizontal direction the aura buttons should expand in."],
				order = 41,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["RIGHT"] = L["Right"],
					["LEFT"] = L["Left"],
				},
				set = setter,
				get = getter
			},
			growthY = {
				name = L["Vertical Growth"],
				desc = L["Choose which vertical direction the aura buttons should expand in."],
				order = 42,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["DOWN"] = L["Down"],
					["UP"] = L["Up"],
				},
				set = setter,
				get = getter
			},
			growthSpace = {
				name = "", order = 50, type = "description", hidden = isdisabled
			},
			paddingX = {
				name = L["Horizontal Padding"],
				desc = L["Sets the horizontal padding between your aura buttons."],
				order = 51,
				type = "range", width = "full", min = 0, max = 12, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			paddingY = {
				name = L["Vertical Padding"],
				desc = L["Sets the horizontal padding between your aura buttons."],
				order = 52,
				type = "range", width = "full", min = 6, max = 18, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			wrapAfter = {
				name = L["Buttons Per Row"],
				desc = L["Sets the maximum number of aura buttons per row."],
				order = 53,
				type = "range", width = "full", min = 1, max = 16, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			}
		}
	}

	return options
end

Options:AddGroup(L["Player Auras"], GenerateOptions)
