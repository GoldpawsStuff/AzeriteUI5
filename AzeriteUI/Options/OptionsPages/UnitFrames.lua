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

local L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)

local Options = ns:GetModule("Options")
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local math_floor = math.floor
local string_match = string.match
local tonumber = tonumber
local tostring = tostring

local getmodule = function(name)
	return ns:GetModule(name or "UnitFrames", true)
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

local GenerateUnitOptions = function(moduleName)
	local module = ns:GetModule(moduleName, true)
	if (not module or not module.db.profile.enabled) then return end

	local setter = function(info,val)
		module.db.profile.savedPosition[MFM:GetLayout()][info[#info]] = val
		module:UpdateSettings()
	end

	local getter = function(info)
		return module.db.profile.savedPosition[MFM:GetLayout()][info[#info]]
	end

	local isdisabled = function(info)
		return info[#info] ~= "enabled" and not module.db.profile.savedPosition[MFM:GetLayout()].enabled
	end

	local setoption = function(info,option,val)
		module.db.profile.savedPosition[MFM:GetLayout()][option] = val
		module:UpdateSettings()
	end

	local getoption = function(info,option)
		return module.db.profile.savedPosition[MFM:GetLayout()][option]
	end

	local options = {
		type = "group",
		args = {
			enabled = {
				name = L["Enable"],
				desc = L["Toggle whether to enable this unit frame or not."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			positionHeader = {
				name = L["Position"],
				order = 60,
				type = "header",
				hidden = isdisabled
			},
			positionDesc = {
				name = L["Fine-tune the position."],
				order = 61,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
			point = {
				name = L["Anchor Point"],
				desc = L["Sets the anchor point."],
				order = 62,
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
				name = "", order = 63, type = "description", hidden = isdisabled
			},
			offsetX = {
				name = L["Offset X"],
				desc = L["Sets the horizontal offset from your chosen anchor point. Positive values means right, negative values means left."],
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
					setoption(info,2,val)
				end,
				get = function(info)
					local val = getoption(info,2)
					val = math_floor(val * 1000 + .5)/1000
					return tostring(val)
				end
			},
			offsetY = {
				name = L["Offset Y"],
				desc = L["Sets the vertical offset from your chosen anchor point. Positive values means up, negative values means down."],
				order = 65,
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
			}
		}
	}

	return options
end

local GenerateOptions = function()
	if (not getmodule()) then return end

	local options = {
		name = L["UnitFrame Settings"],
		type = "group",
		childGroups = "tree",
		args = {
			--auraHeader = {
			--	name = L["Aura Settings"],
			--	order = 2,
			--	type = "header",
			--	hidden = isdisabled
			--},
			--auraDesc = {
			--	name = L["Here you can change settings related to the aura buttons appearing at each unitframe."],
			--	order = 3,
			--	type = "description",
			--	fontSize = "medium",
			--	hidden = isdisabled
			--},
			disableAuraSorting = {
				name = L["Enable Aura Sorting"],
				desc = L["When enabled, unitframe auras will be sorted depending on time left and who cast the aura. When disabled, unitframe auras will appear in the order they were applied, like in the default user interface."],
				order = 10,
				type = "toggle", width = "full",
				hidden = isdisabled,
				set = function(info,val) setter(info, not val) end,
				get = function(info) return not getter(info) end
			}
		}
	}

	local order = 100
	for id,data in next,{
		player = { PLAYER, "PlayerFrame", 0 }, -- Player
		playerCastBar = { L["Cast Bar"], "PlayerCastBarFrame", 1 }, -- Player Cast Bar
		playerClassPower = { function(info) -- generates an appropriate display name
			if (ns.PlayerClass == "MAGE") then
				if (GetSpecialization() == (SPEC_MAGE_ARCANE or 3)) then
					return L["Arcane Charges"]
				end
			elseif (ns.PlayerClass == "MONK") then
				local spec = GetSpecialization()
				if (spec == (SPEC_MONK_WINDWALKER or 3)) then
					return L["Chi"]
				elseif (spec == (SPEC_MONK_BREWMASTER or 1)) then
					return L["Stagger"]
				end
			elseif (ns.PlayerClass == "PALADIN") then
				return L["Holy Power"]
			elseif (ns.PlayerClass == "WARLOCK") then
				if (GetSpecialization() == (SPEC_WARLOCK_DESTRUCTION or 3)) then
					return L["Soul Shards"]
				end
			elseif (ns.PlayerClass == "EVOKER") then
				return L["Essence"]
			elseif (ns.PlayerClass == "DEATHKNIGHT") then
				return L["Runes"]
			end
			return L["Combo Points"]
		end, "PlayerClassPowerFrame", 2 }, -- Player Class Power
		pet = { PET, "PetFrame", 10 }, -- Pet
		target = { TARGET, "TargetFrame", 20 }, -- Target
		tot = { SHOW_TARGET_OF_TARGET_TEXT, "ToTFrame", 30 }, -- ToT
		focus = { FOCUS, "FocusFrame", 40 }, -- Focus
		party = { L["Party Frames"], "PartyFrames", 50 }, -- Party
		raid = { L["Raid Frames"], "RaidFrames", 60 }, -- Raid
		boss = { L["Boss Frames"], "BossFrames", 70 }, -- Boss
		--arena = { L["Arena Frames"], "ArenaFrames", 80 }, -- Arena
	} do
		if (data) then
			local unitOptions = GenerateUnitOptions(data[2])
			if (unitOptions) then
				unitOptions.name = data[1]
				unitOptions.order = order + data[3]
				options.args[id] = unitOptions
			end
		end
	end

	return options
end

Options:AddGroup(L["Unit Frames"], GenerateOptions)
