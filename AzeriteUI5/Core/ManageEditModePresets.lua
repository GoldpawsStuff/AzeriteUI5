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
local oUF = ns.oUF

local EditMode = ns:NewModule("EditMode", "LibMoreEvents-1.0", "AceConsole-3.0")
local LEMO = LibStub("LibEditModeOverride-1.0")

EditMode.RestorePreset = function(self)
	if (InCombatLockdown()) then return end
	if (not LEMO:AreLayoutsLoaded()) then return end

	if (not LEMO:DoesLayoutExist("Azerite")) then
		LEMO:AddLayout(Enum.EditModeLayoutType.Character, "Azerite")
		LEMO:ApplyChanges()
	end

	LEMO:SetActiveLayout("Azerite")
	LEMO:ApplyChanges()

	local minimap = EditModeManagerFrame:GetRegisteredSystemFrame(Enum.EditModeSystem.Minimap)

	-- Reanchor frames. Where do I find these frames?
	LEMO:ReanchorFrame(minimap, "BOTTOMRIGHT", -20, 20)
	LEMO:SetFrameSetting(minimap, Enum.EditModeMinimapSetting.RotateMinimap, 1)

	local tracker = EditModeManagerFrame:GetRegisteredSystemFrame(Enum.EditModeSystem.ObjectiveTracker)
	LEMO:SetFrameSetting(tracker, Enum.EditModeObjectiveTrackerSetting.Height, 40) -- doesn't stick
	LEMO:ReanchorFrame(tracker, "TOPRIGHT", -60, -280)

	local tooltip = EditModeManagerFrame:GetRegisteredSystemFrame(Enum.EditModeSystem.HudTooltip)
	LEMO:ReanchorFrame(tooltip, "BOTTOMRIGHT", -319, 166)


	LEMO:ApplyChanges()

end

EditMode.OnEvent = function(self, event, ...)
	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
		LEMO:LoadLayouts()
	end
	if (not LEMO:AreLayoutsLoaded()) then return end
	if (not LEMO:DoesLayoutExist("Azerite")) then
		self:RestorePreset()
	end
end

EditMode.OnInitialize = function(self)
	self:RegisterChatCommand("resetpreset", "RestorePreset")
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
end
