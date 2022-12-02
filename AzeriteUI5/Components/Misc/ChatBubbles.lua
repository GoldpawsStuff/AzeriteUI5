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
local ChatBubbles = ns:NewModule("ChatBubbles", "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0", "AceTimer-3.0")

-- Lua API
local math_floor = math.floor
local next = next
local select = select

-- WoW API
local CreateFrame = CreateFrame
local GetAllChatBubbles = C_ChatBubbles.GetAllChatBubbles
local GetCVarBool = GetCVarBool
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local UnitAffectingCombat = UnitAffectingCombat

-- Addon API
local GetFont = ns.API.GetFont
local SetObjectScale = ns.API.SetObjectScale

-- Create a custom bubble.
ChatBubbles.CreateCustomBubble = function(self, blizzBubble)
	self.numBubbles = self.numBubbles + 1

	local customBubble = CreateFrame("Frame", nil, bubbleParent, ns.BackdropTemplate)
	customBubble:Hide()
	customBubble:SetFrameStrata("BACKGROUND")
	customBubble:SetPoint("BOTTOM", blizzBubble, "BOTTOM", 0, 0)
	customBubble:SetFrameLevel(self.numBubbles%128 + 1) -- try to avoid overlapping bubbles blending into each other
	customBubble:SetBackdrop(self.backdrop)
	customBubble:SetBackdropColor(unpack(self.backdropColor))
	customBubble:SetBackdropBorderColor(unpack(self.backdropBorderColor))

	customBubble.blizzardRegions = {}
	customBubble.blizzardColor = { 1, 1, 1 }
	customBubble.color = { 1, 1, 1 }

	if (customBubble.SetBackdrop) then
		customBubble.blizzardBackdropFrame = customBubble
		customBubble.blizzardBackdrop = customBubble:GetBackdrop()
	end

	customBubble.text = customBubble:CreateFontString()
	customBubble.text:SetPoint("BOTTOMLEFT", self.backdropPadding, self.backdropPadding)
	customBubble.text:SetFontObject(self.fontObject)

	for i = 1, blizzBubble:GetNumRegions() do
		local region = select(i, blizzBubble:GetRegions())
		if (region:GetObjectType() == "Texture") then
			customBubble.blizzardRegions[region] = region:GetTexture()
		elseif (region:GetObjectType() == "FontString") then
			customBubble.blizzardText = region
		end
	end

	if (not customBubble.blizzardText) then
		for i = 1, blizzBubble:GetNumChildren() do
			local child = select(i, select(i, blizzBubble:GetChildren()))
			if (child:GetObjectType() == "Frame") and (child.String) and (child.Center) then
				if (child.SetBackdrop) and (not customBubble.blizzardBackdrop) then
					customBubble.blizzardBackdropFrame = child
					customBubble.blizzardBackdrop = child:GetBackdrop()
				end
				for i = 1, child:GetNumRegions() do
					local region = select(i, child:GetRegions())
					if (region:GetObjectType() == "Texture") then
						customBubble.blizzardRegions[region] = region:GetTexture()
					elseif (region:GetObjectType() == "FontString") then
						customBubble.blizzardText = region
					end
				end
			end
		end
	end

	self.customBubbles[blizzBubble] = customBubble

	-- Don't mess with the blizzardbubbles when cinematics or movies are player,
	-- nor while we're inside a dungeon.
	local _, instanceType = IsInInstance()
	if (instanceType == "none" and not MovieFrame:IsShown() and not CinematicFrame:IsShown() and UIParent:IsShown()) then
		self:HideBlizzardBubble(blizzBubble)
	end

end

-- Show a blizzard chat bubble.
ChatBubbles.ShowBlizzardBubble = function(self, bubble)
	local customBubble = self.customBubbles[bubble]
	if (not customBubble.blizzardHidden) then
		return
	end

	customBubble.blizzardText:SetTextColor(unpack(customBubble.blizzardColor))

	for region,texture in next,customBubble.blizzardRegions do
		region:SetAlpha(1)
	end

	customBubble.blizzardHidden = nil
end

-- Hide a blizzard chat bubble.
ChatBubbles.HideBlizzardBubble = function(self, bubble)
	local customBubble = self.customBubbles[bubble]
	if (customBubble.blizzardHidden) then
		return
	end

	customBubble.blizzardColor[1],
	customBubble.blizzardColor[2],
	customBubble.blizzardColor[3] = customBubble.blizzardText:GetTextColor()
	customBubble.blizzardText:SetAlpha(0)

	for region,texture in next,customBubble.blizzardRegions do
		if (not ns.IsRetail) then
			region:SetTexture(nil)
		end
		region:SetAlpha(0)
	end

	customBubble.blizzardHidden = true
end

-- Update all current custom bubbles.
ChatBubbles.UpdateBubbles = function(self)

	local maxWidth = 400 + ((self.fontSize or 14) - 12)/22 * 260 -- bubble width from 400 to 660ish (font size 22)
	local offsetX, offsetY = 0, -100 -- bubble offset from its original position

	for _,blizzBubble in next,GetAllChatBubbles(false) do

		local customBubble = self.customBubbles[blizzBubble]

		if (not customBubble) then
			self:CreateCustomBubble(blizzBubble)
			customBubble = self.customBubbles[blizzBubble]
		end


		if (blizzBubble:IsShown()) then

			local msg = customBubble.blizzardText:GetText()
			if (msg) then

				local text = customBubble.text

				customBubble:SetFrameLevel(blizzBubble:GetFrameLevel())
				if (not customBubble:IsShown()) then
					customBubble:Show()
				end

				if (msg and customBubble.last ~= msg) then
					customBubble.last = msg

					local color = customBubble.color
					color[1], color[2], color[3] = customBubble.blizzardText:GetTextColor()

					text:SetText(msg or "")
					text:SetTextColor(color[1], color[2], color[3])

					local rawWidth = text:GetStringWidth()
					text:SetWidth(rawWidth > maxWidth and maxWidth or rawWidth)
				end

				customBubble:SetSize(text:GetWidth() + self.backdropPadding*2, text:GetHeight() + self.backdropPadding*2)

			else
				if (customBubble:IsShown()) then
					customBubble:Hide()
				else
					customBubble.last = nil
				end
			end

			customBubble.blizzardText:SetAlpha(0)

		else

			if (customBubble:IsShown()) then
				customBubble:Hide()
			else
				customBubble.last = nil
			end
		end

	end

	for blizzBubble,customBubble in next,self.customBubbles do
		if (not blizzBubble:IsShown() and customBubble:IsShown()) then
			customBubble:Hide()
			customBubble.last = nil
		end
	end
end

-- Update all custom bubble fonts.
ChatBubbles.UpdateBubbleFont = function(self)
	local fontSize = select(2, ChatFrame1:GetFont())
	if (fontSize) then
		local ourscale = self.bubbleParent:GetEffectiveScale()
		local chatscale = ChatFrame1:GetEffectiveScale()
		fontSize = math_floor(fontSize * (ourscale / chatscale) + .5)
	else
		fontSize = self.fontSizeDefault
	end

	if (fontSize > self.fontSizeMax) then
		fontSize = self.fontSizeMax
	elseif (fontSize < self.fontSizeMin) then
		fontSize = self.fontSizeMin
	end

	if (fontSize and fontSize ~= self.fontSize) then
		self.fontsize = fontSize
		self.fontObject = GetFont(fontSize, true, "Chat")

		for blizzBubble,customBubble in next,self.customBubbles do
			customBubble.text:SetFontObject(self.fontObject)
		end
	end

end

ChatBubbles.UpdateChatWindowFontSize = function(self, _, chatFrame, fontSize)
	if (not chatFrame or chatFrame == ChatFrame1) then
		self:UpdateBubbleFont()
	end
end

-- Update all bubble visibility according to settings.
ChatBubbles.UpdateVisibility = function(self)

	-- Seems to be some taint when CinematicFrame is shown, in here?
	-- Add an extra layer of combat protection here,
	-- in case we got here abruptly by a started cinematic.
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	local _, instanceType = IsInInstance()
	if (instanceType == "none" and not MovieFrame:IsShown() and not CinematicFrame:IsShown() and UIParent:IsShown()) then

		if (not self.bubbleTimer) then
			self.bubbleTimer = self:ScheduleRepeatingTimer("UpdateBubbles", 1/60)
		end

		self.bubbleParent:Show()

		for blizzBubble in next,self.customBubbles do
			self:HideBlizzardBubble(blizzBubble)
		end

	else

		if (self.bubbleTimer) then
			self:CancelTimer(self.bubbleTimer)
		end

		self.bubbleParent:Hide()

		for blizzBubble,customBubble in next,self.customBubbles do
			self:ShowBlizzardBubble(blizzBubble)
		end

	end
end

ChatBubbles.UpdateSettings = function(self)
	if (InCombatLockdown()) then return end

	local db = ns.db.global.chatbubbles

	self.showInWorld = db.visibility.world
	self.showInWorldInCombat = db.visibility.worldcombat
	self.showInInstances = db.visibility.instance
	self.showInInstancesInCombat = db.visibility.instancecombat

	if (db.enableChatBubbles) then
		if (self.stylingEnabled) then
			self:UpdateConsoleVars()
		else
			self:EnableBubbleStyling()
		end
	elseif (not db.enableChatBubbles and self.stylingEnabled) then
		self:DisableBubbleStyling()
	end

end

-- Enable custom bubble styling
ChatBubbles.EnableBubbleStyling = function(self)
	if (self.stylingEnabled or InCombatLockdown()) then return end

	self.stylingEnabled = true

	if (not self.bubbleParent) then
		self.bubbleParent = SetObjectScale(CreateFrame("Frame", nil, UIParent))
	end

	self:UpdateBubbleFont()
	self:UpdateVisibility()

	self:SecureHook("FCF_SetChatWindowFontSize", "UpdateChatWindowFontSize")
	self:SecureHook(ChatFrame1, "SetFont", "UpdateBubbleFont")
	self:SecureHookScript(UIParent, "OnHide", "UpdateVisibility")
	self:SecureHookScript(UIParent, "OnShow", "UpdateVisibility")
	self:SecureHookScript(CinematicFrame, "OnHide", "UpdateVisibility")
	self:SecureHookScript(CinematicFrame, "OnShow", "UpdateVisibility")
	self:SecureHookScript(MovieFrame, "OnHide", "UpdateVisibility")
	self:SecureHookScript(MovieFrame, "OnShow", "UpdateVisibility")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "OnEvent")
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")

	self:OnEvent("PLAYER_ENTERING_WORLD")
end

-- Disable custom bubble styling
ChatBubbles.DisableBubbleStyling = function(self)
	if (not self.stylingEnabled or InCombatLockdown()) then return end

	self.stylingEnabled = nil

	if (self.bubbleTimer) then
		self:CancelTimer(self.bubbleTimer)
	end

	self.bubbleParent:Hide()

	self:UnHook("FCF_SetChatWindowFontSize")
	self:UnHook(ChatFrame1, "SetFont")
	self:Unhook(UIParent, "OnHide")
	self:Unhook(UIParent, "OnShow")
	self:Unhook(CinematicFrame, "OnHide")
	self:Unhook(CinematicFrame, "OnShow")
	self:Unhook(MovieFrame, "OnHide")
	self:Unhook(MovieFrame, "OnShow")

	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("UPDATE_CHAT_WINDOWS", "OnEvent")
	self:UnregisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "OnEvent")
	self:UnregisterEvent("VARIABLES_LOADED", "OnEvent")

end

ChatBubbles.EnableBubbles = function(self)
	ns.db.global.chatbubbles.enableChatBubbles = true
	self:UpdateSettings()
end

ChatBubbles.DisableBubbles = function(self)
	ns.db.global.chatbubbles.enableChatBubbles = false
	self:UpdateSettings()
end

ChatBubbles.UpdateConsoleVars = function(self)
	if (InCombatLockdown()) then return end

	local bubblesShouldShow
	local bubblesShown = GetCVarBool("chatBubbles")
	local _, instanceType = IsInInstance()

	if (instanceType == "none" and self.showInWorld) then
		bubblesShouldShow = self.showInWorldInCombat or not UnitAffectingCombat("player")
	elseif (instanceType ~= "none" and self.showInInstances) then
		bubblesShouldShow = self.showInInstancesInCombat or not UnitAffectingCombat("player")
	end

	if (bubblesShouldShow and not bubblesShown) then
		SetCVar("chatBubbles", 1)
	elseif (not bubblesShouldShow and bubblesShown) then
		SetCVar("chatBubbles", 0)
	end
end

ChatBubbles.OnEvent = function(self, event, ...)
	if (event == "UPDATE_CHAT_WINDOWS" or event == "UPDATE_FLOATING_CHAT_WINDOWS") then
		self:UpdateBubbleFont()
	else
		self:UpdateConsoleVars()
		self:UpdateVisibility()
	end
end

ChatBubbles.OnInitialize = function(self)

	self.customBubbles = {}
	self.numBubbles = 0
	self.fontSizeMin = 12
	self.fontSizeMax = 22
	self.fontSizeDefault = 14
	self.fontSize = select(2, ChatFrame1:GetFont()) or self.fontSizeDefault

	self.backdrop = {
		bgFile = [[Interface\Tooltips\CHATBUBBLE-BACKGROUND]],
		edgeFile = [[Interface\Tooltips\CHATBUBBLE-BACKDROP]],
		edgeSize = 12,
		insets = {
			left = 12,
			right = 12,
			top = 12,
			bottom = 12
		}
	}
	self.backdropColor = { 0, 0, 0, .5 }
	self.backdropBorderColor = { 0, 0, 0, .5 }
	self.backdropPadding = 12

	self:RegisterChatCommand("enablebubbles", "EnableBubbles")
	self:RegisterChatCommand("disablebubbles", "DisableBubbles")

end

ChatBubbles.OnEnable = function(self)
	self:UpdateSettings()
end
