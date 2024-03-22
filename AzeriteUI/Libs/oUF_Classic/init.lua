local _, ns = ...
ns.oUF = {}
ns.oUF.Private = {}

local version = select(4, GetBuildInfo())

ns.oUF.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.oUF.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.oUF.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.oUF.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
--ns.oUF.isCata = WOW_PROJECT_ID == (WOW_PROJECT_CATA_CLASSIC or 99) -- NYI in first build
ns.oUF.isCata = (version >= 40400) and (version < 50000)
ns.oUF.WoW10 = version >= 100000
