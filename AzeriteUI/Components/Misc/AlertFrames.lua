--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local AlertFrames = ns:NewModule("AlertFrames", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: CreateFrame
-- GLOBALS: AlertFrame, GroupLootContainer, UIParent, TalkingHeadFrame
-- GLOBALS: UIPARENT_MANAGED_FRAME_POSITIONS

-- Lua API
local ipairs = ipairs
local table_remove = table.remove
local unpack = unpack

local points = {
	TOP = { "TOP", "BOTTOM", 0, -1 },
	TOPLEFT = { "TOP", "BOTTOM", 0, -1 },
	TOPRIGHT = { "TOP", "BOTTOM", 0, -1 },
	CENTER = { "BOTTOM", "TOP", 0, 1 },
	LEFT = { "BOTTOM", "TOP", 0, 1 },
	RIGHT = { "BOTTOM", "TOP", 0, 1 },
	BOTTOM = { "BOTTOM", "TOP", 0, 1 },
	BOTTOMLEFT = { "BOTTOM", "TOP", 0, 1 },
	BOTTOMRIGHT = { "BOTTOM", "TOP", 0, 1 },
}

local defaults = { profile = ns:Merge({
	useAutomaticGrowth = true,
	growUpwards = false
}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
AlertFrames.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOP",
		[2] = 0 * ns.API.GetEffectiveScale(),
		[3] = -40 * ns.API.GetEffectiveScale()
	}
	return defaults
end

local GetPoints = function()
	if (AlertFrames.db.profile.useAutomaticGrowth) then
		return unpack(points[AlertFrames.db.profile.savedPosition[1]])
	else
		return unpack(AlertFrames.db.profile.growUpwards and points.BOTTOM or points.TOP)
	end
end

local GroupLootContainer_PostUpdate = function(self)
	local config = ns.GetConfig("AlertFrames")
	local point, relPoint, x, y = GetPoints()

	local lastIdx = nil
	for i = 1, self.maxIndex do
		local frame = self.rollFrames[i]
		local prevFrame = self.rollFrames[i-1]
		if (frame) then
			frame:ClearAllPoints()
			if (prevFrame and prevFrame ~= frame) then
				frame:SetPoint(point, prevFrame, relPoint, 0, config.AlertFramesPadding * y)
			else
				frame:SetPoint(point, self, point, 0, 0)
			end
			lastIdx = i
		end
	end
	if (lastIdx) then
		self:SetHeight(self.reservedSize * lastIdx)
		self:Show()
	else
		self:Hide()
	end
end

local AlertSubSystem_AdjustAnchors = function(self, relativeAlert)
	local config = ns.GetConfig("AlertFrames")
	local point, relPoint, x, y = GetPoints()

	local alertFrame = self.alertFrame
	if (alertFrame and alertFrame:IsShown()) then
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(point, relativeAlert, relPoint, 0, config.AlertFramesPadding * y)
		return alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustAnchorsNonAlert = function(self, relativeAlert)
	local config = ns.GetConfig("AlertFrames")
	local point, relPoint, x, y = GetPoints()

	local anchorFrame = self.anchorFrame

	if (anchorFrame and ns.WoW11 and anchorFrame == TalkingHeadFrame) then
		return relativeAlert
	end

	if (anchorFrame and anchorFrame:IsShown()) then
		anchorFrame:ClearAllPoints()
		anchorFrame:SetPoint(point, relativeAlert, relPoint, 0, config.AlertFramesPadding * y)
		return anchorFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustQueuedAnchors = function(self, relativeAlert)
	local config = ns.GetConfig("AlertFrames")
	local point, relPoint, x, y = GetPoints()

	for alertFrame in self.alertFramePool:EnumerateActive() do
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(point, relativeAlert, relPoint, 0, config.AlertFramesPadding * y)
		relativeAlert = alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustPosition = function(alertFrame, subSystem)
	if (subSystem.alertFramePool) then --queued alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustQueuedAnchors
	elseif (not subSystem.anchorFrame) then --simple alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchors
	elseif (subSystem.anchorFrame) then --anchor frame system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchorsNonAlert
	end
end

local AlertSubSystem_AdjustAllPositions = function()
	for index,alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		AlertSubSystem_AdjustPosition(AlertFrame, alertFrameSubSystem)
	end
end

local AlertFrame_PostUpdateAnchors = function()
	local config = ns.GetConfig("AlertFrames")
	local point, relPoint, x, y = GetPoints()

	local AlertFrameHolder = _G[ns.Prefix.."AlertFrameHolder"]

	AlertFrameHolder:ClearAllPoints()
	AlertFrameHolder:SetPoint(unpack(AlertFrames.db.profile.savedPosition))

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(AlertFrameHolder)

	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint(point, AlertFrameHolder, relPoint, 0, config.AlertFramesPadding * y)

	if (GroupLootContainer:IsShown()) then
		GroupLootContainer_PostUpdate(GroupLootContainer)
	end
end

AlertFrames.PostUpdatePositionAndScale = function(self)
	AlertFrame_PostUpdateAnchors()
	AlertSubSystem_AdjustAllPositions()
end

AlertFrames.PrepareFrames = function(self)

	local config = ns.GetConfig("AlertFrames")

	local frame = CreateFrame("Frame", ns.Prefix.."AlertFrameHolder", UIParent)
	frame:SetSize(unpack(config.AlertFramesSize))
	frame:SetPoint(unpack(AlertFrames.db.profile.savedPosition))

	self.frame = frame

	--if (not ns.IsRetail) then
	--	AlertFrame.ignoreFramePositionManager = true
	--	AlertFrame:SetParent(UIParent)
	--	AlertFrame:OnLoad()
	--end
	--AlertSubSystem_AdjustAllPositions()

	GroupLootContainer.ignoreFramePositionManager = true

	if (not ns.IsRetail) then
		UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil
	end

	self:SecureHook(AlertFrame, "AddAlertFrameSubSystem", AlertSubSystem_AdjustPosition)
	self:SecureHook(AlertFrame, "UpdateAnchors", AlertFrame_PostUpdateAnchors)
	self:SecureHook("GroupLootContainer_Update", GroupLootContainer_PostUpdate)
end

AlertFrames.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(L["Alerts"])
	self.anchor:SetScalable(false)

	ns.MovableModulePrototype.OnEnable(self)
end
