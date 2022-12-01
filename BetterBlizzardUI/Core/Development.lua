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
local Development = ns:NewModule("Development", "AceConsole-3.0", "LibMoreEvents-1.0")

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetScale = ns.API.GetScale

Development.ToggleDevMode = function(self)
	ns.db.global.core.enableDevelopmentMode = not ns.db.global.core.enableDevelopmentMode
	ReloadUI()
end

Development.OnInitialize = function(self)

	local showVersion = ns.db.global.core.enableDevelopmentMode or ns.IsDevelopment or ns.IsAlpha or ns.IsBeta or ns.IsRC
	if (showVersion) then
		local versionLabel = UIParent:CreateFontString()
		versionLabel:SetIgnoreParentScale(true)
		versionLabel:SetScale(GetScale())
		versionLabel:SetDrawLayer("OVERLAY", 1)
		versionLabel:SetFontObject(GetFont(12,true))
		versionLabel:SetTextColor(unpack(Colors.offwhite))
		versionLabel:SetAlpha(.85)
		versionLabel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 10)
		if (ns.IsDevelopment) then
			versionLabel:SetText("Git Version")
		else
			versionLabel:SetText(ns.Version)
		end
		self.VersionLabel = versionLabel
	end

	if (ns.db.global.core.enableDevelopmentMode) then
		local devLabel = UIParent:CreateFontString()
		devLabel:SetIgnoreParentScale(true)
		devLabel:SetScale(GetScale())
		devLabel:SetDrawLayer("OVERLAY", 1)
		devLabel:SetFontObject(GetFont(12,true))
		devLabel:SetTextColor(unpack(Colors.gray))
		devLabel:SetAlpha(.85)
		devLabel:SetText("Dev Mode")
		if (showVersion) then
			devLabel:SetPoint("BOTTOMLEFT", self.VersionLabel, "TOPLEFT", 0, 4)
		else
			devLabel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 10)
		end
		self.DevLabel = devLabel
	end

	self:RegisterChatCommand("devmode", "ToggleDevMode")
end
