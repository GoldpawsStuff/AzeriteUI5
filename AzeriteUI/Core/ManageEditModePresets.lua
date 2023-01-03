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

local EditMode = ns:NewModule("EditMode", "LibMoreEvents-1.0", "AceConsole-3.0", "AceTimer-3.0")
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
		layoutType = Enum.EditModeLayoutType.Account,
		systems = azeriteSystems
	}
}

EditMode.RestoreLayouts = function(self)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	-- Create and reset our custom layouts, if they don't exist.
	for _,layoutInfo in ipairs(layouts) do
		if (not LEMO:DoesLayoutExist(layoutInfo.layoutName)) then
			LEMO:AddLayout(layoutInfo.layoutType, layoutInfo.layoutName)
			LEMO:SetActiveLayout(layoutInfo.layoutName)
			LEMO:ApplyChanges()

			for system,systemInfo in pairs(layoutInfo.systems) do
				local systemFrame = EditModeManagerFrame:GetRegisteredSystemFrame(system)
				LEMO:ReanchorFrame(systemFrame, systemInfo.anchorInfo.point, systemInfo.anchorInfo.relativeTo, systemInfo.anchorInfo.relativePoint, systemInfo.anchorInfo.offsetX, systemInfo.anchorInfo.offsetY)

				for setting,value in ipairs(systemInfo.settings) do
					LEMO:SetFrameSetting(systemFrame, setting, value)
				end

				LEMO:ApplyChanges()
			end
		end
	end
end

EditMode.ResetLayouts = function(self)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	-- Delete all existing layouts, in case they are of the wrong type.
	for _,layoutInfo in ipairs(layouts) do
		if (LEMO:DoesLayoutExist(layoutInfo.layoutName)) then
			LEMO:DeleteLayout(layoutInfo.layoutName)
			LEMO:ApplyChanges()
		end
	end

	-- Create and reset our custom layouts.
	self:RestoreLayouts()

	LEMO:SetActiveLayout(layouts.defaultLayout)
	LEMO:ApplyChanges()
end

EditMode.TriggerPresetChange = function(self)
	LEMO:SetActiveLayout(layouts.defaultLayout)
	LEMO:ApplyChanges()
	-- Keep triggering until it works
	if (LEMO:GetActiveLayout() ~= layouts.defaultLayout) then
		return self:TriggerPresetChange("TriggerEditModeReset", 1)
	end
	self.TriggerPresetChange = ns.Noop
end

EditMode.TriggerEditModeReset = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end
	-- Keep triggering until it works
	LEMO:LoadLayouts()
	if (not LEMO:AreLayoutsLoaded()) then
		return self:ScheduleTimer("TriggerEditModeReset", 1)
	end
	-- Reset layouts.
	self:ResetLayouts()
	self:TriggerPresetChange()
	self.TriggerEditModeReset = ns.Noop
end

EditMode.OnEvent = function(self, event, ...)
	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent") -- would be an endless loop otherwise.
		LEMO:LoadLayouts()
	end
	if (not LEMO:AreLayoutsLoaded()) then return end

	-- Restore our custom layouts if they have been deleted.
	-- This might piss people off, so should probably make this a one-time thing.
	-- Create a saved setting for "layoutsCreated" or something like that.
	self:RestoreLayouts() -- this trigger the event that got us here.
end

EditMode.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("EditMode", defaults)

	-- Cannot register for this in OnEnable, that's too late.
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")

	if (ns.triggerEditModeReset) then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "TriggerEditModeReset")
	end

	self:RegisterChatCommand("resetlayout", "ResetLayouts")
end
