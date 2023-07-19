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

--if (not ns.WoW10) then return end

local MirrorTimers = ns:NewModule("MirrorTimers", ns.Module, "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0")

local LibSmoothBar = LibStub("LibSmoothBar-1.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local next = next
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local unpack = unpack

local defaults = { profile = ns:Merge({
	growUpwards = false
}, ns.Module.defaults) }

MirrorTimers.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOP",
		[2] = 0 ,
		[3] = -230 * ns.API.GetEffectiveScale()
	}
	return defaults
end

MirrorTimers.PrepareFrames = function(self)
	if (self.frame) then return end

	if (ns.WoW10) then
		MirrorTimerContainer.HighlightSystem = ns.Noop
		MirrorTimerContainer.ClearHighlight = ns.Noop
		MirrorTimerContainer:UnregisterAllEvents()
		MirrorTimerContainer:SetParent(ns.Hider)
		MirrorTimerContainer:Hide()
	else
		MirrorTimerFrame:UnregisterAllEvents()
		MirrorTimerFrame:SetParent(ns.Hider)
		MirrorTimerFrame:Hide()
		UIParent:UnregisterEvent("MIRROR_TIMER_START")
	end

	local config = ns.GetConfig("MirrorTimers")

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(unpack(config.MirrorTimerTimerSize))

	self.frame = frame
end

MirrorTimers.CreateTimer = function(self, ...)
	local config = ns.GetConfig("MirrorTimers")

	local timer = LibSmoothBar:CreateSmoothBar(nil, self.frame, ...)
	timer:SetSize(unpack(config.MirrorTimerBarSize))
	timer:SetStatusBarTexture(config.MirrorTimerBarTexture)
	timer:SetStatusBarColor(unpack(config.MirrorTimerBarColor))
	timer.elapsed = 0

	local backdrop = timer:CreateTexture(nil, "BACKGROUND", nil, -6)
	backdrop:SetSize(unpack(config.MirrorTimerBackdropSize))
	backdrop:SetPoint(unpack(config.MirrorTimerBackdropPosition))
	backdrop:SetTexture(config.MirrorTimerBackdropTexture)
	backdrop:SetVertexColor(unpack(config.MirrorTimerBackdropColor))
	timer.backdrop = backdrop

	local label = timer:CreateFontString(nil, "OVERLAY", nil, 6)
	label:SetFontObject(config.MirrorTimerLabelFont)
	label:SetPoint(unpack(config.MirrorTimerLabelPosition))
	label:SetTextColor(unpack(config.MirrorTimerLabelColor))
	timer.label = label

	timer:SetScript("OnUpdate", function(self, elapsed)
		if (self.paused) then return end

		self.elapsed = self.elapsed + elapsed
		if (self.elapsed < .05) then return end

		self:SetValue(GetMirrorTimerProgress(self.timer)/1000)
		self.elapsed = 0
	end)

	return timer
end

MirrorTimers.GetActiveTimer = function(self, timer)
	return self.activeTimers[timer]
end

MirrorTimers.GetAvailableTimer = function(self, timer)
	local timerFrame = self:GetActiveTimer(timer)
	if (timerFrame) then
		return timerFrame
	end

	if (next(self.availableTimers)) then
		return table_remove(self.availableTimers)
	end

	return self:CreateTimer()
end

MirrorTimers.SetupTimer = function(self, timer, value, maxvalue, paused, label)
	local timerFrame = self:GetAvailableTimer(timer)
	if (not timerFrame) then return end

	timerFrame:SetMinMaxValues(0, maxvalue/1000, true)
	timerFrame:SetValue(value/1000, true)
	timerFrame.label:SetText(label)
	timerFrame.paused = paused > 0
	timerFrame.timer = timer

	if (not self.activeTimers[timer]) then
		self.activeTimersIndexed[#self.activeTimersIndexed + 1] = timer
	end

	self.activeTimers[timer] = timerFrame

	if (not timerFrame:IsShown()) then
		timerFrame:Show()
	end

	self:UpdateLayout()
end

MirrorTimers.ClearTimer = function(self, timer)
	local timerFrame = self:GetActiveTimer(timer)
	if (not timerFrame) then return end

	timerFrame:Hide()
	timerFrame:SetMinMaxValues(0,1,true)
	timerFrame:SetValue(1,true)
	timerFrame.label:SetText("")
	timerFrame.paused = nil
	timerFrame.timer = nil

	for i,timerID in next,self.activeTimersIndexed do
		if (timerID == timer) then
			self.activeTimersIndexed[i] = nil
			break
		end
	end

	self.activeTimers[timer] = nil
	table_insert(self.availableTimers, timerFrame)

	self:UpdateLayout()
end

MirrorTimers.PauseTimer = function(self, timer, paused)
	local timerFrame = self:GetActiveTimer(timer)
	if (not timerFrame) then return end

	timerFrame.paused = paused > 0
end

MirrorTimers.UpdateTimers = function(self)
	for i = 1,3 do
		local timer, value, maxvalue, _, paused, label = GetMirrorTimerInfo(i)
		if (timer ~= "UNKNOWN") then
			self:SetupTimer(timer, value, maxvalue, paused, label)
		end
	end
end

MirrorTimers.UpdateLayout = function(self)
	local config = ns.GetConfig("MirrorTimers")

	local i,previous = 1,nil
	for _,timer in ipairs(self.activeTimersIndexed) do

		local timerFrame = self:GetActiveTimer(timer)
		if (timerFrame) then
			timerFrame:ClearAllPoints()

			if (previous) then
				if (self.db.profile.growUpwards) then
					timerFrame:SetPoint("BOTTOM", previous, "TOP", 0, config.MirrorTimerBarPadding)
				else
					timerFrame:SetPoint("TOP", previous, "BOTTOM", 0, -config.MirrorTimerBarPadding)
				end
			else
				timerFrame:SetPoint(unpack(config.MirrorTimerBarPosition))
			end

			previous = timerFrame
		end
	end
end

MirrorTimers.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UpdateTimers()

	elseif (event == "MIRROR_TIMER_START") then
		local timer, value, maxvalue, _, paused, label = ...

		self:SetupTimer(timer, value, maxvalue, paused, label)

	elseif (event == "MIRROR_TIMER_STOP") then
		local timer = ...

		self:ClearTimer(timer)

	elseif (event == "MIRROR_TIMER_PAUSE") then
		local timer, paused = ...

		local activeTimer =	self:GetActiveTimer(timer)
		if (activeTimer) then
			self:PauseTimer(activeTimer, paused)
		end
	end
end

MirrorTimers.OnEnable = function(self)

	self.availableTimers = {}
	self.activeTimers = {}
	self.activeTimersIndexed = {}

	self:PrepareFrames()
	self:CreateAnchor(string_format("%s / %s", BREATH_LABEL, EXHAUSTION_LABEL))

	ns.Module.OnEnable(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("MIRROR_TIMER_START", "OnEvent")
	self:RegisterEvent("MIRROR_TIMER_STOP", "OnEvent")
	self:RegisterEvent("MIRROR_TIMER_PAUSE", "OnEvent")
end
