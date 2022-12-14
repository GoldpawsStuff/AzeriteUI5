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

--do return end

local MyButtonDB

local button = CreateFrame("Button", ns.Prefix.."PlayerFrame", UIParent)
button:SetScale(ns:GetRelativeScale())
button:SetSize(439, 93)

local updateFrameSettings = function(unitFrame)
	if (InCombatLockdown()) then return end
	unitFrame:ClearAllPoints()
	unitFrame:SetPoint(MyButtonDB[layoutName].point, MyButtonDB[layoutName].x, MyButtonDB[layoutName].y)
	unitFrame:SetScale(MyButtonDB[layoutName].scale * ns:GetRelativeScale())
end

local onPositionChanged = function(frame, layoutName, point, x, y)

	-- From here you can save the position into a savedvariable
	MyButtonDB[layoutName].point = point
	MyButtonDB[layoutName].x = x
	MyButtonDB[layoutName].y = y

	-- Here we need to move the actual frame,
	-- and register for combat end if needed.
	local unitFrame = frame.unitFrame
	if (unitFrame) then
		if (InCombatLockdown()) then
			return self:RegisterEvent("PLAYER_REGEN_ENABLED", updateFrameSettings)
		end
		updateFrameSettings(unitFrame)
	end
end

local defaultPosition = {
	enabled = true,
	scale = 1,
	point = "BOTTOMLEFT",
	x = 167,
	y = 100
}

local LEM = LibStub("LibEditMode")

LEM:AddFrame(button, onPositionChanged, defaultPosition)

LEM:RegisterCallback("enter", function()
	-- From here you can show your button if it was hidden.
end)

LEM:RegisterCallback("exit", function()
	-- From here you can hide your button if it's supposed to be hidden.
end)

LEM:RegisterCallback("layout", function(layoutName)
	-- This will be called every time the Edit Mode layout is changed (which also happens at login),
	-- use it to load the saved button position from savedvariables and position it.
	if (not MyButtonDB) then
		MyButtonDB = {}
	end
	if (not MyButtonDB[layoutName]) then
		MyButtonDB[layoutName] = CopyTable(defaultPosition)
	end

	button:ClearAllPoints()
	button:SetPoint(MyButtonDB[layoutName].point, MyButtonDB[layoutName].x, MyButtonDB[layoutName].y)
end)

LEM:AddFrameSettings(button, {
	{
		name = "Enable",
		kind = LEM.SettingType.Checkbox,
		default = true,
		get = function(layoutName)
			return MyButtonDB[layoutName].enabled
		end,
		set = function(layoutName, value)
			MyButtonDB[layoutName].enabled = value
		end
	},
	{
		name = "Scale",
		kind = LEM.SettingType.Slider,
		default = 1,
		get = function(layoutName)
			return MyButtonDB[layoutName].scale
		end,
		set = function(layoutName, value)
			MyButtonDB[layoutName].scale = value
			button:SetScale(value * ns:GetRelativeScale())
		end,
		minValue = 0.75,
		maxValue = 1.25,
		valueStep = 0.05,
		formatter = function(value)
			return string.format("%.2f", value)
		end,
	}
})