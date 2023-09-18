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

if (not C_Container) then return print("C_Container not found") end

local Containers = ns:NewModule("Containers", ns.Module, "LibMoreEvents-1.0")

local defaults = { profile = ns:Merge({
	sort = "rtl",
	insert = "ltr"
}, ns.Module.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Containers.GenerateDefaults = function(self)
	return defaults
end

Containers.UpdateSettings = function(self)
	if (C_Container.SetSortBagsRightToLeft) then
		if (self.db.profile.sort == "rtl") then
			C_Container.SetSortBagsRightToLeft(true)
		elseif (self.db.profile.sort == "ltr") then
			C_Container.SetSortBagsRightToLeft(false)
		end
	end
	if (C_Container.SetInsertItemsLeftToRight) then
		if (self.db.profile.insert == "ltr") then
			C_Container.SetInsertItemsLeftToRight(true)
		elseif (self.db.profile.insert == "rtl") then
			C_Container.SetInsertItemsLeftToRight(false)
		end
	end
end
