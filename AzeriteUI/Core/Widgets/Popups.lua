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
local Addon, ns = ...
local Widgets = ns.Private.Widgets or {}
ns.Private.Widgets = Widgets

-- Lua API
local table_insert = table.insert
local table_remove = table.remove

local popups = {}
local all, available, active = {}, {}, {}

local create = function()
	local popupFrame = CreateFrame("Frame", Addon.."PopupFrame"..(#all + 1))
	popupFrame:SetFrameStrata("DIALOG")
	popupFrame:SetFrameLevel(2)

	table_insert(all, popupFrame)

	return popupFrame
end

local pull = function()
	local popupFrame = table_remove(available) or create()
	active[popupFrame] = true
	return popupFrame
end

local push = function(popupFrame)
	if (not popupFrame) then return end
	popupFrame:Hide()
	active[popupFrame] = nil
	table_insert(available, popupFrame)
end

-- Global API
---------------------------------------------------------
Widgets.RegisterPopup = function(popupID, popupData)

end

Widgets.ShowPopup = function(popupID)
	if (not popups[popupID]) then return end
	local popupFrame = pull()
	popupFrame:Show()
end

Widgets.HidePopup = function(popupID)
	if (not popups[popupID]) then return end

end
