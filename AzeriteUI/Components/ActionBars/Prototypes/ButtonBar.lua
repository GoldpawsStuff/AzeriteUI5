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

local MFM = ns:GetModule("MovableFramesManager")

local Bar = ns.Bar.prototype

local ButtonBar = setmetatable({}, { __index = Bar })
local ButtonBar_MT = { __index = ButtonBar }

-- Lua API
local next = next
local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local setmetatable = setmetatable

local defaults = ns:Merge({
	numbuttons = 0
}, ns.Bar.defaults)

ns.ButtonBar = {}
ns.ButtonBar.prototype = ButtonBar
ns.ButtonBar.defaults = defaults

ns.ButtonBar.Create = function(self, id, config, name)
	local bar = setmetatable(ns.Bar:Create(id, config, name), ButtonBar_MT)

	bar.buttons = {}
	bar.buttonConfig = ns:Merge({}, ns.ButtonBar.defaults)
	bar.buttonWidth = 64
	bar.buttonHeight = 64

	return bar
end

ButtonBar.CreateButton = function(self, buttonConfig)

	local id = #self.buttons + 1
	local button = ns.ActionButton.Create(id, self:GetName().."Button"..id, self, buttonConfig)

	self:SetFrameRef("Button"..id, button)
	self.buttons[id] = button

	return button
end

ButtonBar.Enable = function(self)
	if (InCombatLockdown()) then return end

	Bar.Enable(self)
end

ButtonBar.Disable = function(self)
	if (InCombatLockdown()) then return end

	Bar.Disable(self)
end

ButtonBar.UpdateButtons = function(self)
	if (InCombatLockdown()) then return end

	local buttons = self.buttons
	local numbuttons = self.config.numbuttons

	for id = #buttons + 1, numbuttons do
		self:CreateButton()
	end

	for id,button in next,buttons do
		if (id <= numbuttons) then
			button:Show()
			button:SetAttribute("statehidden", nil)
		else
			button:Hide()
			button:SetAttribute("statehidden", true)
		end
	end

end

ButtonBar.UpdateButtonLayout = function(self)
	if (InCombatLockdown()) then return end

	local buttons = self.buttons
	local numbuttons = self.config.numbuttons or #buttons

	if (numbuttons == 0) then
		self:SetSize(self.buttonWidth, self.buttonHeight)
		return
	end

	local layout = self.config.layout

	if (layout == "zigzag") then

		self:SetSize(2,2) -- Just set a temporary size to avoid positioning bugs

		local config = self.config
		local buttonWidth = self.buttonWidth
		local buttonHeight = self.buttonHeight

		local fullZag = config.startAt == 1
		local counter = 0
		local left, right, top, bottom = 0, 0, 0, 0
		local point = (config.growthVertical == "UP" and "BOTTOM" or "TOP")..(config.growthHorizontal == "RIGHT" and "LEFT" or "RIGHT")
		local offsetX, offsetY

		for id,button in next,buttons do

			local isZigZag = (id >= config.startAt) and ((config.startAt - id)%2 == 0)

			if (config.growth == "horizontal") then

				if (config.growthHorizontal == "RIGHT") then
					offsetX = (buttonWidth + config.padding) * (counter - (isZigZag and 1 or 0)) + (isZigZag and (config.offset * buttonWidth) or 0)
					if (id <= numbuttons) then
						left = 0
						right = math_max(right, offsetX + buttonWidth)
					end

				elseif (config.growthHorizontal == "LEFT") then
					offsetX = -((buttonWidth + config.padding) * (counter - (isZigZag and 1 or 0)) + (isZigZag and (config.offset * buttonWidth) or 0))
					if (id <= numbuttons) then
						left = math_min(left, offsetX - buttonWidth)
						right = 0
					end
				end

				if (config.growthVertical == "UP") then
					offsetY = isZigZag and (buttonHeight + config.breakpadding) or 0
					if (id <= numbuttons) then
						top = math_max(top, offsetY + buttonHeight)
						bottom = 0
					end

				elseif (config.growthVertical == "DOWN") then
					offsetY = isZigZag and -(buttonHeight + config.breakpadding) or 0
					if (id <= numbuttons) then
						top = 0
						bottom = math_min(bottom, offsetY - buttonHeight)
					end
				end


			elseif (config.growth == "vertical") then

				if (config.growthVertical == "DOWN") then
					offsetY = -((buttonHeight + config.padding) * counter + (isZigZag and (config.offset * buttonWidth) or 0))
					if (id <= numbuttons) then
						top = 0
						bottom = math_min(bottom, offsetY - buttonHeight)
					end

				elseif (config.growthVertical == "UP") then
					offsetY = (buttonHeight + config.padding) * counter + (isZigZag and (config.offset * buttonWidth) or 0)
					if (id <= numbuttons) then
						top = math_max(top, offsetY + buttonHeight)
						bottom = 0
					end
				end

				if (config.growthHorizontal == "RIGHT") then
					offsetX = isZigZag and (buttonWidth + config.padding) or 0
					if (id <= numbuttons) then
						left = 0
						right = math_max(right, offsetX + buttonWidth)
					end

				elseif (config.growthHorizontal == "LEFT") then
					offsetX = isZigZag and -(buttonWidth + config.padding) or 0
					if (id <= numbuttons) then
						left = math_min(left, offsetX - buttonWidth)
						right = 0
					end
				end

			end

			if (not isZigZag) then
				counter = counter + 1
			end

			button:ClearAllPoints()
			button:SetPoint(point, offsetX, offsetY)

		end

		self:SetSize(math_abs(left - right), math_abs(top - bottom))

	elseif (layout == "grid") then

		local config = self.config

		local buttonWidth = self.buttonWidth
		local buttonHeight = self.buttonHeight

		local totalbreaks = math_ceil(config.numbuttons/config.breakpoint)
		local width, height

		if (config.growth == "horizontal") then
			if (numbuttons < config.breakpoint) then
				width = buttonWidth*numbuttons + config.padding*(numbuttons - 1)
				height = buttonHeight
			else
				width = buttonWidth*config.breakpoint + config.padding*(config.breakpoint - 1)
				height = buttonHeight*totalbreaks + (config.breakpadding or config.padding)*(totalbreaks-1)
			end

		elseif (config.growth == "vertical") then
			if (numbuttons < config.breakpoint) then
				width = buttonWidth
				height = buttonHeight*numbuttons + config.padding*(numbuttons - 1)
			else
				width = buttonWidth*totalbreaks + (config.breakpadding or config.padding)*(totalbreaks-1)
				height = buttonHeight*config.breakpoint + config.padding*(config.breakpoint - 1)
			end
		end

		self:SetSize(width, height)

		local point = (config.growthVertical == "UP" and "BOTTOM" or "TOP")..(config.growthHorizontal == "RIGHT" and "LEFT" or "RIGHT")
		local offsetX, offsetY = 0,0

		for id,button in next,buttons do

			local breakpoint = (id - 1)%config.breakpoint == 0
			local numbreaks = breakpoint and math_floor((id - 1)/config.breakpoint)

			if (config.growth == "horizontal") then
				if (breakpoint) then
					offsetX = 0
					if (config.growthVertical == "UP") then
						offsetY = (buttonHeight + (config.breakpadding or config.padding)) * numbreaks
					elseif (config.growthVertical == "DOWN") then
						offsetY = -(buttonHeight + (config.breakpadding or config.padding)) * numbreaks
					end
				else
					if (config.growthHorizontal == "RIGHT") then
						offsetX = offsetX + (buttonWidth + config.padding)
					elseif (config.growthHorizontal == "LEFT") then
						offsetX = offsetX - (buttonWidth + config.padding)
					end
				end

			elseif (config.growth == "vertical") then
				if (breakpoint) then
					if (config.growthHorizontal == "RIGHT") then
						offsetX = (buttonWidth + (config.breakpadding or config.padding)) * numbreaks
					elseif (config.growthHorizontal == "LEFT") then
						offsetX = -(buttonWidth + (config.breakpadding or config.padding)) * numbreaks
					end
					offsetY = 0
				else
					if (config.growthVertical == "DOWN") then
						offsetY = offsetY - (buttonWidth + config.padding)
					elseif (config.growthVertical == "UP") then
						offsetY = offsetY + (buttonWidth + config.padding)
					end
				end
			end

			button:ClearAllPoints()
			button:SetPoint(point, offsetX, offsetY)

		end

	end

end
