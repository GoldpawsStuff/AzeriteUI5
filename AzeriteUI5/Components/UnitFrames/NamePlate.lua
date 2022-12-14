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
local oUF = ns.oUF

local defaults = {
	enabled = true,
	scale = 1
}

ns.ActiveNamePlates = {}
ns.NamePlates = {}
ns.NamePlate = {
	defaults = defaults,

	OnEnter = function(self, ...)
		self.isMouseOver = true
		if (self.OnEnter) then
			self:OnEnter(...)
		end
	end,

	OnLeave = function(self, ...)
		self.isMouseOver = nil
		if (self.OnLeave) then
			self:OnLeave(...)
		end
	end,

	OnHide = function(self, ...)
		self.isMouseOver = nil
		if (self.OnHide) then
			self:OnHide(...)
		end
	end,

	Initialize = function(self)
		--self.isNamePlate = true (oUF does this)
		self.colors = ns.Colors
		self:SetPoint("CENTER",0,0)
		self:SetScript("OnHide", OnHide)
	end
}

oUF:RegisterMetaFunction("CreateBar", function(self, name, parent, ...)
	return LibStub("LibSmoothBar-1.0"):CreateSmoothBar(name, parent or self, ...)
end)

oUF:RegisterMetaFunction("CreateRing", function(self, name, parent, ...)
	return LibStub("LibSpinBar-1.0"):CreateSpinBar(name, parent or self, ...)
end)

oUF:RegisterMetaFunction("CreateOrb", function(self, name, parent, ...)
	return LibStub("LibOrb-1.0"):CreateOrb(name, parent or self, ...)
end)
