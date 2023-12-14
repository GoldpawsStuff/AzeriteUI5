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

-- Player Constants
local _,playerClass = UnitClass("player")

local getmodule = function()
	local module = ns:GetModule("ExplorerMode", true)
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

local setterReverse = function(info,val)
	getmodule().db.profile[info[#info]] = not val
	getmodule():UpdateSettings()
end

local getterReverse = function(info)
	return not getmodule().db.profile[info[#info]]
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
		name = L["Explorer Mode"],
		type = "group",
		args = {
			explorerermodedesc = {
				name = L["The Explorer Mode is a collection of settings that affect primarily the actionbars and player unit frame,allowing them to fade out in various situations to get a more immersive experience."].."\n ",
				type = "description",
				fontSize = "medium",
				order = 1
			},
			enabled = {
				name = L["Enable Explorer Mode"],
				desc = L["Enables the immersive Explorer Mode"],
				type = "toggle", width = "full",
				set = setter, get = getter,
				order = 2
			},
			explorermodedelayspacer = {
				name = "\n ", type = "description", fontSize = "medium", hidden = isdisabled,
				order = 9
			},
			explorermodedelayheader = {
				name = "When to start Explorer Mode",
				desc = "",
				type = "header",
				disabled = isdisabled, hidden = isdisabled,
				order = 10
			},
			explorerermodedelaydesc = {
				name = "You can choose to have a delay before the Explorer Mode starts after loading screens.".."\n ",
				type = "description",
				fontSize = "medium",
				disabled = isdisabled, hidden = isdisabled,
				order = 11
			},
			delayOnLogin = {
				name = "After logging into the game",
				desc = "",
				order = 15,
				type = "range", width = "full", min = 0, max = 15, step = 1,
				set = setter, get = getter, hidden = isdisabled,
			},
			delayOnReload = {
				name = "After reloading the user interface",
				desc = "",
				order = 16,
				type = "range", width = "full", min = 0, max = 15, step = 1,
				set = setter, get = getter, hidden = isdisabled,
			},
			delayOnZoning = {
				name = "After all other loading screens",
				desc = "",
				order = 17,
				type = "range", width = "full", min = 0, max = 15, step = 1,
				set = setter, get = getter, hidden = isdisabled,
			},
			explorermodesituationsspacer = {
				name = "\n ", type = "description", fontSize = "medium", hidden = isdisabled,
				order = 19
			},
			explorermodesituationsheader = {
				name = L["When to exit Explorer Mode"],
				desc = "",
				type = "header",
				disabled = isdisabled, hidden = isdisabled,
				order = 20
			},
			explorermodesituationsdesc = {
				name = L["Here you can select which situations should be considered unsafe and exit the Explorer Mode."].."\n ",
				type = "description",
				fontSize = "medium",
				disabled = isdisabled, hidden = isdisabled,
				order = 21
			},
			fadeInCombat = {
				name = L["While engaged in combat"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 22
			},
			fadeWithLowHealth = {
				name = L["While having low health"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 23
			},
			fadeThresholdHealth = {
				name = L["Set the Low Health threshold"],
				desc = L["Sets the threshold in a percentage of maximum health for when the Explorer Mode will exit."],
				order = 24,
				type = "range", width = "full", min = 30, max = 90, step = 5,
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowHealth") end,
				set = function(info,value) setter(info,value/100) end,
				get = function(info) return getter(info)*100 end
			},
			fadeThresholdHealthspacer = {
				name = "\n ", type = "description", fontSize = "medium",
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowHealth") end,
				order = 25
			},
			fadeWithLowMana = {
				name = L["While having low mana"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 26
			},
			fadeThresholdMana = {
				name = L["Set the Low Mana threshold"],
				desc = L["Sets the threshold in a percentage of maximum mana for when the Explorer Mode will exit."],
				order = 27,
				type = "range", width = "full", min = 30, max = 90, step = 5,
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				set = function(info,value) setter(info,value/100) end,
				get = function(info) return getter(info)*100 end
			},
			fadeThresholdManaspacer = {
				name = "\n ", type = "description", fontSize = "medium",
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				order = 28
			},
			fadeThresholdManaInForms = {
				name = L["Set the Low Mana while in a Druid from threshold"],
				desc = L["Sets the threshold in a percentage of maximum mana for when the Explorer Mode will exit when in a Druid shapeshift form not currently having mana as the primary resource."],
				order = 29,
				type = "range", width = "full", min = 30, max = 90, step = 5,
				disabled = function(info) return (playerClass ~= "DRUID") end,
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				set = function(info,value) setter(info,value/100) end,
				get = function(info) return getter(info)*100 end
			},
			fadeThresholdManaInFormsspacer = {
				name = "\n ", type = "description", fontSize = "medium",
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				order = 30
			},
			fadeThresholdEnergy = {
				name = L["Set the Low Energy/Focus threshold"],
				desc = L["Sets the threshold in a percentage of maximum energy or focus for when the Explorer Mode will exit."],
				order = 31,
				type = "range", width = "full", min = 30, max = 90, step = 5,
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				set = function(info,value) setter(info,value/100) end,
				get = function(info) return getter(info)*100 end
			},
			fadeThresholdEnergyspacer = {
				name = "\n ", type = "description", fontSize = "medium",
				hidden = function(info) return isdisabled(info) or getoption(info, "fadeWithLowMana") end,
				order = 30
			},
			fadeInGroups = {
				name = L["While in a group"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 33
			},
			fadeInInstances = {
				name = L["While in an instance"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 35
			},
			fadeWithFriendlyTarget = {
				name = L["While having a friendly target"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 40
			},
			fadeWithHostileTarget = {
				name = L["While having a hostile target"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 45
			},
			fadeWithDeadTarget = {
				name = L["While having a dead target"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = function(info) return isdisabled(info) or (getoption(info, "fadeWithFriendlyTarget") and getoption(info, "fadeWithHostileTarget")) end,
				hidden = isdisabled,
				order = 46
			},
			fadeWithFocusTarget = (ns.IsRetail or ns.IsWrath) and {
				name = L["While having a focus target"],
				desc = "",
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 50
			} or nil,
			fadeInVehicles = (ns.IsRetail or ns.IsWrath) and {
				name = L["While having any sort of replacement actionbar"],
				desc = L["Exits Explorer Mode when in vehicles, when possessing a unit or any other situation that would replace your character's action bar with a temporary one."],
				type = "toggle", width = "full",
				set = setterReverse, get = getterReverse, disabled = isdisabled, hidden = isdisabled,
				order = 55
			} or nil,
			elementsspacer = {
				name = "\n ", type = "description", fontSize = "medium", hidden = isdisabled,
				order = 99
			},
			explorermodeframeheader = {
				name = L["Elements to Fade"],
				desc = "",
				type = "header",
				hidden = isdisabled,
				order = 100
			},
			fadeActionBars = {
				name = L["Fade ActionBars"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 130
			},
			fadePetBar = {
				name = L["Fade PetBar"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 131
			},
			fadeStanceBar = {
				name = L["Fade StanceBar"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 132
			},
			fadePlayerFrame = {
				name = L["Fade Player unit frame"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 140
			},
			fadePetFrame = {
				name = L["Fade Pet unit frame"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 141
			},
			fadeFocusFrame = (ns.IsRetail or ns.IsWrath) and {
				name = L["Fade Focus unit frame"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 142
			} or nil,
			fadeTracker = {
				name = L["Fade Objectives Tracker"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 150
			},
			fadeChatFrames = {
				name = L["Fade Chat Windows"],
				desc = "",
				type = "toggle", width = "full",
				set = setter, get = getter, disabled = isdisabled, hidden = isdisabled,
				order = 160
			}
		}
	}

	return options
end

Options:AddGroup(L["Explorer Mode"], GenerateOptions, -10000)
