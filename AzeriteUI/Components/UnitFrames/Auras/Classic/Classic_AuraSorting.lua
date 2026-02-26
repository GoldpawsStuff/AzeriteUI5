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
local _, ns = ...

ns.AuraSorts = ns.AuraSorts or {}

-- Lua API
local math_huge = math.huge
local table_sort = table.sort

-- Data
local Spells = ns.AuraData.Spells
local Hidden = ns.AuraData.Hidden
local Priority = ns.AuraData.Priority

local Aura_Sort = function(a, b)
	if (a and b) then
		if (a:IsShown() and b:IsShown()) then

			-- Debuffs first
			local aHarm = a.isDebuff
			local bHarm = b.isDebuff
			if (aHarm ~= bHarm) then
				return aHarm
			end

			-- These flags are supplied by the aura filters
			local aPlayer = a.isPlayer or false
			local bPlayer = b.isPlayer or false

			if (aPlayer == bPlayer) then

				local aTime = a.noDuration and math_huge or a.expiration or -1
				local bTime = b.noDuration and math_huge or b.expiration or -1
				if (aTime == bTime) then

					local aName = a.spell or ""
					local bName = b.spell or ""
					if (aName and bName) then
						local sortDirection = a:GetParent().sortDirection
						if (sortDirection == "DESCENDING") then
							return (aName < bName)
						else
							return (aName > bName)
						end
					end

				elseif (aTime and bTime) then
					local sortDirection = a:GetParent().sortDirection
					if (sortDirection == "DESCENDING") then
						return (aTime < bTime)
					else
						return (aTime > bTime)
					end
				else
					return (aTime) and true or false
				end

			else
				local sortDirection = a:GetParent().sortDirection
				if (sortDirection == "DESCENDING") then
					return (aPlayer and not bPlayer)
				else
					return (not aPlayer and bPlayer)
				end
			end
		else
			return (a:IsShown())
		end
	end
end

local Aura_Sort_Alternate = function(a, b)
	if (a and b) then
		if (a:IsShown() and b:IsShown()) then

			-- These flags are supplied by the aura filters
			local aPlayer = a.isPlayer or false
			local bPlayer = b.isPlayer or false

			if (aPlayer ~= bPlayer) then
				local sortDirection = a:GetParent().sortDirection
				if (sortDirection == "DESCENDING") then
					return (aPlayer and not bPlayer)
				else
					return (not aPlayer and bPlayer)
				end
			end
		else
			return (a:IsShown())
		end
	end
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
