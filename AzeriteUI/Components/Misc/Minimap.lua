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

local MinimapMod = ns:NewModule("Minimap", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0", "AceConsole-3.0")

local LibDD = LibStub("LibUIDropDownMenu-4.0")

-- Lua API
local ipairs = ipairs
local math_cos = math.cos
local half_pi = math.pi/2
local math_sin = math.sin
local next = next
local pairs = pairs
local string_format = string.format
local string_lower = string.lower
local table_insert = table.insert
local type = type
local unpack = unpack

-- GLOBALS: AddonCompartmentFrame, GameTimeFrame, MiniMapBattlefieldFrame, MiniMapMailFrame, MiniMapLFGFrame
-- GLOBALS: C_CraftingOrders, GameTooltip, GameTooltip_SetDefaultAnchor, GarrisonLandingPage_Toggle
-- GLOBALS: GetPlayerFacing, GetRealZoneText
-- GLOBALS: ExpansionLandingPageMinimapButton, GarrisonLandingPageMinimapButton, MinimapZoneTextButton, MiniMapWorldMapButton, TimeManagerClockButton, QueueStatusButton
-- GLOBALS: InCombatLockdown, IsResting, HasNewMail, PlaySound, ToggleDropDownMenu
-- GLOBALS: MinimapZoomIn, MinimapZoomOut, Minimap_OnClick
-- GLOBALS: Minimap, MinimapBackdrop, MinimapCluster, MinimapBorder, MinimapBorderTop, MicroButtonAndBagsBar, MinimapCompassTexture, MiniMapInstanceDifficulty, MiniMapTracking
-- GLOBALS: SOUNDKIT, MINIMAP_LABEL, PROFESSIONS_CRAFTING

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider
local noop = ns.Noop

-- WoW Strings
local L_NEW = NEW -- "New"
local L_MAIL = MAIL_LABEL -- "Mail"
local L_HAVE_MAIL = HAVE_MAIL -- "You have unread mail"
local L_HAVE_MAIL_FROM = HAVE_MAIL_FROM -- "Unread mail from:"

-- Constants
local TORGHAST_ZONE_ID = 2162
local IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))
local mapScale = ns.WoW10 and 1 or 198/140

local defaults = { profile = ns:Merge({
	enabled = true,
	theme = "Azerite"
}, ns.MovableModulePrototype.defaults) }

MinimapMod.GetScale = function(self)
	return mapScale
end

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
MinimapMod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = mapScale * ns.API.GetEffectiveScale(),
		[1] = "BOTTOMRIGHT",
		[2] = -(40 - ((ns.IsCata or ns.IsClassic) and 10 or 0)) * (mapScale * ns.API.GetEffectiveScale()),
		[3] = (40 - ((ns.IsCata or ns.IsClassic) and 10 or 0)) * (mapScale * ns.API.GetEffectiveScale())
	}
	return defaults
end

local DEFAULT_THEME = "Blizzard"
local CURRENT_THEME = DEFAULT_THEME

local Elements = {}
local Objects = {}
local ObjectOwners = {}

MinimapMod.Elements = Elements
MinimapMod.Objects = Objects
MinimapMod.ObjectOwners = ObjectOwners

-- Snippets to be run upon object toggling.
----------------------------------------------------
local ObjectSnippets = {

	-- Blizzard Objects
	------------------------------------------
	Crafting = {
		Enable = function(object)
			object:OnLoad()
			object:SetScript("OnEvent", object.OnEvent)
		end,
		Disable = function(object)
			object:SetScript("OnEvent", nil)
		end,
		Update = function(object)
			object:OnEvent("CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS")
		end
	},
	Mail = {
		Enable = function(object)
			object:OnLoad()
			object:SetScript("OnEvent", object.OnEvent)
		end,
		Disable = function(object)
			object:SetScript("OnEvent", nil)
		end,
		Update = function(object)
			object:OnEvent("UPDATE_PENDING_MAIL")
		end
	},
	Eye = {
		Enable = function(object)
			if (ns.IsCata) then
				object:SetFrameLevel(object:GetParent():GetFrameLevel() + 2)
			elseif (ns.IsRetail) then
			end
		end,
		Disable = function(object)
			if (ns.IsCata) then
			elseif (ns.IsRetail) then
			end
		end,
		Update = function(object)
			if (ns.IsCata) then
			elseif (ns.IsRetail) then
			end
		end
	},
	EyeClassicPvP = {
		Enable = function(object)
			MiniMapBattlefieldIcon:Show()
			MiniMapBattlefieldBorder:Show()
			BattlegroundShine:Show()
			if (BattlefieldIconText) then BattlefieldIconText:Show() end
		end,
		Disable = function(object)
			MiniMapBattlefieldIcon:Hide()
			MiniMapBattlefieldBorder:Hide()
			BattlegroundShine:Hide()
			if (BattlefieldIconText) then BattlefieldIconText:Hide() end
		end,
		Update = function(object)
			if (PVPBattleground_UpdateQueueStatus) then PVPBattleground_UpdateQueueStatus() end
			BattlefieldFrame_UpdateStatus(false)
		end
	},

	-- AzeriteUI Objects
	------------------------------------------
	AzeriteEye = {
		Enable = function(object)
			if (ns.IsCata) then
				MiniMapLFGFrame:SetParent(Minimap)
				MiniMapLFGFrame:SetFrameLevel(100)
				MiniMapLFGFrame:ClearAllPoints()
				MiniMapLFGFrame:SetPoint("TOPRIGHT", Minimap, -4, -2)
				MiniMapLFGFrame:SetHitRectInsets(-8, -8, -8, -8)
				MiniMapLFGFrameBorder:Hide()
				MiniMapLFGFrameIcon:Hide()
			elseif (ns.IsRetail) then
				QueueStatusButton:SetParent(Minimap)
				QueueStatusButton:SetFrameLevel(100)
				QueueStatusButton:ClearAllPoints()
				QueueStatusButton:SetPoint("CENTER", Minimap, "CENTER", 82, 82)
				QueueStatusButton:SetHitRectInsets(-8, -8, -8, -8)
				QueueStatusButton.Eye:SetParent(UIHider)
				QueueStatusButton.Highlight:SetParent(UIHider)
			end
		end,
		Disable = function(object)
			if (ns.IsCata) then
				MiniMapLFGFrame:SetParent(_G[ObjectOwners.Eye])
				MiniMapLFGFrame:SetFrameLevel(MinimapBackdrop:GetFrameLevel() + 2)
				MiniMapLFGFrame:ClearAllPoints()
				MiniMapLFGFrame:SetPoint("TOPLEFT", 25, -100)
				MiniMapLFGFrame:SetHitRectInsets(0, 0, 0, 0)
				MiniMapLFGFrameBorder:Show()
				MiniMapLFGFrameIcon:Show()
			elseif (ns.IsRetail) then
				QueueStatusButton:SetParent(_G[ObjectOwners.Eye])
				QueueStatusButton:SetFrameLevel(_G[ObjectOwners.Eye]:GetFrameLevel() + 1)
				QueueStatusButton:ClearQueueStatus()
				QueueStatusButton:ClearAllPoints()
				QueueStatusButton:SetPoint("BOTTOMLEFT", -45, 4)
				QueueStatusButton:SetHitRectInsets(0, 0, 0, 0)
				QueueStatusButton.Highlight:SetParent(QueueStatusButton)
				QueueStatusButton.Eye:SetParent(QueueStatusButton)
				QueueStatusButton.Eye:SetFrameLevel(QueueStatusButton:GetFrameLevel() - 1)
			end
		end,
		Update = function(object)
		end
	},
	AzeriteEyeClassicPvP = {
		Enable = function(object)
			MiniMapBattlefieldFrame:SetFrameStrata("MEDIUM")
			MiniMapBattlefieldFrame:SetFrameLevel(70) -- Minimap's XP button is 60
			MiniMapBattlefieldFrame:ClearAllPoints()
			MiniMapBattlefieldFrame:SetPoint("BOTTOMLEFT", Minimap, 4, 2)
			MiniMapBattlefieldFrame:SetHitRectInsets(-8, -8, -8, -8)
			MiniMapBattlefieldIcon:Hide()
			MiniMapBattlefieldBorder:Hide()
			BattlegroundShine:Hide()
			if (BattlefieldIconText) then BattlefieldIconText:Hide() end
		end,
		Disable = function(object)
			MiniMapBattlefieldFrame:SetFrameStrata(Minimap:GetFrameStrata())
			MiniMapBattlefieldFrame:SetFrameLevel(Minimap:GetFrameLevel() + 1)
			MiniMapBattlefieldFrame:ClearAllPoints()
			MiniMapBattlefieldFrame:SetPoint("BOTTOMLEFT", Minimap, 13, -13)
			MiniMapBattlefieldFrame:SetHitRectInsets(0, 0, 0, 0)
			MiniMapBattlefieldIcon:Show()
			MiniMapBattlefieldBorder:Show()
			BattlegroundShine:Show()
			if (BattlefieldIconText) then BattlefieldIconText:Show() end
		end,
		Update = function(object)
		end
	}
}

-- Element type of custom elements.
local ElementTypes = {
	Backdrop = "Texture",
	Border = "Texture",
	AzeriteEye = "Texture",
	AzeriteEyeClassicPvP = "Texture"
}

-- Mask textures for the supported shapes.
local Shapes = {
	Round = GetMedia("minimap-mask-opaque"),
	RoundTransparent = GetMedia("minimap-mask-transparent")
}

-- Our custom embedded skins.
local Skins = {
	Blizzard = {
		Version = 1,
		Shape = "Round"
	},
	["Azerite"] = {
		Version = 1,
		Shape = "RoundTransparent",
		HideElements = {
			Addons = true, -- retail
			BattleField = false, -- classic + wrath
			BorderTop = true,
			BorderClassic = true, -- wrath
			Calendar = true,
			Clock = true,
			Compass = true,
			Crafting = true, -- retail
			Difficulty = true,
			Expansion = true, -- retail
			Eye = false, -- wrath + retail
			Mail = true,
			Tracking = true,
			ToggleButton = true, -- classic
			Zone = true,
			ZoomIn = true,
			ZoomOut = true,
			WorldMap = true -- wrath
		},
		Elements = {
			Backdrop = {
				Owner = "Minimap",
				DrawLayer = "BACKGROUND",
				DrawLevel = -7,
				Path = GetMedia("minimap-mask-opaque"),
				Size = function() return (198 / mapScale), (198 / mapScale) end,
				Point = { "CENTER" },
				Color = { 0, 0, 0, .75 },
			},
			Border = {
				Owner = "Backdrop",
				DrawLayer = "BORDER",
				DrawLevel = 1,
				Path = GetMedia("minimap-border"),
				Size = function() return (398 / mapScale), (398 / mapScale) end, -- 404
				Point = { "CENTER", 0, 0 },
				Color = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
			},
			AzeriteEye = {
				Owner = "Eye",
				DrawLayer = "BORDER",
				DrawLevel = 2,
				Path = GetMedia("group-finder-eye-green"),
				Size = { 64, 64 },
				Point = { "CENTER", 0, 0 },
				Color = { .90, .95, 1 }
			},
			-- CATA: check
			AzeriteEyeClassicPvP = (ns.IsClassic or ns.IsCata) and {
				Owner = "EyeClassicPvP",
				DrawLayer = "BORDER",
				DrawLevel = 2,
				Path = GetMedia("group-finder-eye-orange"),
				Size = { 64, 64 },
				Point = { "CENTER", 0, 0 },
				Color = { .90, .95, 1 }
			}
		}
	}
}

-- Element Callbacks
--------------------------------------------
local Minimap_OnMouseWheel = function(self, delta)
	if (delta > 0) then
		(Minimap.ZoomIn or MinimapZoomIn):Click()
	elseif (delta < 0) then
		(Minimap.ZoomOut or MinimapZoomOut):Click()
	end
end

local Minimap_OnMouseUp = function(self, button)
	if (button == "RightButton") then
		if (ns.IsClassic) then
			MinimapMod:ShowMinimapTrackingMenu()
		else
			ToggleDropDownMenu(1, nil, _G[ns.Prefix.."MiniMapTrackingDropDown"], "cursor")
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		end
	elseif (button == "MiddleButton" and ns.IsRetail) then
		local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
		if (GLP and GLP:IsShown()) and (not InCombatLockdown()) then
			if (GLP.ToggleLandingPage) then
				GLP:ToggleLandingPage()
			else
				GarrisonLandingPage_Toggle()
			end
		end
	else
		local func = Minimap.OnClick or Minimap_OnClick
		if (func) then
			func(self)
		end
	end
end

local Mail_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	-- Add unread mail notifier.
	local sender1, sender2, sender3 = GetLatestThreeSenders()
	if (sender1 or sender2 or sender3) then
		GameTooltip:AddLine(L_HAVE_MAIL_FROM, unpack(Colors.highlight))
		if (sender1) then
			GameTooltip:AddLine(sender1, unpack(Colors.green))
		end
		if (sender2) then
			GameTooltip:AddLine(sender2, unpack(Colors.green))
		end
		if (sender3) then
			GameTooltip:AddLine(sender3, unpack(Colors.green))
		end
	else
		GameTooltip:AddLine(L_HAVE_MAIL, unpack(Colors.highlight))
	end

	-- Add crafting order notifier.
	if (ns.IsRetail) and (self.countInfos and #self.countInfos > 0) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(MAILFRAME_CRAFTING_ORDERS_TOOLTIP_TITLE)
		for _,countInfo in ipairs(mail.countInfos) do
			GameTooltip:AddLine(string_format(PERSONAL_CRAFTING_ORDERS_AVAIL_FMT, countInfo.numPersonalOrders, countInfo.professionName))
		end
	end

	GameTooltip:Show()
end

local Mail_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

-- Element API
--------------------------------------------
MinimapMod.UpdateCompass = function(self)
	local compass = self.compass
	if (not compass) then
		return
	end
	if (self.rotateMinimap) then
		local radius = self.compassRadius
		if (not radius) then
			local width = compass:GetWidth()
			if (not width) then
				return
			end
			radius = width/2
		end

		local playerFacing = GetPlayerFacing()
		if (not playerFacing) or (self.supressCompass) or (IN_TORGHAST) then
			compass:SetAlpha(0)
		else
			compass:SetAlpha(1)
		end

		-- In Torghast, map is always locked. Weird.
		local angle = (IN_TORGHAST) and 0 or (self.rotateMinimap and playerFacing) and -playerFacing or 0
		compass.north:SetPoint("CENTER", radius*math_cos(angle + half_pi), radius*math_sin(angle + half_pi))

	else
		compass:SetAlpha(0)
	end
end

MinimapMod.UpdateMail = function(self)
	local mail = self.mail
	if (not mail) then
		return
	end

	local hasMail = HasNewMail()
	local hasCraftingOrder

	if (ns.IsRetail) then
		mail.countInfos = C_CraftingOrders.GetPersonalOrdersInfo()
		hasCraftingOrder = mail.countInfos and #mail.countInfos > 0

		local mailText = ""

		if (hasCraftingOrder) then
			mailText = mailText .. string_format("%s |cff888888(|r"..Colors.normal.colorCode..#mail.countInfos.."|r|cff888888)|r", PROFESSIONS_CRAFTING, L_MAIL, #mail.countInfos)
		end

		if (hasMail) then
			if (hasCraftingOrder) then
				mailText = string_format("%s %s", L_NEW, L_MAIL) .. "|n" .. mailText
			else
				mailText = string_format("%s %s", L_NEW, L_MAIL)
			end
		end

		mail:SetText(mailText)
	end

	if (hasMail or hasCraftingOrder) then
		mail:Show()
		mail.frame:Show()

		--local resting = self.resting
		--if (resting) then
		--	resting:ClearAllPoints()
		--	resting:SetPoint("BOTTOM", mail, "TOP", 0, 0)
		--end
	else
		mail:Hide()
		mail.frame:Hide()

		--local resting = self.resting
		--if (resting) then
		--	resting:ClearAllPoints()
		--	resting:SetPoint(mail:GetPoint())
		--end
	end

end

MinimapMod.UpdateTimers = function(self)

	-- In Torghast, map is always locked. Weird.
	-- *Note that this is only in the tower, not the antechamber.
	-- *We're resting in the antechamber, and it's a sanctuary. Good indicators.
	-- *Also, we know there is an API call for it. We like ours better.
	IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

	self.rotateMinimap = GetCVarBool("rotateMinimap")

	if (self.rotateMinimap) then
		if (not self.compassTimer) then
			self.compassTimer = self:ScheduleRepeatingTimer("UpdateCompass", 1/60)
			self:UpdateCompass()
		end

	elseif (self.compassTimer) then
		self:CancelTimer(self.compassTimer)
		self:UpdateCompass()
	end
end

-- Addon Styling & Initialization
--------------------------------------------
MinimapMod.InitializeMBB = function(self)
	if (self.addonCompartment) then
		self.addonCompartment:SetParent(ns.Hider)
	end

	local button = CreateFrame("Frame", nil, Minimap)
	button:SetFrameLevel(button:GetFrameLevel() + 10)
	button:SetPoint("BOTTOMRIGHT", -244, 35)
	button:SetSize(32, 32)
	button:SetFrameStrata("LOW") -- MEDIUM collides with Immersion

	local frame = _G.MBB_MinimapButtonFrame
	frame:SetParent(button)
	frame:RegisterForDrag()
	frame:SetSize(32, 32)
	frame:ClearAllPoints()
	frame:SetFrameStrata("LOW") -- MEDIUM collides with Immersion
	frame:SetPoint("CENTER", 0, 0)
	frame:SetHighlightTexture("")
	frame:DisableDrawLayer("OVERLAY")

	frame.ClearAllPoints = noop
	frame.SetPoint = noop
	frame.SetAllPoints = noop

	local icon = _G.MBB_MinimapButtonFrame_Texture
	icon:ClearAllPoints()
	icon:SetPoint("CENTER", 0, 0)
	icon:SetSize(32, 32)
	icon:SetTexture(GetMedia("plus"))
	icon:SetTexCoord(0,1,0,1)
	icon:SetAlpha(.85)

	local down, over
	local setalpha = function()
		if (down and over) then
			icon:SetAlpha(1)
		elseif (down or over) then
			icon:SetAlpha(.95)
		else
			icon:SetAlpha(.85)
		end
	end

	frame:SetScript("OnMouseDown", function(self)
		down = true
		setalpha()
	end)

	frame:SetScript("OnMouseUp", function(self)
		down = false
		setalpha()
	end)

	frame:SetScript("OnEnter", function(self)
		MBB_ShowTimeout = -1
		over = true
		setalpha()

		if (GameTooltip:IsForbidden()) then return end

		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine("MinimapButtonBag v" .. MBB_Version)
		GameTooltip:AddLine(MBB_TOOLTIP1, 0, 1, 0, true)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		MBB_ShowTimeout = 0
		over = false
		setalpha()

		if (GameTooltip:IsForbidden()) then return end

		GameTooltip:Hide()
	end)
end

MinimapMod.InitializeNarcissus = function(self)
	local Narci_MinimapButton = Narci_MinimapButton
	if (not Narci_MinimapButton) then
		return
	end

	Narci_MinimapButton:SetScript("OnDragStart", nil)
	Narci_MinimapButton:SetScript("OnDragStop", nil)
	Narci_MinimapButton:SetSize(56, 56)
	Narci_MinimapButton.Color:SetVertexColor(.85, .85, .85, 1)
	Narci_MinimapButton.Background:SetScale(1)
	Narci_MinimapButton.Background:SetSize(46, 46)
	Narci_MinimapButton.Background:SetVertexColor(.75, .75, .75, 1)
	Narci_MinimapButton.InitPosition = function(self)
		local _, _, rp = self:GetPoint()
		if (rp ~= "TOP") then
			Narci_MinimapButton:ClearAllPoints()
			Narci_MinimapButton:SetPoint("CENTER", Minimap, "TOP", 0, 8)
		end
	end
	Narci_MinimapButton.OnDragStart = noop
	Narci_MinimapButton.OnDragStop = noop
	Narci_MinimapButton.SetIconScale = noop
	Narci_MinimapButton:InitPosition()

	hooksecurefunc(Narci_MinimapButton, "SetPoint", Narci_MinimapButton.InitPosition)

end

MinimapMod.InitializeAddon = function(self, addon)
	if (not IsAddOnEnabled(addon)) then
		return
	end
	local method = self["Initialize"..addon]
	if (method) then
		if (not IsAddOnLoaded(addon)) then
			LoadAddOn(addon)
		end
		method(self)
	end
end

-- Module Theme API (really...?)
--------------------------------------------
MinimapMod.RegisterTheme = function(self, name, skin)
	if (Skins[name] or name == DEFAULT_THEME) then return end
	Skins[name] = skin
end

MinimapMod.SetMinimapTheme = function(self, input)
	if (InCombatLockdown()) then return end
	local theme = self:GetArgs(string_lower(input))
	if (not ns.IsRetail and theme == "blizzard") then
		theme = "azerite"
	end
	self:SetTheme(theme)
end

MinimapMod.SetTheme = function(self, requestedTheme)
	if (InCombatLockdown()) then return end

	-- Theme names are case sensitive,
	-- but we don't want the input to be.
	local name
	for theme in next,Skins do
		if (string_lower(theme) == string_lower(requestedTheme)) then
			name = theme
			break
		end
	end
	if (not name or not Skins[name] or name == CURRENT_THEME) then return end

	local current, new = Skins[CURRENT_THEME], Skins[name]

	-- Disable unused custom elements.
	if (current.Elements) then
		for element,data in next,current.Elements do
			if (data) and (not new.Elements or not new.Elements[element]) then
				Elements[element]:SetParent(UIHider)
				if (ObjectSnippets[element]) then
					ObjectSnippets[element].Disable(Objects[element])
				end
			end
		end
	end

	-- Update Blizzard element visibility.
	for element,object in next,Objects do
		if (new.HideElements and new.HideElements[element]) then
			object:SetParent(UIHider)
			if (ObjectSnippets[element]) then
				ObjectSnippets[element].Disable(object)
			end
		else
			object:SetParent(ObjectOwners[element])
			if (ObjectSnippets[element]) then
				ObjectSnippets[element].Enable(object)
				ObjectSnippets[element].Update(object)
			end
		end
	end

	-- Set the minimap mask for the new theme.
	local mask = new.Shape and Shapes[new.Shape] or Shapes.Round
	Minimap:SetMaskTexture(mask)

	-- Enable new theme's custom elements.
	if (new.Elements) then
		for element,data in next,new.Elements do

			if (data) then

				-- Retrieve the owner of the object
				local owner = data and data.Owner and ObjectOwners[data.Owner] or Minimap

				-- Retrieve the object
				local object, objectParent = Elements[element]

				-- If a custom object does not exist, create it.
				if (not object) then

					-- Figure out what our custom object should be parented to.
					objectParent = data and data.Owner and Objects[data.Owner] or Minimap

					-- Create!
					if (ElementTypes[element] == "Texture") then
						object = objectParent:CreateTexture()
						Elements[element] = object
					end
				end

				-- Silently ignore non-supported objects.
				if (object) then

					object:SetParent(objectParent or owner)

					if (data.Size) then
						if (type(data.Size) == "function") then
							object:SetSize(data.Size())
						else
							object:SetSize(unpack(data.Size))
						end
					else
						object:SetSize(Minimap:GetSize())
					end

					if (data.Point) then
						object:ClearAllPoints()
						if (type(data.Point) == "function") then
							object:SetPoint(data.Point())
						else
							object:SetPoint(unpack(data.Point))
						end
					end

					if (ElementTypes[element] == "Texture") then
						object:SetTexture(data.Path)
						object:SetDrawLayer(data.DrawLayer or "ARTWORK", data.DrawLevel or 0)
						if (data.Color) then
							object:SetVertexColor(unpack(data.Color))
						else
							object:SetVertexColor(1, 1, 1, 1)
						end
					end

					-- Run object callbacks.
					if (ObjectSnippets[element]) then
						ObjectSnippets[element].Enable(Elements[element])
						ObjectSnippets[element].Update(Elements[element])
					end
				end
			end
		end
	end

	CURRENT_THEME = name

	-- Store the theme setting
	self.db.profile.theme = name

	-- Update custom element visibility
	self:UpdateCustomElements()
end

-- Minimap Widget Settings
--------------------------------------------
-- Create our custom elements
-- *This is a temporary and clunky measure,
--  eventually I want this baked into the themes,
--  including the position based visibility.
MinimapMod.CreateCustomElements = function(self)

	local db = ns.GetConfig("Minimap")

	local frame = CreateFrame("Frame", nil, Minimap)
	frame:SetFrameLevel(Minimap:GetFrameLevel())
	frame:SetAllPoints(Minimap)

	self.widgetFrame = frame

	-- Compass
	local compass = CreateFrame("Frame", nil, frame)
	compass:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	compass:SetPoint("TOPLEFT", db.CompassInset, -db.CompassInset)
	compass:SetPoint("BOTTOMRIGHT", -db.CompassInset, db.CompassInset)

	local north = compass:CreateFontString(nil, "ARTWORK", nil, 1)
	north:SetFontObject(db.CompassFont)
	north:SetTextColor(unpack(db.CompassColor))
	north:SetText(db.CompassNorthTag)
	compass.north = north

	self.compass = compass

	-- Coordinates
	local coordinates = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("MIDDLE")
	coordinates:SetFontObject(db.CoordinateFont)
	coordinates:SetTextColor(unpack(db.CoordinateColor))
	coordinates:SetPoint(unpack(db.CoordinatePlace))

	self.coordinates = coordinates

	-- Mail
	local mailFrame = CreateFrame("Button", nil, frame)
	mailFrame:SetFrameLevel(mailFrame:GetFrameLevel() + 5)
	mailFrame:SetScript("OnEnter", Mail_OnEnter)
	mailFrame:SetScript("OnLeave", Mail_OnLeave)

	local mail = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	mail.frame = mailFrame
	mail:SetFontObject(db.MailFont)
	mail:SetTextColor(unpack(db.MailColor))
	mail:SetJustifyH(db.MailJustifyH)
	mail:SetJustifyV(db.MailJustifyV)
	mail:SetFormattedText("%s", L_MAIL)
	mail:SetPoint(unpack(db.MailPosition))
	mailFrame:SetAllPoints(mail)

	self.mail = mail

	-- Addon Compartment
	if (ns.IsRetail) then
		local addonCompartment = self.Objects.Addons
		if (addonCompartment) then
			local addons = CreateFrame("DropdownButton", nil, Minimap)
			addons:SetPoint("BOTTOMRIGHT", -252, 43)
			addons:SetSize(16, 16)

			addons:SetupMenu(addonCompartment.menuGenerator)

			local addonsAnchor = AnchorUtil.CreateAnchor("BOTTOMRIGHT", addons, "TOPLEFT", 0, 0)
			addons:SetMenuAnchor(addonsAnchor)

			addons:SetScript("OnEnter", function(self)
				addons:SetAlpha(.95)

				if (GameTooltip:IsForbidden()) then return end

				GameTooltip_SetDefaultAnchor(GameTooltip, self)
				GameTooltip_SetTitle(GameTooltip, ADDONS)
				GameTooltip:Show()
			end)

			addons:SetScript("OnLeave", function(self)
				addons:SetAlpha(.5)

				if (GameTooltip:IsForbidden()) then return end

				GameTooltip:Hide()
			end)

			local addonsText = addons:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			addonsText:SetText(addonCompartment:GetText())
			addonsText:SetPoint("CENTER")
			addons:SetFontString(addonsText)
			addons.text = addonsText

			hooksecurefunc(addonCompartment, "UpdateDisplay", function(self)
				addonsText:SetText(self:GetText())
			end)

			addons:SetAlpha(.5)

			self.addonCompartment = addons
		end
	end

	local dropdown = LibDD:Create_UIDropDownMenu(ns.Prefix.."MiniMapTrackingDropDown", UIParent)
	dropdown:SetID(1)
	dropdown:SetClampedToScreen(true)
	dropdown:Hide()

	if (ns.IsClassic) then
		self.ShowMinimapTrackingMenu = function(self)
			local hasTracking
			local trackingMenu = { { text = TRACKING or "Select Tracking", isTitle = true, notCheckable = true } }
			for _,spellID in ipairs({
				1494, --Track Beasts
				19883, --Track Humanoids
				19884, --Track Undead
				19885, --Track Hidden
				19880, --Track Elementals
				19878, --Track Demons
				19882, --Track Giants
				19879, --Track Dragonkin
					5225, --Track Humanoids: Druid
					5500, --Sense Demons
					5502, --Sense Undead
					2383, --Find Herbs
					2580, --Find Minerals
					2481  --Find Treasure
			}) do
				if (IsPlayerSpell(spellID)) then
					hasTracking = true
					local tracking = GetTrackingTexture()
					local spellName = GetSpellInfo(spellID)
					local spellTexture = GetSpellTexture(spellID)
					table_insert(trackingMenu, {
						text = spellName,
						icon = spellTexture,
						checked = tracking == spellTexture,
						func = function() CastSpellByID(spellID) end,

					})
				end
			end
			if (hasTracking) then
				table_insert(trackingMenu, {
					text = OBJECTIVES_STOP_TRACKING,
					notCheckable = true,
					func = function() CancelTrackingBuff() end
				})
				EasyMenu(trackingMenu, dropdown, "cursor", 0 , 0, "MENU")
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
			end
		end
	else
		LibDD:UIDropDownMenu_Initialize(dropdown, MiniMapTrackingDropDown_Initialize, "MENU")
	end

	dropdown.noResize = true

	self.dropdown = dropdown

	self:UpdateCustomElements()
	self.CreateCustomElements = noop

end

-- Update the visibility of the custom elements
MinimapMod.UpdateCustomElements = function(self)
	if (not self.widgetFrame) then return end
	self.widgetFrame:SetShown(CURRENT_THEME == "Azerite")
end

MinimapMod.PostUpdatePositionAndScale = function(self)
	local config = self.db.profile.savedPosition

	self.widgetFrame:SetScale(ns.API.GetEffectiveScale() / config.scale)
	self:UpdateCustomElements()

	if (ns.IsRetail) then
		MinimapCluster.MinimapContainer:SetScale(1)
	end

	-- TODO: Figure out all the elements I should rescale.
	for name in next,{
		MiniMapBattlefieldFrame = true,
		MiniMapLFGFrame = true,
		QueueStatusButton = true
	} do
		local element = _G[name]
		if (element) then
			element:SetScale(ns.API.GetEffectiveScale() / config.scale)
		end
	end
end

MinimapMod.UpdateAnchor = function(self)
	if (not self.anchor) then return end

	if (self.PreUpdateAnchor) then
		if (self:PreUpdateAnchor()) then return end
	end

	local config = self.db.profile.savedPosition
	if (config) then
		local w,h = self.frame:GetSize()
		self.anchor:SetSize(w + (16*2*ns.API.GetEffectiveScale())/config.scale, h + (16*2*ns.API.GetEffectiveScale())/config.scale)
		self.anchor:SetScale(config.scale)
		self.anchor:ClearAllPoints()
		self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
	end

	if (self.PostUpdateAnchor) then
		self:PostUpdateAnchor()
	end
end

MinimapMod.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	if (InCombatLockdown()) then
		self.updateneeded = true
		return
	end

	self.updateneeded = nil

	local config = self.db.profile.savedPosition
	if (config) then

		local string_find = string.find

		local x = string_find(config[1], "LEFT") and 16*ns.API.GetEffectiveScale() or string_find(config[1], "RIGHT") and -16*ns.API.GetEffectiveScale() or 0
		local y = string_find(config[1], "TOP") and -16*ns.API.GetEffectiveScale() or string_find(config[1], "BOTTOM") and 16*ns.API.GetEffectiveScale() or 0

		self.frame:SetScale(config.scale)
		self.frame:ClearAllPoints()
		self.frame:SetPoint(config[1], UIParent, config[1], (x + config[2])/config.scale, (y + config[3])/config.scale)
	end

	if (self.PostUpdatePositionAndScale) then
		self:PostUpdatePositionAndScale()
	end
end

MinimapMod.UpdateSettings = function(self)
	self:SetTheme(self.db.profile.theme)
	self:UpdateCompass()
	self:UpdateMail()
	self:UpdateTimers()
	self:UpdateCustomElements()
end

MinimapMod.InitializeObjectTables = function(self)

	-- Minimap objects available for restyling.
	----------------------------------------------------
	if (ns.WoW10) then
		Objects.Addons = AddonCompartmentFrame
		Objects.BorderTop = MinimapCluster.BorderTop
		Objects.Calendar = GameTimeFrame
		Objects.Clock = TimeManagerClockButton
		Objects.Compass = MinimapCompassTexture
		Objects.Crafting = MinimapCluster.IndicatorFrame.CraftingOrderFrame
		Objects.Difficulty = MinimapCluster.InstanceDifficulty
		Objects.Expansion = ExpansionLandingPageMinimapButton
		Objects.Eye = QueueStatusButton
		Objects.Mail = MinimapCluster.IndicatorFrame.MailFrame
		Objects.Tracking = MinimapCluster.TrackingFrame
		--Objects.Tracking = MinimapCluster.Tracking
		Objects.Zone = MinimapCluster.ZoneTextButton
		Objects.ZoomIn = Minimap.ZoomIn
		Objects.ZoomOut = Minimap.ZoomOut
	end

	-- CATA: check
	if (ns.IsCata) then
		Objects.BorderTop = MinimapBorderTop
		Objects.BorderClassic = MinimapBorder
		Objects.Calendar = GameTimeFrame
		Objects.Clock = TimeManagerClockButton
		Objects.Compass = MinimapCompassTexture
		Objects.Difficulty = MiniMapInstanceDifficulty
		Objects.Eye = MiniMapLFGFrame
		Objects.EyeClassicPvP = MiniMapBattlefieldFrame
		Objects.Mail = MiniMapMailFrame
		Objects.Tracking = MiniMapTracking
		Objects.Zone = MinimapZoneTextButton
		Objects.ZoomIn = MinimapZoomIn
		Objects.ZoomOut = MinimapZoomOut
		Objects.WorldMap = MiniMapWorldMapButton
	end

	if (ns.IsClassic) then
		Objects.BorderTop = MinimapBorderTop
		Objects.BorderClassic = MinimapBorder
		Objects.Calendar = GameTimeFrame
		Objects.Clock = TimeManagerClockButton
		Objects.Compass = MinimapCompassTexture
		Objects.Difficulty = MiniMapInstanceDifficulty
		Objects.Eye = MiniMapLFGFrame
		Objects.EyeClassicPvP = MiniMapBattlefieldFrame
		Objects.Mail = MiniMapMailFrame
		Objects.ToggleButton = MinimapToggleButton
		Objects.Tracking = MiniMapTrackingFrame
		Objects.Zone = MinimapZoneTextButton
		Objects.ZoomIn = MinimapZoomIn
		Objects.ZoomOut = MinimapZoomOut
		Objects.WorldMap = MiniMapWorldMapButton
	end

	-- Object parents when using blizzard theme.
	----------------------------------------------------
	if (ns.WoW10) then
		ObjectOwners.Addons = MinimapCluster
		ObjectOwners.BorderTop = MinimapCluster
		ObjectOwners.Calendar = MinimapCluster
		ObjectOwners.Clock = MinimapCluster
		ObjectOwners.Compass = MinimapBackdrop
		ObjectOwners.Crafting = MinimapCluster.IndicatorFrame
		ObjectOwners.Difficulty = MinimapCluster
		ObjectOwners.Expansion = MinimapBackdrop
		ObjectOwners.Eye = MicroButtonAndBagsBar
		ObjectOwners.Mail = MinimapCluster.IndicatorFrame
		ObjectOwners.Tracking = MinimapCluster
		ObjectOwners.Zone = MinimapCluster
		ObjectOwners.ZoomIn = Minimap
		ObjectOwners.ZoomOut = Minimap
	end

	-- CATA: check
	if (ns.IsCata) then
		ObjectOwners.BorderTop = MinimapCluster
		ObjectOwners.BorderClassic = MinimapBackdrop
		ObjectOwners.Calendar = MinimapCluster
		ObjectOwners.Clock = MinimapCluster
		ObjectOwners.Compass = MinimapBackdrop
		ObjectOwners.Difficulty = MinimapCluster
		ObjectOwners.Expansion = MinimapBackdrop
		ObjectOwners.Eye = MinimapBackdrop
		ObjectOwners.EyeClassicPvP = Minimap
		ObjectOwners.Mail = Minimap
		ObjectOwners.Tracking = MinimapCluster
		ObjectOwners.Zone = MinimapCluster
		ObjectOwners.ZoomIn = Minimap
		ObjectOwners.ZoomOut = Minimap
		ObjectOwners.WorldMap = MinimapBackdrop
	end

	if (ns.IsClassic) then
		ObjectOwners.BorderTop = MinimapCluster
		ObjectOwners.BorderClassic = MinimapBackdrop
		ObjectOwners.Calendar = MinimapCluster
		ObjectOwners.Clock = MinimapCluster
		ObjectOwners.Compass = MinimapBackdrop
		ObjectOwners.Difficulty = MinimapCluster
		ObjectOwners.Expansion = MinimapBackdrop
		ObjectOwners.Eye = MinimapBackdrop
		ObjectOwners.EyeClassicPvP = Minimap
		ObjectOwners.Mail = Minimap
		ObjectOwners.ToggleButton = MinimapCluster
		ObjectOwners.Tracking = Minimap
		ObjectOwners.Zone = MinimapCluster
		ObjectOwners.ZoomIn = Minimap
		ObjectOwners.ZoomOut = Minimap
		ObjectOwners.WorldMap = MinimapBackdrop
	end

end

MinimapMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED") then
		self:UpdateAnchor()
		self:UpdateSettings()
	end
end

MinimapMod.OnEnable = function(self)
	LoadAddOn("Blizzard_TimeManager")

	-- Clean out deprecated settings
	self.db.profile.useHalfClock = nil
	self.db.profile.useServerTime = nil

	self:InitializeObjectTables()

	if (ns.WoW10) then
		MinimapCluster.HighlightSystem = ns.Noop
		MinimapCluster.ClearHighlight = ns.Noop
	end

	MinimapCluster:EnableMouse(false)
	MinimapCluster:SetFrameLevel(1)

	self.frame = Minimap
	self.frame:SetMovable(true)
	self.frame:EnableMouseWheel(true)
	self.frame:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
	self.frame:SetScript("OnMouseUp", Minimap_OnMouseUp)

	if (ns.IsRetail) then
		self.frame:SetArchBlobRingScalar(0)
		self.frame:SetQuestBlobRingScalar(0)
	end

	self:CreateCustomElements()
	self:CreateAnchor(MINIMAP_LABEL):SetDefaultScale(mapScale * ns.API.GetEffectiveScale())

	ns.MovableModulePrototype.OnEnable(self)

	self:RegisterEvent("CVAR_UPDATE", "UpdateTimers")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")

	if (ns.WoW10) then
		self:RegisterEvent("CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS", "UpdateMail")
	end

	self:RegisterChatCommand("setminimaptheme", "SetMinimapTheme")

	self:InitializeAddon("MBB")
	self:InitializeAddon("Narcissus")
end
