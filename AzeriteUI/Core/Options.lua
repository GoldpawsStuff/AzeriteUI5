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
local AddonName = GetAddOnMetadata(Addon, "Title")

local L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)

local Options = ns:NewModule("Options", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager")
local EMP = ns:GetModule("EditMode", true)

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Lua API
local math_floor = math.floor
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match
local string_split = string.split
local table_insert = table.insert

local panels = {}

local registerOptionsPanel = function(name, options, parent)
	AceConfigRegistry:RegisterOptionsTable(name, options)
	local categoryID = AceConfigDialog:AddToBlizOptions(name, name, parent or Addon)
	if (not Options.categoryIDs) then
		Options.categoryIDs = {}
	end
	local simplifiedName = string_gsub(string_lower(name), "%s+", "")
	Options.categoryIDs[simplifiedName] = categoryID
	panels[name] = true
end

local generateName = function(name)
	return string_format("%s - %s", AddonName, name)
end

local generateOptions = function()

	local optionsTable = {
		type = "group",
		args = {
			profiles = {
				name = L["Settings Profile"],
				desc = L["Choose your settings profile. This choice affects all settings including frame placement."],
				type = "select",
				style = "dropdown",
				values = function(info)
					local values = {}
					for layout in pairs(MFM.layouts) do
						values[layout] = layout
					end
					return values
				end,
				set = function(info, val)
					MFM:ApplyPreset(val)
				end,
				get = function(info)
					return MFM:GetLayout()
				end
			}
		}
	}
	AceConfigRegistry:RegisterOptionsTable(AddonName, optionsTable)
	Options.categoryID = AceConfigDialog:AddToBlizOptions(AddonName, Addon)

	panels[AddonName] = true
end

local generateActionBarOptions = function()

	local module = ns:GetModule("ActionBars", true)
	if (not module or not module.db.profile.enabled) then
		return
	end

	local setter = function(info,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		db[info[#info]] = val
		module:UpdateSettings()
	end

	local getter = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		return db[info[#info]]
	end

	local isdisabled = function(info)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		return info[#info] ~= "enabled" and not db.enabled
	end

	local getsetting = function(info, setting)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		return db[setting]
	end

	local setoption = function(info,option,val)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		db[option] = val
		module:UpdateSettings()
	end

	local getoption = function(info,option)
		local id = tonumber((string_match(info[#info - 1],"(%d+)")))
		local db = module.db.profile.bars[id].savedPosition[MFM:GetLayout()]
		return db[option]
	end

	local optionsTable = {
		name = generateName(L["Action Bar Settings"]),
		type = "group",
		args = {}
	}

	for id = 1,ns.IsRetail and 8 or 5 do
		optionsTable.args["bar"..id] = {
			name = string_format(L["Action Bar %d"], id),
			order = 1,
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
					name = L["Choose when your auras will be visible."],
					order = 3,
					type = "description",
					fontSize = "medium",
					hidden = isdisabled
				},
				enableBarFading = {
					name = L["Enable Bar Fading"],
					desc = L["Toggle whether to enable the buttons of this action bar to fade out."],
					order = 10,
					type = "toggle", width = "full",
					hidden = isdisabled,
					set = setter,
					get = getter
				},
				fadeFrom = {
					name = L["Start Fading from"],
					desc = L["Choose which button to start the fading from."],
					order = 11,
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
					name = L["Choose how your auras are displayed."],
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
				},
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
					desc = L["Sets the anchor point of your actionbar."],
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
					name = L["Offset X"],
					desc = L["Sets the horizontal offset from your chosen point. Positive values means right, negative values means left."],
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
					name = L["Offset Y"],
					desc = L["Sets the vertical offset from your chosen point. Positive values means up, negative values means down."],
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
				}
			}
		}
	end

	registerOptionsPanel(L["Action Bars"], optionsTable)
end

local generateUnitFrameOptions = function()

	local module = ns:GetModule("UnitFrames", true)
	if (not module or not module.db.profile.enabled) then
		return
	end

	local setter = function(info,val)
		module.db.profile[info[#info]] = val
		module:UpdateSettings()
	end

	local getter = function(info)
		return module.db.profile[info[#info]]
	end

	local isdisabled = function(info)
		return info[#info] ~= "enabled" and not module.db.profile.enabled
	end

	local setoption = function(info,option,val)
		module.db.profile[option] = val
		module:UpdateSettings()
	end

	local getoption = function(info,option)
		return module.db.profile[option]
	end

	local optionsTable = {
		name = generateName(L["UnitFrame Settings"]),
		type = "group",
		args = {
			auraHeader = {
				name = L["Aura Settings"],
				order = 2,
				type = "header",
				hidden = isdisabled
			},
			auraDesc = {
				name = L["Here you can change settings related to the aura buttons appearing at each unitframe."],
				order = 3,
				type = "description",
				fontSize = "medium",
				hidden = isdisabled
			},
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

	local categoryCount = 0

	-- Player
	do
		local module = ns:GetModule("PlayerFrame", true)
		if (module and module.db.profile.enabled) then

			categoryCount = categoryCount + 1

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

			optionsTable.args.player = {
				name = PLAYER,
				type = "group",
				order = 100 + (categoryCount - 1) * 10,
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
						desc = L["Sets the anchor point of the unit frame."],
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
						desc = L["Sets the horizontal offset from your chosen point. Positive values means right, negative values means left."],
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
						desc = L["Sets the vertical offset from your chosen point. Positive values means up, negative values means down."],
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

		end
	end

	-- Player Cast Bar
	-- Player Class Power
	-- Pet
	-- Target
	-- ToT
	-- Focus


	-- NamePlates

	-- Party
	-- Raid
	-- Boss
	-- Arena

	if (ns.IsRetail or ns.IsWrath) then

	end

	registerOptionsPanel(L["Unit Frames"], optionsTable)
end

local generateTooltipOptions = function()

	local module = ns:GetModule("Tooltips", true)
	if (not module or not module.db.profile.enabled) then
		return
	end

	local setter = function(info,val)
		module.db.profile[info[#info]] = val
	end

	local getter = function(info)
		return module.db.profile[info[#info]]
	end

	local optionsTable = {
		name = generateName(L["Tooltip Settings"]),
		type = "group",
		args = {
			showItemID = {
				name = L["Show itemID"],
				desc = L["Toggle whether to add itemID to item tooltips or not."],
				order = 1,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			},
			showSpellID = {
				name = L["Show spellID"],
				desc = L["Toggle whether to add spellIDs and auraIDs in tooltips containing actions, spells or auras."],
				order = 2,
				type = "toggle", width = "full",
				set = setter,
				get = getter
			}
		}
	}

	registerOptionsPanel(L["Tooltips"], optionsTable)
end

local generateAuraOptions = function()

	local module = ns:GetModule("Auras", true)
	if (not module or not module.db.profile.enabled) then
		return
	end

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

	local optionsTable = {
		name = generateName(L["Aura Settings"]),
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
				desc = L["Sets the anchor point of your auras."],
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
			pointPostSpace = {
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
				desc = L["Sets the anchor point of your auras."],
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
				desc = L["Sets the horizontal offset from your chosen point. Positive values means right, negative values means left."],
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
				desc = L["Sets the vertical offset from your chosen point. Positive values means up, negative values means down."],
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

	registerOptionsPanel(L["Player Auras"], optionsTable)
end

local generateBagOptions = function()

	local module = ns:GetModule("Containers", true)
	if (not module or not module.db.profile.enabled) then
		return
	end

	local setter = function(info,val)
		module.db.profile[info[#info]] = val
		module:UpdateSettings()
	end

	local getter = function(info)
		return module.db.profile[info[#info]]
	end

	local isdisabled = function(info)
		return info[#info] ~= "enabled" and not module.db.profile.enabled
	end

	local setoption = function(info,option,val)
		module.db.profile[option] = val
		module:UpdateSettings()
	end

	local getoption = function(info,option)
		return module.db.profile[option]
	end

	local optionsTable = {
		name = generateName(L["Bag Settings"]),
		type = "group",
		args = {}
	}

	if (C_Container.SetSortBagsRightToLeft) then
		optionsTable.args["sort"] = {
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
		optionsTable.args.space1 = {
			name = "", order = 2, type = "description", hidden = isdisabled
		}

	end

	if (C_Container.SetInsertItemsLeftToRight) then
		optionsTable.args["insert"] = {
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
		optionsTable.args.space2 = {
			name = "", order = 4, type = "description", hidden = isdisabled
		}
	end

	registerOptionsPanel(L["Bags"], optionsTable)
end

local generateFadeOptions = function()

	local optionsTable = {
		name = generateName(L["Frame Fade Settings"]),
		type = "group",
		args = {}
	}

	registerOptionsPanel(L["Frame Fading"], optionsTable)
end

local generateOptionsPages = function()
	generateActionBarOptions()
	generateUnitFrameOptions()
	generateAuraOptions()
	generateTooltipOptions()
	generateBagOptions()
	--generateFadeOptions()
end

-- Make updates a little easier.
local shorthand = {
	actionbars = L["Action Bars"],
	unitframes = L["Unit Frames"]
}

-- Refresh requested panels, or all if none is passed.
-- *Note that panel names are localized.
Options.Refresh = function(self, ...)
	if (...) then
		local panelName
		for i = 1,select("#", ...) do
			panelName = select(i, ...)
			local name = shorthand[panelName] or panelName
			if (panels[name]) then
				AceConfigRegistry:NotifyChange(name)
			end
		end
	else
		for panelName in next,panels do
			AceConfigRegistry:NotifyChange(panelName)
		end
	end
end

Options.OnInitialize = function(self)

	-- Main options page.
	-- Register this early to get the order right.
	generateOptions()
end

Options.OnEnable = function(self)

	-- The rest of the options pages.
	-- These require the various addon modules to be loaded.
	generateOptionsPages()

	if (ns.IsClassic or ns.IsTBC or ns.IsWrath and ((ns.ClientMinor < 4) or (ns.ClientMinor == 4 and ns.ClientMicro < 2))) then

		-- Hack to force menu creation early.
		-- If we don't do this the chat command will fail the first time.
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame:Hide()

		local shorthand = {
			aura = "playerauras",
			auras = "playerauras",
			bar = "actionbars",
			bars = "actionbars",
			fade = "framefading",
			fades = "framefading",
			fading = "framefading",
			unit = "unitframes",
			units = "unitframes"
		}

		-- Open directly to a specific menu page.
		-- For reasons unknown this is currently only working in the classics.
		self.OpenMenu = function(self, input)
			local categoryID = self.categoryID
			if (input) then
				input = string_gsub(input, "%s+", " ")
				local subMenuName = string_split(" ", string_lower(input))
				local subMenuCategory = (subMenuName and self.categoryIDs[subMenuName]) or (shorthand[subMenuName] and self.categoryIDs[shorthand[subMenuName]])
				if (subMenuCategory) then
					self.categoryID = subMenuCategory
				end
			end
			(Settings and Settings.OpenToCategory or InterfaceOptionsFrame_OpenToCategory) (self.categoryID)
		end

		-- Add a few commands for faster access.
		self:RegisterChatCommand("azeriteui", "OpenMenu")
		self:RegisterChatCommand("azerite", "OpenMenu")
		self:RegisterChatCommand("azui", "OpenMenu")
		self:RegisterChatCommand("az", "OpenMenu")
	end
end
