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
local MAJOR_VERSION = "LibFadingFrames-1.0"
local MINOR_VERSION = 40

assert(LibStub, MAJOR_VERSION .. " requires LibStub.")

local LibMoreEvents = LibStub:GetLibrary("LibMoreEvents-1.0", true)
assert(MAJOR_VERSION .. " requires LibMoreEvents-1.0.")

local AceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
assert(MAJOR_VERSION .. " requires AceTimer-3.0.")

local AceHook = LibStub:GetLibrary("AceHook-3.0", true)
assert(MAJOR_VERSION .. " requires AceHook-3.0.")

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

LibMoreEvents:Embed(lib)
AceTimer:Embed(lib)
AceHook:Embed(lib)

lib.frame = lib.frame or CreateFrame("Frame", nil, UIParent)
lib.fadeFrames = lib.fadeFrames or {} -- fadeFrames[frame] = "fadeGroup"
lib.fadeFrameType = lib.fadeFrameType or {} -- fadeFrameType[frame] = "type" (e.g "actionbutton")
lib.fadeFrameCurrentAlpha = lib.fadeFrameCurrentAlpha or {} -- fadeFrameCurrentAlpha[frame] = alpha
lib.fadeFrameTargetAlpha = lib.fadeFrameTargetAlpha or {} -- fadeFrameTargetAlpha[frame] = alpha
lib.fadeFrameHitRects = lib.fadeFrameHitRects or {}
lib.hoverFrames = lib.hoverFrames or {} -- hoverFrames[frame] = "fadeGroup"
lib.hoveredGroups = lib.hoveredGroups or {} -- lib.hoveredGroups[fadeGroup] = boolean
lib.hoverCount = lib.hoverCount or { default = 0 } -- hoverCount[groupName] = count
lib.gridCounter = lib.gridCounter or 0
lib.petGridCounter = lib.petGridCounter or 0
lib.embeds = lib.embeds or {}

-- General fade settings.
local fadeThrottle = .05
local fadeInDuration = .1
local fadeOutDuration = .25

lib.fadeThrottle = fadeThrottle
lib.fadeInDuration = fadeInDuration
lib.fadeOutDuration = fadeOutDuration

-- speed!
local FadeFrames = lib.fadeFrames
local FadeFrameType = lib.fadeFrameType
local FadeFrameCurrentAlpha = lib.fadeFrameCurrentAlpha
local FadeFrameTargetAlpha = lib.fadeFrameTargetAlpha
local FadeFrameHitRects = lib.fadeFrameHitRects
local HoverFrames = lib.hoverFrames
local HoveredGroups = lib.hoveredGroups
local HoverCount = lib.hoverCount

-- GLOBALS: CreateFrame, IsPlayerInWorld, LAB10GEFlyoutHandlerFrame, SpellFlyout

-- Lua API
local getmetatable = getmetatable
local math_floor = math.floor
local next = next
local pairs = pairs
local select = select
local tonumber = tonumber
local unpack = unpack

-- Game flavor constants
local patch, build, date, version = GetBuildInfo()
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
--local isCata = WOW_PROJECT_ID == (WOW_PROJECT_CATA_CLASSIC or 99) -- NYI in first build
local isCata = (version >= 40400) and (version < 50000)
local WoW10 = version >= 100000

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha
local getAlpha = getmetatable(CreateFrame("Frame")).__index.GetAlpha

-- Alpha setter that also stores the alpha in our local registry
local setCurrentAlpha = function(frame, alpha)

	setAlpha(frame, alpha)

	-- Store the desired value,
	-- even for empty slots.
	FadeFrameCurrentAlpha[frame] = alpha
end

-- Request an alpha change, trigger fade animation.
local requestAlpha = function(frame, targetAlpha)

	-- Always do this, even if alpha goal is reached.
	-- There's a minor bug in blizzard's frame alpha code where upon showing
	-- a frame its children can be rendered fully visible even if their alpha is set to zero.
	-- Adding an extra check on the next frame update will
	-- update the alpha correctly after the parent has changed its.
	if (not next(FadeFrameTargetAlpha)) then
		if (not lib.fadeTimer) then
			lib.fadeTimer = lib:ScheduleRepeatingTimer("UpdateCurrentAlphas", fadeThrottle)
		end
	end

	-- Store the requested target alpha,
	-- this is what tells the fade timer to fade.
	FadeFrameTargetAlpha[frame] = targetAlpha
end

local updateCurrentAlpha = function(frame)

	local targetAlpha = FadeFrameTargetAlpha[frame]
	local currentAlpha = FadeFrameCurrentAlpha[frame] or math_floor((getAlpha(frame) * 100) + .5) / 100

	-- If we're fading out
	if (currentAlpha > targetAlpha) then

		-- Is there room to change the alpha?
		if (lib.fadeOutDuration > 0) and (currentAlpha - fadeThrottle/lib.fadeOutDuration > targetAlpha) then
			setCurrentAlpha(frame, currentAlpha - fadeThrottle/lib.fadeOutDuration)
		else

			-- The fade is finished.
			setCurrentAlpha(frame, targetAlpha)

			FadeFrameTargetAlpha[frame] = nil
			HoveredGroups[FadeFrames[frame]] = nil
		end

	-- If we're fading in
	elseif (currentAlpha < targetAlpha) then

		-- Is there room to change the alpha?
		if (lib.fadeInDuration > 0) and (currentAlpha + fadeThrottle/lib.fadeInDuration < targetAlpha) then
			setCurrentAlpha(frame, currentAlpha + fadeThrottle/lib.fadeInDuration)
		else

			-- The fade is finished.
			setCurrentAlpha(frame, targetAlpha)

			FadeFrameTargetAlpha[frame] = nil
			HoveredGroups[FadeFrames[frame]] = nil
		end
	else

		-- This is not redundant.
		-- When both parent and child has a fader,
		-- the child can get stuck at max opacity after changing the parent,
		-- and setting the child on the next frame cycle through this will fix it.
		setCurrentAlpha(frame, targetAlpha)

		FadeFrameTargetAlpha[frame] = nil
		HoveredGroups[FadeFrames[frame]] = nil
	end
end

lib.UpdateCurrentAlphas = function()

	-- Iterate frames that hasn't yet been verified
	-- to have reached their target opacity.
	for frame in next,FadeFrameTargetAlpha do
		if (FadeFrames[frame]) then
			updateCurrentAlpha(frame)
		end
	end

	-- Kill off this timer if nothing is still fading.
	if (not next(FadeFrameTargetAlpha)) then
		if (lib.fadeTimer) then
			lib:CancelTimer(lib.fadeTimer)
			lib.fadeTimer = nil
		end
	end
end

local updateTargetAlpha = function(frame)
	if (not lib.enableFading) then
		requestAlpha(frame, 1)
	else
		local forceShow

		local frameType = FadeFrameType[frame]
		if (frameType == "petbutton") then
			if (lib.inCombat and not (frame.header and frame.header.config and frame.header.config.fadeInCombat))
			or (lib.petGridCounter > 0 and not frame.ignoreGridCounterOnHover and (lib.cursorType == "petaction")) then
				forceShow = true
			end

		elseif (frameType == "actionbutton") then
			if (lib.flyoutShown)
			or (lib.inCombat and not(frame.header and frame.header.config and frame.header.config.fadeInCombat)) or (lib.gridCounter > 0 and not frame.ignoreGridCounterOnHover and (lib.cursorType ~= "petaction" or isRetail))
			then
				forceShow = true
			end
		end

		if (forceShow) then
			requestAlpha(frame, 1)
		else

			-- The group is visible.
			local fadeGroup = FadeFrames[frame]
			if (HoverCount[fadeGroup] > 0) then
				requestAlpha(frame, 1)
			else
				-- Group is hidden, hide this.
				--if (HoveredGroups[fadeGroup]) then
					requestAlpha(frame, 0)
				--else
				--	setCurrentAlpha(frame, 0)
				--end
			end
		end

	end
end

lib.UpdateTargetAlphas = function()
	if (not lib.inWorld) then return end

	lib.cursorType = GetCursorInfo()

	for frame in next,FadeFrames do
		updateTargetAlpha(frame)
	end
end

lib.OnFadeFrameEnter = function(_, frame, fadeGroup)
	if (HoverFrames[frame]) then return end

	HoverCount[fadeGroup] = HoverCount[fadeGroup] + 1
	HoverFrames[frame] = fadeGroup
end

lib.OnFadeFrameLeave = function(_, frame, fadeGroup)
	if (not HoverFrames[frame]) then return end

	HoverCount[fadeGroup] = HoverCount[fadeGroup] - 1
	HoveredGroups[fadeGroup] = true
	HoverFrames[frame] = nil
end

lib.CheckHoverFrames = function(needupdate)

	for frame,fadeGroup in next,HoverFrames do
		-- Frame could've been unregistered while hovered.
		local rects = FadeFrameHitRects[frame]
		if (not FadeFrames[frame] or not frame:IsMouseOver(rects[1], rects[2], rects[3], rects[4])) then
			lib:OnFadeFrameLeave(frame, fadeGroup)
			needupdate = true
		end
	end

	for frame,fadeGroup in next,FadeFrames do
		local rects = FadeFrameHitRects[frame]
		if (not HoverFrames[frame] and frame:IsVisible() and frame:IsMouseOver(rects[1], rects[2], rects[3], rects[4])) then
			lib:OnFadeFrameEnter(frame, fadeGroup)
			needupdate = true
		end
	end

	if (needupdate) then
		lib:UpdateTargetAlphas()
	end
end

lib.UpdateFlyout = function()
	if (not lib.flyoutHandler) then return end

	lib.flyoutShown = lib.flyoutHandler:IsShown()

	lib:UpdateTargetAlphas()
end

lib.SetFadeInDuration = function(_, duration)
	lib.fadeInDuration = tonumber(duration) or fadeInDuration
end

lib.SetFadeOutDuration = function(_, duration)
	lib.fadeOutDuration = tonumber(duration) or fadeOutDuration
end

lib.RegisterFrameForFading = function(_, frame, fadeGroup, ...)
	local shouldInit = not next(FadeFrames)
	if (FadeFrames[frame]) then
		return
	end

	fadeGroup = fadeGroup or "default"

	-- Not the best check ever, but it'll have to do for now.
	if (frame:GetObjectType() == "CheckButton") and (frame.HasAction) then

		if (frame.GetAttribute and frame:GetAttribute("type") == "pet") then
			FadeFrameType[frame] = "petbutton"
		else
			FadeFrameType[frame] = "actionbutton"
		end

		-- Keep track of the flyout handlers.
		if (not lib.flyoutHandler) then
			local flyoutHandler = WoW10 and LAB10GEFlyoutHandlerFrame or SpellFlyout
			if (flyoutHandler) then
				lib:HookScript(flyoutHandler, "OnShow", "UpdateFlyout")
				lib:HookScript(flyoutHandler, "OnHide", "UpdateFlyout")
				lib.flyoutHandler = flyoutHandler
			end
		end

	end

	-- Hooking proved to create a lot of problems,
	-- it is ultimately better in this scenario to replace.
	frame.SetAlpha = function() end

	if (not HoverCount[fadeGroup]) then
		HoverCount[fadeGroup] = 0
	end

	local rects = FadeFrameHitRects[frame]
	if (not rects) then
		rects = {}
		FadeFrameHitRects[frame] = rects
	end

	FadeFrames[frame] = fadeGroup

	-- Convert frame hit rects to mouseover values.
	if (...) then
		local left, right, top, bottom = ...
		rects[1], rects[2], rects[3], rects[4] = -top, bottom, left, -right
	else
		rects[1], rects[2], rects[3], rects[4] = 0, 0, 0, 0
	end

	if (shouldInit) then
		lib:Enable()
	end

	--requestAlpha(frame, 0)
	--setCurrentAlpha(frame, 0)

	lib:UpdateTargetAlphas()
end

lib.UnregisterFrameForFading = function(_, frame)
	if (not FadeFrames[frame]) then
		return
	end

	local frameType = FadeFrameType[frame]

	frame.SetAlpha = nil

	FadeFrames[frame] = nil
	FadeFrameType[frame] = nil

	local rects = FadeFrameHitRects[frame]
	if (rects) then
		rects[1], rects[2], rects[3], rects[4] = 0, 0, 0, 0
	end

	-- Return frames to full opacity.
	if (frameType ~= "actionbutton" and frameType ~= "petbutton") then
		setCurrentAlpha(frame, 1)
	end

	if (not next(FadeFrames)) then
		lib:Disable()
	end

	--lib:UpdateTargetAlphas()
end

lib.Enable = function()
	if (lib.enableFading) then return end

	lib.enableFading = true

	lib:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	lib:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	lib:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	lib:RegisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	lib:RegisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")
	lib:RegisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	lib:RegisterEvent("PET_BAR_HIDEGRID", "OnEvent")

	if (IsPlayerInWorld()) then
		lib:OnEvent("PLAYER_ENTERING_WORLD")
	end

	if (not lib.checkTimer) then
		lib.checkTimer = lib:ScheduleRepeatingTimer("CheckHoverFrames", 0.1)
	end

	lib:UpdateTargetAlphas()

end

lib.Disable = function()
	if (not lib.enableFading) then return end

	lib.enableFading = false

	lib:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	lib:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	lib:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	lib:UnregisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	lib:UnregisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")
	lib:UnregisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	lib:UnregisterEvent("PET_BAR_HIDEGRID", "OnEvent")

	if (lib.checkTimer) then
		lib:CancelTimer(lib.checkTimer)
		lib.checkTimer = nil
	end

	lib:UpdateTargetAlphas()
end

lib.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		lib.inWorld = true
		lib.inCombat = nil

		for fadeGroup in next,HoverCount do
			HoverCount[fadeGroup] = 0
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		lib.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		lib.inCombat = nil

	elseif (event == "ACTIONBAR_SHOWGRID") then
		lib.gridCounter = lib.gridCounter + 1

		if (lib.gridCounter >= 1) then
			lib:UpdateTargetAlphas()
		end
		return

	elseif (event == "ACTIONBAR_HIDEGRID") then
		if (lib.gridCounter > 0) then
			lib.gridCounter = lib.gridCounter - 1
		end
		if (lib.gridCounter == 0) then
			lib:UpdateTargetAlphas()
		end
		return

	elseif (event == "PET_BAR_SHOWGRID") then
		lib.petGridCounter = lib.petGridCounter + 1

		if (lib.petGridCounter >= 1) then
			lib:UpdateTargetAlphas()
		end
		return

	elseif (event == "PET_BAR_HIDEGRID") then
		if (lib.petGridCounter > 0) then
			lib.petGridCounter = lib.petGridCounter - 1
		end
		if (isClassic and lib.gridCounter > 0) then
			lib.gridCounter = lib.gridCounter - 1
		end
		if (lib.petGridCounter == 0 or (isClassic and lib.gridCounter == 0)) then
			lib:UpdateTargetAlphas()
		end
		return
	end

	lib:UpdateTargetAlphas()
end

local mixins = {
	SetFadeInDuration = true,
	SetFadeOutDuration = true,
	RegisterFrameForFading = true,
	UnregisterFrameForFading = true
}

lib.Embed = function(_, target)
	for method in pairs(mixins) do
		target[method] = lib[method]
	end
	lib.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
