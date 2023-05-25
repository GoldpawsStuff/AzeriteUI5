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

if (not DurabilityFrame or ns.IsRetail) then return end

local Durability = ns:NewModule("Durability", "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0", "AceTimer-3.0")
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local pairs, unpack = pairs, unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = {
			scale = ns.API.GetEffectiveScale(),
			[1] = "BOTTOMRIGHT",
			[2] = -(360 + 60/2) * ns.API.GetEffectiveScale(),
			[3] = (190 -75/2) * ns.API.GetEffectiveScale()
		}
	}
}, ns.moduleDefaults) }

-- Sourced from INVENTORY_ALERT_STATUS_SLOTS in FrameXML/DurabilityFrame.lua
local inventorySlots = {
	[ 1] = { slot = "Head" },
	[ 2] = { slot = "Shoulders" },
	[ 3] = { slot = "Chest" },
	[ 4] = { slot = "Waist" },
	[ 5] = { slot = "Legs" },
	[ 6] = { slot = "Feet" },
	[ 7] = { slot = "Wrists" },
	[ 8] = { slot = "Hands" },
	[ 9] = { slot = "Weapon", showSeparate = 1 },
	[10] = { slot = "Shield", showSeparate = 1 },
	[11] = { slot = "Ranged", showSeparate = 1 }
}

local inventoryColors = {
	default = { .6, .6, .6, .75 },
	[1] = { 1, .7, .1 },
	[2] = { .9, .3, .1 }
}

Durability.InitializeDurabilityFrame = function(self)

	-- Will this taint?
	-- *This is to prevent the durability frame size
	-- affecting other anchors
	DurabilityFrame:UnregisterAllEvents()
	DurabilityFrame:SetScript("OnShow", nil)
	DurabilityFrame:SetScript("OnHide", nil)
	DurabilityFrame:SetParent(UIHider)
	DurabilityFrame:Hide()
	DurabilityFrame.IsShown = function() return false end

	-- Create a carbon copy of the blizzard durability frame.
	-- Everything here found in FrameXML/DurabilityFrame.xml
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(60,75)

	local head = frame:CreateTexture()
	head:SetSize(18,22)
	head:SetPoint("TOPRIGHT")
	head:SetDrawLayer("BACKGROUND", 0)
	head:SetTexCoord(0, .140625, 0, .171875)
	frame.Head = head

	local shoulders = frame:CreateTexture()
	shoulders:SetSize(48,22)
	shoulders:SetPoint("TOP", head, "BOTTOM", 0,16)
	shoulders:SetDrawLayer("BACKGROUND", 0)
	shoulders:SetTexCoord(.140625, .515625, 0, .171875)
	frame.Shoulders = shoulders

	local chest = frame:CreateTexture()
	chest:SetSize(20,22)
	chest:SetPoint("TOP", shoulders, "TOP", 0,-7)
	chest:SetDrawLayer("BACKGROUND", 0)
	chest:SetTexCoord(.515625, .6640625, 0, .171875)
	frame.Chest = chest

	local wrists = frame:CreateTexture()
	wrists:SetSize(44,22)
	wrists:SetPoint("TOP", shoulders, "BOTTOM", 0,7)
	wrists:SetDrawLayer("BACKGROUND", 0)
	wrists:SetTexCoord(.6640625, 1, 0, .171875)
	frame.Wrists = wrists

	local hands = frame:CreateTexture()
	hands:SetSize(42,18)
	hands:SetPoint("TOP", wrists, "BOTTOM", 0,15)
	hands:SetDrawLayer("BACKGROUND", 0)
	hands:SetTexCoord(0, .328125, .171875, .3046875)
	frame.Hands = hands

	local waist = frame:CreateTexture()
	waist:SetSize(16,5)
	waist:SetPoint("TOP", chest, "BOTTOM", 0,6)
	waist:SetDrawLayer("BACKGROUND", 0)
	waist:SetTexCoord(.328125, .46875, .171875, .203125)
	frame.Waist = waist

	local legs = frame:CreateTexture()
	legs:SetSize(29,20)
	legs:SetPoint("TOP", waist, "BOTTOM", 0,2)
	legs:SetDrawLayer("BACKGROUND", 0)
	legs:SetTexCoord(.46875, .6875, .171875, .3203125)
	frame.Legs = legs

	local feet = frame:CreateTexture()
	feet:SetSize(41,32)
	feet:SetPoint("TOP", legs, "BOTTOM", 0,8)
	feet:SetDrawLayer("BACKGROUND", 0)
	feet:SetTexCoord(.6875, 1, .171875, .4140625)
	frame.Feet = feet

	local weapon = frame:CreateTexture()
	weapon:SetSize(20,45)
	weapon:SetPoint("RIGHT", wrists, "LEFT", 0,-6)
	weapon:SetDrawLayer("BACKGROUND", 0)
	weapon:SetTexCoord(0, .140625, .3203125, .6640625)
	frame.Weapon = weapon

	local shield = frame:CreateTexture()
	shield:SetSize(25,31)
	shield:SetPoint("LEFT", wrists, "RIGHT", 0,10)
	shield:SetDrawLayer("BACKGROUND", 0)
	shield:SetTexCoord(.1875, .375, .3203125, .5546875)
	frame.Shield = shield

	local offHand = frame:CreateTexture()
	offHand:SetSize(20,45)
	offHand:SetPoint("LEFT", wrists, "RIGHT", 0,-6)
	offHand:SetDrawLayer("BACKGROUND", 0)
	offHand:SetTexCoord(0, .140625, .3203125, .6640625)
	frame.OffHand = offHand

	local ranged = frame:CreateTexture()
	ranged:SetSize(28,38)
	ranged:SetPoint("TOP", shield, "BOTTOM", 0,5)
	ranged:SetDrawLayer("BACKGROUND", 0)
	ranged:SetTexCoord(.1875, .3984375, .5546875, .84375)
	frame.Ranged = ranged

	local path = [[Interface\Durability\UI-Durability-Icons]]
	frame.Head:SetTexture(path)
	frame.Shoulders:SetTexture(path)
	frame.Chest:SetTexture(path)
	frame.Wrists:SetTexture(path)
	frame.Hands:SetTexture(path)
	frame.Waist:SetTexture(path)
	frame.Legs:SetTexture(path)
	frame.Feet:SetTexture(path)
	frame.Weapon:SetTexture(path)
	frame.Shield:SetTexture(path)
	frame.OffHand:SetTexture(path)
	frame.Ranged:SetTexture(path)

	self.frame = frame
end

Durability.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(DURABILITY)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.25, 2.5, .05)
	anchor:SetSize(60 + 20 + 14, 75)
	anchor:SetPoint(unpack(defaults.profile.savedPosition[MFM:GetDefaultLayout()]))
	anchor:SetScale(defaults.profile.savedPosition[MFM:GetDefaultLayout()].scale)
	anchor:SetDefaultScale(ns.API.GetEffectiveScale)
	anchor.PreUpdate = function() self:UpdateAnchor() end
	anchor.UpdateDefaults = function() self:UpdateDefaults() end

	self.anchor = anchor
end

Durability.UpdateDefaults = function(self)
	if (not self.anchor or not self.db) then return end

	local defaults = self.db.defaults.profile.savedPosition[MFM:GetDefaultLayout()]
	if (not defaults) then return end

	defaults.scale = self.anchor:GetDefaultScale()
	defaults[1], defaults[2], defaults[3] = self.anchor:GetDefaultPosition()
end

Durability.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]

	self.frame:SetScale(config.scale)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
end

Durability.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition[MFM:GetLayout()]
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

Durability.UpdateWidget = function(self, forced)
	if (not self.frame) then return end

	local frame = self.frame

	local numAlerts = 0
	local texture, showDurability
	local hasLeft, hasRight

	for index,value in pairs(inventorySlots) do
		texture = frame[value.slot]
		if (value.slot == "Shield") then
			if (C_PaperDollInfo.OffhandHasWeapon()) then
				frame.Shield:Hide()
				texture = frame.OffHand
			else
				frame.OffHand:Hide()
				texture = frame.Shield
			end
		end

		local alert = GetInventoryAlertStatus(index)
		local color = alert and inventoryColors[alert]
		if (forced and not color) then
			color = inventoryColors.default
		end
		if (color) then
			texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
			if (value.showSeparate) then
				if ((value.slot == "Shield") or (value.slot == "Ranged")) then
					hasRight = true
				elseif (value.slot == "Weapon") then
					hasLeft = true
				end
				texture:Show()
			else
				showDurability = 1
			end
			numAlerts = numAlerts + 1
		else
			texture:SetVertexColor(unpack(inventoryColors.default))
			if (value.showSeparate) then
				texture:Hide()
			end
		end
	end

	for index, value in pairs(inventorySlots) do
		if (not value.showSeparate) then
			local texture = frame[value.slot]
			if (showDurability) then
				frame[value.slot]:Show()
			else
				frame[value.slot]:Hide()
			end
		end
	end

	local width = 58
	if (hasRight) then
		frame.Head:SetPoint("TOPRIGHT", -40, 0)
		width = width + 20
	else
		frame.Head:SetPoint("TOPRIGHT", -20, 0)
	end
	if (hasLeft) then
		width = width + 14
	end
	frame:SetWidth(width)

	if (numAlerts > 0) or (forced) then
		frame:Show()
	else
		frame:Hide()
	end

end

Durability.OnEvent = function(self, event, ...)
	if (event == "UPDATE_INVENTORY_ALERTS") then
		self:UpdateWidget()

	elseif (event == "PLAYER_ENTERING_WORLD") then
		self.incombat = nil
		self:UpdateWidget()
		self:UpdatePositionAndScale()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_LayoutsUpdated") then
		local LAYOUT = ...

		if (not self.db.profile.savedPosition[LAYOUT]) then
			self.db.profile.savedPosition[LAYOUT] = ns:Merge({}, defaults.profile.savedPosition[MFM:GetDefaultLayout()])
		end

		self:UpdatePositionAndScale()
		self:UpdateAnchor()

	elseif (event == "MFM_LayoutDeleted") then
		local LAYOUT = ...

		self.db.profile.savedPosition[LAYOUT] = nil

	elseif (event == "MFM_PositionUpdated") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT][1] = point
		self.db.profile.savedPosition[LAYOUT][2] = x
		self.db.profile.savedPosition[LAYOUT][3] = y

		self:UpdatePositionAndScale()

	elseif (event == "MFM_AnchorShown") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

	elseif (event == "MFM_ScaleUpdated") then
		local LAYOUT, anchor, scale = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT].scale = scale
		self:UpdatePositionAndScale()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			if (select(2, ...) ~= self.anchor) then return end

			self:OnEvent("MFM_PositionUpdated", ...)
		end
	end
end

Durability.OnInitialize = function(self)

	self.db = ns.db:RegisterNamespace("Durability", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	MFM:RegisterPresets(self.db.profile.savedPosition)

	self:InitializeDurabilityFrame()
	self:InitializeMovableFrameAnchor()
end

Durability.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS", "OnEvent")

	ns.RegisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
	ns.RegisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnEvent")
end
