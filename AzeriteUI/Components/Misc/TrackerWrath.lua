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

if (not ns.IsWrath) then return end

local Tracker = ns:NewModule("Tracker", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- GLOBALS: UIParent, CreateFrame, SetCVar, InCombatLockdown
-- GLOBALS: WatchFrame, WatchFrameItem1, WatchFrameTitle, WatchFrameLinkButtonTemplate_OnClick
-- GLOBALS: WATCHFRAME_LINKBUTTONS, WATCHFRAME_ACHIEVEMENTLINES, WATCHFRAME_TIMERLINES, WATCHFRAME_QUESTLINES

-- Lua API
local pairs = pairs

-- Addon API
local GetFont = ns.API.GetFont
local UIHider = ns.Hider

local defaults = { profile = ns:Merge({

	disableBlizzardTracker = false

}, ns.Module.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Tracker.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOPRIGHT",
		[2] = -60 * ns.API.GetEffectiveScale(),
		[3] = -280 * ns.API.GetEffectiveScale()
	}
	return defaults
end

local config = {
	-- Size of the holder. Set to same width as our Minimap.
	-- *Wrath WatchFrame is 306 expanded, 204 standard width, Retail ObjectiveTracker 248
	Width = 306,
	Position = { "TOPRIGHT", UIParent, "TOPRIGHT", ns.IsWrath and -90 or -60, -240 }, -- might need to adjust
	BottomOffset = 380,
	TrackerHeight = 1080 - 380 - 240,
	WrathScale = 1.0625,
	WrathTitleFont = GetFont(12,true),
}

-- Cache of handled elements
local Handled = {}

-- Something is tainting the Wrath WatchFrame,
-- let's just work around it for now.
local LinkButton_OnClick = function(self, ...)
	if (not InCombatLockdown()) then
		WatchFrameLinkButtonTemplate_OnClick(self:GetParent(), ...)
	end
end

local UpdateQuestItemButton = function(button)
	local name = button:GetName()
	local icon = button.icon or _G[name.."IconTexture"]
	local count = button.Count or _G[name.."Count"]
	local hotKey = button.HotKey or _G[name.."HotKey"]

	if (not Handled[button]) then
		button:SetNormalTexture("")

		if (icon) then
			icon:SetDrawLayer("BACKGROUND",0)
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 2, -2)
			icon:SetPoint("BOTTOMRIGHT", -2, 2)

			local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
			backdrop:SetPoint("TOPLEFT", icon, -2, 2)
			backdrop:SetPoint("BOTTOMRIGHT", icon, 2, -2)
			backdrop:SetColorTexture(0, 0, 0, .75)
		end

		if (count) then
			count:ClearAllPoints()
			count:SetPoint("BOTTOMRIGHT", button, 0, 3)
			count:SetFontObject(GetFont(12,true))
		end

		if (hotKey) then
			hotKey:SetText("")
			hotKey:SetAlpha(0)
		end

		if (button.SetHighlightTexture and not button.Highlight) then
			local Highlight = button:CreateTexture()

			Highlight:SetColorTexture(1, 1, 1, 0.3)
			Highlight:SetAllPoints(icon)

			button.Highlight = Highlight
			button:SetHighlightTexture(Highlight)
		end

		if (button.SetPushedTexture and not button.Pushed) then
			local Pushed = button:CreateTexture()

			Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
			Pushed:SetAllPoints(icon)

			button.Pushed = Pushed
			button:SetPushedTexture(Pushed)
		end

		if (button.SetCheckedTexture and not button.Checked) then
			local Checked = button:CreateTexture()

			Checked:SetColorTexture(0, 1, 0, 0.3)
			Checked:SetAllPoints(icon)

			button.Checked = Checked
			button:SetCheckedTexture(Checked)
		end

		Handled[button] = true
	end
end

local UpdateWatchFrameLinkButtons = function()
	for i,linkButton in pairs(WATCHFRAME_LINKBUTTONS) do
		if (linkButton and not Handled[linkButton]) then
			local clickFrame = CreateFrame("Button", nil, linkButton)
			clickFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			clickFrame:SetAllPoints()
			clickFrame:SetScript("OnClick", LinkButton_OnClick)
			Handled[linkButton] = true
		end
	end
end

local UpdateWatchFrameLine = function(line)
	if (not Handled[line]) then
		line.text:SetFontObject(GetFont(12,true)) -- default size is 12
		line.text:SetWordWrap(false)
		line.dash:SetParent(UIHider)
		Handled[line] = true
	end
end

local UpdateWatchFrameLines = function()
	for _, timerLine in pairs(WATCHFRAME_TIMERLINES) do
		UpdateWatchFrameLine(timerLine)
	end
	for _, achievementLine in pairs(WATCHFRAME_ACHIEVEMENTLINES) do
		UpdateWatchFrameLine(achievementLine)
	end
	for _, questLine in pairs(WATCHFRAME_QUESTLINES) do
		UpdateWatchFrameLine(questLine)
	end
end

local UpdateQuestItemButtons = function()
	local i,item = 1,WatchFrameItem1
	while (item) do
		UpdateQuestItemButton(item)
		i = i + 1
		item = _G["WatchFrameItem" .. i]
	end
end

Tracker.UpdateWatchFrame = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	SetCVar("watchFrameWidth", "1") -- 306 or 204

	WatchFrame:SetFrameStrata("LOW")
	WatchFrame:SetFrameLevel(50)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOP", self.frame, "TOP")
	WatchFrame:SetPoint("BOTTOM", self.frame, "TOP", 0, -config.TrackerHeight)

	UpdateQuestItemButtons()
	UpdateWatchFrameLines()
end

Tracker.UpdateSettings = function(self)
	if (self.db.profile.disableBlizzardTracker) then
		WatchFrame:Hide()
		WatchFrame.Show = function() end
	else
		WatchFrame.Show = nil
		WatchFrame:Show()
	end
end

Tracker.GetFrame = function(self)
	return WatchFrame
end

Tracker.PrepareFrames = function(self)

	local frame = CreateFrame("Frame", ns.Prefix.."WatchFrameAnchor", UIParent)
	frame:SetSize(config.Width, config.TrackerHeight)
	frame:SetPoint(unpack(defaults.profile.savedPosition))

	self.frame = frame

	-- UIParent.lua overrides the position if this is false
	WatchFrame.IsUserPlaced = function() return true end
	WatchFrame:SetAlpha(.9)
	WatchFrameTitle:SetFontObject(config.WrathTitleFont)

	-- The local function WatchFrame_GetLinkButton creates the buttons,
	-- and it's only ever called from these two global functions.
	UpdateWatchFrameLinkButtons()

	self:SecureHook("WatchFrame_Update", UpdateWatchFrameLines)
	self:SecureHook("WatchFrame_DisplayTrackedAchievements", UpdateWatchFrameLinkButtons)
	self:SecureHook("WatchFrame_DisplayTrackedQuests", UpdateWatchFrameLinkButtons)
	self:SecureHook("WatchFrameItem_OnShow", UpdateQuestItemButton)

	self:UpdateWatchFrame()
end

Tracker.PostAnchorEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED") then
		self:UpdateWatchFrame()
		WatchFrame:SetAlpha(.9)

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:UpdateWatchFrame()
	end
end

Tracker.PostUpdatePositionAndScale = function(self)
	WatchFrame:SetScale(self.db.profile.savedPosition.scale)
end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			if (ImmersionFrame) then
				if (not self:IsHooked(ImmersionFrame, "OnShow")) then
					self:SecureHookScript(ImmersionFrame, "OnShow", function() WatchFrame:SetAlpha(0) end)
				end
				if (not self:IsHooked(ImmersionFrame, "OnHide")) then
					self:SecureHookScript(ImmersionFrame, "OnHide", function() WatchFrame:SetAlpha(.9) end)
				end
			end
		end
	end
end

Tracker.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(TRACKER_HEADER_OBJECTIVE, true)

	ns.Module.OnEnable(self)
end
