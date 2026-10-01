# Changelog

All notable changes to TrinketSwitcher are documented here.

## v1.0.0 - 2026-10-01

Initial stable release of TrinketSwitcher.

### Added
- Trinket priority queues for slots 13 and 14.
- Automatic out-of-combat trinket switching based on queue priority and cooldown readiness.
- Preemptive return to higher-priority trinkets when they become switch-ready.
- Cross-slot coordination so both slots do not fight over the same trinket.
- Manual mode per trinket slot with visible slot badges.
- In-combat glow hints for queued trinkets that are nearly ready.
- Ready glow support for equipped on-use trinkets.
- Mount-aware auto-pause with automatic restore after dismounting.
- Talent-based queue profiles with automatic profile switching.
- Minimap button, draggable trinket buttons, configurable tooltips, and options panel.
- Slash commands through `/ts` and `/trinketswitcher`.
- WoW Forever settings mirror for clients that write SavedVariables but do not read them back.
- Compatibility with the Retail-based WoW Forever API, including modern `C_Item` calls, talent configuration events, and the current color picker API.
- Bundled library dependencies: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, and LibDBIcon-1.0.

### Changed
- Forked the addon into a new standalone project named TrinketSwitcher.
- Renamed addon files, frame globals, saved variables, minimap registration, and slash commands for the new project.
- Made legacy event registration tolerant of events that are absent from the WoW Forever client.
- Cooldown handling now avoids arithmetic on protected cooldown values and pauses cooldown-based choices while the client marks values secret.

### Removed
- TBC mount-speed gear manager, including riding trinkets, Riding Crop/Skybreaker Whip handling, riding glove enchant handling, Mithril Spurs handling, and related minimap/options behavior.
- Special trinket system and related options panel.
