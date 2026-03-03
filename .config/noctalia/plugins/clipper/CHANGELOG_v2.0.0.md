# Clipper Plugin - Changelog

## Version 2.0.0 (2026-02-05)

### 🎯 Major Changes

**New Feature: Add Selection to NoteCard**
- New IPC command: `addSelectionToNoteCard` 
- Captures selected text and presents context menu to add to existing notes or create new note
- Text is automatically formatted as bullet points with "- " prefix
- Integrated with Hyprland keybind: Super+V, X (chord)

**Translation System Overhaul**
- Migrated from `I18n.tr()` to `pluginApi?.tr()` across all files
- Added comprehensive `i18n/en.json` with 28 toast message keys
- All user-facing strings now use translation system with fallbacks
- Translation key structure: `component.key` (e.g., `toast.note-created`)

**Architecture Improvements**
- Fixed IPC handlers to use `pluginApi.withCurrentScreen()` instead of direct `Quickshell.screens[0]` access
- Added proper Component.onDestruction cleanup for 6 data structures (pinnedItems, noteCards, items, firstSeenById, imageCache, imageCacheOrder)
- Memory leak prevention with proper process termination
- Unified translation syntax: `pluginApi?.tr("key") || "fallback"`

### 📁 New Files

1. **NoteCardSelector.qml** (173 lines)
   - Fullscreen overlay for note selection menu
   - Synchronously loads notecards from files
   - Shows "Create New Note" + list of existing notes
   - Mouse-position-aware context menu
   - ESC to cancel, click outside to close

2. **NoteCard.qml** (~300 lines)
   - Updated visual style to match ClipboardCard
   - Icon + title left-aligned (not centered)
   - Transparent buttons without background
   - Increased font sizes (13-14px)
   - Auto-height expansion based on content
   - Drag handle on icon only (24px width)
   - All corners rounded on main card
   - Only top corners rounded on header

3. **NoteCardsPanel.qml** (updated)
   - Background click-to-close functionality
   - Controls moved to top-left corner
   - Note counter and add button repositioned
   - Starting Y position increased to 80px to avoid control overlap

### 🔧 Files Modified

**Main.qml** (+250 lines, massive refactoring)

*New IPC Handlers:*
- `addSelectionToNoteCard()` - Main entry point for feature
- Uses same pattern as `addSelectionToTodo()` for consistency

*New Functions:*
- `getSelectionAndShowNoteSelector()` - Triggers selection capture
- `showNoteCardSelector(text)` - Displays note selection menu
- `handleNoteCardSelected(noteId, noteTitle)` - Handles existing note selection
- `handleCreateNewNoteFromSelection()` - Creates new note with bullet text
- `appendTextToNoteCard(noteId, text)` - Adds bullet point to existing note

*New Process:*
- `getSelectionForNoteSelectorProcess` - Captures primary selection via wl-paste
- StdioCollector: `noteSelectionStdout`
- Calls `showNoteCardSelector()` on successful capture

*New Variants:*
- `NoteCardSelector` instances for each screen
- Registered as `noteCardSelector` property
- Connected to signal handlers for note selection/creation

*New Properties:*
- `noteCardSelector: null` - Reference to selector instance
- `pendingNoteCardText: ""` - Stores captured selection

*Translation Updates:*
- All 28 Toast messages now use `pluginApi?.tr()`
- String interpolation for dynamic values ({max}, {fileName}, {count})
- Consistent error handling with translated messages

*Bug Fixes:*
- Fixed `createNoteCard()` to call `saveNoteCard()` after creation
- Removed duplicate `saveNoteCard(newNote)` calls from wrong functions
- Fixed Component.onDestruction syntax error (duplicate `}`)

**i18n/en.json** (+30 keys)

*New Toast Section:*
```json
"toast": {
  "invalid-clipboard-item": "Invalid clipboard item",
  "max-pinned-items": "Maximum {max} pinned items reached",
  "note-created": "Note created",
  "note-not-found": "Note not found",
  "text-added-to-note": "Text added to note",
  "could-not-open-note-selector": "Could not open note selector",
  // ... 22 more keys
}
```

**NoteCard.qml** (visual redesign)
- Header layout changed from centered to left-aligned
- Icon (note) + title in RowLayout
- Drag handle isolated to icon Item (24px width)
- Separate MouseArea for title focus
- Transparent button styling: `colorBg: "transparent"`
- Font changes: removed bold, increased size to 14px
- Radius system: 
  - Main card: `radius: Style.radiusM` (all corners)
  - Header: `topLeftRadius/topRightRadius: Style.radiusM`, bottom: 0
- Auto-height expansion via ScrollView content measurement
- Size changed: 300x180 → 350x280px
- Title input wider, better usability

**NoteCardsPanel.qml**
- Background MouseArea with `z: -1` for click-to-close
- Controls repositioned to `anchors.top` + `anchors.left`
- Note counter + add button in top-left corner
- 16px margins from edges

**ClipboardCard.qml**
- Applied same radius pattern as NoteCard
- Main card: all corners rounded
- Header: top corners only

**BarWidget.qml**
- Migrated `I18n.tr()` → `pluginApi?.tr()`
- Keys: `bar.tooltip`, `context.toggle`, `context.settings`

**Settings.qml**
- Already had full translation coverage
- Verified all labels use `pluginApi?.tr()`

### 🎨 UI/UX Changes

**NoteCard Visual Updates:**
- More modern, cleaner look matching ClipboardCard
- Better readability with larger fonts
- Improved drag interaction (icon-only handle)
- Responsive to global radius settings (Style.radiusM)
- Auto-expands height based on content

**NoteCardsPanel Improvements:**
- Better spatial organization (controls top-left)
- No accidental close when clicking on notes
- Clear visual hierarchy

**Context Menu for Note Selection:**
- Appears at cursor position
- Smooth 150ms delay for compositor
- First option always "Create New Note"
- Separator before existing notes
- Note icons for visual distinction

### ⚙️ Technical Improvements

**Memory Management:**
- Cleanup of 6 data structures in Component.onDestruction
- Process termination for `getSelectionForNoteSelectorProcess`
- Proper array clearing: `items = []`, `imageCache = {}`

**Code Quality:**
- Consistent translation syntax across codebase
- No hardcoded user-facing strings
- Proper null-safe operators: `pluginApi?.tr()`
- Immutable array updates maintained

**IPC Architecture:**
- Correct use of `pluginApi.withCurrentScreen()` 
- No direct `Quickshell.screens` access in IPC handlers
- Consistent pattern with existing `addSelectionToTodo`

### 🐛 Bug Fixes

1. **Syntax Errors:**
   - Fixed duplicate `}` in Component.onDestruction
   - Removed extra closing braces in function declarations
   - Fixed missing `} catch(e) {` block in loadNoteCardsProc

2. **Runtime Errors:**
   - Fixed `ReferenceError: newNote is not defined` by removing invalid `saveNoteCard(newNote)` calls from functions that don't have access to `newNote`
   - Only `createNoteCard()` calls `saveNoteCard(newNote)` now

3. **Functional Issues:**
   - Fixed note selector not showing existing notes (timing issue with async loading)
   - Fixed "Create New Note" not working (signal connection verified)
   - Fixed notes not being saved to files (added `saveNoteCard()` call)

### 📝 Usage Examples

**IPC Commands:**
```bash
# Add selected text to note via keybind
qs -c noctalia-shell ipc call plugin:clipper addSelectionToNoteCard

# Or with dev repo
qs -c ~/dev/repo/noctalia ipc call plugin:clipper addSelectionToNoteCard
```

**Hyprland Keybind (chord):**
```bash
# In ~/.config/hypr/keybind.conf
binds = SUPER_L, V&C, exec, qs -c ~/dev/repo/noctalia ipc call plugin:clipper addSelectionToTodo
binds = SUPER_L, V&X, exec, qs -c ~/dev/repo/noctalia ipc call plugin:clipper addSelectionToNoteCard
```

**User Flow:**
1. Select text anywhere
2. Press Super+V (opens chord mode)
3. Press X (triggers addSelectionToNoteCard)
4. Context menu appears at cursor
5. Click "Create New Note" or select existing note
6. Text is added as bullet point: `- selected text`

### 📊 Statistics

**Lines Changed:**
- Main.qml: +250 lines
- NoteCard.qml: ~300 lines (redesigned)
- NoteCardSelector.qml: +173 lines (new)
- NoteCardsPanel.qml: +50 lines
- i18n/en.json: +30 keys
- Total: ~800 lines added/modified

**Files:**
- New: 1 file (NoteCardSelector.qml)
- Modified: 7 files
- Total: 8 files changed

**Translation Coverage:**
- 28 new toast message keys
- 100% coverage for user-facing strings
- All components use pluginApi?.tr()

### 🔄 Breaking Changes

**Translation System:**
- Old: `I18n.tr("clipboard.key", "Fallback")`
- New: `pluginApi?.tr("component.key") || "Fallback"`
- All plugins must update if they were using I18n

**IPC Handlers:**
- Now use `pluginApi.withCurrentScreen()` instead of `Quickshell.screens[0]`
- More robust multi-screen support

### 🚀 Next Steps (Future Enhancements)

1. **i18n Completion:**
   - Translate en.json to all other language files (de, es, fr, etc.)
   - Maintain identical structure across all languages

2. **Feature Enhancements:**
   - Resizable note cards
   - Rich text formatting
   - Note categories/tags
   - Search functionality

3. **Performance:**
   - Lazy loading for large note collections
   - Virtual scrolling if >20 notes

4. **Integration:**
   - Share notes between devices
   - Sync with cloud services

---

**Version:** 2.0.0  
**Date:** 2026-02-05  
**Author:** Development Team  
**Reviewed by:** Code Review (QML-code-reviewer.md)
