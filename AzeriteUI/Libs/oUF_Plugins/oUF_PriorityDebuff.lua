--[[
# Element: Priority Debuff Icon

Shows a high priority debuff icon, including boss debuffs and dispellable debuffs.

## Widget

PriorityDebuff - Must be a frame.

## Sub-Widgets

icon - A `Texture` used to represent the debuff texture.


--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

--local LCD = oUF.isClassic and LibStub('LibClassicDurations', true)
-- Add in support for LibClassicDurations.
local LCD
if (oUF.isClassic) then
	LCD = LibStub and LibStub("LibClassicDurations", true)
	if (LCD) then
		local ADDON, Private = ...
		LCD:RegisterFrame(Private)
	end
end

-- Lua API
local next = next
local select = select
local type = type

-- WoW API
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpellInfo = GetSpellInfo
local IsUsableSpell = IsUsableSpell
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitIsCharmed = UnitIsCharmed

-- Player Class Constant
local _,playerClass = UnitClass('player')

-- Higher number means higher priority.
local DispellPriority = {
	['Boss'] 	= 5, -- higher or lower?
	['Magic']	= 4,
	['Curse']	= 3,
	['Disease']	= 2,
	['Poison']	= 1
}

-- Retail
local DispelTypesBySpec = {
	[62] = { -- Arcane Mage
		Curse = true
	},
	[63] = { -- Fire Mage
		Curse = true
	},
	[64] = { -- Frost Mage
		Curse = true
	},
	[65] = { -- Holy Paladin
		Magic = true,
		Poison = true,
		Disease = true
	},
	[66] = { -- Protection Paladin
		Poison = true,
		Disease = true
	},
	[70] = { -- Retribution Paladin
		Poison = true,
		Disease = true
	},
	[102] = { -- Balance Druid
		Curse = true,
		Poison = true
	},
	[103] = { -- Feral Druid
		Curse = true,
		Poison = true
	},
	[104] = { -- Guardian Druid
		Curse = true,
		Poison = true
	},
	[105] = { -- Restoration Druid
		Magic = true,
		Curse = true,
		Poison = true
	},
	[256] = { -- Discipline Priest
		Magic = true,
		Disease = true
	},
	[257] = { -- Holy Priest
		Magic = true,
		Disease = true
	},
	[258] = { -- Shadow Priest
		Magic = true,
		Disease = true
	},
	[262] = { -- Elemental Shaman
		Curse = true
	},
	[263] = { -- Enhancement Shaman
		Curse = true
	},
	[264] = { -- Restoration Shaman
		Magic = true,
		Curse = true
	},
	[268] = { -- Brewmaster Monk
		Poison = true,
		Disease = true
	},
	[269] = { -- Windwalker Monk
		Poison = true,
		Disease = true
	},
	[270] = { -- Mistweaver Monk
		Magic = true,
		Poison = true,
		Disease = true
	},
	[1467] = { -- Devastation Evoker
		Poison = true,
		Disease = function() return IsUsableSpell(GetSpellInfo(374251)) end,
		Curse = function() return IsUsableSpell(GetSpellInfo(374251)) end
	},
	[1468] = { -- Preservation Evoker
		Magic = true,
		Poison = true,
		Disease = function() return IsUsableSpell(GetSpellInfo(374251)) end,
		Curse = function() return IsUsableSpell(GetSpellInfo(374251)) end
	},
	[1473] = { -- Augmentation Evoker
		Poison = true,
		Disease = function() return IsUsableSpell(GetSpellInfo(374251)) end,
		Curse = function() return IsUsableSpell(GetSpellInfo(374251)) end
	}
}

-- Classic and Wrath
local DispelTypesByClass = {
	PRIEST = {
		Magic = true,
		Disease = true,
	},
	MAGE = {
		Curse = true,
	},
	PALADIN = {
		Magic = true,
		Poison = true,
		Disease = true,
	},
	DRUID = {
		Curse = true,
		Poison = true,
	},
	SHAMAN = {
		Disease = true,
		Poison = true,
		-- Shamans 'Cleanse Spirit' restoration talent
		Curse = function() return IsUsableSpell(GetSpellInfo(51886)) end
	},
	WARLOCK = {
		-- Felhunter's Devour Magic or Doomguard's Dispel Magic
		Magic = function() return IsUsableSpell(GetSpellInfo(19736)) or IsUsableSpell(GetSpellInfo(19476)) end
	},
	EVOKER = {
		Bleed = function() return IsUsableSpell(GetSpellInfo(374251)) end,
		Poison = true,
		Disease = function() return IsUsableSpell(GetSpellInfo(374251)) end,
		Curse = function() return IsUsableSpell(GetSpellInfo(374251)) end
	}
}

local function UpdateTooltip(element)
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:SetUnitAura(element.__owner.unit, element.spellID, 'HARMFUL')
end

local function onEnter(self)
	if(GameTooltip:IsForbidden() or not self:IsVisible()) then return end

	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')

	self:UpdateTooltip()
end

local function onLeave()
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:Hide()
end

-- Set whether an aura should be blacklisted and not shown
-- element:SetBlacklisted(spellID[, isBlacklisted])
local function SetBlacklisted(element, spellID, isBlacklisted)
	if(not self.blacklistedDebuffs) then
		self.blacklistedDebuffs = {}
	end
	self.blacklistedDebuffs[spellID] = isBlacklisted or nil
end

local function ClearBlacklist(element)
	if(self.blacklistedDebuffs) then
		self.blacklistedDebuffs = nil
	end
end

-- Add auras to the custom debuff filter
-- element:RegisterDebuffs([spellID, priority[, spellID, priority[, ...]]])
local function RegisterDebuffs(element, ...)
	if(not self.customDebuffs) then
		self.customDebuffs = {}
	end
	for i = 1,select('#', ...) do
		local spellID = select(i, ...)
		self.customDebuffs[spellID] = spellID
	end
end

-- Remove auras from the custom debuff filter
-- element:UnregisterDebuffs([spellID[, spellID[, ...]]])
local function UnregisterDebuffs(element, ...)
	if(not self.customDebuffs) then return end
	for i = 1,select('#', ...) do
		local spellID = select(i, ...)
		if(self.customDebuffs[spellID]) then
			self.customDebuffs[spellID] = nil
		end
	end
end

-- Remove all auras from the custom debuff filter
-- element:UnregisterAllDebuffs()
local function UnregisterAllDebuffs(element)
	self.customDebuffs = nil
end

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.PriorityDebuff

	-- We can't dispel from charmed or attackable units.
	-- Nor can we dispel if we can't dispel.
	local canDispel = not UnitCanAttack('player', unit) and not UnitIsCharmed(unit)

	--[[ Callback: PriorityDebuff:PreUpdate(unit)
	Called before the element has been updated.

	* self 		- the PriorityDebuff element
	* unit 		- the unit for which the update has been triggered (string)
	* event 	- the event which caused the update (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit,event)
	end

	-- Scan auras for dispellable or priority debuffs
	local name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom
	local priority = -1

	for i = 1,40 do
		local _name, _icon, _count, _debuffType, _duration, _expirationTime, _unitCaster, _, _, _spellID, _, _isBossDebuff = UnitAura(unit, i, 'HARMFUL')

		if (not name) then break end

		local isBlacklisted = self.blacklistedDebuffs and self.blacklistedDebuffs[spellID]
		if(not isBlacklisted) then

			if(_isBossDebuff) then
				local _priority = DispellPriority.Boss
				if(_priority and _priority > priority) then
					priority = _priority
					name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom = _name, _icon, _count, _debuffType, _duration, _expirationTime, _spellID, _isBossDebuff, nil
				end
			end

			if(self.dispelTypes and canDispel) then
				local _priority = self.dispelTypes[_debuffType]
				if(_priority and _priority > priority) then
					priority = _priority
					name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom = _name, _icon, _count, _debuffType, _duration, _expirationTime, _spellID, _isBossDebuff, nil
				end
			end

			if(self.customDebuffs) then
				local _priority = self.customDebuffs[_spellID]
				if(_priority and _priority > priority) then
					priority = _priority
					name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom = _name, _icon, _count, _debuffType, _duration, _expirationTime, _spellID, _isBossDebuff, true
				end

			end
		end

	end

	-- Just for testing purposes. Tukz' idea.
	if(element.forceShow) then
		priority = 10000
		spellID = 47540
		name, _, icon = GetSpellInfo(spellID)
		count, debuffType, duration, expirationTime = 5, "Magic", 0, 60
	end

	if(priority > 0) then
		element.spellID = spellID

		if(element.icon) then element.icon:SetTexture(icon) end
		if(element.count) then element.count:SetText(count and count > 1 and count or '') end
		if(element.border) then

		end
		if(element.time) then

		end

		element:Show()
	else
		element.spellID = nil
		element:Hide()
	end

	--[[ Callback: PriorityDebuff:PostUpdate(event, isVisible, name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom)
	Called after the element has been updated.

	* self 				- the PriorityDebuff element
	* event 			- the event that caused the update (string)
	* isVisible 		- whether or not the element is visible (boolean)
	* name 				- name of the debuff (string)
	* icon 				- texture id or path of the debuff (number,string)
	* count 			- stack size of the debuff (number,nil)
	* debuffType 		- The locale-independent magic type of the aura:
						  Curse, Disease, Magic, Poison, otherwise nil.
	* duration 			- The full duration of the aura in seconds (number)
	* expirationTime 	- Time the aura expires compared to GetTime(),
						  e.g. to get the remaining duration: expirationtime - GetTime() (number)
	* spellID 			- The spell ID for e.g. GetSpellInfo() (number)
	* isBoss 			- If the aura was cast by a boss (boolean)
	* isCustom 			- If the aura was on the element's custom debuff list (boolean)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(event, priority > 0, name, icon, count, debuffType, duration, expirationTime, spellID, isBoss, isCustom)
	end

end

local function UpdateDispelTypes(self, event, unit, ...)
	if(event == 'UNIT_SPELLCAST_SUCCEEDED') then
		local unit, _, spellID = ...
		if(unit ~= 'player') then return end

		-- 200749 = 'Activating Specialization'
		-- 384255 = 'Changing Talents'
		if(spellID ~= 200749 and spellID ~= 384255) then return end

	elseif(event == 'CHARACTER_POINTS_CHANGED') then
		-- A 'change' of -1 indicates one used (learning a talent)
		-- A 'change' of 1 indicates one gained (leveling)
		local change = ...
		if (change and change > 0) then return end -- sometimes this can be nil, for some reason.
	end

	local dispelTypes

	if(oUF.isRetail) then
		local specID = GetSpecializationInfo(GetSpecialization() or 1)
		dispelTypes = specID and DispelTypesBySpec[specID]

	elseif(oUF.isClassic or oUF.isWrath) then
		dispelTypes = DispelTypesByClass[playerClass]
	end

	self.dispelTypes = dispelTypes and {} or nil

	-- Copy the table and parse functions
	-- for faster aura processing speed later.
	if(dispelTypes) then
		for dispelType,data in next,dispelTypes do
			if (type(data) == "function") then
				self.dispelTypes[dispelType] = data()
			else
				self.dispelTypes[dispelType] = data
			end
		end
	end
end

local function Path(self, ...)
	--[[ Override: PriorityDebuff.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.PriorityDebuff.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.PriorityDebuff
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		element.SetBlacklisted = SetBlacklisted
		element.ClearBlacklist = ClearBlacklist
		element.RegisterDebuffs = RegisterDebuffs
		element.UnregisterDebuffs = UnregisterDebuffs
		element.UnregisterAllDebuffs = UnregisterAllDebuffs

		if(element.disableMouse) then
			element.UpdateTooltip = nil
			element:SetScript('OnEnter', nil)
			element:SetScript('OnLeave', nil)
			element:EnableMouse(false)
		else
			element.UpdateTooltip = UpdateTooltip
			element:SetScript('OnEnter', onEnter)
			element:SetScript('OnLeave', onLeave)
			element:SetMouseClickEnabled(false) -- let clicks pass through(?)
			element:SetMouseMotionEnabled(true) -- show debuff tooltips
		end

		self:RegisterEvent('PLAYER_LOGIN', UpdateDispelTypes, true)

		if(oUF.isRetail) then
			self:RegisterEvent('PLAYER_TALENT_UPDATE', UpdateDispelTypes, true)
			self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateDispelTypes, true)
		end

		if(oUF.isClassic or oUF.isWrath) then
			self:RegisterEvent('CHARACTER_POINTS_CHANGED', UpdateDispelTypes, true)
		end

		self:RegisterEvent('UNIT_AURA', Update)

		return true
	end
end

local function Disable(self)
	local element = self.PriorityDebuff
	if(element) then

		self:UnregisterEvent('PLAYER_LOGIN', UpdateDispelTypes)

		if(oUF.isRetail) then
			self:UnregisterEvent('PLAYER_TALENT_UPDATE', UpdateDispelTypes)
			self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateDispelTypes)
		end

		if(oUF.isClassic or oUF.isWrath) then
			self:UnregisterEvent('CHARACTER_POINTS_CHANGED', UpdateDispelTypes)
		end

		self:UnregisterEvent('UNIT_AURA', Update)

		element:Hide()
	end
end

oUF:AddElement('PriorityDebuff', Path, Enable, Disable)
