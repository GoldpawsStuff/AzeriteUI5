--[[
# Element: Trinket Icon

Toggles the visibility of an indicator showing the player's PvP trinket availability or cooldown.

## Widget

Trinket - Any UI widget.

## Sub-Widgets

icon                - A `Texture` used to represent the Trinket.
cd                  - A 'Cooldown' used to indicate remaining time before the Trinket is usable.

--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

local ClearCooldowns = function(self)
	local element = self.Trinket
	element.spellID = 0
	element.cd:Clear()
end

local function Update(self, event, ...)
	local element = self.Trinket
	local _, instanceType = IsInInstance()

	if(instanceType ~= 'arena') then
		element.icon:SetTexture(select(2, UnitFactionGroup('player')) == 'Horde' and [[Interface\Icons\inv_jewelry_trinketpvp_01]] or [[Interface\Icons\inv_jewelry_trinketpvp_02]])
		element:Hide()
		ClearCooldowns(self)
		return
	end

	--[[ Callback: Trinket:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Trinket element
	* event - the event which caused the update (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(event, ...)
	end

	if(event == 'ARENA_COOLDOWNS_UPDATE') then
		local unit = ...

		if(self.unit == unit) then
			C_PvP.RequestTrinketSpell(unit)

			local spellID, itemID, startTime, duration
			if (oUF.isWrath) then
				spellID, itemID, startTime, duration = C_PvP.GetArenaTrinketInfo(unit)
			else
				spellID, startTime, duration = C_PvP.GetArenaTrinketInfo(unit)
			end

			if(spellID and startTime ~= 0 and duration ~= 0) then
				CooldownFrame_Set(element.cd, startTime / 1000, duration / 1000, 1)
			else
				ClearCooldowns(self)
			end
		end
	elseif(event == 'ARENA_CROWD_CONTROL_SPELL_UPDATE') then
		local unit, spellID, itemID

		if (oUF.isWrath) then
			unit, spellID, itemID = ...
		else
			unit, spellID = ...
		end

		if(self.unit == unit) then
			if(itemID ~= 0) then
				local itemTexture = GetItemIcon(itemID)
				element.spellID = spellID
				element.icon:SetTexture(itemTexture)
			else
				--local _, _, spellTexture = GetSpellInfo(spellID)
				local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)
				element.spellID = spellID
				element.icon:SetTexture(spellTextureNoOverride)
			end
		end

	elseif(event == 'PLAYER_ENTERING_WORLD') then
		CooldownFrame_Set(element.cd, 1, 1, 1)
	end

	element:SetShown(element.spellID and element.spellID ~= 0)

	--[[ Callback: Trinket:PostUpdate(event)
	Called after the element has been updated.

	* self - the Trinket element
	* event - the event that caused the update (string)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(event, ...)
	end
end

local function Path(self, ...)
	--[[ Override: Trinket.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.Trinket.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.Trinket
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('ARENA_COOLDOWNS_UPDATE', Path, true)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', Path, true)
		self:RegisterEvent('ARENA_CROWD_CONTROL_SPELL_UPDATE', Path, true)
		if(oUF.isRetail) then
			self:RegisterEvent('PVP_MATCH_INACTIVE', ClearCooldowns, true)
		end

		if(not element.cd) then
			element.cd = CreateFrame('Cooldown', nil, element)
			element.cd:SetAllPoints(element)
		end

		if(not element.icon) then
			element.icon = element:CreateTexture(nil, 'BORDER')
			element.icon:SetAllPoints(element)
			element.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			element.icon:SetTexture(select(2, UnitFactionGroup('player')) == 'Horde' and [[Interface\Icons\inv_jewelry_trinketpvp_01]] or [[Interface\Icons\inv_jewelry_trinketpvp_02]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.Trinket
	if(element) then
		self:UnregisterEvent('ARENA_COOLDOWNS_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ENTERING_WORLD', Path)
		self:UnregisterEvent('ARENA_CROWD_CONTROL_SPELL_UPDATE', Path)
		if(oUF.isRetail) then
			self:UnregisterEvent('PVP_MATCH_INACTIVE', ClearCooldowns)
		end
		element:Hide()
	end
end

oUF:AddElement('Trinket', Path, Enable, Disable)
