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

local Bar = ns.Bar.prototype

local ButtonBar = setmetatable({}, { __index = Bar })
local ButtonBar_MT = { __index = ButtonBar }

-- Lua API
local next = next
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min

local maps = {
	azerite = {
		[1] = { "BOTTOMLEFT", 0, 0 }, -- bottom row
		[2] = { "BOTTOMLEFT", 72, 0 }, -- bottom row
		[3] = { "BOTTOMLEFT", 144, 0 }, -- bottom row
		[4] = { "BOTTOMLEFT", 216, 0 }, -- bottom row
		[5] = { "BOTTOMLEFT", 288, 0 }, -- bottom row
		[6] = { "BOTTOMLEFT", 360, 0 }, -- bottom row
		[7] = { "BOTTOMLEFT", 432, 0 }, -- bottom row
		[8] = { "BOTTOMLEFT", 504, 0 }, -- bottom row
		[9] = { "BOTTOMLEFT", 576, 0 }, -- bottom row
		[10] = { "BOTTOMLEFT", 638, 0 }, -- bottom row
		[11] = { "BOTTOMLEFT", 720, 0 }, -- bottom row
		[12] = { "BOTTOMLEFT", 792, 0 } -- bottom row
	},
	horizontal = {
		[1] = { "BOTTOMLEFT", 0, 0 }, -- bottom row
		[2] = { "BOTTOMLEFT", 72, 0 }, -- bottom row
		[3] = { "BOTTOMLEFT", 144, 0 }, -- bottom row
		[4] = { "BOTTOMLEFT", 216, 0 }, -- bottom row
		[5] = { "BOTTOMLEFT", 288, 0 }, -- bottom row
		[6] = { "BOTTOMLEFT", 360, 0 }, -- bottom row
		[7] = { "BOTTOMLEFT", 432, 0 }, -- bottom row
		[8] = { "BOTTOMLEFT", 504, 0 }, -- bottom row
		[9] = { "BOTTOMLEFT", 576, 0 }, -- bottom row
		[10] = { "BOTTOMLEFT", 638, 0 }, -- bottom row
		[11] = { "BOTTOMLEFT", 720, 0 }, -- bottom row
		[12] = { "BOTTOMLEFT", 792, 0 } -- bottom row
	},
	zigzag = {
		[1] = { "BOTTOMLEFT", -28, 72 }, -- top row
		[2] = { "BOTTOMLEFT", 0, 0 }, -- bottom row
		[3] = { "BOTTOMLEFT", 44, 72 }, -- top row
		[4] = { "BOTTOMLEFT", 72, 0 }, -- bottom row
		[5] = { "BOTTOMLEFT", 116, 72 }, -- top row
		[6] = { "BOTTOMLEFT", 144, 0 }, -- bottom row
		[7] = { "BOTTOMLEFT", 188, 72 }, -- top row
		[8] = { "BOTTOMLEFT", 216, 0 }, -- bottom row
		[9] = { "BOTTOMLEFT", 260, 72 }, -- top row
		[10] = { "BOTTOMLEFT", 288, 0 }, -- bottom row
		[11] = { "BOTTOMLEFT", 332, 72 }, -- top row
		[12] = { "BOTTOMLEFT", 360, 0 } -- bottom row
	}
}

local defaults = ns:Merge({
	numbuttons = 12,
	layout = "grid",
	grid = {
		growth = "horizontal",
		growthHorizontal = "RIGHT",
		growthVertical = "DOWN",
		padding = 2,
		breakpoint = 12,
		breakpadding = 2
	},
	hidemacrotext = false,
	hidehotkey = false,
	hideequipped = false,
	hideborder = false
}, ns.Bar.defaults)

ns.ButtonBar = {}
ns.ButtonBar.prototype = ButtonBar
ns.ButtonBar.defaults = defaults

ns.ButtonBar.Create = function(self, id, config, name)
	local bar = setmetatable(ns.Bar:Create(id, config, name), ButtonBar_MT)

	bar.buttons = {}
	bar.buttonConfig = ns.ActionButton.defaults
	bar.buttonWidth = 64
	bar.buttonHeight = 64

	return bar
end

ButtonBar.CreateButton = function(self, config)

	local id = #self.buttons + 1
	local button = ns.ActionButton.Create(id, self:GetName().."Button"..id, self, config)

	self:SetFrameRef("Button"..id, button)
	self.buttons[id] = button

	return button
end

ButtonBar.UpdateButtons = function(self)
	if (InCombatLockdown()) then return end

	local buttons = self.buttons
	local numbuttons = self.config.numbuttons

	for id = #buttons + 1, numbuttons do
		self:CreateButton()
	end

	for id,button in next,buttons do
		button:SetEnabled(id <= numbuttons)
	end

end

ButtonBar.UpdateButtonLayout = function(self)
	if (InCombatLockdown()) then return end

	local buttons = self.buttons
	local numbuttons = self.numbuttons or #buttons

	if (numbuttons == 0) then return end

	local layout = self.config.layout

	if (layout == "map") then

		local map = maps[self.config.maptype]
		local left, right, top, bottom

		for id,button in next,buttons do
			button:ClearAllPoints()
			button:SetPoint(unpack(map[id]))

			local bleft = button:GetLeft()
			local bright = button:GetRight()
			local btop = button:GetTop()
			local bbottom = button:GetBottom()

			left = left and math_min(left, bleft) or bleft
			right = right and math_max(right, bright) or bright
			top = top and math_max(top, btop) or btop
			bottom = bottom and math_min(bottom, bbottom) or bbottom

		end

		local width, height = right-left, top-bottom

		self:SetSize(width, height)

		if (self.anchor) then
			self.anchor:SetSize(width, height)
			self.anchor.Text:SetRotation(0)
			self.anchor.Title:SetRotation(0)
		end

		return

	elseif (layout == "grid") then

		local grid = self.config.grid

		local buttonWidth = self.buttonWidth
		local buttonHeight = self.buttonHeight

		local totalbreaks = math_ceil(self.config.numbuttons/grid.breakpoint)
		local width, height

		if (grid.growth == "horizontal") then
			width = buttonWidth*grid.breakpoint + grid.padding*(grid.breakpoint - 1)
			height = buttonHeight*totalbreaks + (grid.breakpadding or grid.padding)*(totalbreaks-1)

		elseif (grid.growth == "vertical") then
			width = buttonWidth*totalbreaks + (grid.breakpadding or grid.padding)*(totalbreaks-1)
			height = buttonHeight*grid.breakpoint + grid.padding*(grid.breakpoint - 1)
		end

		self:SetSize(width, height)

		local point = (grid.growthVertical == "UP" and "BOTTOM" or "TOP")..(grid.growthHorizontal == "RIGHT" and "LEFT" or "RIGHT")
		local offsetX, offsetY = 0,0

		for id,button in next,buttons do

			local breakpoint = (id - 1)%grid.breakpoint == 0
			local numbreaks = breakpoint and math_floor((id - 1)/grid.breakpoint)

			if (grid.growth == "horizontal") then
				if (breakpoint) then
					offsetX = 0
					if (grid.growthVertical == "UP") then
						offsetY = (buttonHeight + (grid.breakpadding or grid.padding)) * numbreaks
					elseif (grid.growthVertical == "DOWN") then
						offsetY = -(buttonHeight + (grid.breakpadding or grid.padding)) * numbreaks
					end
				else
					if (grid.growthHorizontal == "RIGHT") then
						offsetX = offsetX + (buttonWidth + grid.padding)
					elseif (grid.growthHorizontal == "LEFT") then
						offsetX = offsetX - (buttonWidth + grid.padding)
					end
				end

			elseif (grid.growth == "vertical") then
				if (breakpoint) then
					if (grid.growthHorizontal == "UP") then
						offsetX = (buttonWidth + (grid.breakpadding or grid.padding)) * numbreaks
					elseif (grid.growthHorizontal == "DOWN") then
						offsetX = -(buttonWidth + (grid.breakpadding or grid.padding)) * numbreaks
					end
					offsetY = 0
				else
					if (grid.growthVertical == "DOWN") then
						offsetY = offsetY - (buttonWidth + grid.padding)
					elseif (grid.growthVertical == "UP") then
						offsetY = offsetY + (buttonWidth + grid.padding)
					end
				end
			end

			button:ClearAllPoints()
			button:SetPoint(point, offsetX, offsetY)

		end

	end

end
