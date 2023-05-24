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

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local Tutorials = ns:NewModule("Tutorials", "LibMoreEvents-1.0", "AceConsole-3.0", "AceTimer-3.0")
local EMP = ns:GetModule("EditMode", true)
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local math_max = math.max
local next = next
local string_format = string.format
local string_gsub = string.gsub
local table_insert = table.insert

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local UIHider = ns.Hider

local defaults = {
	char = {
		tutorials = {}
	}
}

local tutorials = {}

if (ns.WoW10) then
	table_insert(tutorials, {
		name = "editmode",
		version = 1
	})
end

-- Temporarily disable this.
-- *don't need it with new scaling system.
--if (not ns.WoW10) then
--	table_insert(tutorials, {
--		name = "scale",
--		version = 1
--	})
--end

-- Create frame backdrop
local createBackdropFrame = function(frame)
	local backdrop = CreateFrame("Frame", nil, frame, ns.BackdropTemplate)
	backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", -10, 10)
	backdrop:SetPoint("BOTTOMRIGHT", 10, -10)
	backdrop:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	})
	backdrop:SetBackdropColor(.05, .05, .05, .95)

	return backdrop
end

Tutorials.ShowEditModeTutorial = function(self)

	if (not self.tutorials.editmode) then

		local db = self.db.char.tutorials.editmode
		if (not db) then
			db = {}
			self.db.char.tutorials.editmode = db
		end

		local width, height = math_max(400, 140*3 + 10*2 + 20*2),200

		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()
		frame:EnableMouse(true)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetToplevel(true)
		frame:SetFrameLevel(1000)
		frame:SetSize(width, height)
		frame:SetPoint("CENTER", 0, 0)
		frame.step = 1

		local backdrop = createBackdropFrame(frame)
		frame.Backdrop = backdrop

		local addonName = GetAddOnMetadata(Addon, "Title")
		addonName = string_gsub(addonName, "|T.*|t", "")
		addonName = string_gsub(addonName, "^%s+", "")
		addonName = string_gsub(addonName, "%s+$", "")

		local heading = frame:CreateFontString(nil, "OVERLAY")
		heading:SetPoint("TOP", 0, -20)
		heading:SetPoint("LEFT", frame, "LEFT", 20, 0)
		heading:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
		heading:SetFontObject(GetFont(26, true))
		heading:SetJustifyH("CENTER")
		heading:SetText("Welcome to "..addonName)
		heading:SetTextColor(unpack(Colors.offwhite))
		frame.Heading = heading

		width = math_max(heading:GetStringWidth() + 40, width)

		local currExpID = GetExpansionLevel()
		local expName = _G["EXPANSION_NAME"..currExpID]

		local subHeading = frame:CreateFontString(nil, "OVERLAY")
		subHeading:SetPoint("TOP", heading, "BOTTOM", 0, 0)
		subHeading:SetPoint("LEFT", frame, "LEFT", 20, 0)
		subHeading:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
		subHeading:SetFontObject(GetFont(13, true))
		subHeading:SetJustifyH("CENTER")
		subHeading:SetText(string_format(BNET_FRIEND_ZONE_WOW_REGULAR, expName))
		subHeading:SetTextColor(unpack(Colors.gray))
		frame.SubHeading = subHeading

		width = math_max(subHeading:GetStringWidth() + 40, width)

		local message = frame:CreateFontString(nil, "OVERLAY")
		message:SetPoint("TOP", subHeading, "BOTTOM", 0, -10)
		message:SetPoint("LEFT", frame, "LEFT", 20, 0)
		message:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
		message:SetFontObject(GetFont(13, true))
		message:SetTextColor(unpack(Colors.offwhite))
		message:SetText("")
		frame.Message = message

		local hide = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		hide:SetSize(140, 30)
		hide:SetNormalFontObject(GetFont(13,true))
		hide:SetHighlightFontObject(GetFont(13,true))
		hide:SetDisabledFontObject(GetFont(13,true))
		hide:SetText(L["Hide"])
		hide:SetPoint("BOTTOM", 0, 20)
		hide:SetScript("OnClick", function(widget)

			-- close tutorial
			widget:GetParent():Hide()

			-- save progress

			-- store as not completed
			self.db.char.tutorials.editmode.completed = false

		end)

		frame.HideButton = hide

		local accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		accept:SetSize(140, 30)
		accept:SetNormalFontObject(GetFont(13,true))
		accept:SetHighlightFontObject(GetFont(13,true))
		accept:SetDisabledFontObject(GetFont(13,true))
		accept:SetText(L["Apply"])
		accept:ClearAllPoints()
		accept:SetPoint("RIGHT", hide, "LEFT", -10, 0)
		accept:SetScript("OnClick", function(widget)

			-- Apply default layout preset
			local layoutName = "Azerite"
			if (layoutName and not MFM.layouts[layoutName]) then
				MFM:RegisterPreset(layoutName)
				MFM:ApplyPreset(layoutName)
			end

			-- create or reset editmode preset
			if (EMP:DoesDefaultLayoutExist()) then
				EMP:SetToDefaultLayout() -- switch to default layout
				EMP:ApplySystems() -- reset editmode layout
			else
				EMP:ResetLayouts() -- create editmode layout
			end

			-- Update MFM module buttons.
			MFM:GetMFMFrame().ResetEditModeLayoutButton:SetDisabled(self.incombat or not EMP:CanEditActiveLayout())
			MFM:GetMFMFrame().CreateEditModeLayoutButton:SetDisabled(self.incombat or EMP:DoesDefaultLayoutExist())

			-- close tutorial
			widget:GetParent():Hide()

			-- mark as completed
			self.db.char.tutorials.editmode.completed = true

		end)

		frame.AcceptButton = accept

		local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		cancel:SetSize(140, 30)
		cancel:SetNormalFontObject(GetFont(13,true))
		cancel:SetHighlightFontObject(GetFont(13,true))
		cancel:SetDisabledFontObject(GetFont(13,true))
		cancel:SetText(L["Cancel"])
		cancel:SetPoint("LEFT", hide, "RIGHT", 10, 0)
		cancel:SetScript("OnClick", function(widget)

			-- close tutorial
			widget:GetParent():Hide()

			-- save progress

			-- store as completed(?)
			self.db.char.tutorials.editmode.completed = true

		end)

		frame.CancelButton = cancel

		-- figure out current height
		-- apply updated sizes
		frame:SetSize(width, height)

		frame:SetScript("OnShow", function(frame)

			local acceptLabel = EMP:DoesDefaultLayoutExist() and RESET or APPLY

			frame.AcceptButton:SetText(acceptLabel)
			frame.Message:SetText(string_format(L["Congratulations, you are now running AzeriteUI for Retail!|n|nTo create or reset an editmode layout named 'Azerite' and switch to it, click the '|cffffd200%s|r' button. To hide this window for now, click the '|cffffd200%s|r' button. To cancel this tutorial, click the '|cffffd200%s|r' button."], acceptLabel, HIDE, CANCEL))

			-- calculate frame size
			local top = frame.Heading:GetTop()
			local bottom = frame.Message:GetBottom()
			local width = math_max(400, 140*3 + 10*2 + 20*2)
			local height = math_max(200, (top - bottom) + 20 + (20 + 30 + 20))

			-- apply frame size
			frame:SetSize(width, height)

			-- Update MFM module buttons.
			MFM:GetMFMFrame().ResetEditModeLayoutButton:SetDisabled(self.incombat or not EMP:CanEditActiveLayout())
			MFM:GetMFMFrame().CreateEditModeLayoutButton:SetDisabled(self.incombat or EMP:DoesDefaultLayoutExist())

		end)

		self.tutorials.editmode = frame
	end
	self.tutorials.editmode:Show()
end

--Tutorials.ShowWrathSetupTutorial = function(self)
--	if (not self.tutorials.scale) then
--		local db = self.db.char.tutorials.scale
--		if (not db) then
--			db = {}
--			self.db.char.tutorials.scale = db
--		end
--
--		local width, height = math_max(400, 140*3 + 10*2 + 20*2),200
--
--		local frame = CreateFrame("Frame", nil, UIParent)
--		frame:Hide()
--		frame:EnableMouse(true)
--		frame:SetFrameStrata("FULLSCREEN_DIALOG")
--		frame:SetToplevel(true)
--		frame:SetFrameLevel(1000)
--		frame:SetSize(width, height)
--		frame:SetPoint("CENTER", 0, 0)
--		frame.step = 1
--
--		local backdrop = createBackdropFrame(frame)
--		frame.Backdrop = backdrop
--
--		local addonName = GetAddOnMetadata(Addon, "Title")
--		addonName = string_gsub(addonName, "|T.*|t", "")
--		addonName = string_gsub(addonName, "^%s+", "")
--		addonName = string_gsub(addonName, "%s+$", "")
--
--		local heading = frame:CreateFontString(nil, "OVERLAY")
--		heading:SetPoint("TOP", 0, -20)
--		heading:SetPoint("LEFT", frame, "LEFT", 20, 0)
--		heading:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
--		heading:SetFontObject(GetFont(26, true))
--		heading:SetJustifyH("CENTER")
--		heading:SetText(string_format(L["Welcome to %s"], addonName))
--		heading:SetTextColor(unpack(Colors.offwhite))
--		frame.Heading = heading
--
--		width = math_max(heading:GetStringWidth() + 40, width)
--
--		local currExpID = GetExpansionLevel()
--		local expName = _G["EXPANSION_NAME"..currExpID]
--
--		local subHeading = frame:CreateFontString(nil, "OVERLAY")
--		subHeading:SetPoint("TOP", heading, "BOTTOM", 0, 0)
--		subHeading:SetPoint("LEFT", frame, "LEFT", 20, 0)
--		subHeading:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
--		subHeading:SetFontObject(GetFont(13, true))
--		subHeading:SetJustifyH("CENTER")
--		subHeading:SetText(string_format(BNET_FRIEND_ZONE_WOW_CLASSIC, expName))
--		subHeading:SetTextColor(unpack(Colors.gray))
--		frame.SubHeading = subHeading
--
--		width = math_max(subHeading:GetStringWidth() + 40, width)
--
--		local message = frame:CreateFontString(nil, "OVERLAY")
--		message:SetPoint("TOP", subHeading, "BOTTOM", 0, -10)
--		message:SetPoint("LEFT", frame, "LEFT", 20, 0)
--		message:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
--		message:SetFontObject(GetFont(13, true))
--		message:SetTextColor(unpack(Colors.offwhite))
--		message:SetText("")
--		frame.Message = message
--
--		local hide = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
--		hide:SetSize(140, 30)
--		hide:SetNormalFontObject(GetFont(13,true))
--		hide:SetHighlightFontObject(GetFont(13,true))
--		hide:SetDisabledFontObject(GetFont(13,true))
--		hide:SetText(L["Hide"])
--		hide:SetPoint("BOTTOM", 0, 20)
--		hide:SetScript("OnClick", function(widget)
--
--			-- close tutorial
--			widget:GetParent():Hide()
--
--			-- save progress
--
--			-- store as not completed
--			self.db.char.tutorials.scale.completed = false
--
--		end)
--
--		frame.HideButton = hide
--
--		local accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
--		accept:SetSize(140, 30)
--		accept:SetNormalFontObject(GetFont(13,true))
--		accept:SetHighlightFontObject(GetFont(13,true))
--		accept:SetDisabledFontObject(GetFont(13,true))
--		accept:SetText(L["Apply"])
--		accept:ClearAllPoints()
--		accept:SetPoint("RIGHT", hide, "LEFT", -10, 0)
--		accept:SetScript("OnClick", function(widget)
--			if (InCombatLockdown()) then return end
--
--			-- close tutorial
--			widget:GetParent():Hide()
--
--			-- change the game's interface scale
--			SetCVar("uiScale", ns.API.GetDefaultBlizzardScale())
--
--			-- setup chat frames
--			ChatFrame1:SetUserPlaced(true)
--			ChatFrame1:ClearAllPoints()
--			ChatFrame1:SetSize(499, 176)
--			ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 85, 350)
--
--			-- save it
--			FCF_SavePositionAndDimensions(ChatFrame1)
--
--			-- mark as completed
--			self.db.char.tutorials.scale.completed = true
--
--			-- need a reset as the above can taint
--			ReloadUI()
--		end)
--
--		frame.AcceptButton = accept
--
--		local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
--		cancel:SetSize(140, 30)
--		cancel:SetNormalFontObject(GetFont(13,true))
--		cancel:SetHighlightFontObject(GetFont(13,true))
--		cancel:SetDisabledFontObject(GetFont(13,true))
--		cancel:SetText(L["Cancel"])
--		cancel:SetPoint("LEFT", hide, "RIGHT", 10, 0)
--		cancel:SetScript("OnClick", function(widget)
--
--			-- close tutorial
--			widget:GetParent():Hide()
--
--			-- save progress
--
--			-- store as completed(?)
--			self.db.char.tutorials.scale.completed = true
--
--		end)
--
--		frame.CancelButton = cancel
--
--		-- figure out current height
--		-- apply updated sizes
--		frame:SetSize(width, height)
--
--		frame:SetScript("OnShow", function(frame)
--
--			frame.Message:SetText(string_format(L["You are now running AzeriteUI for %s!|n|nTo set the game's general interface scale to AzeriteUI defaults and position the chat frames to match, click the '|cffffd200%s|r' button. To hide this window for now, click the '|cffffd200%s|r' button. To cancel this tutorial and handle interface scaling yourself, click the '|cffffd200%s|r' button."], expName, APPLY, HIDE, CANCEL))
--
--			-- calculate frame size
--			local top = frame.Heading:GetTop()
--			local bottom = frame.Message:GetBottom()
--			local width = math_max(400, 140*3 + 10*2 + 20*2)
--			local height = math_max(200, (top - bottom) + 20 + (20 + 30 + 20))
--
--			-- apply frame size
--			frame:SetSize(width, height)
--
--		end)
--
--		self.tutorials.scale = frame
--
--	end
--	self.tutorials.scale:Show()
--end

Tutorials.RunTutorial = function(self, tutorial)
	if (tutorial == "editmode") then
		self:ShowEditModeTutorial()
	elseif (tutorial == "scale") then
		--self:ShowWrathSetupTutorial()
	end
end

Tutorials.RunTutorials = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	local tutorialDB = self.db.char.tutorials

	for i,tutorial in next,tutorials do

		-- Create the saved setting if it does not exist.
		local db = tutorialDB[tutorial.name]
		if (not db) then
			db = {}
			tutorialDB[tutorial.name] = db
		end

		-- Check if a more recent tutorial is a available,
		-- or if the current version hasn't been completed yet.
		if ((not db.version) or (db.version < tutorial.version)) or (not db.completed) then

			-- Run tutorial callback
			if (not db.ignore and not db.completed) then
				self:RunTutorial(tutorial.name)
			end

			db.version = tutorial.version
		end

	end

end

Tutorials.ResetTutorials = function(self)
	local tutorialDB = self.db.char.tutorials
	for i,tutorial in next,tutorials do
		local db = tutorialDB[tutorial.name]
		if (db) then
			db.completed = nil
		end
	end
	self:RunTutorials()
end

Tutorials.CancelTutorials = function(self)
	if (self.timer) then
		self:CancelTimer(self.timer)
	end
end

Tutorials.ScheduleTutorials = function(self)
	self:CancelTutorials()
	self.timer = self:ScheduleTimer("RunTutorials", 5)
end

Tutorials.OnEvent = function(self, event, ...)

	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:ScheduleTutorials()
			self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:ScheduleTutorials()
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self:CancelTutorials()
		for tutorial,window in next,self.tutorials do
			if (window:IsShown()) then
				window:Hide()
			end
		end
	end
end

Tutorials.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Tutorials", defaults)

	self.tutorials = {}
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterChatCommand("resettutorials", "ResetTutorials")
	self:RegisterChatCommand("runtutorials", "RunTutorials")
end
