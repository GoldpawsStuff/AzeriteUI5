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
local MAJOR_VERSION = "LibMoreEvents-1.0"
local MINOR_VERSION = 4

if (not LibStub) then
	error(MAJOR_VERSION .. " requires LibStub.")
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

-- Lua API
local assert = assert
local next = next
local pairs = pairs
local pcall = pcall
local rawset = rawset
local setmetatable = setmetatable
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local type = type
local xpcall = xpcall

-- Library registries
lib.embeds = lib.embeds or {}
lib.frame = lib.frame or CreateFrame("Frame")
lib.validator = lib.validator or CreateFrame("Frame")

-- Private API
local frame = lib.frame
local validator = lib.validator

-- Frame Methods
local registerEvent = frame.RegisterEvent
local registerUnitEvent = frame.RegisterUnitEvent
local unregisterEvent = frame.UnregisterEvent
local isEventRegistered = frame.IsEventRegistered

-- Event Handling
--------------------------------------------------
-- Fire the events for a single module.
-- This is a table mimicking a function,
-- and will be called by the metatable below.
-- events[event][module](event, ...)
local fire_mt = {
	__call = function(funcs, module, event, ...)
		for _,func in next,funcs do
			if (type(func) == "string") then
				module[func](module, event, ...)
			else
				func(module, event, ...)
			end
		end
	end
}

-- Fire an event to all registered modules.
-- events[event](...)
local events_mt = {
	__call = function(modules, event, ...)
		for module,funcs in next,modules do
			 -- funcs can be a function, a method name, or a table of those.
			if (type(funcs) == "string") then
				module[funcs](module, event, ...)
			else
				-- This applies to both functions and tables.
				-- our tables mimicks functions,
				-- using the fire_mt meta above.
				funcs(module, event, ...)
			end
		end
	end
}

-- Event registry.
-- events[event][module] = { func, func, ... }
local events = setmetatable({}, {
	__index = function(t,k)
		local new = setmetatable({}, events_mt)
		rawset(t,k,new)
		return new
	end
})

-- Invoke the __call metamethod of the event registry,
-- which in turn iterates all modules and fires its methods.
local onEvent = function(_, event, ...)
	return events[event](event, ...)
end

-- Error Handling
--------------------------------------------------
local error = function(...)
	local message, level = ...
	if (message) then
		print("|cffff0000"..message.."|r")
	end
end

local _xpcall = function(func, ...)
	return xpcall(func, error, ...)
end

-- Validation
--------------------------------------------------
local validateEvent = function(event)
	local isOK = _xpcall(validator.RegisterEvent, validator, event)
	if (isOK) then
		validator:UnregisterEvent(event)
	end
	return isOK
end

local validateUnit = function(unit)
	local isOK, _ = pcall(validator.RegisterUnitEvent, validator, "UNIT_HEALTH", unit)
	if (isOK) then
		_, unit = validator:IsEventRegistered("UNIT_HEALTH")
		validator:UnregisterEvent("UNIT_HEALTH")
		return not not unit
	end
end

local isUnitEvent = function(event, unit)
	local isOK = pcall(validator.RegisterUnitEvent, validator, event, unit)
	if (isOK) then
		validator:UnregisterEvent(event)
	end
	return isOK
end

-- Public API
--------------------------------------------------
--[[ RegisterEvent(self, event, callback)
Used to register a module for a game event and add an event handler.

* self      - module that will be registered for the given event.
* event     - name of the event to register (string)
* callback  - function or method that will be executed when the event fires.
	          Multiple functions or methods can be added for
			  the same module and event (function,string)
--]]
lib.RegisterEvent = function(self, event, callback)
	local curev = events[event][self]
	if (curev) then
		local kind = type(curev)
		if ((kind == "function" or kind == "string") and (curev ~= callback)) then
			events[event][self] = setmetatable({ curev, callback }, fire_mt)

		elseif (kind == "table") then
			for _, infunc in next, curev do
				if (infunc == callback) then
					return
				end
			end
			table_insert(curev, callback)
		end
		registerEvent(frame, event)

	elseif (validateEvent(event)) then
		events[event][self] = callback

		if (not frame:GetScript("OnEvent")) then
			frame:SetScript("OnEvent", onEvent)
		end
		registerEvent(frame, event)

	end
end

--[[ RegisterUnitEvent(self, event, callback, unit1, unit2)
Used to register a module for a game unit event and add an event handler.

A frame can only ever watch for events for two units using this mechanism. Repeated calls will overwrite old registrations.

You must unregister the event in order to switch to or from an Frame:RegisterEvent registration for the same event. Otherwise, the RegisterEvent call is silently ignored, and the filters remain in effect.

* self      - module that will be registered for the given event.
* event     - name of the event to register (string)
* callback  - function or method that will be executed when the event fires.
	          Multiple functions or methods can be added for
			  the same module and event (function,string)
* unit1     - unitID to deliver the event for (string)
* unit2     - second unitID to deliver the event for (string,nil)
--]]
lib.RegisterUnitEvent = function(self, event, callback, unit1, unit2)
	local curev = events[event][self]
	if (curev) then
		local kind = type(curev)
		if ((kind == "function" or kind == "string") and (curev ~= callback)) then
			events[event][self] = setmetatable({ curev, callback }, fire_mt)

		elseif (kind == "table") then
			for _, infunc in next, curev do
				if (infunc == callback) then
					return
				end
			end
			table_insert(curev, callback)
		end
		registerUnitEvent(frame, event, unit1, unit2)

	elseif (validateEvent(event)) then
		events[event][self] = callback

		if (not frame:GetScript("OnEvent")) then
			frame:SetScript("OnEvent", onEvent)
		end
		if (unit1 and validateUnit(unit1)) then

			assert(isUnitEvent(event, unit1), string_format("Event \"%s\" is not an unit event", event))
			registerUnitEvent(frame, event, unit1, unit2)
		end

	end
end

--[[ UnregisterEvent(self, event, func)
Used to remove a function from the event handler list for a game event.

* self      - the module registered for the event
* event     - name of the registered event (string)
* callback  - function or method to be removed from the list of event handlers.
	          If this is the only handler for the given event, then
              the frame will be unregistered for the event (function,string)
--]]
lib.UnregisterEvent = function(self, event, callback)
	local cleanUp = false
	local curev = events[event][self]
	-- We have multiple event registrations on the module,
	-- so iterate them all and remove only the current.
	if ((type(curev) == "table") and (callback)) then
		for k,infunc in next,curev do
			if (infunc == callback) then
				curev[k] = nil
				break
			end
		end
		-- This module has no more entries for this event,
		-- so schedule a cleanup down below to see if
		-- the event listener is still needed.
		if (not next(curev)) then
			cleanUp = true
		end
	end
	if ((cleanUp) or (curev == callback)) then
		-- Clear the event entry for this module.
		events[event][self] = nil
		-- Kill the event listener if no more modules
		-- has registered for it.
		if (not next(events[event])) then
			unregisterEvent(frame, event)
		end
	end
end

local mixins = {
	RegisterEvent = true,
	RegisterUnitEvent = true,
	UnregisterEvent = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
