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
	local getmodule = function(name) return ns:GetModule(name or "UnitFrames", true) end
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
		suboptions.args.showName = {
			name = L["Show Unit Name"],
			desc = L["Toggle whether to show the name of the unit."],
			order = 30, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
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
			name = L["Visibility"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.showPlayer = {
			name = L["Show player"],
			desc = L["Toggle whether to show the player while in a party."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.showParty = {
			name = L["Show in parties."],
			desc = L["Toggle whether to show the party frames while in parties.\n\nIt is not possible to show both the Raid Frames and the Party Frames at the same time. Setting this option will disable the raid frames from being shown in parties."],
			order = 30, type = "toggle", width = "full", get = getter, hidden = isdisabled,
			set = function(info,val)
				setter(info, val, true)
				local raid = ns:GetModule("RaidFrames", true)
				if (raid) then
					raid.db.profile.showParty = false
					raid.db.profile.useRaidStylePartyFrames = false
					raid:UpdateSettings()
				end
				module:UpdateSettings()
			end
		}
		suboptions.args.showRaid = {
			name = L["Show in party sized raid groups (1-5 Players)."],
			desc = L["Toggle whether to show the party frames while in a raid group.\n\nIt is not possible to show both the Raid Frames and the Party Frames at the same time. Setting this option will disable the raid frames from being shown in party sized raid groups."],
			order = 40, type = "toggle", width = "full", get = getter, hidden = isdisabled,
			set = function(info,val)
				setter(info, val, true)
				local raid = ns:GetModule("RaidFrames", true)
				if (raid) then
					raid.db.profile.showInPartySizedRaidGroups = false
					raid:UpdateSettings()
				end
				module:UpdateSettings()
			end
		}
		options.args.party = suboptions
	end

	-- Raid Frames
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrames")
		suboptions.name = L["Raid Frames"]
		suboptions.order = 160
		suboptions.args.elementHeader = {
			name = L["Visibility"], order = 10, type = "header", hidden = isdisabled
		}
		suboptions.args.showRaid = {
			name = L["Show in raids."],
			desc = L["Toggle whether to show the raid frames while in a raid groups of five members or more."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.useRaidStylePartyFrames = {
			name = L["Show in parties."],
			desc = L["Toggle whether to show the raid frames while in parties.\n\nIt is not possible to show both the Raid Frames and the Party Frames at the same time. Setting this option will disable the party frames when in parties."],
			order = 30, type = "toggle", width = "full", get = getter, hidden = isdisabled,
			set = function(info,val)
				setter(info, val, true)
				setoption(info, "showParty", val, true)
				if (val) then
					local party = ns:GetModule("PartyFrames", true)
					if (party) then
						--party.db.profile.showRaid = false
						party.db.profile.showParty = false
						party:UpdateSettings()
					end
				end
				module:UpdateSettings()
			end
		}
		suboptions.args.showInPartySizedRaidGroups = {
			name = L["Show in party sized raid groups (1-5 Players)."],
			desc = L["Toggle whether to show the raid frames while in party sized raid groups.\n\nIt is not possible to show both the Raid Frames and the Party Frames at the same time. Setting this option will disable the party frames from being shown in party sized raid groups."],
			order = 40, type = "toggle", width = "full", get = getter, hidden = isdisabled,
			set = function(info,val)
				setter(info, val, true)
				setoption(info, "showParty", val, true)
				if (val) then
					local party = ns:GetModule("PartyFrames", true)
					if (party) then
						party.db.profile.showRaid = false
						--party.db.profile.showParty = false
						party:UpdateSettings()
					end
				end
				module:UpdateSettings()
			end
		}

		options.args.raid = suboptions
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
		--local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("ArenaFrames")
		--suboptions.name = L["Arena Frames"]
		--suboptions.order = 180
		--options.args.arena = suboptions
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
