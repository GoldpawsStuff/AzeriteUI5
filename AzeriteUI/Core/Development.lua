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
local Development = ns:NewModule("Development", "AceConsole-3.0", "LibMoreEvents-1.0")

Development.OnInitialize = function(self)

	local showVersion = ns.db.global.enableDevelopmentMode or ns.IsDevelopment or ns.IsAlpha or ns.IsBeta
	if (showVersion) then

		local label = UIParent:CreateFontString()
		label:SetIgnoreParentScale(true)
		label:SetScale(ns.API.GetEffectiveScale())
		label:SetDrawLayer("HIGHLIGHT", 1)
		label:SetFontObject(ns.API.GetFont(12,true))
		label:SetTextColor(ns.Colors.offwhite[1], ns.Colors.offwhite[2], ns.Colors.offwhite[3], .85)
		label:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 10)
		label:SetText((ns.db.global.enableDevelopmentMode and "Dev Mode|n" or "") .. (ns.IsDevelopment and "Git Version" or ns.Version))

		--self.VersionLabel = label
	end

	self:RegisterChatCommand("devmode", function(self)
		ns.db.global.enableDevelopmentMode = not ns.db.global.enableDevelopmentMode
		ReloadUI()
	end)
end
