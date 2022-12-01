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
local MAJOR_VERSION = "LibSpinBar-1.0"
local MINOR_VERSION = 3

if (not LibStub) then
	error(MAJOR_VERSION .. " requires LibStub.")
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local math_abs = math.abs
local math_cos = math.cos
local math_pi = math.pi
local math_sqrt = math.sqrt
local math_rad = math.rad
local math_sin = math.sin
local pairs = pairs
local select = select
local string_format = string.format
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = CreateFrame
local GetTime = GetTime

-- Library registries
lib.bars = lib.bars or {}
lib.textures = lib.textures or {}
lib.embeds = lib.embeds or {}

-- Speed shortcuts
local Bars = lib.bars
local Textures = lib.textures

-- Constants needed later on
local TWO_PI = math_pi*2 -- a 360 interval (full circle)
local HALF_PI = math_pi/2 -- a 90 degree interval (full quadrant)
local QUARTER_PI = math_pi/4 -- a 45 degree interval (center of quadrant)
local DEGS_TO_RADS = math_pi/180 -- simple conversion multiplier
local ROOT_OF_HALF = math_sqrt(.5) -- just something we need to calculate center offsets

----------------------------------------------------------------
-- SpinBar template
----------------------------------------------------------------
-- The virtual bar objects that the modules can manipulate
local SpinBar = CreateFrame("Frame")
local SpinBar_MT = { __index = SpinBar }

-- Grab some of the original methods before we change them
local Orig_GetScript = getmetatable(SpinBar).__index.GetScript
local Orig_SetScript = getmetatable(SpinBar).__index.SetScript

-- Noop out the old blizzard methods.
local noop = function() end
SpinBar.GetFillStyle = noop
SpinBar.GetMinMaxValues = noop
SpinBar.GetOrientation = noop
SpinBar.GetReverseFill = noop
SpinBar.GetRotatesTexture = noop
SpinBar.GetStatusBarAtlas = noop
SpinBar.GetStatusBarColor = noop
SpinBar.GetStatusBarTexture = noop
SpinBar.GetValue = noop
SpinBar.SetFillStyle = noop
SpinBar.SetMinMaxValues = noop
SpinBar.SetOrientation = noop
SpinBar.SetReverseFill = noop
SpinBar.SetValue = noop
SpinBar.SetRotatesTexture = noop
SpinBar.SetStatusBarAtlas = noop
SpinBar.SetStatusBarColor = noop
SpinBar.SetStatusBarTexture = noop

-- Connected to the textures, not the scrollframes.
local Quadrant = SpinBar:CreateTexture()
local Quadrant_MT = { __index = Quadrant }

-- Resets a quadrant's texture to its default (full)
-- texcoords and removes any applied rotations.
-- *Does NOT toggle visibility!
Quadrant.ResetTexture = function(self)
	if (self.quadrantID == 1) then
		self:SetTexCoord(.5, 1, 0, .5) -- upper right
		self:SetPoint("BOTTOMLEFT", 0, 0)
	elseif (self.quadrantID == 2) then
		self:SetTexCoord(0, .5, 0, .5) -- upper left
		self:SetPoint("BOTTOMRIGHT", 0, 0)
	elseif (self.quadrantID == 3) then
		self:SetTexCoord(0, .5, .5, 1) -- lower left
		self:SetPoint("TOPRIGHT", 0, 0)
	elseif (self.quadrantID == 4) then
		self:SetTexCoord(.5, 1, .5, 1) -- lower right
		self:SetPoint("TOPLEFT", 0, 0)
	end
	self:SetRotation(0)
end

Quadrant.RotateTexture = function(self, degrees)

	-- Make sure the degree is in bounds, or just reset the texture and exit
	local compareDegrees = degrees % 360

	-- Reset texture and return if the given degree is not in our quadrant
	if not((compareDegrees >= self.quadrantDegree) and (compareDegrees < self.quadrantDegree + 90)) then
		return self:ResetTexture()
	end

	-- Calculate where the current position is
	local radians = degrees * DEGS_TO_RADS

	-- Simple modifier to decide which direction the box expands in
	local mod = self.clockwise and -1 or 1

	-- Figure out where the points are
	local mainX, mainY = math_cos(radians) *.5, math_sin(radians) *.5
	local otherX, otherY = mainY*mod, -mainX*mod
	local centerX, centerY = mainX + otherX, mainY + otherY

	-- Notes about quadrants and their textures:
	-- * clockwise textures assume a full square when at the start of the quadrant
	-- * clockwise textures extend towards the end of the quadrant
	-- * anti-clockwise textures assume a full square when at the end of a quadrant
	-- * anti-clockwise textures extend towards the start of the quadrant
	local point, ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
	if (self.quadrantID == 1) then

		LLx, LLy, point = 0, 0, "BOTTOMLEFT"
		if self.clockwise then
			LRx, LRy = mainX, mainY
			ULx, ULy = otherX, otherY
			URx, URy = centerX, centerY

		else
			ULx, ULy = mainX, mainY
			LRx, LRy = otherX, otherY
			URx, URy = centerX, centerY
		end

	elseif (self.quadrantID == 2) then

		LRx, LRy, point = 0, 0, "BOTTOMRIGHT"
		if self.clockwise then
			URx, URy = mainX, mainY
			LLx, LLy = otherX, otherY
			ULx, ULy = centerX, centerY
		else
			LLx, LLy = mainX, mainY
			URx, URy = otherX, otherY
			ULx, ULy = centerX, centerY
		end

	elseif (self.quadrantID == 3) then

		URx, URy, point = 0, 0, "TOPRIGHT"
		if self.clockwise then
			ULx, ULy = mainX, mainY
			LRx, LRy = otherX, otherY
			LLx, LLy = centerX, centerY
		else
			LRx, LRy = mainX, mainY
			ULx, ULy = otherX, otherY
			LLx, LLy = centerX, centerY
		end

	elseif (self.quadrantID == 4) then

		ULx, ULy, point = 0, 0, "TOPLEFT"
		if self.clockwise then
			LLx, LLy = mainX, mainY
			URx, URy = otherX, otherY
			LRx, LRy = centerX, centerY
		else
			URx, URy = mainX, mainY
			LLx, LLy = otherX, otherY
			LRx, LRy = centerX, centerY
		end

	end

	-- Get the angle and position of the new center
	local width, height = self:GetSize()
	local center = (degrees-45*mod)* DEGS_TO_RADS

	-- Relative to quadrant #1
	local CX, CY = math_cos(center) *.5, math_sin(center) *.5
	local offsetX = CX*ROOT_OF_HALF*width*2 - width/2
	local offsetY = CY*ROOT_OF_HALF*height*2 - height/2

	-- Correct offsets
	if (self.quadrantID == 2) then
		offsetX = offsetX + width
	end

	if (self.quadrantID == 3) then
		offsetX = offsetX + width
		offsetY = offsetY + height
	end

	if (self.quadrantID == 4) then
		offsetY = offsetY + height
	end

		-- Convert to coordinates used
	-- by the wow texcoord system
	LLx = LLx + .5
	LRx = LRx + .5
	ULx = ULx + .5
	URx = URx + .5
	LLy = 1 - (LLy + .5)
	LRy = 1 - (LRy + .5)
	ULy = 1 - (ULy + .5)
	URy = 1 - (URy + .5)

	-- Perform rotation, texcoord transformation and repositioning
	self:SetRotation(-(self.quadrantDegree + (self.clockwise and 0 or 90) - degrees) * DEGS_TO_RADS)
	self:SetPoint(point, offsetX, offsetY)
	self:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)


	local data = Bars[self]
	local bar = data.statusbar
	local spark = data.spark

	if bar.showSpark then

		local width, height = data.statusbar:GetSize()

		local sparkRadians = radians + data.sparkOffset*DEGS_TO_RADS*(self.clockwise and -1 or 1)

		local x = (width/2 - data.sparkInset) * math_cos(sparkRadians)
		local y = (height/2 - data.sparkInset) * math_sin(sparkRadians)
		-- mainX*(width-data.sparkInset*2), mainY*(height-data.sparkInset*2)

		spark:SetRotation(radians + HALF_PI)
		spark:ClearAllPoints()
		spark:SetPoint("CENTER", data.statusbar, "CENTER", x, y)

		-- where's the center of it?
		--[[
		if not spark.dummy then
			spark.dummy = bar:CreateTexture()
			spark.dummy:SetSize(2,2)
			spark.dummy:SetColorTexture(1,1,1)
		end

		spark.dummy:ClearAllPoints()
		spark.dummy:SetPoint("CENTER", spark, "CENTER", 0, 0)
		]]

		if (not spark:IsShown()) then
			spark:Show()
		end

	elseif spark:IsShown() then
		spark:Hide()
	end


	-- Tell the environment this was the active quadrant
	return true
end

local Update = function(self, elapsed)
	local data = Bars[self]

	local value = data.disableSmoothing and data.barValue or data.barDisplayValue
	local minValue, maxValue = data.barMin, data.barMax
	local width, height = data.statusbar:GetSize()
	local bar = data.bar
	local spark = data.spark

	-- Make sure the value is in the visual range
	if (value > maxValue) then
		value = maxValue
	elseif (value < minValue) then
		value = minValue
	end

	-- Hide the bar textures if the value is at 0, or if max equals min.
	if (value == minValue) or (maxValue == minValue) then
		for id,bar in ipairs(data.quadrants) do
			bar.active = false
			bar:Hide()
		end
	else

		-- percentage of the bar filled
		local percentage = value/(maxValue - minValue)

		-- get current values
		local degreeOffset = data.degreeOffset
		local degreeSpan = data.degreeSpan
		local quadrantOrder = data.quadrantOrder

		-- How many degrees into the bar?
		local valueDegree = degreeSpan * percentage
		if data.clockwise then

			-- add offset, subtract value
			local realAngle = degreeOffset - valueDegree

			local passedCurrent
			for quadrantID = 1,#quadrantOrder,1 do
				local quadrant = data.quadrants[quadrantOrder[quadrantID]]

				local isCurrent = quadrant:RotateTexture(realAngle)
				if isCurrent then
					passedCurrent = true
				end

				quadrant.active = isCurrent or (not passedCurrent)

				if quadrant.active and (not quadrant:IsShown()) then
					quadrant:Show()
				elseif (not quadrant.active) and quadrant:IsShown() then
					quadrant:Hide()
				end
			end
		else

			-- add offset, subtract span size, add value
			local realAngle = degreeOffset - degreeSpan + valueDegree

			local passedCurrent
			for quadrantID = 1,#quadrantOrder,1 do
				local quadrant = data.quadrants[quadrantOrder[quadrantID]]

				local isCurrent = quadrant:RotateTexture(realAngle)
				if isCurrent then
					passedCurrent = true
				end

				quadrant.active = isCurrent or (not passedCurrent)

				if quadrant.active and (not quadrant:IsShown()) then
					quadrant:Show()
				elseif (not quadrant.active) and quadrant:IsShown() then
					quadrant:Hide()
				end
			end
		end
	end

	-- Spark alpha animation
	if ((value == maxValue) or (value == minValue) or (value/maxValue >= data.sparkMaxPercent) or (value/maxValue <= data.sparkMinPercent)) then
		if spark:IsShown() then
			spark:Hide()
			spark:SetAlpha(data.sparkMinAlpha)
			data.sparkDirection = "IN"
		end
	else
		if elapsed then
			local currentAlpha = spark:GetAlpha()
			local targetAlpha = data.sparkDirection == "IN" and data.sparkMaxAlpha or data.sparkMinAlpha
			local range = data.sparkMaxAlpha - data.sparkMinAlpha
			local alphaChange = elapsed/(data.sparkDirection == "IN" and data.sparkDurationIn or data.sparkDurationOut) * range
			if data.sparkDirection == "IN" then
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "OUT"
				end
			elseif data.sparkDirection == "OUT" then
				if currentAlpha + alphaChange > targetAlpha then
					currentAlpha = currentAlpha - alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "IN"
				end
			end
			spark:SetAlpha(currentAlpha)
		end
		if (not spark:IsShown()) then
			spark:Show()
		end
	end

end

local smoothingMinValue = .3 -- if a value is lower than this, we won't smoothe
local smoothingFrequency = .5 -- default duration of smooth transitions
local smartSmoothingDownFrequency = .15 -- duration of smooth reductions in smart mode
local smartSmoothingUpFrequency = .75 -- duration of smooth increases in smart mode
local smoothingLimit = 1/120 -- max updates per second

local OnUpdate = function(self, elapsed)
	local data = Bars[self]
	data.elapsed = (data.elapsed or 0) + elapsed
	if (data.elapsed < smoothingLimit) then
		return
	end

	if (data.updatesRunning) then
		if (data.disableSmoothing) then
			if (data.barValue <= data.barMin) or (data.barValue >= data.barMax) then
				data.updatesRunning = nil
			end
		elseif (data.smoothing) then
			if (math_abs(data.barDisplayValue - data.barValue) < smoothingMinValue) then
				data.barDisplayValue = data.barValue
				data.smoothing = nil
			else
				-- The fraction of the total bar this total animation should cover
				local animsize = (data.barValue - data.smoothingInitialValue)/(data.barMax - data.barMin)

				local smoothSpeed
				if data.barValue > data.barDisplayValue then
					smoothSpeed = smartSmoothingUpFrequency
				elseif data.barValue < data.barDisplayValue then
					smoothSpeed = smartSmoothingDownFrequency
				else
					smoothSpeed = data.smoothingFrequency or smoothingFrequency
				end

				-- Points per second on average for the whole bar
				local pps = (data.barMax - data.barMin)/smoothSpeed

				-- Position in time relative to the length of the animation, scaled from 0 to 1
				local position = (GetTime() - data.smoothingStart)/smoothSpeed
				if (position < 1) then
					-- The change needed when using average speed
					local average = pps * animsize * data.elapsed -- can and should be negative

					-- Tha change relative to point in time and distance passed
					local change = 2*(3 * ( 1 - position )^2 * position) * average*2 --  y = 3 * (1 − t)^2 * t  -- quad bezier fast ascend + slow descend

					-- If there's room for a change in the intended direction, apply it, otherwise finish the animation
					if ( (data.barValue > data.barDisplayValue) and (data.barValue > data.barDisplayValue + change) )
					or ( (data.barValue < data.barDisplayValue) and (data.barValue < data.barDisplayValue + change) ) then
						data.barDisplayValue = data.barDisplayValue + change
					else
						data.barDisplayValue = data.barValue
						data.smoothing = nil
					end
				else
					data.barDisplayValue = data.barValue
					data.smoothing = nil
				end
			end
		else
			if (data.barDisplayValue <= data.barMin) or (data.barDisplayValue >= data.barMax) or (not data.smoothing) then
				data.updatesRunning = nil
			end
		end

		Update(self, data.elapsed)
	end

	-- call module OnUpdate handler
	if data.OnUpdate then
		data.OnUpdate(data.statusbar, data.elapsed)
	end

	-- only reset this at the very end, as calculations above need it
	data.elapsed = 0
end

local UpdateQuadrantOrder = function(self)
	local data = Bars[self]

	local clockwise = data.clockwise
	local degreeOffset = data.degreeOffset
	local degreeSpan = data.degreeSpan
	local quadrants = data.quadrants
	local quadrantOrder = data.quadrantOrder

	-- Figure out where the quadrant containing the offset is located
	local firstDegree
	if clockwise then
		firstDegree = degreeOffset
	else
		firstDegree = degreeOffset - degreeSpan
	end

	if (firstDegree < 0) then
		firstDegree = firstDegree + 360
	elseif (firstDegree >= 360) then
		firstDegree = firstDegree - 360
	end

	local firstQuadrant
	for i = 1,#quadrants do
		local bar = quadrants[i]
		if (firstDegree >= bar.quadrantDegree) and (firstDegree < bar.quadrantDegree + 90) then
			firstQuadrant = i
			break
		end
	end

	-- Iterate through quadrants to decide the order
	local current = firstQuadrant
	if clockwise then
		for i = 1,4 do
			local id = i
			quadrantOrder[i] = current
			current = current - 1
			if (current < 1) then
				current = current + 4
			end
		end
	else
		for i = 1,4 do
			local id = i
			quadrantOrder[i] = current
			current = current + 1
			if (current > 4) then
				current = current - 4
			end
		end
	end

	Update(self)
end

-- Sets the angles where the bar starts and ends.
-- Generally recommended to slightly overshoot the texture "edges"
-- to avoid textures being abruptly cut off.
SpinBar.SetDegreeOffset = function(self, degreeOffset)
	Bars[self].degreeOffset = degreeOffset
	UpdateQuadrantOrder(self)
end

SpinBar.SetDegreeSpan = function(self, degreeSpan)
	Bars[self].degreeSpan = degreeSpan
	UpdateQuadrantOrder(self)
end

-- Sets the min/max-values as in any other bar.
SpinBar.SetSmoothingFrequency = function(self, smoothingFrequency)
	Bars[self].smoothingFrequency = smoothingFrequency
end

SpinBar.DisableSmoothing = function(self, disableSmoothing)
	Bars[self].disableSmoothing = disableSmoothing
end

-- Sets the current value of the spinbar.
SpinBar.SetValue = function(self, value, overrideSmoothing)
	local data = Bars[self]
	local min, max = data.barMin, data.barMax
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	data.barValue = value

	if overrideSmoothing then
		data.barDisplayValue = value
	end

	if (not data.disableSmoothing) then
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
		data.smoothingInitialValue = data.barDisplayValue
		data.smoothingStart = GetTime()
	end

	if (value ~= data.barDisplayValue) then
		data.smoothing = true
	end

	if (data.smoothing or (data.barDisplayValue > min) or (data.barDisplayValue < max)) then
		if (not data.scaffold:GetScript("OnUpdate")) then
			data.scaffold:SetScript("OnUpdate", OnUpdate)
		end
	end

	Update(self)
end

SpinBar.Clear = function(self)
	local data = Bars[self]
	data.barValue = data.barMin
	data.barDisplayValue = data.barMin
	Update(self)
end

SpinBar.SetMinMaxValues = function(self, min, max, overrideSmoothing)
	local data = Bars[self]
	if (data.barMin == min) and (data.barMax == max) then
		return
	end
	if (data.barValue > max) then
		data.barValue = max
	elseif (data.barValue < min) then
		data.barValue = min
	end
	if overrideSmoothing then
		data.barDisplayValue = data.barValue
	else
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
	end
	data.barMin = min
	data.barMax = max
	Update(self)
end

SpinBar.SetStatusBarColor = function(self, ...)
	local data = Bars[self]
	for id,bar in ipairs(data.quadrants) do
		bar:SetVertexColor(...)
	end
	self:SetSparkColor(...)
end

SpinBar.SetStatusBarTexture = function(self, path)
	local data = Bars[self]
	for id,bar in ipairs(data.quadrants) do
		bar:SetTexture(path)
	end
	-- Don't need an update here, texture changes are instant,
	-- and won't change applied rotations and texcoords. I think(?).
	--Update(self)
end

SpinBar.GetStatusBarTexture = function(self)
	return Bars[self].quadrants[1]:GetTexture()
end

SpinBar.SetClockwise = function(self, clockwise)
	local data = Bars[self]
	data.clockwise = clockwise
	for id,bar in ipairs(data.quadrants) do
		bar.clockwise = clockwise
	end
	UpdateQuadrantOrder(self)
end

SpinBar.IsClockwise = function(self)
	return Bars[self].clockwise
end

SpinBar.SetSparkTexture = function(self, ...)
	local arg = ...
	if (type(arg) == "number") then
		Bars[self].spark:SetColorTexture(...)
	else
		Bars[self].spark:SetTexture(...)
	end
end

SpinBar.SetSparkColor = function(self, r, g, b)
	local data = Bars[self]
	local mult = data.statusbar.sparkMultiplier
	if mult then
		data.spark:SetVertexColor(r*mult, g*mult, b*mult)
	else
		data.spark:SetVertexColor(r, g, b)
	end
end

SpinBar.SetSparkMinMaxPercent = function(self, min, max)
	local data = Bars[self]
	data.sparkMinPercent = min
	data.sparkMinPercent = max
end

SpinBar.SetSparkSize = function(self, width, height)
	local data = Bars[self]
	data.sparkWidth = width
	data.sparkHeight = height
	data.spark:SetSize(width, height)
end

SpinBar.SetSparkInset = function(self, inset)
	local data = Bars[self]
	data.sparkInset = inset
end

SpinBar.SetSparkOffset = function(self, offset)
	local data = Bars[self]
	data.sparkOffset = offset
end

SpinBar.SetSparkBlendMode = function(self, blendMode)
	Bars[self].spark:SetBlendMode(blendMode)
end

SpinBar.SetSparkFlash = function(self, durationIn, durationOut, minAlpha, maxAlpha)
	local data = Bars[self]
	data.sparkDurationIn = durationIn or data.sparkDurationIn
	data.sparkDurationOut = durationOut or data.sparkDurationOut
	data.sparkMinAlpha = minAlpha or data.sparkMinAlpha
	data.sparkMaxAlpha = maxAlpha or data.sparkMaxAlpha
	data.sparkDirection = "IN"
	data.spark:SetAlpha(data.sparkMinAlpha)
end

SpinBar.GetParent = function(self)
	return Bars[self].scaffold:GetParent()
end

SpinBar.ClearAllPoints = function(self)
	Bars[self].scaffold:ClearAllPoints()
end

SpinBar.SetPoint = function(self, ...)
	Bars[self].scaffold:SetPoint(...)
end

SpinBar.SetAllPoints = function(self, ...)
	Bars[self].scaffold:SetAllPoints(...)
end

SpinBar.GetPoint = function(self, ...)
	return Bars[self].scaffold:GetPoint(...)
end

SpinBar.SetSize = function(self, width, height)
	local data = Bars[self]

	data.scaffold:SetSize(width, height)

	for id,bar in ipairs(data.quadrants) do
		bar:SetSize(width/2, height/2)
	end

	Update(self)
end

SpinBar.SetWidth = function(self, width)
	local data = Bars[self]

	data.scaffold:SetWidth(width)

	for id,bar in ipairs(data.quadrants) do
		bar:SetWidth(width/2)
	end

	Update(self)
end

SpinBar.SetHeight = function(self, height)
	local data = Bars[self]

	data.scaffold:SetHeight(height)

	for id,bar in ipairs(data.quadrants) do
		bar:SetHeight(height/2)
	end

	Update(self)
end

SpinBar.GetHeight = function(self, ...)
	local top = self:GetTop()
	local bottom = self:GetBottom()
	if top and bottom then
		return top - bottom
	else
		return Bars[self].scaffold:GetHeight(...)
	end
end

SpinBar.GetWidth = function(self, ...)
	local left = self:GetLeft()
	local right = self:GetRight()
	if left and right then
		return right - left
	else
		return Bars[self].scaffold:GetWidth(...)
	end
end

SpinBar.GetSize = function(self, ...)
	local top = self:GetTop()
	local bottom = self:GetBottom()
	local left = self:GetLeft()
	local right = self:GetRight()

	local width, height
	if left and right then
		width = right - left
	end
	if top and bottom then
		height = top - bottom
	end

	return width or Bars[self].scaffold:GetWidth(), height or Bars[self].scaffold:GetHeight()
end

SpinBar.SetFrameLevel = function(self, ...)
	Bars[self].scaffold:SetFrameLevel(...)
end

SpinBar.SetFrameStrata = function(self, ...)
	Bars[self].scaffold:SetFrameStrata(...)
end

SpinBar.SetAlpha = function(self, ...)
	Bars[self].scaffold:SetAlpha(...)
end

SpinBar.SetParent = function(self, ...)
	Bars[self].scaffold:SetParent(...)
end

SpinBar.CreateTexture = function(self, ...)
	return Bars[self].overlay:CreateTexture(...)
end

SpinBar.CreateFontString = function(self, ...)
	return Bars[self].overlay:CreateFontString(...)
end

SpinBar.SetScript = function(self, ...)
	-- can not allow the scaffold to get its scripts overwritten
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		Bars[self].OnUpdate = func
	else
		Bars[self].scaffold:SetScript(...)
	end
end

SpinBar.GetScript = function(self, ...)
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		return Bars[self].OnUpdate
	else
		return Bars[self].scaffold:GetScript(...)
	end
end

SpinBar.GetAnchor = function(self) return Bars[self].bar end
SpinBar.GetObjectType = function(self) return "StatusBar" end
SpinBar.IsObjectType = function(self, type) return type == "SpinBar" or type == "StatusBar" or type == "Frame" end
SpinBar.Show = function(self) Bars[self].scaffold:Show() end
SpinBar.Hide = function(self) Bars[self].scaffold:Hide() end
SpinBar.IsShown = function(self) return Bars[self].scaffold:IsShown() end
SpinBar.IsForbidden = function(self) return true end

lib.CreateSpinBar = function(self, name, parent, template)

	-- The scaffold is the top level frame object
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = CreateFrame("Frame", nil, parent, template)
	scaffold:SetSize(2,2)

	-- The overlay is meant to hold overlay textures like the spark, glow, etc
	local overlay = CreateFrame("Frame", nil, scaffold)
	overlay:SetFrameLevel(scaffold:GetFrameLevel() + 2)
	overlay:SetAllPoints(scaffold)

	-- the spark texture
	local spark = overlay:CreateTexture()
	spark:SetDrawLayer("BORDER", 1)
	spark:SetPoint("CENTER", bar, "CENTER", 0, 0)
	spark:SetSize(16,32)
	spark:SetAlpha(1)
	spark:SetBlendMode("ADD")
	spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical spark being 32x9px, from 0,11px to 32,19px
	spark:SetTexCoord(7/32, 23/32, 9/32, 21/32)

	-- Create the 4 quadrants of the bar
	local quadrants = {}
	for i = 1,4 do

		-- The scrollchild is where we put rotating texture that needs to be cropped.
		local scrollchild = CreateFrame("Frame", nil, scaffold)
		scrollchild:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollchild:SetSize(1,1)

		-- The scrollframe defines the visible area of the quadrant
		local scrollframe = CreateFrame("ScrollFrame", nil, scaffold)
		scrollframe:SetScrollChild(scrollchild)
		scrollframe:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollframe:SetSize(1,1)

		-- Lock the scrollchild to the scrollframe.
		-- We won't be changing its value, it's just used for cropping overflow.
		scrollchild:SetAllPoints(scrollframe)

		-- The actual bar quadrant texture
		local quadrant = setmetatable(scrollchild:CreateTexture(), Quadrant_MT)
		quadrant:SetSize(1,1)
		quadrant:SetDrawLayer("BACKGROUND", 0)
		quadrant.quadrantID = i
		quadrant.spark = spark

		-- Reset position, texcoords and rotation.
		-- Just use the standard method here,
		-- even though it's an extra function call.
		-- Better to have that part in a single place.
		quadrant:ResetTexture()

		-- Quadrant arrangement:
		--
		-- 		/2|1\
		-- 		\3|4/
		--
		-- Note that the quadrants are counter clockwise,
		-- and moving in the opposite direction of default bars.

		if (i == 1) then

			scrollframe:SetPoint("TOPRIGHT", scaffold, "TOPRIGHT", 0, 0)
			scrollframe:SetPoint("BOTTOMLEFT", scaffold, "CENTER", 0, 0)

			quadrant.quadrantDegree = 0

		elseif (i == 2) then

			scrollframe:SetPoint("TOPLEFT", scaffold, "TOPLEFT", 0, 0)
			scrollframe:SetPoint("BOTTOMRIGHT", scaffold, "CENTER", 0, 0)

			quadrant.quadrantDegree = 90

		elseif (i == 3) then

			scrollframe:SetPoint("BOTTOMLEFT", scaffold, "BOTTOMLEFT", 0, 0)
			scrollframe:SetPoint("TOPRIGHT", scaffold, "CENTER", 0, 0)

			quadrant.quadrantDegree = 180


		elseif (i == 4) then

			scrollframe:SetPoint("BOTTOMRIGHT", scaffold, "BOTTOMRIGHT", 0, 0)
			scrollframe:SetPoint("TOPLEFT", scaffold, "CENTER", 0, 0)

			quadrant.quadrantDegree = 270

		end
		quadrants[i] = quadrant

	end

	-- The statusbar is the virtual object that we return to the user.
	-- This contains all the methods.
	local statusbar = CreateFrame("Frame", nil, scaffold)
	statusbar:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(statusbar, SpinBar_MT)

	local data = {}

	-- frame handles
	data.scaffold = scaffold
	data.overlay = overlay
	data.statusbar = statusbar
	data.spark = spark

	-- bar value
	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing

	data.showSpark = true
	data.sparkOffset = 0
	data.sparkInset = 0
	data.sparkWidth = 16
	data.sparkHeight = 32
	data.sparkDirection = "IN"
	data.sparkDurationIn = .75
	data.sparkDurationOut = .55
	data.sparkMinAlpha = .25
	data.sparkMaxAlpha = .95
	data.sparkMinPercent = 1/100
	data.sparkMaxPercent = 99/100

	-- quadrants and degrees
	data.quadrants = quadrants
	data.clockwise = nil -- let the bar fill clockwise
	data.degreeOffset = 0 -- where the bar starts in the circle
	data.degreeSpan = 360 -- size of the bar in degrees
	data.quadrantOrder = { 1,2,3,4 } -- might go with this system instead?

	-- Give multiple objects access using their 'self' as key
	Bars[statusbar] = data
	Bars[scaffold] = data

	-- Allow the quadrant textures
	-- to be used to reference the data too.
	for id,bar in ipairs(quadrants) do
		Bars[bar] = data
	end

	return statusbar
end

local mixins = {
	CreateSpinBar = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
