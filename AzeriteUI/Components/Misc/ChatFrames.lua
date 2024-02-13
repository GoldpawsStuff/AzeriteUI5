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
local _, ns = ...

if (ns.API.IsAddOnEnabled("Prat-3.0") or ns.API.IsAddOnEnabled("ls_Glass")) then return end

local ChatFrames = ns:NewModule("ChatFrames", "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0", "AceTimer-3.0")

-- Lua API
local ipairs = ipairs
local next = next
local pairs = pairs
local rawget = rawget
local rawset = rawset
local select = select
local setmetatable = setmetatable
local string_format = string.format

-- GLOBALS: ChatFrame1, ChatFrame2
-- GLOBALS: CHAT_FRAMES, CHAT_FONT_HEIGHTS, NUM_CHAT_WINDOWS
-- GLOBALS: CreateFrame, FCF_GetCurrentChatFrame, FCF_GetChatWindowInfo
-- GLOBALS: QuickJoinToastButton, CombatLogQuickButtonFrame_Custom

-- Addon API
local GetFont = ns.API.GetFont
local UIHider = ns.Hider

local defaults = { profile = ns:Merge({
	enabled = true,
	fadeOnInActivity = true, -- blizz default is true
	timeVisible = 20, -- 120, -- blizz default is 120
	timeFading = 3
}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
ChatFrames.GenerateDefaults = function(self)
	return defaults
end

-- Global buttons not unique to any frame
local GLOBAL_BUTTONS = {
	"ChatFrameMenuButton",
	"ChatFrameChannelButton",
	"ChatFrameToggleVoiceDeafenButton",
	"ChatFrameToggleVoiceMuteButton",
	"ChatMenu"
}

-- ChatFrame Texture Suffixes
local TEXTURES = {
	Frame = {
		"Background",
		"TopLeftTexture", "TopRightTexture",
		"BottomLeftTexture", "BottomRightTexture",
		"LeftTexture", "RightTexture",
		"BottomTexture", "TopTexture"
	},
	ButtonFrame = {
		"Background",
		"TopLeftTexture", "TopRightTexture",
		"BottomLeftTexture", "BottomRightTexture",
		"LeftTexture", "RightTexture",
		"BottomTexture", "TopTexture"
	},
	EditBox = {
		"Left", "Mid", "Right",
		"FocusLeft", "FocusMid", "FocusRight",
		"ConversationIcon"
	},
	Tab = {
		"Left", "Middle", "Right",
		"SelectedLeft", "SelectedMiddle", "SelectedRight",
		"HighlightLeft", "HighlightMiddle", "HighlightRight",
		"ActiveLeft", "ActiveMiddle", "ActiveRight" -- 10.0
	}
}

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha
local getAlpha = getmetatable(CreateFrame("Frame")).__index.GetAlpha

-- Local element cache for lookups without member properties
local Elements = setmetatable({}, { __index = function(t,k) rawset(t,k,{}) return rawget(t,k) end })

local Tab_PostEnter = function(tab)
	local frame = _G["ChatFrame"..tab:GetID()]
	Elements[frame].isMouseOverTab = true
end

local Tab_PostLeave = function(tab)
	local frame = _G["ChatFrame"..tab:GetID()]
	Elements[frame].isMouseOverTab = false
end

-------------------------------------------------------
-- Custom ChatFrame API
-------------------------------------------------------
local ChatFrame = {}

-- Getters
-------------------------------------------------------
ChatFrame.GetEditBox = function(self)
	if (not Elements[self].editBox) then
		Elements[self].editBox = _G[self:GetName().."EditBox"]
	end
	return Elements[self].editBox
end

ChatFrame.GetButtonFrame = function(self)
	if (not Elements[self].buttonFrame) then
		Elements[self].buttonFrame = _G[self:GetName().."ButtonFrame"]
	end
	return Elements[self].buttonFrame
end

ChatFrame.GetMinimizeButton = function(self)
	if (not Elements[self].minimizeButton) then
		Elements[self].minimizeButton = _G[self:GetName().."ButtonFrameMinimizeButton"]
	end
	return Elements[self].minimizeButton
end

ChatFrame.GetUpButton = function(self)
	if (not Elements[self].upButton) then
		Elements[self].upButton = _G[self:GetName().."ButtonFrameUpButton"]
	end
	return Elements[self].upButton
end

ChatFrame.GetDownButton = function(self)
	if (not Elements[self].downButton) then
		Elements[self].downButton = _G[self:GetName().."ButtonFrameDownButton"]
	end
	return Elements[self].downButton
end

ChatFrame.GetToBottomButton = function(self)
	if (not Elements[self].scrollToBottomButton) then
		Elements[self].scrollToBottomButton = _G[self:GetName().."ButtonFrameBottomButton"] or self.ScrollToBottomButton
	end
	return Elements[self].scrollToBottomButton
end

ChatFrame.GetScrollBar = function(self)
	if (not Elements[self].scrollBar) then
		Elements[self].scrollBar = self.ScrollBar
	end
	return Elements[self].scrollBar
end

ChatFrame.GetScrollBarThumbTexture = function(self)
	if (not Elements[self].scrollBarThumbTexture) then
		Elements[self].scrollBarThumbTexture = self.ScrollBar and self.ScrollBar.ThumbTexture
	end
	return Elements[self].scrollBarThumbTexture
end

ChatFrame.GetTab = function(self)
	if (not Elements[self].tab) then
		Elements[self].tab = self.tab or _G[self:GetName() .. "Tab"]
	end
	return Elements[self].tab
end

ChatFrame.GetTabIcon = function(self)
	if (not Elements[self].tabIcon) then
		Elements[self].tabIcon = _G[self:GetName().."TabConversationIcon"]
	end
	return Elements[self].tabIcon
end

ChatFrame.GetTabText = function(self)
	if (not Elements[self].tabText) then
		Elements[self].tabText = _G[self:GetName().."TabText"] or _G[self:GetName().."Tab"].Text -- 10.0.0
	end
	return Elements[self].tabText
end

-- Iterators
-------------------------------------------------------
-- Returns an iterator for the chatframe textures
ChatFrame.GetFrameTextures = function(self)
	local counter = 0
	local numEntries = #TEXTURES.Frame
	local name = self:GetName()
	return function()
		local tex
		while (numEntries > counter) do
			counter = counter + 1
			tex = _G[name..TEXTURES.Frame[counter]]
			if (tex) then
				break
			end
		end
		if (counter <= numEntries) then
			return tex
		end
	end
end

-- Returns an iterator for the buttonframe textures
ChatFrame.GetButtonFrameTextures = function(self)
	local buttonFrame = ChatFrame.GetButtonFrame(self)
	if (buttonFrame) then
		local counter = 0
		local numEntries = #TEXTURES.ButtonFrame
		local name = buttonFrame:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.ButtonFrame[counter]]
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Returns an iterator for the editbox textures
ChatFrame.GetEditBoxTextures = function(self)
	local editBox = ChatFrame.GetEditBox(self)
	if (editBox) then
		local counter = 0
		local numEntries = #TEXTURES.EditBox
		local name = editBox:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.EditBox[counter]]
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Returns an iterator for the tab textures
ChatFrame.GetTabTextures = function(self)
	local tab = ChatFrame.GetTab(self)
	if (tab) then
		local counter = 0
		local numEntries = #TEXTURES.Tab
		local name = tab:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.Tab[counter]] or tab[TEXTURES.Tab[counter]] -- 10.0
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Module API
-------------------------------------------------------
ChatFrames.StyleFrame = function(self, frame)
	if (frame.isSkinned) then return end

	if (frame:GetID() == 2) then
		local buttonframe = CombatLogQuickButtonFrame_Custom
		for i = 1, buttonframe:GetNumRegions() do
			local region = select(i, buttonframe:GetRegions())
			if (region and region:GetObjectType() == "Texture") then
				region:SetTexture(nil)
			end
		end
	end

	for tex in ChatFrame.GetFrameTextures(frame) do
		tex:SetTexture(nil)
		tex:SetAlpha(0)
	end

	for tex in ChatFrame.GetButtonFrameTextures(frame) do
		tex:SetTexture(nil)
		tex:SetAlpha(0)
	end

	local tab = ChatFrame.GetTab(frame)
	local fontObject = GetFont(15,true,"Chat")

	tab:SetNormalFontObject(fontObject)

	for tex in ChatFrame.GetTabTextures(frame) do
		tex:SetTexture(nil)
		tex:SetAlpha(0)
	end

	local tabText = ChatFrame.GetTabText(frame)
	tabText:Hide()
	tabText:SetAlpha(.5)
	tabText:SetFontObject(fontObject)

	local tabIcon = ChatFrame.GetTabIcon(frame)
	if (tabIcon) then
		tabIcon:Hide()
	end

	tab:HookScript("OnEnter", Tab_PostEnter)
	tab:HookScript("OnLeave", Tab_PostLeave)

	local editBox = ChatFrame.GetEditBox(frame)
	for tex in ChatFrame.GetEditBoxTextures(frame) do
		tex:SetTexture(nil)
		tex:SetAlpha(0)
	end
	editBox:Hide()
	editBox:SetAltArrowKeyMode(false)
	editBox:SetHeight(45)
	editBox:ClearAllPoints()
	editBox:SetPoint("LEFT", frame, "LEFT", -15, 0)
	editBox:SetPoint("RIGHT", frame, "RIGHT", 15, 0)
	editBox:SetPoint("TOP", frame, "BOTTOM", 0, -1)

	self:UpdateChatFont(frame)
	self:UpdateChatFading(frame)
	self:SecureHook(frame, "SetFont", "UpdateChatFont")

	-- Attempt to fix coins and chat textures not fading by double setting the alpha.
	-- The bug seems to go away when the textures once have been set to zero alpha.
	--hooksecurefunc(UIParent, "SetAlpha", function()
	--	local alpha = UIParent:GetAlpha()
	--	if (alpha < .5) then
	--		setAlpha(frame, 0)
	--	else
	--		setAlpha(frame, alpha)
	--	end
	--end)

	local fixAlpha = function()
		if (frame.alphaTimer) then
			frame.alphaTimer:Cancel()
		end
		local alpha = getAlpha(frame)
		setAlpha(frame, 0)
		setAlpha(frame, 1)
		setAlpha(frame, alpha)
	end

	-- Overkill experiment to see if we can force the opacity
	-- of chat textures to be updated right from the start.
	-- *the bug re-occur on scrolling, as the textures are redrawn.
	local origAddMessage = frame.AddMessage
	frame.AddMessage = function(chatFrame, msg, r, g, b, chatID, ...)

		-- call this first, otherwise the alpha changes are meaningless.
		origAddMessage(chatFrame, msg, r, g, b, chatID, ...)
		fixAlpha() -- call the fix the first time
		-- schedule a timer on the next frame update
		if (not chatFrame.alphaTimer) then
			chatFrame.alphaTimer = C_Timer.After(0, fixAlpha)
		end
	end

	frame.isSkinned = true
end

ChatFrames.StyleTempFrame = function(self)
	local frame = FCF_GetCurrentChatFrame()
	if (not frame or frame.isSkinned) then return end
	self:StyleFrame(frame)
end

ChatFrames.UpdateTabAlpha = function(self, frame)
	if (not frame.GetTab) then return end -- can fire for more frames than ours
	local tab = ChatFrame.GetTab(frame)
	if (tab.noMouseAlpha == .4 or tab.noMouseAlpha == .2) then
		tab:SetAlpha(0)
		tab.noMouseAlpha = 0
	end
end

ChatFrames.UpdateChatFading = function(self, frame)
	if (not frame) then return end

	frame:SetFading(self.db.profile.fadeOnInActivity)
	frame:SetFadeDuration(self.db.profile.timeFading)
	frame:SetTimeVisible(self.db.profile.timeVisible)
end

ChatFrames.UpdateChatFont = function(self, frame)
	if (not frame) then return end
	local font,_,style = GetFont(14,true,"Chat"):GetFont()
	local currentFont, currentSize, currentStyle = frame:GetFont()
	if (font == currentFont and style == currentStyle) then
		return
	end
	frame:SetFont(font, currentSize, style)
end

ChatFrames.UpdateDockedChatTabs = function(self)
	local frame = ChatFrame1
	if (frame:IsMouseOver(30,0,-30,30)) then
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame) then
				local _, _, _, _, _, _, shown, _, docked = FCF_GetChatWindowInfo(frame:GetID())
				if (docked and not frame.minimized) then
					local tabText = ChatFrame.GetTabText(frame)
					if (tabText) then
						tabText:Show()
						if (shown) then
							tabText:SetAlpha(.9)
						else
							tabText:SetAlpha(.5)
						end
					end
				end
			end
		end

	else
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame) then
				local _, _, _, _, _, _, _, _, docked = FCF_GetChatWindowInfo(frame:GetID())
				if (docked and not frame.minimized) then
					local tabText = ChatFrame.GetTabText(frame)
					if (tabText) then tabText:Hide() end
				end
			end
		end

	end
end

ChatFrames.UpdateButtons = function(self, event, ...)

	local atDock
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then
			local _, _, _, _, _, _, shown, _, docked = FCF_GetChatWindowInfo(frame:GetID())
			local isMouseOver

			if (frame == ChatFrame2) then
				isMouseOver = frame:IsMouseOver(60,0,-30,30)
			else
				isMouseOver = frame:IsMouseOver(30,0,-30,30)
			end

			local buttonFrame = ChatFrame.GetButtonFrame(frame)
			local up = ChatFrame.GetUpButton(frame)
			local down = ChatFrame.GetDownButton(frame)
			local bottom = ChatFrame.GetToBottomButton(frame)
			local scrollBar = ChatFrame.GetScrollBar(frame)

			-- Blizzard script uses GetParent and we change the parent.
			if (bottom and not bottom.hasFixedScript) then
				bottom:SetScript("OnClick", function(self)
					PlaySound(SOUNDKIT.IG_CHAT_BOTTOM)
					frame:ScrollToBottom()
				end)
				bottom.hasFixedScript = true
			end

			if (isMouseOver) and (shown and shown ~= 0) and (not frame.minimized) then
				if (docked or frame == ChatFrame1) then -- dock position or nil
					atDock = true
				end

				if (not Elements[frame].isMouseOver) then

					if (up) then up:SetParent(buttonFrame) end
					if (down) then down:SetParent(buttonFrame) end
					if (bottom) then bottom:SetParent(buttonFrame) end
					if (scrollBar) then scrollBar:SetParent(buttonFrame); scrollBar:Update() end

					local tabText = ChatFrame.GetTabText(frame)
					tabText:Show()

					if (ChatFrame.GetTab(frame):IsMouseOver()) then
						tabText:SetAlpha(.9)
					else
						tabText:SetAlpha(.5)
					end

					Elements[frame].isMouseOver = true
				end
			else
				-- Todo: check out what happens when minimized.
				if (event == "PLAYER_ENTERING_WORLD") or (Elements[frame].isMouseOver) then

					local up = ChatFrame.GetUpButton(frame)
					local down = ChatFrame.GetDownButton(frame)
					local bottom = ChatFrame.GetToBottomButton(frame)
					local scrollBar = ChatFrame.GetScrollBar(frame)

					if (up) then up:SetParent(UIHider) end
					if (down) then down:SetParent(UIHider) end
					if (bottom) then bottom:SetParent(UIHider) end
					if (scrollBar) then scrollBar:SetParent(UIHider) end

					ChatFrame.GetTabText(frame):Hide()

					Elements[frame].isMouseOver = false
				end
			end
		end
	end

	if (atDock) then
		for button in self:GetGlobalButtons() do
			button:SetAlpha(1)
		end
	else
		for button in self:GetGlobalButtons() do
			button:SetAlpha(0)
		end
	end

end

ChatFrames.UpdateClutter = function(self, event, ...)
	self:UpdateDockedChatTabs()
	self:UpdateButtons(event, ...)
end

ChatFrames.UpdateSettings = function(self)
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then
			self:UpdateChatFading(frame)
		end
	end
end

-- Returns an iterator for the global buttons
ChatFrames.GetGlobalButtons = function(self)
	local counter = 0
	local numEntries = #GLOBAL_BUTTONS
	return function()
		local button
		while (numEntries > counter) do
			counter = counter + 1
			button = _G[GLOBAL_BUTTONS[counter]]
			if (button) then
				break
			end
		end
		if (counter <= numEntries) then
			return button
		end
	end
end

ChatFrames.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

			for i = 1, NUM_CHAT_WINDOWS do
				local frame = _G["ChatFrame"..i]
				if (i == 2) then
					local buttonframe = CombatLogQuickButtonFrame_Custom
					for i = 1, buttonframe:GetNumRegions() do
						local region = select(i, buttonframe:GetRegions())
						if (region and region:GetObjectType() == "Texture") then
							region:SetTexture(nil)
						end
					end
				end
				self:StyleFrame(frame)
			end

			self:UpdateButtons(event, ...)

			self:SecureHook("FCF_OpenTemporaryWindow", "StyleTempFrame")
			self:SecureHook("FCFTab_UpdateAlpha", "UpdateTabAlpha")
			self:SecureHook("FCF_DockUpdate","UpdateClutter")

			-- Not an ideal solution for this,
			-- but mouse scripts are just too unreliable here.
			self:ScheduleRepeatingTimer("UpdateClutter", 1/10)

			if (QuickJoinToastButton) then
				QuickJoinToastButton:UnregisterAllEvents()
				QuickJoinToastButton:SetParent(UIHider)
				QuickJoinToastButton:Hide()
			end

			if (not ns.IsVerboseMode) then
				local quiettime = GetTime() + 10
				CreateFrame("Frame"):SetScript("OnUpdate", function(self)
					if (GetTime() > quiettime) then
						self:Hide()
						self:SetScript("OnUpdate", nil)
						return
					end
					ChatFrame1:Clear()
				end)
			end
		end
	end
end

ChatFrames.OnInitialize = function(self)
	if (ns.API.IsAddOnEnabled("Prat-3.0") or ns.API.IsAddOnEnabled("ls_Glass")) then return self:Disable() end

	self.db = ns.db:RegisterNamespace(self:GetName(), defaults)

	-- Add a command to clear all chat frames.
	-- I mainly use this to remove clutter before taking screenshots.
	-- You could theoretically put this in a macro and clear chat then screenshot.
	self:RegisterChatCommand("clear", function()
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame and frame:IsShown()) then
				frame:Clear()
			end
		end
	end)

	-- Add more font sizes.
	for i = #CHAT_FONT_HEIGHTS, 1, -1 do
		CHAT_FONT_HEIGHTS[i] = nil
	end
	for i,v in ipairs({ 12, 14, 16, 18, 20, 22, 24, 28, 32 }) do
		CHAT_FONT_HEIGHTS[i] = v
	end
end

ChatFrames.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
