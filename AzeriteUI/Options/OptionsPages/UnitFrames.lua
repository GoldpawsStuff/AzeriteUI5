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

local GenerateSubOptions = function(moduleName)
	local module = ns:GetModule(moduleName, true)
	if (not module) then return end

	local setter = function(info,val,noRefresh)
		module.db.profile[info[#info]] = val
		if (not noRefresh) then
			module:UpdateSettings()
		end
	end
	local getter = function(info) return module.db.profile[info[#info]] end
	local setoption = function(info,option,val,noRefresh)
		module.db.profile[option] = val
		if (not noRefresh) then
			module:UpdateSettings()
		end
	end
	local getoption = function(info,option) return module.db.profile[option] end
	local isdisabled = function(info) return info[#info] ~= "enabled" and not module.db.profile.enabled end

	local options = {
		type = "group",
		args = {
			enabled = {
				name = L["Enable"],
				desc = L["Toggle whether to enable this element or not."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			}
		}
	}

	return options, module, setter, getter, setoption, getoption, isdisabled
end

local GenerateOptions = function()
	local getmodule = function(name)
		local module = ns:GetModule(name or "UnitFrames", true)
		if (module and module:IsEnabled()) then
			return module
		end
	end

	if (not getmodule()) then return end

	local setter = function(info,val) getmodule().db.profile[info[#info]] = val; getmodule():UpdateSettings() end
	local getter = function(info) return getmodule().db.profile[info[#info]] end
	local setoption = function(info,option,val) getmodule().db.profile[option] = val; getmodule():UpdateSettings() end
	local getoption = function(info,option) return getmodule().db.profile[option] end
	local isdisabled = function(info) return info[#info] ~= "enabled" and not getmodule().db.profile.enabled end

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

	-- Player
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PlayerFrame")
		suboptions.name = L["Player"]
		suboptions.order = 100
		suboptions.args.elementHeader = {
			name = L["Elements"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.showAuras = {
			name = L["Show Auras"],
			desc = L["Toggle whether to show auras on this unit frame."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.showCastbar = {
			name = L["Show Castbar"],
			desc = L["Toggle whether to show overlay castbars on this unit frame."],
			order = 30, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.player = suboptions
	end

	-- Pet
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PetFrame")
		suboptions.name = L["Pet"]
		suboptions.order = 110
		options.args.pet = suboptions
	end

	-- Target
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("TargetFrame")
		suboptions.name = L["Target"]
		suboptions.order = 120
		suboptions.args.elementHeader = {
			name = L["Elements"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.showAuras = {
			name = L["Show Auras"],
			desc = L["Toggle whether to show auras on this unit frame."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.showCastbar = {
			name = L["Show Castbar"],
			desc = L["Toggle whether to show overlay castbars on this unit frame."],
			order = 25, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.showName = {
			name = L["Show Unit Name"],
			desc = L["Toggle whether to show the name of the unit."],
			order = 30, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.textureHeader = {
			name = L["Texture Variations"], order = 40, type = "header", hidden = isdisabled
		}
		suboptions.args.useStandardBossTexture = {
			name = L["Use Large Boss Texture"],
			desc = L["Toggle whether to show a larger texture for bosses."],
			order = 50, type = "toggle", width = "full", hidden = isdisabled,
			set = function(info,val) setter(info, not val) end,
			get = function(info) return not getter(info) end
		}
		suboptions.args.useStandardCritterTexture = {
			name = L["Use Small Critter Texture"],
			desc = L["Toggle whether to show a smaller texture for critters."],
			order = 60, type = "toggle", width = "full", hidden = isdisabled,
			set = function(info,val) setter(info, not val) end,
			get = function(info) return not getter(info) end
		}
		options.args.target = suboptions
	end

	-- Target of Target
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("ToTFrame")
		suboptions.name = L["Target of Target"]
		suboptions.order = 130
		suboptions.args.elementHeader = {
			name = L["Visibility"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.hideWhenTargetingPlayer = {
			name = L["Hide when targeting player."],
			desc = L["Makes the ToT frame transparent when its target is you."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.hideWhenTargetingSelf = {
			name = L["Hide when targeting self."],
			desc = L["Makes the ToT frame transparent when its target is itself."],
			order = 30, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.tot = suboptions
	end

	-- Focus Target
	if (not ns.IsClassic) then
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("FocusFrame")
		suboptions.name = L["Focus"]
		suboptions.order = 140
		options.args.focus = suboptions
	end

	-- Party Frames
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PartyFrames")
		suboptions.name = L["Party Frames"]
		suboptions.order = 150
		suboptions.args.elementHeader = {
			name = L["Elements"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.showAuras = {
			name = L["Show Auras"],
			desc = L["Toggle whether to show auras on this unit frame."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.elementHeader = {
			name = L["Visibility"], order = 19, type = "header", hidden = isdisabled
		}
		suboptions.args.showPlayer = {
			name = L["Show player"],
			desc = L["Toggle whether to show the player while in a party."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.party = suboptions
	end


	-- Raid Frames (5)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame5")
		suboptions.name = L["Raid Frames"] .. " (5)"
		suboptions.order = 160
		options.args.raid5 = suboptions
	end

	-- Raid Frames (25)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame25")
		suboptions.name = L["Raid Frames"] .. " (25)"
		suboptions.order = 161
		options.args.raid25 = suboptions
	end

	-- Raid Frames (40)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame40")
		suboptions.name = L["Raid Frames"] .. " (40)"
		suboptions.order = 162
		options.args.raid40 = suboptions
	end

	-- Boss Frames
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("BossFrames")
		suboptions.name = L["Boss Frames"]
		suboptions.order = 170
		options.args.boss = suboptions
	end

	-- Arena Enemy Frames
	if (not ns.IsClassic) then
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("ArenaFrames")
		suboptions.name = L["Arena Enemy Frames"]
		suboptions.order = 180
		options.args.arena = suboptions
	end

	-- Player CastBar
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PlayerCastBarFrame")
		suboptions.name = L["Cast Bar"]
		suboptions.order = 200
		options.args.castbar = suboptions
	end

	-- Player ClassPower
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PlayerClassPowerFrame")
		suboptions.name = function(info) return ns:GetModule("PlayerClassPowerFrame"):GetLabel() end
		suboptions.order = 210
		options.args.classpower = suboptions
	end

	return options
end

Options:AddGroup(L["Unit Frames"], GenerateOptions)
