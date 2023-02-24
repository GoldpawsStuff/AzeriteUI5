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
if (ns.IsRetail) then return end

local Timers = ns:NewModule("Timers", "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0")

-- Lua API
local _G = _G
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Cache of handled elements
local Handled = {}

local config = {
	MirrorTimerPosition = { "TOP", UIParent, "TOP", 0, -370 },

	MirrorTimerBarPosition = { "CENTER", 0, 0 },
	MirrorTimerBarSize = { 111, 12 },
	MirrorTimerBarTexture = GetMedia("cast_bar"),
	MirrorTimerBarColor = { Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3] },

	MirrorTimerLabelPosition = { "CENTER", 0, 0 },
	MirrorTimerLabelFont = GetFont(14, true),
	MirrorTimerLabelColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .7 },

	MirrorTimerBackdropPosition = { "CENTER", 1, -2 },
	MirrorTimerBackdropSize = { 193,93 },
	MirrorTimerBackdropTexture = GetMedia("cast_back"),
	MirrorTimerBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] }
}

Timers.UpdateMirrorTimers = function(self)

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local timer  = _G["MirrorTimer"..i]
		if (timer) then
			local bar = _G[timer:GetName().."StatusBar"]
			if (not Handled[bar]) then

				if (i == 1) then
					timer:ClearAllPoints()
					timer:SetPoint(unpack(config.MirrorTimerPosition))
				end

				local oldborder = _G[timer:GetName().."Border"]
				local label = _G[timer:GetName().."Text"]

				for i = 1, bar:GetNumRegions() do
					local region = select(i, bar:GetRegions())
					if (region:GetObjectType() == "Texture") then
						region:SetTexture(nil)
					end
				end
				oldborder:SetTexture(nil)
				timer:DisableDrawLayer("BACKGROUND")

				bar:SetStatusBarTexture(config.MirrorTimerBarTexture)
				bar:GetStatusBarTexture():SetDrawLayer("BORDER", 0)
				bar:SetSize(unpack(config.MirrorTimerBarSize))
				bar:ClearAllPoints()
				bar:SetPoint(unpack(config.MirrorTimerBarPosition))

				label:SetFontObject(config.MirrorTimerLabelFont)
				label:SetTextColor(unpack(config.MirrorTimerLabelColor))
				label:ClearAllPoints()
				label:SetPoint(unpack(config.MirrorTimerLabelPosition))

				local backdrop = bar:CreateTexture(nil, "BACKGROUND", nil, -5)
				backdrop:SetPoint(unpack(config.MirrorTimerBackdropPosition))
				backdrop:SetSize(unpack(config.MirrorTimerBackdropSize))
				backdrop:SetTexture(config.MirrorTimerBackdropTexture)
				backdrop:SetVertexColor(unpack(config.MirrorTimerBackdropColor))

				Handled[bar] = true
			end
			bar:SetStatusBarColor(unpack(config.MirrorTimerBarColor))
		end

	end
end

Timers.UpdateAll = function(self)
	self:UpdateMirrorTimers("ForceUpdate")
end

Timers.OnInitialize = function(self)

	-- Reset scripts and events
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local timer  = _G["MirrorTimer"..i]
		if (timer) then
			timer:SetParent(UIParent)
			timer:SetScript("OnEvent", MirrorTimerFrame_OnEvent)
			timer:SetScript("OnUpdate", MirrorTimerFrame_OnUpdate)
			MirrorTimerFrame_OnLoad(timer)
		end
	end

	-- Update mirror timers (breath/fatigue)
	self:SecureHook("MirrorTimer_Show", "UpdateMirrorTimers")

	-- Update all on world entering
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAll")

end
