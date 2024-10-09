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

if (not ns.IsRetail) then return end

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Banners = ns:NewModule("Banners", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local next = next
local unpack = unpack

local banners = {
	{ nil, "ArtifactLevelUpToast", 128, 128, "TOP", 0, -123 },
	{ nil, "AzeriteLevelUpToast", 128, 128, "TOP", 0, -123 },
	{ nil, "BossBanner", 128, 156, "TOP", 0, -120 },
	{ nil, "HonorLevelUpBanner", 128, 128, "TOP", 0, -133 },
	{ nil, "LevelUpDisplay", 418, 72, "TOP", 0, -190 },
	{ nil, "PrestigeLevelUpBanner", 128, 128, "TOP", 0, -270 },
	{ "Blizzard_ChallengesUI", "ChallengeModeCompleteBanner", 128, 356, "TOP", 0, -120 },
	{ "Blizzard_CovenantToasts", "CovenantChoiceToast", 128, 128, "TOP", 0, -160 },
	{ "Blizzard_CovenantToasts", "CovenantRenownToast", 128, 128, "TOP", 0, -160 },
	{ "Blizzard_MajorFactions", "MajorFactionsRenownToast", 128, 128, "TOP", 0, -160 },
	{ "Blizzard_MajorFactions", "MajorFactionUnlockToast", 128, 128, "TOP", 0, -180 },
	{ "Blizzard_ObjectiveTracker", "ObjectiveTrackerBonusBannerFrame", 128, 128, "TOP", 0, -170 },
	{ "Blizzard_ObjectiveTracker", "ObjectiveTrackerTopBannerFrame", 128, 128, "TOP", 0, -170 },
	{ "Blizzard_PVPUI", "PvPObjectiveBannerFrame", 128, 128, "TOP", 0, -180 }
}

local defaults = { profile = ns:Merge({
	hideArtifact = false,
	HideBoss = false,
	hideLevel = false,
	hidePvP = false,
	hideChallenges = false,
	hideCovenant = false,
	hideMajorFactions = false,
	hideObjectives = false
}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Banners.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOP",
		[2] = 0 * ns.API.GetEffectiveScale(),
		[3] = -180 * ns.API.GetEffectiveScale()
	}
	return defaults
end

Banners.TopBannerManager_Show = function(self, frame, data, isExclusiveQueued)
	if (self.banners[frame]) then return end

	local isCurrent = TopBannerMgr.currentBanner and TopBannerMgr.currentBanner.frame == frame
	if (isCurrent) then
		frame:StopBanner()
	end

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)

	self.banners[frame] = true

	if (isCurrent) then
		frame:PlayBanner(data)
	end

end

Banners.PrepareFrames = function(self)

	local frame = CreateFrame("Frame", ns.Prefix.."BannerFrameHolder", UIParent)
	frame:SetSize(418,128)
	frame:SetPoint(unpack(Banners.db.profile.savedPosition))

	self.frame = frame
	self.banners = {}

	for i,data in next,banners do
		local addon, name, w, h, point, x, y = unpack(data)
		if (_G[name]) then
			self:TopBannerManager_Show(_G[name])
		end
	end

	self:SecureHook("TopBannerManager_Show", "TopBannerManager_Show")
end

Banners.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(L["Banners"])
	self.anchor:SetScalable(false)
	self.anchor:RestrictToVertical()

	ns.MovableModulePrototype.OnEnable(self)
end
