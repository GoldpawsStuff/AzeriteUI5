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

local ButtonBar = ns.ButtonBar.prototype

local ActionBar = setmetatable({}, { __index = ButtonBar })
local ActionBar_MT = { __index = ActionBar }

local select, string_format = select, string.format

local playerClass = ns.PlayerClass

-- Return bindaction by blizzard barID.
local BINDTEMPLATE_BY_ID = {
	[1] = "ACTIONBUTTON%d",
	[BOTTOMLEFT_ACTIONBAR_PAGE] = "MULTIACTIONBAR1BUTTON%d",
	[BOTTOMRIGHT_ACTIONBAR_PAGE] = "MULTIACTIONBAR2BUTTON%d",
	[RIGHT_ACTIONBAR_PAGE] = "MULTIACTIONBAR3BUTTON%d",
	[LEFT_ACTIONBAR_PAGE] = "MULTIACTIONBAR4BUTTON%d"
}
if (ns.IsRetail) then
	BINDTEMPLATE_BY_ID[MULTIBAR_5_ACTIONBAR_PAGE] = "MULTIACTIONBAR5BUTTON%d"
	BINDTEMPLATE_BY_ID[MULTIBAR_6_ACTIONBAR_PAGE] = "MULTIACTIONBAR6BUTTON%d"
	BINDTEMPLATE_BY_ID[MULTIBAR_7_ACTIONBAR_PAGE] = "MULTIACTIONBAR7BUTTON%d"
end

local defaults = ns:Merge({
	visibility = {
		dragon = false,
		possess = false,
		overridebar = false,
		vehicleui = false
	}
}, ns.ButtonBar.defaults)

ns.ActionBar = {}
ns.ActionBar.prototype = ActionBar
ns.ActionBar.defaults = defaults

ns.ActionBar.Create = function(self, id, config, name)
	local bar = setmetatable(ns.ButtonBar:Create(id, config, name), ActionBar_MT)

	bar:SetAttribute("UpdateVisibility", [[
		local visibility = self:GetAttribute("visibility");
		local userhidden = self:GetAttribute("userhidden");
		if (visibility == "show") then
			if (userhidden) then
				self:Hide();
			else
				self:Show();
			end
		elseif (visibility == "hide") then
			self:Hide();
		end
	]])

	bar:SetAttribute("_onstate-vis", [[
		if (not newstate) then
			return
		end
		self:SetAttribute("visibility", newstate);
		self:RunAttribute("UpdateVisibility");
	]])

	bar:SetAttribute("_onstate-page", [[
		-- Store the dragonriding state as a member value in lua
		-- before actual page changes and button updates.
		self:CallMethod("UpdateDragonRiding", newstate == "dragon" and true or false)
		if (newstate == "possess" or newstate == "dragon" or newstate == "11") then
			if HasVehicleActionBar() then
				newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar() then
				newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then
				newstate = GetBonusBarIndex()
			else
				newstate = nil
			end
			if not newstate then
				newstate = 12
			end
		end
		self:SetAttribute("state", newstate);
		control:ChildUpdate("state", newstate);
	]])

	bar:UpdateButtons()
	bar:UpdateVisibilityDriver()

	return bar
end

ActionBar.CreateButton = function(self, config)

	local button = ButtonBar.CreateButton(self, config)

	for k = 1,18 do
		button:SetState(k, "action", (k - 1) * 12 + button.id)
	end

	button:SetState(0, "action", (self.id - 1) * 12 + button.id)
	button:Show()
	button:SetAttribute("statehidden", nil)
	button:UpdateAction()

	local keyBoundTarget = string_format(BINDTEMPLATE_BY_ID[self.id], button.id)
	button.keyBoundTarget = keyBoundTarget

	local buttonConfig = button.config or {}
	buttonConfig.keyBoundTarget = keyBoundTarget

	button:UpdateConfig(buttonConfig)
end

ActionBar.Enable = function(self)
	if (InCombatLockdown()) then return end

	self.config.enabled = true

	self:UpdateStateDriver()
	self:UpdateVisibilityDriver()
	self:UpdateBindings()
end

ActionBar.Disable = function(self)
	if (InCombatLockdown()) then return end

	self.config.enabled = false

	self:UpdateVisibilityDriver()
end

ActionBar.SetEnabled = function(self, enable)
	if (InCombatLockdown()) then return end

	self.config.enabled = not not enable

	if (self.config.enabled) then
		self:Enable()
	else
		self:Disable()
	end
end

ActionBar.IsEnabled = function(self)
	return self.config.enabled
end

ActionBar.UpdateDragonRiding = function(self, isDragonRiding)
	self.isDragonRiding = isDragonRiding
end

ActionBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then return end
	if (not next(self.buttons)) then return end

	ClearOverrideBindings(self)

	for id,button in pairs(self.buttons) do
		local bindingAction = button.keyBoundTarget
		if (bindingAction) then

			-- iterate through the registered keys for the action
			local buttonName = button:GetName()
			for keyNumber = 1,select("#", GetBindingKey(bindingAction)) do

				-- get a key for the action
				local key = select(keyNumber, GetBindingKey(bindingAction))
				if (key and (key ~= "")) then

					-- this is why we need named buttons
					SetOverrideBindingClick(self, false, key, buttonName) -- assign the key to our own button
				end
			end
		end
	end
end

ActionBar.UpdateStateDriver = function(self)
	if (InCombatLockdown()) then return end

	local statedriver
	if (self.id == 1) then
		statedriver = "[overridebar] possess; [possessbar] possess; [shapeshift] possess; [bonusbar:5] dragon; [form,noform] 0; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6"

		if (playerClass == "DRUID") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"

		elseif (playerClass == "MONK") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"

		elseif (playerClass == "ROGUE") then
			if (ns.IsWrath) then
				statedriver = statedriver .. "; [bonusbar:1] 7 [bonusbar:2] 8" -- Shadowdance
			else
				statedriver = statedriver .. "; [bonusbar:1] 7"
			end

		elseif (ns.IsWrath and playerClass == "PRIEST") then
			statedriver = statedriver .. "; [bonusbar:1] 7" -- Shadowform

		elseif (playerClass == "WARRIOR") then
			if (ns.IsWrath) then
				statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"
			elseif (ns.IsClassic) then
				statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8"
			end
		end

		statedriver = statedriver .. "; 1"
	else
		statedriver = tostring(self.id)
	end

	UnregisterStateDriver(self, "page")
	self:SetAttribute("state-page", "0")
	RegisterStateDriver(self, "page", statedriver or "0")
end

ActionBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then return end

	local config = self.config

	local visdriver
	if (self.config.enabled) then

		visdriver = "[petbattle]hide;"

		if (config.visibility.possess) then
			visdriver = visdriver.."[possessbar]show;"
		else
			visdriver = visdriver.."[possessbar]hide;"
		end

		if (config.visibility.overridebar) then
			visdriver = visdriver.."[overridebar]show;"
		else
			visdriver = visdriver.."[overridebar]hide;"
		end

		if (config.visibility.vehicleui) then
			visdriver = visdriver.."[vehicleui]show;"
		else
			visdriver = visdriver.."[vehicleui]hide;"
		end

		if (config.visibility.dragon) then
			visdriver = visdriver.."[bonusbar:5]show;"
		else
			visdriver = visdriver.."[bonusbar:5]hide;"
		end

		visdriver = visdriver.."show"
	end

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end
