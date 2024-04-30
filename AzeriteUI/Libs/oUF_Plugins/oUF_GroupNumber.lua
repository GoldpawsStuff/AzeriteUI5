--[[
# Element: Raid Subgroup Number

Shows a number indicating a unit's subgroup number in the raid.

## Widget

GroupNumber - Fontstring.

--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

local function Update(self, event, ...)
	local element = self.GroupNumber
	local unit = self.unit

	--[[ Callback: GroupNumber:PreUpdate(unit)
	Called before the element has been updated.

	* self - the GroupNumber element
	* event - the event which caused the update (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(event, ...)
	end

	local groupNumber
	if (UnitExists(unit) and UnitInRaid(unit)) then
		for i = 1,40 do
			if (UnitIsUnit("raid"..i, unit)) then
				local _, _, subgroup = GetRaidRosterInfo(i)
				if (subgroup) then
					groupNumber = subgroup
					break
				end
			end
		end
	end

	if (groupNumber) then
		element:SetText(groupNumber)
		element:Show()
	else
		element:Hide()
		element:SetText("")
	end

	--[[ Callback: GroupNumber:PostUpdate(event)
	Called after the element has been updated.

	* self - the GroupNumber element
	* event - the event that caused the update (string)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(event, ...)
	end
end


local function Path(self, ...)
	--[[ Override: GroupNumber.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.GroupNumber.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.GroupNumber
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element:Hide()

		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.GroupNumber
	if(element) then
		element:Hide()
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('GroupNumber', Path, Enable, Disable)
