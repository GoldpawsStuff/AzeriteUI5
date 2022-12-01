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
local MAJOR_VERSION = "LibOrb-1.0"
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
local math_abs = math.abs
local math_max = math.max
local math_sqrt = math.sqrt
local select = select
local setmetatable = setmetatable
local type = type
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime

-- Library registries
lib.orbs = lib.orbs or {}
lib.data = lib.data or {}
lib.embeds = lib.embeds or {}

-- Speed shortcuts
local Orbs = lib.orbs

----------------------------------------------------------------
-- Orb template
----------------------------------------------------------------
local Orb = CreateFrame("StatusBar")
local Orb_MT = { __index = Orb }

-- Grab some of the original methods before we change them
local Orig_GetScript = getmetatable(Orb).__index.GetScript
local Orig_SetScript = getmetatable(Orb).__index.SetScript

-- Noop out the old blizzard methods.
local noop = function() end
Orb.GetFillStyle = noop
Orb.GetMinMaxValues = noop
Orb.GetOrientation = noop
Orb.GetReverseFill = noop
Orb.GetRotatesTexture = noop
Orb.GetStatusBarAtlas = noop
Orb.GetStatusBarColor = noop
Orb.GetStatusBarTexture = noop
Orb.GetValue = noop
Orb.SetFillStyle = noop
Orb.SetMinMaxValues = noop
Orb.SetOrientation = noop
Orb.SetReverseFill = noop
Orb.SetValue = noop
Orb.SetRotatesTexture = noop
Orb.SetStatusBarAtlas = noop
Orb.SetStatusBarColor = noop
Orb.SetStatusBarTexture = noop

local smoothingMinValue = 1 -- if a value is lower than this, we won't smoothe
local smoothingFrequency = .5 -- time for the smooth transition to complete
local smoothingLimit = 1/60 -- max updates per second

local Update = function(self, elapsed)
	local data = Orbs[self]

	local value = data.disableSmoothing and data.barValue or data.barDisplayValue
	local min, max = data.barMin, data.barMax
	local orientation = data.orbOrientation
	local width, height = self:GetSize()
	local spark = data.spark

	if value > max then
		value = max
	elseif value < min then
		value = min
	end

	local newHeight
	if value > 0 and value > min and max > min then
		newHeight = (value-min)/(max-min) * height
	else
		newHeight = 0
	end

	if (value <= min) or (max == min) then
		data.scrollframe:Hide()
	else

		local newSize, mult
		if (max > min) then
			mult = (value-min)/(max-min)
			newSize = mult * width
		else
			newSize = 0.0001
			mult = 0.0001
		end
		local displaySize = math_max(newSize, 0.0001) -- sizes can't be 0 in Legion

		data.scrollframe:SetHeight(displaySize)
		data.scrollframe:SetVerticalScroll(height - newHeight)
		if (not data.scrollframe:IsShown()) then
			data.scrollframe:Show()
		end
		if (data.OnDisplayValueChanged) then
			data.OnDisplayValueChanged(self, value)
		end
	end

	if (value == max) or (value == min) or (value/max >= data.sparkMaxPercent) or (value/max <= data.sparkMinPercent) then
		if spark:IsShown() then
			spark:Hide()
		end
	else
		local scrollframe = data.scrollframe
		local sparkOffsetY = data.sparkOffset
		local sparkHeight = data.sparkHeight
		local leftCrop = data.barLeftCrop
		local rightCrop = data.barRightCrop

		local sparkWidth = math_sqrt((height/2)^2 - (math_abs((height/2) - newHeight))^2) * 2
		local sparkOffsetX = (height - sparkWidth)/2
		local sparkOffsetY = data.sparkOffset * sparkHeight
		local freeSpace = height - leftCrop - rightCrop

		if sparkWidth > freeSpace then
			spark:SetSize(freeSpace, sparkHeight)
			spark:ClearAllPoints()

			if (leftCrop > freeSpace/2) then
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", leftCrop, sparkOffsetY)
			else
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY)
			end

			if (rightCrop > freeSpace/2) then
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -rightCrop, sparkOffsetY)
			else
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)
			end

		else
			-- fixing the stupid Legion no zero size problem
			if (sparkWidth == 0) then
				sparkWidth = 0.0001
			end

			spark:SetSize(sparkWidth, sparkHeight)
			spark:ClearAllPoints()
			spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY)
			spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)

		end
		if (not spark:IsShown()) then
			spark:Show()
		end
	end
end

local OnUpdate = function(self, elapsed)
	local data = Orbs[self]
	data.elapsed = (data.elapsed or 0) + elapsed
	if (data.elapsed < smoothingLimit) then
		return
	end

	if (data.disableSmoothing) then
		if (data.barValue <= data.barMin) or (data.barValue >= data.barMax) then
			Orig_SetScript(self, "OnUpdate", nil)
		end
	elseif (data.smoothing) then
		if (math_abs(data.barDisplayValue - data.barValue) < smoothingMinValue) then
			data.barDisplayValue = data.barValue
			data.smoothing = nil
		else
			-- The fraction of the total bar this total animation should cover
			local animsize = (data.barValue - data.smoothingInitialValue)/(data.barMax - data.barMin)

			-- Points per second on average for the whole bar
			local pps = (data.barMax - data.barMin)/(data.smoothingFrequency or smoothingFrequency)

			-- Position in time relative to the length of the animation, scaled from 0 to 1
			local position = (GetTime() - data.smoothingStart)/(data.smoothingFrequency or smoothingFrequency)
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
			Orig_SetScript(self, "OnUpdate", nil)
		end
	end

	Update(self, elapsed)

	if (data.OnUpdate) then
		data.OnUpdate(data.orb, data.elapsed)
	end

	data.elapsed = 0
end

local OnSizeChanged = function(self, width, height)
	local data = Orbs[self]
	local leftCrop = data.barLeftCrop
	local rightCrop = data.barRightCrop
	self:SetHitRectInsets(leftCrop, rightCrop, 0, 0)
	data.scrollchild:SetSize(width,height)
	data.scrollframe:SetWidth(width - (leftCrop + rightCrop))
	data.scrollframe:SetHorizontalScroll(leftCrop)
	data.scrollframe:ClearAllPoints()
	data.scrollframe:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	data.sparkHeight = height/4 >= 8 and height/4 or 8
	Update(self)
	if (data.OnSizeChanged) then
		data.OnSizeChanged(self, width, height)
	end
end

----------------------------------------------------------------
-- Custom API
----------------------------------------------------------------
Orb.SetSmoothHZ = function(self, smoothingFrequency)
	Orbs[self].smoothingFrequency = smoothingFrequency
end

Orb.DisableSmoothing = function(self, disableSmoothing)
	Orbs[self].disableSmoothing = disableSmoothing
end

-- forces a hard reset to zero
Orb.Clear = function(self)
	local data = Orbs[self]
	data.barValue = data.barMin
	data.barDisplayValue = data.barMin
	Update(self)
end

Orb.SetSparkTexture = function(self, path)
	Orbs[self].spark:SetTexture(path)
	Update(self)
end

Orb.SetSparkColor = function(self, ...)
	Orbs[self].spark:SetVertexColor(...)
end

Orb.SetSparkMinMaxPercent = function(self, min, max)
	local data = Orbs[self]
	data.sparkMinPercent = min
	data.sparkMinPercent = max
end

Orb.SetSparkBlendMode = function(self, blendMode)
	Orbs[self].spark:SetBlendMode(blendMode)
end

-- Fancy method allowing us to crop the orb's sides
Orb.SetCrop = function(self, leftCrop, rightCrop)
	local data = Orbs[self]
	data.barLeftCrop = leftCrop
	data.barRightCrop = rightCrop
	self:SetSize(data.scrollchild:GetSize())
end

Orb.GetCrop = function(self)
	local data = Orbs[self]
	return data.barLeftCrop, data.barRightCrop
end

----------------------------------------------------------------
-- Standard API
----------------------------------------------------------------
-- Sets the value the orb should move towards
Orb.SetValue = function(self, value, overrideSmoothing)
	local data = Orbs[self]
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
		if (not Orig_GetScript(self, "OnUpdate")) then
			Orig_SetScript(self, "OnUpdate", OnUpdate)
		end
	end
	Update(self)
end

Orb.SetMinMaxValues = function(self, min, max, overrideSmoothing)
	local data = Orbs[self]
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

Orb.GetValue = function(self)
	return Orbs[self].barValue
end

Orb.GetMinMaxValues = function(self)
	local data = Orbs[self]
	return data.barMin, data.barMax
end

Orb.SetStatusBarColor = function(self, ...)
	local data = Orbs[self]
	local r, g, b = ...
	data.layer1:SetVertexColor(r, g, b)
	data.layer2:SetVertexColor(r * 4/5, g * 4/5 * 3/4, b * 4/5)
	data.layer3:SetVertexColor(r * 3/4, g * 3/4 * 2/3, b * 3/4)
	data.layer4:SetVertexColor(r * 2/3, g * 2/3 * 1/2, b * 2/3)
	data.spark:SetVertexColor(r, g *3/4, b)
end

Orb.GetStatusBarColor = function(self, id)
	local r, g, b = Orbs[self].layer1:GetVertexColor()
	return r, g, b
end

Orb.SetStatusBarTexture = function(self, ...)
	local data = Orbs[self]

	-- set all the layers at once
	local numArgs = select("#", ...)
	for i = 1, numArgs do
		local layer = data["layer"..i]
		if (not layer) then
			break
		end
		local path = select(i, ...)
		layer:SetTexture(path)
	end

	-- We hide layers that aren't set
	for i = numArgs+1,4 do
		local layer = data["layer"..i]
		if (layer) then
			layer:SetTexture(nil)
		end
	end
end

Orb.GetStatusBarTexture = function(self)
	local data = Orbs[self]
	return data.layer1, data.layer2, data.layer3, data.layer4
end

-- Can not allow the scaffold to get its scripts overwritten
Orb.SetScript = function(self, ...)
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		Orbs[self].OnUpdate = func
	elseif (scriptHandler == "OnSizeChanged") then
		Orbs[self].OnSizeChanged = func
	elseif (scriptHandler == "OnDisplayValueChanged") then
		Orbs[self].OnDisplayValueChanged = func
	else
		Orig_SetScript(self, ...)
	end
end

Orb.GetScript = function(self, ...)
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		return Orbs[self].OnUpdate
	elseif (scriptHandler == "OnSizeChanged") then
		return Orbs[self].OnSizeChanged
	elseif (scriptHandler == "OnDisplayValueChanged") then
		return Orbs[self].OnDisplayValueChanged
	else
		return Orig_GetScript(self, ...)
	end
end

Orb.GetAnchor = function(self) return Orbs[self].scrollframe end
Orb.GetOverlay = function(self) return Orbs[self].scrollframe end
Orb.GetObjectType = function(self) return "StatusBar" end
Orb.IsObjectType = function(self, type) return type == "Orb" or type == "StatusBar" or type == "Frame" end
Orb.IsForbidden = function(self) return true end

lib.CreateOrb = function(self, name, parent, template, rotateClockwise, speedModifier)

	local orb = setmetatable(CreateFrame("Frame", name, parent, template), Orb_MT)
	orb:SetSize(1,1)
	Orig_SetScript(orb, "OnSizeChanged", OnSizeChanged)

	-- The scrollchild is where we put rotating textures that needs to be cropped.
	local scrollchild = CreateFrame("Frame", nil, orb)
	scrollchild:SetFrameLevel(orb:GetFrameLevel())
	scrollchild:SetSize(1,1)

	-- The scrollframe defines the height/filling of the orb,
	-- and is where the actual cropping of the textures occur.
	-- We need this anchored to the bottom,
	-- its height a fraction of the frame height,
	-- and its sides subjective to our custom crop.
	--
	-- Note: Even though his is a frame, it's comparable to the statusbar texture
	-- in regular statusbars when it comes to layout and anchoring.
	local scrollframe = CreateFrame("ScrollFrame", nil, orb)
	scrollframe:SetScrollChild(scrollchild)
	scrollframe:SetFrameLevel(orb:GetFrameLevel())
	scrollframe:SetPoint("BOTTOM")
	scrollframe:SetPoint("LEFT")
	scrollframe:SetPoint("RIGHT")
	scrollframe:SetSize(1,1)

	-- The overlay is meant to hold overlay textures like the spark.
	local overlay = CreateFrame("Frame", nil, scrollframe)
	overlay:SetFrameLevel(scrollframe:GetFrameLevel() + 2)
	overlay:SetAllPoints(orb)

	local orbTex1 = scrollchild:CreateTexture()
	orbTex1:SetDrawLayer("BACKGROUND", 0)
	orbTex1:SetAllPoints()

	local orbTex2 = scrollchild:CreateTexture()
	orbTex2:SetDrawLayer("BACKGROUND", -1)
	orbTex2:SetAllPoints()

	local orbTex3 = scrollchild:CreateTexture()
	orbTex3:SetDrawLayer("BACKGROUND", -2)
	orbTex3:SetAllPoints()

	local orbTex4 = scrollchild:CreateTexture()
	orbTex4:SetDrawLayer("BACKGROUND", -3)
	orbTex4:SetAllPoints()

	-- Alpha values for top two layers
	local high, low = .75, .25

	-- Layer one animations
	local t1ag1 = orbTex1:CreateAnimationGroup()

		local t1a2 = t1ag1:CreateAnimation("Alpha")
		t1a2:SetFromAlpha(low)
		t1a2:SetToAlpha(high)
		t1a2:SetDuration(6)
		t1a2:SetOrder(1)

		local t1a3 = t1ag1:CreateAnimation("Alpha")
		t1a3:SetFromAlpha(high)
		t1a3:SetToAlpha(low)
		t1a3:SetDuration(3)
		t1a3:SetOrder(2)

	t1ag1:SetLooping("REPEAT")
	t1ag1:Play()

	local t1ag2 = orbTex1:CreateAnimationGroup()

		local t1ag2a1 = t1ag2:CreateAnimation("Rotation")
		t1ag2a1:SetDegrees(-360)
		t1ag2a1:SetDuration(24)
		t1ag2a1:SetOrder(1)

	t1ag2:SetLooping("REPEAT")
	t1ag2:Play()

	-- Layer two animations
	local t2ag1 = orbTex2:CreateAnimationGroup()

		local t2a2 = t2ag1:CreateAnimation("Alpha")
		t2a2:SetFromAlpha(high)
		t2a2:SetToAlpha(low)
		t2a2:SetDuration(6)
		t2a2:SetOrder(1)

		local t2a3 = t2ag1:CreateAnimation("Alpha")
		t2a3:SetFromAlpha(low)
		t2a3:SetToAlpha(high)
		t2a3:SetDuration(3)
		t2a3:SetOrder(2)

	t2ag1:SetLooping("REPEAT")
	t2ag1:Play()

	local t2ag2 = orbTex2:CreateAnimationGroup()

		local t2ag2a1 = t2ag2:CreateAnimation("Rotation")
		t2ag2a1:SetDegrees(360)
		t2ag2a1:SetDuration(24)
		t2ag2a1:SetOrder(1)

	t2ag2:SetLooping("REPEAT")
	t2ag2:Play()

	-- The spark will be cropped,
	-- and only what's in the filled part of the orb will be visible.
	local spark = scrollchild:CreateTexture()
	spark:SetDrawLayer("BORDER", 1)
	spark:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
	spark:SetPoint("TOPRIGHT", scrollframe, "TOPRIGHT", 0, 0)
	spark:SetSize(1,1)
	spark:SetAlpha(.6)
	spark:SetBlendMode("ADD")
	spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical spark being 32x9px, from 0,11px to 32,19px
	spark:SetTexCoord(1,11/32,0,11/32,1,19/32,0,19/32)-- ULx,ULy,LLx,LLy,URx,URy,LRx,LRy
	spark:Hide()

	local data = {}

	-- framework
	data.scrollchild = scrollchild
	data.scrollframe = scrollframe
	data.overlay = overlay

	-- layers
	data.layer1 = orbTex1
	data.layer2 = orbTex2
	data.layer3 = orbTex3
	data.layer4 = orbTex4
	data.spark = spark

	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing
	data.barLeftCrop = 0 -- percentage of the orb cropped from the left
	data.barRightCrop = 0 -- percentage of the orb cropped from the right
	data.barSmoothingMode = "bezier-fast-in-slow-out"

	data.sparkHeight = 8
	data.sparkOffset = 1/32
	data.sparkMinPercent = 1/100
	data.sparkMaxPercent = 99/100

	Orbs[orb] = data

	Update(orb)

	return orb
end

local mixins = {
	CreateOrb = true
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
