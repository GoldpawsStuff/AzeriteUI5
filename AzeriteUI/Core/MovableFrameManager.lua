--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local MovableFramesManager = ns:NewModule("MovableFramesManager", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Lua API
local error = error
local getmetatable = getmetatable
local math_abs = math.abs
local math_floor = math.floor
local next = next
local pairs = pairs
local rawget = rawget
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_match = string.match
local table_insert = table.insert
local table_sort = table.sort
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

-- GLOBALS: CreateFrame, UIParent, WorldFrame

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Constants & Flags
local SCALE = UIParent:GetScale() -- current blizzard scale
local CURRENT -- currently selected anchor frame
local HOVERED -- currently mouseovered anchor frame

-- Outline frame for mouseover events.
local OUTLINE = CreateFrame("Frame", nil, UIParent, ns.BackdropTemplate)
OUTLINE:SetBackdrop({ edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16, insets = { left = 5, right = 3, top = 3, bottom = 5 } })
OUTLINE:SetBackdropBorderColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75)
OUTLINE:SetFrameStrata("HIGH")
OUTLINE:SetFrameLevel(10000)

-- Anchor cache
local AnchorData = {}
local AnchorProxies = {}

-- Utility
--------------------------------------
-- Compare two scales or two positions.
local compare = function(...)
	local numArgs = select("#", ...)
	if (numArgs == 2) then
		local s, s2 = ...
		return (math_abs(s - s2) < (diff or 0.01))
	else
		local point, x, y, point2, x2, y2, diff = ...
		return (point == point2) and (math_abs(x - x2) < (diff or 0.01)) and (math_abs(y - y2) < (diff or 0.01))
	end
end

-- Get a properly parsed position of a frame,
-- relative to UIParent and the frame's scale.
local getPosition = function(frame, point)

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

	-- Has this frame requested a specific anchor point?
	-- If so, calculate the coordinates relative to it,
	-- regardless of its position on-screen.
	if (point) then
		if (point == "TOPLEFT") then
			return "TOPLEFT", left / frameScale, top / frameScale

		elseif (point == "TOP") then
			return "TOP", (x - uiWidth/2) / frameScale, top / frameScale

		elseif (point == "TOPRIGHT") then
			return "TOPRIGHT", right / frameScale, top / frameScale

		elseif (point == "RIGHT") then
			return "RIGHT", right / frameScale, (y - uiHeight/2) / frameScale

		elseif (point == "BOTTOMRIGHT") then
			return "BOTTOMRIGHT", right / frameScale, bottom / frameScale

		elseif (point == "BOTTOM") then
			return "BOTTOM", (x - uiWidth/2) / frameScale, bottom / frameScale

		elseif (point == "BOTTOMLEFT") then
			return "BOTTOMLEFT", left / frameScale, bottom / frameScale

		elseif (point == "LEFT") then
			return "LEFT", left / frameScale, (y - uiHeight/2) / frameScale

		elseif (point == "CENTER") then
			return "CENTER", (x - uiWidth/2) / frameScale, (y - uiHeight/2) / frameScale
		end
	end

	-- Figure out the point within the given coordinate space,
	-- return values converted to the frame's own scale.
	--[[
	                  1/3             2/3
	        _______________________________________ uiWidth, uiHeight
	        | TOPLEFT  |     TOP       | TOPRIGHT |
	        |__________|_______________|__________| 3/4
	        |      1/4      CENTER       3/4      |
	        | LEFT  |                     | RIGHT |
	        |       |_________1/3_________|       |
	        |_______|__                 __|_______| 1/4
	        | BOTTOM   |    BOTTOM     |   BOTTOM |
	        |_LEFT_____|_______________|____RIGHT_|
		0,0

	--]]

	-- Top Row
	if (y > uiHeight * 3/4) then

		-- Top Left
		if (x < uiWidth * 1/3) then
			return "TOPLEFT", left / frameScale, top / frameScale

		-- Top Right
		elseif (x > uiWidth * 2/3) then
			return "TOPRIGHT", right / frameScale, top / frameScale

		-- Top Center
		else
			return "TOP", (x - uiWidth/2) / frameScale, top / frameScale
		end

	-- Mid & Bottom Segments
	else

		-- Mid to Bottom Left Columns
		if (x < uiWidth * 1/4) then

			-- Mid Left
			if (y > uiHeight * 1/4) then
				return "LEFT", left / frameScale, (y - uiHeight/2) / frameScale

			-- Bottom Left
			else
				return "BOTTOMLEFT", left / frameScale, bottom / frameScale
			end

		-- Mid to Bottom Right Columns
		elseif (x > uiWidth * 3/4) then

			-- Mid Right
			if (y > uiHeight * 1/4) then
				return "RIGHT", right / frameScale, (y - uiHeight/2) / frameScale

			-- Bottom Right
			else
				return "BOTTOMRIGHT", right / frameScale, bottom / frameScale
			end

		-- Mid and Bottom Center Columns
		else

			-- Center
			if (y > uiHeight * 1/3) then
				return "CENTER", (x - uiWidth/2) / frameScale, (y - uiHeight/2) / frameScale

			-- Bottom Center Segment
			else

				-- Bottom Left
				if (x < uiWidth * 1/3) then
					return "BOTTOMLEFT", left / frameScale, bottom / frameScale

				-- Bottom Right
				elseif (x > uiWidth * 2/3) then
					return "BOTTOMRIGHT", right / frameScale, bottom / frameScale

				-- Bottom Center
				else
					return "BOTTOM", (x - uiWidth/2) / frameScale, bottom / frameScale
				end
			end

		end

	end

end

-- Create frame backdrop
local createBackdropFrame = function(frame)
	local backdrop = CreateFrame("Frame", nil, frame, ns.BackdropTemplate)
	backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", -10, 10)
	backdrop:SetPoint("BOTTOMRIGHT", 10, -10)
	backdrop:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	})
	backdrop:SetBackdropColor(.05, .05, .05, .95)

	return backdrop
end

-- Anchor Template
--------------------------------------
local mt = getmetatable(CreateFrame("Button")).__index
local Anchor = {}

-- Constructor
Anchor.Create = function(self)

	local anchor = CreateFrame("Button", nil, UIParent)
	anchor:Hide()
	anchor:SetFrameStrata("HIGH")
	anchor:SetFrameLevel(1000)
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(false)
	anchor:RegisterForDrag("LeftButton")
	anchor:RegisterForClicks("AnyUp")
	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnMouseWheel", Anchor.OnMouseWheel)
	anchor:SetScript("OnClick", Anchor.OnClick)
	anchor:SetScript("OnShow", Anchor.OnShow)
	anchor:SetScript("OnHide", Anchor.OnHide)
	anchor:SetScript("OnEnter", Anchor.OnEnter)
	anchor:SetScript("OnLeave", Anchor.OnLeave)

	for method,func in next,Anchor do
		anchor[method] = func
	end

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

	local r, g, b = unpack(Colors.anchor.general)
	overlay:SetBackdropColor(r, g, b, .75)
	overlay:SetBackdropBorderColor(r, g, b, 1)

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
	title:SetAlpha(.5)
	anchor.Title = title

	AnchorData[anchor] = {
		isMovable = true,
		isScalable = true,
		scale = ns.API.GetEffectiveScale(),
		defaultScale = ns.API.GetEffectiveScale(),
		minScale = .25,
		maxScale = 2.5,
		scaleStep = .1,
		lockAnchorPoint = false,
		colorGroup = "general"
	}

	AnchorProxies[overlay] = AnchorData[anchor]

	anchor:Enable()

	return anchor
end

Anchor.Enable = function(self)
	self.enabled = true
	if (MovableFramesManager:IsMFMFrameOpen()) then
		MovableFramesManager:UpdateMovableFrameAnchors()
	end
end

Anchor.Disable = function(self)
	self.enabled = false
	self:Hide()
end

Anchor.IsEnabled = function(self)
	return self.enabled
end

Anchor.SetEnabled = function(self, enable)
	self.enabled = enable and true or false
end

-- 'true' if the frame is in its default position and scale.
Anchor.IsInDefaultPosition = function(self, diff)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end
	local point2, x2, y2 = self:GetParsedDefaultPosition() -- unpack(anchorData.defaultPosition)
	local point, x, y = getPosition(self, point2) -- compare with same anchor point

	return compare(anchorData.scale, anchorData.defaultScale) and compare(point, x, y, point2, x2, y2, diff)
end

-- 'true' if the frame can be scaled.
Anchor.IsScalable = function(self)
	return AnchorData[self].isScalable
end

-- 'true' if the frame can be moved.
Anchor.IsMovableBase = mt.IsMovable
Anchor.IsMovable = function(self)
	return AnchorData[self].isMovable
end

-- 'true' if set to always obey the same anchor point.
Anchor.IsAnchorPointLocked = function(self)
	return AnchorData[self].lockAnchorPoint and true or false
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

	self:UpdateScale(anchorData.lastScale or anchorData.scale or anchorData.defaultScale)
	self:UpdatePosition(point, x, y)
	self:UpdateText()

	ns:Fire("MFM_PositionUpdated", self, point, x, y, anchorData.scale)
end

-- Reset to default position.
Anchor.ResetToDefault = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end

	local point, x, y = self:GetParsedDefaultPosition() -- unpack(anchorData.defaultPosition)

	anchorData.currentPosition = { point, x, y }
	anchorData.lastPosition = { point, x, y }

	self:UpdateScale(anchorData.defaultScale)
	self:UpdatePosition(point, x, y)
	self:UpdateText()

	ns:Fire("MFM_PositionUpdated", self, point, x, y, anchorData.scale)
end

Anchor.UpdateText = function(self)
	local anchorData = AnchorData[self]

	if (not anchorData.currentPosition) then return end

	local msg
	if (self:IsScalable()) then
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f ( %.2f )|r", anchorData.currentPosition[1], anchorData.currentPosition[2], anchorData.currentPosition[3], anchorData.scale)
	else
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f|r", unpack(anchorData.currentPosition))
	end

	if (ns.IsCata or ns.IsRetail) then
		local width,height = self:GetSize()
		if (width/height < .8) and (width > 100) then
			self.Text:SetRotation(-math.pi/2)
			self.Title:SetRotation(-math.pi/2)
		else
			self.Text:SetRotation(0)
			self.Title:SetRotation(0)
		end
	end

	if (self.isSelected) then
		if (self:IsInDefaultPosition()) then
			if (self:IsMovable()) then
				msg = msg .. Colors.green.colorCode.."\n"..L["<Left-Click and drag to move>"].."|r"
			end
			if (self:IsScalable()) then
				msg = msg .. Colors.green.colorCode.."\n"..L["<MouseWheel to change scale>"].."|r"
			end
		else
			if (self:HasMovedSinceLastUpdate()) then
				msg = msg .. Colors.green.colorCode.."\n"..L["<Ctrl and Right-Click to undo last change>"].."|r"
			end
			msg = msg .. Colors.green.colorCode.."\n"..L["<Shift-Click to reset to default>"].."|r"
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

Anchor.UpdatePosition = function(self, point, x, y)
	local anchorData = AnchorData[self]

	anchorData.currentPosition = { point, x, y }

	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	self.Overlay:SetSize(self:GetSize())
	self.Overlay:ClearAllPoints()
	self.Overlay:SetPoint(point, UIParent, point, x, y)

	ns:Fire("MFM_PositionUpdated", self, point, x, y, anchorData.scale)
end

Anchor.UpdateScale = function(self, scale)
	local anchorData = AnchorData[self]
	if (anchorData.scale == scale) then return end

	anchorData.scale = scale

	if (anchorData.width and anchorData.height) then
		self:SetSizeBase(anchorData.width * anchorData.scale, anchorData.height * anchorData.scale)
		self:UpdateText()

		self.Overlay:SetSize(self:GetSize())
		self.Overlay:ClearAllPoints()
		self.Overlay:SetPoint(self:GetPoint())
	end

	ns:Fire("MFM_ScaleUpdated", self, anchorData.scale)
end

-- Anchor Getters
--------------------------------------
Anchor.GetPosition = function(self)
	local anchorData = AnchorData[self]

	if (not anchorData.currentPosition) then return end

	return anchorData.currentPosition[1], anchorData.currentPosition[2], anchorData.currentPosition[3]
end

Anchor.GetScale = function(self)
	return AnchorData[self].scale
end

Anchor.GetDefaultScale = function(self, scale)
	return AnchorData[self].defaultScale
end

Anchor.GetDefaultPosition = function(self)
	return AnchorData[self].defaultPosition[1], AnchorData[self].defaultPosition[2], AnchorData[self].defaultPosition[3]
end

local dummy = CreateFrame("Frame", nil, UIParent)
dummy:Hide()

Anchor.GetParsedDefaultPosition = function(self)
	local anchorData = AnchorData[self]
	local point, x, y = unpack(anchorData.defaultPosition)

	dummy:Show()
	dummy:ClearAllPoints()
	dummy:SetPoint(point, x, y)
	dummy:SetSize(self:GetSize())

	AnchorProxies[dummy] = anchorData

	point, x, y = getPosition(dummy, point) -- keep relative to default point

	dummy:Hide()

	AnchorProxies[dummy] = nil

	return point, x, y
end

Anchor.GetColorGroup = function(self)
	return AnchorData[self].colorGroup or "general"
end


-- Anchor Setters
--------------------------------------
Anchor.RestrictToHorizontal = function(self)
	AnchorData[self].restrictToHorizontal = true
	AnchorData[self].restrictToVertical = nil
end

Anchor.RestrictToVertical = function(self)
	AnchorData[self].restrictToHorizontal = nil
	AnchorData[self].restrictToVertical = true
end

Anchor.Unrestrict = function(self)
	AnchorData[self].restrictToHorizontal = nil
	AnchorData[self].restrictToVertical = nil
end

Anchor.SetAnchorPointLocked = function(self, isLocked)
	AnchorData[self].lockAnchorPoint = isLocked and true or false
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

Anchor.SetMovableBase = mt.SetMovable
Anchor.SetMovable = function(self, movable)
	if (movable) then
		AnchorData[self].isMovable = true
	else
		AnchorData[self].isMovable = nil
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
	self:UpdateScale(scale)
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
	self:SetHitRectInsets(width < 20 and -10 or 0, width < 20 and -10 or 0, height < 20 and -10 or 0, height < 20 and -10 or 0)
end

Anchor.SetHeightBase = mt.SetHeight
Anchor.SetHeight = function(self, height)
	local anchorData = AnchorData[self]
	anchorData.height = height
	self:SetHeightBase(height * anchorData.scale)
	self:SetHitRectInsets(width < 20 and -10 or 0, width < 20 and -10 or 0, height < 20 and -10 or 0, height < 20 and -10 or 0)
end

Anchor.SetPointBase = mt.SetPoint
Anchor.SetPoint = function(self, ...)

	-- Set the raw point to what the user has decided.
	self:SetPointBase(...)

	-- Parse the position.
	local point, x, y = getPosition(self, (self:IsAnchorPointLocked() and self:GetPosition()))

	-- Reset the position to our system.
	self:UpdatePosition(point, x, y)

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

Anchor.SetColorGroup = function(self, colorGroup)

	AnchorData[self].colorGroup = colorGroup and Colors.anchor[colorGroup] and colorGroup or "general"

	local r, g, b = unpack(Colors.anchor[AnchorData[self].colorGroup])
	self.Overlay:SetBackdropColor(r, g, b, .75)
	self.Overlay:SetBackdropBorderColor(r, g, b, 1)
end


-- Anchor Script Handlers
--------------------------------------
Anchor.OnClick = function(self, button)
	if (self.PreClick) then
		self:PreClick(button)
	end

	if (button == "LeftButton") then
		if (CURRENT) then
			CURRENT.isSelected = nil
			CURRENT:OnLeave()
		end
		CURRENT = self

		self.isSelected = true
		self:OnEnter()
		self:SetFrameLevel(60)

		if (IsShiftKeyDown() and not self:IsInDefaultPosition()) then
			self:ResetToDefault()
		end

		MovableFramesManager:RefreshMFMFrame()

	elseif (button == "RightButton") then
		if (CURRENT and CURRENT == self) then
			CURRENT = nil
			self.isSelected = nil
			self:OnLeave()

			MovableFramesManager:RefreshMFMFrame()
		end
		self:SetFrameLevel(40)

		if (IsControlKeyDown() and self:HasMovedSinceLastUpdate()) then
			self:ResetLastChange()
		end
	end

	if (self.PostClick) then
		self:PostClick(button)
	end
end

Anchor.OnMouseWheel = function(self, delta)
	if (not self.isSelected) then return end

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

	MovableFramesManager:RefreshMFMFrame()
end

Anchor.OnDragStart = function(self, button)
	local anchorData = AnchorData[self]
	if (not anchorData.isMovable) then return end

	local w, h = self:GetSize()
	local fx, fy = self:GetCenter()
	local frameScale = self:GetEffectiveScale()

	--fx = fx * frameScale
	--fy = fy * frameScale

	anchorData.dragStartPosition = { fx - (w/2), fy - (h/2) }
	--anchorData.dragStartPosition = { fx - (w/2)*frameScale, fy - (h/2)*frameScale }

	-- Treat the dragged frame as clicked.
	if (CURRENT) then
		CURRENT.isSelected = nil
		CURRENT:OnLeave()
	end

	CURRENT = self

	self.isSelected = true
	self:OnEnter()
	self:SetFrameLevel(60)

	-- Start the drag handler.
	self:StartMoving()
	self:SetUserPlaced(false)
	self.elapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)

	anchorData.hasMoved = true

	MovableFramesManager:RefreshMFMFrame()
end

Anchor.UpdateOverlay = function(self)
	local anchorData = AnchorData[self]

	local w, h = self:GetSize()
	local frameScale = self:GetEffectiveScale()
	local fx, fy = GetCursorPosition()
	fx = fx / frameScale
	fy = fy / frameScale

	fx = anchorData.restrictToVertical and anchorData.dragStartPosition[1] or (fx - (w/2))
	fy = anchorData.restrictToHorizontal and anchorData.dragStartPosition[2] or (fy - (h/2))

	self.Overlay:SetSize(w,h)
	self.Overlay:ClearAllPoints()
	self.Overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", fx, fy)

end

Anchor.OnDragStop = function(self)
	local anchorData = AnchorData[self]

	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)
	--self:UpdateOverlay()

	local point, x, y = getPosition(self.Overlay, (self:IsAnchorPointLocked() and self:GetPosition()))

	anchorData.currentPosition = { point, x, y }

	self:UpdatePosition(point, x, y)

	MovableFramesManager:RefreshMFMFrame()
end

Anchor.OnEnter = function(self)
	if (HOVERED ~= self) then
		HOVERED = self
		OUTLINE:ClearAllPoints()
		OUTLINE:SetAllPoints(self.Overlay)
		OUTLINE:Show()
	end
	self:SetAlpha(.75)
	self.Title:SetTextColor(unpack(Colors.normal))
	self.Title:SetAlpha(1)
	self:UpdateText()
end

Anchor.OnLeave = function(self)
	if (HOVERED == self) then
		HOVERED = nil
		OUTLINE:ClearAllPoints()
		OUTLINE:Hide()
	end
	self.Title:SetTextColor(unpack(Colors.highlight))
	self.Title:SetAlpha(.5)
	self:SetAlpha(.25)
	self:UpdateText()
end

Anchor.OnShow = function(self)
	-- Allow modules to position anchor correctly.
	if (self.PreUpdate) then
		self:PreUpdate()
	end

	local anchorData = AnchorData[self]
	local point, x, y = getPosition(self, (self:IsAnchorPointLocked() and self:GetPosition()))

	anchorData.lastScale = anchorData.scale
	anchorData.lastPosition = { point, x, y }
	anchorData.currentPosition = { point, x, y }

	self:SetFrameLevel(50)
	self:SetAlpha(.5)
	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	self.Overlay:SetSize(self:GetSize())
	self.Overlay:ClearAllPoints()
	self.Overlay:SetPoint(point, UIParent, point, x, y)

	ns:Fire("MFM_AnchorShown", self, point, x, y)
end

Anchor.OnHide = function(self)
	self:SetScript("OnUpdate", nil)
	self.elapsed = 0
end

Anchor.OnUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if (self.elapsed < .05) then
		return
	end
	self.elapsed = 0
	self:UpdateOverlay()

	local point, x, y = getPosition(self.Overlay, (self:IsAnchorPointLocked() and self:GetPosition()))

	-- Reuse old table here,
	-- or we'll spam the garbage handler.
	local anchorData = AnchorData[self]
	anchorData.currentPosition[1] = point
	anchorData.currentPosition[2] = x
	anchorData.currentPosition[3] = y

	self:UpdateText()

	ns:Fire("MFM_Dragging", self, point, x, y)
end

-- Module API
--------------------------------------
MovableFramesManager.RequestAnchor = function(self, ...)
	return Anchor:Create(...)
end

MovableFramesManager.GenerateMFMFrame = function(self)
	if (self.appName and AceConfigRegistry:GetOptionsTable(self.appName)) then
		return
	end

	local Options = ns:GetModule("Options", true)
	if (not Options) then return end

	local noselection = function(info)
		return not CURRENT
	end

	local hasselection = function(info)
		return CURRENT
	end

	local getter = function(info)
		if (not CURRENT) then return end

		local point, x, y = CURRENT:GetPosition()
		local scale = CURRENT:GetScale()

		local arg = info[#info]
		if (arg == "point") then
			return point

		elseif (arg == "offsetX") then
			return tostring(math_floor(x * 1000 + .5)/1000)

		elseif (arg == "offsetY") then
			return tostring(math_floor(y * 1000 + .5)/1000)

		elseif (arg == "scale") then
			return tostring(math_floor(scale * 1000 + .5)/1000)
		elseif (arg == "lockAnchorPoint") then
			return AnchorData[CURRENT].lockAnchorPoint
		end
	end

	local setter = function(info,val)
		if (not CURRENT) then return end

		local point, x, y = CURRENT:GetPosition()
		local scale = CURRENT:GetScale()

		local arg = info[#info]
		if (arg == "point") then

			if (CURRENT:IsAnchorPointLocked()) then
				point, x, y = getPosition(CURRENT, val)

				CURRENT:UpdatePosition(point, x, y)
			else
				point = val
			end

		elseif (arg == "offsetX") then

			local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
			if (not val) then return end

			x = val

		elseif (arg == "offsetY") then

			local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
			if (not val) then return end

			y = val

		elseif (arg == "scale") then
			local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
			if (not val) then return end

			scale = val

		elseif (arg == "lockAnchorPoint") then
			CURRENT:SetAnchorPointLocked(val and true or false)
		end

		CURRENT:ClearAllPoints()
		CURRENT:SetPoint(point, x, y)
		CURRENT:SetScale(scale)
	end

	local validate = function(info,val)
		local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
		if (val) then return true end
		return L["Only numbers are allowed."]
	end

	local options, orderoffset = Options:GenerateProfileMenu()
	orderoffset = orderoffset + 30

	-- Export/import positions.
	if (ns.IsDevelopment and ns.db.global.enableDevelopmentMode) then
		options.args.framePositionsHeader = {
			name = "Layouts",
			order = orderoffset + 1,
			type = "header",
			disabled = function(info) return true end
		}
		options.args.framePositionsExport = {
			name = "Export Layout",
			desc = "Expert the current frame positions to a string you can copy and share with other people.",
			type = "execute",
			order = orderoffset + 2,
			disabled = function(info) return true end,
			func = function(info) end
		}

		options.args.framePositionsImport = {
			name = "Import Layout",
			desc = "Import frame positions from a string into the current options profile.",
			type = "execute",
			order = orderoffset + 3,
			disabled = function(info) return true end,
			func = function(info) end
		}
		options.args.framePositionsSpace = {
			name = "", order = orderoffset + 4, type = "description"
		}

		orderoffset = orderoffset + 10
	end

	-- Frame positioning & scaling.
	options.args.frameSelectionHeader = {
		name = function(info)
			return CURRENT and CURRENT.Title:GetText() or L["Current Frame"]
		end,
		order = orderoffset + 10,
		type = "header",
		--hidden = noselection
	}
	options.args.frameSelection = {
		name = L["Select Frame"],
		order = orderoffset + 11,
		type = "select", style = "dropdown",
		-- Create a table of currently enabled anchors,
		-- use their titles as display names.
		values = function(info)
			local values = { ["N/A"] = L["Nothing Selected"] }
			for anchor in next,AnchorData do
				if (anchor:IsEnabled()) then
					local title = anchor.Title:GetText()
					if (title and title ~= "") then
						values[anchor] = title
					end
				end
			end
			return values
		end,
		-- Create a sorted table of the frame display names.
		sorting = function(info)
			local sorted = {}
			for anchor in next,AnchorData do
				if (anchor:IsEnabled()) then
					local title = anchor.Title:GetText()
					if (title and title ~= "") then
						table_insert(sorted, anchor)
					end
				end
			end
			table_sort(sorted, function(a,b)
				return a.Title:GetText() < b.Title:GetText()
			end)
			table_insert(sorted, 1, "N/A")
			return sorted
		end,
		set = function(info, val)
			if (val == "N/A") then
				if (CURRENT) then
					CURRENT.isSelected = nil
					CURRENT:OnLeave()
					CURRENT = nil

					MovableFramesManager:RefreshMFMFrame()
				end
			else
				val:OnClick("LeftButton")
			end
		end,
		get = function(info)
			if (CURRENT) then
				return CURRENT
			else
				return "N/A"
			end
		end
	}
	orderoffset = orderoffset + 20

	local colorize = function(msg)
		msg = string.gsub(msg, "<", "|cffffd200<")
		msg = string.gsub(msg, ">", ">|r")
		return msg
	end

	-- Guide text when nothing is selected.
	options.args.guideHeader = {
		name = L["Help"],
		order = orderoffset + 89,
		type = "header",
		hidden = hasselection
	}
	options.args.guideText1 = {
		name = colorize(L["<Left-Click> an anchor to select it and raise it."]),
		order = orderoffset + 90,
		type = "description",
		fontSize = "medium",
		hidden = hasselection
	}
	options.args.guideText2 = {
		name = colorize(L["<Right-Click> an anchor to deselect it and/or lower it."]),
		order = orderoffset + 91,
		type = "description",
		fontSize = "medium",
		hidden = hasselection
	}

	options.args.positionDesc = {
		name = L["Fine-tune the position."],
		order = orderoffset + 101,
		type = "description",
		fontSize = "medium",
		hidden = noselection
	}
	options.args.point = {
		name = L["Anchor Point"],
		desc = L["Sets the anchor point."],
		order = orderoffset + 110,
		hidden = noselection,
		type = "select", style = "dropdown",
		values = {
			["TOPLEFT"] = L["Top-Left Corner"],
			["TOP"] = L["Top Center"],
			["TOPRIGHT"] = L["Top-Right Corner"],
			["RIGHT"] = L["Middle Right Side"],
			["BOTTOMRIGHT"] = L["Bottom-Right Corner"],
			["BOTTOM"] = L["Bottom Center"],
			["BOTTOMLEFT"] = L["Bottom-Left Corner"],
			["LEFT"] = L["Middle Left Side"],
			["CENTER"] = L["Center"]
		},
		set = setter,
		get = getter
	}
	options.args.lockAnchorPoint = {
		name = "Lock Anchor Point",
		desc = "Forces the frame to always use this anchor point regardless of position on-screen.\n\nThis is useful if you wish a frame to always have a certain distance from a specific anchor point regardless of screen size, ratio or scale.\n\nWhen this option is chosen, changing anchor point does not move the frame, but rather recalculates the coordinates relative to that anchor point.",
		order = orderoffset + 111,
		hidden = noselection,
		type = "toggle",
		set = setter,
		get = getter
	}
	options.args.pointSpace = {
		name = "", order = orderoffset + 112, type = "description", hidden = noselection
	}
	options.args.offsetX = {
		name = L["X Offset"],
		desc = L["Sets the horizontal offset from your chosen anchor point. Positive values means right, negative values means left."],
		order = orderoffset + 120,
		type = "input",
		hidden = noselection,
		validate = validate,
		set = setter,
		get = getter
	}
	options.args.offsetY = {
		name = L["Y Offset"],
		desc = L["Sets the vertical offset from your chosen anchor point. Positive values means up, negative values means down."],
		order = orderoffset + 130,
		type = "input",
		hidden = noselection,
		validate = validate,
		set = setter,
		get = getter
	}
	options.args.scale = {
		name = L["Scale"],
		desc = L["Sets the relative scale of this element. Default scale is set to match the ideal size."],
		order = orderoffset + 140,
		type = "range", width = "full", min = 0.25 * 100, max = 2.5 * 100, step = 0.1, bigStep = 1,
		hidden = noselection,
		validate = validate,
		set = function(info,val)
			setter(info,tostring(val/100))
		end,
		get = function(info)
			return tonumber(getter(info)*100)
		end
	}

	self:SecureHook(self.app.frame, "Show", "UpdateMovableFrameAnchors")
	self:SecureHook(self.app.frame, "Hide", "HideMovableFrameAnchors")

	-- Hook into the blizzard function to close windows on Esc
	-- without tainting their table of special windows to close.
	-- Kindly borrowed this method from AceConfigDialog which also does it.
	if (not self.CloseSpecialWindows) then
		self.CloseSpecialWindows = CloseSpecialWindows
		CloseSpecialWindows = function()
			local found = self.CloseSpecialWindows()
			return self:CloseMFMFrame() or found
		end
	end

	AceConfigRegistry:RegisterOptionsTable(self.appName, options)

	return
end

MovableFramesManager.RefreshMFMFrame = function(self)
	if (AceConfigRegistry:GetOptionsTable(self.appName)) then
		if (self.app.frame:IsShown()) then
			-- When using a custom window for the dialog,
			-- the library's notify callback does not fire for it.
			-- So we need to fake a refresh by hiding and showing.
			if (self:IsHooked(self.app.frame, "Hide")) then
				self:Unhook(self.app.frame, "Hide")
			end
			self.app.frame:Hide()
			self:SecureHook(self.app.frame, "Hide", "HideMovableFrameAnchors")
			self:OpenMFMFrame()
		end
	end
end

MovableFramesManager.OpenMFMFrame = function(self)
	if (not AceConfigRegistry:GetOptionsTable(self.appName)) then
		self:GenerateMFMFrame()
	end
	AceConfigDialog:SetDefaultSize(self.appName, self.app.status.width, self.app.status.height)
	AceConfigDialog:Open(self.appName, self.app)
end

MovableFramesManager.CloseMFMFrame = function(self)
	if (not AceConfigRegistry:GetOptionsTable(self.appName)) then return end
	if (self.app.frame:IsShown()) then
		self.app.frame:Hide()
		return true -- prevents game menu from being shown
	end
end

MovableFramesManager.IsMFMFrameOpen = function(self)
	return self.app.frame:IsShown()
end

MovableFramesManager.ToggleMFMFrame = function(self)
	if (self.app.frame:IsShown()) then
		self:CloseMFMFrame()
	else
		self:OpenMFMFrame()
	end
end

MovableFramesManager.UpdateMovableFrameAnchors = function(self)
	for anchor in next,AnchorData do
		if (anchor:IsEnabled()) then
			anchor:Show()
		end
	end
end

MovableFramesManager.HideMovableFrameAnchors = function(self)
	if (not self.app.frame:IsShown()) then
		for anchor in next,AnchorData do
			anchor:Hide()
		end
	end
end

MovableFramesManager.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

		if (self:IsMFMFrameOpen()) then
			self:RefreshMFMFrame()
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self.incombat = nil

			if (self:IsMFMFrameOpen()) then
				self:RefreshMFMFrame()
			end
		end

	elseif (event == "PLAYER_ENTERING_WORLD") then
		self.incombat = InCombatLockdown()
	end

	if (event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED") then
		local scale = UIParent:GetScale()

		for anchor,anchorData in next,AnchorData do

			local anchorscale = anchor:GetScale()
			local point, x, y = anchor:GetPosition()

			local nscale = (anchorscale * SCALE) / scale
			local npoint, nx, ny = point, (x * SCALE) / scale, (y * SCALE) / scale

			anchor:SetScale(nscale)
			anchor:ClearAllPoints()
			anchor:SetPoint(npoint, nx, ny)

			anchorData.lastScale = nscale
			anchorData.lastPosition = { npoint, nx, ny }
			anchorData.currentPosition = { npoint, nx, ny }

			if (anchorData.defaultPosition) then
				local anchorscale = anchorData.defaultScale
				local point, x, y = anchorData.defaultPosition[1], anchorData.defaultPosition[2], anchorData.defaultPosition[3]

				local nscale = (anchorscale * SCALE) / scale
				local npoint, nx, ny = point, (x * SCALE) / scale, (y * SCALE) / scale

				anchorData.defaultPosition[1] = npoint
				anchorData.defaultPosition[2] = nx
				anchorData.defaultPosition[3] = ny
				anchorData.defaultScale = nscale
			end
		end

		SCALE = scale

		ns:Fire("MFM_UIScaleChanged")
	end
end

MovableFramesManager.OnInitialize = function(self)

	SCALE = UIParent:GetScale()

	local app = AceGUI:Create("Frame")
	app:Hide()
	app:SetStatusTable({
		width = 440,
		height = 580,
		left = 160,
		top = UIParent:GetTop() / 2 + 100
	})

	self.app = app
	self.appName = L["Movable Frames Manager"]

	self:RegisterChatCommand("lock", "ToggleMFMFrame")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
end
