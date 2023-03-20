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
local Experimental = ns:NewModule("Experimental", "LibMoreEvents-1.0", "AceConsole-3.0")

-- Addon API
local GetScale = ns.API.GetScale

Experimental.SetEnableAuraSorting = function(self)

	-- Store the setting.
	ns.db.global.disableAuraSorting = nil

	self:EnableAuraSorting()
end

Experimental.SetDisableAuraSorting = function(self)

	-- Store the setting.
	ns.db.global.disableAuraSorting = true

	self:DisableAuraSorting()
end

Experimental.DisableAuraSorting = function(self)

	-- Iterate through unitframes.
	for frame in next,ns.UnitFrames do
		local auras = frame.Auras
		if (auras) then
			auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
			auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
			auras:ForceUpdate()
		end
	end

	-- Iterate through nameplates.
	for frame in next,ns.NamePlates do
		local auras = frame.Auras
		if (auras) then
			auras.PreSetPosition = ns.AuraSorts.Alternate -- only in classic
			auras.SortAuras = ns.AuraSorts.AlternateFuncton -- only in retail
			auras:ForceUpdate()
		end
	end

	-- Don't need this even anymore.
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "DisableAuraSorting")
end

Experimental.EnableAuraSorting = function(self)

	-- Iterate through unitframes.
	for frame in next,ns.UnitFrames do
		local auras = frame.Auras
		if (auras) then
			auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
			auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
			auras:ForceUpdate()
		end
	end

	-- Iterate through nameplates.
	for frame in next,ns.NamePlates do
		local auras = frame.Auras
		if (auras) then
			auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
			auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail
			auras:ForceUpdate()
		end
	end

	-- Now we might need this event.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "DisableAuraSorting")
end

Experimental.ToggleBlips = function(self)
	local show = not self.Blips:IsShown()
	self.Blips:SetShown(show)
	self.BlibsBackdrop:SetShown(show)
end

Experimental.SpawnAuraSorting = function(self)

	self:RegisterChatCommand("disableaurasorting", "SetDisableAuraSorting")
	self:RegisterChatCommand("enableaurasorting", "SetEnableAuraSorting")

	-- Make sure this happens when the setting is saved
	local db = ns.db.global
	if (db.disableAuraSorting) then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "DisableAuraSorting")
	end
end

Experimental.SpawnBlips = function(self)

	-- Little trick to show the layout and dimensions
	-- of the Minimap blip icons on-screen in-game,
	-- whenever blizzard decide to update those.
	------------------------------------------------------------

	-- By setting a single point, but not any sizes,
	-- the texture is shown in its original size and dimensions!
	local f = UIParent:CreateTexture()
	f:SetIgnoreParentScale(true)
	f:SetScale(GetScale())
	f:Hide()
	f:SetTexture([[Interface\MiniMap\ObjectIconsAtlas.blp]])
	f:SetPoint("CENTER")

	-- Add a little backdrop for easy
	-- copy & paste from screenshots!
	local g = UIParent:CreateTexture()
	g:Hide()
	g:SetColorTexture(0,.7,0,.25)
	g:SetAllPoints(f)

	self.Blips = f
	self.BlibsBackdrop = g

	self:RegisterChatCommand("toggleblips", "ToggleBlips")
end

Experimental.OnInitialize = function(self)
	self:SpawnBlips()
	self:SpawnAuraSorting()
end
