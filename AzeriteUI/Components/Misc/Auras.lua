
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
local Auras = ns:NewModule("Auras", "LibMoreEvents-1.0")

Auras.DisableBlizzard = function(self)

	BuffFrame:SetScript("OnLoad", nil)
	BuffFrame:SetScript("OnUpdate", nil)
	BuffFrame:SetScript("OnEvent", nil)
	BuffFrame:SetParent(ns.Hider)
	BuffFrame:UnregisterAllEvents()

	DebuffFrame:SetScript("OnLoad", nil)
	DebuffFrame:SetScript("OnUpdate", nil)
	DebuffFrame:SetScript("OnEvent", nil)
	DebuffFrame:SetParent(ns.Hider)
	DebuffFrame:UnregisterAllEvents()

end

Auras.OnInitialize = function(self)
	self:DisableBlizzard()
end

Auras.OnEnable = function(self)
end
