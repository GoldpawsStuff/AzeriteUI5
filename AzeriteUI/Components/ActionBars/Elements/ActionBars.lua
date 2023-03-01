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

local ActionBarMod = ns:NewModule("ActionBars", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "AceConsole-3.0", "AceTimer-3.0")
local LAB_Name = "LibActionButton-1.0-GE"
local LAB, LAB_Version = LibStub(LAB_Name)
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local next = next
local string_format = string.format
local string_lower = string.lower
local tonumber = tonumber

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

-- Just not there in Wrath
local IsSpellOverlayed = IsSpellOverlayed or function() end

-- Return blizzard barID by barnum.
local BAR_TO_ID = {
	[1] = 1,
	[2] = BOTTOMLEFT_ACTIONBAR_PAGE,
	[3] = BOTTOMRIGHT_ACTIONBAR_PAGE,
	[4] = RIGHT_ACTIONBAR_PAGE,
	[5] = LEFT_ACTIONBAR_PAGE
}
if (ns.IsRetail) then
	BAR_TO_ID[6] = MULTIBAR_5_ACTIONBAR_PAGE
	BAR_TO_ID[7] = MULTIBAR_6_ACTIONBAR_PAGE
	BAR_TO_ID[8] = MULTIBAR_7_ACTIONBAR_PAGE
end

local ID_TO_BAR = {}
for i,j in pairs(BAR_TO_ID) do ID_TO_BAR[j] = i end

local barDefaults = {
	["**"] = ns:Merge({
	}, ns.ActionBar.defaults),
	[1] = { --[[ primary action bar ]]
		numbuttons = 8,
		layout = "map",
		maptype = "azerite",
		visibility = {
			dragon = true,
			possess = true,
			overridebar = true,
			vehicleui = true
		},
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "BOTTOMLEFT",
				[2] = 60,
				[3] = 42
			}
		}
	},
	[2] = { --[[ bottomleft multibar ]]
		enabled = enabled,
		numbuttons = 8,
		layout = "map",
		maptype = "horizontal",
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "BOTTOMLEFT",
				[2] = 780,
				[3] = 42
			}
		}
	},
	[3] = { --[[ bottomright multibar ]]
		enabled = enabled,
		numbuttons = 8,
		layout = "map",
		maptype = "horizontal",
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "RIGHT",
				[2] = -40,
				[3] = 0
			}
		}
	},
	[4] = { --[[ right multibar 1 ]]
		enabled = enabled,
		numbuttons = 8,
		layout = "map",
		maptype = "horizontal",
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "RIGHT",
				[2] = -(40 + 10 + 72*2),
				[3] = 0
			}
		}
	},
	[5] = { --[[ right multibar 2 ]]
		enabled = false,
		grid = {
			breakpoint = 6,
			growth = "vertical",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
		},
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "RIGHT",
				[2] = -(40 + 10 + 72*2 + 10 + 72*2),
				[3] = 0
			}
		}
	}
}
if (ns.IsRetail) then
	barDefaults[6] = { --[[]]
		enabled = false,
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "CENTER",
				[2] = 0,
				[3] = 72 + 10
			}
		}
	}
	barDefaults[7] = { --[[]]
		enabled = false,
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "CENTER",
				[2] = 0,
				[3] = 0
			}
		}
	}
	barDefaults[8] = { --[[]]
		enabled = false,
		savedPosition = {
			Azerite = {
				scale = 1,
				[1] = "CENTER",
				[2] = 0,
				[3] = -(72 + 10)
			}
		}
	}
end

local defaults = { profile = ns:Merge({
	enabled = true,
	enableBarFading = false,
	bars = barDefaults
}, ns.moduleDefaults) }

local config = {

	ButtonSize = { 64, 64 },
	ButtonHitRects =  { -10, -10, -10, -10 },
	ButtonMaskTexture = GetMedia("actionbutton-mask-circular"),

	ButtonBackdropPosition = { "CENTER", 0, 0 },
	ButtonBackdropSize = { 134.295081967, 134.295081967 },
	ButtonBackdropTexture = GetMedia("actionbutton-backdrop"),
	ButtonBackdropColor = { .67, .67, .67, 1 },

	ButtonIconPosition = { "CENTER", 0, 0 },
	ButtonIconSize = { 44, 44 },

	ButtonKeybindPosition = { "TOPLEFT", -5, -5 },
	ButtonKeybindJustifyH = "CENTER",
	ButtonKeybindJustifyV = "BOTTOM",
	ButtonKeybindFont = GetFont(15, true),
	ButtonKeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	ButtonCountPosition = { "BOTTOMRIGHT", -3, 3 },
	ButtonCountJustifyH = "CENTER",
	ButtonCountJustifyV = "BOTTOM",
	ButtonCountFont = GetFont(18, true),
	ButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },

	ButtonCooldownCountPosition = { "CENTER", 1, 0 },
	ButtonCooldownCountJustifyH = "CENTER",
	ButtonCooldownCountJustifyV = "MIDDLE",
	ButtonCooldownCountFont = GetFont(16, true),
	ButtonCooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	ButtonBorderPosition = { "CENTER", 0, 0 },
	ButtonBorderSize = { 134.295081967, 134.295081967 },
	ButtonBorderTexture = GetMedia("actionbutton-border"),
	ButtonBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3], 1 },

	ButtonSpellHighlightPosition = { "CENTER", 0, 0 },
	ButtonSpellHighlightSize = { 134.295081967, 134.295081967 },
	ButtonSpellHighlightTexture = GetMedia("actionbutton-spellhighlight"),

}

---------------------------------------------
-- LAB Overrides & MaxDps Integration
---------------------------------------------
local ShowMaxDps = function(self)
	if (self.spellHighlight) then
		if (self.maxDpsGlowColor) then
			local r, g, b, a = unpack(self.maxDpsGlowColor)
			self.spellHighlight:SetVertexColor(r, g, b, a or .75)
		else
			self.spellHighlight:SetVertexColor(249/255, 188/255, 65/255, .75)
		end
		self.spellHighlight:Show()
		--LAB.callbacks:Fire("OnButtonShowOverlayGlow", self)
	end
end

local HideMaxDps = function(self)
	if (self.spellHighlight) then
		if (not self.maxDpsGlowShown) then
			self.spellHighlight:Hide()
			--LAB.callbacks:Fire("OnButtonHideOverlayGlow", self)
		end
	end
end

local UpdateMaxDps = function(self)
	if (self.maxDpsGlowShown) then
		ShowMaxDps(self)
	else
		local spellId = self:GetSpellId()
		if (spellId and IsSpellOverlayed(spellId)) then
			ShowMaxDps(self)
		else
			HideMaxDps(self)
		end
	end
end

local UpdateUsable = function(self)
	local config = self.config

	if (UnitIsDeadOrGhost("player") or (IsMounted() and not self.header.isDragonRiding)) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(.4, .36, .32)

	elseif (self.outOfRange) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(unpack(config.colors.range))
	else
		local isUsable, notEnoughMana = self:IsUsable()
		if (isUsable) then
			self.icon:SetDesaturated(false)
			self.icon:SetVertexColor(1, 1, 1)

		elseif (notEnoughMana) then
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(unpack(config.colors.mana))
		else
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(.4, .36, .32)
		end
	end

	if (C_LevelLink and self._state_type == "action") then
		local isLevelLinkLocked = C_LevelLink.IsActionLocked(self._state_action)
		if (not self.icon:IsDesaturated()) then
			self.icon:SetDesaturated(isLevelLinkLocked)
			if (isLevelLinkLocked) then
				self.icon:SetVertexColor(.4, .36, .32)
			end
		end
		if (self.LevelLinkLockIcon) then
			self.LevelLinkLockIcon:SetShown(isLevelLinkLocked)
		end
	end

end

local buttonOnEnter = function(self)
	self.icon.darken:SetAlpha(0)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local buttonOnLeave = function(self)
	self.icon.darken:SetAlpha(.1)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local style = function(button)

	local db = config
	local usingMaxDps = IsAddOnEnabled("MaxDps")

	-- Clean up the button template
	for _,i in next,{ "AutoCastShine", "Border", "Name", "NewActionTexture", "NormalTexture", "SpellHighlightAnim", "SpellHighlightTexture",
		--[[ WoW10 ]] "CheckedTexture", "HighlightTexture", "BottomDivider", "RightDivider", "SlotArt", "SlotBackground" } do
		if (button[i] and button[i].Stop) then button[i]:Stop() elseif button[i] then button[i]:SetParent(UIHider) end
	end

	local m = db.ButtonMaskTexture
	local b = GetMedia("blank")

	button:SetAttribute("buttonLock", true)
	button:SetSize(unpack(db.ButtonSize))
	button:SetHitRectInsets(unpack(db.ButtonHitRects))
	button:SetNormalTexture("")
	button:SetHighlightTexture("")
	button:SetCheckedTexture("")
	button:GetHighlightTexture():Hide()
	button:GetCheckedTexture():Hide()

	-- New 3.4.1 checked texture keeps being reset.
	hooksecurefunc(button, "SetChecked", function() button:GetCheckedTexture():Hide() end)

	-- Custom slot texture
	local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	backdrop:SetSize(unpack(db.ButtonBackdropSize))
	backdrop:SetPoint(unpack(db.ButtonBackdropPosition))
	backdrop:SetTexture(db.ButtonBackdropTexture)
	backdrop:SetVertexColor(unpack(db.ButtonBackdropColor))
	button.backdrop = backdrop

	-- Icon
	local icon = button.icon
	icon:SetDrawLayer("BACKGROUND", 1)
	icon:ClearAllPoints()
	icon:SetPoint(unpack(db.ButtonIconPosition))
	icon:SetSize(unpack(db.ButtonIconSize))

	local i = 1
	while button.icon:GetMaskTexture(i) do
		button.icon:RemoveMaskTexture(button.icon:GetMaskTexture(i))
		i = i + 1
	end
	if (button.IconMask) then
		icon:RemoveMaskTexture(button.IconMask)
	end
	icon:SetMask(m)

	-- Custom icon darkener
	local darken = button:CreateTexture(nil, "BACKGROUND", nil, 2)
	darken:SetAllPoints(button.icon)
	darken:SetTexture(m)
	darken:SetVertexColor(0, 0, 0, .1)
	button.icon.darken = darken

	button:SetScript("OnEnter", buttonOnEnter)
	button:SetScript("OnLeave", buttonOnLeave)

	-- Some crap WoW10 border I can't figure out how to remove right now.
	button:DisableDrawLayer("ARTWORK")

	-- Button is pushed
	-- Responds to mouse and keybinds
	-- if we allow blizzard to handle it.
	local pushedTexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
	pushedTexture:SetVertexColor(1, 1, 1, .2)
	pushedTexture:SetTexture(m)
	pushedTexture:SetAllPoints(button.icon)
	button.PushedTexture = pushedTexture

	button:SetPushedTexture(button.PushedTexture)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("OVERLAY", 1)

	-- Autoattack flash
	local flash = button.Flash
	flash:SetDrawLayer("OVERLAY", 2)
	flash:SetAllPoints(icon)
	flash:SetVertexColor(1, 0, 0, .25)
	flash:SetTexture(m)
	flash:Hide()

	-- Button cooldown frame
	local cooldown = button.cooldown
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	cooldown:ClearAllPoints()
	cooldown:SetAllPoints(button.icon)
	cooldown:SetUseCircularEdge(true)
	cooldown:SetReverse(false)
	cooldown:SetSwipeTexture(m)
	cooldown:SetDrawSwipe(true)
	cooldown:SetBlingTexture(b, 0, 0, 0, 0)
	cooldown:SetDrawBling(false)
	cooldown:SetEdgeTexture(b)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true)

	button.UpdateCharge = function(self)
		local m = config.ButtonMaskTexture
		local b = GetMedia("blank")
		local cooldown = self.chargeCooldown
		if (not cooldown) then return end
		cooldown:SetFrameStrata(self:GetFrameStrata())
		cooldown:SetFrameLevel(self:GetFrameLevel() + 2)
		cooldown:SetUseCircularEdge(true)
		cooldown:SetReverse(false)
		cooldown:SetSwipeTexture(m)
		cooldown:SetDrawSwipe(true)
		cooldown:SetBlingTexture(b, 0, 0, 0, 0)
		cooldown:SetDrawBling(false)
		cooldown:SetEdgeTexture(b)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(true)
		cooldown:SetAlpha(.5)
		cooldown:ClearAllPoints()
		cooldown:SetAllPoints(self.icon)
	end

	--button.UpdateLocal = UpdateUsable

	-- Custom overlay frame
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 3)
	overlay:SetAllPoints()
	button.overlay = overlay

	local border = overlay:CreateTexture(nil, "BORDER", nil, 1)
	border:SetPoint(unpack(db.ButtonBorderPosition))
	border:SetSize(unpack(db.ButtonBorderSize))
	border:SetTexture(db.ButtonBorderTexture)
	border:SetVertexColor(unpack(db.ButtonBorderColor))
	--border:SetAlpha(0)
	button.iconBorder = border

	-- Custom spell highlight
	local spellHighlight = overlay:CreateTexture(nil, "ARTWORK", nil, -7)
	spellHighlight:SetSize(unpack(db.ButtonSpellHighlightSize))
	spellHighlight:SetPoint(unpack(db.ButtonSpellHighlightPosition))
	spellHighlight:SetTexture(db.ButtonSpellHighlightTexture)
	spellHighlight:SetVertexColor(249/255, 188/255, 65/255, .75)
	spellHighlight:Hide()
	button.spellHighlight = spellHighlight

	-- Custom cooldown count
	local cooldownCount = overlay:CreateFontString(nil, "ARTWORK", nil, 1)
	cooldownCount:SetPoint(unpack(db.ButtonCooldownCountPosition))
	cooldownCount:SetFontObject(db.ButtonCooldownCountFont)
	cooldownCount:SetJustifyH(db.ButtonCooldownCountJustifyH)
	cooldownCount:SetJustifyV(db.ButtonCooldownCountJustifyV)
	cooldownCount:SetTextColor(unpack(db.ButtonCooldownCountColor))
	button.cooldownCount = cooldownCount

	-- Button charge/stack count
	local count = button.Count
	count:SetParent(overlay)
	count:SetDrawLayer("OVERLAY", 1)
	count:ClearAllPoints()
	count:SetPoint(unpack(db.ButtonCountPosition))
	count:SetFontObject(db.ButtonCountFont)
	count:SetJustifyH(db.ButtonCountJustifyH)
	count:SetJustifyV(db.ButtonCountJustifyV)
	count:SetTextColor(unpack(db.ButtonCountColor))

	-- Button keybind
	local hotkey = button.HotKey
	hotkey:SetParent(overlay)
	hotkey:SetDrawLayer("OVERLAY", 1)
	hotkey:ClearAllPoints()
	hotkey:SetPoint(unpack(db.ButtonKeybindPosition))
	hotkey:SetJustifyH(db.ButtonKeybindJustifyH)
	hotkey:SetJustifyV(db.ButtonKeybindJustifyV)
	hotkey:SetFontObject(db.ButtonKeybindFont)
	hotkey:SetTextColor(unpack(db.ButtonKeybindColor))

	RegisterCooldown(button.cooldown, button.cooldownCount)

	hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	--hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
	hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	local config = button.config or {}
	config.text = {
		hotkey = {
			font = {
				font = db.ButtonKeybindFont:GetFont(),
				size = select(2, db.ButtonKeybindFont:GetFont()),
				flags = select(3, db.ButtonKeybindFont:GetFont()),
			},
			color = db.ButtonKeybindColor,
			position = {
				anchor = db.ButtonKeybindPosition[1],
				relAnchor = db.ButtonKeybindPosition[1],
				offsetX = db.ButtonKeybindPosition[2],
				offsetY = db.ButtonKeybindPosition[3],
			},
			justifyH = db.ButtonKeybindJustifyH,
		},
		count = {
			font = {
				font = db.ButtonCountFont:GetFont(),
				size = select(2, db.ButtonCountFont:GetFont()),
				flags = select(3, db.ButtonCountFont:GetFont()),
			},
			color = db.ButtonCountColor,
			position = {
				anchor = db.ButtonCountPosition[1],
				relAnchor = db.ButtonCountPosition[1],
				offsetX = db.ButtonCountPosition[2],
				offsetY = db.ButtonCountPosition[3],
			},
			justifyH = db.ButtonCountJustifyH,
		}
	}
	button:UpdateConfig(config)

	-- Disable masque for our buttons,
	-- they are not compatible.
	button.AddToMasque = noop
	button.AddToButtonFacade = noop
	button.LBFSkinned = nil
	button.MasqueSkinned = nil

	return button
end

ActionBarMod.HandleMaxDps = function(self)

	MaxDps:RegisterLibActionButton(LAB_Name) -- LAB_Version

	-- This will hide the MaxDps overlays for the most part.
	local MaxDps_GetTexture = MaxDps.GetTexture
	MaxDps.GetTexture = function() end

	local Glow = MaxDps.Glow
	MaxDps.Glow = function(this, button, id, texture, type, color)
		if (not self.buttons[button]) then
			return Glow(this, button, id, texture, type, color)
		end
		local col = color and { color.r, color.g, color.b, color.a } or nil
		if (not color) and (type) then
			if (type == "normal") then
				local c = this.db.global.highlightColor
				col = { c.r, c.g, c.b, c.a }

			elseif (type == "cooldown") then
				local c = this.db.global.cooldownColor
				col = { c.r, c.g, c.b, c.a }
			end
		end
		button.maxDpsGlowColor = col
		button.maxDpsGlowShown = true
		UpdateMaxDps(button)
	end

	local HideGlow = MaxDps.HideGlow
	MaxDps.HideGlow = function(this, button, id)
		if (not self.buttons[button]) then
			return HideGlow(this, button, id)
		end
		button.maxDpsGlowColor = nil
		button.maxDpsGlowShown = nil
		UpdateMaxDps(button)
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")

	LAB.RegisterCallback(self, "OnButtonShowOverlayGlow", "OnEvent")
	LAB.RegisterCallback(self, "OnButtonHideOverlayGlow", "OnEvent")

	self.MaxDps = true
end

ActionBarMod.UpdateBindings = function(self)
	for i,bar in next,self.bars do
		if (bar:IsEnabled()) then
			bar:UpdateBindings()
		end
	end
end

ActionBarMod.UpdatePositionAndScale = function(self, bar)
	if (InCombatLockdown()) then
		self.positionNeedsFix = true
		return
	end

	local savedPosition = bar.currentLayout and bar.config.savedPosition[bar.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local anchor = bar.anchor

		-- Set the scale before positioning,
		-- or everything will be wonky.
		bar:SetScale(scale * ns.API.GetDefaultElementScale())

		if (anchor and anchor.framePoint) then
			-- Position the frame at the anchor,
			-- with the given point and offsets.
			bar:ClearAllPoints()
			bar:SetPoint(anchor.framePoint, anchor, anchor.framePoint, (anchor.frameOffsetX or 0)/scale, (anchor.frameOffsetY or 0)/scale)

			-- Parse where this actually is relative to UIParent
			local point, x, y = ns.API.GetPosition(bar)

			-- Reposition the frame relative to UIParent,
			-- to avoid it being hooked to our anchor in combat.
			bar:ClearAllPoints()
			bar:SetPoint(point, UIParent, point, x, y)
		end
	end

end

ActionBarMod.OnAnchorUpdate = function(self, bar, reason, layoutName, ...)
	local savedPositions = self.db.profile.bars[ID_TO_BAR[bar.id]].savedPosition
	local defaultPositions = self.db.defaults.profile.bars[ID_TO_BAR[bar.id]].savedPosition

	local anchor = bar.anchor

	if (reason == "LayoutDeleted") then
		if (savedPositions[layoutName]) then
			savedPositions[layoutName] = nil
		end

	elseif (reason == "LayoutsUpdated") then

		if (savedPositions[layoutName]) then

			anchor:SetScale(savedPositions[layoutName].scale or anchor:GetScale())
			anchor:ClearAllPoints()
			anchor:SetPoint(unpack(savedPositions[layoutName]))

			local defaultPosition = defaultPositions[layoutName] or defaultPositions.Azerite
			if (defaultPosition) then
				anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			bar.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not bar.initialPositionSet) then

				local defaultPosition = defaultPositions.Azerite

				anchor:SetScale(defaultPosition.scale)
				anchor:ClearAllPoints()
				anchor:SetPoint(unpack(defaultPosition))
				anchor:SetDefaultPosition(unpack(defaultPosition))

				bar.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPositions[layoutName] = { anchor:GetPosition() }
			savedPositions[layoutName].scale = anchor:GetScale()
		end

		bar.currentLayout = layoutName

		self:UpdatePositionAndScale(bar)

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPositions[layoutName] = { point, x, y }
		savedPositions[layoutName].scale = anchor:GetScale()

		self:UpdatePositionAndScale(bar)

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPositions[layoutName].scale = scale

		self:UpdatePositionAndScale(bar)

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		if (not self.incombat) then
			self:OnAnchorUpdate(bar, "PositionUpdated", layoutName, ...)
		end
	end
end

-- Returns a localized named usable for our movable frame anchor.
ActionBarMod.GetBarDisplayName = function(self, id)
	local barID = tonumber(id)
	if (barID == RIGHT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR3_TEXT -- "Right Action Bar 1"
	elseif (barID == LEFT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR4_TEXT -- "Right Action Bar 2"
	else
		return ITEM_SUFFIX_TEMPLATE:format(BINDING_HEADER_ACTIONBAR, barID)
		--return HUD_EDIT_MODE_ACTION_BAR_LABEL:format(barID) -- "Action Bar %d"
	end
end

ActionBarMod.EnableBar = function(self, input)
	if (InCombatLockdown()) then return end

	local db = self.db.profile.bars
	local id = tonumber((self:GetArgs(string_lower(input))))

	if (not id or not db[id]) then return end

	db[id].enabled = true

	self:UpdateSettings()
end

ActionBarMod.DisableBar = function(self, input)
	if (InCombatLockdown()) then return end

	local db = self.db.profile.bars
	local id = tonumber((self:GetArgs(string_lower(input))))

	if (not id or not db[id]) then return end

	db[id].enabled = false

	self:UpdateSettings()
end

-- fucking charge cooldown styling
ActionBarMod.UpdateChargeCooldowns = function(self)
	if (not self.chargeCooldowns) then
		self.chargeCooldowns = {}
	end

	local m = config.ButtonMaskTexture
	local b = GetMedia("blank")

	local i = 1
	local cooldown = _G["LAB10ChargeCooldown"..i]
	while cooldown do
		if (not self.chargeCooldowns[cooldown]) then

			cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
			cooldown:ClearAllPoints()
			cooldown:SetAllPoints(button.icon)
			cooldown:SetUseCircularEdge(true)
			cooldown:SetReverse(false)
			cooldown:SetSwipeTexture(m)
			cooldown:SetDrawSwipe(true)
			cooldown:SetBlingTexture(b, 0, 0, 0, 0)
			cooldown:SetDrawBling(false)
			cooldown:SetEdgeTexture(b)
			cooldown:SetDrawEdge(false)
			cooldown:SetHideCountdownNumbers(true)

			hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
			hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
			hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
			--hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
			hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
			hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
			hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
			hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
			hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

			hooksecurefunc(cooldown, "Show", function(self)
				local parent = self:GetParent()
				self:GetFrameStrata(parent:GetFrameStrata())
				self:SetFrameLevel(parent:GetFrameLevel() + 1)
			end)

			self.chargeCooldowns[cooldown] = true
		end
		i = i + 1
		cooldown = _G["LAB10ChargeCooldown"..i]
	end

end

ActionBarMod.UpdateSettings = function(self)
	local db = self.db.profile

	for i,bar in next,self.bars do
		local bardb = db.bars[i]

		-- Update enabled bars.
		-- Settings not there?
		if (bardb.enabled) then
			bar:Enable()
		else
			bar:Disable()
		end

		-- Update bar fading for enabled bars.
		if (bardb.enabled and db.enableBarFading) then
			if (i == 1) then
				if (bardb.layout == "map") then
					for id = 8, #bar.buttons do
						self:RegisterFrameForFading(bar.buttons[id], "actionbuttons", unpack(config.ButtonHitRects))
					end
				else
					for id, button in next,bar.buttons do
						self:UnregisterFrameForFading(bar.buttons[id])
					end
				end
			else
				for id, button in next,bar.buttons do
					self:RegisterFrameForFading(bar.buttons[id], "actionbuttons", unpack(config.ButtonHitRects))
				end
			end
		else
			for id, button in next,bar.buttons do
				self:UnregisterFrameForFading(bar.buttons[id])
			end
		end

	end
end

ActionBarMod.EnableBarFading = function(self)
	self.db.profile.enableBarFading = true
	self:UpdateSettings()
end

ActionBarMod.DisableBarFading = function(self)
	self.db.profile.enableBarFading = false
	self:UpdateSettings()
end

ActionBarMod.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addon = ...
		if (addon == "MaxDps") then
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			self:HandleMaxDps()
		end
	elseif (event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_SHAPESHIFT_FORM") then

		if (self.MaxDps) then
			for button in next, LAB.activeButtons do
				if (self.buttons[button]) then
					if (button.maxDpsGlowShown) then
						button.maxDpsGlowColor = nil
						button.maxDpsGlowShown = nil
						UpdateMaxDps(button)
					end
				end
			end
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil
		if (self.positionNeedsFix) then
			self:UpdatePositionAndScale()
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true
	elseif (event == "UPDATE_BINDINGS") then
		for id,bar in next(self.bars) do
			bar:UpdateBindings()
		end
	elseif (event == "OnButtonUpdate") then
		local button = ...
		if (self.buttons[button]) then
			button.cooldown:ClearAllPoints()
			button.cooldown:SetAllPoints(button.icon)
			button.cooldown:SetDrawEdge(false)

			local i = 1
			while button.icon:GetMaskTexture(i) do
				button.icon:RemoveMaskTexture(button.icon:GetMaskTexture(i))
				i = i + 1
			end
			button.icon:SetMask(config.ButtonMaskTexture)

			local spellId = button:GetSpellId()
			if spellId and IsSpellOverlayed(spellId) then
				button.spellHighlight:Show()
			else
				button.spellHighlight:Hide()
			end

			-- The update function calls this for valid actions
			UpdateUsable(button)
		end

	elseif (event == "OnButtonUsable" or event == "OnButtonState") then
		local button = ...
		if (self.buttons[button]) then
			UpdateUsable(button)
		end
	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
		local arg1 = ...
		for button in next, LAB.activeButtons do
			local spellId = button:GetSpellId()
			if (spellId and spellId == arg1) then
				button.spellHighlight:Show()
			else
				if (button._state_type == "action") then
					local actionType, id = GetActionInfo(button._state_action)
					if (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
						button.spellHighlight:Hide()
					end
				end
			end
		end

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE") then
		local arg1 = ...
		for button in next, LAB.activeButtons do
			local spellId = button:GetSpellId()
			if (spellId and spellId == arg1) then
				button.spellHighlight:Hide()
			else
				if (button._state_type == "action") then
					local actionType, id = GetActionInfo(button._state_action)
					if (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
						button.spellHighlight:Hide()
					end
				end
			end
		end
	end
end

ActionBarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ActionBars", defaults)

	self.bars = {}
	self.buttons = {}

	self:SetEnabledState(self.db.profile.enabled)

	for i = 1,#BAR_TO_ID do

		local config = self.db.profile.bars[i]
		local bar = ns.ActionBar:Create(BAR_TO_ID[i], config, ns.Prefix.."ActionBar"..i)

		-- Register the available layout names
		-- with the movable frames manager.
		if (MFM) then
			MFM:RegisterPresets(self.db.profile.bars[i].savedPosition)
		end

		-- Set an initial size and point before button updates,
		-- since mapped buttons (like the primary and secondary bars have)
		-- rely on the bar having these to correctly size both the bar and the anchor.
		bar:SetPoint(unpack(defaults.profile.bars[i].savedPosition.Azerite))
		bar:SetSize(2,2)

		-- This will spawn the buttons.
		bar:UpdateButtons()

		-- This will fix the layout and size of the bar.
		bar:UpdateButtonLayout()

		-- This is pretty damn pointless at this point.
		bar:UpdateBindings()

		for id,button in next,bar.buttons do
			style(button)
			self.buttons[button] = true
		end

		if (i == 1) then

			local exitButton = {
				func = function(button)
					if (UnitExists("vehicle")) then
						VehicleExit()
					else
						PetDismiss()
					end
				end,
				tooltip = _G.LEAVE_VEHICLE,
				texture = [[Interface\Icons\achievement_bg_kill_carrier_opposing_flagroom]]
			}

			bar.buttons[7]:SetState(16, "custom", exitButton)
			bar.buttons[7]:SetState(17, "custom", exitButton)
			bar.buttons[7]:SetState(18, "custom", exitButton)

			-- Pet Battle Keybind Fixer
			-------------------------------------------------------
			local buttons = bar.buttons
			local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
			controller:SetAttribute("_onstate-petbattle", string_format([[
				if (newstate == "petbattle") then
					b = b or table.new();
					b[1], b[2], b[3], b[4], b[5], b[6] = "%s", "%s", "%s", "%s", "%s", "%s";
					for i = 1,6 do
						local button, vbutton = "CLICK "..b[i]..":LeftButton", "ACTIONBUTTON"..i
						for k=1,select("#", GetBindingKey(button)) do
							local key = select(k, GetBindingKey(button))
							self:SetBinding(true, key, vbutton)
						end
						-- do the same for the default UIs bindings
						for k=1,select("#", GetBindingKey(vbutton)) do
							local key = select(k, GetBindingKey(vbutton))
							self:SetBinding(true, key, vbutton)
						end
					end
				else
					self:ClearBindings()
				end
			]], buttons[1]:GetName(), buttons[2]:GetName(), buttons[3]:GetName(), buttons[4]:GetName(), buttons[5]:GetName(), buttons[6]:GetName()))

			self.petBattleController = controller

		end

		local anchor = MFM:RequestAnchor()
		anchor:SetTitle(self:GetBarDisplayName(i))
		anchor:SetScalable(true)
		anchor:SetMinMaxScale(.75, 1.25, .05)
		anchor:SetSize(bar:GetSize()) -- will be updated later
		anchor:SetPoint(unpack(defaults.profile.bars[i].savedPosition.Azerite))
		anchor:SetScale(defaults.profile.bars[i].savedPosition.Azerite.scale)
		anchor.frameOffsetX = 0
		anchor.frameOffsetY = 0
		anchor.framePoint = "BOTTOMLEFT"
		anchor.Callback = function(_,...) self:OnAnchorUpdate(bar, ...) end

		-- do this on layout updates too
		if (ns.IsWrath or ns.IsRetail) then
			if (config.grid and config.grid.growth == "vertical") then
				anchor.Text:SetRotation((-90 / 180) * math.pi)
				anchor.Title:SetRotation((-90 / 180) * math.pi)
			end
		end

		bar.anchor = anchor

		self.bars[i] = bar
	end

	self:RegisterChatCommand("enablebar", "EnableBar")
	self:RegisterChatCommand("disablebar", "DisableBar")
	self:RegisterChatCommand("enablebarfade", "EnableBarFading")
	self:RegisterChatCommand("disablebarfade", "DisableBarFading")

	if (ns.IsRetail) then
		if (MaxDps) then
			self:HandleMaxDps()
		elseif (IsAddOnEnabled("MaxDps")) then
			self:RegisterEvent("ADDON_LOADED", "OnEvent")
		end
	end

end

ActionBarMod.UpdateBarStates = function(self)

end

ActionBarMod.OnEnable = function(self)
	self:UpdateSettings()
	self:UpdateBindings()

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")

	if (not IsAddOnEnabled("MaxDps")) then
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "OnEvent")
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", "OnEvent")
	end

	LAB.RegisterCallback(self, "OnButtonUpdate", "OnEvent")
	LAB.RegisterCallback(self, "OnButtonUsable", "OnEvent")

end

ActionBarMod.OnDisable = function(self)
	for i,bar in next,self.bars do
		bar:Disable()
	end

	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("UPDATE_BINDINGS", "UpdateBindings")

	LAB.UnregisterCallback(self, "OnButtonUpdate")
	LAB.UnregisterCallback(self, "OnButtonUsable")

end
