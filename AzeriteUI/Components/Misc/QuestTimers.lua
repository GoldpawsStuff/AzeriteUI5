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
local _, ns = ...

if (not ns.IsClassic or not QuestTimerFrame) then return end

local QuestTimers = ns:NewModule("QuestTimers", ns.MovableModulePrototype, "LibMoreEvents-1.0")

local defaults = { profile = ns:Merge({}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
QuestTimers.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = 0 ,
		[3] = 200 * ns.API.GetEffectiveScale()
	}
	return defaults
end

QuestTimers.PrepareFrames = function(self)
	if (self.frame) then return end

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(QuestTimerFrame:GetSize()) -- 158,72

	QuestTimerFrame:SetParent(UIParent)
	QuestTimerFrame:ClearAllPoints()
	QuestTimerFrame:SetPoint("TOP", frame)

	hooksecurefunc(QuestTimerFrame, "SetPoint", function(self, point, anchor, ...)
		if (anchor ~= frame) then
			self:ClearAllPoints()
			self:SetPoint("TOP", frame)
		end
	end)

	self.frame = frame
end

QuestTimers.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(QUEST_TIMERS)

	ns.MovableModulePrototype.OnEnable(self)
end
