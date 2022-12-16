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
local oUF = ns.oUF

local BlizzardUFDisabler = ns:NewModule("BlizzardUFDisabler")

BlizzardUFDisabler.OnEnable = function(self)

	oUF:DisableBlizzard("pet")
	oUF:DisableBlizzard("target")
	oUF:DisableBlizzard("focus")

	-- Disable Boss Frames
	for i = 1, MAX_BOSS_FRAMES do
		oUF:DisableBlizzard("boss"..i)
	end

	-- Disable Arena Enemy Frames
	for i = 1, MAX_ARENA_ENEMIES do
		oUF:DisableBlizzard("arena"..i)
	end

	-- Disable Paryt & Raid Frames
	for i = 1, MEMBERS_PER_RAID_GROUP do
		oUF:DisableBlizzard("party"..i)
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	LoadAddOn("Blizzard_CUFProfiles")
	LoadAddOn("Blizzard_CompactRaidFrames")

	CompactRaidFrameManager_SetSetting("IsShown", "0")

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:SetParent(ns.Hider)

end