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

local Compressor, Serializer = LibStub("LibDeflate"), LibStub("AceSerializer-3.0")

-- Lua API
local pairs = pairs
local type = type

local defaults = { enabled = true }

local Module =  { defaults = defaults }

ns.ModulePrototype = Module

Module.GetDefaults = function(self)
	if (self.GenerateDefaults) then
		return self:GenerateDefaults()
	end
	return self.defaults
end

Module.EnableSettingsExport = function(self)
	ns.exportableSettings[self:GetName()] = true
end

Module.EnableLayoutExport = function(self)
	ns.exportableLayouts[self:GetName()] = true
end

Module.Export = function(self)
	if (not self.db.profile) then return end

	if (ns.exportableLayouts[self:GetName()]) then
		local encodedLayout = self:ExportLayouts()
	end

	if (ns.exportableSettings[self:GetName()]) then
		local encodedSettings = self:ExportSettings()
	end


end

Module.ExportLayouts = function(self)
	if (not ns.exportableLayouts[self:GetName()]) then return end

	local db = self.db.profile
	if (not db) then return end

	local defaults = self:GetDefaults()
	if (not defaults) then return end

	local exported = ns:PurgeOtherKeys(ns:Merge(ns:Copy(db), defaults), "savedPosition")

	local serialized = Serializer:Serialize(exported)
	local compressed = Compressor:CompressDeflate(serialized)
	local encoded = Compressor:EncodeForPrint(compressed)

	return encoded
end

Module.ExportSettings = function(self)
	if (not ns.exportableSettings[self:GetName()]) then return end

	local db = self.db.profile
	if (not db) then return end

	local defaults = self:GetDefaults()
	if (not defaults) then return end

	local exported = ns:PurgeKeys(ns:Merge(ns:Copy(db), defaults), "savedPosition")

	local serialized = Serializer:Serialize(exported)
	local compressed = Compressor:CompressDeflate(serialized)
	local encoded = Compressor:EncodeForPrint(compressed)

	return encoded
end

Module.Import = function(self, importString)
	if (not self.db.profile) then return end

end

Module.MergeLayouts = function(self, target, source, fallback)
	local db = target or self.db.profile
	if (not db) then return end

	local defaults = fallback or self:GetDefaults()
	if (not defaults) then return end

	-- Iterate default table
	-- to catch nilled out entries.
	for k in pairs(defaults) do

		-- Only merge layout data.
		if (k == "savedPosition") then

			local layoutTarget = db[k]
			local layoutSource = source[k]
			local layoutFallback = defaults[k]

			for i in pairs(layoutFallback) do

				-- Import anything that's not nil.
				if (layoutSource[i] ~= nil) then
					layoutTarget[i] = layoutSource[i]
				else
					-- Fallback to defaults for
					-- entries that are nil in the source.
					layoutTarget[i] = layoutFallback[i]
				end
			end

		end
	end

	return db
end

Module.MergeSettings = function(self, target, source, fallback)
	local db = target or self.db.profile
	if (not db) then return end

	local defaults = fallback or self:GetDefaults()
	if (not defaults) then return end

	-- Iterate default table
	-- to catch nilled out entries.
	for k in pairs(defaults) do

		-- Just ignore the layout tables in this method.
		if (k ~= "savedPosition") then

			-- Deep merge.
			if (type(defaults[k]) == "table") then
				db[k] = self:MergeSettings(db[k], source[k], defaults[k])
			else
				-- Import anything that's not nil.
				if (source[k] ~= nil) then
					db[k] = source[k]
				else
					-- Fallback to defaults for
					-- entries that are nil in the source.
					db[k] = defaults[k]
				end
			end
		end

	end

	return db
end

ns:SetDefaultModulePrototype(ns.ModulePrototype)
