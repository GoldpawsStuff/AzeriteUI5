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

if (not C_Container) then return print("C_Container not found") end

local Containers = ns:NewModule("Containers", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

local defaults = { profile = ns:Merge({
	sort = "rtl",
	insert = "ltr"
}, ns.Module.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Containers.GenerateDefaults = function(self)
	return defaults
end

Containers.AquireBagButtons = function(self)

	-- Don't interfere with known bag addons.
	for _,addon in next,{ "AdiBags", "ArkInventory", "Bagnon", "Combuctor" } do
		if (ns.API.IsAddOnEnabled(addon)) then return end
	end

	-- Attempt to hook the bag bar to the bags
	-- Retrieve the first slot button and the backpack
	local firstSlot = CharacterBag0Slot
	local backpack = ContainerFrame1
	local combined = ContainerFrameCombinedBags -- Retail
	local reagentSlot = CharacterReagentBag0Slot -- Retail
	local keyring = KeyRingButton -- Classic, Wrath
	local slots = {
		"CharacterBag0Slot",
		"CharacterBag1Slot",
		"CharacterBag2Slot",
		"CharacterBag3Slot",
		"CharacterReagentBag0Slot" -- >= 10.0.0
	}

	-- Try to avoid the potential error with anima deposit animations.
	-- Just give it a simplified version of the default position it is given,
	-- it will be replaced by UpdateContainerFrameAnchors() later on anyway.
	if (not backpack:GetPoint()) then
		backpack:SetPoint("BOTTOMRIGHT", backpack:GetParent(), "BOTTOMRIGHT", -14, 93 )
	end

	-- These should always exist, but Blizz do have a way of changing things,
	-- and I prefer having functionality not be applied in a future update
	-- rather than having the UI break from nil bugs.
	if (firstSlot and backpack) then
		firstSlot:ClearAllPoints()
		firstSlot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 0)

		local strata = backpack:GetFrameStrata()
		local level = backpack:GetFrameLevel()

		-- Rearrange slots
		-- *Dragonflight features a reagent bag slot
		local slotSize = reagentSlot and 24 or 30
		local previous
		for i,slotName in ipairs(slots) do

			-- Always check for existence,
			-- because nothing is ever guaranteed.
			local slot = _G[slotName]
			if (slot) then
				slot:SetParent(backpack)
				slot:SetSize(slotSize,slotSize)
				slot:SetFrameStrata(strata)
				slot:SetFrameLevel(level)

				-- Remove that fugly outer border
				local tex = _G[slotName.."NormalTexture"]
				if tex then
					tex:SetTexture("")
					tex:SetAlpha(0)
				end

				-- Re-anchor the slots to remove space
				if (not previous) then
					slot:ClearAllPoints()
					slot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 4)
				else
					slot:ClearAllPoints()
					slot:SetPoint("RIGHT", previous, "LEFT", 0, 0)
				end
				previous = slot
			end
		end

		if (keyring) then
			keyring:SetParent(backpack)
			keyring:SetHeight(slotSize)
			keyring:SetFrameStrata(strata)
			keyring:SetFrameLevel(level)
			keyring:ClearAllPoints()
			keyring:SetPoint("RIGHT", previous, "LEFT", 0, 0)
			previous = keyring
		end
	end

	if (combined) then

		self:HookScript(backpack, "OnShow", function()
			firstSlot:SetParent(backpack)
			firstSlot:ClearAllPoints()
			firstSlot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 4)

			for _,slotName in ipairs(slots) do
				-- Always check for existence,
				-- because nothing is ever guaranteed.
				local slot = _G[slotName]
				if (slot) then
					slot:SetParent(backpack)
				end
			end

		end)

		self:HookScript(combined, "OnShow", function()
			firstSlot:SetParent(combined)
			firstSlot:ClearAllPoints()
			firstSlot:SetPoint("TOPRIGHT", combined, "BOTTOMRIGHT", -6, 4)

			for _,slotName in ipairs(slots) do
				-- Always check for existence,
				-- because nothing is ever guaranteed.
				local slot = _G[slotName]
				if (slot) then
					slot:SetParent(combined)
				end
			end

		end)

	end
end

Containers.UpdateSettings = function(self)
	if (C_Container.SetSortBagsRightToLeft) then
		if (self.db.profile.sort == "rtl") then
			C_Container.SetSortBagsRightToLeft(true)
		elseif (self.db.profile.sort == "ltr") then
			C_Container.SetSortBagsRightToLeft(false)
		end
	end
	if (C_Container.SetInsertItemsLeftToRight) then
		if (self.db.profile.insert == "ltr") then
			C_Container.SetInsertItemsLeftToRight(true)
		elseif (self.db.profile.insert == "rtl") then
			C_Container.SetInsertItemsLeftToRight(false)
		end
	end
end

Containers.OnEnable = function(self)
	self:AquireBagButtons()
end
