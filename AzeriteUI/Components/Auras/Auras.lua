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

-- Lua API
local math_ceil = math.ceil
local math_max = math.max
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local table_insert = table.insert
local tonumber = tonumber

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local RegisterCooldown = ns.Widgets.RegisterCooldown

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "TOPRIGHT",
			[2] = -40,
			[3] = -40
		}
	}
}, ns.moduleDefaults) }

-- Aura Template
--------------------------------------------
local Aura = {}

Aura.Style = function(self)

	local icon = self:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetVertexColor(.75, .75, .75)
	self.icon = icon

	local border = CreateFrame("Frame", nil, self, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.verydarkgray[1], Colors.verydarkgray[2], Colors.verydarkgray[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(self:GetFrameLevel() + 2)
	self.border = border

	local count = self.border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 3)
	self.count = count

	local time = self.border:CreateFontString(nil, "OVERLAY")
	time:Hide()
	time:SetFontObject(GetFont(18,true))
	time:SetTextColor(Colors.red[1], Colors.red[2], Colors.red[3])
	time:SetPoint("CENTER")
	time:SetIgnoreParentAlpha(true)
	time:SetAlpha(.85)
	--hooksecurefunc(time, "SetFormattedText", function(self)
	--	if (self:GetParent():GetParent():GetParent():GetAlpha() > .1) then
	--		self:SetAlpha(.85)
	--	else
	--		self:SetAlpha(0)
	--	end
	--end)
	self.time = time

	local bar = Auras:CreateSmoothBar(nil, self)
	bar:SetPoint("TOP", self, "BOTTOM", 0, 0)
	bar:SetPoint("LEFT", self, "LEFT", 1, 0)
	bar:SetPoint("RIGHT", self, "RIGHT", -1, 0)
	bar:SetHeight(4)
	bar:SetStatusBarTexture(GetMedia("bar-small"))
	bar:SetStatusBarColor(Colors.aura[1], Colors.aura[2], Colors.aura[3])
	--bar:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3])
	bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar.bg:SetColorTexture(.05, .05, .05, .85)
	self.bar = bar

	local fadeAnimation = self:CreateAnimationGroup()
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
		self.cd:SetCooldown(GetTime() - (duration - remaining), remaining)
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
	GameTooltip:SetUnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self.filter)
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
Auras.UpdateAlpha = function(self)
	local buffs = self.buffs
	if (not buffs) then
		return
	end

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

Auras.UpdateSettings = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	local visibility = self.visibility
	if (not visibility) then
		return
	end
	if (self.db.profile.alwaysHideAuras) then
		visibility:SetAttribute("auraMode", -1)
	elseif (self.db.profile.alwaysShowAuras) then
		visibility:SetAttribute("auraMode", 1)
	else
		visibility:SetAttribute("auraMode", 0)
	end
	visibility:Execute([[ self:RunAttribute("UpdateDriver"); ]])
end

-- Initialization & Events
--------------------------------------------
Auras.SpawnAuras = function(self)
	if (not self.buffs) then

		-----------------------------------------
		-- Header
		-----------------------------------------
		-- The primary buff window.
		local buffs = CreateFrame("Frame", ns.Prefix.."BuffHeader", UIParent, "SecureAuraHeaderTemplate")
		buffs:SetFrameLevel(10)
		buffs:SetSize(36,36)
		buffs:SetPoint("TOPRIGHT", -40, -40)
		buffs:SetAttribute("weaponTemplate", "AzeriteAuraTemplate")
		buffs:SetAttribute("template", "AzeriteAuraTemplate")
		buffs:SetAttribute("minHeight", 36)
		buffs:SetAttribute("minWidth", 36)
		buffs:SetAttribute("point", "TOPRIGHT")
		buffs:SetAttribute("xOffset", -42)
		buffs:SetAttribute("yOffset", 0)
		buffs:SetAttribute("wrapAfter", 6)
		buffs:SetAttribute("wrapXOffset", 0)
		buffs:SetAttribute("wrapYOffset", -48)
		buffs:SetAttribute("filter", "HELPFUL")
		buffs:SetAttribute("includeWeapons", 1)
		buffs:SetAttribute("sortMethod", "TIME")
		buffs:SetAttribute("sortDirection", "-")

		buffs.UpdateAlpha = function() Auras:UpdateAlpha() end
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
		proxy:SetIgnoreParentAlpha(true)
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
		self:SecureHookScript(proxy, "OnShow", "UpdateAlpha")
		self:SecureHookScript(proxy, "OnHide", "UpdateAlpha")

		-- Consolidation frame where the consolidated auras appear.
		local consolidation = CreateFrame("Frame", buffs:GetName().."Consolidation", buffs.proxy, "SecureFrameTemplate")
		consolidation:Hide()
		consolidation:SetIgnoreParentAlpha(true)
		consolidation:SetSize(36, 36)
		consolidation:SetPoint("TOPRIGHT", proxy, "TOPLEFT", -6, 0)
		consolidation:SetAttribute("minHeight", nil)
		consolidation:SetAttribute("minWidth", nil)
		consolidation:SetAttribute("point", "TOPRIGHT")
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
				buffs:CallMethod("UpdateAlpha")
			else
				consolidation:Show()
				buffs:CallMethod("UpdateAlpha")
			end
		]])

		proxy.button = button

		-----------------------------------------
		-- Visibility
		-----------------------------------------
		-- The visibility driver used when visibility mode is set to auto.
		local visdriver = "[petbattle]hide;[@target,exists]hide;" -- always hide when these are true
		--visdriver = visdriver .. "[group,nocombat]show;" -- show when buffing / before pulls
		visdriver = visdriver .. "[mod:ctrl+shift]show;" -- show when ctrl + shift is held
		visdriver = visdriver .. "hide" -- hide otherwise

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

		visibility:SetAttribute("UpdateDriver", string_format([[
			local visdriver;
			local buffs = self:GetFrameRef("buffs");
			local auraMode = self:GetAttribute("auraMode");
			if (auraMode == -1) then
				visdriver = "hide";
			elseif (auraMode == 1) then
				visdriver = "[petbattle]hide;show";
			else
				visdriver = "%s";
			end
			self:SetAttribute("visdriver", visdriver);
			UnregisterStateDriver(self, "vis");
			RegisterStateDriver(self, "vis", visdriver);
		]], visdriver))

		self.visibility = visibility
	end
end

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

Auras.OnChatCommand = function(self, input)
	if (InCombatLockdown()) then
		return
	end

	local arg1, arg2 = self:GetArgs(string_lower(input))
	local db = self.db.profile

	if (arg1 == "show") then
		db.alwaysShowAuras = true
		db.alwaysHideAuras = false
	elseif (arg1 == "hide") then
		db.alwaysShowAuras = false
		db.alwaysHideAuras = true
	elseif (arg1 == "auto") then
		db.alwaysShowAuras = false
		db.alwaysHideAuras = false
	end

	self:UpdateSettings()
end

Auras.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then

		end
		self:ForAll("Update")
		self:UpdateAlpha()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			self:UpdateSettings()
		end
	end
end

Auras.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Auras", defaults)
	self:DisableBlizzard()
	self:SpawnAuras()
	self:RegisterChatCommand("auras", "OnChatCommand")
end

Auras.OnEnable = function(self)
	self:UpdateSettings()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterUnitEvent("UNIT_AURA", "UpdateAlpha", "player", "vehicle")
end
