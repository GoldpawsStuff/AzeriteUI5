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
local API = ns.API or {}
ns.API = API

-- Lua API
local math_ceil = math.ceil
local math_floor = math.floor
local string_format = string.format
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_match = string.match
local string_utf8lower = string.utf8lower
local string_utf8sub = string.utf8sub
local tonumber = tonumber

-- Constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- String Abbreviations
-----------------------------------------------
local AbbreviateName = function(name)
	local letters, lastWord = "", string_match(name, ".+%s(.+)$")
	if lastWord then
		for word in string_gmatch(name, ".-%s") do
			local firstLetter = string_utf8sub(string_gsub(word, "^[%s%p]*", ""), 1, 1)
			if firstLetter ~= string_utf8lower(firstLetter) then
				letters = string_format("%s%s. ", letters, firstLetter)
			end
		end
		name = string_format("%s%s", letters, lastWord)
	end
	return name
end

-- Number Abbreviations
-----------------------------------------------
-- Shorten as much as possible.
local AbbreviateNumber = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then							return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e6) then 						return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e3) or (value <= -1e3) then 	return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	elseif (value > 0) then							return ""..math_floor(value)
	else 											return ""
	end	
end

-- Aim at filling 3-5 digits or letters.
local AbbreviateNumberBalanced = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e8) then 		return string_format("%.0fm", value/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (value >= 1e6) then 	return string_format("%.1fm", value/1e6) 	-- 1.0m - 99.9m 
	elseif (value >= 1e5) then 	return string_format("%.0fk", value/1e3) 	-- 100k - 999k
	elseif (value >= 1e3) then 	return string_format("%.1fk", value/1e3) 	-- 1.0k - 99.9k
	elseif (value > 0) then 	return ""..math_floor(value)				-- 1 - 999
	else 						return ""
	end 
end 

-- Time Abbreviations
-----------------------------------------------
-- Returns a format string and input values 
local AbbreviateTime = function(secs)
	if (secs > DAY) then -- more than a day
		return "%.0f%s", math_ceil(secs / DAY), "d"
	elseif (secs > HOUR) then -- more than an hour
		return "%.0f%s", math_ceil(secs / HOUR), "h"
	elseif (secs > MINUTE) then -- more than a minute
		return "%.0f%s", math_ceil(secs / MINUTE), "m"
	elseif (secs > 5) then 
		return "%.0f", math_ceil(secs)
	elseif (secs > .9) then 
		return "|cffff8800%.0f|r", math_ceil(secs)
	elseif (secs > .05) then
		return "|cffff0000%.0f|r", secs*10 - secs*10%1
	else
		return ""
	end	
end

-- zhCN Exceptions
-----------------------------------------------
if (GetLocale() == "zhCN") then
	AbbreviateNumber = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then							return ("%.2f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif (value >= 1e4) or (value <= -1e3) then	return ("%.2f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		elseif (value > 0) then 						return ""..math_floor(value)
		else 											return ""
		end 
	end

	AbbreviateNumberBalanced = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then 							return string_format("%.2f亿", value/1e8)
		elseif (value >= 1e4) then 						return string_format("%.2f万", value/1e4)
		elseif (value > 0) then 						return ""..math_floor(value)
		else 											return ""
		end 
	end
end 

-- Global API
---------------------------------------------------------
API.AbbreviateName = AbbreviateName
API.AbbreviateNumber = AbbreviateNumber
API.AbbreviateNumberBalanced = AbbreviateNumberBalanced
API.AbbreviateTime = AbbreviateTime
