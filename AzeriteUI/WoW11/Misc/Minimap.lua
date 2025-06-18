--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

if (not ns.WoW11) then return end

local MinimapMod = ns:GetModule("Minimap", true)
if (not MinimapMod) then return end

MinimapMod:SetEnabledState(false)

MinimapMod.OnInitialize = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "DelayedEnable")
end

MinimapMod.DelayedEnable = function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "DelayedEnable")

	ns.MovableModulePrototype.OnInitialize(self)

	self:Enable()

	-- Manually enable the XP bars,
	-- in case they were unable to previously load
	-- because of the delayed Minimap module start.
	local PlayerStatusBars = ns:GetModule("PlayerStatusBars", true)
	if (PlayerStatusBars and not PlayerStatusBars:IsEnabled()) then
		PlayerStatusBars:Enable()
	end
end

MinimapMod.InitializeObjectTables = function(self)

	-- Minimap objects available for restyling.
	----------------------------------------------------
	self.Objects.Addons = AddonCompartmentFrame
	self.Objects.BorderTop = MinimapCluster.BorderTop
	self.Objects.Calendar = GameTimeFrame
	self.Objects.Clock = TimeManagerClockButton
	self.Objects.Compass = MinimapCompassTexture
	self.Objects.Crafting = MinimapCluster.IndicatorFrame.CraftingOrderFrame
	self.Objects.Difficulty = MinimapCluster.InstanceDifficulty
	self.Objects.Expansion = ExpansionLandingPageMinimapButton
	self.Objects.Eye = QueueStatusButton
	self.Objects.Mail = MinimapCluster.IndicatorFrame.MailFrame
	self.Objects.Tracking = MinimapCluster.Tracking
	self.Objects.Zone = MinimapCluster.ZoneTextButton
	self.Objects.ZoomIn = Minimap.ZoomIn
	self.Objects.ZoomOut = Minimap.ZoomOut

	-- Object parents when using blizzard theme.
	----------------------------------------------------
	self.ObjectOwners.Addons = MinimapCluster
	self.ObjectOwners.BorderTop = MinimapCluster
	self.ObjectOwners.Calendar = MinimapCluster
	self.ObjectOwners.Clock = MinimapCluster
	self.ObjectOwners.Compass = MinimapBackdrop
	self.ObjectOwners.Crafting = MinimapCluster.IndicatorFrame
	self.ObjectOwners.Difficulty = MinimapCluster
	self.ObjectOwners.Expansion = MinimapBackdrop
	self.ObjectOwners.Eye = MicroButtonAndBagsBar
	self.ObjectOwners.Mail = MinimapCluster.IndicatorFrame
	self.ObjectOwners.Tracking = MinimapCluster
	self.ObjectOwners.Zone = MinimapCluster
	self.ObjectOwners.ZoomIn = Minimap
	self.ObjectOwners.ZoomOut = Minimap

end
