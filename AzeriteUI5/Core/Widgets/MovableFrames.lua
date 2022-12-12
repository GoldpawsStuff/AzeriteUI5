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
local Widgets = ns.Private.Widgets or {}
ns.Private.Widgets = Widgets

-- Lua API
local math_abs = math.abs
local next = next
local setmetatable = setmetatable
local string_format = string.format
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetPosition = ns.API.GetPosition
local GetScale = ns.API.GetScale

-- Private event frame
local Frame = CreateFrame("Frame")
Frame:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		Widgets:HideMovableFrameAnchors()
	end
end)

-- Anchor cache
local Anchors = {}

-- Anchor Template
local Anchor = CreateFrame("Button")
local Anchor_MT = { __index = Anchor }

-- Anchor API
--------------------------------------
-- Constructor
Anchor.Create = function(self, frame, savedPosition, ...)

	local anchor = setmetatable(CreateFrame("Button", nil, UIParent), Anchor_MT)
	anchor:Hide()
	anchor:SetFrameStrata("DIALOG")
	anchor:SetIgnoreParentAlpha(true)
	anchor:SetIgnoreParentScale(true)
	anchor:SetMovable(true)
	anchor.frame = frame
	anchor.savedPosition = savedPosition or {}

	-- Populate the saved position table if it's empty,
	-- to avoid bugs if the calling module tries to
	-- manually position the element using it.
	if (savedPosition and not next(savedPosition)) then
		local parsed = { GetPosition(frame) }
		for i,j in ipairs(parsed) do
			savedPosition[i] = j
		end
	end

	-- Apply custom/static sizing to the anchor frame
	local anchorWidth, anchorHeight, displayName = ...
	if (anchorWidth and anchorHeight) then
		anchor.anchorWidth = anchorWidth
		anchor.anchorHeight = anchorHeight
		anchor:SetSize(anchor.anchorWidth, anchor.anchorHeight)
	end

	-- Store the parsed default position.
	anchor.defaultPosition = { GetPosition(frame) }

	local overlay = anchor:CreateTexture(nil, "ARTWORK", nil, 1)
	overlay:SetAllPoints()
	overlay:SetColorTexture(.25, .5, 1, .75)
	anchor.Overlay = overlay

	local positionText = anchor:CreateFontString(nil, "OVERLAY", nil, 1)
	positionText:SetFontObject(GetFont(15,true))
	positionText:SetTextColor(unpack(Colors.highlight))
	positionText:SetIgnoreParentScale(true)
	positionText:SetScale(GetScale())
	positionText:SetPoint("CENTER")
	anchor.Text = positionText

	if (displayName) then
		local titleText = anchor:CreateFontString(nil, "OVERLAY", nil, 1)
		titleText:SetFontObject(GetFont(15,true))
		titleText:SetTextColor(unpack(Colors.normal))
		titleText:SetIgnoreParentScale(true)
		titleText:SetScale(GetScale())
		titleText:SetPoint("BOTTOM", positionText, "TOP", 0, 1)
		titleText:SetText(displayName)
		anchor.TitleText = positionText
	end

	anchor:SetHitRectInsets(-20,-20,-20,-20)
	anchor:RegisterForClicks("AnyUp")
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnClick", Anchor.OnClick)
	anchor:SetScript("OnShow", Anchor.OnShow)
	anchor:SetScript("OnHide", Anchor.OnHide)
	anchor:SetScript("OnEnter", Anchor.OnEnter)
	anchor:SetScript("OnLeave", Anchor.OnLeave)

	if (savedPosition and next(savedPosition)) then
		anchor:ResetToSaved()
	end

	if (not next(Anchors)) then
		Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	end

	Anchors[#Anchors + 1] = anchor

	return anchor
end

-- Compare two anchor points.
local compare = function(point, x, y, point2, x2, y2)
	return (point == point2) and (math_abs(x - x2) < 0.01) and (math_abs(y - y2) < 0.01)
end

-- 'true' if the frame has moved since last showing the anchor.
Anchor.HasMoved = function(self)
	local point, x, y = unpack(self.currentPosition)
	local point2, x2, y2 = unpack(self.lastPosition)
	return not compare(point, x, y, point2, x2, y2)
end

-- 'true' if the frame is in its default position.
Anchor.IsInDefaultPosition = function(self)
	local point, x, y = GetPosition(self)
	local point2, x2, y2 = unpack(self.defaultPosition)
	return compare(point, x, y, point2, x2, y2)
end

-- Reset to initial position after last showing the anchor.
Anchor.ResetLastChange = function(self)
	local point, x, y = unpack(self.lastPosition)

	-- Always reuse saved table, or it stops saving.
	self.savedPosition[1] = point
	self.savedPosition[2] = x
	self.savedPosition[3] = y

	self.currentPosition = { point, x, y }

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	local width, height = self.frame:GetSize()

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(self.anchorWidth or width, self.anchorHeight or height)
	self:UpdateText()

	if (self.frame.PostUpdateAnchoring) then
		self.frame:PostUpdateAnchoring(self.anchorWidth or width, self.anchorHeight or height, point, UIParent, point, x, y)
	end
end

-- Reset to saved position.
Anchor.ResetToSaved = function(self)
	local point, x, y = unpack(self.savedPosition)

	self.currentPosition = { point, x, y }
	self.lastPosition = { point, x, y }

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	local width, height = self.frame:GetSize()

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(self.anchorWidth or width, self.anchorHeight or height)
	self:UpdateText()

	if (self.frame.PostUpdateAnchoring) then
		self.frame:PostUpdateAnchoring(self.anchorWidth or width, self.anchorHeight or height, point, UIParent, point, x, y)
	end
end

-- Reset to default position.
Anchor.ResetToDefault = function(self)
	local point, x, y = unpack(self.defaultPosition)

	-- Always reuse saved table, or it stops saving.
	self.savedPosition[1] = point
	self.savedPosition[2] = x
	self.savedPosition[3] = y

	self.currentPosition = { point, x, y }
	self.lastPosition = { point, x, y }

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	local width, height = self.frame:GetSize()

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(self.anchorWidth or width, self.anchorHeight or height)
	self:UpdateText()

	if (self.frame.PostUpdateAnchoring) then
		self.frame:PostUpdateAnchoring(self.anchorWidth or width, self.anchorHeight or height, point, UIParent, point, x, y)
	end
end

-- Update display text on the anchor.
Anchor.UpdateText = function(self)
	local msg = string_format("%s, %.0f, %.0f", unpack(self.currentPosition))
	if (self:IsMouseOver(20,-20,-20,20)) then
		if (not self:IsInDefaultPosition()) then
			if (self:HasMoved()) then
				msg = msg .. Colors.green.colorCode.."\n<Right-Click to undo last change>|r"
			end
			msg = msg .. Colors.green.colorCode.."\n<Shift-Click to reset to default>|r"
		end
	end
	self.Text:SetText(msg)
	if (self:IsDragging()) then
		self.Text:SetTextColor(unpack(Colors.normal))
	else
		self.Text:SetTextColor(unpack(Colors.highlight))
	end
end

-- Anchor Script Handlers
--------------------------------------
Anchor.OnClick = function(self, button)
	if (button == "LeftButton") then
		self:SetFrameLevel(60)
		if (IsShiftKeyDown() and not self:IsInDefaultPosition()) then
			self:ResetToDefault()
		end
	elseif (button == "RightButton") then
		self:SetFrameLevel(40)
		if (self:HasMoved()) then
			self:ResetLastChange()
		end
	end
end

Anchor.OnDragStart = function(self, button)
	self:StartMoving()
	self:SetUserPlaced(false)
	self.elapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)
end

Anchor.OnDragStop = function(self)
	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = GetPosition(self)
	self.currentPosition = { point, x, y }
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)

	-- Always reuse saved table, or it stops saving.
	self.savedPosition[1] = point
	self.savedPosition[2] = x
	self.savedPosition[3] = y

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	if (self.frame.PostUpdateAnchoring) then
		self.frame:PostUpdateAnchoring(self.anchorWidth or width, self.anchorHeight or height, point, UIParent, point, x, y)
	end
end

Anchor.OnEnter = function(self)
	self:UpdateText()
	self:SetAlpha(1)
end

Anchor.OnLeave = function(self)
	self:UpdateText()
	self:SetAlpha(.75)
end

Anchor.OnShow = function(self)
	local point, x, y = GetPosition(self.frame)

	self.lastPosition = { point, x, y }
	self.currentPosition = { point, x, y }

	local effectiveScale = self.frame:GetEffectiveScale()
	local width, height = self.frame:GetSize()

	self:SetFrameLevel(50)
	self:SetAlpha(.75)
	self:SetScale(effectiveScale)
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(self.anchorWidth or width, self.anchorHeight or height)
	self:UpdateText()

	if (self.frame.PostUpdateAnchoring) then
		self.frame:PostUpdateAnchoring(self.anchorWidth or width, self.anchorHeight or height, point, UIParent, point, x, y)
	end
end

Anchor.OnHide = function(self)
	self:SetScript("OnUpdate", nil)
	self.elapsed = 0
end

Anchor.OnUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if (self.elapsed < 0.02) then
		return
	end
	self.elapsed = 0

	local point, x, y = GetPosition(self)

	-- Reuse old table here,
	-- or we'll spam the garbage handler.
	self.currentPosition[1] = point
	self.currentPosition[2] = x
	self.currentPosition[3] = y

	self:UpdateText()
end

-- Public API
--------------------------------------
Widgets.RegisterFrameForMovement = function(frame, db, ...)
	if (InCombatLockdown()) then return end
	return Anchor:Create(frame, db, ...).savedPosition
end

Widgets.ShowMovableFrameAnchors = function()
	if (InCombatLockdown()) then return end
	for i,anchor in next,Anchors do
		anchor:Show()
	end
end

Widgets.HideMovableFrameAnchors = function()
	for i,anchor in next,Anchors do
		anchor:Hide()
	end
end

Widgets.ToggleMovableFrameAnchors = function()
	if (InCombatLockdown()) then
		return Widgets:HideMovableFrameAnchors()
	end
	local allshown = true
	for i,anchor in next,Anchors do
		if (not anchor:IsShown()) then
			allshown = false
			break
		end
	end
	if (allshown) then
		Widgets:HideMovableFrameAnchors()
	else
		Widgets:ShowMovableFrameAnchors()
	end
end