--[[
# Element: Dispellable

Highlights debuffs that are dispelable by the player

## Widget

.Dispellable - A `table` to hold the sub-widgets.

## Sub-Widgets

.dispelIcon    - A `Button` to represent the icon of a dispellable debuff.
.dispelTexture - A `Texture` to be colored according to the debuff type.

## Notes

At least one of the sub-widgets should be present for the element to work.

The `.dispelTexture` sub-widget is updated by setting its color and alpha. It is always shown to allow the use on non-
texture widgets without the need to override the internal update function.

If mouse interactivity is enabled for the `.dispelIcon` sub-widget, 'OnEnter' and/or 'OnLeave' handlers will be set to
display a tooltip.

If `.dispelIcon` and `.dispelIcon.cd` are defined without a global name, one will be set accordingly by the element to
prevent /fstack errors.

The element uses oUF's `debuff` colors table to apply colors to the sub-widgets.

## .dispelIcon Sub-Widgets

.cd      - used to display the cooldown spiral for the remaining debuff duration (Cooldown)
.count   - used to display the stack count of the dispellable debuff (FontString)
.icon    - used to show the icon's texture (Texture)
.overlay - used to represent the icon's border. Will be colored according to the debuff type color (Texture)

## .dispelIcon Options

.tooltipAnchor - anchor for the widget's tooltip if it is mouse-enabled. Defaults to 'ANCHOR_BOTTOMRIGHT' (string)

## .dispelIcon Attributes

.id   - the aura index of the dispellable debuff displayed by the widget (number)
.unit - the unit on which the dispellable dubuff displayed by the widget has been found (string)

## .dispelTexture Options

.dispelAlpha   - alpha value for the widget when a dispellable debuff is found. Defaults to 1 (number)[0-1]
.noDispelAlpha - alpha value for the widget when no dispellable debuffs are found. Defaults to 0 (number)[0-1]

## Examples

    -- Position and size
    local Dispellable = {}
    local button = CreateFrame('Button', 'LayoutName_Dispel', self.Health)
    button:SetPoint('CENTER')
    button:SetSize(22, 22)
    button:SetToplevel(true)

    local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
    cd:SetAllPoints()

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()

    local overlay = button:CreateTexture(nil, 'OVERLAY')
    overlay:SetTexture('Interface\\Buttons\\UI-Debuff-Overlays')
    overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    overlay:SetAllPoints()

    local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal', 1)
    count:SetPoint('BOTTOMRIGHT', -1, 1)

    local texture = self.Health:CreateTexture(nil, 'OVERLAY')
    texture:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 0) -- hide in case the class can't dispel at all

    -- Register with oUF
    button.cd = cd
    button.icon = icon
    button.overlay = overlay
    button.count = count
    button:Hide() -- hide in case the class can't dispel at all

    Dispellable.dispelIcon = button
    Dispellable.dispelTexture = texture
    self.Dispellable = Dispellable
--]]

local _, ns = ...

local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Dispellable requires oUF.')

local LPS = LibStub('LibPlayerSpells-1.0')
assert(LPS, 'oUF_Dispellable requires LibPlayerSpells-1.0.')

local dispelTypeFlags = {
	Curse = LPS.constants.CURSE,
	Disease = LPS.constants.DISEASE,
	Magic = LPS.constants.MAGIC,
	Poison = LPS.constants.POISON,
}

local band = bit.band
local wipe = table.wipe
local IsPlayerSpell = IsPlayerSpell
local IsSpellKnown = IsSpellKnown
local UnitCanAssist = UnitCanAssist

local _, playerClass = UnitClass('player')
local _, playerRace = UnitRace('player')
local dispels = {}

for id, _, _, _, _, _, types in LPS:IterateSpells('HELPFUL PERSONAL', 'DISPEL ' .. playerClass) do
	dispels[id] = types
end

if playerRace == 'Dwarf' then
	dispels[20594] = select(6, LPS:GetSpellInfo(20594)) -- Stoneform
end

if playerRace == 'DarkIronDwarf' then
	dispels[265221] = select(6, LPS:GetSpellInfo(265221)) -- Fireblood
end

if not next(dispels) then
	return
end

local canDispel = {}

local function IsDispellable(aura, unit)
	local dispellable = canDispel[aura.dispelName]

	return dispellable == true or dispellable == unit
end

--[[ Override: Dispellable.dispelIcon:UpdateTooltip()
Called to update the widget's tooltip.

* self - the dispelIcon sub-widget
--]]
local function UpdateTooltip(dispelIcon)
	GameTooltip:SetUnitDebuffByAuraInstanceID(dispelIcon.unit, dispelIcon.id)
end

local function OnEnter(dispelIcon)
	if not dispelIcon:IsVisible() then
		return
	end

	GameTooltip:SetOwner(dispelIcon, dispelIcon.tooltipAnchor)
	dispelIcon:UpdateTooltip()
end

local function OnLeave()
	GameTooltip:Hide()
end

--[[ Override: Dispellable.dispelTexture:UpdateColor(debuffType, r, g, b, a)
Called to update the widget's color.

* self       - the dispelTexture sub-widget
* debuffType - the type of the dispellable debuff (string?)['Curse', 'Disease', 'Magic', 'Poison']
* r          - the red color component (number)[0-1]
* g          - the green color component (number)[0-1]
* b          - the blue color component (number)[0-1]
* a          - the alpha color component (number)[0-1]
--]]
local function UpdateColor(dispelTexture, _, r, g, b, a)
	dispelTexture:SetVertexColor(r, g, b, a)
end

local function UpdateDebuffs(self, updateInfo)
	local unit = self.unit
	local element = self.Dispellable
	local debuffs = element.debuffs

	if not UnitCanAssist('player', unit) then
		wipe(debuffs)

		return
	end

	if not updateInfo or updateInfo.isFullUpdate then
		wipe(debuffs)
		local slots = { UnitAuraSlots(unit, 'HARMFUL') }

		for i = 2, #slots do
			local debuff = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])

			if IsDispellable(debuff, unit) then
				debuffs[debuff.auraInstanceID] = debuff
			end
		end
	else
		for _, aura in next, updateInfo.addedAuras or {} do
			if aura.isHarmful and IsDispellable(aura, unit) then
				debuffs[aura.auraInstanceID] = aura
			end
		end

		for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs or {} do
			local aura = C_UnitAuras.GetAuraByAuraInstanceID(unit, auraInstanceID)

			if aura.isHarmful and IsDispellable(aura, unit) then
				debuffs[aura.auraInstanceID] = aura
			end
		end

		for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs or {} do
			debuffs[auraInstanceID] = nil
		end
	end
end

local function UpdateDisplay(self)
	local element = self.Dispellable
	local lowestID = nil

	for auraInstanceID in next, element.debuffs do
		if not lowestID or auraInstanceID < lowestID then
			lowestID = auraInstanceID
		end
	end

	local dispelTexture = element.dispelTexture
	local dispelIcon = element.dispelIcon

	if lowestID and lowestID ~= element.__current then
		element.__current = lowestID
		local debuff = element.debuffs[lowestID]
		local debuffType = debuff.dispelName
		local r, g, b = self.colors.debuff[debuffType]:GetRGB()

		if dispelTexture then
			dispelTexture:UpdateColor(debuffType, r, g, b, dispelTexture.dispelAlpha)
		end

		if dispelIcon then
			dispelIcon.unit = self.unit
			dispelIcon.id = lowestID
			if dispelIcon.icon then
				dispelIcon.icon:SetTexture(debuff.icon)
			end
			if dispelIcon.overlay then
				dispelIcon.overlay:SetVertexColor(r, g, b)
			end
			if dispelIcon.count then
				local count = debuff.applications
				dispelIcon.count:SetText(count and count > 1 and count or '')
			end
			if dispelIcon.cd then
				local duration = debuff.duration

				if duration > 0 then
					dispelIcon.cd:SetCooldown(debuff.expirationTime - duration, duration, debuff.timeMod)
					dispelIcon.cd:Show()
				else
					dispelIcon.cd:Hide()
				end
			end

			dispelIcon:Show()
		end

		return debuff
	elseif not lowestID and element.__current ~= nil then
		element.__current = nil

		if dispelTexture then
			dispelTexture:UpdateColor(nil, 1, 1, 1, dispelTexture.noDispelAlpha)
		end
		if dispelIcon then
			dispelIcon:Hide()
		end
	end
end

local function Update(self, _, unit, updateInfo)
	if self.unit ~= unit then
		return
	end

	local element = self.Dispellable

	--[[ Callback: Dispellable:PreUpdate()
	Called before the element has been updated.

	* self - the Dispellable element
	--]]
	if element.PreUpdate then
		element:PreUpdate()
	end

	UpdateDebuffs(self, updateInfo)
	local displayed = UpdateDisplay(self)

	--[[ Callback: Dispellable:PostUpdate(debuffType, texture, count, duration, expiration)
	Called after the element has been updated.

	* self      - the Dispellable element
	* displayed - the displayed debuff (UnitAuraInfo?)
	--]]
	if element.PostUpdate then
		element:PostUpdate(displayed)
	end
end

local function Path(self, event, unit)
	--[[ Override: Dispellable.Override(self, event, unit)
	Used to override the internal update function.

	* self  - the parent of the Dispellable element
	* event - the event triggering the update (string)
	* unit  - the unit accompaning the event (string)
	--]]
	return (self.Dispellable.Override or Update)(self, event, unit)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.Dispellable
	if not element then
		return
	end

	element.__owner = self
	element.debuffs = {}
	element.ForceUpdate = ForceUpdate

	local dispelTexture = element.dispelTexture
	if dispelTexture then
		dispelTexture.dispelAlpha = dispelTexture.dispelAlpha or 1
		dispelTexture.noDispelAlpha = dispelTexture.noDispelAlpha or 0
		dispelTexture.UpdateColor = dispelTexture.UpdateColor or UpdateColor
	end

	local dispelIcon = element.dispelIcon
	if dispelIcon then
		-- prevent /fstack errors
		if dispelIcon.cd then
			if not dispelIcon:GetName() then
				dispelIcon:SetName(dispelIcon:GetDebugName())
			end
			if not dispelIcon.cd:GetName() then
				dispelIcon.cd:SetName('$parentCooldown')
			end
		end

		if dispelIcon:IsMouseEnabled() then
			dispelIcon.tooltipAnchor = dispelIcon.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			dispelIcon.UpdateTooltip = dispelIcon.UpdateTooltip or UpdateTooltip

			if not dispelIcon:GetScript('OnEnter') then
				dispelIcon:SetScript('OnEnter', OnEnter)
			end
			if not dispelIcon:GetScript('OnLeave') then
				dispelIcon:SetScript('OnLeave', OnLeave)
			end
		end
	end

	if not self.colors.debuff then
		self.colors.debuff = {}
		for debuffType, color in next, oUF.colors.debuff do
			self.colors.debuff[debuffType] = color
		end
	end

	self:RegisterEvent('UNIT_AURA', Path)

	return true
end

local function Disable(self)
	local element = self.Dispellable
	if not element then
		return
	end

	if element.dispelIcon then
		element.dispelIcon:Hide()
	end
	if element.dispelTexture then
		element.dispelTexture:UpdateColor(nil, 1, 1, 1, element.dispelTexture.noDispelAlpha)
	end

	self:UnregisterEvent('UNIT_AURA', Path)
end

oUF:AddElement('Dispellable', Path, Enable, Disable)

local function ToggleElement(enable)
	for _, object in next, oUF.objects do
		local element = object.Dispellable
		if element then
			if enable then
				object:EnableElement('Dispellable')
				element:ForceUpdate()
			else
				object:DisableElement('Dispellable')
			end
		end
	end
end

-- shallow comparison of primitive key/value types
local function TablesMatch(a, b)
	for k, v in next, a do
		if b[k] ~= v then
			return false
		end
	end
	for k, v in next, b do
		if a[k] ~= v then
			return false
		end
	end

	return true
end

local function UpdateDispels()
	local available = {}
	for id, types in next, dispels do
		if IsSpellKnown(id, id == 89808) or IsPlayerSpell(id) then
			for debuffType, flags in next, dispelTypeFlags do
				if band(types, flags) > 0 and available[debuffType] ~= true then
					available[debuffType] = band(LPS:GetSpellInfo(id), LPS.constants.PERSONAL) > 0 and 'player' or true
				end
			end
		end
	end

	if next(available) then
		if not TablesMatch(available, canDispel) then
			wipe(canDispel)
			for debuffType in next, available do
				canDispel[debuffType] = available[debuffType]
			end
			ToggleElement(true)
		end
	elseif next(canDispel) then
		wipe(canDispel)
		ToggleElement()
	end
end

local frame = CreateFrame('Frame')
frame:SetScript('OnEvent', UpdateDispels)
frame:RegisterEvent('SPELLS_CHANGED')