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
local Widgets = ns.Private.Widgets or {}
ns.Private.Widgets = Widgets

-- Lua API
local pairs = pairs
local select = select

-- WoW API
local GetTime = GetTime
local hooksecurefunc = hooksecurefunc

-- Addon API
local AbbreviateTime = ns.API.AbbreviateTime

-- Local Caches
local Cooldowns, Active = {}, {}

-- Local Timer Frame
local Timer = CreateFrame("Frame"); Timer:Hide()
Timer:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = (self.elapsed or 0) - elapsed
	if (self.elapsed > 0) then
		return
	end
	self.elapsed = .01

	local timeLeft
	local now = GetTime()

	-- Parse and update the active cooldowns.
	for cooldown,info in next,Active do
		timeLeft = info.expiration - now

		-- Don't show bars and texts for cooldowns
		-- shorter than the global cooldown. Their spirals is enough.
		if (timeLeft > 0) and (info.duration > 1.5) then
			if (info.Bar) and (info.Bar:IsVisible()) then
				info.Bar:SetValue(timeLeft)
			end
			if (info.Time) then
				info.Time:SetFormattedText(AbbreviateTime(timeLeft))
			end
		else
			if (info.Bar) then
				info.Bar:Hide()
				info.Bar:SetMinMaxValues(0, 1, true)
				info.Bar:SetValue(1, true)
			end
			if (info.Time) then
				info.Time:SetText("")
			end
			Active[cooldown] = nil
		end
	end

	if (not next(Active)) then
		self:Hide()
	end
end)

-- Callbacks
---------------------------------------------------------
local AttachToCooldown = function(cooldown, ...)
	local info = Cooldowns[cooldown]
	if (not info) then
		return
	end
	for i,v in pairs({...}) do
		if (v) and (v.IsObjectType) and (v ~= cooldown) then
			if (not info.Bar) and (v:IsObjectType("StatusBar")) then
				info.Bar = v
			end
			if (not info.Time) and (v:IsObjectType("FontString")) then
				info.Time = v
			end
		end
	end
end

-- Virtual Cooldown Template
---------------------------------------------------------
-- This is meant as a way for bars and texts to
-- piggyback on the normal cooldown API,
-- without using a normal cooldown frame.
-- We're only adding methods we or our libraries use.
local Cooldown = {}
local Cooldown_MT = { __index = Cooldown }

Cooldown.SetCooldown = function(self, start, duration)
	local info = Cooldowns[self]
	info.start = start
	info.expiration = start + duration
	info.duration = duration
	info.shown = true

	local now = GetTime()
	local timeLeft = info.expiration - now

	if (info.Bar) then
		info.Bar:SetMinMaxValues(0, info.duration, true)
		info.Bar:SetValue(timeLeft, true)
	end
	if (info.Time) then
		info.Time:SetFormattedText(AbbreviateTime(timeLeft))
	end

	Active[self] = info

	if (not Timer:IsShown()) then
		Timer:Show()
	end
end

Cooldown.Clear = function(self)
	if (Active[self]) then
		local info = Cooldowns[self]
		info.start = 0
		info.expiration = 0
		info.duration = 0
	end
end

Cooldown.Show = function(self)
	local info = Cooldowns[self]
	if info.Bar then
		if (not info.Bar:IsShown()) then
			info.Bar:Show()
		end
	end
	info.shown = true
end

Cooldown.Hide = function(self)
	local info = Cooldowns[self]
	if info.Bar then
		info.Bar:Hide()
		info.Bar:SetMinMaxValues(0, 1, true)
		info.Bar:SetValue(1, true)
	end
	if info.Time then
		info.Time:SetText("")
	end
	info.shown = nil
	self:Clear()
end

Cooldown.IsShown = function(self)
	return self._isshown
end

Cooldown.IsObjectType = function(self, objectType)
	return objectType == "Cooldown"
end

-- Global API
---------------------------------------------------------
Widgets.RegisterCooldown = function(...)
	-- Check if an actual element is passed,
	-- and hook its relevant methods if so.
	local cooldown
	for i,v in pairs({...}) do
		if (v) and (v.IsObjectType) and (v:IsObjectType("Cooldown")) then
			cooldown = v
			break
		end
	end
	if (cooldown) then
		if (not Cooldowns[cooldown]) then
			Cooldowns[cooldown] = {}
			hooksecurefunc(cooldown, "SetCooldown", Cooldown.SetCooldown)
			hooksecurefunc(cooldown, "Clear", Cooldown.Clear)
			hooksecurefunc(cooldown, "Hide", Cooldown.Clear) -- not hide?
		end
		AttachToCooldown(cooldown, ...)
		return cooldown
	else
		-- Only subelements were passed,
		-- so we need a virtual cooldown element.
		local cooldown = setmetatable({}, Cooldown_MT)
		Cooldowns[cooldown] = { shown = nil }
		AttachToCooldown(cooldown, ...)
		return cooldown
	end
end
