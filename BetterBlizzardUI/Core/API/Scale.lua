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
local next = next
local tonumber = tonumber

-- WoW Objects
local UIParent = UIParent

-- Cache
local Scaled = {}
local ScaledToUIParent = {}

-- Scaling Functions
---------------------------------------------------------
-- Get the scale to set when ignoring parent scale
API.GetScale = function()
	return ns.UIScale
end

-- Return the default scale
API.GetDefaultScale = function()
	return ns.UIDefaultScale
end

-- Get the scale to use when slaved to UIParent
API.GetEffectiveScale = function()
	return API.GetScale() * 1/UIParent:GetScale()
end

-- Set the scale
API.SetScale = function(scale)
	ns.UIScale = tonumber(scale) or API.GetDefaultScale()
end

-- Set the scale as a factor of the default scale
API.SetRelativeScale = function(scale)
	ns.UIScale = (tonumber(scale) or 1) * API.GetDefaultScale()
end

-- Register an object to follow the main UIScale
-- *Optional second input is a scaling factor.
-- *Passes the input value as return value,
--  thus allowing method chaining.
API.SetObjectScale = function(object, factor)
	if (object and object.SetScale) then
		Scaled[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetScale() * (factor or 1))
	end
	return object
end

API.SetEffectiveObjectScale = function(object, factor)
	if (object and object.SetScale) then
		ScaledToUIParent[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetEffectiveScale() * (factor or 1))
	end
	return object
end

-- Updates the scale of all objects
-- registered with the above commands.
API.UpdateObjectScales = function()
	-- Update independent objects
	local scale = API.GetScale()
	for object, factor in next,Scaled do
		object:SetIgnoreParentScale(true)
		object:SetScale(scale * factor)
	end
	-- Update frames that can't ignore parent scales
	local effectiveScale = API.GetEffectiveScale()
	for object, factor in next,ScaledToUIParent do
		object:SetScale(effectiveScale * factor)
	end
end
