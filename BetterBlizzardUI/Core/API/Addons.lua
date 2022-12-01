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

local PLAYER_NAME = UnitName("player")

local GetAddOnInfo = function(index)
	local name, title, notes, loadable, reason, security, newVersion = _G.GetAddOnInfo(index)
	local enabled = not(_G.GetAddOnEnableState(PLAYER_NAME, index) == 0) 
	return name, title, notes, enabled, loadable, reason, security
end

-- Check if an addon exists	in the addon listing
local IsAddOnAvailable = function(target)
	local target = string.lower(target)
	for i = 1,_G.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string.lower(name) == target) then
			return true
		end
	end
end

-- Check if an addon is enabled	in the addon listing
-- *Making this available as a generic library method.
local IsAddOnEnabled = function(target)
	local target = string.lower(target)
	for i = 1,_G.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string.lower(name) == target) then
			if (enabled and loadable) then
				return true
			end
		end
	end
end

-- Check if an addon exists in the addon listing and loadable on demand
local IsAddOnLoadable = function(target, ignoreLoD)
	local target = string.lower(target)
	for i = 1,_G.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string_lower(name) == target) then
			if (loadable or ignoreLoD) then
				return true
			end
		end
	end
end

-- Global API
---------------------------------------------------------
API.GetAddOnInfo = GetAddOnInfo
API.IsAddOnLoadable = IsAddOnLoadable
API.IsAddOnEnabled = IsAddOnEnabled
API.IsAddOnAvailable = IsAddOnAvailable
