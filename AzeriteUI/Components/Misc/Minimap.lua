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

LoadAddOn("Blizzard_TimeManager")

local MinimapMod = ns:NewModule("Minimap", "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0", "AceConsole-3.0")
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local ipairs = ipairs
local math_abs = math.abs
local math_cos = math.cos
local math_floor = math.floor
local math_pi = math.pi
local half_pi = math_pi/2
local math_sin = math.sin
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local string_match = string.match
local string_upper = string.upper
local table_insert = table.insert
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local GetTime = ns.API.GetTime
local GetLocalTime = ns.API.GetLocalTime
local GetServerTime = ns.API.GetServerTime
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider
local noop = ns.Noop

-- WoW Strings
local L_RESTING = TUTORIAL_TITLE30 -- "Resting"
local L_NEW = NEW -- "New"
local L_MAIL = MAIL_LABEL -- "Mail"
local L_HAVE_MAIL = HAVE_MAIL -- "You have unread mail"
local L_HAVE_MAIL_FROM = HAVE_MAIL_FROM -- "Unread mail from:"
local L_FPS = string_upper(string_match(FPS_ABBR, "^.")) -- "fps"
local L_HOME = string_upper(string_match(HOME, "^.")) -- "Home"
local L_WORLD = string_upper(string_match(WORLD, "^.")) -- "World"

-- Constants
local TORGHAST_ZONE_ID = 2162
local IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

local defaults = { profile = ns:Merge({
	enabled = true,
	theme = "Azerite",
	useHalfClock = true,
	useServerTime = false,

}, ns.moduleDefaults) }
if (not ns.IsRetail) then
	defaults.profile.savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOMRIGHT",
			[2] = -20,
			[3] = 20
		}
	}
end

local DEFAULT_THEME = "Blizzard"
local CURRENT_THEME = DEFAULT_THEME

local Elements = {}

-- Minimap objects available for restyling.
----------------------------------------------------
local Objects = { Calendar = GameTimeFrame, Clock = TimeManagerClockButton, Compass = MinimapCompassTexture }
if (ns.IsRetail) then
	Objects.BorderTop = MinimapCluster.BorderTop
	Objects.Difficulty = MinimapCluster.InstanceDifficulty
	Objects.Expansion = ExpansionLandingPageMinimapButton
	Objects.Eye = QueueStatusButton
	Objects.Mail = MinimapCluster.IndicatorFrame.MailFrame
	Objects.Tracking = MinimapCluster.Tracking
	Objects.Zone = MinimapCluster.ZoneTextButton
	Objects.ZoomIn = Minimap.ZoomIn
	Objects.ZoomOut = Minimap.ZoomOut
end
if (ns.IsWrath) then
	Objects.BorderTop = MinimapBorderTop
	Objects.BorderClassic = MinimapBorder
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
local ObjectOwners = {}
if (ns.IsRetail) then
	ObjectOwners.BorderTop = MinimapCluster
	ObjectOwners.Calendar = MinimapCluster
	ObjectOwners.Clock = MinimapCluster
	ObjectOwners.Compass = MinimapBackdrop
	ObjectOwners.Difficulty = MinimapCluster
	ObjectOwners.Expansion = MinimapBackdrop
	ObjectOwners.Eye = MicroButtonAndBagsBar
	ObjectOwners.Mail = MinimapCluster.IndicatorFrame
	ObjectOwners.Tracking = MinimapCluster
	ObjectOwners.Zone = MinimapCluster
	ObjectOwners.ZoomIn = Minimap
	ObjectOwners.ZoomOut = Minimap
end
if (ns.IsWrath) then
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

-- Snippets to be run upon object toggling.
----------------------------------------------------
local ObjectSnippets = {

	-- Blizzard Objects
	------------------------------------------
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
			if (ns.IsWrath) then
				object:SetFrameLevel(object:GetParent():GetFrameLevel() + 2)
			elseif (ns.IsRetail) then
			end
		end,
		Disable = function(object)
			if (ns.IsWrath) then
			elseif (ns.IsRetail) then
			end
		end,
		Update = function(object)
			if (ns.IsWrath) then
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
			if (ns.IsWrath) then
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
			if (ns.IsWrath) then
				MiniMapLFGFrame:SetParent(ObjectOwners.Eye)
				MiniMapLFGFrame:SetFrameLevel(MinimapBackdrop:GetFrameLevel() + 2)
				MiniMapLFGFrame:ClearAllPoints()
				MiniMapLFGFrame:SetPoint("TOPLEFT", 25, -100)
				MiniMapLFGFrame:SetHitRectInsets(0, 0, 0, 0)
				MiniMapLFGFrameBorder:Show()
				MiniMapLFGFrameIcon:Show()
			elseif (ns.IsRetail) then
				QueueStatusButton:SetParent(ObjectOwners.Eye)
				QueueStatusButton:SetFrameLevel(ObjectOwners.Eye:GetFrameLevel() + 1)
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
			MiniMapBattlefieldFrame:ClearAllPoints()
			MiniMapBattlefieldFrame:SetPoint("BOTTOMLEFT", Minimap, 4, 2)
			MiniMapBattlefieldFrame:SetHitRectInsets(-8, -8, -8, -8)
			MiniMapBattlefieldIcon:Hide()
			MiniMapBattlefieldBorder:Hide()
			BattlegroundShine:Hide()
			if (BattlefieldIconText) then BattlefieldIconText:Hide() end
		end,
		Disable = function(object)
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
	Azerite = {
		Version = 1,
		Shape = "RoundTransparent",
		HideElements = {
			BattleField = false, -- classic + wrath
			BorderTop = true,
			BorderClassic = true, -- wrath
			Calendar = true,
			Clock = true,
			Compass = true,
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
				Size = { 198, 198 },
				Point = { "CENTER" },
				Color = { 0, 0, 0, .75 },
			},
			Border = {
				Owner = "Backdrop",
				DrawLayer = "BORDER",
				DrawLevel = 1,
				Path = GetMedia("minimap-border"),
				Size = { 404, 404 },
				Point = { "CENTER", -1, 0 },
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
			AzeriteEyeClassicPvP = (ns.IsClassic or ns.IsWrath) and {
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

-- Just a temporary measure,
-- will eventually move all into the skins.
local Unskinned = {

	CompassInset = 14,
	CompassFont = GetFont(16,true),
	CompassColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 },
	CompassNorthTag = "N",

	CoordinateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
	CoordinateFont = GetFont(12, true),
	CoordinatePlace = { "BOTTOM", 3, 23 },

	ClockPosition = { "BOTTOMRIGHT", -226, -8 },
	ClockFont = GetFont(15,true),
	ClockColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },

	-- About 8px to the left of the clock.
	ZoneTextPosition = { "BOTTOMRIGHT", -(226 + 60), -8 }, -- adjust this
	ZoneTextPositionHalfClock = { "BOTTOMRIGHT", -(226 + 60 + 20), -8 }, -- adjust this
	ZoneTextFont = GetFont(15,true),
	ZoneTextAlpha = .85,

	-- About 6px Above the clock, slightly indented towards the left.
	FrameRatePosition = { "BOTTOMRIGHT", -(226 + 6), -8 + 15 + 6 },
	FrameRateFont = GetFont(12,true),
	FrameRateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

	-- To the left of the framerate, right above the zone text.
	LatencyPosition = { "BOTTOMRIGHT", -(226 + 60), -8 + 15 + 6 }, -- adjust this
	LatencyPositionHalfClock = { "BOTTOMRIGHT", -(226 + 60 + 20), -8 + 15 + 6 }, -- adjust this
	LatencyFont = GetFont(12,true),
	LatencyColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

	MailPosition = { "BOTTOM", 0, 30 },
	MailJustifyH = "CENTER",
	MailJustifyV = "MIDDLE",
	MailFont = GetFont(15, true),
	MailColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .85 },

	-- Dungeon Eye
	EyePosition = { "CENTER", math.cos(225*(math.pi/180)) * (280/2 + 10), math.sin(225*(math.pi/180)) * (280/2 + 10) },
	EyeSize = { 64, 64 },
	EyeTexture = GetMedia("group-finder-eye-green"),
	EyeTextureColor = { .90, .95, 1 },
	EyeTextureSize = { 64, 64 },
	EyeGroupSizePosition = { "BOTTOMRIGHT", 0, 0 },
	EyeGroupSizeFont = GetFont(15,true),
	EyeGroupStatusFramePosition = { "TOPRIGHT", QueueStatusMinimapButton, "BOTTOMLEFT", 0, 0 },
}

-- Theme Prototype
--------------------------------------------
local Prototype = {}

Prototype.RegisterTheme = function(self, name, skin)
	if (Skins[name] or name == DEFAULT_THEME) then return end
	Skins[name] = skin
end

Prototype.SetTheme = function(self, requestedTheme)
	if (InCombatLockdown()) then return end

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
						object:SetSize(unpack(data.Size))
					else
						object:SetSize(Minimap:GetSize())
					end

					if (data.Point) then
						object:ClearAllPoints()
						object:SetPoint(unpack(data.Point))
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
	MinimapMod.db.profile.theme = name

	-- Update custom element visibility
	MinimapMod:UpdateCustomElements()
end

-- Element Callbacks
--------------------------------------------
local getTimeStrings = function(h, m, suffix, useHalfClock, abbreviateSuffix)
	if (useHalfClock) then
		return "%.0f:%02.0f |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
	else
		return "%02.0f:%02.0f", h, m
	end
end

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

	GameTooltip:Show()
end

local Mail_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local useHalfClock = MinimapMod.db.profile.useHalfClock -- the outlandish 12 hour clock the colonials seem to favor so much
	local lh, lm, lsuffix = GetLocalTime(useHalfClock) -- local computer time
	local sh, sm, ssuffix = GetServerTime(useHalfClock) -- realm time
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, unpack(Colors.title))
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, lsuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ssuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddLine("<"..GAMETIME_TOOLTIP_TOGGLE_CALENDAR..">", unpack(Colors.quest.green))
	GameTooltip:Show()
end

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end

local Time_OnLeave = function(self)
	self.UpdateTooltip = nil
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_OnClick = function(self, mouseButton)
	if (ToggleCalendar) and (not InCombatLockdown()) then
		ToggleCalendar()
	end
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

MinimapMod.UpdatePerformance = function(self)

	local now = GetTime()
	local fps = GetFramerate()
	local world, home, _

	if (not self.latency.nextUpdate) or (now >= self.latency.nextUpdate) then
		-- latencyHome: chat, auction house, some addon data
		-- latencyWorld: combat, data from people around you(specs, gear, enchants, etc.), NPCs, mobs, casting, professions
		_, _, home, world = GetNetStats()
		self.latency.nextUpdate = now + 30
		self.latency.latencyWorld = world
	else
		world = self.latency.latencyWorld
	end

	if (fps and fps > 0) then
		self.fps:SetFormattedText("|cff888888%.0f %s|r", fps, L_FPS)
	else
		self.fps:SetText("")
	end

	if (home and home > 0 and world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f - |cff888888%s|r %.0f", L_HOME, home, L_WORLD, world)
	elseif (world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f", L_WORLD, world)
	else
		self.latency:SetText("")
	end

end

MinimapMod.UpdateClock = function(self)
	local time = self.time
	if (not time) then return end
	local db = Unskinned
	if (self.db.profile.useServerTime) then
		if (self.db.profile.useHalfClock) then
			time:SetFormattedText("%.0f:%02.0f |cff888888%s|r", GetServerTime(true))

			if (not time.useHalfClock) then
				time.useHalfClock = true
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPositionHalfClock))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPositionHalfClock))
			end
		else
			time:SetFormattedText("%02.0f:%02.0f", GetServerTime(false))

			if (time.useHalfClock) then
				time.useHalfClock = nil
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPosition))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPosition))
			end
		end
	else
		if (self.db.profile.useHalfClock) then
			time:SetFormattedText("%.0f:%02.0f |cff888888%s|r", GetLocalTime(true))

			if (not time.useHalfClock) then
				time.useHalfClock = true
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPositionHalfClock))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPositionHalfClock))
			end

		else
			time:SetFormattedText("%02.0f:%02.0f", GetLocalTime(false))

			if (time.useHalfClock) then
				time.useHalfClock = nil
				self.zoneName:ClearAllPoints()
				self.zoneName:SetPoint(unpack(db.ZoneTextPosition))
				self.latency:ClearAllPoints()
				self.latency:SetPoint(unpack(db.LatencyPosition))
			end
		end
	end
end

MinimapMod.UpdateMail = function(self)
	local mail = self.mail
	if (not mail) then
		return
	end
	local hasMail = HasNewMail()
	if (hasMail) then
		mail:Show()
		mail.frame:Show()
	else
		mail:Hide()
		mail.frame:Hide()
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
	if (not self.performanceTimer) then
		self.performanceTimer = self:ScheduleRepeatingTimer("UpdatePerformance", 1)
		self:UpdatePerformance()
	end
	if (not self.clockTimer) then
		self.clockTimer = self:ScheduleRepeatingTimer("UpdateClock", 1)
		self:UpdateClock()
	end
end

MinimapMod.UpdateZone = function(self)
	local zoneName = self.zoneName
	if (not zoneName) then
		return
	end
	local a = zoneName:GetAlpha() -- needed to preserve alpha after text color changes
	local minimapZoneName = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	if (pvpType) then
		local color = Colors.zone[pvpType]
		if (color) then
			zoneName:SetTextColor(color[1], color[2], color[3], a)
		else
			zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
		end
	else
		zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
	end
	zoneName:SetText(minimapZoneName)
end

-- Addon Styling
--------------------------------------------
MinimapMod.InitializeMBB = function(self)

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
		local p, a, rp, x, y = self:GetPoint()
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

MinimapMod.InitializeAddon = function(self, addon, ...)
	if (addon == "ADDON_LOADED") then
		addon = ...
	end
	if (not self.Addons[addon]) then
		return
	end
	local method = self["Initialize"..addon]
	if (method) then
		method(self)
	end
	self.Addons[addon] = nil
end

-- Module Theme API (really...?)
--------------------------------------------
MinimapMod.SetMinimapTheme = function(self, input)
	if (InCombatLockdown()) then return end
	local theme = self:GetArgs(string.lower(input))
	if (not ns.IsRetail and theme == "Blizzard") then
		theme = "Azerite"
	end
	Minimap:SetTheme(theme)
end

-- Minimap Widget Settings
--------------------------------------------
MinimapMod.SetClock = function(self, input)
	local args = { self:GetArgs(string_lower(input)) }
	for _,arg in ipairs(args) do
		if (arg == "24") then
			self.db.profile.useHalfClock = false
		elseif (arg == "12") then
			self.db.profile.useHalfClock = true
		elseif (arg == "realm") then
			self.db.profile.useServerTime = true
		elseif (arg == "local") then
			self.db.profile.useServerTime = false
		end
	end
end

-- Create our custom elements
-- *This is a temporary and clunky measure,
--  eventually I want this baked into the themes,
--  including the position based visibility.
MinimapMod.CreateCustomElements = function(self)

	local db = Unskinned

	local frame = CreateFrame("Frame", nil, Minimap)
	frame:SetFrameLevel(Minimap:GetFrameLevel())
	frame:SetAllPoints(Minimap)

	self.widgetFrame = frame

	-- Zone Text
	local zoneName = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	zoneName:SetFontObject(db.ZoneTextFont)
	zoneName:SetAlpha(db.ZoneTextAlpha)
	zoneName:SetPoint(unpack(db.ZoneTextPosition))
	zoneName:SetJustifyH("CENTER")
	zoneName:SetJustifyV("MIDDLE")

	self.zoneName = zoneName

	-- Latency Text
	local latency = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	latency:SetFontObject(db.LatencyFont)
	latency:SetTextColor(unpack(db.LatencyColor))
	latency:SetPoint(unpack(db.LatencyPosition))
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("MIDDLE")

	self.latency = latency

	-- Framerate Text
	local fps = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	fps:SetFontObject(db.FrameRateFont)
	fps:SetTextColor(unpack(db.FrameRateColor))
	fps:SetPoint(unpack(db.FrameRatePosition))
	fps:SetJustifyH("CENTER")
	fps:SetJustifyV("MIDDLE")

	self.fps = fps

	-- Time Text
	local time = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	time:SetJustifyH("CENTER")
	time:SetJustifyV("MIDDLE")
	time:SetFontObject(db.ClockFont)
	time:SetTextColor(unpack(db.ClockColor))
	time:SetPoint(unpack(db.ClockPosition))

	local timeFrame = CreateFrame("Button", nil, frame)
	timeFrame:SetScript("OnEnter", Time_OnEnter)
	timeFrame:SetScript("OnLeave", Time_OnLeave)
	timeFrame:SetScript("OnClick", Time_OnClick)
	timeFrame:RegisterForClicks("AnyUp")
	timeFrame:SetAllPoints(time)

	self.time = time

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
	mail:SetFormattedText("%s %s", L_NEW, L_MAIL)
	mail:SetPoint(unpack(db.MailPosition))
	mailFrame:SetAllPoints(mail)

	self.mail = mail

	local dropdown = CreateFrame("Frame", ns.Prefix.."MiniMapTrackingDropDown", UIParent, "UIDropDownMenuTemplate")
	dropdown:SetID(1)
	dropdown:SetClampedToScreen(true)
	dropdown:Hide()

	if (ns.IsClassic) then
		self.ShowMinimapTrackingMenu = function(self)
			local hasTracking
			local trackingMenu = { { text = TRACKING or "Select Tracking", isTitle = true } }
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
					local spellName = GetSpellInfo(spellID)
					local spellTexture = GetSpellTexture(spellID)
					table_insert(trackingMenu, {
						text = spellName,
						icon = spellTexture,
						func = function() CastSpellByID(spellID) end
					})
				end
			end
			if (hasTracking) then
				EasyMenu(trackingMenu, dropdown, "cursor", 0 , 0, "MENU")
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
			end
		end
	else
		UIDropDownMenu_Initialize(dropdown, MiniMapTrackingDropDown_Initialize, "MENU")
	end

	dropdown.noResize = true

	self.dropdown = dropdown

	if (EditModeManagerFrame) then
		self:SecureHook(EditModeManagerFrame, "EnterEditMode", "UpdateCustomElements")
		self:SecureHook(EditModeManagerFrame, "ExitEditMode", "UpdateCustomElements")
		self:SecureHook(EditModeManagerFrame, "OnAccountSettingChanged", "UpdateCustomElements")
	end

	self:UpdateCustomElements()
	self.CreateCustomElements = noop

end

-- Update the visibility of the custom elements
-- *This is based on minimap position.
MinimapMod.UpdateCustomElements = function(self)
	if (not self.widgetFrame) then return end
	if (CURRENT_THEME ~= "Azerite") then
		return self.widgetFrame:Hide()
	end
	if (not ns.IsRetail) then
		self.widgetFrame:SetShown(self.anchor:IsInDefaultPosition(60))
	else
		local anchorInfo = ns:GetModule("EditMode"):GetDefaultSystems()[Enum.EditModeSystem.Minimap].anchorInfo
		local point, anchor, rpoint, x, y = MinimapCluster:GetPoint()
		local point2, x2, y2 = anchorInfo.point, anchorInfo.offsetX, anchorInfo.offsetY
		self.widgetFrame:SetShown(((point == point2) and (math_abs(x - x2) < 60) and (math_abs(y - y2) < 60)))
	end
end

-- Embed theme methods into the Minimap.
-- *Might have to stop doing this if it taints.
MinimapMod.Embed = function(self)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
	Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp)

	for method,func in next,Prototype do
		_G.Minimap[method] = func
	end
end

-- Classic API
--------------------------------------------
MinimapMod.UpdatePosition = function(self)
	if (ns.IsRetail) then return end
	Minimap:SetMovable(true)
end

MinimapMod.UpdateSize = function(self)
	if (ns.IsRetail) then return end
	Minimap:SetSize(213,213)
end

-- Module Initialization & Events
--------------------------------------------
MinimapMod.OnEvent = function(self, event)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UpdateSize()
		self:UpdatePosition()
		self:UpdateZone()
		self:UpdateMail()
		self:UpdateTimers()
		self:UpdateCustomElements()

	elseif (event == "VARIABLES_LOADED") then
		self:UpdateSize()
		self:UpdatePosition()
		self:UpdateTimers()
		self:UpdateCustomElements()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			self:UpdateTimers()
		end

	elseif (event == "EDIT_MODE_LAYOUTS_UPDATED") then
		self:UpdateCustomElements()
	end
end

MinimapMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Minimap", defaults)

	-- This theme only works for retail currently.
	if (not ns.IsRetail and self.db.profile.theme == "Blizzard") then
		self.db.profile.theme = "Azerite"
	end

	self:SetEnabledState(self.db.profile.enabled)
	self:Embed()
	self:CreateCustomElements()

	if (self.InitializeMovableFrameAnchor) then
		self:InitializeMovableFrameAnchor()
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("CVAR_UPDATE", "UpdateTimers")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:RegisterEvent("ZONE_CHANGED", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZone")

	self:RegisterChatCommand("setclock", "SetClock")
	self:RegisterChatCommand("setminimaptheme", "SetMinimapTheme")

	self.Addons = {}

	local addons, queued = { "MBB", "Narcissus" }
	for _,addon in ipairs(addons) do
		if (IsAddOnEnabled(addon)) then
			self.Addons[addon] = true
			if (IsAddOnLoaded(addon)) then
				self:InitializeAddon(addon)
			else
				-- Forcefully load addons
				-- *This helps work around an issue where
				--  Narcissus can bug out when started in combat.
				LoadAddOn(addon)
				self:InitializeAddon(addon)
			end
		end
	end
end

MinimapMod.OnEnable = function(self)
	if (not ns.IsRetail) then
		self:UpdateSize()
		self:UpdatePosition()
	end
	self:SetMinimapTheme(self.db.profile.theme)
end

-- Movable Frames (Classics)
--------------------------------------------
if (ns.IsRetail) then return end

MinimapMod.InitializeMovableFrameAnchor = function(self)

	self.frame = Minimap

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(MINIMAP_LABEL)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(240, 240)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "CENTER"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

MinimapMod.UpdatePositionAndScale = function(self)

	local savedPosition = self.currentLayout and self.db.profile.savedPosition[self.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local frame = self.frame
		local anchor = self.anchor

		-- Set the scale before positioning,
		-- or everything will be wonky.
		frame:SetScale(scale * ns.API.GetDefaultElementScale())

		if (anchor and anchor.framePoint) then
			-- Position the frame at the anchor,
			-- with the given point and offsets.
			frame:ClearAllPoints()
			frame:SetPoint(anchor.framePoint, anchor, anchor.framePoint, (anchor.frameOffsetX or 0)/scale, (anchor.frameOffsetY or 0)/scale)

			-- Parse where this actually is relative to UIParent
			local point, x, y = ns.API.GetPosition(frame)

			-- Reposition the frame relative to UIParent,
			-- to avoid it being hooked to our anchor in combat.
			frame:ClearAllPoints()
			frame:SetPoint(point, UIParent, point, x, y)
		end
	end
	self:UpdateCustomElements()
end

MinimapMod.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = self.db.profile.savedPosition
	local lockdown = InCombatLockdown()

	if (reason == "LayoutDeleted") then
		if (savedPosition[layoutName]) then
			savedPosition[layoutName] = nil
		end

	elseif (reason == "LayoutsUpdated") then

		if (savedPosition[layoutName]) then

			self.anchor:SetScale(savedPosition[layoutName].scale or self.anchor:GetScale())
			self.anchor:ClearAllPoints()
			self.anchor:SetPoint(unpack(savedPosition[layoutName]))

			local defaultPosition = defaults.profile.savedPosition[layoutName]
			if (defaultPosition) then
				self.anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			self.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not self.initialPositionSet) then
				--print("setting default position for", layoutName, self.frame:GetName())

				local defaultPosition = defaults.profile.savedPosition.Azerite

				self.anchor:SetScale(defaultPosition.scale)
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(unpack(defaultPosition))
				self.anchor:SetDefaultPosition(unpack(defaultPosition))

				self.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPosition[layoutName] = { self.anchor:GetPosition() }
			savedPosition[layoutName].scale = self.anchor:GetScale()
		end

		self.currentLayout = layoutName

		self:UpdatePositionAndScale()

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPosition[layoutName] = { point, x, y }
		savedPosition[layoutName].scale = self.anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		--if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		--end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.


	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end