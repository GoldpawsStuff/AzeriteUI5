# LibActionButton-1.0-GE Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] 2024-07-24
### Fixed
- Various fixes for WoW Retail 11.0.0.

## [1.0.126-Alpha] 2024-02-07
### Fixed
- Various fixes for WoW Classic Era 1.15.1.

## [1.0.125-Alpha] 2023-12-18
### Changed
- Don't show hotkeys under any circumstances if the button config says to hide them.

## [1.0.124-Alpha] 2023-12-17
### Added
- Attempted to map `GetMacroSpell` to `Macro:GetSpellId()` for better results with MaxDps.

### Changed
- Improved the logic in the MaxDps prehooks.

## [1.0.123-Alpha] 2023-12-13
### Added
- Added a `button:ForceUpdate()` method to manually trigger a full button update.

## [1.0.122-Alpha] 2023-10-31
### Fixed
- Fixed how the public methods `lib:ShowOverlayGlow(button[, r, g, b[, a]])` and `lib:HideOverlayGlow(button)` handles input arguments to work better with SpellActivationOverlay.

## [1.0.121-Alpha] 2023-10-30
### Changed
- Moved `dimWhenResting` and `dimWhenInactive` to button config.

## [1.0.120-Alpha] 2023-10-22
### Changed
- Added the public library methods `lib:ShowOverlayGlow(button[, r, g, b[, a]])` and `lib:HideOverlayGlow(button)` to improve compatibility with external addons utilizing our button's overlay glow feature.

## [1.0.119-Alpha] 2023-10-21
### Changed
- Don't dim buttons while in a vehicle, when using an override bar or when using a temporary shapeshift bar.

## [1.0.118-Alpha] 2023-10-21
### Changed
- Don't dim buttons while Dragonriding.

## [1.0.117-Alpha] 2023-10-18
### Added
- Added a simplistic SpellActivationOverlay (Classic Era, Wrath) integration.

## [1.0.110-Alpha] 2023-09-13
### Added
- Added a custom spell activation overlay glow system.
- Added a simplistic MaxDps (Retail) integration utilizing the above.

### Changed
- Hid stack counts when the count is one or less.
- Hid charge counts when the count is zero.

### Removed
- Removed new action highlighting completely.
- Removed third party integrations for styling and overlay glows.
