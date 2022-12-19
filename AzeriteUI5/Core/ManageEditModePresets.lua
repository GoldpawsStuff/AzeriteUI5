--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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

local EditMode = ns:NewModule("EditMode", "LibMoreEvents-1.0", "AceConsole-3.0")
local LEMO = LibStub("LibEditModeOverride-1.0")

local ipairs = ipairs

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
			offsetY = 350,
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
			offsetY = 260,
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
			offsetY = 360,
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
			offsetY = 20,
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
			offsetY = 166,
		}
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
			offsetY = -280,
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
			offsetY = -100,
		}
	}
}

local layouts = {
	defaultLayout = "Azerite",
	{
		layoutName = "Azerite",
		layoutType = Enum.EditModeLayoutType.Account,
		systems = azeriteSystems,
	}
}

EditMode.ResetLayout = function(self, layoutInfo)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	for system,systemInfo in ipairs(layoutInfo.systems) do
		local systemFrame = EditModeManagerFrame:GetRegisteredSystemFrame(system)
		LEMO:ReanchorFrame(systemFrame, systemInfo.anchorInfo.point, systemInfo.anchorInfo.relativeTo, systemInfo.anchorInfo.relativePoint, systemInfo.anchorInfo.offsetX, systemInfo.anchorInfo.offsetY)
		for setting,value in ipairs(systemInfo.settings) do
			LEMO:SetFrameSetting(systemFrame, setting, value)
		end
		LEMO:ApplyChanges()
	end
end

EditMode.ResetLayouts = function(self)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	for layoutIndex,layoutInfo in ipairs(layouts) do
		if LEMO:DoesLayoutExist(layoutInfo.layoutName) then
			LEMO:DeleteLayout(layoutInfo.layoutName)
		end
	end

	self:RestoreLayouts()

	LEMO:SetActiveLayout(layouts.defaultLayout)
	LEMO:ApplyChanges()
end

EditMode.RestoreLayouts = function(self)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	-- Create and reset our custom layouts, if they don't exist.
	for layoutIndex,layoutInfo in ipairs(layouts) do
		if (not LEMO:DoesLayoutExist(layoutInfo.layoutName)) then
			LEMO:AddLayout(layoutInfo.layoutType, layoutInfo.layoutName)
			LEMO:ApplyChanges()
			self:ResetLayout(layoutInfo)
		end
	end
end

EditMode.OnEvent = function(self, event, ...)
	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
		LEMO:LoadLayouts()
	end
	if (not LEMO:AreLayoutsLoaded()) then return end

	-- Restore our custom layouts if they have been deleted.
	-- This might piss people off, so should probably make this a one-time thing.
	-- Create a saved setting for "layoutsCreated" or something like that.
	self:RestoreLayouts()
end

EditMode.OnInitialize = function(self)
	self:RegisterChatCommand("resetlayout", "ResetLayouts")
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
end
