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

local Info = ns:NewModule("Info", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0", "AceConsole-3.0")

-- GLOBALS: CreateFrame, GameTooltip, GameTooltip_SetDefaultAnchor, InCombatLockdown, IsResting, ToggleCalendar
-- GLOBALS: GetFramerate, GetLocalTime, GetMinimapZoneText, GetNetStats, GetServerTime, GetZonePVPInfo
-- GLOBALS: GetAddOnMemoryUsage, GetNumAddOns, GetAddOnInfo, UpdateAddOnMemoryUsage
-- GLOBALS: TIMEMANAGER_TITLE, TIMEMANAGER_TOOLTIP_TITLE, TUTORIAL_TITLE30, FPS_ABBR, HOME, WORLD, INFO
-- GLOBALS: TIMEMANAGER_TOOLTIP_LOCALTIME, TIMEMANAGER_TOOLTIP_REALMTIME, GAMETIME_TOOLTIP_TOGGLE_CALENDAR
-- GLOBALS: TOTAL_MEM_MB_ABBR, TOTAL_MEM_KB_ABBR, ADDON_MEM_MB_ABBR, ADDON_MEM_KB_ABBR

-- Lua API
local math_max = math.max
local math_min = math.min
local next = next
local string_format = string.format
local string_match = string.match
local string_upper = string.upper
local table_insert = table.insert
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetLocalTime = ns.API.GetLocalTime
local GetServerTime = ns.API.GetServerTime

-- WoW Strings
local L_RESTING = TUTORIAL_TITLE30 -- "Resting"
local L_FPS = string_upper(string_match(FPS_ABBR, "^.")) -- "fps"
local L_HOME = string_upper(string_match(HOME, "^.")) -- "Home"
local L_WORLD = string_upper(string_match(WORLD, "^.")) -- "World"

-- Constants
local NUM_ADDON_MEMORY = 5

local defaults = { profile = ns:Merge({
	enabled = true,

	enableLatency = true,
	enableFPS = true,
	enableZone = true,
	enableResting = true,

	useHalfClock = GetCurrentRegionName() == "US",
	useServerTime = false,

	hideInCombat = false,
	hideWhenResting = false,
	hideWhenMinimapIsHidden = true

}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Info.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOMRIGHT",
		[2] = -284 * ns.API.GetEffectiveScale(),
		[3] = 48 * ns.API.GetEffectiveScale()
	}
	return defaults
end

local getTimeStrings = function(h, m, suffix, useHalfClock, abbreviateSuffix)
	if (useHalfClock) then
		return "%.0f:%02.0f |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
	else
		return "%02.0f:%02.0f", h, m
	end
end

local Time_UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local useHalfClock = Info.db.profile.useHalfClock -- the outlandish 12 hour clock the colonials seem to favor so much
	local lh, lm, lsuffix = GetLocalTime(useHalfClock) -- local computer time
	local sh, sm, ssuffix = GetServerTime(useHalfClock) -- realm time
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, unpack(Colors.title))
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, lsuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ssuffix, useHalfClock)), rh, gh, bh, r, g, b)
	if (ToggleCalendar) then
		GameTooltip:AddLine("<"..GAMETIME_TOOLTIP_TOGGLE_CALENDAR..">", unpack(Colors.quest.green))
	end
	GameTooltip:Show()
end

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end

local Time_OnLeave = function(self)
	self.UpdateTooltip = nil
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_OnClick = function(self, mouseButton)
	if (ToggleCalendar) and (not InCombatLockdown()) then
		ToggleCalendar()
	end
end

local Fps_UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(L["AddOn Memory Usage"], unpack(Colors.title))

	for i = 1, NUM_ADDON_MEMORY, 1 do
		Info.addonUsage[i].value = 0
	end

	UpdateAddOnMemoryUsage()
	local totalMemory = 0

	for i = 1, GetNumAddOns(), 1 do
		local memUsage = GetAddOnMemoryUsage(i)
		totalMemory = totalMemory + memUsage

		for j = 1, NUM_ADDON_MEMORY, 1 do
			if (memUsage > Info.addonUsage[j].value) then
				for k = NUM_ADDON_MEMORY, 1, -1 do
					if (k == j) then
						Info.addonUsage[k].name = GetAddOnInfo(i)
						Info.addonUsage[k].value = memUsage
						break
					elseif (k ~= 1) then
						Info.addonUsage[k].name = Info.addonUsage[k - 1].name
						Info.addonUsage[k].value = Info.addonUsage[k - 1].value
					end
				end
				break
			end
		end
	end

	if (totalMemory > 0) then
		if (totalMemory > 1000) then
			totalMemory = totalMemory / 1000
			GameTooltip:AddLine(string_format(TOTAL_MEM_MB_ABBR, totalMemory), 1.0, 1.0, 1.0)
		else
			GameTooltip:AddLine(string_format(TOTAL_MEM_KB_ABBR, totalMemory), 1.0, 1.0, 1.0)
		end

		local size = 0
		for i = 1, NUM_ADDON_MEMORY, 1 do
			if (Info.addonUsage[i].value == 0) then
				break
			end

			size = Info.addonUsage[i].value

			if (size > 1000) then
				size = size / 1000
				GameTooltip:AddLine(string_format(ADDON_MEM_MB_ABBR, size, Info.addonUsage[i].name), 1.0, 1.0, 1.0)
			else
				GameTooltip:AddLine(string_format(ADDON_MEM_KB_ABBR, size, Info.addonUsage[i].name), 1.0, 1.0, 1.0)
			end
		end

		GameTooltip:Show()
	end
end

local Fps_OnEnter = function(self)
	self.UpdateTooltip = Fps_UpdateTooltip
	self:UpdateTooltip()
end

local Fps_OnLeave = function(self)
	self.UpdateTooltip = nil
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

Info.PrepareFrames = function(self)
	if (self.frame) then return end

	local db = ns.GetConfig("Info")

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(260, 37)
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(50)
	frame.elements = {}

	-- Zone Text
	local zoneName = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	zoneName:SetFontObject(db.ZoneTextFont)
	zoneName:SetAlpha(db.ZoneTextAlpha)
	zoneName:SetPoint(unpack(db.ZoneTextPosition))
	zoneName:SetJustifyH("CENTER")
	zoneName:SetJustifyV("MIDDLE")

	self.zoneName = zoneName

	-- Latency Text
	local latency = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	latency:SetFontObject(db.LatencyFont)
	latency:SetTextColor(unpack(db.LatencyColor))
	latency:SetPoint(unpack(db.LatencyPosition))
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("MIDDLE")

	self.latency = latency

	-- Framerate Text
	local fps = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	fps:SetFontObject(db.FrameRateFont)
	fps:SetTextColor(unpack(db.FrameRateColor))
	fps:SetPoint(unpack(db.FrameRatePosition))
	fps:SetJustifyH("CENTER")
	fps:SetJustifyV("MIDDLE")
	fps:SetScript("OnEnter", Fps_OnEnter)
	fps:SetScript("OnLeave", Fps_OnLeave)

	self.fps = fps

	-- Resting Text
	local resting = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	resting:SetFontObject(db.ZoneTextFont)
	resting:SetPoint("RIGHT", self.zoneName, "LEFT", -4, 0)
	resting:SetJustifyH("CENTER")
	resting:SetJustifyV("MIDDLE")
	resting:SetTextColor(unpack(db.ClockColor))
	resting:SetText("|cff888888(|r"..L_RESTING.."|cff888888)|r")

	self.resting = resting

	-- Time Text
	local time = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	time:SetJustifyH("CENTER")
	time:SetJustifyV("MIDDLE")
	time:SetFontObject(db.ClockFont)
	time:SetTextColor(unpack(db.ClockColor))
	time:SetPoint(unpack(db.ClockPosition))

	-- Clickable Time Frame
	local timeFrame = CreateFrame("Button", nil, frame)
	timeFrame:SetScript("OnEnter", Time_OnEnter)
	timeFrame:SetScript("OnLeave", Time_OnLeave)
	timeFrame:SetScript("OnClick", Time_OnClick)
	timeFrame:RegisterForClicks("AnyUp")
	timeFrame:SetAllPoints(time)

	self.time = time

	self.frame = frame
end

Info.UpdateClock = function(self)
	local time = self.time
	if (not time) then return end

	local db = ns.GetConfig("Info")

	if (self.db.profile.useServerTime) then
		if (self.db.profile.useHalfClock) then
			time:SetFormattedText("%.0f:%02.0f |cff888888%s|r", GetServerTime(true))

			if (not time.useHalfClock) then
				time.useHalfClock = true
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPositionHalfClock))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPositionHalfClock))
			end
		else
			time:SetFormattedText("%02.0f:%02.0f", GetServerTime(false))

			if (time.useHalfClock) then
				time.useHalfClock = nil
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPosition))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPosition))
			end
		end
	else
		if (self.db.profile.useHalfClock) then
			time:SetFormattedText("%.0f:%02.0f |cff888888%s|r", GetLocalTime(true))

			if (not time.useHalfClock) then
				time.useHalfClock = true
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPositionHalfClock))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPositionHalfClock))
			end

		else
			time:SetFormattedText("%02.0f:%02.0f", GetLocalTime(false))

			if (time.useHalfClock) then
				time.useHalfClock = nil
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPosition))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPosition))
			end
		end
	end
end

Info.UpdatePerformance = function(self)

	local fps = GetFramerate()
	local _, _, home, world = GetNetStats()

	if (fps and fps > 0) then
		self.fps:SetFormattedText("|cff888888%.0f %s|r", fps, L_FPS)
	else
		self.fps:SetText("")
	end

	if (home and home > 0 and world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f - |cff888888%s|r %.0f", L_HOME, home, L_WORLD, world)
	elseif (world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f", L_WORLD, world)
	elseif (home and home > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f", L_HOME, home)
	else
		self.latency:SetText("")
	end

end

Info.UpdateResting = function(self)
	local resting = self.resting
	if (not resting) then
		return
	end
	if (IsResting()) then
		resting:Show()
	else
		resting:Hide()
	end
end

Info.UpdateTimers = function(self)

	if (not self.performanceTimer) then
		self.performanceTimer = self:ScheduleRepeatingTimer("UpdatePerformance", 1)
		self:UpdatePerformance()
	end

	if (not self.clockTimer) then
		self.clockTimer = self:ScheduleRepeatingTimer("UpdateClock", 1)
		self:UpdateClock()
	end
end

Info.UpdateZone = function(self)
	local zoneName = self.zoneName
	if (not zoneName) then
		return
	end
	local a = zoneName:GetAlpha() -- needed to preserve alpha after text color changes
	local minimapZoneName = GetMinimapZoneText()
	local pvpType = GetZonePVPInfo()
	if (pvpType) then
		local color = Colors.zone[pvpType]
		if (color) then
			zoneName:SetTextColor(color[1], color[2], color[3], a)
		else
			zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
		end
	else
		zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
	end
	zoneName:SetText(minimapZoneName)
end

Info.UpdateSettings = function(self)
	self:UpdateClock()
	self:UpdatePerformance()
	self:UpdateTimers()
	self:UpdateZone()
end

Info.OnEnable = function(self)
	self.addonUsage = {}

	for i = 1, NUM_ADDON_MEMORY, 1 do
		self.addonUsage[i] = {
			name = "",
			value = 0
		}
	end

	self:PrepareFrames()
	self:CreateAnchor(string_format("%s / %s", INFO, TIMEMANAGER_TITLE))

	ns.MovableModulePrototype.OnEnable(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateResting")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateResting")
	self:RegisterEvent("ZONE_CHANGED", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZone")

end

