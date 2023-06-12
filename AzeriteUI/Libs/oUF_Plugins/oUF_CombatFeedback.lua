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
local _, ns = ...
local oUF = ns.oUF

-- Lua API
local math_floor = math.floor
local next = next
local pairs = pairs
local string_format = string.format
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetTime = GetTime

local damage_format = '-%s'
local heal_format = '+%s'
local maxAlpha = .6
local updateFrame
local feedback = {}

-- Sourced from FrameXML\CombatFeedback.lua
local CombatFeedbackText = CombatFeedbackText
local FADEINTIME = COMBATFEEDBACK_FADEINTIME -- 0.2
local HOLDTIME = COMBATFEEDBACK_HOLDTIME -- 0.7
local FADEOUTTIME = COMBATFEEDBACK_FADEOUTTIME -- 0.3

local colors = {
	STANDARD		= { 1, 1, 1 },
	IMMUNE			= { 1, 1, 1 },
	DAMAGE			= { 1, 0, 0 },
	CRUSHING		= { 1, 0, 0 },
	CRITICAL		= { 1, 0, 0 },
	GLANCING		= { 1, 0, 0 },
	ABSORB			= { 1, 1, 1 },
	BLOCK			= { 1, 1, 1 },
	RESIST			= { 1, 1, 1 },
	MISS			= { 1, 1, 1 },
	HEAL			= { 0, 1, 0 },
	CRITHEAL		= { 0, 1, 0 },
	ENERGIZE		= { 0.41, 0.8, 0.94 },
	CRITENERGIZE	= { 0.41, 0.8, 0.94 },
}

local function large(value)
	value = tonumber(value)
	if (not value) then
		return ""
	end
	if (value >= 1e8) then 		return string_format("%.0fm", value/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (value >= 1e6) then 	return string_format("%.1fm", value/1e6) 	-- 1.0m - 99.9m
	elseif (value >= 1e5) then 	return string_format("%.0fk", value/1e3) 	-- 100k - 999k
	elseif (value >= 1e3) then 	return string_format("%.1fk", value/1e3) 	-- 1.0k - 99.9k
	elseif (value > 0) then 	return tostring(math_floor(value))			-- 1 - 999
	else 						return ""
	end
end

local function short(value)
	value = tonumber(value)
	if (not value) then
		return ""
	end
	if (value >= 1e9) then							return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e6) then 						return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e3) or (value <= -1e3) then 	return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	elseif (value > 0) then							return tostring(math_floor(value))
	else 											return ""
	end
end

if (GetLocale() == "zhCN") then
	large = function(value)
		value = tonumber(value)
		if (not value) then
			return ""
		end
		if (value >= 1e8) then 							return string_format("%.2f亿", value/1e8)
		elseif (value >= 1e4) then 						return string_format("%.2f万", value/1e4)
		elseif (value > 0) then 						return tostring(math_floor(value))
		else 											return ""
		end
	end
	short = function(value)
		value = tonumber(value)
		if (not value) then
			return ""
		end
		if (value >= 1e8) then							return ("%.2f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif (value >= 1e4) or (value <= -1e3) then	return ("%.2f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		elseif (value > 0) then 						return tostring(math_floor(value))
		else 											return ""
		end
	end
end

local function createUpdateFrame()
	if(updateFrame) then return end
	updateFrame = CreateFrame("Frame")
	updateFrame.elapsed = 0
	updateFrame:Hide()
	updateFrame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		if (self.elapsed < .05) then
			return
		end
		self.elapsed = 0
		if next(feedback) == nil then
			self:Hide()
			return
		end
		local time = GetTime()
		for object, startTime in pairs(feedback) do
			local feedbackText = object.CombatFeedback
			local maxalpha = feedbackText.maxAlpha or maxAlpha
			local elapsedTime = time - startTime
			if ( elapsedTime < FADEINTIME ) then
				local alpha = maxalpha * (elapsedTime / FADEINTIME)
				feedbackText:SetAlpha(alpha)

			elseif ( elapsedTime < (FADEINTIME + HOLDTIME) ) then
				feedbackText:SetAlpha(maxalpha)

			elseif ( elapsedTime < (FADEINTIME + HOLDTIME + FADEOUTTIME) ) then
				local alpha = maxalpha - maxalpha*((elapsedTime - HOLDTIME - FADEINTIME) / FADEOUTTIME)
				feedbackText:SetAlpha(alpha)

			else
				feedbackText:Hide()
				feedback[object] = nil
			end
		end
	end)
end

local function Update(self, event, unit, ...)
	if(not unit) or (unit ~= self.unit) then
		return
	end

	local element = self.CombatFeedback
	local colors = self.colors.feedback or colors

	local event, flagText, amount, schoolMask = ...
	local color, fontType, text, arg

	if (event == 'IMMUNE') then
		fontType ='small'
		text = CombatFeedbackText[event]
		color = colors.IMMUNE

	elseif (event == 'WOUND') then
		if (amount ~= 0) then

			if (flags == 'CRITICAL') then
				fontType ='large'
				color = colors.CRITICAL

			elseif (flags == 'CRUSHING') then
				fontType ='large'
				color = colors.CRUSHING

			elseif (flags == 'GLANCING') then
				fontType ='small'
				color = colors.GLANCING
			else
				color = colors.DAMAGE
			end

			if (flags == 'BLOCK_REDUCED') then
				text = COMBAT_TEXT_BLOCK_REDUCED:format(short(text))
			else
				text = damage_format
				arg = large(amount)
			end

		elseif (flags == 'ABSORB') then
			fontType ='small'
			text = CombatFeedbackText['ABSORB']
			color = colors.ABSORB

		elseif (flags == 'BLOCK') then
			fontType ='small'
			text = CombatFeedbackText['BLOCK']
			color = colors.BLOCK

		elseif (flags == 'RESIST') then
			fontType ='small'
			text = CombatFeedbackText['RESIST']
			color = colors.RESIST

		else
			text = CombatFeedbackText['MISS']
			color = colors.MISS
		end

	elseif (event == 'BLOCK') then
		fontType ='small'
		text = CombatFeedbackText[event]
		color = colors.BLOCK

	elseif (event == 'HEAL') then
		text = heal_format
		arg = large(amount)
		if (flags == 'CRITICAL') then
			fontType ='large'
			color = colors.CRITHEAL
		else
			color = colors.HEAL
		end

	elseif (event == 'ENERGIZE') then
		text = large(amount)
		if (flags == 'CRITICAL') then
			fontType = 'large'
			color = colors.CRITENERGIZE
		else
			color = colors.ENERGIZE
		end
	else
		text = CombatFeedbackText[event]
		color = colors.STANDARD
	end

	if (text) then
		if (fontType ~= element.fontType) then
			local fontObject
			if (fontType == 'small') then
				fontObject = element.feedbackFontSmall

			elseif (fontType == 'large') then
				fontObject = element.feedbackFontLarge
			end
			element:SetFontObject(fontObject or element.feedbackFont)
			element.fontType = fontType
		end
		element:SetFormattedText(text, arg)
		element:SetTextColor(unpack(color or colors.STANDARD))
		element:SetAlpha(0)
		element:Show()
		feedback[self] = GetTime()
		updateFrame:Show()
	end
end

local function Path(self, ...)
	--[[ Override: CombatFeedback.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.CombatFeedback.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.CombatFeedback
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element:Show()

		createUpdateFrame()

		self:RegisterEvent('UNIT_COMBAT', Path)

		return true
	end
end

local function Disable(self)
	local element = self.CombatFeedback
	if(element) then
		element:Hide()
		feedback[self] = nil

		self:UnregisterEvent('UNIT_COMBAT', Path)
	end
end

oUF:AddElement('CombatFeedback', Path, Enable, Disable)
