# Clipper v2.0.0 Release Notes

**Release Date**: 2026-02-05

## 🎉 Major Features

### 📝 NoteCards (Sticky Notes)
Brand new sticky notes system for quick note-taking:
- Individual JSON storage for each notecard
- Editable titles and auto-saving content
- 8 color presets for organization
- Export to TXT files
- Add selected text directly to notecards via keybind
- Drag to reorder (visual feedback)

**Demo**: [Notecard Preview.mp4](Assets/Notecard%20Preview.mp4)

### ✅ Enhanced ToDo Integration
Completely revamped ToDo integration:
- Selection-to-ToDo with visual page selector
- Context menu for adding clipboard items to specific pages
- Fixed pageId type handling (int instead of string)
- Proper active selector routing

**Demo**: [ToDo Preview.mp4](Assets/ToDo%20Preview.mp4)

### 🌍 Complete Translation Coverage
- 16 languages fully supported
- 30+ toast messages translated
- All UI strings use `pluginApi?.tr()`
- Synchronized structure across all language files

## 🔧 Bug Fixes

### Critical Fixes
- ✅ Fixed `addSelectionToTodo` not adding items to correct page
- ✅ Fixed pageId type (string → int) causing ToDo filtering issues
- ✅ Fixed `handleTodoPageSelected` syntax error (missing closing brace)
- ✅ Fixed selector routing with `activeSelector` property

### High Priority Fixes
- ✅ Fixed timer memory leak in NoteCardsPanel.qml
- ✅ Fixed all hardcoded strings (now use translations)
- ✅ Fixed `appendTextToNoteCard` mutation (now immutable)

### Medium Priority Fixes
- ✅ Added Component.onDestruction cleanup to ClipboardCard.qml
- ✅ Removed all console.log debug statements
- ✅ Removed debug stack traces from Noctalia core

## 🎨 Improvements

### Architecture
- Immutable data patterns throughout codebase
- Proper memory cleanup (timers, processes, connections)
- Active selector routing for context menus
- No internal IPC calls (only external API)

### User Experience
- Universal SelectionContextMenu component
- Smooth notecard interactions
- Visual feedback for all operations
- Consistent color scheme customization

### Performance
- Zero memory leaks (tested with 500+ operations)
- Efficient ListModel-based rendering
- Proper garbage collection

## 📦 Technical Details

### Files Changed
- Main.qml (1176 lines) - Core logic and IPC handlers
- TodoPageSelector.qml - Fixed pageId type
- SelectionContextMenu.qml - Universal context menu
- Panel.qml, NoteCardsPanel.qml - UI improvements
- Settings.qml - Enhanced configuration
- i18n/*.json - All 16 files synchronized

### New Dependencies
None - still uses cliphist and wl-clipboard

### Breaking Changes
None - fully backward compatible with v1.x settings

## 🚀 Upgrade Instructions

### From v1.x
1. **Backup your data** (optional, but recommended):
   ```bash
   cp -r ~/.config/noctalia/plugins/clipper/pinned.json ~/clipper-backup.json
   ```

2. **Update plugin**:
   - Via Plugin Manager: Update button in Noctalia Settings
   - Via Git:
     ```bash
     cd ~/.config/noctalia/plugins/clipper
     git pull
     ```

3. **Reload Noctalia**:
   ```bash
   qs -c noctalia-shell reload
   ```

4. **No migration needed** - all settings and pinned items preserved!

### Fresh Install
See [README.md](README.md) for installation instructions.

## 🎬 Media

### Screenshots
![Clipboard Preview](Assets/clipboard-preview.png)

### Videos
- [Notecard Preview.mp4](Assets/Notecard%20Preview.mp4)
- [ToDo Preview.mp4](Assets/ToDo%20Preview.mp4)

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## 🙏 Acknowledgments

Special thanks to:
- Code reviewers who identified all issues
- Memory leak testers
- Translation contributors
- Noctalia Shell team

## 🐛 Known Issues

None currently! 🎉

If you find any bugs, please report at:
https://github.com/blackbartblues/noctalia-clipper/issues

## 💡 What's Next?

Planned for v2.1.0:
- Notecard categories/folders
- Search within notecards
- Rich text formatting
- Notecard templates
- Cloud sync (optional)

---

**Enjoy Clipper v2.0.0!** 🚀
