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

local Auras = ns:NewModule("Auras", "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0", "AceConsole-3.0", "LibSmoothBar-1.0")
local LFF = LibStub("LibFadingFrames-1.0")
local MFM = ns:GetModule("MovableFramesManager")

-- Lua API
local math_ceil = math.ceil
local math_max = math.max
local pairs = pairs
local select = select
local string_lower = string.lower
local tonumber = tonumber

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local RegisterCooldown = ns.Widgets.RegisterCooldown

local profileDefaults = {
	enabled = true,
	enableAuraFading = true,
	enableModifier = false,
	modifier = "SHIFT",
	anchorPoint = "TOPRIGHT",
	growthX = "LEFT",
	growthY = "DOWN",
	paddingX = 6,
	paddingY = 12,
	wrapAfter = 6,
	scale = ns.API.GetEffectiveScale(),
	[1] = "TOPRIGHT",
	[2] = -40 * ns.API.GetEffectiveScale(),
	[3] = -40 * ns.API.GetEffectiveScale()
}

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = ns:Copy(profileDefaults)
	}
}, ns.moduleDefaults) }

-- Aura Template
--------------------------------------------
local Aura = {}

Aura.Style = function(self)

	local contents = CreateFrame("Frame", nil, self)
	contents:SetAllPoints(self)
	self.contents = contents

	local icon = contents:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetVertexColor(.75, .75, .75)
	self.icon = icon

	local border = CreateFrame("Frame", nil, self.contents, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.verydarkgray[1], Colors.verydarkgray[2], Colors.verydarkgray[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(contents:GetFrameLevel() + 2)
	self.border = border

	local count = self.border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 3)
	self.count = count

	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetPoint("TOPLEFT", -6, 6)
	overlay:SetPoint("BOTTOMRIGHT", 6, -6)
	overlay:SetFrameLevel(contents:GetFrameLevel() + 3)
	self.overlay = overlay

	local time = self.overlay:CreateFontString(nil, "OVERLAY")
	time:Hide()
	time:SetFontObject(GetFont(18,true))
	time:SetTextColor(Colors.red[1], Colors.red[2], Colors.red[3])
	time:SetPoint("CENTER")
	time:SetAlpha(.85)
	self.time = time

	local bar = Auras:CreateSmoothBar(nil, contents)
	bar:SetPoint("TOP", contents, "BOTTOM", 0, 0)
	bar:SetPoint("LEFT", contents, "LEFT", 1, 0)
	bar:SetPoint("RIGHT", contents, "RIGHT", -1, 0)
	bar:SetHeight(4)
	bar:SetStatusBarTexture(GetMedia("bar-small"))
	bar:SetStatusBarColor(Colors.aura[1], Colors.aura[2], Colors.aura[3])
	--bar:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3])
	bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar.bg:SetColorTexture(.05, .05, .05, .85)
	self.bar = bar

	local fadeAnimation = contents:CreateAnimationGroup()
	fadeAnimation:SetLooping("BOUNCE")

	local fade = fadeAnimation:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(.5)
	fade:SetDuration(.6)
	fade:SetSmoothing("IN_OUT")

	self.fadeAnimation = fadeAnimation

	-- Using a virtual cooldown element with the bar and timer attached,
	-- allowing them to piggyback on oUF's cooldown updates.
	self.cd = RegisterCooldown(bar, time)

end

Aura.Update = function(self, index)

	local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(self:GetParent():GetAttribute("unit"), index, self.filter)

	if (name) then
		self:SetAlpha(1)
		self.icon:SetTexture(icon)
		self.count:SetText((count and count > 1) and count or "")

		if (duration and duration > 0 and expirationTime) then
			self.cd:SetCooldown(expirationTime - duration, duration)
			self.cd:Show()

			local timeLeft = expirationTime - GetTime()

			self.timeLeft = timeLeft
			self:SetScript("OnUpdate", self.OnUpdate)

			-- Fade short duration auras in and out
			if (timeLeft < 10) then
				if (not self.fadeAnimation:IsPlaying()) then
					self.fadeAnimation:Play()
				end
				self.time:Show()
			else
				if (self.fadeAnimation:IsPlaying()) then
					self.fadeAnimation:Stop()
				end
				self.time:Hide()
			end

		else
			self.cd:Hide()
			self.time:Hide()
			if (self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Stop()
			end
			self:SetScript("OnUpdate", nil)
			self.timeLeft = nil
		end
	else
		self.icon:SetTexture(nil)
		self.count:SetText("")
		self.cd:Hide()
		self.time:Hide()
		if (self.fadeAnimation:IsPlaying()) then
			self.fadeAnimation:Stop()
		end
		self:SetScript("OnUpdate", nil)
		self.timeLeft = nil
	end

end

Aura.UpdateTempEnchant = function(self, slot)
	local enchant = (slot == 16 and 2) or 6
	local expiration = select(enchant, GetWeaponEnchantInfo())
	local remaining = expiration / 1e3

	-- We can't really know the duration of temp enchants without huge lists,
	-- so we sort of just make them up according to remaining time left.
	-- Makes them easier to read.
	local duration = (remaining <= 7200 and remaining > 3600) and 7200 or (remaining <= 3600 and remaining > 1800) and 3600 or (remaining <= 1800 and remaining > 600) and 1800 or 600

	local icon = GetInventoryItemTexture("player", slot)

	if (icon) then
		self:SetAlpha(1)
		self.icon:SetTexture(icon)
	else
		-- sometimes empty temp enchants are shown
		-- this is a bug in the secure aura headers
		self:SetAlpha(0)
		self.icon:SetTexture(nil)
	end

	if (expiration) then
		self.enchant = enchant
		self.cd:SetCooldown(GetTime() + remaining - duration, duration)
		self.cd:Show()
		self:SetScript("OnUpdate", self.OnUpdate)
	else
		self.cd:Hide()
		self.enchant = nil
		self.timeLeft = nil
		self:SetScript("OnUpdate", nil)
	end

	self.count:SetText("")

end

Aura.UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	if (self.enchant) then
		GameTooltip:SetInventoryItem("player", self:GetID())
	else
		GameTooltip:SetUnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self.filter)
	end
end

Aura.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) - elapsed
	if (self.elapsed > 0) then
		return
	end
	self.elapsed = .01

	local timeLeft
	if (self.enchant) then
		local expiration = select(self.enchant, GetWeaponEnchantInfo())
		timeLeft = expiration and (expiration / 1e3) or 0
	else
		timeLeft = self.timeLeft - elapsed
	end
	self.timeLeft = timeLeft

	if (timeLeft > 0) then
		if (timeLeft < 10) then
			if (not self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Play()
			end
			self.time:Show()
		else
			if (self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Stop()
			end
			self.time:Hide()
		end
	else
		self.timeLeft = nil
		self:SetScript("OnUpdate", nil)
	end

end

Aura.OnEnter = function(self)
	if (not self:IsVisible()) then return end
	if (GameTooltip:IsForbidden()) then return end
	local p = self:GetParent()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(p.tooltipPoint, self, p.tooltipAnchor, p.tooltipOffsetX, p.tooltipOffsetY)
	self:UpdateTooltip()
end

Aura.OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

Aura.OnAttributeChanged = function(self, attribute, value)
	if (attribute == "index") then
		return self:Update(value)
	elseif(attribute == "target-slot") then
		return self:UpdateTempEnchant(value)
	end
end

Aura.OnInitialize = function(self)
	self:Style()
	self.isRetail = ns.IsRetail
	self.filter = self:GetParent():GetAttribute("filter")
	self.UpdateTooltip = self.UpdateTooltip
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnAttributeChanged", self.OnAttributeChanged)
end

-- Module API
--------------------------------------------
-- Embed the aura template methods
-- into an existing aura frame.
Auras.Embed = function(self, aura)
	for method,func in pairs(Aura) do
		aura[method] = func
	end
end

-- Run a member method on all auras.
Auras.ForAll = function(self, method, ...)
	local buffs = self.buffs
	if (not buffs) then
		return
	end
	local child = buffs:GetAttribute("child1")
	local i = 1
	while (child) do
		local func = child[method]
		if (func) then
			func(child, child:GetID(), ...)
		end
		i = i + 1
		child = buffs:GetAttribute("child" .. i)
	end
end

-- Updates
--------------------------------------------
Auras.UpdateAuraButtonAlpha = function(self)
	local buffs = self.buffs
	if (not buffs) then return end

	local consolidateDuration = tonumber(buffs:GetAttribute("consolidateDuration")) or 30
	local consolidateThreshold = tonumber(buffs:GetAttribute("consolidateThreshold")) or 10
	local consolidateFraction = tonumber(buffs:GetAttribute("consolidateFraction")) or 0.1
	local unit, filter = buffs:GetAttribute("unit"), buffs:GetAttribute("filter")
	local slot, consolidated, time = 1, 0, GetTime()
	local name, duration, expires, caster, shouldConsolidate, _

	repeat
		-- Sourced from FrameXML\SecureGroupHeaders.lua
		name, _, _, _, duration, expires, caster, _, _, _, _, _, _, _, _, shouldConsolidate = UnitAura(unit, slot, filter)
		if (name and shouldConsolidate) then
			if (not expires or duration > consolidateDuration or (expires - time >= math_max(consolidateThreshold, duration * consolidateFraction)) ) then
				consolidated = consolidated + 1
			end
		end
		slot = slot + 1
	until (not name)

	-- Update count and counter.
	buffs.numConsolidated = consolidated
	buffs.proxy.count:SetText(buffs.numConsolidated > 0 and buffs.numConsolidated or "")

	-- If there are currently consolidated buffs and both
	-- the proxy button and the consolidation frame are shown,
	-- reduce the alpha of the buff window.
	if (buffs.numConsolidated > 0 and buffs.proxy:IsShown() and buffs.consolidation:IsShown()) then
		buffs:SetAlpha(.5)
	else
		buffs:SetAlpha(1)
	end
end

Auras.UpdatePositionAndScale = function(self)
	if (InCombatLockdown()) then
		self.needupdate = true
		return
	end
	if (not self.frame) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]

	self.frame:SetScale(config.scale)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
end

Auras.UpdateAnchor = function(self)
	if (not self.anchor) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]
	self.anchor:SetSize(self.frame:GetSize())
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

Auras.UpdateSettings = function(self)
	if (InCombatLockdown()) then
		self.needupdate = true
		return
	end
	if (not self.frame) then return end

	local config = self.db.profile.savedPosition[MFM:GetLayout()]

	if (config.enabled and config.enableAuraFading) then
		LFF:RegisterFrameForFading(self.frame, "playerauras")
		LFF:RegisterFrameForFading(self.buffs.proxy, "playerauras")
		LFF:RegisterFrameForFading(self.buffs.consolidation, "playerauras")
	else
		LFF:UnregisterFrameForFading(self.frame, "playerauras")
		LFF:UnregisterFrameForFading(self.buffs.proxy, "playerauras")
		LFF:UnregisterFrameForFading(self.buffs.consolidation, "playerauras")
	end

	self.frame:SetSize(config.wrapAfter * 36 + (config.wrapAfter - 1) * config.paddingX, (36 + config.paddingY) * math_ceil(BUFF_MAX_DISPLAY / config.wrapAfter))

	self.buffs:SetAttribute("point", config.anchorPoint)
	self.buffs:SetAttribute("xOffset", (36 + config.paddingX) * (config.growthX == "LEFT" and -1 or 1))
	self.buffs:SetAttribute("wrapAfter", config.wrapAfter)
	self.buffs:SetAttribute("wrapYOffset", (36 + config.paddingY) * (config.growthY == "DOWN" and -1 or 1))

	self.buffs.consolidation:SetAttribute("point", self.buffs:GetAttribute("point"))
	self.buffs.consolidation:SetAttribute("xOffset", self.buffs:GetAttribute("xOffset"))
	self.buffs.consolidation:SetAttribute("wrapAfter", self.buffs:GetAttribute("wrapAfter"))
	self.buffs.consolidation:SetAttribute("wrapYOffset", self.buffs:GetAttribute("wrapYOffset"))

	self.visibility:SetAttribute("auramode", not config.enabled and "hide" or config.enableModifier and "modifier" or "show")
	self.visibility:SetAttribute("modifierkey", string_lower(config.modifier))
	self.visibility:Execute([[ self:RunAttribute("UpdateDriver"); ]])
end

-- Initialization & Events
--------------------------------------------
Auras.DisableBlizzard = function(self)

	-- Not present in Wrath
	if (BuffFrame.Update) then
		BuffFrame:Update()
		BuffFrame:UpdateAuras()
		BuffFrame:UpdatePlayerBuffs()
	end

	BuffFrame:SetScript("OnLoad", nil)
	BuffFrame:SetScript("OnUpdate", nil)
	BuffFrame:SetScript("OnEvent", nil)
	BuffFrame:SetParent(ns.Hider)
	BuffFrame:UnregisterAllEvents()

	-- Not present in Wrath
	if (DebuffFrame) then
		DebuffFrame:SetScript("OnLoad", nil)
		DebuffFrame:SetScript("OnUpdate", nil)
		DebuffFrame:SetScript("OnEvent", nil)
		DebuffFrame:SetParent(ns.Hider)
		DebuffFrame:UnregisterAllEvents()
	end

	-- Only present in Wrath
	if (TemporaryEnchantFrame) then
		TemporaryEnchantFrame:SetScript("OnUpdate", nil)
		TemporaryEnchantFrame:SetParent(ns.Hider)
	end

end

Auras.InitializeAuras = function(self)
	if (not self.frame) then

		local config = self.db.profile.savedPosition[MFM:GetLayout()]

		local frame = CreateFrame("Frame", ns.Prefix.."BuffHeaderFrame", UIParent)
		frame:SetSize(config.wrapAfter * (36 + config.paddingX), (36 + config.paddingY) * math_ceil(BUFF_MAX_DISPLAY / config.wrapAfter))
		frame:SetPoint(config[1], UIParent, config[1], config[2], config[3])
		frame:SetScale(config.scale)

		self.frame = frame

		-----------------------------------------
		-- Header
		-----------------------------------------
		-- The primary buff window.
		local buffs = CreateFrame("Frame", ns.Prefix.."BuffHeader", frame, "SecureAuraHeaderTemplate")
		buffs:SetFrameLevel(10)
		buffs:SetSize(36,36)
		buffs:SetPoint("TOPRIGHT", 0, 0)
		buffs:SetAttribute("weaponTemplate", "AzeriteAuraTemplate")
		buffs:SetAttribute("template", "AzeriteAuraTemplate")
		buffs:SetAttribute("minHeight", 36)
		buffs:SetAttribute("minWidth", 36)
		buffs:SetAttribute("point", config.anchorPoint)
		buffs:SetAttribute("xOffset", -(36 + config.paddingX))
		buffs:SetAttribute("yOffset", 0)
		buffs:SetAttribute("wrapAfter", config.wrapAfter)
		buffs:SetAttribute("wrapXOffset", 0)
		buffs:SetAttribute("wrapYOffset", -(36 + config.paddingY))
		buffs:SetAttribute("filter", "HELPFUL")
		buffs:SetAttribute("includeWeapons", 1)
		buffs:SetAttribute("sortMethod", "TIME")
		buffs:SetAttribute("sortDirection", "-")

		buffs.UpdateAuraButtonAlpha = function() Auras:UpdateAuraButtonAlpha() end
		buffs.tooltipPoint = "TOPRIGHT"
		buffs.tooltipAnchor = "BOTTOMLEFT"
		buffs.tooltipOffsetX = -10
		buffs.tooltipOffsetY = -10

		-- Aura slot index where the
		-- consolidation button will appear.
		buffs:SetAttribute("consolidateTo", -1)

		-- Auras with less remaining duration than
		-- this many seconds should not be consolidated.
		buffs:SetAttribute("consolidateThreshold", 10) -- default 10

		-- The minimum total duration an aura should
		-- have to be considered for consolidation.
		buffs:SetAttribute("consolidateDuration", 10) -- default 30

		-- The fraction of remaining duration a buff
		-- should still have to be eligible for consolidation.
		buffs:SetAttribute("consolidateFraction", .1) -- default .10

		-- Add a vehicle switcher
		RegisterAttributeDriver(buffs, "unit", "[vehicleui] vehicle; player")

		self.buffs = buffs

		-----------------------------------------
		-- Consolidation
		-----------------------------------------
		-- The proxybutton appearing in the aura listing
		-- representing the existence of consolidated auras.
		local proxy = CreateFrame("Button", buffs:GetName().."ProxyButton", buffs, "SecureUnitButtonTemplate, SecureHandlerEnterLeaveTemplate")
		proxy:Hide()
		proxy:SetSize(36,36)
		--proxy:SetIgnoreParentAlpha(true)
		buffs.proxy = proxy

		local texture = proxy:CreateTexture(nil, "BACKGROUND")
		texture:SetSize(64,64)
		texture:SetPoint("CENTER")
		texture:SetTexture(GetMedia("chatbutton-maximize"))
		proxy.texture = texture

		local count = proxy:CreateFontString(nil, "OVERLAY")
		count:SetFontObject(GetFont(12,true))
		count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		count:SetPoint("BOTTOMRIGHT", -2, 3)
		proxy.count = count

		buffs:SetAttribute("consolidateProxy", proxy)

		-- The other updates aren't called when it is hidden,
		-- so to have the correct count when toggling through chat commands,
		-- we need to have this extra update on each show.
		self:SecureHookScript(proxy, "OnShow", "UpdateAuraButtonAlpha")
		self:SecureHookScript(proxy, "OnHide", "UpdateAuraButtonAlpha")

		-- Consolidation frame where the consolidated auras appear.
		local consolidation = CreateFrame("Frame", buffs:GetName().."Consolidation", buffs.proxy, "SecureFrameTemplate")
		consolidation:Hide()
		consolidation:SetIgnoreParentAlpha(true)
		consolidation:SetSize(36, 36)
		consolidation:SetPoint("TOPRIGHT", proxy, "TOPLEFT", -6, 0)
		consolidation:SetAttribute("minHeight", nil)
		consolidation:SetAttribute("minWidth", nil)
		consolidation:SetAttribute("point", buffs:GetAttribute("point"))
		consolidation:SetAttribute("template", buffs:GetAttribute("template"))
		consolidation:SetAttribute("weaponTemplate", buffs:GetAttribute("weaponTemplate"))
		consolidation:SetAttribute("xOffset", buffs:GetAttribute("xOffset"))
		consolidation:SetAttribute("yOffset", buffs:GetAttribute("yOffset"))
		consolidation:SetAttribute("wrapAfter", buffs:GetAttribute("wrapAfter"))
		consolidation:SetAttribute("wrapYOffset", buffs:GetAttribute("wrapYOffset"))

		consolidation.tooltipPoint = buffs.tooltipPoint
		consolidation.tooltipAnchor = buffs.tooltipAnchor
		consolidation.tooltipOffsetX = buffs.tooltipOffsetX
		consolidation.tooltipOffsetY = buffs.tooltipOffsetY

		buffs:SetAttribute("consolidateHeader", consolidation)

		-- Add a vehicle switcher
		RegisterAttributeDriver(consolidation, "unit", "[vehicleui] vehicle; player")

		buffs.consolidation = consolidation

		-- Clickbutton to toggle the consolidation window.
		local button = CreateFrame("Button", proxy:GetName().."ClickButton", proxy, "SecureHandlerClickTemplate")
		button:SetAllPoints()
		button:SetFrameRef("buffs", buffs)
		button:SetFrameRef("consolidation", consolidation)
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("_onclick", [[
			local consolidation = self:GetFrameRef("consolidation")
			local buffs = self:GetFrameRef("buffs")
			if consolidation:IsShown() then
				consolidation:Hide()
				buffs:CallMethod("UpdateAuraButtonAlpha")
			else
				consolidation:Show()
				buffs:CallMethod("UpdateAuraButtonAlpha")
			end
		]])

		proxy.button = button

		-----------------------------------------
		-- Visibility
		-----------------------------------------
		local visibility = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		visibility:SetFrameRef("buffs", buffs)
		visibility:SetAttribute("_onstate-vis", [[ self:RunAttribute("UpdateVisibility"); ]])
		visibility:SetAttribute("UpdateVisibility", [[
			local visdriver = self:GetAttribute("visdriver");
			if (not visdriver) then
				return
			end
			local buffs = self:GetFrameRef("buffs");
			local shouldhide = SecureCmdOptionParse(visdriver) == "hide";
			local isshown = buffs:IsShown();
			if (shouldhide and isshown) then
				buffs:Hide();
			elseif (not shouldhide and not isshown) then
				buffs:Show();
			end
		]])

		visibility:SetAttribute("UpdateDriver", [[
			local visdriver;
			local buffs = self:GetFrameRef("buffs");
			local auramode = self:GetAttribute("auramode");
			if (auramode == "hide") then
				visdriver = "hide";
			elseif (auramode == "show") then
				visdriver = "[petbattle]hide;[@target,exists]hide;show";
			elseif (auramode == "modifier") then
				local modifierkey = self:GetAttribute("modifierkey");
				visdriver = "[petbattle]hide;[@target,exists]hide;[mod:"..modifierkey.."]show;hide";
			end
			self:SetAttribute("visdriver", visdriver);
			UnregisterStateDriver(self, "vis");
			RegisterStateDriver(self, "vis", visdriver);
		]])

		self.visibility = visibility
	end
end

Auras.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(AURAS)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.25, 2.5, .05)
	anchor:SetSize(240, 24)
	anchor:SetPoint(unpack(defaults.profile.savedPosition[MFM:GetDefaultLayout()]))
	anchor:SetScale(defaults.profile.savedPosition[MFM:GetDefaultLayout()].scale)
	anchor:SetDefaultScale(ns.API.GetEffectiveScale)
	anchor.PreUpdate = function() self:UpdateAnchor() end
	anchor.UpdateDefaults = function() self:UpdateDefaults() end

	self.anchor = anchor
end

Auras.UpdateDefaults = function(self)
	if (not self.anchor or not self.db) then return end

	local defaults = self.db.defaults.profile.savedPosition[MFM:GetDefaultLayout()]
	if (not defaults) then return end

	defaults.scale = self.anchor:GetDefaultScale()
	defaults[1], defaults[2], defaults[3] = self.anchor:GetDefaultPosition()
end

Auras.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.incombat = nil
		self:ForAll("Update")
		self:UpdateAuraButtonAlpha()
		self:UpdatePositionAndScale()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil
		if (self.needupdate) then
			self:UpdateSettings()
			self:UpdatePositionAndScale()
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_LayoutsUpdated") then
		local LAYOUT = ...

		if (not self.db.profile.savedPosition[LAYOUT]) then
			self.db.profile.savedPosition[LAYOUT] = ns:Merge({}, defaults.profile.savedPosition[MFM:GetDefaultLayout()])
		end

		self:UpdatePositionAndScale()
		self:UpdateAnchor()

	elseif (event == "MFM_LayoutDeleted") then
		local LAYOUT = ...

		self.db.profile.savedPosition[LAYOUT] = nil

	elseif (event == "MFM_PositionUpdated") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT][1] = point
		self.db.profile.savedPosition[LAYOUT][2] = x
		self.db.profile.savedPosition[LAYOUT][3] = y

		self:UpdatePositionAndScale()

	elseif (event == "MFM_AnchorShown") then
		local LAYOUT, anchor, point, x, y = ...

		if (anchor ~= self.anchor) then return end

	elseif (event == "MFM_ScaleUpdated") then
		local LAYOUT, anchor, scale = ...

		if (anchor ~= self.anchor) then return end

		self.db.profile.savedPosition[LAYOUT].scale = scale
		self:UpdatePositionAndScale()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			if (select(2, ...) ~= self.anchor) then return end

			self:OnEvent("MFM_PositionUpdated", ...)
		end
	end
end

Auras.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Auras", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	if (not self.db.profile.enabled) then return end

	self:DisableBlizzard()
	self:InitializeAuras()
	self:InitializeMovableFrameAnchor()
	--self:RegisterChatCommand("auras", "OnChatCommand")
end

Auras.OnEnable = function(self)
	self:UpdateSettings()

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterUnitEvent("UNIT_AURA", "UpdateAuraButtonAlpha", "player", "vehicle")

	ns.RegisterCallback(self, "MFM_LayoutDeleted", "OnEvent")
	ns.RegisterCallback(self, "MFM_LayoutsUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnEvent")
end
