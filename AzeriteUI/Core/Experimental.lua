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
local Experimental = ns:NewModule("Experimental", "LibMoreEvents-1.0", "AceConsole-3.0", "AceSerializer-3.0")

-- GLOBALS: EnableAddOn, DisableAddOn, ReloadUI, UIParent

-- Lua API
local next = next
local string_lower = string.lower

Experimental.ToggleUI = function(self, input)
	if (not ns.IsDevelopment) then return end
	if (not self._ui_list) then
		self._ui_list = {}
		for ui,cmds in next,{
			["AzeriteUI"] = { "azerite", "az" },
			["DiabolicUI"] = { "diabolic", "diablo", "dio" }
		} do
			if (ui ~= Addon) and (ns.API.IsAddOnAvailable(ui)) then
				for _,cmd in next,cmds do
					self._ui_list[cmd] = ui
				end
			end
		end
	end
	local arg = self:GetArgs(string_lower(input))
	local target = arg and self._ui_list[arg]
	if (target) then
		EnableAddOn(target) -- Enable the desired UI
		for cmd,ui in next,self._ui_list do
			if (ui and ui ~= target) then -- Don't disable target UI
				DisableAddOn(ui) -- Disable all other UIs
			end
		end
		DisableAddOn(Addon) -- Disable the current UI
		ReloadUI() -- Reload interface to the selected UI
	end
end

Experimental.ToggleBlips = function(self)
	if (not ns.IsDevelopment) then return end

	if (not self.Blips) then

		-- Little trick to show the layout and dimensions
		-- of the Minimap blip icons on-screen in-game,
		-- whenever blizzard decide to update those.
		------------------------------------------------------------

		-- By setting a single point, but not any sizes,
		-- the texture is shown in its original size and dimensions!
		local f = UIParent:CreateTexture()
		f:SetIgnoreParentScale(true)
		f:SetScale(ns.API.GetScale())
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
	end

	local show = not self.Blips:IsShown()

	self.Blips:SetShown(show)
	self.BlibsBackdrop:SetShown(show)
end

Experimental.SerializeOptions = function(self)
	if (not self.SerializedOutputWindow) then
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()
		frame:SetSize(1200,900)
		frame:SetPoint("CENTER")

		local backdrop = frame:CreateTexture(nil, "BACKGROUND")
		backdrop:SetAllPoints()
		backdrop:SetColorTexture(.15, .15, .15, .75)

		local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -27, 15)

		local messageFrame = CreateFrame("EditBox", nil, scrollFrame)
		frame.messageFrame = messageFrame

		messageFrame:SetScript("OnEscapePressed", function() frame:Hide() end)
		messageFrame:SetMultiLine(true)
		messageFrame:SetAutoFocus(false)
		messageFrame:SetFontObject(ChatFontNormal)
		messageFrame:SetSize(440, 260)
		messageFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -5)
		messageFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT")
		messageFrame:Show()

		self.SerializedOutputWindow = frame
	end

	local LibDeflate = LibStub("LibDeflate")

	local serialized = self:Serialize(ns:GetModule("ActionBars").db.profile)
	local compressed = LibDeflate:CompressDeflate(serialized)
	local encoded = LibDeflate:EncodeForPrint(compressed)

	--local compressed = LibDeflate:DecodeForPrint(encoded)
	--local serialized = LibDeflate:DecompressDeflate(compressed)
	--local success, table = self:Deserialize(serialized)

	self.SerializedOutputWindow.messageFrame:SetText(encoded)
	self.SerializedOutputWindow:SetShown(not self.SerializedOutputWindow:IsShown())
end

Experimental.OnInitialize = function(self)
	if (ns.IsDevelopment and ns.db.global.enableDevelopmentMode) then
		self:RegisterChatCommand("serial", "SerializeOptions")
		self:RegisterChatCommand("toggleblips", "ToggleBlips")
		self:RegisterChatCommand("go", "ToggleUI")
	end
end
