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
local MFM = ns:GetModule("MovableFramesManager", true)
local EMP = ns:GetModule("EditMode", true)

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Lua API
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match
local string_split = string.split
local table_insert = table.insert

local registerOptionsPanel = function(name, options, parent)
	AceConfigRegistry:RegisterOptionsTable(name, options)
	local categoryID = AceConfigDialog:AddToBlizOptions(name, name, parent)
	if (not Options.categoryIDs) then
		Options.categoryIDs = {}
	end
	local name = string_gsub(string_lower(name), "%s+", "")
	Options.categoryIDs[name] = categoryID
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
					return MFM.db.char.layout
				end
			}
		}
	})
	Options.categoryID = AceConfigDialog:AddToBlizOptions(AddonName, Addon)
end

local generateActionBarOptions = function()
	local subModName = AddonName.." - %s"
	local barMod = ns:GetModule("ActionBars")
	local barModEnabled = barMod.db.profile.enabled
	if (barModEnabled) then

		local setter = function(info,val)
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)"))) -- extract barID
			local db = barMod.db.profile.bars[id] -- retrieve the bar's db
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
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id]
			return db[option]
		end

		local isdisabled = function(info)
			local option, parent = info[#info], info[#info - 1]
			local id = tonumber((string_match(parent,"(%d+)")))
			local db = barMod.db.profile.bars[id]
			return option ~= "enabled" and not db.enabled
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
					numbuttons = {
						name = L["Number of buttons"],
						desc = L["Sets the number of action buttons on the action bar."],
						order = 2,
						type = "range", width = "full", min = 0, max = 12, step = 1,
						disabled = isdisabled,
						set = setter,
						get = getter
					},

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

	-- Add a few commands for faster access.
	self:RegisterChatCommand("azeriteui", "OpenMenu")
	self:RegisterChatCommand("azerite", "OpenMenu")
	self:RegisterChatCommand("azui", "OpenMenu")
	self:RegisterChatCommand("az", "OpenMenu")
end
