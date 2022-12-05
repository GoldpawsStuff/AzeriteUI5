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
local Addon, AzeriteUI5 = ...

-- Addon version
------------------------------------------------------
-- Keyword substitution requires the packager,
-- and does not affect direct GitHub repo pulls.
local version = "@project-version@"
if (version:find("project%-version")) then
	version = "Development"
end
AzeriteUI5.Private.Version = version
AzeriteUI5.Private.IsDevelopment = version == "Development"
AzeriteUI5.Private.IsAlpha = string.find(version, "%-Alpha$")
AzeriteUI5.Private.IsBeta = string.find(version, "%-Beta$")
AzeriteUI5.Private.IsRC = string.find(version, "%-RC$")
AzeriteUI5.Private.IsRelease = string.find(version, "%-Release$")

-- WoW client version
------------------------------------------------------
local patch, build, date, version = GetBuildInfo()
local major, minor = string.split(".", patch)

AzeriteUI5.Private.ClientVersion = version
AzeriteUI5.Private.ClientDate = date
AzeriteUI5.Private.ClientPatch = patch
AzeriteUI5.Private.ClientMajor = tonumber(major)
AzeriteUI5.Private.ClientMinor = tonumber(minor)
AzeriteUI5.Private.ClientBuild = tonumber(build)

-- Simple flags for client version checks
AzeriteUI5.Private.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
AzeriteUI5.Private.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
AzeriteUI5.Private.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
AzeriteUI5.Private.IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
AzeriteUI5.Private.WoW10 = version >= 100000

-- Prefix for frame names
------------------------------------------------------
AzeriteUI5.Private.Prefix = string.gsub(Addon, "UI(%d*)", "")

-- Player constants
------------------------------------------------------
local _,playerClass = UnitClass("player")
AzeriteUI5.Private.PlayerClass = playerClass
AzeriteUI5.Private.PlayerRealm = GetRealmName()
AzeriteUI5.Private.PlayerName = UnitNameUnmodified("player")

-- Scaling Constants
------------------------------------------------------
AzeriteUI5.UIScale = 768/1080
AzeriteUI5.Private.UIDefaultScale = 768/1080
