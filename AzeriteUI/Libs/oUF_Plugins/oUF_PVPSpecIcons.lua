--[[
# Element: PVP Spec Icon

Toggles the visibility of an indicator showing the player's PvP spec.

## Widget

PVPSpecIcon - Any UI widget.

## Sub-Widgets

icon - A `Texture` used to represent the PvP spec in arenas or faction elsewhere.

--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

local Update = function(self, event, unit)
	if(event == 'ARENA_OPPONENT_UPDATE' and unit ~= self.unit) then return end
	local element = self.PVPSpecIcon

	local _, instanceType = IsInInstance()
	element.instanceType = instanceType

	--[[ Callback: PVPSpecIcon:PreUpdate(unit)
	Called before the element has been updated.

	* self - the PVPSpecIcon element
	* unit - the unit for which the update has been triggered (string)
	* event - the event which caused the update (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit,event)
	end

	if(instanceType == 'arena') then
		local ID = self.unit:match('arena(%d)') or self:GetID() or 0
		local specID = GetArenaOpponentSpec(tonumber(ID))
		if(specID and specID > 0) then
			local _, _, _, icon = GetSpecializationInfoByID(specID);
			element.icon:SetTexture(icon)
		else
			element.icon:SetTexture([[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]])
		end
	else
		local unitFactionGroup = UnitFactionGroup(self.unit)
		if(unitFactionGroup == 'Horde') then
			element.icon:SetTexture([[Interface\Icons\INV_BannerPVP_01]])
		elseif(unitFactionGroup == 'Alliance') then
			element.icon:SetTexture([[Interface\Icons\INV_BannerPVP_02]])
		else
			element.icon:SetTexture([[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]])
		end
	end

	element:Show()

	--[[ Callback: PVPSpecIcon:PostUpdate(event)
	Called after the element has been updated.

	* self - the PVPSpecIcon element
	* event - the event that caused the update (string)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(event)
	end
end

local function Path(self, ...)
	--[[ Override: PVPSpecIcon.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.PVPSpecIcon.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.PVPSpecIcon
	if(element) then
		element.__owner = self

		self:RegisterEvent('ARENA_OPPONENT_UPDATE', Path, true)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', Path, true)
		if(oUF.isRetail) then
			self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS', Path)
		end

		if(not element.icon) then
			element.icon = element:CreateTexture(nil, 'OVERLAY')
			element.icon:SetAllPoints(element)
			element.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		end

		return true
	end
end

local function Disable(self)
	local element = self.PVPSpecIcon
	if(element) then
		if(oUF.isRetail) then
			self:UnregisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS', Path)
		end
		self:UnregisterEvent('ARENA_OPPONENT_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ENTERING_WORLD', Path)

		element:Hide()
	end
end

oUF:AddElement('PVPSpecIcon', Path, Enable, Disable)
