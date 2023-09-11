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
local _, ns = ...
if (not ns.API.IsAddOnEnabled("ConsolePort")) then return end

if (ns.API.IsAddOnEnabled("ConsolePort_Bar")) then return end

local ConsolePort = ns:NewModule("ConsolePort", "LibMoreEvents-1.0", "AceHook-3.0")

ConsolePort.UpdateHotkeys = function(self)
	local HotkeyHandler = ConsolePortHotkeyHandler
	if (not HotkeyHandler) then return end

	local ActionBars = ns:GetModule("ActionBars")
	if (not ActionBars or not ActionBars:IsEnabled()) then return end

	for widget in HotkeyHandler.Widgets:EnumerateActive() do
		local owner = widget:GetParent()
		if (ActionBars.buttons[owner]) then
			widget:SetFrameLevel(owner:GetFrameLevel() + 10)
			widget:SetScale(1.25)
		end
	end

end

ConsolePort.HandleHotkeys = function(self)
	local HotkeyHandler = ConsolePortHotkeyHandler
	if (not HotkeyHandler) then return end

	self:SecureHook(HotkeyHandler, "UpdateHotkeys")
end

ConsolePort.HandleConsolePort = function(self, event, addon)
	if (not IsAddOnLoaded("ConsolePort")) then
		return self:RegisterEvent("ADDON_LOADED", "HandleConsolePort")
	elseif (event == "ADDON_LOADED") then
		if (addon ~= "ConsolePort") then return end
		self:UnregisterEvent("ADDON_LOADED", "HandleConsolePort")
	end

	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "HandleConsolePort")
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "HandleConsolePort")
	end

	self:HandleHotkeys()

	ns.ConsolePortHandled = true

	ns:Fire("ConsolePort_Handled")
end

ConsolePort.OnInitialize = function(self)
	self:HandleConsolePort()
end
