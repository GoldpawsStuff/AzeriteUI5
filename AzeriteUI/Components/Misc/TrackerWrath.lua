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
if (not ns.IsWrath) then return end

local Tracker = ns:NewModule("Tracker", "LibMoreEvents-1.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager")

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = {
			scale = ns.API.GetEffectiveScale(),
			[1] = "TOPRIGHT",
			[2] = -60 * ns.API.GetEffectiveScale(),
			[3] = -280 * ns.API.GetEffectiveScale()
		}
	}
}, ns.moduleDefaults) }

local config = {
	-- Size of the holder. Set to same width as our Minimap.
	-- *Wrath WatchFrame is 306 expanded, 204 standard width, Retail ObjectiveTracker 248
	Size = { 306, 22 }, -- 213
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

Tracker.InitializeWatchFrame = function(self)

	local db = config

	self.holder = CreateFrame("Frame", ns.Prefix.."WatchFrameAnchor", WatchFrame)
	self.holder:SetPoint(unpack(db.Position))
	self.holder:SetSize(unpack(db.Size))

	-- UIParent.lua overrides the position if this is false
	WatchFrame.IsUserPlaced = function() return true end
	WatchFrame:SetAlpha(.9)
	WatchFrameTitle:SetFontObject(db.WrathTitleFont)

	-- The local function WatchFrame_GetLinkButton creates the buttons,
	-- and it's only ever called from these two global functions.
	UpdateWatchFrameLinkButtons()

	hooksecurefunc("WatchFrame_Update", UpdateWatchFrameLines)
	hooksecurefunc("WatchFrame_DisplayTrackedAchievements", UpdateWatchFrameLinkButtons)
	hooksecurefunc("WatchFrame_DisplayTrackedQuests", UpdateWatchFrameLinkButtons)
	hooksecurefunc("WatchFrameItem_OnShow", UpdateQuestItemButton)

	self:UpdateWatchFrame()

	self.frame = self.holder -- ?
end

Tracker.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(TRACKER_HEADER_OBJECTIVE)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.25, 2.5, .05)
	anchor:SetSize(config.Size[1], config.TrackerHeight)
	anchor:SetPoint(unpack(defaults.profile.savedPosition[MFM:GetDefaultLayout()]))
	anchor:SetScale(defaults.profile.savedPosition[MFM:GetDefaultLayout()].scale)
	anchor:SetDefaultScale(ns.API.GetEffectiveScale)
	anchor.PreUpdate = function() self:UpdateAnchor() end
	anchor.UpdateDefaults = function() self:UpdateDefaults() end

	self.anchor = anchor
end

Tracker.UpdateDefaults = function(self)
	if (not self.anchor or not self.db) then return end

	local defaults = self.db.defaults.profile.savedPosition[MFM:GetDefaultLayout()]
	if (not defaults) then return end

	defaults.scale = self.anchor:GetDefaultScale()
	defaults[1], defaults[2], defaults[3] = self.anchor:GetDefaultPosition()
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
	WatchFrame:SetPoint("TOP", self.holder, "TOP")
	WatchFrame:SetPoint("BOTTOM", self.holder, "TOP", 0, -config.TrackerHeight)

	UpdateQuestItemButtons()
	UpdateWatchFrameLines()
end

Tracker.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]

	self.frame:SetScale(config.scale)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
end

Tracker.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition[MFM:GetLayout()]
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then

		WatchFrame:SetAlpha(.9)

		if (self.queueImmersionHook) then
			local frame = ImmersionFrame
			if (frame) then
				self.queueImmersionHook = nil
				frame:HookScript("OnShow", function() WatchFrame:SetAlpha(0) end)
				frame:HookScript("OnHide", function() WatchFrame:SetAlpha(.9) end)
			end
		end
		self:UpdateWatchFrame()
		self:UpdatePositionAndScale()

	elseif (event == "VARIABLES_LOADED") then
		self:UpdateWatchFrame()
		self:UpdatePositionAndScale()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil
		self:UpdateWatchFrame()

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_LayoutsUpdated") then
		local LAYOUT = ...

		if (not self.db.profile.savedPosition[LAYOUT]) then
			self.db.profile.savedPosition[LAYOUT] = ns:Merge({}, defaults.profile.savedPosition[MFM:GetDefaultLayout()])
		end

		self:UpdatePositionAndScale()
		self:UpdateAnchor()

	elseif (event == "MFM_LayoutDeleted") then
		local LAYOUT = ...

		self.db.profile.savedPosition[LAYOUT] = nil

	elseif (event == "MFM_PositionUpdated") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT][1] = point
		self.db.profile.savedPosition[LAYOUT][2] = x
		self.db.profile.savedPosition[LAYOUT][3] = y

		self:UpdatePositionAndScale()

	elseif (event == "MFM_AnchorShown") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

	elseif (event == "MFM_ScaleUpdated") then
		local LAYOUT, anchor, scale = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT].scale = scale
		self:UpdatePositionAndScale()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			if (select(2, ...) ~= self.anchor) then return end

			self:OnEvent("MFM_PositionUpdated", ...)
		end
	end
end

Tracker.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Tracker", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	MFM:RegisterPresets(self.db.profile.savedPosition)

	self:InitializeWatchFrame()
	self:InitializeMovableFrameAnchor()

	self.queueImmersionHook = IsAddOnEnabled("Immersion")
end

Tracker.OnEnable = function(self)

	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

	ns.RegisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
	ns.RegisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnEvent")
end