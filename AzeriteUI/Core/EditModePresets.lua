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
if (not ns.WoW10) then return end

local EditMode = ns:NewModule("EditMode", "LibMoreEvents-1.0", "AceConsole-3.0", "AceTimer-3.0", "AceHook-3.0")
local LEMO = LibStub("LibEditModeOverride-1.0")

local ipairs = ipairs

local defaults = { profile = ns:Merge({
	enabled = true,
}, ns.moduleDefaults) }

-- Mimicking the format used by Blizz in
-- Interface\FrameXML\EditModePresetLayouts.lua
local azeriteSystems = {
	[Enum.EditModeSystem.ChatFrame] = {
		settings = {
			[Enum.EditModeChatFrameSetting.WidthHundreds] = 4,
			[Enum.EditModeChatFrameSetting.WidthTensAndOnes] = 99,
			[Enum.EditModeChatFrameSetting.HeightHundreds] = 1,
			[Enum.EditModeChatFrameSetting.HeightTensAndOnes] = 76
		},
		anchorInfo = {
			point = "BOTTOMLEFT",
			relativeTo = "UIParent",
			relativePoint = "BOTTOMLEFT",
			offsetX = 85,
			offsetY = 350
		}
	},

	[Enum.EditModeSystem.EncounterBar] = {
		settings = {
		},
		anchorInfo = {
			point = "BOTTOM",
			relativeTo = "UIParent",
			relativePoint = "BOTTOM",
			offsetX = 0,
			offsetY = 260
		}
	},

	[Enum.EditModeSystem.ExtraAbilities] = {
		settings = {
		},
		anchorInfo = {
			point = "CENTER",
			relativeTo = "UIParent",
			relativePoint = "BOTTOMRIGHT",
			offsetX = -482,
			offsetY = 360
		}
	},

	[Enum.EditModeSystem.Minimap] = {
		settings = {
			[Enum.EditModeMinimapSetting.HeaderUnderneath] = 0,
			[Enum.EditModeMinimapSetting.RotateMinimap] = 1
		},
		anchorInfo = {
			point = "BOTTOMRIGHT",
			relativeTo = "UIParent",
			relativePoint = "BOTTOMRIGHT",
			offsetX = -20,
			offsetY = 20
		}
	},

	[Enum.EditModeSystem.HudTooltip] = {
		settings = {
		},
		anchorInfo = {
			point = "BOTTOMRIGHT",
			relativeTo = "UIParent",
			relativePoint = "BOTTOMRIGHT",
			offsetX = -319,
			offsetY = 166
		}
	},

	[Enum.EditModeUnitFrameSystemIndices.Party] = {
		settings = {
			[Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames] = 0, -- this is the important part
			[Enum.EditModeUnitFrameSetting.ShowPartyFrameBackground] = 0,
			[Enum.EditModeUnitFrameSetting.UseHorizontalGroups] = 0,
			[Enum.EditModeUnitFrameSetting.DisplayBorder] = 0,
			[Enum.EditModeUnitFrameSetting.FrameHeight] = 0,
			[Enum.EditModeUnitFrameSetting.FrameWidth] = 0,
			[Enum.EditModeUnitFrameSetting.FrameSize] = 0,
			[Enum.EditModeUnitFrameSetting.SortPlayersBy] = Enum.SortPlayersBy.Group,
		},
		anchorInfo = {
			point = "TOPLEFT",
			relativeTo = "CompactRaidFrameManager",
			relativePoint = "TOPRIGHT",
			offsetX = 0,
			offsetY = -7,
		},
	},

	[Enum.EditModeSystem.ObjectiveTracker] = {
		settings = {
			[Enum.EditModeObjectiveTrackerSetting.Height] = 40 -- doesn't stick
		},
		anchorInfo = {
			point = "TOPRIGHT",
			relativeTo = "UIParent",
			relativePoint = "TOPRIGHT",
			offsetX = -60,
			offsetY = -280
		}
	},

	[Enum.EditModeSystem.TalkingHeadFrame] = {
		settings = {
		},
		anchorInfo = {
			point = "TOP",
			relativeTo = "UIParent",
			relativePoint = "TOP",
			offsetX = 0,
			offsetY = -100
		}
	}
}

-- Yes, it's only one. My thought was to maybe have more.
local layouts = {
	defaultLayout = "Azerite",
	{
		layoutName = "Azerite",
		--layoutType = Enum.EditModeLayoutType.Character,
		layoutType = Enum.EditModeLayoutType.Account,
		systems = azeriteSystems
	}
}

EditMode.GetDefaultSystems = function(self)
	return azeriteSystems
end

EditMode.CanEditActiveLayout = function(self)
	self:LoadLayouts()
	return self.loaded and LEMO:CanEditActiveLayout() -- bugs out before initial editmode event
end

EditMode.DoesDefaultLayoutExist = function(self)
	self:LoadLayouts()
	return LEMO:DoesLayoutExist(layouts.defaultLayout)
end

EditMode.UpdateActiveLayout = function(self)
	LEMO:SetActiveLayout(LEMO:GetActiveLayout())
	LEMO:ApplyChanges()
end

EditMode.SetToDefaultLayout = function(self)
	if (InCombatLockdown()) then return end
	self:LoadLayouts()
	if (not LEMO:DoesLayoutExist(layouts.defaultLayout)) then return end
	-- Set the active layout.
	LEMO:SetActiveLayout(layouts.defaultLayout)
	LEMO:ApplyChanges()
end

-- Reset the currently selected EditMode layout
-- to AzeriteUI defaults for selected frames.
EditMode.ApplySystems = function(self, systems)
	if (InCombatLockdown()) then return end
	if (not self:CanEditActiveLayout()) then return end

	-- Get default systems.
	-- *This whole thing is redundant,
	--  but working on the assumption I'll
	--  be adding multiple systems in the future.
	if (not systems) then
		for _,layoutInfo in ipairs(layouts) do
			if (layoutInfo.layoutName == layouts.defaultLayout) then
				systems = layoutInfo.systems
				break
			end
		end
	end
	if (systems) then

		-- Apply default systems to current layout.
		for system,systemInfo in pairs(systems) do

			-- Retrieve the system frame.
			local systemFrame = EditModeManagerFrame:GetRegisteredSystemFrame(system)

			-- Reposition the system frame.
			LEMO:ReanchorFrame(systemFrame, systemInfo.anchorInfo.point, systemInfo.anchorInfo.relativeTo, systemInfo.anchorInfo.relativePoint, systemInfo.anchorInfo.offsetX, systemInfo.anchorInfo.offsetY)

			-- Apply the system frame settings.
			for setting,value in ipairs(systemInfo.settings) do
				LEMO:SetFrameSetting(systemFrame, setting, value)
			end

			-- Save the settings.
			LEMO:ApplyChanges()

		end

	end

end

-- Reset our custom layouts to AzeriteUI defaults.
-- *currently just a single one.
EditMode.ResetLayouts = function(self)
	if (InCombatLockdown()) then return end
	self:LoadLayouts()

	-- Delete all existing layouts, in case they are of the wrong type.
	for _,layoutInfo in ipairs(layouts) do
		if (LEMO:DoesLayoutExist(layoutInfo.layoutName)) then
			LEMO:DeleteLayout(layoutInfo.layoutName)
			LEMO:ApplyChanges()
		end
	end

	-- Create and reset our custom layouts.
	for _,layoutInfo in ipairs(layouts) do
		LEMO:AddLayout(layoutInfo.layoutType, layoutInfo.layoutName)
		LEMO:SetActiveLayout(layoutInfo.layoutName)
		LEMO:ApplyChanges()
		self:ApplySystems(layoutInfo.systems)
	end

	-- Set the active layout.
	self:SetToDefaultLayout()
end

EditMode.LoadLayouts = function(self)
	LEMO:LoadLayouts()
end

EditMode.AreLayoutsLoaded = function(self)
	return self.loaded and LEMO:AreLayoutsLoaded()
end

EditMode.ConsiderLayoutsLoaded = function(self)
	if (self.timer) then
		self:CancelTimer(self.timer)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "Onevent")
		self.loaded = true
	end
end

EditMode.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		if (not self.loaded) then
			self.timer = self:ScheduleTimer("ConsiderLayoutsLoaded", 5)
		end
	elseif (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		local layoutInfo, fromServer = ...
		if (fromServer) then
			self.loaded = true
		end
	end
end

EditMode.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("EditMode", defaults)

	self.db.profile.layoutsCreated = nil

	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
