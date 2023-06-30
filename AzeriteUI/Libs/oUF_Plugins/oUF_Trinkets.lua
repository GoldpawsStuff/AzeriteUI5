--[[
# Element: Trinket Icon

Toggles the visibility of an indicator showing the player's PvP trinket availability or cooldown.

## Widget

Trinket - Any UI widget.

## Sub-Widgets

icon                  - A `Texture` used to represent the Trinket.
cooldownFrame         - A 'Cooldown' used to indicate remaining time before the Trinket is usable.

--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

local Update = function(self, event, ...)
	local element = self.Trinket
	local _, instanceType = IsInInstance()

	if(instanceType ~= 'arena') then
		element.icon:SetTexture(select(2, UnitFactionGroup('player')) == 'Horde' and [[Interface\Icons\inv_jewelry_trinketpvp_01]] or [[Interface\Icons\inv_jewelry_trinketpvp_02]])
		element:Hide()

		return
	else
		element:Show()
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
		local tunit = self.unit

		if(self.unit == unit) then
			C_PvP.RequestCrowdControlSpell(unit)

			local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)

			if(spellID and startTime ~= 0 and duration ~= 0) then
				CooldownFrame_Set(element.cooldownFrame, startTime / 1000, duration / 1000, 1)
			end
		end
	elseif(event == 'ARENA_CROWD_CONTROL_SPELL_UPDATE') then
		local unit, spellID = ...

		if(self.unit == unit) then
			local _, _, spellTexture = GetSpellInfo(spellID)

			element.icon:SetTexture(spellTexture)
		end
	elseif(event == 'PLAYER_ENTERING_WORLD') then
		CooldownFrame_Set(element.cooldownFrame, 1, 1, 1)
	end

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

		if(not element.cooldownFrame) then
			element.cooldownFrame = CreateFrame('Cooldown', nil, element)
			element.cooldownFrame:SetAllPoints(element)
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
		element:Hide()
	end
end

oUF:AddElement('Trinket', Path, Enable, Disable)
