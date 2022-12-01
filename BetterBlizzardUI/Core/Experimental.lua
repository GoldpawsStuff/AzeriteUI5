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

-- Addon API
local GetScale = ns.API.GetScale

-- Little trick to show the layout and dimensions
-- of the Minimap blip icons on-screen in-game,
-- whenever blizzard decide to update those.
------------------------------------------------------------

-- By setting a single point, but not any sizes,
-- the texture is shown in its original size and dimensions!
local f = UIParent:CreateTexture()
f:SetIgnoreParentScale(true)
f:SetScale(GetScale())
f:Hide()
f:SetTexture([[Interface\MiniMap\ObjectIconsAtlas.blp]])
f:SetPoint("CENTER")

-- Add a little backdrop for easy
-- copy & paste from screenshots!
local g = UIParent:CreateTexture()
g:Hide()
g:SetColorTexture(0,.7,0,.25)
g:SetAllPoints(f)

LibStub("AceConsole-3.0"):RegisterChatCommand("toggleblips", function()
	local show = not f:IsShown()
	f:SetShown(show)
	g:SetShown(show)
end)

-- Kill off the non-stop voice chat error 17 on retail.
if (ns.IsRetail) then
	if (ChannelFrame) then
		ChannelFrame:UnregisterEvent("VOICE_CHAT_ERROR")
	else
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(self, event, addon)
			if (addon ~= "Blizzard_Channels") then return end
			self:UnregisterEvent("ADDON_LOADED")
			ChannelFrame:UnregisterEvent("VOICE_CHAT_ERROR")
		end)
	end
end
