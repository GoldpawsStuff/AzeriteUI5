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
local Addon, ns = ...
local API = ns.API or {}
ns.API = API

local Colors = ns.Colors

-- WoW API
local GetQuestGreenRange = GetQuestGreenRange
local GetScalingQuestGreenRange = GetScalingQuestGreenRange
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitEffectiveLevel = UnitEffectiveLevel or UnitLevel
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapDenied = UnitIsTapDenied
local UnitLevel = UnitLevel
local UnitPlayerControlled = UnitPlayerControlled
local UnitQuestTrivialLevelRange = UnitQuestTrivialLevelRange
local UnitQuestTrivialLevelRangeScaling = UnitQuestTrivialLevelRangeScaling
local UnitReaction = UnitReaction

-- Retrieve a unit's color
local GetUnitColor = function(unit)
	if (unit) then
		if ((not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit) and UnitCanAttack("player", unit)) then
			color = Colors.tapped
		elseif (not UnitIsConnected(unit)) then
			color = Colors.disconnected
		elseif (UnitIsDeadOrGhost(unit)) then
			color = Colors.dead
		elseif (UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			if class then
				color = Colors.class[class]
			else
				color = Colors.disconnected
			end
		else
			local reaction = UnitReaction(unit, "player")
			if (reaction) then
				color = Colors.reaction[reaction]
			else
				color = Colors.offwhite
			end
		end
	end
	return color
end

-- Unit difficulty coloring.
local GetDifficultyColor = (ns.IsClassic or ns.IsTBC or ns.IsWrath) and function(level, isScaling)
	local colors = Colors.quest
	local levelDiff = level - UnitLevel("player")
	if (isScaling) then
		if (levelDiff > 5) then
			return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
		elseif (levelDiff > 3) then
			return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
		elseif (levelDiff >= 0) then
			return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
		elseif (-levelDiff <= GetScalingQuestGreenRange()) then
			return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
		else
			return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
		end
	else
		if (levelDiff > 5) then
			return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
		elseif (levelDiff > 3) then
			return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
		elseif (levelDiff >= -2) then
			return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
		elseif (-levelDiff <= GetQuestGreenRange()) then
			return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
		else
			return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
		end
	end
end or function(level, isScaling)
	local colors = Colors.quest
	if (isScaling) then
		local levelDiff = level - UnitEffectiveLevel("player")
		if (levelDiff > 5) then
			return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
		elseif (levelDiff > 3) then
			return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
		elseif (levelDiff >= 0) then
			return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
		elseif (-levelDiff <= -UnitQuestTrivialLevelRangeScaling("player")) then
			return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
		else
			return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
		end
	else
		local levelDiff = level - UnitLevel("player")
		if (levelDiff > 5) then
			return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
		elseif (levelDiff > 3) then
			return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
		elseif (levelDiff >= -4) then
			return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
		elseif (-levelDiff <= -UnitQuestTrivialLevelRange("player")) then
			return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
		else
			return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
		end
	end
end


-- Global API
---------------------------------------------------------
API.GetUnitColor = GetUnitColor
API.GetDifficultyColorByLevel = GetDifficultyColor
