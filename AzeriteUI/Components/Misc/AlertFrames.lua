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

if (ns.IsRetail) then return end

local AlertFrames = ns:NewModule("AlertFrames", "AceHook-3.0")

-- Lua API
local ipairs = ipairs
local table_remove = table.remove
local unpack = unpack

local GroupLootContainer_PostUpdate = function(self)
	local config = ns.GetConfig("AlertFrames")

	local lastIdx = nil
	for i = 1, self.maxIndex do
		local frame = self.rollFrames[i]
		local prevFrame = self.rollFrames[i-1]
		if (frame) then
			frame:ClearAllPoints()
			if (prevFrame and prevFrame ~= frame) then
				frame:SetPoint(config.AlertFramesPoint, prevFrame, config.AlertFramesRelativePoint, 0, config.AlertFramesOffsetY)
			else
				frame:SetPoint(config.AlertFramesPoint, self, config.AlertFramesPoint, 0, 0)
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

	local alertFrame = self.alertFrame
	if (alertFrame and alertFrame:IsShown()) then
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(config.AlertFramesPoint, relativeAlert, config.AlertFramesRelativePoint, 0, config.AlertFramesOffsetY)
		return alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustAnchorsNonAlert = function(self, relativeAlert)
	local config = ns.GetConfig("AlertFrames")

	local anchorFrame = self.anchorFrame
	if (anchorFrame and anchorFrame:IsShown()) then
		anchorFrame:ClearAllPoints()
		anchorFrame:SetPoint(config.AlertFramesPoint, relativeAlert, config.AlertFramesRelativePoint, 0, config.AlertFramesOffsetY)
		return anchorFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustQueuedAnchors = function(self, relativeAlert)
	local config = ns.GetConfig("AlertFrames")

	for alertFrame in self.alertFramePool:EnumerateActive() do
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(config.AlertFramesPoint, relativeAlert, config.AlertFramesRelativePoint, 0, config.AlertFramesOffsetY)
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

local AlertFrame_PostUpdateAnchors = function()
	local config = ns.GetConfig("AlertFrames")

	local AlertFrameHolder = _G[ns.Prefix.."AlertFrameHolder"]

	AlertFrameHolder:ClearAllPoints()
	AlertFrameHolder:SetPoint(unpack(config.AlertFramesPosition))

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(AlertFrameHolder)

	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint(config.AlertFramesPoint, AlertFrameHolder, config.AlertFramesRelativePoint, 0, config.AlertFramesOffsetY)

	if (GroupLootContainer:IsShown()) then
		GroupLootContainer_PostUpdate(GroupLootContainer)
	end
end

AlertFrames.OnInitialize = function(self)
	local config = ns.GetConfig("AlertFrames")

	local AlertFrameHolder = CreateFrame("Frame", ns.Prefix.."AlertFrameHolder", UIParent)
	AlertFrameHolder:SetPoint(unpack(config.AlertFramesPosition))
	AlertFrameHolder:SetSize(unpack(config.AlertFramesSize))

	AlertFrame.ignoreFramePositionManager = true
	AlertFrame:SetParent(UIParent)
	AlertFrame:OnLoad()

	for index,alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		AlertSubSystem_AdjustPosition(AlertFrame, alertFrameSubSystem)
	end

	GroupLootContainer.ignoreFramePositionManager = true

	UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil

	self:SecureHook(AlertFrame, "AddAlertFrameSubSystem", AlertSubSystem_AdjustPosition)
	self:SecureHook(AlertFrame, "UpdateAnchors", AlertFrame_PostUpdateAnchors)
	self:SecureHook("GroupLootContainer_Update", GroupLootContainer_PostUpdate)
end
