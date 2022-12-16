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
local MinimapMod = ns:NewModule("Minimap", "LibMoreEvents-1.0", "AceHook-3.0", "AceTimer-3.0", "AceConsole-3.0")

LoadAddOn("Blizzard_TimeManager")

-- Lua API
local next = next
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local UIHider = ns.Hider

local defaults = { profile = ns:Merge({
	enabled = true,
	theme = "Azerite"
}, ns.moduleDefaults) }

local DEFAULT_THEME = "Blizzard"
local CURRENT_THEME = DEFAULT_THEME

local Elements = {}

local Objects = {
	BorderTop = MinimapCluster.BorderTop,
	Calendar = GameTimeFrame,
	Clock = TimeManagerClockButton,
	Compass = MinimapCompassTexture,
	Difficulty = MinimapCluster.InstanceDifficulty,
	Expansion = ExpansionLandingPageMinimapButton,
	Mail = MinimapCluster.MailFrame,
	Tracking = MinimapCluster.Tracking,
	Zone = MinimapCluster.ZoneTextButton,
	ZoomIn = Minimap.ZoomIn,
	ZoomOut = Minimap.ZoomOut
}

local ObjectOwners = {
	BorderTop = MinimapCluster,
	Calendar = MinimapCluster,
	Clock = MinimapCluster,
	Compass = MinimapBackdrop,
	Difficulty = MinimapCluster,
	Expansion = MinimapBackdrop,
	Mail = MinimapCluster,
	Tracking = MinimapCluster,
	Zone = MinimapCluster,
	ZoomIn = Minimap,
	ZoomOut = Minimap
}

local ElementTypes = {
	Backdrop = "Texture",
	Border = "Texture"
}

local Shapes = {
	Round = GetMedia("minimap-mask-opaque"),
	RoundTransparent = GetMedia("minimap-mask-transparent")
}

local Skins = {
	Blizzard = {
		Version = 1,
		Shape = "Round"
	},
	Azerite = {
		Version = 1,
		Shape = "RoundTransparent",
		HideElements = {
			BorderTop = true,
			Calendar = true,
			Clock = true,
			Compass = true,
			Difficulty = true,
			Expansion = true,
			Mail = true,
			Tracking = true,
			Zone = true,
			ZoomIn = true,
			ZoomOut = true
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
			}
		}
	}
}

local Prototype = {}

Prototype.RegisterTheme = function(self, name, skin)
	if (Skins[name] or name == DEFAULT_THEME) then return end
	Skins[name] = skin
end

Prototype.SetTheme = function(self, requestedTheme)

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

	-- Disable unused elements.
	if (current.Elements) then
		for element,data in next,current.Elements do
			if (not new.Elements or not new.Elements[element]) then
				Elements[element]:SetParent(UIHider)
			end
		end
	end

	-- Update Blizzard element visibility.
	for element,object in next,Objects do
		object:SetParent(new.HideElements and new.HideElements[element] and UIHider or ObjectOwners[element])
	end

	local mask = new.Shape and Shapes[new.Shape] or Shapes.Round
	Minimap:SetMaskTexture(mask)

	-- Show new theme's elements.
	if (new.Elements) then
		for element,data in next,new.Elements do

			local owner = data.Owner and ObjectOwners[data.Owner] or Minimap
			local object = Elements[element]
			if (not object) then
				if (ElementTypes[element] == "Texture") then
					object = owner:CreateTexture()
					Elements[element] = object
				end
			end

			-- Silently ignore non-supported objects.
			if (object) then

				object:SetParent(owner)

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

			end
		end
	end

	CURRENT_THEME = name

	-- Store the theme setting
	MinimapMod.db.profile.theme = name
end

MinimapMod.SetMinimapTheme = function(self, input)
	Minimap:SetTheme((self:GetArgs(string.lower(input))))
end

MinimapMod.Embed = function(self)
	for method,func in next,Prototype do
		_G.Minimap[method] = func
	end
end

MinimapMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Minimap", defaults)
	self:SetEnabledState(self.db.profile.enabled)
	self:Embed()
	self:RegisterChatCommand("setminimaptheme", "SetMinimapTheme")
end

MinimapMod.OnEnable = function(self)
	Minimap:SetTheme(self.db.profile.theme)
end
