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
local Events = oUF.Tags.Events
local Methods = oUF.Tags.Methods

-- Lua API
local ipairs = ipairs
local math_max = math.max
local select = select
local string_find = string.find
local string_gsub = string.gsub
local string_len = string.len
local tonumber = tonumber
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local AbbreviateName = ns.API.AbbreviateName
local AbbreviateNumber = ns.API.AbbreviateNumber
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel

-- Colors
local c_gray = Colors.gray.colorCode
local c_normal = Colors.normal.colorCode
local c_rare = Colors.quality.Rare.colorCode
local c_red = Colors.red.colorCode
local c_paleblue = Colors.paleblue.colorCode
local r = "|r"

-- Strings
local L_AFK = AFK
local L_DEAD = DEAD
local L_OFFLINE = PLAYER_OFFLINE
local L_RARE = ITEM_QUALITY3_DESC

-- Textures
local T_BOSS = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14:-2:1|t"

-- Utility Functions
--------------------------------------------
-- Simplify the tagging process a little.
local prefix = function(msg)
	return string_gsub(msg, "*", ns.Prefix)
end

local getargs = function(...)
	local args = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		local num = tonumber(arg)
		if (num) then
			args[i] = num
		elseif (arg == "true" or arg == true) then
			args[i] = true
		elseif (arg == "nil" or arg == "false" or not arg) then
			args[i] = false
		else
			args[i] = arg
		end
	end
	return unpack(args)
end

local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

-- Tags
---------------------------------------------------------------------
if (ns.IsRetail) then
	Events[prefix("*:Absorb")] = "UNIT_ABSORB_AMOUNT_CHANGED"
	Methods[prefix("*:Absorb")] = function(unit)
		if (UnitIsDeadOrGhost(unit)) then
			return
		else
			local absorb = UnitGetTotalAbsorbs(unit) or 0
			if (absorb > 0) then
				return c_gray.." ("..r..c_normal..absorb..r..c_gray..")"..r
			end
		end
	end
end

Events[prefix("*:Classification")] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[prefix("*:Classification")] = function(unit)
		local l = UnitEffectiveLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
else
	Methods[prefix("*:Classification")] = function(unit)
		local l = UnitEffectiveLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
end

Events[prefix("*:Health")] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_FLAGS_CHANGED UNIT_CONNECTION GROUP_ROSTER_UPDATE"
Methods[prefix("*:Health")] = function(unit, realUnit, ...)
	local useSmart, useFull, hideStatus, showAFK = getargs(...)
	if (UnitIsDeadOrGhost(unit)) then
		return not hideStatus and L_DEAD
	elseif (not UnitIsConnected(realUnit or unit)) then
		return not hideStatus and L_OFFLINE
	elseif (showAFK and UnitIsAFK(realUnit or unit)) then
		return L_AFK
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if (maxHealth == 0) then return end
		if (useSmart) then
			local displayValue = health / maxHealth * 100 + .5
			displayValue = displayValue - displayValue%1

			if (displayValue < 100) then
				return displayValue
			else
				return AbbreviateNumber(health)
			end

		elseif (useFull) then
			return health..c_gray.."/"..r..maxHealth

		elseif (health > 0) then
			return AbbreviateNumber(health)
		end
	end
end

Events[prefix("*:HealthPercent")] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_FLAGS_CHANGED UNIT_CONNECTION"
Methods[prefix("*:HealthPercent")] = function(unit)
	if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
		return
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		local displayValue = health / maxHealth * 100 + .5
		return displayValue - displayValue%1
	end
end

Events[prefix("*:Mana")] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[prefix("*:Mana")] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local mana, maxMana = UnitPower(unit, Enum.PowerType.Mana), UnitPowerMax(unit, Enum.PowerType.Mana)
		if (maxMana > 0) then
			return AbbreviateNumber(mana)
		end
	end
end

Events[prefix("*:ManaText:Low")] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[prefix("*:ManaText:Low")] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local mana, maxMana = UnitPower(unit, Enum.PowerType.Mana), UnitPowerMax(unit, Enum.PowerType.Mana)
		if (maxMana > 0) then
			local perc = mana / maxMana
			if (perc < .25) then
				local value = perc * 100 + .5
				return c_red .. (value - value%1) .. r
			elseif (perc < .75) then
				local value = perc * 100 + .5
				return c_paleblue .. (value - value%1) .. r
			end
		end
	end
end

Events[prefix("*:Name")] = "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP GROUP_ROSTER_UPDATE"
Methods[prefix("*:Name")] = function(unit, realUnit, ...)
	local name = UnitName(realUnit or unit)
	if (not name) then
		return
	end

	local maxChars, showLevel, showLevelLast, showFull = getargs(...)
	local levelTextLength, levelText, shouldShowLevel = 0, nil, nil
	local fullName, fullLength = name, string_len(name) + (shouldShowLevel and levelTextLength or 0)
	local abbreviatedLength

	-- Create level text if requested.
	if (showLevel) then
		local level = UnitEffectiveLevel(realUnit or unit)
		if (level and level > 0) then
			local _,_,_,colorCode = GetDifficultyColorByLevel(level)
			levelText = colorCode .. level .. "|r"
			levelTextLength = level >= 100 and 5 or level >= 10 and 4 or 3
			shouldShowLevel = true
		end
	end

	-- Abbreviate when needed, but not when we have space.
	if (not showFull) and (not maxChars or fullLength > maxChars) then
		name = AbbreviateName(name)
		abbreviatedLength = string_len(name) + (shouldShowLevel and levelTextLength or 0)
	end

	-- Truncate when needed. Messy.
	if (maxChars) and (showFull and fullLength > maxChars) or (abbreviatedLength and abbreviatedLength > maxChars) then
		name = utf8sub(name, showLevel and (maxChars - levelTextLength) or maxChars)
	end

	if (shouldShowLevel) then
		if (showLevelLast) then
			name = name .. " |cff888888:|r" .. levelText
		else
			name = levelText .. "|cff888888:|r " .. name
		end
	end

	return name
end

Events[prefix("*:Power")] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[prefix("*:Power")] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local power = UnitPower(unit)
		return power > 0 and AbbreviateNumber(power)
	end
end

Events[prefix("*:Power:Full")] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[prefix("*:Power:Full")] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
		if (powerMax > 0) then
			return power..c_gray.."/"..r..powerMax
		end
	end
end

Events[prefix("*:Rare")] = "UNIT_CLASSIFICATION_CHANGED"
Methods[prefix("*:Rare")] = function(unit)
	local classification = UnitClassification(unit)
	local rare = classification == "rare" or classification == "rareelite"
	if (rare) then
		return c_rare.."("..L_RARE..")"..r
	end
end

Events[prefix("*:Rare:Suffix")] = "UNIT_CLASSIFICATION_CHANGED"
Methods[prefix("*:Rare:Suffix")] = function(unit)
	local r = Methods[prefix("*:Rare")](unit)
	return r and " "..r
end

Events[prefix("*:Dead")] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
Methods[prefix("*:Dead")] = function(unit)
	return UnitIsConnected(unit) and UnitIsDeadOrGhost(unit) and L_DEAD
end

Events[prefix("*:Offline")] = "UNIT_CONNECTION"
Methods[prefix("*:Offline")] = function(unit)
	return not UnitIsConnected(unit) and L_OFFLINE
end

Events[prefix("*:DeadOrOffline")] = "UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
Methods[prefix("*:DeadOrOffline")] = function(unit)
	return not UnitIsConnected(unit) and L_OFFLINE or UnitIsDeadOrGhost(unit) and L_DEAD
end

Events[prefix("*:Level")] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[prefix("*:Level")] = function(unit, asPrefix)
		local l = UnitEffectiveLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
else
	Methods[prefix("*:Level")] = function(unit, realUnit, asPrefix)
		local l = UnitEffectiveLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
end

Events[prefix("*:Level:Prefix")] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
Methods[prefix("*:Level:Prefix")] = function(unit, realUnit)
	local l = Methods[prefix("*:Level")](unit, realUnit, true)
	return (l and l ~= T_BOSS) and l.." " or l
end
