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
		suboptions.hidden = function(info)
			if (not ns.IsDevelopment) or (not ns.db.global.enableDevelopmentMode) then return end

			-- Not hidden if self is enabled.
			local playerFrame = ns:GetModule("PlayerFrame", true)
			if playerFrame.db.profile.enabled then
				return
			end

			-- Hidden if self is disabled and alternate frame is enabled.
			local playerFrameAlt = ns:GetModule("PlayerFrameAlternate", true)
			if playerFrameAlt then
				if (playerFrameAlt:IsEnabled() and playerFrameAlt.db.profile.enabled) then
					return  true
				end
			end

		end

		suboptions.args.enabled.set = function(info, val)
			if (val) then
				local playerFrameAlt = ns:GetModule("PlayerFrameAlternate", true)
				if (playerFrameAlt) then
					playerFrameAlt.db.profile.enabled = false
					playerFrameAlt:Disable()
				end
			end
			setter(info, val)
		end

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
		suboptions.args.alwaysUseCrystal = {
			name = L["Always use Power Crystal"],
			desc = L["Choose whether to always show a power crystal or dynamically switch to the orb for mana users."],
			order = 40, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.useWrathCrystal = {
			name = L["Use Ice Crystal"],
			desc = L["Toggle whether to show the ice power crystal or the regular power crystal colored by resource type."],
			order = 45, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.player = suboptions
	end

	-- Player Alternate Version (mirrored Target)
	do
		-- This isn't always here, check for it to avoid breaking the whole addon!
		local PlayerFrameAlternate = ns:GetModule("PlayerFrameAlternate", true)
		if (PlayerFrameAlternate) then
			
			local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("PlayerFrameAlternate")
			suboptions.hidden = function(info)

				-- Hidden if this isn't a development version with devmode enabled.
				if (not ns.IsDevelopment) or (not ns.db.global.enableDevelopmentMode) then return true end

				-- Hidden if the main playerframe is enabled.
				local module = ns:GetModule("PlayerFrame", true)
				if (not module) then return end

				return module.db.profile.enabled
			end

			suboptions.args.enabled.set = function(info, val)
				if (val) then
					local playerFrame = ns:GetModule("PlayerFrame", true)
					if (playerFrame) then
						playerFrame.db.profile.enabled = false
						playerFrame:Disable()
					end
				end
				setter(info, val)
			end

			suboptions.name = "Player Alternate"
			suboptions.order = 105
			suboptions.args.elementHeader = {
				name = L["Elements"], order = 10, type = "header", hidden = isdisabled
			}
			suboptions.args.showAuras = {
				name = L["Show Auras"],
				desc = L["Toggle whether to show auras on this unit frame."],
				order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
			}
			suboptions.args.aurasBelowFrame = {
				name = "Auras below frame",
				desc = "Toggle whether to show auras below or above the unit frame.",
				order = 21, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled,
				disabled = function(info) return not getoption(info, "showAuras") end
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

			options.args.playerAlternate = suboptions
		end
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
		suboptions.args.showInRaids = {
			name = L["Show in raids."],
			desc = L["Show in party sized raid groups (1-5 Players)."],
			order = 21, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.party = suboptions
	end

	-- Raid Frames (5)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame5")
		suboptions.name = L["Raid Frames"] .. " (5)"
		suboptions.order = 160
		suboptions.hidden = function(info)
			return getmodule("PartyFrames").db.profile.enabled and getmodule("PartyFrames").db.profile["showInRaids"]
		end
		suboptions.args.useRangeIndicator = {
			name = L["Use Range Indicator"],
			desc = L["Toggle whether to fade unit frames of units that are out of range."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.raid5 = suboptions
	end

	-- Raid Frames (25)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame25")
		suboptions.name = L["Raid Frames"] .. " (25)"
		suboptions.order = 161
		suboptions.args.useRangeIndicator = {
			name = L["Use Range Indicator"],
			desc = L["Toggle whether to fade unit frames of units that are out of range."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		options.args.raid25 = suboptions
	end

	-- Raid Frames (40)
	do
		local suboptions, module, setter, getter, setoption, getoption, isdisabled = GenerateSubOptions("RaidFrame40")
		suboptions.name = L["Raid Frames"] .. " (40)"
		suboptions.order = 162
		suboptions.args.useRangeIndicator = {
			name = L["Use Range Indicator"],
			desc = L["Toggle whether to fade unit frames of units that are out of range."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
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
		suboptions.args.useRangeIndicator = {
			name = L["Use Range Indicator"],
			desc = L["Toggle whether to fade unit frames of units that are out of range."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		suboptions.args.elementHeader = {
			name = L["Visibility"], order = 19, type = "header", hidden = isdisabled
		}
		suboptions.args.showInBattlegrounds = {
			name = L["Show in Battlegrounds"],
			desc = L["Toggle whether to show flag carrier frames in Battlegrounds."],
			order = 20, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
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
		suboptions.args.showComboPoints = {
			name = L["Show Combo Points"],
			desc = L["Toggle whether to show Combo Points."],
			order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
		}
		if (ns.IsWrath or ns.IsRetail) then
			suboptions.args.showRunes = {
				name = L["Show Runes (Death Knight)"],
				desc = L["Toggle whether to show Death Knight Runes."],
				order = 12, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
			}
			if (ns.IsRetail) then
				suboptions.args.showArcaneCharges = {
					name = L["Show Arcane Charges (Mage)"],
					desc = L["Toggle whether to show Mage Arcane Charges."],
					order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
				}
				suboptions.args.showChi = {
					name = L["Show Chi (Monk)"],
					desc = L["Toggle whether to show Monk Chi."],
					order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
				}
				suboptions.args.showHolyPower = {
					name = L["Show Holy Power (Paladin)"],
					desc = L["Toggle whether to show Paladin Holy Power."],
					order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
				}
				suboptions.args.showSoulShards = {
					name = L["Show Soul Shards (Warlock)"],
					desc = L["Toggle whether to show Warlock Soul Shards."],
					order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
				}
				suboptions.args.showStagger = {
					name = L["Show Stagger (Monk)"],
					desc = L["Toggle whether to show Monk Stagger."],
					order = 11, type = "toggle", width = "full", set = setter, get = getter, hidden = isdisabled
				}
			end
		end
		options.args.classpower = suboptions
	end

	return options
end

Options:AddGroup(L["Unit Frames"], GenerateOptions, -8000)
