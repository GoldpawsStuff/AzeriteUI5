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

local defaults = {
	enabled = true
}

local Bar = CreateFrame("Frame")
local Bar_MT = { __index = Bar }

ns.Bar = {}
ns.Bar.prototype = Bar
ns.Bar.defaults = defaults

ns.Bar.Create = function(self, id, config, name)

	local bar = setmetatable(CreateFrame("Frame", name, UIParent, "SecureHandlerStateTemplate"), Bar_MT)
	bar.id = id
	bar.name = name or id
	bar.config = config or ns:Merge({}, defaults)

	return bar
end

Bar.Enable = function(self)
	if (InCombatLockdown()) then return end

	self.config.enabled = true
end

Bar.Disable = function(self)
	if (InCombatLockdown()) then return end

	self.config.enabled = false
end

Bar.SetEnabled = function(self, enable)
	if (InCombatLockdown()) then return end

	self.config.enabled = not not enable -- strict booleans

	if (self.config.enabled) then
		self:Enable()
	else
		self:Disable()
	end
end

Bar.IsEnabled = function(self)
	return self.config.enabled
end
