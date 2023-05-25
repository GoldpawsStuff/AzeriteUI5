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
local AddonName = GetAddOnMetadata(Addon, "Title")

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local MovableFramesManager = ns:NewModule("MovableFramesManager", "LibMoreEvents-1.0", "AceConsole-3.0", "AceHook-3.0")
local EMP = ns:GetModule("EditMode", true)
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Lua API
local error = error
local getmetatable = getmetatable
local math_abs = math.abs
local next = next
local rawget = rawget
local select = select
local setmetatable = setmetatable
local string_format = string.format
local table_insert = table.insert
local table_sort = table.sort
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
			if (self:IsScalable() and compare(anchorData.scale, anchorData.defaultScale)) then
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

	ns:Fire("MFM_ScaleUpdated", LAYOUT, self, scale)
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
		if (CURRENT and CURRENT == self) then
			CURRENT = nil
			self.isSelected = nil
			self:OnLeave()
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
end

Anchor.OnDragStop = function(self)
	local anchorData = AnchorData[self]

	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = getPosition(self)

	anchorData.currentPosition = { point, x, y }

	self:UpdatePosition(LAYOUT, point, x, y)
end

Anchor.OnEnter = function(self)
	self:UpdateText()
	self:SetAlpha(1)
end

Anchor.OnLeave = function(self)
	self:UpdateText()
	self:SetAlpha(.5)
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
		if (ns.WoW10 and anchor.editModeAccountSetting) then
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

-- Register a preset name in our dropdown menu.
MovableFramesManager.RegisterPreset = function(self, layoutName)
	if (self.layouts[layoutName]) then return end

	-- Add the preset to our list.
	self.layouts[layoutName] = true

	-- Update the manager frame.
	self:UpdateMFMFrame()
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
	self:UpdateMFMFrame()
end

-- Send a message to modules to delete a saved preset.
-- Will switch to the default preset in our dropdown menu.
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
	self:UpdateMFMFrame()
end

-- Update available preset list in our dropdown.
MovableFramesManager.UpdateMFMFrame = function(self)
	local MFMFrame = self:GetMFMFrame()

	-- Create a sorted table.
	local sorted = {}
	for layoutName in next,self.layouts do
		table_insert(sorted, layoutName)
	end
	table_sort(sorted)

	-- Apply the sorted table to our dropdown.
	MFMFrame.SelectLayoutDropdown:SetList(sorted)

	-- Select the currently active layout in the dropdown.
	for i,layoutName in ipairs(sorted) do
		if (layoutName == LAYOUT) then
			MFMFrame.SelectLayoutDropdown:SetValue(i)
			break
		end
	end

	-- Toggle button enabled status.
	MFMFrame.DeleteLayoutButton:SetDisabled(LAYOUT == DEFAULTLAYOUT)
	if (EMP) then
		if (not EMP:AreLayoutsLoaded()) then return end
		MFMFrame.ResetEditModeLayoutButton:SetDisabled(self.incombat or not EMP:CanEditActiveLayout())
		MFMFrame.CreateEditModeLayoutButton:SetDisabled(self.incombat or EMP:DoesDefaultLayoutExist())
	end
end

MovableFramesManager.GetMFMFrame = function(self)
	if (not self.frame) then

		-- Create primary window
		--------------------------------------------------
		local window = AceGUI:Create("Frame")
		window:Hide()
		window:SetWidth(360)
		window:SetHeight(EMP and 366 or 166)
		window:SetPoint(EMP and "TOPRIGHT" or "TOP", UIParent, EMP and "TOPRIGHT" or "TOP", EMP and -220 or 0, -260)
		window:SetTitle(Addon)
		window:SetStatusText(Addon .." ".. (ns.IsDevelopment and "Git Version" or ns.Version))
		window:SetLayout("Flow")

		window.frame:SetResizable(false)
		window.frame:SetBackdrop(nil)
		window.frame.obj.sizer_se:Hide()
		window.frame.obj.sizer_s:Hide()
		window.frame.obj.sizer_e:Hide()
		window.Backdrop = createBackdropFrame(window.frame)

		self.frame = window

		-- Layout Selection Dropdown Group
		--------------------------------------------------
		local group = AceGUI:Create("SimpleGroup")
		group:SetLayout("Flow")
		group:SetFullWidth(true)
		group:SetAutoAdjustHeight(false)
		group:SetHeight(54)

		-- Dropdown label
		local label = AceGUI:Create("Label")
		label:SetText(L["Layout:"])
		label:SetFontObject(GetFont(13, true))
		label:SetColor(unpack(Colors.normal))
		label:SetFullWidth(true)
		group:AddChild(label)

		-- Preset selection dropdown
		local dropdown = AceGUI:Create("Dropdown")
		dropdown:SetWidth(220)
		dropdown:SetCallback("OnValueChanged", function(widget, script, key)
			local selected
			for i,item in widget.pullout:IterateItems() do
				if (i == key) then
					selected = item:GetText() or ""
					break
				end
			end
			if (selected) then
				self:ApplyPreset(selected)
			end
		end)
		group:AddChild(dropdown)
		window.SelectLayoutDropdown = dropdown

		window:AddChild(group)

		-- Layout Management Group
		--------------------------------------------------
		local group = AceGUI:Create("SimpleGroup")
		group:SetLayout("Flow")
		group:SetFullWidth(true)
		group:SetAutoAdjustHeight(false)
		group:SetHeight(60)

		local button = AceGUI:Create("Button")
		button:SetText(L["Create"])
		button:SetRelativeWidth(.3)
		button:SetCallback("OnClick", function()

			if (not self.DialogFrame) then

				local popup = CreateFrame("Frame", nil, window.frame)
				popup:Hide()
				popup:SetFrameStrata("FULLSCREEN_DIALOG")
				popup:SetToplevel(true)
				popup:SetFrameLevel(1000)
				popup:SetSize(380, 160)
				popup:SetPoint("CENTER", window.frame)
				popup:SetScript("OnShow", function()
					window.frame:SetToplevel(false)
				end)
				popup:SetScript("OnHide", function()
					window.frame:SetToplevel(true)
				end)

				popup.Backdrop = createBackdropFrame(popup)

				local editbox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
				editbox:SetAutoFocus(true)
				editbox:SetFontObject(GetFont(15, true))
				editbox:SetScript("OnEnter", nil)
				editbox:SetScript("OnLeave", nil)
				editbox:SetScript("OnEscapePressed", function(widget)
					widget:ClearFocus()
				end)
				editbox:SetScript("OnEnterPressed", function(widget)
					widget:GetParent().AcceptButton:Click()
				end)
				editbox:SetScript("OnTextChanged", nil)
				editbox:SetScript("OnReceiveDrag", nil)
				editbox:SetScript("OnMouseDown", nil)
				editbox:SetScript("OnEditFocusGained", function(widget)
					widget:SetText("")
					widget:SetCursorPosition(0)
				end)
				editbox:SetScript("OnEditFocusLost", function(widget)
					widget:GetParent():Hide()
					widget:SetText("")
					widget:SetCursorPosition(0)
				end)
				editbox:SetTextInsets(3, 3, 6, 6)
				editbox:SetMaxLetters(32)
				editbox:SetPoint("BOTTOMLEFT", 28, 70)
				editbox:SetPoint("BOTTOMRIGHT", -23, 70)
				editbox:SetHeight(27)

				popup.EditBox = editbox

				local label = popup:CreateFontString(nil, "OVERLAY")
				label:SetFontObject(GetFont(13, true))
				label:SetTextColor(unpack(Colors.normal))
				label:SetText(L["Name the New Layout"])
				label:SetPoint("BOTTOM", editbox, "TOP", 0, 6)
				label:SetJustifyH("LEFT")
				label:SetJustifyV("BOTTOM")

				popup.Label = label

				local accept = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
				accept:SetSize(160, 30)
				accept:SetText(L["Save"])
				accept:SetPoint("BOTTOMLEFT", 20, 20)
				accept:SetScript("OnClick", function(widget)
					local layoutName = widget:GetParent().EditBox:GetText()
					widget:GetParent():Hide()
					if (layoutName and not self.layouts[layoutName]) then
						self:RegisterPreset(layoutName)
						self:ApplyPreset(layoutName)
					end
				end)

				popup.AcceptButton = accept

				local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
				cancel:SetSize(160, 30)
				cancel:SetText(L["Cancel"])
				cancel:SetPoint("BOTTOMRIGHT", -20, 20)
				cancel:SetScript("OnClick", function(widget)
					widget:GetParent():Hide()
				end)

				popup.CancelButton = cancel

				self.DialogFrame = popup
			end

			-- Open name dialog
			self.DialogFrame:Show()
		end)
		group:AddChild(button)
		window.CreateLayoutButton = button

		local button = AceGUI:Create("Button")
		button:SetText(L["Copy"])
		button:SetRelativeWidth(.3)
		button:SetDisabled(true)
		button:SetCallback("OnClick", function()
			-- Open name dialog
			-- Copy preset
			-- Fire anchor callback to let modules copy and save it
			-- Add preset to list
			-- Update managerframe
		end)
		group:AddChild(button)
		window.CopyLayoutButton = button

		local button = AceGUI:Create("Button")
		button:SetText(L["Delete"])
		button:SetRelativeWidth(.3)
		button:SetDisabled(true)
		button:SetCallback("OnClick", function()
			-- Open confirmation dialog
			-- Fire module callback to let modules clear the saved entry
			self:DeletePreset(LAYOUT)
		end)
		group:AddChild(button)
		window.DeleteLayoutButton = button

		window:AddChild(group)

		if (EMP) then

			-- HUD Edit Mode Title
			--------------------------------------------------
			local group = AceGUI:Create("SimpleGroup")
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			group:SetAutoAdjustHeight(false)
			group:SetHeight(20)

			-- EditMode section title
			local label = AceGUI:Create("Label")
			label:SetText(L["HUD Edit Mode"])
			label:SetFontObject(GetFont(15, true))
			label:SetColor(unpack(Colors.normal))
			label:SetFullWidth(true)
			group:AddChild(label)

			window:AddChild(group)

			-- HUD Edit Mode Reset
			--------------------------------------------------
			local group = AceGUI:Create("SimpleGroup")
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			group:SetAutoAdjustHeight(false)
			group:SetHeight(80)

			-- EditMode reset button description
			local label = AceGUI:Create("Label")
			label:SetText(L["Click the button below to reset the currently selected EditMode preset to positions matching the default AzeriteUI layout."])
			label:SetFontObject(GetFont(13, true))
			label:SetColor(unpack(Colors.offwhite))
			label:SetRelativeWidth(.9)
			group:AddChild(label)

			local button = AceGUI:Create("Button")
			button:SetText(L["Reset EditMode Layout"])
			button:SetFullWidth(true)
			button:SetCallback("OnClick", function()
				EMP:ApplySystems()
			end)
			window.ResetEditModeLayoutButton = button

			group:AddChild(button)

			window:AddChild(group)

			-- HUD Edit Mode Azerite Preset
			--------------------------------------------------
			local group = AceGUI:Create("SimpleGroup")
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			group:SetAutoAdjustHeight(true)
			--group:SetHeight(60)

			-- EditMode reset button description
			local label = AceGUI:Create("Label")
			label:SetText(L["Click the button below to create an EditMode preset named 'Azerite'."])
			label:SetFontObject(GetFont(13, true))
			label:SetColor(unpack(Colors.offwhite))
			label:SetRelativeWidth(.9)
			group:AddChild(label)

			local button = AceGUI:Create("Button")
			button:SetText(L["Create EditMode Layout"])
			button:SetFullWidth(true)
			button:SetDisabled(true)
			button:SetCallback("OnClick", function()
				EMP:ResetLayouts()
			end)
			window.CreateEditModeLayoutButton = button

			group:AddChild(button)

			window:AddChild(group)
		end
	end

	return self.frame
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

MovableFramesManager.ToggleAnchors = function(self)
	local MFMFrame = self:GetMFMFrame()
	if (MFMFrame:IsShown()) then
		MFMFrame:Hide()
	else
		MFMFrame:Show()
	end
end

MovableFramesManager.OnEnterEditMode = function(self)
	self:UpdateMFMFrame()
	self:GetMFMFrame():Show()
end

MovableFramesManager.OnExitEditMode = function(self)
	self:GetMFMFrame():Hide()
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

	self:UpdateMFMFrame()
end

MovableFramesManager.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("MovableFrames", defaults)
	self.db.profile = nil

	self.layouts = {}

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

	else
		self:RegisterChatCommand("lock", "ToggleAnchors")
	end

	-- Hook our anchor visibility updates to our managerframe visibility.
	self:SecureHook(self:GetMFMFrame(), "Show", "UpdateMovableFrameAnchors")
	self:SecureHook(self:GetMFMFrame(), "Hide", "HideMovableFrameAnchors")

	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
end
