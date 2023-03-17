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
ns.AuraStyles = ns.AuraStyles or {}

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	if (self.isHarmful) then
		GameTooltip:SetUnitDebuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
	else
		GameTooltip:SetUnitBuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
	end
end

local OnEnter = function(self)
	if (GameTooltip:IsForbidden() or not self:IsVisible()) then return end
	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, self:GetParent().__restricted and "ANCHOR_CURSOR" or self:GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local OnClick = function(self, button, down)
	if (button == "RightButton") and (not InCombatLockdown()) then
		local unit = self:GetParent().__owner.unit
		if (not self.isHarmful) and (UnitExists(unit)) then
			CancelUnitBuff(unit, self:GetID(), self.filter)
		end
	end
end

ns.AuraStyles.CreateButton = function(element, position)
	local aura = CreateFrame("Button", element:GetDebugName() .. "Button" .. position, element)
	aura:RegisterForClicks("RightButtonUp")

	local icon = aura:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	aura.Icon = icon

	local border = CreateFrame("Frame", nil, aura, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.aura[1], Colors.aura[2], Colors.aura[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(aura:GetFrameLevel() + 2)
	aura.Border = border

	local count = aura.Border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 3)
	aura.Count = count

	local time = aura.Border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(14,true))
	time:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	time:SetPoint("TOPLEFT", aura, "TOPLEFT", -4, 4)
	aura.Time = time

	-- Using a virtual cooldown element with the timer attached,
	-- allowing them to piggyback on the back-end's cooldown updates.
	aura.Cooldown = ns.Widgets.RegisterCooldown(time)

	-- Replacing oUF's aura tooltips, as they are not secure.
	if (not element.disableMouse) then
		aura.UpdateTooltip = UpdateTooltip
		aura:SetScript("OnEnter", OnEnter)
		aura:SetScript("OnLeave", OnLeave)
	end

	return aura
end

ns.AuraStyles.CreateSmallButton = function(element, position)
	local aura = ns.AuraStyles.CreateButton(element, position)

	aura.Time:SetFontObject(GetFont(12,true))

	return aura
end

ns.AuraStyles.CreateButtonWithBar = function(element, position)
	local aura = ns.AuraStyles.CreateButton(element, position)

	local bar = element.__owner:CreateBar(nil, aura)
	bar:SetPoint("TOP", aura, "BOTTOM", 0, 0)
	bar:SetPoint("LEFT", aura, "LEFT", 1, 0)
	bar:SetPoint("RIGHT", aura, "RIGHT", -1, 0)
	bar:SetHeight(6)
	bar:SetStatusBarTexture(GetMedia("bar-small"))
	bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar.bg:SetColorTexture(.05, .05, .05, .85)
	aura.Bar = bar

	aura.Cooldown = ns.Widgets.RegisterCooldown(aura.Cooldown, bar)

	return aura
end

ns.AuraStyles.PlayerPostUpdateButton = function(element, button, unit, data, position)

	-- Border Coloring
	local color
	if (button.isHarmful and element.showDebuffType) or (not button.isHarmful and element.showBuffType) or (element.showType) then
		color = Colors.debuff[data.dispelName] or Colors.debuff.none
	else
		color = Colors.verydarkgray -- Colors.aura
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		--button.Bar:SetStatusBarColor(color[1], color[2], color[3])
	end

	-- Icon Coloring
	if (button.isHarmful)
	or (data.nameplateShowAll or (data.nameplateShowPersonal and data.isPlayerAura))
	or (not data.isHarmful and data.isPlayerAura and data.canApplyAura) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(1, 1, 1)

	elseif (data.isPlayerAura) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(.3, .3, .3)

	else
		button.Icon:SetDesaturated(true)
		button.Icon:SetVertexColor(.6, .6, .6)
	end

	--if (button.isHarmful) or (data.isPlayerAura and (data.nameplateShowAll or data.nameplateShowPersonal)) or (not button.isHarmful and data.isPlayerAura and data.canApplyAura) then
	--	button.Icon:SetDesaturated(false)
	--	button.Icon:SetVertexColor(1, 1, 1)
	--else
	--	button.Icon:SetDesaturated(true)
	--	button.Icon:SetVertexColor(.6, .6, .6)
	--end

end

ns.AuraStyles.TargetPostUpdateButton = function(element, button, unit, data, position)

	-- Stealable buffs
	--if(not button.isHarmful and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	--end

	-- Border Coloring
	local color
	if (button.isHarmful and element.showDebuffType) or (not button.isHarmful and element.showBuffType) or (element.showType) then
		color = Colors.debuff[data.dispelName] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

	-- Icon Coloring
	if (data.nameplateShowAll or (data.nameplateShowPersonal and data.isPlayerAura))
	or (not data.isHarmful and data.isPlayerAura and data.canApplyAura) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(1, 1, 1)

	elseif (data.isPlayerAura) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(.3, .3, .3)

	else
		button.Icon:SetDesaturated(true)
		button.Icon:SetVertexColor(.6, .6, .6)
	end

end

ns.AuraStyles.NameplatePostUpdateButton = function(element, button, unit, data, position)

	-- Stealable buffs
	--if(not button.isHarmful and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	--end

	-- Coloring
	local color
	if (button.isHarmful and element.showDebuffType) or (not button.isHarmful and element.showBuffType) or (element.showType) then
		color = Colors.debuff[data.dispelName] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

end

-- Wrath overrides
if (ns.IsRetail) then return end

UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID(), self.filter)
end

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
