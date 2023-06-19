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

-- Lua API
local next = next
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local tostring = tostring

-- GLOBALS: UIParent
-- GLOBALS: UnregisterStateDriver, RegisterStateDriver
-- GLOBALS: ClearOverrideBindings, GetBindingKey, SetOverrideBindingClick
-- GLOBALS: InCombatLockdown, PetDismiss, UnitExists, VehicleExit
-- GLOBALS: BOTTOMLEFT_ACTIONBAR_PAGE, BOTTOMRIGHT_ACTIONBAR_PAGE, RIGHT_ACTIONBAR_PAGE, LEFT_ACTIONBAR_PAGE
-- GLOBALS: MULTIBAR_5_ACTIONBAR_PAGE, MULTIBAR_6_ACTIONBAR_PAGE, MULTIBAR_7_ACTIONBAR_PAGE
-- GLOBALS: NUM_ACTIONBAR_BUTTONS, LEAVE_VEHICLE

local ButtonBar = ns.ButtonBar.prototype

local ActionBar = setmetatable({}, { __index = ButtonBar })
local ActionBar_MT = { __index = ActionBar }

local LFF = LibStub("LibFadingFrames-1.0")

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

-- Exit button for Wrath & Retail
local exitButton = {
	func = function(button)
		if (UnitExists("vehicle")) then
			VehicleExit()
		else
			PetDismiss()
		end
	end,
	tooltip = LEAVE_VEHICLE,
	texture = [[Interface\Icons\achievement_bg_kill_carrier_opposing_flagroom]]
}

local defaults = ns:Merge({
	enabled = false,
	enableBarFading = false, -- whether to enable non-combat/hover button fading
	fadeInCombat = false, -- whether to keep fading out even in combat
	fadeFrom = 1, -- which button to start the button fading from
	numbuttons = 12, -- total number of buttons on the bar
	layout = "grid", -- currently applied layout type
	startAt = 1, -- at which button the zigzag pattern should begin
	growth = "horizontal", -- which direction the bar goes in
	growthHorizontal = "RIGHT", -- the bar's horizontal growth direction
	growthVertical = "UP", -- the bar's vertical growth direction
	padding = 8, -- horizontal padding between the buttons
	breakpadding = 8, -- vertical padding between the buttons
	breakpoint = 12, -- when to start a new grid row
	offset = 44/64, -- 44 -- relative offset in the growth direction for the alternate zigzag row as a fraction of button size.
	hitrects = { -10, -10, -10, -10 },
	visibility = {
		dragon = false,
		possess = false,
		overridebar = false,
		vehicleui = false
	},
	savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = 0,
		[3] = 0
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
		self:CallMethod("UpdateDragonRiding", newstate == "dragon" and true or false);
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

	for i = 1,NUM_ACTIONBAR_BUTTONS do
		bar:CreateButton()
	end

	bar:UpdateButtons()
	bar:UpdateVisibilityDriver()

	return bar
end

ActionBar.CreateButton = function(self, buttonConfig)

	local button = ButtonBar.CreateButton(self, buttonConfig)

	for k = 1,18 do
		button:SetState(k, "action", (k - 1) * NUM_ACTIONBAR_BUTTONS + button.id)
	end

	button:SetState(0, "action", (self.id - 1) * NUM_ACTIONBAR_BUTTONS + button.id)
	button:Show()
	button:SetAttribute("statehidden", nil)
	button:UpdateAction()

	-- Add in a vehicle exit button at slot 7 for Wrath and Retail.
	if ((ns.IsWrath or ns.IsRetail) and (self.id == 1 and button.id == 7)) then
		button:SetState(16, "custom", exitButton)
		button:SetState(17, "custom", exitButton)
		button:SetState(18, "custom", exitButton)
	end

	local keyBoundTarget = string_format(BINDTEMPLATE_BY_ID[self.id], button.id)
	button.keyBoundTarget = keyBoundTarget

	local buttonConfig = buttonConfig or button.config or {}
	buttonConfig.keyBoundTarget = keyBoundTarget
	buttonConfig.clickOnDown = self.config.clickOnDown

	button:UpdateConfig(buttonConfig)
end

ActionBar.Enable = function(self)
	ButtonBar.Enable(self)
	self:Update()
end

ActionBar.Disable = function(self)
	ButtonBar.Disable(self)
	self:Update()
end

ActionBar.Update = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateButtonConfig()
	self:UpdateButtons()
	self:UpdateButtonLayout()
	self:UpdateStateDriver()
	self:UpdateVisibilityDriver()
	self:UpdateBindings()
	self:UpdateFading()
end

ActionBar.UpdateFading = function(self)
	if (not self:IsEnabled()) then return end

	local config, buttons = self.config, self.buttons

	if (config.enabled and config.enableBarFading) then

		-- Remove any previous fade registrations.
		for id = 1, #buttons do
			LFF:UnregisterFrameForFading(buttons[id])
		end

		-- Register fading for selected buttons.
		for id = config.fadeFrom or 1, #buttons do
			LFF:RegisterFrameForFading(buttons[id], "actionbuttons", unpack(config.hitrects))
		end

	else

		-- Unregister all fading.
		for id, button in next,buttons do
			LFF:UnregisterFrameForFading(buttons[id])
		end
	end

	-- Our fade frame unregistration sets alpha back to full opacity,
	-- this conflicts with how actionbuttons work so we're faking events to fix it.
	local LAB = LibStub("LibActionButton-1.0-GE")
	local OnEvent = LAB.eventFrame:GetScript("OnEvent")
	if (OnEvent) then
		OnEvent(LAB, "ACTIONBAR_SHOWGRID")
		OnEvent(LAB, "ACTIONBAR_HIDEGRID")
	end
end

ActionBar.UpdatePosition = function(self)
	if (InCombatLockdown()) then return end

	local config = self.config.savedPosition

	self:SetScale(config.scale)
	self:ClearAllPoints()
	self:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
end

ActionBar.UpdateAnchor = function(self)
	if (self.anchor) then

		local config = self.config.savedPosition

		self.anchor:SetSize(self:GetSize())
		self.anchor:SetScale(config.scale)
		self.anchor:ClearAllPoints()
		self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
	end
end

ActionBar.UpdateButtons = function(self)
	ButtonBar.UpdateButtons(self)
end

ActionBar.UpdateButtonLayout = function(self)
	ButtonBar.UpdateButtonLayout(self)
end

ActionBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then return end
	if (not next(self.buttons)) then return end

	ClearOverrideBindings(self)

	if (not self:IsEnabled()) then return end

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
	if (config.enabled) then

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

ActionBar.UpdateDragonRiding = function(self, isDragonRiding)
	self.isDragonRiding = isDragonRiding
end
