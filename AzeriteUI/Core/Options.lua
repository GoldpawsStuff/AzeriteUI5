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
	local categoryID = AceConfigDialog:AddToBlizOptions(name, name, parent)
	if (not Options.categoryIDs) then
		Options.categoryIDs = {}
	end
	local simplifiedName = string_gsub(string_lower(name), "%s+", "")
	Options.categoryIDs[simplifiedName] = categoryID
	panels[name] = true
end

local generateOptions = function()
	AceConfigRegistry:RegisterOptionsTable(AddonName, {
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
	})
	Options.categoryID = AceConfigDialog:AddToBlizOptions(AddonName, Addon)
	panels[AddonName] = true
end

local generateActionBarOptions = function()
	local subModName = AddonName.." - %s"
	local barMod = ns:GetModule("ActionBars")
	local barModEnabled = barMod.db.profile.enabled
	if (barModEnabled) then

		local setter = function(info,val)
			local LAYOUT = MFM:GetLayout()
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)"))) -- extract barID
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT] -- retrieve the bar's db
			db[option] = val -- save the setting
			barMod:UpdateSettings() -- apply bar settings
			if (option == "enabled") then
				local parent = info[#info-1]
				for i,v in pairs(info.options.args[parent].args) do
					if (i ~= "enabled") then
						v.disabled = not val -- disable bar options when bar is disabled
					end
				end
			end
		end

		local getter = function(info)
			local LAYOUT = MFM:GetLayout()
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT]
			return db[option]
		end

		local isdisabled = function(info)
			local LAYOUT = MFM:GetLayout()
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT]
			return option ~= "enabled" and not db.enabled
		end

		local getsetting = function(info, setting)
			local LAYOUT = MFM:GetLayout()
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT]
			return db[setting]
		end

		local setoption = function(info,option,val)
			local LAYOUT = MFM:GetLayout()
			local parent = info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)"))) -- extract barID
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT] -- retrieve the bar's db
			db[option] = val -- save the setting
			barMod:UpdateSettings() -- apply bar settings
		end

		local getoption = function(info,option)
			local LAYOUT = MFM:GetLayout()
			local parent = info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id].savedPosition[LAYOUT]
			return db[option]
		end

		local barOptions = {
			name = string_format(subModName, L["Action Bar Settings"]),
			type = "group",
			args = {}
		}

		-- Build standar bar option tables.
		for id = 1,ns.IsRetail and 8 or 5 do
			barOptions.args["bar"..id] = {
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
					pointPreSpace = {
						name = "", order = 60, type = "description", hidden = isdisabled
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
							local val = tonumber((string_match(val,"(%d+%.?%d*)")))
							if (val) then return true end
							return L["Only numbers are allowed."]
						end,
						set = function(info,val)
							local val = tonumber((string_match(val,"(%d+%.?%d*)")))
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
							local val = tonumber((string_match(val,"(%d+%.?%d*)")))
							if (val) then return true end
							return L["Only numbers are allowed."]
						end,
						set = function(info,val)
							local val = tonumber((string_match(val,"(%d+%.?%d*)")))
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
		registerOptionsPanel(L["Action Bars"], barOptions, Addon)
	end

end

local generateUnitFrameOptions = function()
	local subModName = AddonName.." - %s"
	local unitFrameOptions = {
		name = string_format(subModName, L["UnitFrame Settings"]),
		type = "group",
		args = {}
	}
	if (ns.IsRetail or ns.IsWrath) then
	end
	registerOptionsPanel(L["Unit Frames"], unitFrameOptions, Addon)
end

local generateTooltipOptions = function()
	local subModName = AddonName.." - %s"
	local tooltipMod = ns:GetModule("Tooltips")
	local tooltipModEnabled = tooltipMod.db.profile.enabled
	if (tooltipModEnabled) then

		local setter = function(info,val)
			tooltipMod.db.profile[info[#info]] = val
		end

		local getter = function(info)
			return tooltipMod.db.profile[info[#info]]
		end

		local tooltipOptions = {
			name = string_format(subModName, L["Tooltip Settings"]),
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
		registerOptionsPanel(L["Tooltips"], tooltipOptions, Addon)
	end
end

local generateAuraOptions = function()
	local subModName = AddonName.." - %s"
	local auraMod = ns:GetModule("Auras")
	local auraModEnabled = auraMod.db.profile.enabled
	if (auraModEnabled) then
		registerOptionsPanel(L["Player Auras"], {
			name = string_format(subModName, L["Aura Settings"]),
			type = "group",
			args = {}
		}, Addon)
	end
end

local generateFadeOptions = function()
	local subModName = AddonName.." - %s"
	registerOptionsPanel(L["Frame Fading"], {
		name = string_format(subModName, L["Frame Fade Settings"]),
		type = "group",
		args = {}
	}, Addon)
end

local generateOptionsPages = function()
	generateActionBarOptions()
	--generateUnitFrameOptions()
	generateTooltipOptions()
	--generateAuraOptions()
	--generateFadeOptions()
end

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

Options.OpenMenu = function(self, input)
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

Options.OnInitialize = function(self)
	-- Main options page.
	-- Register this early to get the order right.
	generateOptions()
end

-- Refresh requested panels, or all if none is passed.
-- *Note that panel names are localized.
Options.Refresh = function(self, ...)
	if (...) then
		local panelName
		for i = 1,select("#", ...) do
			panelName = select(i, ...)
			if (panels[panelName]) then
				AceConfigRegistry:NotifyChange(panelName)
			end
		end
	else
		for panelName in next,panels do
			AceConfigRegistry:NotifyChange(panelName)
		end
	end
end

Options.OnEnable = function(self)
	-- The rest of the options pages.
	-- These require the various addon modules to be loaded.
	generateOptionsPages()

	-- Hack to force menu creation early.
	-- If we don't do this the chat command will fail the first time.
	if (InterfaceOptionsFrame) then
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame:Hide()
	end

	--ns.RegisterCallback(self, "MFM_LayoutDeleted", "Refresh")
	--ns.RegisterCallback(self, "MFM_LayoutsUpdated", "Refresh")

	-- Add a few commands for faster access.
	self:RegisterChatCommand("azeriteui", "OpenMenu")
	self:RegisterChatCommand("azerite", "OpenMenu")
	self:RegisterChatCommand("azui", "OpenMenu")
	self:RegisterChatCommand("az", "OpenMenu")
end
