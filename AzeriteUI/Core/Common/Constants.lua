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

-- Lua API
local string_find = string.find
local string_match = string.match
local string_split = string.split
local tonumber = tonumber

-- GLOBALS: GetBuildInfo, GetRealmName, UnitClass, UnitNameUnmodified
-- GLOBALS: WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- Addon version
------------------------------------------------------
-- Keyword substitution requires the packager,
-- and does not affect direct GitHub repo pulls.
local version = "@project-version@"
if (version:find("project%-version")) then
	version = "Development"
end
ns.Private.Version = version
ns.Private.IsDevelopment = version == "Development"
ns.Private.IsAlpha = string_find(version, "%-Alpha$")
ns.Private.IsBeta =string_find(version, "%-Beta$")
ns.Private.IsRC = string_find(version, "%-RC$")
ns.Private.IsRelease = string_find(version, "%-Release$")

-- WoW client version
------------------------------------------------------
local patch, build, date, version = GetBuildInfo()
local major, minor, micro = string_split(".", patch)

ns.Private.ClientVersion = version
ns.Private.ClientDate = date
ns.Private.ClientPatch = patch
ns.Private.ClientMajor = tonumber(major)
ns.Private.ClientMinor = tonumber(minor)
ns.Private.ClientMicro = tonumber(micro)
ns.Private.ClientBuild = tonumber(build)

-- Simple flags for client version checks
ns.Private.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.Private.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.Private.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.Private.IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
--ns.Private.IsCata = WOW_PROJECT_ID == (WOW_PROJECT_CATA_CLASSIC or 99) -- NYI in first build
ns.Private.IsCata = (version >= 40400) and (version < 50000)
ns.Private.WoW10 = version >= 100000

-- Developer Mode constants
------------------------------------------------------
ns.Private.IsInTestMode = IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown()
ns.Private.IsVerboseMode = not ns.Private.IsInTestMode and IsShiftKeyDown()

-- Prefix for frame names
------------------------------------------------------
ns.Private.Prefix = string_match(Addon, "^(.*)UI") or Addon

-- Player constants
------------------------------------------------------
local _,playerClass = UnitClass("player")
ns.Private.PlayerClass = playerClass
ns.Private.PlayerRealm = GetRealmName()
ns.Private.PlayerName = UnitNameUnmodified("player")
