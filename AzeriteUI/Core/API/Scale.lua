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
local API = ns.API or {}
ns.API = API

-- Lua API
local next = next
local tonumber = tonumber

-- WoW Objects
local UIParent = UIParent

-- Cache
local Scaled = {}
local ScaledToUIParent = {}

-- Global API
---------------------------------------------------------
-- Get the scale to set when ignoring parent scale
API.GetScale = function()
	return ns.UIScale
end

-- Return the default scale to set when ignoring parent scale
API.GetDefaultScale = function()
	return ns.UIDefaultScale
end

-- Returns the ideal scale for blizzard elements.
API.GetDefaultBlizzardScale = function(self)
	return ns.UIDefaultBlizzardScale
end

-- Returns the scale we should set our own elements to
-- for them to have a correct scale relative to the blizzard elements.
API.GetDefaultElementScale = function(self)
	return ns.API.GetDefaultScale()/ns.API.GetDefaultBlizzardScale()
end

-- Get the scale to use on custom elements when slaved to UIParent
-- in order for them to match the scale of custom elements ignoring the parent scale.
API.GetEffectiveScale = function()
	return API.GetScale() * 1/UIParent:GetScale()
end
