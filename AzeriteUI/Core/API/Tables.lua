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

local pairs, select, type = pairs, select, type

-- Global API
---------------------------------------------------------
-- Deep table merging without metatables.
-- *Fills in holes in target with values from source.
ns.Merge = function(self, target, source)
	if (type(target) ~= "table") then target = {} end
	for k,v in pairs(source) do
		if (type(v) == "table") then
			target[k] = ns:Merge(target[k], v)
		elseif (target[k] == nil) then
			target[k] = v
		end
	end
	return target
end

-- Deep table copy without metatables.
ns.Copy = function(self, target, source)
	if (not source) then
		source = target
		target = {}
	end
	for k,v in pairs(source) do
		if (type(v) == "table") then
			target[k] = ns:Copy(v)
		else
			target[k] = v
		end
	end
	return target
end

-- Purges given keys from a table
ns.PurgeKeys = function(self, target, ...)
	for k,v in pairs(target) do
		local shouldPurge
		for i = 1,select("#", ...) do
			local unwantedKeys = select(i, ...)
			if (unwantedKeys == k) then
				shouldPurge = true
				break
			end
		end
		if (shouldPurge) then
			target[k] = nil
		else
			-- Iterate subtables for keys to purge.
			if (type(v) == "table") then
				target[k] = ns:PurgeKeys(target[k], ...)
			end
		end
	end
end

-- Purges keys not given from a table
ns.PurgeOtherKeys = function(self, target, ...)
	for k,v in pairs(target) do
		-- Leave table structure intact, always.
		if (type(v) == "table") then
			target[k] = ns:PurgeKeys(target[k], ...)
		else
			-- Assume anything not a table
			-- should be purged until proven otherwise.
			local shouldPurge = true
			for i = 1,select("#", ...) do
				local wantedKeys = select(i, ...)
				if (wantedKeys == k) then
					shouldPurge = nil
					break
				end
			end
			if (shouldPurge) then
				target[k] = nil
			end
		end
	end
end
