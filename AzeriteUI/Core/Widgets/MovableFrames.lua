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
local Widgets = ns.Private.Widgets or {}
ns.Private.Widgets = Widgets

-- Lua API
local error = error
local getmetatable = getmetatable
local math_abs = math.abs
local next = next
local rawget = rawget
local setmetatable = setmetatable
local string_format = string.format
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont

local CURRENT

local LAYOUT
local layoutNames = setmetatable({ "Modern", "Classic" }, {
	__index = function(t, key)
		if (key > 2) then
			-- The first 2 indices are reserved for 'Modern' and 'Classic' layouts, and anything
			-- else are custom ones, although GetLayouts() doesn't return data for the 'Modern'
			-- and 'Classic' layouts, so we'll have to substract and check
			local layouts = C_EditMode.GetLayouts().layouts
			if ((key - 2) > #layouts) then
				error("index is out of bounds")
			else
				return layouts[key - 2].layoutName
			end
		else
			-- Also work for 'Modern' and 'Classic'
			rawget(t, key)
		end
	end
})

-- Anchor cache
local AnchorData = {}

-- Utility
--------------------------------------
-- Compare two anchor points or two scales.
local compare = function(...)
	local numArgs = select("#", ...)
	if (numArgs == 2) then
		local s, s2 = ...
		return (math_abs(s - s2) < 0.01)
	else
		local point, x, y, point2, x2, y2 = ...
		return (point == point2) and (math_abs(x - x2) < 0.01) and (math_abs(y - y2) < 0.01)
	end
end

-- Get a properly parsed position of a frame,
-- relative to UIParent and the frame's scale.
local getPosition = function(frame)

	-- Retrieve UI coordinates, convert to unscaled screen coordinates
	local worldHeight = 768 -- WorldFrame:GetHeight()
	local worldWidth = WorldFrame:GetWidth()
	local uiScale = UIParent:GetEffectiveScale()
	local uiWidth = UIParent:GetWidth() * uiScale
	local uiHeight = UIParent:GetHeight() * uiScale
	local uiBottom = UIParent:GetBottom() * uiScale
	local uiLeft = UIParent:GetLeft() * uiScale
	local uiTop = UIParent:GetTop() * uiScale - worldHeight -- use values relative to edges, not origin
	local uiRight = UIParent:GetRight() * uiScale - worldWidth -- use values relative to edges, not origin

	-- Retrieve frame coordinates, convert to unscaled screen coordinates
	local frameScale = frame:GetEffectiveScale()
	local x, y = frame:GetCenter(); x = x * frameScale; y = y * frameScale
	local bottom = frame:GetBottom() * frameScale
	local left = frame:GetLeft() * frameScale
	local top = frame:GetTop() * frameScale - worldHeight -- use values relative to edges, not origin
	local right = frame:GetRight() * frameScale - worldWidth -- use values relative to edges, not origin

	-- Figure out the frame position relative to UIParent
	left = left - uiLeft
	bottom = bottom - uiBottom
	right = right - uiRight
	top = top - uiTop

	-- Figure out the point within the given coordinate space,
	-- return values converted to the frame's own scale.
	if (y < uiHeight * 1/3) then
		if (x < uiWidth * 1/3) then
			return "BOTTOMLEFT", left / frameScale, bottom / frameScale
		elseif (x > uiWidth * 2/3) then
			return "BOTTOMRIGHT", right / frameScale, bottom / frameScale
		else
			return "BOTTOM", (x - uiWidth/2) / frameScale, bottom / frameScale
		end
	elseif (y > uiHeight * 2/3) then
		if (x < uiWidth * 1/3) then
			return "TOPLEFT", left / frameScale, top / frameScale
		elseif x > uiWidth * 2/3 then
			return "TOPRIGHT", right / frameScale, top / frameScale
		else
			return "TOP", (x - uiWidth/2) / frameScale, top / frameScale
		end
	else
		if (x < uiWidth * 1/3) then
			return "LEFT", left / frameScale, (y - uiHeight/2) / frameScale
		elseif (x > uiWidth * 2/3) then
			return "RIGHT", right / frameScale, (y - uiHeight/2) / frameScale
		else
			return "CENTER", (x - uiWidth/2) / frameScale, (y - uiHeight/2) / frameScale
		end
	end
end

-- Anchor Template
--------------------------------------
local mt = getmetatable(CreateFrame("Button")).__index
local Anchor = {}

-- Constructor
Anchor.Create = function(self)

	local anchor = CreateFrame("Button", nil, UIParent)
	for method,func in next,Anchor do
		anchor[method] = func
	end

	anchor:Hide()
	anchor:Enable()
	anchor:SetFrameStrata("HIGH")
	anchor:SetFrameLevel(1000)
	anchor:SetMovable(true)
	anchor:SetHitRectInsets(-20,-20,-20,-20)
	anchor:RegisterForDrag("LeftButton")
	anchor:RegisterForClicks("AnyUp")
	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnMouseWheel", Anchor.OnMouseWheel)
	anchor:SetScript("OnClick", Anchor.OnClick)
	anchor:SetScript("OnShow", Anchor.OnShow)
	anchor:SetScript("OnHide", Anchor.OnHide)
	--anchor:SetScript("OnEnter", Anchor.OnEnter)
	--anchor:SetScript("OnLeave", Anchor.OnLeave)

	local overlay = CreateFrame("Frame", nil, anchor, ns.BackdropTemplate)
	overlay:SetAllPoints()
	overlay:SetBackdrop({
		bgFile =[[Interface\Tooltips\UI-Tooltip-Background]],
		tile = true,
		tileSize = 16,
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		edgeSize = 16,
		insets = { left = 5, right = 3, top = 3, bottom = 5 }
	})
	overlay:SetBackdropColor(.5, 1, .5, .75)
	overlay:SetBackdropBorderColor(.5, 1, .5, 1)
	anchor.Overlay = overlay

	local text = overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	text:SetFontObject(GetFont(13, true))
	text:SetTextColor(unpack(Colors.highlight))
	text:SetIgnoreParentScale(true)
	text:SetIgnoreParentAlpha(true)
	text:SetJustifyV("MIDDLE")
	text:SetJustifyH("CENTER")
	text:SetPoint("CENTER")
	anchor.Text = text

	local title = overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	title:SetFontObject(GetFont(15, true))
	title:SetTextColor(unpack(Colors.highlight))
	title:SetIgnoreParentScale(true)
	title:SetIgnoreParentAlpha(true)
	title:SetJustifyV("MIDDLE")
	title:SetJustifyH("CENTER")
	title:SetPoint("CENTER")
	anchor.Title = title

	AnchorData[anchor] = {
		anchor = anchor,
		scale = 1,
		minScale = .5,
		maxScale = 1.5,
		isScalable = false,
		defaultScale = 1
	}

	return anchor
end

Anchor.Enable = function(self)
	self.enabled = true
end

Anchor.Disable = function(self)
	self.enabled = false
end

Anchor.IsEnabled = function(self)
	return self.enabled
end

Anchor.SetEnabled = function(self, enable)
	self.enabled = enable and true or false
end

-- 'true' if the frame is in its default position and scale.
Anchor.IsInDefaultPosition = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end
	local point, x, y = getPosition(self)
	local point2, x2, y2 = unpack(anchorData.defaultPosition)
	return compare(anchorData.scale, anchorData.defaultScale) and compare(point, x, y, point2, x2, y2)
end

-- 'true' if the frame can be scaled.
Anchor.IsScalable = function(self)
	return AnchorData[self].isScalable
end

-- 'true' if the frame has moved since last showing the anchor.
Anchor.HasMovedSinceLastUpdate = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.lastPosition) then return end
	local point, x, y = unpack(anchorData.currentPosition)
	local point2, x2, y2 = unpack(anchorData.lastPosition)
	return not compare(anchorData.scale, anchorData.lastScale or anchorData.defaultScale) or not compare(point, x, y, point2, x2, y2)
end

-- Reset to initial position after last showing the anchor.
Anchor.ResetLastChange = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.lastPosition) then return end

	local point, x, y = unpack(anchorData.lastPosition)

	anchorData.currentPosition = { point, x, y }

	self:SetScale(anchorData.scale)

	self:UpdateScale(LAYOUT, anchorData.lastScale or anchorData.scale or anchorData.defaultScale)
	self:UpdatePosition(LAYOUT, point, x, y)
	self:UpdateText()

	if (self.Callback) then
		self:Callback("PositionUpdated", LAYOUT, point, x, y)
	end
end

-- Reset to default position.
Anchor.ResetToDefault = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end

	local point, x, y = unpack(anchorData.defaultPosition)

	anchorData.currentPosition = { point, x, y }
	anchorData.lastPosition = { point, x, y }

	self:UpdateScale(LAYOUT, anchorData.defaultScale)
	self:UpdatePosition(LAYOUT, point, x, y)
	self:UpdateText()

	if (self.Callback) then
		self:Callback("PositionUpdated", LAYOUT, point, x, y)
	end
end

Anchor.UpdateText = function(self)
	local anchorData = AnchorData[self]

	local msg
	if (self:IsScalable() and not compare(anchorData.scale, anchorData.defaultScale)) then
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f ( %.2f )|r", anchorData.currentPosition[1], anchorData.currentPosition[2], anchorData.currentPosition[3], anchorData.scale)
	else
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f|r", unpack(anchorData.currentPosition))
	end

	if (self.isSelected) then -- self:IsMouseOver(20,-20,-20,20)
		if (self:IsInDefaultPosition()) then
			msg = msg .. Colors.green.colorCode.."\n<Left-Click and drag to move>|r"
			if (self:IsScalable() and compare(anchorData.scale, anchorData.defaultScale)) then
				msg = msg .. Colors.green.colorCode.."\n<MouseWheel to change scale>|r"
			end
		else
			if (self:HasMovedSinceLastUpdate()) then
				msg = msg .. Colors.green.colorCode.."\n<Right-Click to undo last change>|r"
			end
			msg = msg .. Colors.green.colorCode.."\n<Shift-Click to reset to default>|r"
		end
		self.Title:Hide()
		self.Text:Show()
	else
		self.Title:Show()
		self.Text:Hide()
	end

	self.Text:SetText(msg)
	if (self:IsDragging()) then
		self.Text:SetTextColor(unpack(Colors.normal))
	else
		self.Text:SetTextColor(unpack(Colors.highlight))
	end
end

Anchor.UpdateLayoutInfo = function(self, layoutName)

	if (self.Callback) then
		self:Callback("LayoutsUpdated", layoutName)
	end
end

Anchor.UpdatePosition = function(self, layoutName, point, x, y)
	local anchorData = AnchorData[self]

	anchorData.currentPosition = { point, x, y }

	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	if (self.Callback) then
		self:Callback("PositionUpdated", layoutName, point, x, y)
	end
end

Anchor.UpdateScale = function(self, layoutName, scale)
	local anchorData = AnchorData[self]
	if (anchorData.scale == scale) then return end

	anchorData.scale = scale

	if (anchorData.width and anchorData.height) then
		self:SetSizeBase(anchorData.width * anchorData.scale, anchorData.height * anchorData.scale)
		self:UpdateText()
	end

	if (self.Callback) then
		self:Callback("ScaleUpdated", LAYOUT, scale)
	end
end

-- Anchor Getters
--------------------------------------
Anchor.GetPosition = function(self)
	return unpack(AnchorData[self].currentPosition)
end

Anchor.GetScale = function(self)
	return AnchorData[self].scale
end

-- Anchor Setters
--------------------------------------
Anchor.SetEditModeAccountSetting = function(self, setting)
	self.editModeAccountSetting = setting
end

-- Scale can still be set and changed,
-- this setting only toggles mousewheel input.
Anchor.SetScalable = function(self, scalable)
	if (scalable) then
		AnchorData[self].isScalable = true
		self:EnableMouseWheel(true)
	else
		AnchorData[self].isScalable = nil
		self:EnableMouseWheel(false)
	end
end

-- Scale can be outside these bounds,
-- they don't even need to exist.
-- This is only for mousewheel input.
Anchor.SetMinMaxScale = function(self, min, max, step)
	local anchorData = AnchorData[self]
	anchorData.minScale = min
	anchorData.maxScale = max
	anchorData.scaleStep = step
end

Anchor.SetDefaultScale = function(self, scale)
	AnchorData[self].defaultScale = scale
end

Anchor.SetDefaultPosition = function(self, point, x, y)
	AnchorData[self].defaultPosition = { point, x, y }
end

-- Don't scale, just size based on it.
Anchor.SetBaseScale = mt.SetScale
Anchor.SetScale = function(self, scale)
	self:UpdateScale(LAYOUT, scale)
end

Anchor.SetSizeBase = mt.SetSize
Anchor.SetSize = function(self, width, height)
	local anchorData = AnchorData[self]
	anchorData.width, anchorData.height = width, height
	self:SetSizeBase(width * anchorData.scale, height * anchorData.scale)
end

Anchor.SetWidthBase = mt.SetWidth
Anchor.SetWidth = function(self, width)
	local anchorData = AnchorData[self]
	anchorData.width = width
	self:SetWidthBase(width * anchorData.scale)
end

Anchor.SetHeightBase = mt.SetHeight
Anchor.SetHeight = function(self, height)
	local anchorData = AnchorData[self]
	anchorData.height = height
	self:SetHeightBase(height * anchorData.scale)
end

Anchor.SetPointBase = mt.SetPoint
Anchor.SetPoint = function(self, ...)

	-- Set the raw point to what the user has decided.
	self:SetPointBase(...)

	-- Parse the position.
	local point, x, y = getPosition(self)

	-- Reset the position to our system.
	self:UpdatePosition(LAYOUT, point, x, y)

	-- Set this as the default position
	-- if none has been registered so far.
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then
		anchorData.defaultPosition = { point, x, y }
	end
end

Anchor.SetTitle = function(self, title)
	self.Title:SetText(title)
end

-- Anchor Script Handlers
--------------------------------------
Anchor.OnClick = function(self, button)
	if (button == "LeftButton") then
		if (CURRENT) then
			CURRENT.isSelected = nil
			CURRENT:OnLeave()
			--CURRENT:UpdateText()
		end
		CURRENT = self
		self.isSelected = true
		self:OnEnter()
		--self:UpdateText()
		self:SetFrameLevel(60)
		if (IsShiftKeyDown() and not self:IsInDefaultPosition()) then
			self:ResetToDefault()
		end
	elseif (button == "RightButton") then
		self:SetFrameLevel(40)
		if (self:HasMovedSinceLastUpdate()) then
			self:ResetLastChange()
		end
	end
end

Anchor.OnMouseWheel = function(self, delta)
	local anchorData = AnchorData[self]
	local scale = anchorData.scale
	local step = anchorData.scaleStep or .1
	if (delta > 0) then
		if ((scale + step) > anchorData.maxScale) then
			scale = anchorData.maxScale
		else
			scale = scale + step
		end
	elseif (delta < 0) then
		if ((scale - step) < anchorData.minScale) then
			scale = anchorData.minScale
		else
			scale = scale - step
		end
	end
	self:SetScale(scale)
end

Anchor.OnDragStart = function(self, button)
	self:StartMoving()
	self:SetUserPlaced(false)
	self.elapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)
end

Anchor.OnDragStop = function(self)
	local anchorData = AnchorData[self]

	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = getPosition(self)

	anchorData.currentPosition = { getPosition(self) }

	self:UpdatePosition(LAYOUT, point, x, y)
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
	local anchorData = AnchorData[self]
	local point, x, y = getPosition(self)

	anchorData.lastScale = anchorData.scale
	anchorData.lastPosition = { point, x, y }
	anchorData.currentPosition = { point, x, y }

	self:SetFrameLevel(50)
	self:SetAlpha(.75)
	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	if (self.Callback) then
		self:Callback("AnchorShown", LAYOUT, point, x, y)
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

	local anchorData = AnchorData[self]
	local point, x, y = getPosition(self)

	-- Reuse old table here,
	-- or we'll spam the garbage handler.
	anchorData.currentPosition[1] = point
	anchorData.currentPosition[2] = x
	anchorData.currentPosition[3] = y

	self:UpdateText()

	if (self.Callback) then
		self:Callback("Dragging", LAYOUT, point, x, y)
	end
end

-- Public API
--------------------------------------
local editModeActive

Widgets.RequestMovableFrameAnchor = function()
	return Anchor:Create()
end

Widgets.UpdateMovableFrameAnchors = function(requestedByEditMode)
	if (requestedByEditMode) then
		editModeActive = true
	end
	for anchor in next,AnchorData do
		if (anchor.editModeAccountSetting) then
			if (EditModeManagerFrame:GetAccountSettingValueBool(anchor.editModeAccountSetting)) then
				if (anchor:IsEnabled()) then
					anchor:Show()
				end
			else
				anchor:Hide()
			end
		else
			if (anchor:IsEnabled()) then
				anchor:Show()
			end
		end
	end
end

Widgets.HideMovableFrameAnchors = function(requestedByEditMode)
	if (requestedByEditMode) then
		editModeActive = false
	end
	for anchor in next,AnchorData do
		anchor:Hide()
	end
end

-- Private event frame
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandler:RegisterEvent("PLAYER_REGEN_DISABLED")
eventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
eventHandler:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
eventHandler:SetScript("OnEvent", function(self, event, ...)

	if (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		local layoutInfo = ...
		local layoutName = layoutNames[layoutInfo.activeLayout]
		LAYOUT = layoutName
		for anchor in next,AnchorData do
			anchor:UpdateLayoutInfo(layoutName) -- let modules reposition
			anchor:OnShow() -- update anchor, don't show
		end

	elseif (event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
		local layoutInfo = C_EditMode.GetLayouts()
		local layoutName = layoutNames[layoutInfo.activeLayout]
		LAYOUT = layoutName
		for anchor in next,AnchorData do
			anchor:UpdateLayoutInfo(layoutName) -- let modules reposition
			anchor:OnShow() -- update anchor, don't show
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		for anchor in next,AnchorData do
			if (anchor.Callback) then
				if (anchor:IsShown()) then
					anchor:Callback("CombatStart", LAYOUT)
				end
			end
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end

		for anchor in next,AnchorData do
			if (anchor.Callback) then
				if (anchor:IsShown()) then
					anchor:Callback("CombatEnd", LAYOUT)
				end
			end
		end

	end
end)

hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() Widgets:UpdateMovableFrameAnchors(true) end)
hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()  Widgets:HideMovableFrameAnchors(true) end)
hooksecurefunc(EditModeManagerFrame, "OnAccountSettingChanged", function() Widgets:UpdateMovableFrameAnchors() end )
