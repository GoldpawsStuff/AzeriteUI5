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

if (not ns.IsRetail) then return end

ns.AuraSorts = ns.AuraSorts or {}

-- Lua API
local math_huge = math.huge
local table_sort = table.sort

-- Data
local Spells = ns.AuraData.Spells
local Hidden = ns.AuraData.Hidden
local Priority = ns.AuraData.Priority

-- https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataByAuraInstanceID
local Aura_Sort = function(a, b)

	-- Debuffs first
	local aHarm = a.isHarmful
	local bHarm = b.isHarmful
	if (aHarm ~= bHarm) then
		return aHarm
	end

	-- Show priority auras first
	local aPrio = a.spellId and Priority[a.spellId]
	local bPrio = b.spellId and Priority[b.spellId]
	if (aPrio ~= bPrio) then
		return aPrio
	end

	-- Player applied HoTs that we would display on nameplates
	local aHoT = not a.isHarmful and a.isPlayerAura and a.canApplyAura
	local bHoT = not b.isHarmful and b.isPlayerAura and b.canApplyAura
	if (aHoT ~= bHoT) then
		return aHoT
	end

	-- Playered applied debuffs that would display by default on nameplates
	local aPlate = a.nameplateShowAll or (a.nameplateShowPersonal and a.isPlayerAura)
	local bPlate = b.nameplateShowAll or (b.nameplateShowPersonal and b.isPlayerAura)
	if (aPlate ~= bPlate) then
		return aPlate
	end

	-- Player first, includes procs and zone buffs.
	if (a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	-- No duration last, short times first.
	local aTime = (not a.duration or a.duration == 0) and math_huge or a.expirationTime or -1
	local bTime = (not b.duration or b.duration == 0) and math_huge or b.expirationTime or -1

	if (aTime ~= bTime) then
		return aTime < bTime
	end

	return a.auraInstanceID < b.auraInstanceID
end

-- The alternate function is meant to mimic Blizzard sorting.
local Aura_Sort_Alternate = function(a, b)

	-- Player applied HoTs that we would display on nameplates
	local aHoT = not a.isHarmful and a.isPlayerAura and a.canApplyAura
	local bHoT = not b.isHarmful and b.isPlayerAura and b.canApplyAura
	if (aHoT ~= bHoT) then
		return aHoT
	end

	-- Playered applied debuffs that would display by default on nameplates
	local aPlate = a.nameplateShowAll or (a.nameplateShowPersonal and a.isPlayerAura)
	local bPlate = b.nameplateShowAll or (b.nameplateShowPersonal and b.isPlayerAura)
	if (aPlate ~= bPlate) then
		return aPlate
	end

	-- Player first, includes procs and zone buffs.
	if (a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	-- No duration last, short times first.
	--local aTime = (not a.duration or a.duration == 0) and math_huge or a.expirationTime or -1
	--local bTime = (not b.duration or b.duration == 0) and math_huge or b.expirationTime or -1

	--if (aTime ~= bTime) then
	--	return aTime < bTime
	--end

	return a.auraInstanceID < b.auraInstanceID
end

ns.AuraSorts.AlternateFuncton = Aura_Sort_Alternate
ns.AuraSorts.Alternate = function(element, max)
	table_sort(element, ns.AuraSorts.AlternateFuncton)
	return 1, #element
end

ns.AuraSorts.DefaultFunction = Aura_Sort
ns.AuraSorts.Default = function(element, max)
	table_sort(element, ns.AuraSorts.DefaultFunction)
	return 1, #element
end
