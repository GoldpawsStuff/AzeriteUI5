--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

if (not ns.WoW11) then return end

local Options = ns:GetModule("Options", true)
if (not Options) then return end

Options:SetEnabledState(false)

Options.OnInitialize = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ExtraDelayedEnable")
end

Options.OnEnable = function(self)
	self:RegisterChatCommand("az", "OpenOptionsMenu")
	self:RegisterChatCommand("azerite", "OpenOptionsMenu")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
	ns.RegisterCallback(self, "OptionsNeedRefresh", "Refresh")
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")

	self:OnEvent("PLAYER_ENTERING_WORLD", true)
end

Options.ExtraDelayedEnable = function(self)
	C_Timer.After(.1, function() Options:OnEnable() end)
end
