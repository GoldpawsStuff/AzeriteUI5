--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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

local MicroMenu = ns:NewModule("MicroMenu", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local ipairs = ipairs
local table_insert = table.insert

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia

MicroMenu.UpdateButtonLayout = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateButtonLayout")
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent(event, "UpdateButtonLayout")
	end

	local bar, custom, buttons = self.bar, self.bar.custom, self.bar.buttons
	local visible, first, last = 0

	for i,v in ipairs(buttons) do
		if (v and v:IsShown()) then
			custom[v]:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -26, 64 + (i-1)*30)

			visible = visible + 1
			first = first or custom[v]
			last = custom[v]
		end

	end

	local backdrop = bar.backdrop
	if (first and last) then
		backdrop:SetPoint("RIGHT", first, "RIGHT", 10, 0)
		backdrop:SetPoint("BOTTOM", first, "BOTTOM", 0, -18)
		backdrop:SetPoint("LEFT", first, "LEFT", -10, 0)
		backdrop:SetPoint("TOP", last, "TOP", 0, 18)
	end
end

MicroMenu.UpdateMicroButtonsParent = function(self, parent)
	if (parent == self.bar) then
		self.ownedByUI = false
		return
	end
	if parent and (parent == (PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame)) then
		self.ownedByUI = true
		self:BlizzardBarShow()
		return
	end
	self.ownedByUI = false
	self:MicroMenuBarShow()
end

MicroMenu.MicroMenuBarShow = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "MicroMenuBarShow")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent(event, "MicroMenuBarShow")
	end
	if (not self.ownedByUI) then

		local bar = self.bar

		UpdateMicroButtonsParent(bar)

		for i,v in ipairs(bar.buttons) do

			-- Show our layers
			local b = bar.custom[v]

			-- Hide blizzard layers
			--SetObjectScale(v)
			v:SetAlpha(0)
			v:SetSize(b:GetSize())
			v:SetHitRectInsets(0,0,0,0)

			-- Update button layout
			v:ClearAllPoints()
			v:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
		end

		self:UpdateButtonLayout()
	end
end

MicroMenu.BlizzardBarShow = function(self)

	local bar = self.bar

	-- Only reset button positions not set in MoveMicroButtons()
	for i,v in pairs(bar.buttons) do
		if (v ~= CharacterMicroButton) and (v ~= LFDMicroButton) then

			-- Restore blizzard button layout
			v:SetIgnoreParentScale(false)
			v:SetScale(1)
			v:SetSize(28,36)
			v:SetHitRectInsets(0,0,0,0)
			v:ClearAllPoints()
			v:SetPoint(unpack(bar.anchors[i]))

			-- Show Blizzard style
			v:SetAlpha(1)

			-- Hide our style
			--self.bar.custom[v]:SetAlpha(0)
		end
	end
end

MicroMenu.ActionBarController_UpdateAll = function(self)
	if (self.ownedByUI) and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN and not (C_PetBattles and C_PetBattles.IsInBattle()) then
		UpdateMicroButtonsParent(self.bar)
		self:MicroMenuBarShow()
	end
end

MicroMenu.InitializeMicroMenu = function(self)

	if (not self.bar) then

		local buttons, anchors, custom = {}, {}, {}

		local bar = CreateFrame("Frame", ns.Prefix.."MicroMenu", UIParent, "SecureHandlerStateTemplate")
		bar:SetFrameStrata("HIGH")
		bar:Hide()

		local backdrop = CreateFrame("Frame", nil, bar, ns.BackdropTemplate)
		backdrop:SetFrameLevel(bar:GetFrameLevel())
		backdrop:SetBackdrop({
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
			tile = true,
			insets = { left = 8, right = 8, top = 16, bottom = 16 }
		})
		backdrop:SetBackdropColor(.05, .05, .05, .95)
		bar:SetAllPoints(backdrop)

		for i,name in ipairs({
			"CharacterMicroButton",
			"SpellbookMicroButton",
			"TalentMicroButton",
			"AchievementMicroButton",
			"QuestLogMicroButton",
			"SocialsMicroButton",
			"PVPMicroButton",
			"LFGMicroButton",
			"WorldMapMicroButton",
			"GuildMicroButton",
			"LFDMicroButton",
			"CollectionsMicroButton",
			"EJMicroButton",
			"StoreMicroButton",
			"MainMenuMicroButton",
			"HelpMicroButton"
		}) do
			local button = _G[name]
			if (button) then
				table_insert(buttons, button)
			end
		end

		if (buttons[1]:GetParent() ~= MainMenuBarArtFrame) then
			self.ownedByUI = true
		end

		local labels = {
			CharacterMicroButton = CHARACTER_BUTTON,
			SpellbookMicroButton = SPELLBOOK_ABILITIES_BUTTON,
			TalentMicroButton = TALENTS_BUTTON,
			AchievementMicroButton = ACHIEVEMENT_BUTTON,
			QuestLogMicroButton = QUESTLOG_BUTTON,
			SocialsMicroButton = SOCIALS,
			PVPMicroButton = PLAYER_V_PLAYER,
			LFGMicroButton = DUNGEONS_BUTTON,
			WorldMapMicroButton = WORLD_MAP,
			GuildMicroButton = LOOKINGFORGUILD,
			LFDMicroButton = DUNGEONS_BUTTON,
			CollectionsMicroButton = COLLECTIONS,
			EJMicroButton = ADVENTURE_JOURNAL or ENCOUNTER_JOURNAL,
			StoreMicroButton = BLIZZARD_STORE,
			MainMenuMicroButton = MAINMENU_BUTTON,
			HelpMicroButton = HELP_BUTTON
		}

		for i,v in ipairs(buttons) do
			anchors[i] = { v:GetPoint() }

			v.OnEnter = v:GetScript("OnEnter")
			v.OnLeave = v:GetScript("OnLeave")
			v:SetScript("OnEnter", nil)
			v:SetScript("OnLeave", nil)
			v:SetFrameLevel(bar:GetFrameLevel() + 1)

			local b = CreateFrame("Frame", nil, v, "SecureHandlerStateTemplate")
			b:SetMouseMotionEnabled(true)
			b:SetMouseClickEnabled(false)
			b:SetIgnoreParentAlpha(true)
			b:SetAlpha(1)
			b:SetFrameLevel(v:GetFrameLevel() - 1)
			b:SetSize(200, 30)
			b:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -26, 64 + (i-1)*30)

			local c = b:CreateTexture(nil, "ARTWORK")
			c:SetPoint("TOPLEFT", 1,-1)
			c:SetPoint("BOTTOMRIGHT", -1,1)
			c:SetColorTexture(1,1,1,.9)

			v:SetScript("OnEnter", function() c:SetVertexColor(.75,.75,.75) end)
			v:SetScript("OnLeave", function() c:SetVertexColor(.1,.1,.1) end)
			v:GetScript("OnLeave")(v)

			local d = b:CreateFontString(nil, "OVERLAY")
			d:SetFontObject(GetFont(13,true))
			d:SetText(labels[v:GetName()])
			d:SetJustifyH("CENTER")
			d:SetJustifyV("MIDDLE")
			d:SetPoint("CENTER")

			custom[v] = b
		end

		bar.backdrop = backdrop
		bar.buttons = buttons
		bar.anchors = anchors
		bar.custom = custom

		self.bar = bar

		--self:UpdateButtonLayout()

		local toggle = CreateFrame("CheckButton", nil, UIParent, "SecureHandlerClickTemplate")
		toggle:SetScale(ns:GetRelativeScale())
		toggle:SetSize(48, 48)
		toggle:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 4)
		toggle:RegisterForClicks("AnyUp")
		toggle:SetFrameRef("Bar", bar)

		for i,v in ipairs(buttons) do
			toggle:SetFrameRef("Button"..i, custom[v])
		end

		toggle:SetAttribute("_onclick", [[
			local bar = self:GetFrameRef("Bar");
			if (bar:IsShown()) then
				bar:Hide();
			else
				bar:Show();
			end

			bar:UnregisterAutoHide();

			if (bar:IsShown()) then
				bar:RegisterAutoHide(.75);
				bar:AddToAutoHide(self);

				local i = 1;
				local button = self:GetFrameRef("Button"..i);
				while (button) do
					i = i + 1;
					bar:AddToAutoHide(button);
					button = self:GetFrameRef("Button"..i);
				end
			end
		]])

		local texture = toggle:CreateTexture(nil, "ARTWORK", nil, 0)
		texture:SetSize(96, 96)
		texture:SetPoint("CENTER", 0, 0)
		texture:SetTexture(GetMedia("config_button"))
		texture:SetVertexColor(Colors.ui[1], Colors.ui[2], Colors.ui[3])

		RegisterStateDriver(toggle, "visibility", "[petbattle]hide;show")

	end

	self:SecureHook("UpdateMicroButtons", "MicroMenuBarShow")
	self:SecureHook("UpdateMicroButtonsParent")
	self:SecureHook("ActionBarController_UpdateAll")
	self:RegisterEvent("PET_BATTLE_CLOSE", "OnEvent")

	self:MicroMenuBarShow()

end

MicroMenu.OnEvent = function(self, event, ...)
	if (event == "PET_BATTLE_CLOSE") then
		UpdateMicroButtonsParent(self.bar)
		self:MicroMenuBarShow()
	end
end

MicroMenu.OnInitialize = function(self)
	if (ns.API.IsAddOnEnabled("ConsolePort")) then
		return self:Disable()
	end
end

MicroMenu.OnEnabled = function(self)
	if (ns.API.IsAddOnEnabled("Bartender4") and not ns.BartenderHandled) then
		ns.RegisterCallback(self, "Bartender_Handled", "InitializeMicroMenu")
	else
		self:InitializeMicroMenu()
	end
end
