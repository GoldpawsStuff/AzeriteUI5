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

if (ns.IsRetail) then return end

ns.AuraStyles = ns.AuraStyles or {}

-- Addon API
local Colors = ns.Colors

ns.AuraStyles.PlayerPostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	-- Border Coloring
	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray -- Colors.aura
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		--button.Bar:SetStatusBarColor(color[1], color[2], color[3])
	end

	-- Icon Coloring
	if (button.isPlayer or button.isDebuff) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(1, 1, 1)
	else
		button.Icon:SetDesaturated(true)
		button.Icon:SetVertexColor(.6, .6, .6)
	end

end

ns.AuraStyles.TargetPostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	-- Stealable buffs
	if(not button.isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end

	-- Border Coloring
	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

	-- Icon Coloring
	if (button.isPlayer) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(1, 1, 1)
	else
		button.Icon:SetDesaturated(true)
		button.Icon:SetVertexColor(.6, .6, .6)
	end

end

ns.AuraStyles.NameplatePostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	-- Stealable buffs
	if(not button.isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end

	-- Coloring
	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

end

ns.AuraStyles.ArenaPostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	-- Stealable buffs
	if(not button.isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end

	-- Coloring
	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

end
