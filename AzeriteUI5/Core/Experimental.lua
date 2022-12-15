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

do return end

-- Attempt to create a proxy anchor with callbacks
local anchor = ns.Widgets.RequestMovableFrameAnchor()
anchor:SetScalable(true)
anchor:SetMinMaxScale(.75, 1.25, .05)
anchor:SetSize(439, 93)
anchor:SetPoint("BOTTOMLEFT", 167, 100)
anchor:SetTitle(ns.Prefix.."PlayerFrame")

local savedPosition = {
	Azerite = {
		scale = 1,
		[1] = "BOTTOMLEFT",
		[2] = 167,
		[3] = 100
	},
	Classic = {
		scale = 1,
		[1] = "TOPLEFT",
		[2] = 167,
		[3] = -100
	},
	Modern = {
		scale = 1,
		[1] = "TOPLEFT",
		[2] = 167,
		[3] = -100
	}
}

anchor.PostUpdate = function(self, reason, layoutName, ...)
	if (reason == "LayoutsUpdated") then
		if (savedPosition[layoutName]) then

			-- Update defaults
			-- Update current positon
			self:SetScale(savedPosition[layoutName].scale or self:GetScale())
			self:ClearAllPoints()
			self:SetPoint(unpack(savedPosition[layoutName]))

		else
			savedPosition[layoutName] = { self:GetPosition() }
			savedPosition[layoutName].scale = self:GetScale()
		end

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPosition[layoutName] = { point, x, y }
		savedPosition[layoutName].scale = self:GetScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy-
		local point, x, y = ...

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown

	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends

	end
end
