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

local Options = ns:NewModule("Options", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager")
local EMP = ns:GetModule("EditMode", true)

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

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
			},
			space1 = {
				name = "", order = 10, type = "description"
			},
			reset = {
				name = L["Reset"],
				type = "execute",
				--width = .3,
				order = 11,
				func = function(info) end
			},
			delete = {
				name = L["Delete"],
				type = "execute",
				--width = .3,
				order = 12,
				disabled = function(info)
					return MFM:GetLayout() == MFM:GetDefaultLayout()
				end,
				func = function(info) end
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
			},
			create = {
				name = L["Create"],
				type = "execute",
				--width = .3,
				order = 22,
				func = function(info) end
			},
			space3 = {
				name = "", order = 23, type = "description"
			}
		}
	}
	return options
end

--local generateFadeOptions = function()
--
--	local optionsTable = {
--		name = L["Frame Fade Settings"],
--		type = "group",
--		args = {}
--	}
--
--	registerOptionsPanel(L["Frame Fading"], optionsTable)
--end

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
	self.objects[#self.objects + 1] = { name = name, group = group }
end

Options.GenerateOptionsMenu = function(self)
	if (not self.objects) then return end

	-- Sort groups by localized name.
	table.sort(self.objects, function(a,b) return a.name < b.name end)

	-- Generate the options table.
	local options = self:GenerateProfileMenu()
	local order = 0
	for i,data in ipairs(self.objects) do

		local group
		if (type(data.group) == "function") then
			group = data.group()
		else
			group = data.group
		end
		if (group) then
			order = order + 10
			group.order = order
			group.childGroups = group.childGroups or "tab"
			options.args[data.name] = group
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
