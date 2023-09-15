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

-- Lua API
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local next = next
local string_format = string.format
local string_match = string.match
local tonumber = tonumber
local tostring = tostring

local getmodule = function()
	local module = ns:GetModule("ActionBars", true)
	if (module and module:IsEnabled()) then
		return module
	end
end

local setter = function(info,val)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	db[info[#info]] = val
	getmodule():UpdateSettings()
end

local getter = function(info)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	return db[info[#info]]
end

local isdisabled = function(info)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	return info[#info] ~= "enabled" and not db.enabled
end

local getsetting = function(info, setting)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	return db[setting]
end

local setoption = function(info,option,val)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	db[option] = val
	getmodule():UpdateSettings()
end

local getoption = function(info,option)
	local id = tonumber((string_match(info[#info - 1],"(%d+)")))
	local db = getmodule().db.profile.bars[id]
	return db[option]
end

local GenerateIndexedBarOptions = function(moduleName, displayName, order)
	local getmodule = function()
		local module = ns:GetModule(moduleName, true)
		if (module and module:IsEnabled()) then
			return module
		end
	end
	if (not getmodule(moduleName)) then return end
	local options = {
		name = displayName,
		order = order,
		type = "group",
		args = {
			enabled = {
				name = L["Enable"],
				desc = L["Toggle whether to enable this action bar or not."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			visibilityHeader = {
				name = L["Visibility"],
				order = 2,
				type = "header",
				hidden = isdisabled
			},
			visibilityDesc = {
				name = L["Choose when your bars will be visible."],
				order = 3,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			enableBarFading = {
				name = L["Enable Bar Fading"],
				desc = L["Toggle whether to enable the buttons of this action bar to fade out."],
				order = 9,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			fadeAlone = {
				name = L["Don't fade in other bars"],
				desc = L["Only show buttons from this specific bar when hovering it."],
				order = 10,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			fadeInCombat = {
				name = L["Only show on mouseover"],
				desc = L["Enable this to only show faded bars on mouseover, and not force them visible in combat."],
				order = 11,
				type = "toggle", width = "full",
				hidden = function(info) return isdisabled(info) or not getsetting(info, "enableBarFading") end,
				set = setter,
				get = getter
			},
			fadeFrom = {
				name = L["Start Fading from"],
				desc = L["Choose which button to start the fading from."],
				order = 12,
				type = "range", width = "full", min = 1, max = 12, step = 1,
				hidden = function(info) return isdisabled(info) or not getsetting(info, "enableBarFading") end,
				set = setter,
				get = getter
			},
			layoutHeader = {
				name = L["Layout"],
				order = 18,
				type = "header",
				hidden = isdisabled
			},
			layoutDesc = {
				name = L["Choose how your bar is displayed."],
				order = 19,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			layout = {
				name = L["Bar Layout"],
				desc = L["Choose the action bar layout type."],
				order = 20,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["grid"] = L["Grid Layout"],
					["zigzag"] = L["ZigZag Layout"],
				},
				set = setter,
				get = getter
			},
			startAt = {
				name = L["First ZigZag Button"],
				desc = L["Sets which button the zigzag pattern should begin at."],
				order = 21,
				type = "range", width = "full", min = 1, max = 12, step = 1,
				hidden = function(info) return isdisabled(info) or getsetting(info, "layout") ~= "zigzag" end,
				set = setter,
				get = getter
			},
			numbuttons = {
				name = L["Number of buttons"],
				desc = L["Sets the number of action buttons on the action bar."],
				order = 30,
				type = "range", width = "full", min = 0, max = 12, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			padding = {
				name = L["Button Padding"],
				desc = L["Sets the padding between buttons on the same line."],
				order = 31,
				type = "range", width = "full", min = 0, max = 16, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			breakpadding = {
				name = L["Line Padding"],
				desc = L["Sets the padding between multiple lines of buttons."],
				order = 32,
				type = "range", width = "full", min = 0, max = 16, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			breakpoint = {
				name = L["Line Break"],
				desc = L["Sets when a new line of buttons should begin."],
				order = 40,
				type = "range", width = "full", min = 1, max = 12, step = 1,
				hidden = function(info) return isdisabled(info) or getsetting(info, "layout") ~= "grid" end,
				set = setter,
				get = getter
			},
			growth = {
				name = L["Initial Growth"],
				desc = L["Choose whether the bar initially should expand horizontally or vertically."],
				order = 50,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["horizontal"] = L["Horizontal Layout"],
					["vertical"] = L["Vertical Layout"],
				},
				set = setter,
				get = getter
			},
			growthSpace = {
				name = "", order = 51, type = "description",
				hidden = isdisabled
			},
			growthHorizontal = {
				name = L["Horizontal Growth"],
				desc = L["Choose which horizontal direction the bar should expand in."],
				order = 52,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["RIGHT"] = L["Right"],
					["LEFT"] = L["Left"],
				},
				set = setter,
				get = getter
			},
			growthVertical = {
				name = L["Vertical Growth"],
				desc = L["Choose which vertical direction the bar should expand in."],
				order = 53,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["DOWN"] = L["Down"],
					["UP"] = L["Up"],
				},
				set = setter,
				get = getter
			}--[[,
			positionHeader = {
				name = L["Position"],
				order = 58,
				type = "header",
				hidden = isdisabled
			},
			positionDesc = {
				name = L["Fine-tune the position."],
				order = 59,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			point = {
				name = L["Anchor Point"],
				desc = L["Sets the anchor point."],
				order = 61,
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
				set = function(info,val) setoption(info,1,val) end,
				get = function(info) return getoption(info,1) end
			},
			pointPostSpace = {
				name = "", order = 62, type = "description", hidden = isdisabled
			},
			offsetX = {
				name = L["X Offset"],
				desc = L["Sets the horizontal offset from your chosen anchor point. Positive values means right, negative values means left."],
				order = 63,
				type = "input",
				hidden = isdisabled,
				validate = function(info,val)
					local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
					if (val) then return true end
					return L["Only numbers are allowed."]
				end,
				set = function(info,val)
					local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
					if (not val) then return end
					setoption(info,2,val)
				end,
				get = function(info)
					local val = getoption(info,2)
					val = math_floor(val * 1000 + .5)/1000
					return tostring(val)
				end
			},
			offsetY = {
				name = L["Y Offset"],
				desc = L["Sets the vertical offset from your chosen anchor point. Positive values means up, negative values means down."],
				order = 64,
				type = "input",
				hidden = isdisabled,
				validate = function(info,val)
					local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
					if (val) then return true end
					return L["Only numbers are allowed."]
				end,
				set = function(info,val)
					local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
					if (not val) then return end
					setoption(info,3,val)
				end,
				get = function(info)
					local val = getoption(info,3)
					val = math_floor(val * 1000 + .5)/1000
					return tostring(val)
				end
			}]]
		}
	}
	return options
end

local GenerateBarOptions = function(moduleName, displayName, order, maxButtons)
	local getmodule = function()
		local module = ns:GetModule(moduleName, true)
		if (module and module:IsEnabled()) then
			return module
		end
	end
	if (not getmodule(moduleName)) then return end

	local setter = function(info,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		db[info[#info]] = val
		getmodule():UpdateSettings()
	end

	local getter = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[info[#info]]
	end

	local isdisabled = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return info[#info] ~= "enabled" and not db.enabled
	end

	local getsetting = function(info, setting)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[setting]
	end

	local setoption = function(info,option,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		db[option] = val
		getmodule():UpdateSettings()
	end

	local getoption = function(info,option)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[option]
	end

	local options = {
		name = displayName,
		order = order,
		type = "group",
		args = {
			enabled = {
				name = L["Enable"],
				desc = L["Toggle whether to enable this action bar or not."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			visibilityHeader = {
				name = L["Visibility"],
				order = 2,
				type = "header",
				hidden = isdisabled
			},
			visibilityDesc = {
				name = L["Choose when your bars will be visible."],
				order = 3,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			enableBarFading = {
				name = L["Enable Bar Fading"],
				desc = L["Toggle whether to enable the buttons of this action bar to fade out."],
				order = 9,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			fadeAlone = {
				name = L["Don't fade in other bars"],
				desc = L["Only show buttons from this specific bar when hovering it."],
				order = 10,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			fadeInCombat = {
				name = L["Only show on mouseover"],
				desc = L["Enable this to only show faded bars on mouseover, and not force them visible in combat."],
				order = 10,
				type = "toggle", width = "full",
				hidden = function(info) return isdisabled(info) or not getsetting(info, "enableBarFading") end,
				set = setter,
				get = getter
			},
			fadeFrom = {
				name = L["Start Fading from"],
				desc = L["Choose which button to start the fading from."],
				order = 11,
				type = "range", width = "full", min = 1, max = maxButtons or 12, step = 1,
				hidden = function(info) return isdisabled(info) or not getsetting(info, "enableBarFading") end,
				set = setter,
				get = getter
			},
			layoutHeader = {
				name = L["Layout"],
				order = 18,
				type = "header",
				hidden = isdisabled
			},
			layoutDesc = {
				name = L["Choose how your bar is displayed."],
				order = 19,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			layout = {
				name = L["Bar Layout"],
				desc = L["Choose the action bar layout type."],
				order = 20,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["grid"] = L["Grid Layout"],
					["zigzag"] = L["ZigZag Layout"],
				},
				set = setter,
				get = getter
			},
			startAt = {
				name = L["First ZigZag Button"],
				desc = L["Sets which button the zigzag pattern should begin at."],
				order = 21,
				type = "range", width = "full", min = 1, max = maxButtons or 12, step = 1,
				hidden = function(info) return isdisabled(info) or getsetting(info, "layout") ~= "zigzag" end,
				set = setter,
				get = getter
			},
			numbuttons = {
				name = L["Number of buttons"],
				desc = L["Sets the number of action buttons on the action bar."],
				order = 30,
				type = "range", width = "full", min = 0, max = maxButtons or 12, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			padding = {
				name = L["Button Padding"],
				desc = L["Sets the padding between buttons on the same line."],
				order = 31,
				type = "range", width = "full", min = 0, max = 16, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			breakpadding = {
				name = L["Line Padding"],
				desc = L["Sets the padding between multiple lines of buttons."],
				order = 32,
				type = "range", width = "full", min = 0, max = 16, step = 1,
				hidden = isdisabled,
				set = setter,
				get = getter
			},
			breakpoint = {
				name = L["Line Break"],
				desc = L["Sets when a new line of buttons should begin."],
				order = 40,
				type = "range", width = "full", min = 1, max = maxButtons or 12, step = 1,
				hidden = function(info) return isdisabled(info) or getsetting(info, "layout") ~= "grid" end,
				set = setter,
				get = getter
			},
			growth = {
				name = L["Initial Growth"],
				desc = L["Choose whether the bar initially should expand horizontally or vertically."],
				order = 50,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["horizontal"] = L["Horizontal Layout"],
					["vertical"] = L["Vertical Layout"],
				},
				set = setter,
				get = getter
			},
			growthSpace = {
				name = "", order = 51, type = "description",
				hidden = isdisabled
			},
			growthHorizontal = {
				name = L["Horizontal Growth"],
				desc = L["Choose which horizontal direction the bar should expand in."],
				order = 52,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["RIGHT"] = L["Right"],
					["LEFT"] = L["Left"],
				},
				set = setter,
				get = getter
			},
			growthVertical = {
				name = L["Vertical Growth"],
				desc = L["Choose which vertical direction the bar should expand in."],
				order = 53,
				type = "select", style = "dropdown",
				hidden = isdisabled,
				values = {
					["DOWN"] = L["Down"],
					["UP"] = L["Up"],
				},
				set = setter,
				get = getter
			}
		}
	}
	return options
end

local GenerateOptions = function()
	if (not getmodule()) then return end

	local setter = function(info,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		db[info[#info]] = val
		getmodule():UpdateSettings()
	end

	local getter = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[info[#info]]
	end

	local isdisabled = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return info[#info] ~= "enabled" and not db.enabled
	end

	local getsetting = function(info, setting)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[setting]
	end

	local setoption = function(info,option,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		db[option] = val
		getmodule():UpdateSettings()
	end

	local getoption = function(info,option)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = getmodule().db.profile
		return db[option]
	end

	local options = {
		name = L["Action Bar Settings"],
		type = "group", childGroups = "tree",
		args = {
			description = {
				name = L["ActionBars are banks of hotkeys that allow you to quickly access abilities and inventory items. Here you can activate additional ActionBars and control their behaviors."],
				type = "description",
				fontSize = "medium",
				order = 0
			},
			clickOnDown = {
				name = L["Cast action keybinds on key down"],
				desc = L["Cast action keybinds on key down"],
				order = 1,
				type = "toggle", width = "full",
				set = function(info, val)
					setter(info,val)
					local pet = ns:GetModule("PetBar", true)
					if (pet) then
						pet:UpdateSettings()
					end
					local stance = ns:GetModule("StanceBar", true)
					if (stance) then
						pet:UpdateSettings()
					end
				end,
				get = getter
			},
			dimWhenInactive = {
				name = L["Dim the actionbuttons when inactive"],
				desc = L["Dim down and desaturate your action buttons when not engaged in combat and not currently targeting anything."],
				order = 2,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			dimWhenResting = {
				name = L["Only dim the actionbuttons when resting"],
				desc = L["This restricts the dimming to when the player is resting."],
				order = 3,
				type = "toggle", width = "full",
				hidden = function(info) return not getsetting(info, "dimWhenInactive") end,
				set = setter,
				get = getter
			}
		}
	}

	for id = 1,ns.IsRetail and 8 or 5 do
		options.args["bar"..id] = GenerateIndexedBarOptions("ActionBars", string_format(L["Action Bar %d"], id), 100 + id*10)
	end

	options.args["petbar"] = GenerateBarOptions("PetBar", L["Pet Bar"], 200, NUM_PET_ACTION_SLOTS)

	local stanceBarOptions = GenerateBarOptions("StanceBar", L["Stance Bar"], 210, GetNumShapeshiftForms())

	for _,opt in next,{ "fadeFrom", "startAt", "numbuttons", "breakpoint" } do
		local getter = stanceBarOptions.args[opt].get
		stanceBarOptions.args[opt].get = function(info)
			return math_min(getter(info), stanceBarOptions.args[opt].max)
		end
	end

	for i,v in next,stanceBarOptions.args do
		if (i ~= "enabled") then
			local ishidden = v.hidden
			v.hidden = function(info)
				return (GetNumShapeshiftForms() == 0) or ishidden(info)
			end
		end
	end

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	updater:RegisterEvent("PLAYER_ENTERING_WORLD")
	updater:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	updater:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	updater:SetScript("OnEvent", function()
		local numStances = GetNumShapeshiftForms()
		stanceBarOptions.args.fadeFrom.max = numStances
		stanceBarOptions.args.startAt.max = numStances
		stanceBarOptions.args.numbuttons.max = numStances
		stanceBarOptions.args.breakpoint.max = numStances
	end)

	options.args["stancebar"] = stanceBarOptions

	return options
end

Options:AddGroup(L["Action Bars"], GenerateOptions)
