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

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local MovableFramesManager = ns:NewModule("MovableFramesManager", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")
local EMP = ns:GetModule("EditMode", true)

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Lua API
local error = error
local getmetatable = getmetatable
local math_abs = math.abs
local math_floor = math.floor
local next = next
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

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local UIHider = ns.Hider

local SCALE = UIParent:GetScale() -- current blizzard scale
local DEFAULTLAYOUT = "Azerite" -- default layout name
local LAYOUT = DEFAULTLAYOUT -- currently selected layout preset
local CURRENT -- currently selected anchor frame
local HOVERED -- currently mouseovered anchor frame
local OUTLINE = CreateFrame("Frame", nil, UIParent, ns.BackdropTemplate) -- mouseover outline
OUTLINE:SetBackdrop({ edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16, insets = { left = 5, right = 3, top = 3, bottom = 5 } })
OUTLINE:SetBackdropBorderColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75)
OUTLINE:SetFrameStrata("HIGH")
OUTLINE:SetFrameLevel(10000)

-- Addon defaults. Don't change, does not affect what is saved.
local defaults = {
	char = {
		layout = DEFAULTLAYOUT
	}
}

-- Anchor cache
local AnchorData = {}

-- Utility
--------------------------------------
-- Parse any number of arguments for functions,
-- return the function result as the value,
-- or just the pass the value otherwise.
local get = function(...)
	local numArgs = select("#", ...)
	if (numArgs == "1") then
		return type(...) == "function" and (...)() or ...
	end
	local args = { ... }
	for i,val in ipairs(args) do
		local arg = select(i, ...)
		if (type(arg) == "function") then
			args[i] = arg()
		end
	end
	return unpack(args)
end

-- Compare two scales or two positions.
local compare = function(...)
	local numArgs = select("#", ...)
	if (numArgs == 2) then
		local s, s2 = get(...)
		return (math_abs(s - s2) < (diff or 0.01))
	else
		local point, x, y, point2, x2, y2, diff = get(...)
		return (point == point2) and (math_abs(x - x2) < (diff or 0.01)) and (math_abs(y - y2) < (diff or 0.01))
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

	-- How many sections to divide the screen into.
	local vertical = 1/3
	local horizontal = 1/4

	-- Figure out the point within the given coordinate space,
	-- return values converted to the frame's own scale.
	if (y < uiHeight * vertical) then
		if (x < uiWidth * horizontal) then
			return "BOTTOMLEFT", left / frameScale, bottom / frameScale
		elseif (x > uiWidth * (1 - horizontal)) then
			return "BOTTOMRIGHT", right / frameScale, bottom / frameScale
		else
			return "BOTTOM", (x - uiWidth/2) / frameScale, bottom / frameScale
		end
	elseif (y > uiHeight * (1 - vertical)) then
		if (x < uiWidth * horizontal) then
			return "TOPLEFT", left / frameScale, top / frameScale
		elseif x > uiWidth * (1 - horizontal) then
			return "TOPRIGHT", right / frameScale, top / frameScale
		else
			return "TOP", (x - uiWidth/2) / frameScale, top / frameScale
		end
	else
		if (x < uiWidth * horizontal) then
			return "LEFT", left / frameScale, (y - uiHeight/2) / frameScale
		elseif (x > uiWidth * (1 - horizontal)) then
			return "RIGHT", right / frameScale, (y - uiHeight/2) / frameScale
		else
			return "CENTER", (x - uiWidth/2) / frameScale, (y - uiHeight/2) / frameScale
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
	for method,func in next,Anchor do
		anchor[method] = func
	end

	anchor:Hide()
	anchor:Enable()
	anchor:SetFrameStrata("HIGH")
	anchor:SetFrameLevel(1000)
	anchor:SetMovable(true)
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
	anchor.Title = title

	AnchorData[anchor] = {
		hasMoved = false,
		--anchor = anchor,
		scale = ns.API.GetEffectiveScale(), -- we're doing this?
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
Anchor.IsInDefaultPosition = function(self, diff)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end
	local point, x, y = getPosition(self)
	local point2, x2, y2 = unpack(anchorData.defaultPosition)
	return compare(anchorData.scale, anchorData.defaultScale) and compare(point, x, y, point2, x2, y2, diff)
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

	self:UpdateScale(LAYOUT, get(anchorData.lastScale or anchorData.scale or anchorData.defaultScale))
	self:UpdatePosition(LAYOUT, point, x, y)
	self:UpdateText()

	ns:Fire("MFM_PositionUpdated", LAYOUT, self, point, x, y)
end

-- Reset to default position.
Anchor.ResetToDefault = function(self)
	local anchorData = AnchorData[self]
	if (not anchorData.defaultPosition) then return end

	local point, x, y = unpack(anchorData.defaultPosition)

	anchorData.currentPosition = { point, x, y }
	anchorData.lastPosition = { point, x, y }

	self:UpdateScale(LAYOUT, get(anchorData.defaultScale))
	self:UpdatePosition(LAYOUT, point, x, y)
	self:UpdateText()

	ns:Fire("MFM_PositionUpdated", LAYOUT, self, point, x, y)
end

Anchor.UpdateText = function(self)
	local anchorData = AnchorData[self]

	local msg
	if (self:IsScalable() and not compare(anchorData.scale, anchorData.defaultScale)) then
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f ( %.2f )|r", anchorData.currentPosition[1], anchorData.currentPosition[2], anchorData.currentPosition[3], anchorData.scale)
	else
		msg = string_format(Colors.highlight.colorCode.."%s, %.0f, %.0f|r", unpack(anchorData.currentPosition))
	end

	-- No texture rotation in Classic or TBC
	if (ns.IsWrath or ns.IsRetail) then
		local width,height = self:GetSize()
		if (width/height < .8) then
			self.Text:SetRotation(-math.pi/2)
			self.Title:SetRotation(-math.pi/2)
		else
			self.Text:SetRotation(0)
			self.Title:SetRotation(0)
		end
	end

	if (self.isSelected) then -- self:IsMouseOver(20,-20,-20,20)
		if (self:IsInDefaultPosition()) then
			msg = msg .. Colors.green.colorCode.."\n"..L["<Left-Click and drag to move>"].."|r"
			if (self:IsScalable()--[[ and compare(anchorData.scale, anchorData.defaultScale)]]) then
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

Anchor.UpdatePosition = function(self, layoutName, point, x, y)
	local anchorData = AnchorData[self]

	anchorData.currentPosition = { point, x, y }

	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	ns:Fire("MFM_PositionUpdated", layoutName, self, point, x, y)
end

Anchor.UpdateScale = function(self, layoutName, scale)
	local anchorData = AnchorData[self]
	if (anchorData.scale == scale) then return end

	anchorData.scale = scale

	if (anchorData.width and anchorData.height) then
		self:SetSizeBase(anchorData.width * get(anchorData.scale), anchorData.height * get(anchorData.scale))
		self:UpdateText()
	end

	ns:Fire("MFM_ScaleUpdated", layoutName, self, scale)
end

-- Anchor Getters
--------------------------------------
Anchor.GetPosition = function(self)
	return AnchorData[self].currentPosition[1], AnchorData[self].currentPosition[2], AnchorData[self].currentPosition[3]
end

Anchor.GetScale = function(self)
	return AnchorData[self].scale
end

Anchor.GetDefaultScale = function(self, scale)
	return get(AnchorData[self].defaultScale)
end

Anchor.GetDefaultPosition = function(self, point, x, y)
	return AnchorData[self].defaultPosition
end

-- Anchor Setters
--------------------------------------
-- Link the visibility of the anchor to an editmode account setting.
-- *The intention is to make anchors visible when the frame
-- we have replaced is selected in the editmode.
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
end

Anchor.OnDragStart = function(self, button)

	-- Treat the dragged frame as clicked.
	CURRENT = self
	self.isSelected = true
	self:OnEnter()
	self:SetFrameLevel(60)

	-- Start the drag handler.
	self:StartMoving()
	self:SetUserPlaced(false)
	self.elapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)

	AnchorData[self].hasMoved = true

	MovableFramesManager:RefreshMFMFrame()
end

Anchor.OnDragStop = function(self)
	local anchorData = AnchorData[self]

	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = getPosition(self)

	anchorData.currentPosition = { point, x, y }

	self:UpdatePosition(LAYOUT, point, x, y)

	MovableFramesManager:RefreshMFMFrame()
end

Anchor.OnEnter = function(self)
	if (HOVERED ~= self) then
		HOVERED = self
		OUTLINE:ClearAllPoints()
		OUTLINE:SetAllPoints(self)
		OUTLINE:Show()
	end
	self:SetAlpha(.75)
	self:UpdateText()
end

Anchor.OnLeave = function(self)
	if (HOVERED == self) then
		HOVERED = nil
		OUTLINE:ClearAllPoints()
		OUTLINE:Hide()
	end
	self:SetAlpha(.25)
	self:UpdateText()
end

Anchor.OnShow = function(self)
	-- Allow modules to position anchor correctly.
	if (self.PreUpdate) then
		self:PreUpdate()
	end

	local anchorData = AnchorData[self]
	local point, x, y = getPosition(self)

	anchorData.lastScale = anchorData.scale
	anchorData.lastPosition = { point, x, y }
	anchorData.currentPosition = { point, x, y }

	self:SetFrameLevel(50)
	self:SetAlpha(.5)
	self:ClearAllPoints()
	self:SetPointBase(point, UIParent, point, x, y)
	self:UpdateText()

	ns:Fire("MFM_AnchorShown", LAYOUT, self, point, x, y)
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

	ns:Fire("MFM_Dragging", LAYOUT, self, point, x, y)
end

local RequestMovableFrameAnchor = function(...)
	return Anchor:Create(...)
end

-- This needs to be updated on layout changes.
local UpdateMovableFrameAnchors = function()
	for anchor in next,AnchorData do
		-- Only hook anchor visibility to the editmode
		-- if the editmode manager frame is actually visible.
		if (ns.WoW10 and anchor.editModeAccountSetting and EditModeManagerFrame:IsShown()) then
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

local HideMovableFrameAnchors = function()
	for anchor in next,AnchorData do
		anchor:Hide()
	end
end

-- Module API
--------------------------------------
MovableFramesManager.RequestAnchor = function(self, ...)
	return RequestMovableFrameAnchor(...)
end

MovableFramesManager.PresetExists = function(self, layoutName)
	return layoutName and self.layouts[layoutName] and true or false
end

-- Register a preset name in our dropdown menu.
MovableFramesManager.RegisterPreset = function(self, layoutName)
	if (self.layouts[layoutName]) then return end

	-- Add the preset to our list.
	self.layouts[layoutName] = true

	-- Update the manager frame.
	--self:UpdateMFMFrame()
end

-- Register a table of layout names at once.
-- *The keys represent the layout names.
MovableFramesManager.RegisterPresets = function(self, layoutTable)
	for layoutName in pairs(layoutTable) do
		if (type(layoutName) == "string") then
			if (not self.layouts[layoutName]) then
				self:RegisterPreset(layoutName)
			end
		end
	end
end

-- Send a message to the modules to apply a saved preset.
-- Will switch to the preset in our dropdown menu.
MovableFramesManager.ApplyPreset = function(self, layoutName)
	if (layoutName == LAYOUT) then return end
	if (not self.layouts[layoutName]) then return end

	-- Switch currently selected preset.
	LAYOUT = layoutName

	-- Store the setting.
	self.db.char.layout = LAYOUT

	-- Send message to modules to switch to the selected preset.
	ns:Fire("MFM_LayoutsUpdated", LAYOUT)

	-- Update the manager frame.
	--self:UpdateMFMFrame()
end

-- Send a message to the modules to reset a saved preset.
MovableFramesManager.ResetPreset = function(self, layoutName)
	if (not self.layouts[layoutName]) then return end

	-- Send message to modules to reset the selected preset.
	ns:Fire("MFM_LayoutReset", LAYOUT)
end

-- Send a message to modules to delete a saved preset.
MovableFramesManager.DeletePreset = function(self, layoutName)
	if (layoutName == DEFAULTLAYOUT) then return end
	if (not self.layouts[layoutName]) then return end

	-- Check if preset is the current one,
	-- we'll have to swith to the default preset if it is.
	if (layoutName == LAYOUT) then

		-- Switch currently selected preset.
		LAYOUT = DEFAULTLAYOUT

		-- Store the setting.
		self.db.char.layout = LAYOUT

		-- Send message to modules to switch to the selected preset.
		ns:Fire("MFM_LayoutsUpdated", LAYOUT)
	end

	-- Remove from our preset list.
	self.layouts[layoutName] = nil

	-- Send message to all moduels to remove the selected preset.
	ns:Fire("MFM_LayoutDeleted", LAYOUT)

	-- Update the manager frame.
	--self:UpdateMFMFrame()
end

MovableFramesManager.GenerateMFMFrame = function(self)
	if (self.appName and AceConfigRegistry:GetOptionsTable(self.appName)) then
		return
	end

	local Options = ns:GetModule("Options", true)
	if (not Options) then return end

	local isdisabled = function(info)
		return not CURRENT
	end

	local getter = function(info)
		if (not CURRENT) then return end

		local point, x, y = CURRENT:GetPosition()

		local arg = info[#info]
		if (arg == "point") then
			return point

		elseif (arg == "offsetX") then
			return tostring(math_floor(x * 1000 + .5)/1000)

		elseif (arg == "offsetY") then
			return tostring(math_floor(y * 1000 + .5)/1000)
		end
	end

	local setter = function(info,val)
		if (not CURRENT) then return end

		local point, x, y = CURRENT:GetPosition()

		local arg = info[#info]
		if (arg == "point") then
			point = val

		elseif (arg == "offsetX") then

			local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
			if (not val) then return end

			x = val

		elseif (arg == "offsetY") then

			local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
			if (not val) then return end

			y = val
		end

		CURRENT:ClearAllPoints()
		CURRENT:SetPoint(point, x, y)
	end

	local validate = function(info,val)
		local val = tonumber((string_match(val,"(-*%d+%.?%d*)")))
		if (val) then return true end
		return L["Only numbers are allowed."]
	end

	local options = Options:GenerateProfileMenu()

	-- EditMode integration
	if (EMP) then
	end

	local colorize = function(msg)
		msg = string.gsub(msg, "<", "|cffffd200<")
		msg = string.gsub(msg, ">", ">|r")
		return msg
	end

	-- Guide text when nothing is selected.
	options.args.guideHeader = {
		name = L["Help"],
		order = 89,
		type = "header",
		hidden = function(info) return not isdisabled(info) end
	}
	options.args.guideText1 = {
		name = colorize(L["<Left-Click> an anchor to select it and raise it."]),
		order = 90,
		type = "description",
		fontSize = "medium",
		hidden = function(info) return not isdisabled(info) end
	}
	options.args.guideText2 = {
		name = colorize(L["<Right-Click> an anchor to deselect it and/or lower it."]),
		order = 91,
		type = "description",
		fontSize = "medium",
		hidden = function(info) return not isdisabled(info) end
	}


	-- Frame Positioning
	options.args.positionHeader = {
		name = function(info)
			return CURRENT and CURRENT.Title:GetText() or L["Position"]
		end,
		order = 100,
		type = "header",
		hidden = isdisabled
	}
	options.args.positionDesc = {
		name = L["Fine-tune the position."],
		order = 101,
		type = "description",
		fontSize = "medium",
		hidden = isdisabled
	}
	options.args.point = {
		name = L["Anchor Point"],
		desc = L["Sets the anchor point."],
		order = 110,
		hidden = isdisabled,
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
	options.args.pointSpace = {
		name = "", order = 111, type = "description", hidden = isdisabled
	}
	options.args.offsetX = {
		name = L["Offset X"],
		desc = L["Sets the horizontal offset from your chosen anchor point. Positive values means right, negative values means left."],
		order = 120,
		type = "input",
		hidden = isdisabled,
		validate = validate,
		set = setter,
		get = getter
	}
	options.args.offsetY = {
		name = L["Offset Y"],
		desc = L["Sets the vertical offset from your chosen anchor point. Positive values means up, negative values means down."],
		order = 130,
		type = "input",
		hidden = isdisabled,
		validate = validate,
		set = setter,
		get = getter
	}

	self.app = AceGUI:Create("Frame")
	self:SecureHook(self.app.frame, "Show", "UpdateMovableFrameAnchors")
	self:SecureHook(self.app.frame, "Hide", "HideMovableFrameAnchors")

	AceConfigRegistry:RegisterOptionsTable(self.appName, options)

	return
end

MovableFramesManager.RefreshMFMFrame = function(self)
	if (AceConfigRegistry:GetOptionsTable(self.appName)) then
		if (self.app) then
			-- When using a custom window for the dialog,
			-- the notify callback does not fire for it.
			-- So we need to fake a refresh by toggling twice.
			if (self.app.frame:IsShown()) then
				self:ToggleMFMFrame()
				self:ToggleMFMFrame()
			end
		else
			AceConfigRegistry:NotifyChange(self.appName)
		end
	end
end

MovableFramesManager.OpenMFMFrame = function(self)
	if (not AceConfigRegistry:GetOptionsTable(self.appName)) then
		self:GenerateMFMFrame()
	end
	AceConfigDialog:SetDefaultSize(self.appName, 440, 360)
	AceConfigDialog:Open(self.appName, self.app)
end

MovableFramesManager.CloseMFMFrame = function(self)
	if (AceConfigRegistry:GetOptionsTable(self.appName)) then
		AceConfigDialog:Close(self.appName)
	end
end

MovableFramesManager.ToggleMFMFrame = function(self)
	if (AceConfigDialog.OpenFrames[self.appName]) then
		self:CloseMFMFrame()
	else
		self:OpenMFMFrame()
	end
end

MovableFramesManager.GetLayout = function(self)
	return LAYOUT
end

MovableFramesManager.GetDefaultLayout = function(self)
	return DEFAULTLAYOUT
end

MovableFramesManager.UpdateMovableFrameAnchors = function(self, ...)
	UpdateMovableFrameAnchors()
end

MovableFramesManager.HideMovableFrameAnchors = function(self)
	HideMovableFrameAnchors()
end

MovableFramesManager.IsInEditMode = function(self)
	return self.inEditMode
end

MovableFramesManager.OnEnterEditMode = function(self)
	self.inEditMode = true
	self:RefreshMFMFrame()
	self:OpenMFMFrame()
end

MovableFramesManager.OnExitEditMode = function(self)
	self.inEditMode = nil
	self:CloseMFMFrame()
end

MovableFramesManager.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self.incombat = nil
		end

	elseif (event == "PLAYER_LOGIN") then
		if (EMP) then
			return EMP:LoadLayouts()
		end

	elseif (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			if (EMP) then
				self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
			end
		end
		self.incombat = InCombatLockdown()

		ns:Fire("MFM_LayoutsUpdated", LAYOUT)

	elseif (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		local layoutInfo, fromServer = ...
		if (fromServer) then
			if (EMP) then
				EMP:LoadLayouts()
			end
		end

	elseif (event == "UI_SCALE_CHANGED") then
		local scale = UIParent:GetScale()

		for anchor,anchorData in next,AnchorData do

			--local isDefault = anchor:IsInDefaultPosition()
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

			-- If the default position has been set, adjust it.
			if (anchorData.defaultPosition) then
				local anchorscale = anchorData.defaultScale
				local calculatedscale = type(anchorscale) == "function" and anchorscale()
				local point, x, y = anchorData.defaultPosition[1], anchorData.defaultPosition[2], anchorData.defaultPosition[3]

				local nscale = ((calculatedscale or anchorscale) * SCALE) / scale
				local npoint, nx, ny = point, (x * SCALE) / scale, (y * SCALE) / scale

				anchorData.defaultPosition[1] = npoint
				anchorData.defaultPosition[2] = nx
				anchorData.defaultPosition[3] = ny

				-- Only update this is the scale is a number,
				-- assume functions are meant as overrides.
				if (type(anchorscale) == "number") then
					anchorData.defaultScale = nscale
				end

				-- Callback to modules so they can update their default tables.
				if (anchor.UpdateDefaults) then
					anchor:UpdateDefaults()
				end
			end
		end

		SCALE = scale
	end

	--self:UpdateMFMFrame()
end

MovableFramesManager.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("MovableFrames", defaults)
	self.db.profile = nil

	self.layouts = {}
	self.appName = L["Movable Frames Manager"]

	LAYOUT = self.db.char.layout
	SCALE = UIParent:GetScale()

	if (ns.WoW10) then
		-- Hook our anchor frame's visibility to the editmode.
		-- Note that we cannot simply parent it to the editmode manager,
		-- as that will break the resizing and functionality of the editmode manager.
		self:SecureHook(EditModeManagerFrame, "EnterEditMode", "OnEnterEditMode")
		self:SecureHook(EditModeManagerFrame, "ExitEditMode", "OnExitEditMode")

		-- Update our anchors on editmode changes,
		-- since they might be related to anchor visibility.
		self:SecureHook(EditModeManagerFrame, "OnEvent", "UpdateMovableFrameAnchors")
		self:SecureHook(EditModeManagerFrame, "OnAccountSettingChanged", "UpdateMovableFrameAnchors")
	end

	-- Use this command for all versions now.
	self:RegisterChatCommand("lock", "ToggleMFMFrame")

	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
end
