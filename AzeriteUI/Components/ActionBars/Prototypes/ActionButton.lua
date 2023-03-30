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

local LAB = LibStub("LibActionButton-1.0-GE")

-- Default button config
local defaults = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { 1, .15, .15 },
		mana = { .25, .25, 1 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = true,
		border = true,
		borderIfEmpty = true
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
	clickOnDown = true,
	flyoutDirection = "UP"
}

ns.ActionButtons = {}
ns.ActionButton = {}
ns.ActionButton.defaults = defaults

ns.ActionButton.Create = function(id, name, header, config)

	local button = LAB:CreateButton(id, name, header, config)
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("checkmouseovercast", true)

	ns.ActionButtons[button] = true

	return button
end

