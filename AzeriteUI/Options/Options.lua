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
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local Options = ns:NewModule("Options", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")
local EMP = ns:GetModule("EditMode", true)

-- Lua API
local ipairs = ipairs
local pairs = pairs
local string_format = string.format
local table_remove = table.remove
local table_sort = table.sort
local type = type

Options.GenerateProfileMenu = function(self)
	local options = {
		type = "group",
		childGroups = "tree",
		args = {
			profiles = {
				name = L["Settings Profile"],
				desc = L["Choose your settings profile. This choice affects all settings including frame placement."],
				type = "select",
				style = "dropdown",
				order = 0,
				values = function(info)
					local values = {}
					for i,profileKey in ipairs(ns:GetProfiles()) do
						values[profileKey] = profileKey
					end
					return values
				end,
				set = function(info, val)
					ns:SetProfile(val)
				end,
				get = function(info)
					return ns:GetProfile()
				end
			},
			space1 = {
				name = "", order = 10, type = "description"
			},
			reset = {
				name = L["Reset"],
				type = "execute",
				order = 11,
				func = function(info)
					ns:ResetProfile(ns:GetProfile())
				end
			},
			delete = {
				name = L["Delete"],
				type = "execute",
				order = 12,
				confirm = function(info)
					return string_format(L["Are you sure you want to delete the preset '%s'? This cannot be undone."], ns:GetProfile())
				end,
				disabled = function(info)
					return ns:GetProfile() == ns:GetDefaultProfile()
				end,
				func = function(info)
					ns:DeleteProfile(ns:GetProfile())
				end
			},
			space2 = {
				name = "", order = 13, type = "description"
			},
			newprofileheader = {
				name = L["Create New Profile"],
				desc = L["Create a new settings profile."],
				type = "header",
				order = 20
			},
			newprofileName = {
				name = L["Name of new profile:"],
				type = "input",
				order = 21,
				arg = "", -- store the name here
				validate = function(info,val)
					if (not val or val == "") then
						return L["The new profile needs a name."]
					end
					if (ns:ProfileExists(val)) then
						return L["Profile already exists."]
					end
					return true
				end,
				get = function(info)
					return info.option.arg
				end,
				set = function(info,val)
					info.option.arg = val
				end
			},
			space3 = {
				name = "", order = 22, type = "description"
			},
			create = {
				name = L["Create"],
				desc = L["Create a new profile with the chosen name."],
				type = "execute",
				order = 23,
				disabled = function(info)
					local val = info.options.args.newprofileName.arg
					return (not val or val == "" or ns:ProfileExists(val))
				end,
				func = function(info)
					local layoutName = info.options.args.newprofileName.arg
					if (layoutName) then
						ns:SetProfile(layoutName)
						info.options.args.newprofileName.arg = ""
					end
				end
			},
			duplicate = {
				name = L["Duplicate"],
				desc = L["Create a new profile with the chosen name and copy the settings from the currently active one."],
				type = "execute",
				order = 24,
				disabled = function(info)
					local val = info.options.args.newprofileName.arg
					return (not val or val == "" or ns:ProfileExists(val))
				end,
				func = function(info)
					local layoutName = info.options.args.newprofileName.arg
					if (layoutName) then
						ns:DuplicateProfile(layoutName)
						info.options.args.newprofileName.arg = ""
					end
				end
			},
			space4 = {
				name = "", order = 25, type = "description"
			}
		}
	}
	return options
end

Options.Refresh = function(self)
	if (AceConfigRegistry:GetOptionsTable(Addon)) then
		AceConfigRegistry:NotifyChange(Addon)
	end
end

Options.OpenOptionsMenu = function(self)
	if (AceConfigRegistry:GetOptionsTable(Addon)) then
		AceConfigDialog:Open(Addon)
	end
end

Options.AddGroup = function(self, name, group)
	if (not self.objects) then
		self.objects = {}
	end
	if (group) then
		self.objects[#self.objects + 1] = { name = name, group = group }
	end
end

Options.GenerateOptionsMenu = function(self)
	if (not self.objects) then return end

	-- Generate the menus, remove empty objects.
	for i = #self.objects,1,-1 do
		local data = self.objects[i]
		if (type(data.group) == "function") then
			data.group = data.group()
			if (not data.group) then
				table_remove(self.objects, i)
			end
		end
	end

	-- Sort groups by localized name.
	table_sort(self.objects, function(a,b) return a.group.name < b.group.name end)

	-- Generate the options table.
	local options = self:GenerateProfileMenu()
	local order = 0
	for i,data in ipairs(self.objects) do
		if (data.group) then
			order = order + 10
			data.group.order = order
			data.group.childGroups = data.group.childGroups or "tab"
			options.args[data.name] = data.group
		end
	end

	AceConfigRegistry:RegisterOptionsTable(Addon, options)
end

Options.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:GenerateOptionsMenu()
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		end
	elseif (event == "PLAYER_TALENT_UPDATE") then
		self:Refresh()
	end
end

Options.OnInitialize = function(self)
end

Options.OnEnable = function(self)
	self:RegisterChatCommand("az", "OpenOptionsMenu")
	self:RegisterChatCommand("azerite", "OpenOptionsMenu")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
end

Options.OnDisable = function(self)
	self:UnregisterChatCommand("az")
	self:UnregisterChatCommand("azerite")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
end
