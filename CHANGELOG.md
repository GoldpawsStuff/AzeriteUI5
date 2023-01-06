# AzeriteUI5 for Dragonflight Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [5.0.18-Beta] 2023-01-06 (Dragonflight)
### Added
- Added the floating player castbar.
- Added latency, framerate, zone name, clock and new mail warning to the minimap.
- Added the styled MBB button to the minimap.

## [5.0.17-Alpha] 2023-01-06 (Dragonflight)
### Fixed
- Fixed an issue with unit names in raid groups.

## [5.0.16-Alpha] 2023-01-06 (Dragonflight)
### Added
- Added Combo Points, Arcane Charges, Chi, Holy Power, Soul Shards, Stagger and Runes.

## [5.0.15-Alpha] 2023-01-05 (Dragonflight)
### Changed
- Attempted to prevent actionbuttons from being grayed out while dragonriding.

### Fixed
- The editmode azerite preset will no longer unintentionally attempt to reset on every logon.

## [5.0.14-Alpha] 2023-01-05 (Dragonflight)
### Added
- Added XP and Reputation tracking.

### Fixed
- More tracker theme change fixes.
- Fixed an issue related to a chat tab alpha update hook.
- Party frames are now parented to their visibility driver and should hide when in a raid group.

## [5.0.13-Alpha] 2023-01-03 (Dragonflight)
### Fixed
- The issue where some unit frames would bug out from their color post updates not receiving a color should now be fixed.

## [5.0.12-Alpha] 2023-01-03 (Dragonflight)
### Changed
- Party frames no longer appear when in a raid group.
- Player buffs now have a dark gray border, while debuffs should be colored by school of magic, if any.

### Fixed
- Updated issues related to powerType colors causing the power crystal to sometimes bug out.
- Fixed an issue related to caching of objective tracker mask textures when toggling between blizzard and azerite modes.

## [5.0.11-Alpha] 2023-01-03 (Dragonflight)
### Changed
- Updated LibEditModeOverride.

## [5.0.10-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- The chat command messages about scaling and layouts will no longer be shown on every portal, zoning or teleport. Just after fresh logins and manual reloads.

## [5.0.9-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- The Azerite layout in the editmode will no longer reset on every single login. I did not intend for that to happen.

## [5.0.8-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- Fixed some bugs in the initial positioning of actionbars and unitframes on the initial login on a character.
- Fixed an issue that prevented our custom party (not raid) frames from showing.
- Attempted to work around the initial Azerite editmode preset being wrong by adding a forced timed profile reset on the initial login, or when the addon decides it's time for an update. We're still in Alpha, forced resets happen.

## [5.0.7-Alpha] 2022-12-29 (Dragonflight)
### Changed
- The blizzard compact party frames should no longer forcefully be disabled.

## [5.0.6-Alpha] 2022-12-29 (Dragonflight)
### Added
- Added startup chat messages to inform about `/resetscale` and `/resetlayout`.

## [5.0.5-Alpha] 2022-12-29 (Dragonflight)
### Changed
- The blizzard compact raid frames should no longer forcefully be disabled.

## [5.0.4-Alpha] 2022-12-29 (Dragonflight)
### Changed
- Reworked the retail health prediction post-update element to pass same values as the classic version, removing the need for extra function calls in the front-end.

### Fixed
- Added some missing post updates to correctly color actionbuttons.

## [5.0.3-Alpha] 2022-12-27 (Dragonflight)
### Added
- Clicking the middle mouse button on the minimap now opens the relevant expansion landing page like covenant, dragon stuff, order hall and so on.
- Mousewheel now zooms in and out on the minimap.

## [5.0.2-Alpha] 2022-12-27 (Dragonflight)
### Fixed
- Fixed an issue with heal prediction that caused a lot of bugs and broken health bars.

## [5.0.1-Alpha] 2022-12-23 (Dragonflight)
- First public commit.
