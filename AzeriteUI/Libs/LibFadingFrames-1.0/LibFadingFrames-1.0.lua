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
local MINOR_VERSION = 22

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
lib.fadeFrames = lib.fadeFrames or {} -- lib.fadeFrames[frame] = fadeGroup
lib.fadeFrameType = lib.fadeFrameType or {} -- lib.fadeFrameType[frame] = "type" (e.g "actionbutton")
lib.fadeFrameCurrentAlpha = lib.fadeFrameCurrentAlpha or {} -- lib.fadeFrameCurrentAlpha[frame] = alpha
lib.fadeFrameTargetAlpha = lib.fadeFrameTargetAlpha or {} -- lib.fadeFrameTargetAlpha[frame] = alpha
lib.fadeFrameHitRects = lib.fadeFrameHitRects or {}
lib.hoverFrames = lib.hoverFrames or {}
lib.hoverCount = lib.hoverCount or { default = 0 }
lib.gridCounter = lib.gridCounter or 0
lib.petGridCounter = lib.petGridCounter or 0
lib.cache = lib.cache or { methods = {}, scrips = {} }
lib.embeds = lib.embeds or {}

-- GLOBALS: CreateFrame, IsPlayerInWorld, LAB10GEFlyoutHandlerFrame, SpellFlyout

-- Lua API
local getmetatable = getmetatable
local math_floor = math.floor
local next = next
local pairs = pairs
local select = select
local unpack = unpack

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoW10 = select(4, GetBuildInfo()) >= 100000

local fadeThrottle = .02
local fadeInDuration = .1
local fadeOutDuration = .35
local fadeHoldDuration = 0

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha
local getAlpha = getmetatable(CreateFrame("Frame")).__index.GetAlpha

-- Alpha getter fixing the inconsistent blizzard return values
local getCurrentAlpha = function(frame)
	return lib.fadeFrameCurrentAlpha[frame] or math_floor((getAlpha(frame) * 100) + .5) / 100
end

-- Alpha setter that also stores the alpha in our local registry
local setCurrentAlpha = function(frame, alpha)
	setAlpha(frame, alpha)
	lib.fadeFrameCurrentAlpha[frame] = alpha
end

local requestAlpha = function(frame, targetAlpha)
	-- Always do this, even if alpha goal is reached.
	-- There's a minor bug in blizzard's frame alpha code where upon showing
	-- a frame its children can be rendered fully visible even if their alpha is set to zero.
	-- Adding an extra check on the next frame update will
	-- update the alpha correctly after the parent has changed its.
	if (not next(lib.fadeFrameTargetAlpha)) then
		if (not lib.fadeTimer) then
			lib.fadeTimer = lib:ScheduleRepeatingTimer("UpdateCurrentlyFadingFrames", fadeThrottle)
		end
	end
	lib.fadeFrameTargetAlpha[frame] = targetAlpha
end

-- Our fade frame unregistration sets alpha back to full opacity,
-- this conflicts with how actionbuttons work so we're faking events to fix it.
local updateLAB = function()
	local LAB = LibStub("LibActionButton-1.0-GE", true)
	local OnEvent = LAB and LAB.eventFrame:GetScript("OnEvent")
	if (OnEvent) then
		OnEvent(LAB, "ACTIONBAR_SHOWGRID")
		OnEvent(LAB, "ACTIONBAR_HIDEGRID")
	end
end

lib.UpdateCurrentlyFadingFrames = function(self)

	for frame,targetAlpha in next,self.fadeFrameTargetAlpha do
		local currentAlpha = getCurrentAlpha(frame)

		-- If we're fading out
		if (currentAlpha > targetAlpha) then

			-- Is there room to change the alpha?
			if (currentAlpha - fadeThrottle/fadeOutDuration > targetAlpha) then
				setCurrentAlpha(frame, currentAlpha - fadeThrottle/fadeOutDuration)
			else

				-- The fade is finished.
				setCurrentAlpha(frame, targetAlpha)
				self.fadeFrameTargetAlpha[frame] = nil

				if (self.fadeFrameType[frame] == "actionbutton") then
					frame:UpdateConfig(frame.config)
					updateLAB()
				end

			end

		-- If we're fading in
		elseif (currentAlpha < targetAlpha) then

			-- Is there room to change the alpha?
			if (currentAlpha + fadeThrottle/fadeInDuration < targetAlpha) then
				setCurrentAlpha(frame, currentAlpha + fadeThrottle/fadeInDuration)
			else

				-- The fade is finished.
				setCurrentAlpha(frame, targetAlpha)
				self.fadeFrameTargetAlpha[frame] = nil

				if (self.fadeFrameType[frame] == "actionbutton") then
					frame:UpdateConfig(frame.config)
					updateLAB()
				end

			end
		else

			setCurrentAlpha(frame, targetAlpha)
			self.fadeFrameTargetAlpha[frame] = nil

			if (self.fadeFrameType[frame] == "actionbutton") then
				frame:UpdateConfig(frame.config)
				updateLAB()
			end

		end

	end

	-- Kill off this timer if nothing is still fading.
	if (not next(self.fadeFrameTargetAlpha)) then
		if (self.fadeTimer) then
			self:CancelTimer(self.fadeTimer)
			self.fadeTimer = nil
		end
	end
end

lib.UpdateFadeFrame = function(self, frame)

	local isActionButton = self.fadeFrameType[frame] == "actionbutton"
	local isPetButton = isActionButton and frame.GetAttribute and frame:GetAttribute("type") == "pet"

	if (isPetButton) then
		if (self.inCombat and not (frame.header and frame.header.config and frame.header.config.fadeInCombat) and frame:GetTexture()) or (self.petGridCounter > 0 and not frame.ignoreGridCounterOnHover and (self.cursorType == "petaction")) then
			requestAlpha(frame, 1)
			return
		end

	elseif (isActionButton) then
		if (self.flyoutShown) or (self.inCombat and not (frame.header and frame.header.config and frame.header.config.fadeInCombat) and frame:GetTexture()) or (self.gridCounter > 0 and not frame.ignoreGridCounterOnHover and (self.cursorType ~= "petaction" or isRetail)) then
			requestAlpha(frame, 1)
			return
		end
	end

	if (not self.enableFading) then
		if (isActionButton) then
			-- The frame has an action or grid set to visible.
			if (frame:GetTexture()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
				requestAlpha(frame, 1)
			else
				requestAlpha(frame, 0)
			end
		else
			requestAlpha(frame, 1)
		end
	else
		-- The group is visible.
		if (self.hoverCount[self.fadeFrames[frame]] > 0) then
			if (isActionButton) then
				-- The frame has an action or grid set to visible.
				if (frame:GetTexture()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
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

lib.UpdateFadeFrames = function(self)
	if (not self.inWorld) then return end
	self.cursorType = GetCursorInfo()
	for frame in next,self.fadeFrames do
		self:UpdateFadeFrame(frame)
	end
end

lib.OnFadeFrameEnter = function(self, frame, fadeGroup)
	if (self.hoverFrames[frame]) then return end
	self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] + 1
	self.hoverFrames[frame] = fadeGroup
end

lib.OnFadeFrameLeave = function(self, frame, fadeGroup)
	if (not self.hoverFrames[frame]) then return end
	self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] - 1
	self.hoverFrames[frame] = nil
end

lib.CheckFadeFrames = function(self)
	local needupdate
	for frame,fadeGroup in next,self.hoverFrames do
		-- Frame could've been unregistered while hovered.
		if (not self.fadeFrames[frame] or not frame:IsMouseOver(unpack(lib.fadeFrameHitRects[frame]))) then
			self:OnFadeFrameLeave(frame, fadeGroup)
			needupdate = true
		end
	end
	for frame,fadeGroup in next,self.fadeFrames do
		if (not self.hoverFrames[frame] and frame:IsVisible() and frame:IsMouseOver(unpack(lib.fadeFrameHitRects[frame]))) then
			self:OnFadeFrameEnter(frame, fadeGroup)
			needupdate = true
		end
	end
	if (needupdate) then
		self:UpdateFadeFrames()
	end
end

lib.UpdateFlyout = function(self)
	if (not self.flyoutHandler) then return end
	self.flyoutShown = self.flyoutHandler:IsShown()
	self:UpdateFadeFrames()
end

lib.RegisterFrameForFading = function(self, frame, fadeGroup, ...)
	if (lib.fadeFrames[frame]) then
		return
	end

	local shouldInit = not next(lib.fadeFrames)

	fadeGroup = fadeGroup or "default"

	-- Not the best check ever, but it'll have to do for now.
	if (frame:GetObjectType() == "CheckButton") and (frame.HasAction) then
		lib.fadeFrameType[frame] = "actionbutton"

		-- Keep track of the flyout handlers.
		if (not self.flyoutHandler) then
			local flyoutHandler = WoW10 and LAB10GEFlyoutHandlerFrame or SpellFlyout
			if (flyoutHandler) then
				self:HookScript(flyoutHandler, "OnShow", "UpdateFlyout")
				self:HookScript(flyoutHandler, "OnHide", "UpdateFlyout")

				self.flyoutHandler = flyoutHandler
			end
		end

	end

	-- Might be spammy, but I prefer not to replace frame methods.
	--lib:SecureHook(frame, "SetAlpha", "UpdateFadeFrame")
	frame.SetAlpha = function() end

	if (not lib.hoverCount[fadeGroup]) then
		lib.hoverCount[fadeGroup] = 0
	end

	lib.fadeFrames[frame] = fadeGroup

	-- Convert frame hit rects to mouseover values.
	if (...) then
		local left, right, top, bottom = ...
		lib.fadeFrameHitRects[frame] = { -top, bottom, left, -right }
	else
		lib.fadeFrameHitRects[frame] = { 0, 0, 0, 0 }
	end

	if (shouldInit) then
		lib:Enable()
	end

	lib:UpdateFadeFrames()
end

lib.UnregisterFrameForFading = function(self, frame, noAlphaChange)
	if (not lib.fadeFrames[frame]) then
		if (not noAlphaChange) then
			if (lib.fadeFrameType[frame] == "actionbutton") then
				frame:UpdateConfig(frame.config)
				updateLAB()
			else
				requestAlpha(frame, 1)
			end
		elseif (lib.fadeFrameType[frame] == "actionbutton") then
			frame:UpdateConfig(frame.config)
			updateLAB()
		end
		return
	end

	--lib:Unhook(frame, "SetAlpha", "UpdateFadeFrame")
	frame.SetAlpha = nil

	lib.fadeFrames[frame] = nil
	lib.fadeFrameType[frame] = nil
	lib.fadeFrameHitRects[frame] = nil

	if (not noAlphaChange) then
		if (lib.fadeFrameType[frame] == "actionbutton") then
			frame:UpdateConfig(frame.config)
			updateLAB()
		else
			requestAlpha(frame, 1)
		end
	elseif (lib.fadeFrameType[frame] == "actionbutton") then
		frame:UpdateConfig(frame.config)
		updateLAB()
	end

	if (not next(lib.fadeFrames)) then
		lib:Disable()
	end

	lib:UpdateFadeFrames()
end

lib.Enable = function(self)
	if (self.enableFading) then return end

	self.enableFading = true

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")
	self:RegisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("PET_BAR_HIDEGRID", "OnEvent")

	if (IsPlayerInWorld()) then
		self:OnEvent("PLAYER_ENTERING_WORLD")
	end

	if (not self.checkTimer) then
		self.checkTimer = self:ScheduleRepeatingTimer("CheckFadeFrames", 0.1)
	end

	self:CheckFadeFrames()
	self:UpdateFadeFrames()
end

lib.Disable = function(self)
	if (not self.enableFading) then return end

	self.enableFading = false

	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")
	self:UnregisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	self:UnregisterEvent("PET_BAR_HIDEGRID", "OnEvent")

	if (self.checkTimer) then
		self:CancelTimer(self.checkTimer)
		self.checkTimer = nil
	end

	self:UpdateFadeFrames()
end

lib.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.inWorld = true
		self.inCombat = nil

		for fadeGroup in next,self.hoverCount do
			self.hoverCount[fadeGroup] = 0
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

	elseif (event == "CURSOR_CHANGED") then
		self.cursorType = GetCursorInfo()

	elseif (event == "ACTIONBAR_SHOWGRID") then
		self.gridCounter = self.gridCounter + 1
		if (self.gridCounter >= 1) then
			self:UpdateFadeFrames()
		end
		return

	elseif (event == "ACTIONBAR_HIDEGRID") then
		if (self.gridCounter > 0) then
			self.gridCounter = self.gridCounter - 1
		end
		if (self.gridCounter == 0) then
			self:UpdateFadeFrames()
		end
		return

	elseif (event == "PET_BAR_SHOWGRID") then
		self.petGridCounter = self.petGridCounter + 1
		if (self.petGridCounter >= 1) then
			self:UpdateFadeFrames()
		end
		return

	elseif (event == "PET_BAR_HIDEGRID") then
		if (self.petGridCounter > 0) then
			self.petGridCounter = self.petGridCounter - 1
		end
		if (isClassic and self.gridCounter > 0) then
			self.gridCounter = self.gridCounter - 1
		end
		if (self.petGridCounter == 0 or (isClassic and self.gridCounter == 0)) then
			self:UpdateFadeFrames()
		end
		return
	end
	self:UpdateFadeFrames()
end

local mixins = {
	RegisterFrameForFading = true,
	UnregisterFrameForFading = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
