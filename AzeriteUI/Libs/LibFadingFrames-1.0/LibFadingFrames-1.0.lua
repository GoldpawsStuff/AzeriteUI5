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
local MAJOR_VERSION = "LibFadingFrames-1.0"
local MINOR_VERSION = 36

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
lib.hoverCount = lib.hoverCount or { default = 0 } -- hoverCount[groupName] = count
lib.gridCounter = lib.gridCounter or 0
lib.petGridCounter = lib.petGridCounter or 0
lib.embeds = lib.embeds or {}

-- General fade settings.
local fadeThrottle = .02
local fadeInDuration = .1
local fadeOutDuration = .35
local fadeHoldDuration = 0

lib.fadeThrottle = fadeThrottle
lib.fadeInDuration = fadeInDuration
lib.fadeOutDuration = fadeOutDuration
lib.fadeHoldDuration = fadeHoldDuration

-- speed!
local FadeFrames = lib.fadeFrames
local FadeFrameType = lib.fadeFrameType
local FadeFrameCurrentAlpha = lib.fadeFrameCurrentAlpha
local FadeFrameTargetAlpha = lib.fadeFrameTargetAlpha
local FadeFrameHitRects = lib.fadeFrameHitRects
local HoverFrames = lib.hoverFrames
local HoverCount = lib.hoverCount

-- GLOBALS: CreateFrame, IsPlayerInWorld, LAB10GEFlyoutHandlerFrame, SpellFlyout

-- Lua API
local getmetatable = getmetatable
local math_floor = math.floor
local next = next
local pairs = pairs
local select = select
local unpack = unpack

-- Game flavor constants
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoW10 = select(4, GetBuildInfo()) >= 100000

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha
local getAlpha = getmetatable(CreateFrame("Frame")).__index.GetAlpha

-- Check if a frame is of the type actionbutton.
local isButton = function(frame)
	return frame and FadeFrameType[frame] == "actionbutton"
end

-- Check if a frame is a pet actionbutton.
local isPetButton = function(frame)
	return frame and FadeFrameType[frame] == "actionbutton" and frame.GetAttribute and frame:GetAttribute("type") == "pet"
end

-- Check if a frame is an empty action button set to have no visible slot.
-- This will return false when you hold an item on the cursor that fit the slot.
local isTransparentButton = function(frame)
	if (not frame) then return end

	local isEmpty = isButton(frame) and not frame:GetTexture() and not (frame.config and frame.config.showGrid)
	if (isEmpty) then
		if (CursorHasSpell() or CursorHasItem()) then
			return false
		end
		local cursor =  GetCursorInfo() -- money, merchant
		if (cursor == "spell")
		or (cursor == "macro")
		or (cursor == "mount")
		or (cursor == "item")
		or (cursor == "petaction" and (isPetButton(frame) or isRetail)) then
			return false
		end
		return true
	end
	return false
end

-- Alpha getter fixing the inconsistent blizzard return values
local getCurrentAlpha = function(frame)

	-- Report empty slots as transparent,
	-- regardless of actual values.
	if (isTransparentButton(frame)) then
		return 0
	end

	return FadeFrameCurrentAlpha[frame] or math_floor((getAlpha(frame) * 100) + .5) / 100
end

-- Alpha setter that also stores the alpha in our local registry
local setCurrentAlpha = function(frame, alpha)

	-- Keep empty slots faded,
	-- regardless of actual opacity.
	if (isTransparentButton(frame)) then
		setAlpha(frame, 0)
	else
		setAlpha(frame, alpha)
	end

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
			lib.fadeTimer = lib:ScheduleRepeatingTimer("UpdateCurrentlyFadingFrames", fadeThrottle)
		end
	end

	-- Store the requested target alpha,
	-- this is what tells the fade timer to fade.
	FadeFrameTargetAlpha[frame] = targetAlpha
end

-- Update: No longer needed, keeping it for reference for a while.
-- Our fade frame unregistration sets alpha back to full opacity,
-- this conflicts with how actionbuttons work so we're faking events to fix it.
--local updateLAB = function()
--	local LAB = LibStub("LibActionButton-1.0-GE", true)
--	local OnEvent = LAB and LAB.eventFrame:GetScript("OnEvent")
--	if (OnEvent) then
--		OnEvent(LAB, "ACTIONBAR_SHOWGRID")
--		OnEvent(LAB, "ACTIONBAR_HIDEGRID")
--	end
--end

lib.UpdateCurrentlyFadingFrames = function()

	-- Iterate frames that hasn't yet been verified
	-- to have reached their target opacity.
	for frame,targetAlpha in next,FadeFrameTargetAlpha do

		-- Retrieve a rounded, two decimal vale of the current alpha.
		local currentAlpha = getCurrentAlpha(frame)

		-- If we're fading out
		if (currentAlpha > targetAlpha) then

			-- Is there room to change the alpha?
			if (lib.fadeOutDuration > 0) and (currentAlpha - fadeThrottle/lib.fadeOutDuration > targetAlpha) then
				setCurrentAlpha(frame, currentAlpha - fadeThrottle/lib.fadeOutDuration)
			else

				-- The fade is finished.
				setCurrentAlpha(frame, targetAlpha)

				FadeFrameTargetAlpha[frame] = nil
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
			end
		else

			-- This is not redundant.
			-- When both parent and child has a fader,
			-- the child can get stuck at max opacity after changing the parent,
			-- and setting the child on the next frame cycle through this will fix it.
			setCurrentAlpha(frame, targetAlpha)

			FadeFrameTargetAlpha[frame] = nil
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

lib.UpdateFadeFrame = function(self, frame)

	local isActionButton = isButton(frame)
	local isEmpty = isActionButton and isTransparentButton(frame)
	local isPetButton = isActionButton and isPetButton(frame)

	if (isPetButton) then
		if (lib.inCombat and not (frame.header and frame.header.config and frame.header.config.fadeInCombat) and not isEmpty)
		or (lib.petGridCounter > 0 and not frame.ignoreGridCounterOnHover and (lib.cursorType == "petaction")) then
			requestAlpha(frame, 1)
			return
		end

	elseif (isActionButton) then
		if (lib.flyoutShown)
		or (not isEmpty and lib.inCombat and not(frame.header and frame.header.config and frame.header.config.fadeInCombat)) or (lib.gridCounter > 0 and not frame.ignoreGridCounterOnHover and (lib.cursorType ~= "petaction" or isRetail))
		then
			requestAlpha(frame, 1)
			return
		end
	end

	if (not lib.enableFading) then
		if (isActionButton) then

			-- The frame has an action or grid set to visible.
			if (not isEmpty) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
				requestAlpha(frame, 1)
			else
				requestAlpha(frame, 0)
			end
		else
			requestAlpha(frame, 1)
		end
	else
		-- The group is visible.
		if (HoverCount[FadeFrames[frame]] > 0) then
			if (isActionButton) then

				-- The frame has an action or grid set to visible.
				if (not isEmpty) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
					requestAlpha(frame, 1)
				else
					requestAlpha(frame, 0)
				end
			else
				requestAlpha(frame, 1)
			end
		else
			-- Group is hidden, hide this.
			requestAlpha(frame, 0)
		end
	end
end

lib.UpdateFadeFrames = function()
	if (not lib.inWorld) then return end

	lib.cursorType = GetCursorInfo()

	for frame in next,FadeFrames do
		lib:UpdateFadeFrame(frame)
	end
end

lib.OnFadeFrameEnter = function(self, frame, fadeGroup)
	if (HoverFrames[frame]) then return end

	HoverCount[fadeGroup] = HoverCount[fadeGroup] + 1
	HoverFrames[frame] = fadeGroup
end

lib.OnFadeFrameLeave = function(self, frame, fadeGroup)
	if (not HoverFrames[frame]) then return end

	HoverCount[fadeGroup] = HoverCount[fadeGroup] - 1
	HoverFrames[frame] = nil
end

lib.CheckFadeFrames = function()
	local needupdate
	for frame,fadeGroup in next,HoverFrames do
		-- Frame could've been unregistered while hovered.
		if (not FadeFrames[frame] or not frame:IsMouseOver(unpack(FadeFrameHitRects[frame]))) then
			lib:OnFadeFrameLeave(frame, fadeGroup)
			needupdate = true
		end
	end
	for frame,fadeGroup in next,FadeFrames do
		if (not HoverFrames[frame] and frame:IsVisible() and frame:IsMouseOver(unpack(FadeFrameHitRects[frame]))) then
			lib:OnFadeFrameEnter(frame, fadeGroup)
			needupdate = true
		end
	end
	if (needupdate) then
		lib:UpdateFadeFrames()
	end
end

lib.UpdateFlyout = function()
	if (not lib.flyoutHandler) then return end

	lib.flyoutShown = lib.flyoutHandler:IsShown()

	lib:UpdateFadeFrames()
end

lib.SetFadeInDuration = function(self, duration)
	lib.fadeInDuration = tonumber(duration) or fadeInDuration
end

lib.SetFadeOutDuration = function(self, duration)
	lib.fadeOutDuration = tonumber(duration) or fadeOutDuration
end

lib.RegisterFrameForFading = function(self, frame, fadeGroup, ...)
	if (FadeFrames[frame]) then
		return
	end

	local shouldInit = not next(FadeFrames)

	fadeGroup = fadeGroup or "default"

	-- Not the best check ever, but it'll have to do for now.
	if (frame:GetObjectType() == "CheckButton") and (frame.HasAction) then
		FadeFrameType[frame] = "actionbutton"

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
	--lib:SecureHook(frame, "SetAlpha", "UpdateFadeFrame")
	if (FadeFrameType[frame] == "actionbutton") then

		-- Keeping a one-way dummy function here so that
		-- the actionbutton library can hide empty slots instantly.
		frame.SetAlpha = function(frame, alpha)
			if (isTransparentButton(frame)) then
				setAlpha(frame, 0)
			end
		end
	else
		-- Nooping this method for all other frames,
		-- giving the fade library full control over the opacity.
		frame.SetAlpha = function() end
	end

	if (not HoverCount[fadeGroup]) then
		HoverCount[fadeGroup] = 0
	end

	FadeFrames[frame] = fadeGroup

	-- Convert frame hit rects to mouseover values.
	if (...) then
		local left, right, top, bottom = ...
		FadeFrameHitRects[frame] = { -top, bottom, left, -right }
	else
		FadeFrameHitRects[frame] = { 0, 0, 0, 0 }
	end

	if (shouldInit) then
		lib:Enable()
	end

	lib:UpdateFadeFrames()
end

lib.UnregisterFrameForFading = function(self, frame)
	if (not FadeFrames[frame]) then
		return
	end

	-- Retrieve button status before we reset registry entries.
	local isEmpty = isTransparentButton(frame)

	--lib:Unhook(frame, "SetAlpha", "UpdateFadeFrame")
	frame.SetAlpha = nil

	FadeFrames[frame] = nil
	FadeFrameType[frame] = nil
	FadeFrameHitRects[frame] = nil

	-- Keep empty actionbutton slots
	-- fully transparent if setting implies it.
	if (isEmpty) then
		setAlpha(frame, 0)
	else
		-- Return other frames to full opacity.
		requestAlpha(frame, 1)
	end

	if (not next(FadeFrames)) then
		lib:Disable()
	end

	lib:UpdateFadeFrames()
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
		lib.checkTimer = lib:ScheduleRepeatingTimer("CheckFadeFrames", 0.1)
	end

	lib:CheckFadeFrames()
	lib:UpdateFadeFrames()
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

	lib:UpdateFadeFrames()
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
			lib:UpdateFadeFrames()
		end

		return

	elseif (event == "ACTIONBAR_HIDEGRID") then
		if (lib.gridCounter > 0) then
			lib.gridCounter = lib.gridCounter - 1
		end
		if (lib.gridCounter == 0) then
			lib:UpdateFadeFrames()
		end
		return

	elseif (event == "PET_BAR_SHOWGRID") then
		lib.petGridCounter = lib.petGridCounter + 1

		if (lib.petGridCounter >= 1) then
			lib:UpdateFadeFrames()
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
			lib:UpdateFadeFrames()
		end
		return
	end

	lib:UpdateFadeFrames()
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
