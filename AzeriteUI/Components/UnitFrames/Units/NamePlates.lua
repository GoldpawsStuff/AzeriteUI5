local callback = function(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
	elseif (event == "NAME_PLATE_UNIT_ADDED") then
        local frame = self
        local guid = UnitGUID(unit)
        local canAttack = UnitCanAttack("player", unit)
        local healthMax = UnitHealthMax(unit) or 0

        if (not canAttack and healthMax == 0) then
            if frame.SoftTargetFrame then
                frame.SoftTargetFrame:Show()
                frame.SoftTargetFrame:SetAlpha(1)
            end
            if frame.Health then frame.Health:Hide() end
            if frame.Power then frame.Power:Hide() end
            if frame.Castbar then frame.Castbar:Hide() end
            if frame.Name then frame.Name:Hide() end
            if frame.RaidTargetIndicator then frame.RaidTargetIndicator:Hide() end
            if frame.Classification then frame.Classification:Hide() end
            if frame.Auras then frame.Auras:Hide() end
            if frame.TargetHighlight then frame.TargetHighlight:Hide() end
        end

		self.isPRD = UnitIsUnit(unit, "player")

		if (self.WidgetContainer) then
			if (NamePlatesMod.db.profile.showBlizzardWidgets) then
				local db = ns.GetConfig("NamePlates")

				self.WidgetContainer:SetIgnoreParentAlpha(true)
				self.WidgetContainer:SetParent(self)
				self.WidgetContainer:ClearAllPoints()
				self.WidgetContainer:SetPoint(unpack(db.WidgetPosition))

				local widgetFrames = self.WidgetContainer.widgetFrames

				if (widgetFrames) then
					for _, frame in next, widgetFrames do
						if (frame.Label) then
							frame.Label:SetAlpha(0)
						end
					end
				end
			else
				self.WidgetContainer:SetParent(ns.Hider)
			end
		end

		if (self.SoftTargetFrame) then
			self.SoftTargetFrame:SetIgnoreParentAlpha(true)
			self.SoftTargetFrame:SetParent(self)
			self.SoftTargetFrame:ClearAllPoints()
			self.SoftTargetFrame:SetPoint("BOTTOM", self.Name, "TOP", 0, 0)
		end

		ns.NamePlates[self] = true
		ns.ActiveNamePlates[self] = true

	elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if self.Health then self.Health:Show() end
        if self.Power then self.Power:Show() end
        if self.Castbar then self.Castbar:Show() end
        if self.Name then self.Name:Show() end
        if self.RaidTargetIndicator then self.RaidTargetIndicator:Show() end
        if self.Classification then self.Classification:Show() end
        if self.Auras then self.Auras:Show() end
        if self.TargetHighlight then self.TargetHighlight:Show() end

		if (self.WidgetContainer) then
			if (NamePlatesMod.db.profile.showBlizzardWidgets) then
				self.WidgetContainer:SetIgnoreParentAlpha(false)
				self.WidgetContainer:SetParent(self.blizzPlate)
				self.WidgetContainer:ClearAllPoints()
			end
		end

		if (self.SoftTargetFrame) then
			self.SoftTargetFrame:SetIgnoreParentAlpha(false)
			self.SoftTargetFrame:SetParent(self.blizzPlate)
			self.SoftTargetFrame:ClearAllPoints()
			self.SoftTargetFrame:SetPoint("BOTTOM", self.blizzPlate.name, "TOP", 0, -8)
		end

		self.isPRD = nil
		self.inCombat = nil
		self.isFocus = nil
		self.isTarget = nil
		self.isSoftEnemy = nil
		self.isSoftInteract = nil

		ns.ActiveNamePlates[self] = nil
	end
end