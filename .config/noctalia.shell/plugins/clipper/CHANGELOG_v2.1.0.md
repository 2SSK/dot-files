# Changelog v2.1.0

## Release Date
2026-02-08

## New Features

### Show Close Button
- Added optional X button in top-right corner of panel header
- Toggle available in Settings > General
- Provides alternative way to close the panel
- Button styled with error color on hover for clear visual feedback

## Bug Fixes

### Clipboard Selection Fix
- Fixed critical bug where only the last copied item could be selected from history
- Fixed issue where clipboard items couldn't be copied back to system clipboard
- Changed from two-process approach to direct shell pipe: `cliphist decode ID | wl-copy`
- Removed non-existent `stdout.data` API usage

### Note Persistence Fix
- Fixed bug where notes didn't persist after reopening panel
- Added missing `saveNoteCard()` call in `updateNoteCard()` function
- Notes now properly save to disk when modified

## Improvements

### Settings UI Enhancement
- Reorganized settings into tabbed interface using NTabs
- **General Tab**: Integrations, Features (PinCards/NoteCards toggles), Show Close Button
- **Appearance Tab**: Card color customization
- Improved settings organization and discoverability
- Added feature toggles with item counters showing current usage

### Translation System Synchronization
- Synchronized all 16 language files with consistent structure
- Removed unused translation keys
- All translation files now have identical key structure
- Maintained existing translations while adding new keys

### Code Quality
- Removed experimental "Close on Background Click" feature (not implementable in current Noctalia architecture)
- Cleaned up debug logging
- Removed temporary backup files
- Improved code organization

## Technical Details

### Fixed Functions
- `copyToClipboard()` in Main.qml (line 742-755)
- `updateNoteCard()` in Main.qml (added saveNoteCard call)

### Modified Components
- Settings.qml: Restructured with NTabBar/NTabView
- Panel.qml: Added optional close button with reactive visibility
- i18n/*.json: All 16 language files synchronized

### Removed Features
- "Close on Background Click" toggle and related code
- Panel behavior section in settings
- Related translation keys and properties

## Breaking Changes
None - all changes are backward compatible

## Known Issues
None

## Upgrade Notes
- Plugin will automatically migrate settings
- No user action required
- Existing pinned items and notecards will be preserved
