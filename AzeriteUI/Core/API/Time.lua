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
local API = ns.API or {}
ns.API = API

-- Lua API
local _G = _G
local date = date
local time = time
local tonumber = tonumber

-- GLOBALS: TIMEMANAGER_AM, TIMEMANAGER_PM

-- Converts dates to time since epoch and compares.
local dateInRange = function(day1, month1, year1, day2, month2, year2)
	local now = time()
	local first = time({year=year1, month=month1, day=day1, hour=0, min=0, sec=0})
	local last = time({year=year2, month=month2, day=day2, hour=23, min=59, sec=59})
	return now >= first and now <= last
end

-- Calculates standard hours from a give 24-hour time
-- Keep this systematic to the point of moronic, or I'll mess it up again.
local ComputeStandardHours = function(hour)
	if (hour == 0) then return 12, TIMEMANAGER_AM -- 0 is 12 AM
	elseif (hour > 0) and (hour < 12) then return hour, TIMEMANAGER_AM -- 01-11 is 01-11 AM
	elseif (hour == 12) then return 12, TIMEMANAGER_PM -- 12 is 12 PM
	elseif (hour > 12) then return hour - 12, TIMEMANAGER_PM -- 13-24 is 01-12 PM
	end
end

-- Calculates military time, but assumes the given time is standard (12 hour)
local ComputeMilitaryHours = function(hour, am)
	if (am and hour == 12) then
		return 0
	elseif (not am and hour < 12) then
		return hour + 12
	else
		return hour
	end
end

-- Retrieve the local client computer time
local GetLocalTime = function(useStandardTime)
	local hour, minute = tonumber(date("%H")), tonumber(date("%M"))
	if useStandardTime then
		local hour, suffix = ComputeStandardHours(hour)
		return hour, minute, suffix
	else
		return hour, minute
	end
end

-- Retrieve the server time
local GetServerTime = function(useStandardTime)
	local hour, minute = GetGameTime()
	if useStandardTime then
		local hour, suffix = ComputeStandardHours(hour)
		return hour, minute, suffix
	else
		return hour, minute
	end
end

local GetTime = function(useStandardTime, useServerTime)
    if (useServerTime) then
        return GetServerTime(useStandardTime)
    else
        return GetLocalTime(useStandardTime)
    end
end

-- Update for Winter Veil 2023-2024
local IsWinterVeil = function()
	local year = tonumber(date("%Y"))
	return dateInRange(16,12,2023,2,1,2024) or dateInRange(16,12,year-1,2,1,year) or dateInRange(16,12,year,2,1,year+1)
end

-- Updated for Love is in the Air 2024
local IsLoveFestival = function()
	local year = tonumber(date("%Y"))
	return dateInRange(5,2,2024,19,2,2024) or dateInRange(5,2,year,25,2,year)
end

-- Global API
---------------------------------------------------------
API.ComputeMilitaryHours = ComputeMilitaryHours
API.ComputeStandardHours = ComputeStandardHours
API.GetTime = GetTime
API.GetLocalTime = GetLocalTime
API.GetServerTime = GetServerTime
API.IsWinterVeil = IsWinterVeil
API.IsLoveFestival = IsLoveFestival
