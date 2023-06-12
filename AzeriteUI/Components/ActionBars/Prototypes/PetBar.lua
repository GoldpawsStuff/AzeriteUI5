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

local LFF = LibStub("LibFadingFrames-1.0")

-- Lua API
local next = next
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local tostring = tostring

-- GLOBALS: ClearOverrideBindings, GetBindingKey, InCombatLockdown, SetOverrideBindingClick
-- GLOBALS: NUM_PET_ACTION_SLOTS

local ButtonBar = ns.ButtonBar.prototype

local PetBar = setmetatable({}, { __index = ButtonBar })
local PetBar_MT = { __index = PetBar }


local playerClass = ns.PlayerClass


local defaults = ns:Merge({
	enabled = false,
	enableBarFading = true, -- whether to enable non-combat/hover button fading
	fadeInCombat = false, -- whether to keep fading out even in combat
	fadeFrom = 1, -- which button to start the button fading from
	numbuttons = NUM_PET_ACTION_SLOTS, -- total number of buttons on the bar
	layout = "grid", -- currently applied layout type
	startAt = 1, -- at which button the zigzag pattern should begin
	growth = "horizontal", -- which direction the bar goes in
	growthHorizontal = "RIGHT", -- the bar's horizontal growth direction
	growthVertical = "DOWN", -- the bar's vertical growth direction
	padding = 8, -- horizontal padding between the buttons
	breakpadding = 8, -- vertical padding between the buttons
	breakpoint = NUM_PET_ACTION_SLOTS, -- when to start a new grid row
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

ns.PetBar = {}
ns.PetBar.prototype = PetBar
ns.PetBar.defaults = defaults

ns.PetBar.Create = function(self, config, name)

	local bar = setmetatable(ns.ButtonBar:Create(nil, config, name), PetBar_MT)

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

	for i = 1,NUM_PET_ACTION_SLOTS do
		bar:CreateButton()
	end
	bar:UpdateButtons()
	bar:UpdateVisibilityDriver()

	bar:RegisterEvent("PLAYER_CONTROL_LOST")
	bar:RegisterEvent("PLAYER_CONTROL_GAINED")
	bar:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	bar:RegisterEvent("UNIT_PET")
	bar:RegisterEvent("UNIT_FLAGS")
	bar:RegisterEvent("PET_BAR_UPDATE")
	bar:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	bar:RegisterEvent("PET_BAR_UPDATE_USABLE")
	bar:RegisterEvent("PET_UI_UPDATE")
	bar:RegisterEvent("PLAYER_TARGET_CHANGED")
	if (ns.IsRetail or ns.IsWrath) then
		bar:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	end
	bar:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	bar:RegisterUnitEvent("UNIT_AURA", "pet")
	bar:RegisterEvent("PET_BAR_SHOWGRID")
	bar:RegisterEvent("PET_BAR_HIDEGRID")

	return bar
end

PetBar.UpdateBindings = function(self)
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

PetBar.Enable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = true
	self:UpdateVisibilityDriver()
end

PetBar.Disable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = false
	self:UpdateVisibilityDriver()
end

PetBar.IsEnabled = function(self)
	return self.enabled
end

PetBar.CreateButton = function(self, buttonConfig)

	local id = #self.buttons + 1

	local button = ns.PetButton:Create(id, self:GetName().."Button"..id, self, buttonConfig)


	self:SetFrameRef("Button"..id, button)
	self.buttons[id] = button

	local keyBoundTarget = "BONUSACTIONBUTTON"..id
	button.keyBoundTarget = keyBoundTarget

	local buttonConfig = buttonConfig or button.config or {}
	buttonConfig.keyBoundTarget = keyBoundTarget

	button:UpdateConfig(buttonConfig)

	return button
end

PetBar.ForAll = function(self, method, ...)
	if (not self.buttons) then
		return
	end
	for _,button in self:GetAll() do
		local func = button[method]
		if (func) then
			func(button, ...)
		end
	end
end

PetBar.GetAll = function(self)
	return pairs(self.buttons)
end

PetBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then
		return
	end
	if (not self.buttons) then
		return
	end
	ClearOverrideBindings(self)
	for id,button in ipairs(self.buttons) do
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

PetBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then
		return
	end

	local visdriver
	if (self.enabled) then
		visdriver = self.customVisibilityDriver or "[petbattle][vehicleui]hide;[@pet,exists,nopossessbar]show;hide"
	end
	self:SetAttribute("visibility-driver", visdriver)

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end
