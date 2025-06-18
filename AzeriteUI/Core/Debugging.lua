--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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
local Debugging = ns:NewModule("Debugging", "LibMoreEvents-1.0", "AceConsole-3.0")

-- GLOBALS: EnableAddOn, GetAddOnInfo

-- Lua API
local next = next
local print = print
local select = select
local string_format = string.format

local ADDONS = {

	"Blizzard_AchievementUI",
	"Blizzard_AdventureMap",
	"Blizzard_AlliedRacesUI",
	"Blizzard_AnimaDiversionUI",
	"Blizzard_APIDocumentation",
	"Blizzard_ArchaeologyUI",
	"Blizzard_ArdenwealdGardening",
	"Blizzard_ArenaUI",
	"Blizzard_ArtifactUI",
	"Blizzard_AuctionHouseUI",
	"Blizzard_AuthChallengeUI",
	"Blizzard_AzeriteEssenceUI",
	"Blizzard_AzeriteRespecUI",
	"Blizzard_AzeriteUI",
	"Blizzard_BarbershopUI",
	"Blizzard_BattlefieldMap",
	"Blizzard_BehavioralMessaging",
	"Blizzard_BlackMarketUI",
	"Blizzard_BoostTutorial",
	"Blizzard_Calendar",
	"Blizzard_ChallengesUI",
	"Blizzard_Channels",
	"Blizzard_CharacterCreate",
	"Blizzard_CharacterCustomize",
	"Blizzard_ChromieTimeUI",
	"Blizzard_ClassTalentUI",
	"Blizzard_ClassTrial",
	"Blizzard_ClickBindingUI",
	"Blizzard_ClientSavedVariables",
	"Blizzard_Collections",
	"Blizzard_CombatLog",
	"Blizzard_CombatText",
	"Blizzard_Commentator",
	"Blizzard_Communities",
	"Blizzard_CompactRaidFrames",
	"Blizzard_Console",
	"Blizzard_Contribution",
	"Blizzard_CovenantCallings",
	"Blizzard_CovenantPreviewUI",
	"Blizzard_CovenantRenown",
	"Blizzard_CovenantSanctum",
	"Blizzard_CovenantToasts",
	"Blizzard_CUFProfiles",
	"Blizzard_DeathRecap",
	"Blizzard_DebugTools",
	"Blizzard_Deprecated",
	"Blizzard_EncounterJournal",
	"Blizzard_EventTrace",
	"Blizzard_ExpansionLandingPage",
	"Blizzard_FlightMap",
	"Blizzard_FrameEffects",
	"Blizzard_GarrisonTemplates",
	"Blizzard_GarrisonUI",
	"Blizzard_GenericTraitUI",
	"Blizzard_GMChatUI",
	"Blizzard_GuildBankUI",
	"Blizzard_GuildControlUI",
	"Blizzard_GuildUI",
	"Blizzard_HybridMinimap",
	"Blizzard_InspectUI",
	"Blizzard_IslandsPartyPoseUI",
	"Blizzard_IslandsQueueUI",
	"Blizzard_ItemInteractionUI",
	"Blizzard_ItemSocketingUI",
	"Blizzard_ItemUpgradeUI",
	"Blizzard_Kiosk",
	"Blizzard_LandingSoulbinds",
	"Blizzard_MacroUI",
	"Blizzard_MainlineSettings",
	"Blizzard_MajorFactions",
	"Blizzard_MapCanvas",
	"Blizzard_MawBuffs",
	"Blizzard_MoneyReceipt",
	"Blizzard_MovePad",
	"Blizzard_NamePlates",
	"Blizzard_NewPlayerExperience",
	"Blizzard_NewPlayerExperienceGuide",
	"Blizzard_ObjectiveTracker",
	"Blizzard_ObliterumUI",
	"Blizzard_OrderHallUI",
	"Blizzard_PartyPoseUI",
	"Blizzard_PetBattleUI",
	"Blizzard_PlayerChoice",
	"Blizzard_Professions",
	"Blizzard_ProfessionsCrafterOrders",
	"Blizzard_ProfessionsCustomerOrders",
	"Blizzard_PTRFeedback",
	"Blizzard_PTRFeedbackGlue",
	"Blizzard_PVPMatch",
	"Blizzard_PVPUI",
	"Blizzard_QuestNavigation",
	"Blizzard_RaidUI",
	"Blizzard_RuneforgeUI",
	"Blizzard_ScrappingMachineUI",
	"Blizzard_SecureTransferUI",
	"Blizzard_SelectorUI",
	"Blizzard_Settings",
	"Blizzard_SharedMapDataProviders",
	"Blizzard_SharedTalentUI",
	"Blizzard_SocialUI",
	"Blizzard_Soulbinds",
	"Blizzard_StoreUI",
	"Blizzard_SubscriptionInterstitialUI",
	"Blizzard_TalentUI",
	"Blizzard_TalkingHeadUI",
	"Blizzard_TimeManager",
	"Blizzard_TokenUI",
	"Blizzard_TorghastLevelPicker",
	"Blizzard_TrainerUI",
	"Blizzard_Tutorial",
	"Blizzard_TutorialTemplates",
	"Blizzard_UIFrameManager",
	"Blizzard_UIWidgets",
	"Blizzard_VoidStorageUI",
	"Blizzard_WarfrontsPartyPoseUI",
	"Blizzard_WeeklyRewards",
	"Blizzard_WorldMap",
	"Blizzard_WowTokenUI"

}

Debugging.EnableBlizzardAddOns = function(self)
	local disabled = {}
	for _,addon in next,ADDONS do
		local reason = select(5, GetAddOnInfo(addon))
		if (reason == "DISABLED") then
			EnableAddOn(addon)
			disabled[#disabled + 1] = addon
		end
	end
	local num = #disabled
	if (num == 0) then
		print("|cff33ff99", "No Blizzard addons were disabled.")
	else
		if (num > 1) then
			print("|cff33ff99", string_format("The following %d Blizzard addons were enabled:", #disabled))
		else
			print("|cff33ff99", "The following Blizzard addon was enabled:")
		end
		for _,addon in next,ADDONS do
			print(string_format("|cfff0f0f0%s|r", addon))
		end
		print("|cfff00a0aA /reload is required to apply changes!|r")
	end
end

Debugging.EnableScriptErrors = function(self)
	SetCVar("scriptErrors", 1)
end

Debugging.OnEvent = function(self, event, ...)
	self:EnableScriptErrors()
end

Debugging.OnInitialize = function(self)
	self:RegisterChatCommand("enableblizzard", "EnableBlizzardAddOns")
	if (ns.WoW10) then
		self:RegisterEvent("SETTINGS_LOADED", "OnEvent")
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:EnableScriptErrors()
end
