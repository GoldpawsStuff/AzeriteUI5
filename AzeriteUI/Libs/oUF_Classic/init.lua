local _, ns = ...
ns.oUF = {}
ns.oUF.Private = {}

local version = select(4, GetBuildInfo())

ns.oUF.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.oUF.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.oUF.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.oUF.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
ns.oUF.isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
ns.oUF.isMists = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
ns.oUF.WoW10 = version >= 100000
ns.oUF.WoW11 = version >= 110000
ns.oUF.WoW12 = version >= 120000
