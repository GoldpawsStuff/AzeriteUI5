--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

for _,a in next,{"ElvUI","KkthnxUI","TukUI"} do
	if (a ~= Addon and ns.API.IsAddOnEnabled(a)) then
		local n=ns.Noop;ns.OnInitialize=n;ns.OnEnable=n;ns.OnDisable=n
		for _,m in ns:IterateModules() do
			m.OnInitialize=n;m.OnEnable=n;m.OnDisable=n
			for i,v in next,m do if(type(v)=="function") then m[i]=n end end
		end
		local f=CreateFrame("Frame");f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:SetScript("OnEvent", function(f)
			for name,module in next,ns.modules do for i,v in next,module do module[i]=nil end end
			for i,v in next,ns do ns[i]=nil end
			f:UnregisterAllEvents();f:Hide()
		end)
		return
	end
end
