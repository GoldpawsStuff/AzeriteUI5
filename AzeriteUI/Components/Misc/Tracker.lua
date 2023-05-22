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
if (not ns.IsRetail) then return end

LoadAddOn("Blizzard_ObjectiveTracker")

local Tracker = ns:NewModule("Tracker", "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0")
local MFM = ns:GetModule("MovableFramesManager")

-- WoW API
local IsAddOnLoaded = IsAddOnLoaded
local SetOverrideBindingClick = SetOverrideBindingClick

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider
local noop = ns.Noop

local DEFAULT_THEME = "Blizzard"
local CURRENT_THEME = DEFAULT_THEME

local Cache = {}
local Custom = {}

-- Will move data to the skins,
-- currently just the keys need to exist though.
local Skins = {
	Blizzard = {},
	[MFM:GetDefaultLayout()] = {}
}

local defaults = { profile = ns:Merge({
	enabled = true,
	theme = "Azerite"
}, ns.moduleDefaults) }

local UpdateObjectiveTracker = function()
	local frame = ObjectiveTrackerFrame.MODULES
	if (frame) then

		local theme = Tracker.db.profile.theme
		local azerite = theme == "Azerite"
		local blizzard = theme == "Blizzard"

		for i = 1,#frame do
			local module = frame[i]
			if (module) then

				local header = module.Header

				local background = header.Background
				if (azerite) then
					if (not Cache[background]) then
						Cache[background] = { atlas = background:GetAtlas() }
					end
					background:SetAtlas(nil)

				elseif (blizzard) then
					local cache = Cache[background]
					if (cache) then
						background:SetAtlas(cache.atlas)
						Cache[background] = nil
					end
				end

				local msg = header.Text
				if (azerite) then
					if (not Cache[msg]) then
						Cache[msg] = {
							fontObject = msg:GetFontObject(),
							font = { msg:GetFont() },
							fontColor = { msg:GetTextColor() },
							shadowColor = { msg:GetShadowColor() },
							drawLayer = { msg:GetDrawLayer() },
							parent = msg:GetParent()
						}
					end
					msg:SetFontObject(GetFont(16,true))
					msg:SetTextColor(unpack(ns.Colors.title))
					msg:SetShadowColor(0,0,0,0)
					msg:SetDrawLayer("OVERLAY", 7)
					msg:SetParent(header)

				elseif (blizzard) then
					local cache = Cache[msg]
					if (cache) then
						msg:SetFontObject(cache.fontObject)
						msg:SetTextColor(unpack(cache.fontColor))
						msg:SetShadowColor(unpack(cache.shadowColor))
						msg:SetDrawLayer(unpack(cache.drawLayer))
						msg:SetParent(cache.parent)
						Cache[msg] = nil
					end
				end

				-- Calling module:GetActiveBlocks() would create an empty table,
				-- which in turn renders the whole tracker and the editmode tainted.
				local blocks = module.blockTemplate and module.usedBlocks and module.usedBlocks[module.blockTemplate]
				if (blocks) then
					for id,block in pairs(blocks) do

						-- Quest/Objective title
						local headerText = block.HeaderText
						if (headerText) then
							if (azerite) then
								if (not Cache[headerText]) then
									Cache[headerText] = {
										fontObject = headerText:GetFontObject(),
										font = { headerText:GetFont() },
										spacing = headerText:GetSpacing()
									}
								end
								headerText:SetFontObject(GetFont(13,true))
								headerText:SetSpacing(2)

							elseif (blizzard) then
								local cache = Cache[headerText]
								if (cache) then
									headerText:SetFontObject(cache.fontObject)
									headerText:SetSpacing(cache.spacing)
									Cache[headerText] = nil
								end
							end
						end

						-- Quest/Objective text/objectives
						for objectiveKey,line in pairs(block.lines) do
							local text = line.Text
							local dash = line.Dash

							if (azerite) then
								if (not Cache[text]) then
									Cache[text] = {
										fontObject = text:GetFontObject(),
										font = { text:GetFont() },
										spacing = text:GetSpacing()
									}
								end
								text:SetFontObject(GetFont(13,true))
								text:SetSpacing(2)

								if (dash) then
									if (not Cache[dash]) then
										Cache[dash] = { parent = dash:GetParent() }
									end
									dash:SetParent(UIHider)
								end

							elseif (blizzard) then
								local cache = Cache[text]
								if (cache) then
									text:SetFontObject(cache.fontObject)
									text:SetSpacing(cache.spacing)
									Cache[text] = nil
								end
								if (dash) then
									local cache = Cache[dash]
									if (cache) then
										dash:SetParent(cache.parent)
										Cache[dash] = nil
									end
								end
							end

						end
					end
				end

				local minimize = header.MinimizeButton
				if (azerite) then
					if (not Cache[minimize]) then
						Cache[minimize] = {
							func = minimize.SetCollapsed,
							normalTexture = minimize:GetNormalTexture():GetAtlas(),
							pushedTexture = minimize:GetPushedTexture():GetAtlas(),
							highlightTexture = minimize:GetHighlightTexture():GetAtlas(),
							size = { minimize:GetSize() },
							points = { minimize:GetPoint() }
						}
						minimize.SetCollapsed = function() return end
						minimize:GetNormalTexture():SetTexture(nil)
						minimize:GetPushedTexture():SetTexture(nil)
						minimize:GetHighlightTexture():SetTexture(nil)
						minimize:DisableDrawLayer(minimize:GetNormalTexture():GetDrawLayer())
						minimize:DisableDrawLayer(minimize:GetPushedTexture():GetDrawLayer())
						minimize:DisableDrawLayer(minimize:GetHighlightTexture():GetDrawLayer())
						minimize:SetSize(header:GetSize())
						minimize:ClearAllPoints()
						minimize:SetPoint("CENTER")
					end

				elseif (blizzard) then
					local cache = Cache[minimize]
					if (cache) then
						minimize.SetCollapsed = cache.func
						minimize:EnableDrawLayer(minimize:GetNormalTexture():GetDrawLayer())
						minimize:EnableDrawLayer(minimize:GetPushedTexture():GetDrawLayer())
						minimize:EnableDrawLayer(minimize:GetHighlightTexture():GetDrawLayer())
						minimize:GetNormalTexture():SetAtlas(cache.normalTexture)
						minimize:GetPushedTexture():SetAtlas(cache.pushedTexture)
						minimize:GetHighlightTexture():SetAtlas(cache.highlightTexture)
						minimize:SetSize(unpack(cache.size))
						minimize:ClearAllPoints()
						minimize:SetPoint(unpack(cache.points))
						Cache[minimize] = nil
					end
				end
			end
		end
	end
end

local UpdateProgressBar = function(_, _, line)

	local progress = line.ProgressBar
	local bar = progress.Bar

	if (bar) then

		local theme = Tracker.db.profile.theme
		local azerite = theme == "Azerite"
		local blizzard = theme == "Blizzard"

		local label = bar.Label
		local icon = bar.Icon
		local iconBG = bar.IconBG
		local barBG = bar.BarBG
		local glow = bar.BarGlow
		local sheen = bar.Sheen
		local frame = bar.BarFrame
		local frame2 = bar.BarFrame2
		local frame3 = bar.BarFrame3
		local borderLeft = bar.BorderLeft
		local borderRight = bar.BorderRight
		local borderMid = bar.BorderMid

		-- This will fix "stuck" animations?
		if (progress.AnimatableFrames) then
			BonusObjectiveTrackerProgressBar_ResetAnimations(progress)
		end

		if (azerite) then

			if (not Custom[bar]) then

				local backdrop = bar:CreateTexture(nil, "BORDER", nil, -1)
				backdrop:SetPoint("TOPLEFT", 0, 0)
				backdrop:SetPoint("BOTTOMRIGHT", 0, 0)
				backdrop:SetColorTexture(.6, .6, .6, .05)
				backdrop:Hide()

				local border = bar:CreateTexture(nil, "BORDER", nil, -2)
				border:SetPoint("TOPLEFT", -2, 2)
				border:SetPoint("BOTTOMRIGHT", 2, -2)
				border:SetColorTexture(0, 0, 0, .75)
				border:Hide()

				Custom[bar] = { backdrop = backdrop, border = border }
			end

			Custom[bar].backdrop:Show()
			Custom[bar].border:Show()

			if (not Cache[bar]) then
				Cache[bar] = {
					barHeight = bar:GetHeight(),
					barTexture = bar:GetStatusBarTexture(),
					barDrawLayer = { bar:GetStatusBarTexture():GetDrawLayer() }
				}
			end

			-- Some of these tend to pop back up, so let's just always hide them.
			if (barBG) then barBG:Hide(); barBG:SetAlpha(0) end
			if (iconBG) then iconBG:Hide(); iconBG:SetAlpha(0) end
			if (glow) then glow:Hide() end
			if (sheen) then sheen:Hide() end
			if (frame) then frame:Hide() end
			if (frame2) then frame2:Hide() end
			if (frame3) then frame3:Hide() end
			if (borderLeft) then borderLeft:SetAlpha(0) end
			if (borderRight) then borderRight:SetAlpha(0) end
			if (borderMid) then borderMid:SetAlpha(0) end

			bar:SetStatusBarTexture(GetMedia("bar-progress"))
			bar:GetStatusBarTexture():SetDrawLayer("BORDER", 0)
			bar:DisableDrawLayer("BACKGROUND")
			bar:SetHeight(18)

			if (label) then
				if (not Cache[label]) then
					Cache[label] = {
						fontObject = label:GetFontObject(),
						font = { label:GetFont() },
						points = { label:GetPoint() }
					}
				end
				label:SetFontObject(GetFont(12, true))
				label:ClearAllPoints()
				label:SetPoint("CENTER", bar, 0,0)
			end

			if (icon) then
				if (not Cache[icon]) then
					Cache[icon] = {
						mask = icon:GetMaskTexture(1),
						size = { icon:GetSize() },
						points = { icon:GetPoint() }
					}
				end
				local i = 1
				while icon:GetMaskTexture(i) do
					icon:RemoveMaskTexture(icon:GetMaskTexture(i))
					i = i + 1
				end
				icon:SetSize(20, 20)
				icon:SetMask("")
				icon:SetMask(GetMedia("actionbutton-mask-square-rounded"))
				icon:ClearAllPoints()
				icon:SetPoint("RIGHT", bar, 26, 0)
			end


		elseif (blizzard) then

			local custom = Custom[bar]
			if (custom) then
				custom.backdrop:Hide()
				custom.border:Hide()
			end

			local cache = Cache[bar]
			if (cache) then
				-- Should all these be shown? Really?
				if (barBG) then barBG:Show(); barBG:SetAlpha(1) end
				if (iconBG) then iconBG:Show(); iconBG:SetAlpha(1) end
				if (glow) then glow:Show() end
				if (sheen) then sheen:Show() end
				if (frame) then frame:Show() end
				if (frame2) then frame2:Show() end
				if (frame3) then frame3:Show() end
				if (borderLeft) then borderLeft:SetAlpha(1) end
				if (borderRight) then borderRight:SetAlpha(1) end
				if (borderMid) then borderMid:SetAlpha(1) end

				bar:EnableDrawLayer("BACKGROUND")
				bar:SetHeight(cache.barHeight)
				bar:SetStatusBarTexture(cache.barTexture)
				bar:GetStatusBarTexture():SetDrawLayer(unpack(cache.barDrawLayer))

				Cache[bar] = nil
			end

			local cache = Cache[label]
			if (cache) then
				label:SetFontObject(cache.fontObject)
				label:ClearAllPoints()
				label:SetPoint(unpack(cache.points))
				Cache[label] = nil
			end

			local cache = Cache[icon]
			if (cache) then
				local i = 1
				while icon:GetMaskTexture(i) do
					icon:RemoveMaskTexture(icon:GetMaskTexture(i))
					i = i + 1
				end
				icon:SetSize(unpack(cache.size))
				icon:SetMask("")
				icon:SetMask(cache.mask)
				icon:ClearAllPoints()
				icon:SetPoint(unpack(cache.points))
				Cache[icon] = nil
			end
		end
	end
end

local UpdateQuestItemButton = function(button)

	local name = button:GetName()
	local icon = button.icon or _G[name.."IconTexture"]
	local count = button.Count or _G[name.."Count"]
	local hotKey = button.HotKey or _G[name.."HotKey"]

	local theme = Tracker.db.profile.theme
	local azerite = theme == "Azerite"
	local blizzard = theme == "Blizzard"

	if (azerite) then
		if (not Custom[button]) then

			local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
			backdrop:SetPoint("TOPLEFT", icon, -2, 2)
			backdrop:SetPoint("BOTTOMRIGHT", icon, 2, -2)
			backdrop:SetColorTexture(0, 0, 0, .75)
			backdrop:Hide()

			local highlight = button:CreateTexture()
			highlight:SetColorTexture(1, 1, 1, .3)
			highlight:SetAllPoints(icon)
			highlight:Hide()

			local pushed = button:CreateTexture()
			pushed:SetColorTexture(.9, .8, .1, .3)
			pushed:SetAllPoints(icon)
			pushed:Hide()

			local checked = button:CreateTexture()
			checked:SetColorTexture(0, 1, 0, .3)
			checked:SetAllPoints(icon)
			checked:Hide()

			Custom[button] = { backdrop = backdrop, highlight = highlight, pushed = pushed, cheched = checked }
		end

		if (not Cache[button]) then
			Cache[button] = {
				normalTexture = button:GetNormalTexture(),
				highlightTexture = button:GetHighlightTexture(),
				pushedTexture = button:GetPushedTexture(),
				--chechedTexture = button:GetCheckedTexture()
			}

			button:SetNormalTexture("")
			button:SetHighlightTexture(Custom[button].highlight)
			button:SetPushedTexture(Custom[button].pushed)
			--button:SetCheckedTexture(Custom[button].cheched)

			Custom[button].backdrop:Show()
			Custom[button].highlight:Show()
			Custom[button].pushed:Show()
			Custom[button].cheched:Show()
		end

		if (icon) then
			if (not Cache[icon]) then
				Cache[icon] = {
					drawLayer = { icon:GetDrawLayer() },
					texCoords = { icon:GetTexCoord() },
					points = { icon:GetPoint() }
				}
				icon:SetDrawLayer("BACKGROUND",0)
				icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				icon:ClearAllPoints()
				icon:SetPoint("TOPLEFT", 2, -2)
				icon:SetPoint("BOTTOMRIGHT", -2, 2)
			end
		end

		if (count) then
			if (not Cache[count]) then
				Cache[count] = {
					fontObject = count:GetFontObject(),
					points = { count:GetPoint() }
				}
				count:ClearAllPoints()
				count:SetPoint("BOTTOMRIGHT", button, 0, 3)
				count:SetFontObject(GetFont(12,true))
			end
		end

		if (hotKey) then
			if (not Cache[hotKey]) then
				Cache[hotKey] = {
					text = hotKey:GetText()
				}
				hotKey:SetText("")
				hotKey:SetAlpha(0)
			end
		end

	elseif (blizzard) then
		local custom = Custom[button]
		if (custom) then
			custom.backdrop:Show()
			custom.highlight:Show()
			custom.pushed:Show()
			custom.cheched:Show()
		end

		local cache = Cache[button]
		if (cache) then
			button:SetNormalTexture(cache.normalTexture)
			button:SetHighlightTexture(cache.highlightTexture)
			button:SetPushedTexture(cache.pushedTexture)
			--button:SetCheckedTexture(cache.chechedTexture)
			Cache[button] = nil
		end

		if (icon) then
			local cache = Cache[icon]
			if (cache) then
				icon:SetDrawLayer(unpack(cache.drawLayer))
				icon:SetTexCoord(unpack(cache.texCoords))
				icon:ClearAllPoints()
				icon:SetPoint(unpack(cache.points))
				Cache[icon] = nil
			end
		end

		if (count) then
			local cache = Cache[count]
			if (cache) then
				count:ClearAllPoints()
				count:SetPoint(unpack(cache.points))
				count:SetFontObject(cache.fontObject)
				Cache[count] = nil
			end
		end

		if (hotKey) then
			local cache = Cache[hotKey]
			if (cache) then
				hotKey:SetText(cache.text)
				hotKey:SetAlpha(1)
				Cache[hotKey] = nil
			end
		end
	end

end

local UpdateQuestItem = function(_, block)
	local button = block.itemButton
	if (button) then
		UpdateQuestItemButton(button)
	end
end

local AutoHider_OnHide = function()
	if (not ObjectiveTrackerFrame.collapsed) then
		ObjectiveTracker_Collapse()
	end
end

local AutoHider_OnShow = function()
	if (ObjectiveTrackerFrame.collapsed) then
		ObjectiveTracker_Expand()
	end
end

local Immersion_OnShow = function()
	if (ObjectiveTrackerFrame) then
		ObjectiveTrackerFrame:SetAlpha(0)
	end
end

local Immersion_OnHide = function()
	if (ObjectiveTrackerFrame) then
		ObjectiveTrackerFrame:SetAlpha(.9)
	end
end

local SetObjectivesTrackerTheme = function(self, requestedTheme)

	-- Theme names are case sensitive,
	-- but we don't want the input to be.
	local name
	for theme in next,Skins do
		if (string.lower(theme) == string.lower(requestedTheme)) then
			name = theme
			break
		end
	end

	if (not name or not Skins[name] or name == CURRENT_THEME) then return end

	CURRENT_THEME = name
	Tracker.db.profile.theme = name

	ObjectiveTracker_Update() -- taint?

end

Tracker.SetObjectivesTrackerTheme = function(self, input)
	ObjectiveTrackerFrame:SetTheme((self:GetArgs(string.lower(input))))
end

Tracker.HookTracker = function(self)

	ObjectiveTrackerUIWidgetContainer:SetFrameStrata("BACKGROUND")
	ObjectiveTrackerFrame:SetFrameStrata("BACKGROUND")

	self:SecureHook("ObjectiveTracker_Update", UpdateObjectiveTracker)
	self:SecureHook(QUEST_TRACKER_MODULE, "SetBlockHeader", UpdateQuestItem)
	self:SecureHook(WORLD_QUEST_TRACKER_MODULE, "AddObjective", UpdateQuestItem)
	self:SecureHook(CAMPAIGN_QUEST_TRACKER_MODULE, "AddObjective", UpdateQuestItem)
	self:SecureHook(CAMPAIGN_QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	self:SecureHook(QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	self:SecureHook(DEFAULT_OBJECTIVE_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	self:SecureHook(BONUS_OBJECTIVE_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	self:SecureHook(WORLD_QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	self:SecureHook(SCENARIO_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)

	ObjectiveTrackerFrame.autoHider = CreateFrame("Frame", nil, ObjectiveTrackerFrame, "SecureHandlerStateTemplate")
	ObjectiveTrackerFrame.autoHider:SetAttribute("_onstate-vis", [[ if (newstate == "hide") then self:Hide() else self:Show() end ]])
	ObjectiveTrackerFrame.autoHider:SetScript("OnHide", AutoHider_OnHide)
	ObjectiveTrackerFrame.autoHider:SetScript("OnShow", AutoHider_OnShow)

	ObjectiveTrackerFrame.SetTheme = SetObjectivesTrackerTheme

	local driver = "hide;show"
	driver = "[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists]" .. driver
	driver = "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists][@boss5,exists]" .. driver

	RegisterStateDriver(ObjectiveTrackerFrame.autoHider, "vis", driver)

	if (IsAddOnEnabled("Immersion")) then
		if (IsPlayerInWorld()) then
			self:HookImmersion()
		else
			self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		end
	end

end

Tracker.HookImmersion = function(self)
	if (not ImmersionFrame) then return end
	if (not self:IsHooked(ImmersionFrame, "OnShow")) then
		self:SecureHookScript(ImmersionFrame, "OnShow", Immersion_OnShow)
	end
	if (not self:IsHooked(ImmersionFrame, "OnHide")) then
		self:SecureHookScript(ImmersionFrame, "OnHide", Immersion_OnHide)
	end
end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
			self:HookImmersion()
		end
	end
end

Tracker.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ObjectivesTracker", defaults)

	self:SetEnabledState(self.db.profile.enabled)
	self:HookTracker()
	self:RegisterChatCommand("settrackertheme", "SetObjectivesTrackerTheme")
end

Tracker.OnEnable = function(self)
	self:SetObjectivesTrackerTheme(self.db.profile.theme)
end
