import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Noctalia
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  // Panel settings control
  property bool showCloseButton: false

  // Auto-paste support
  property bool wtypeAvailable: false

  // Watch for pluginApi changes and initialize settings
  onPluginApiChanged: {
    if (pluginApi) {
      showCloseButton = pluginApi.pluginSettings?.showCloseButton ?? false;
    }
  }

  // Pending selected text for ToDo selector
  property string pendingSelectedText: ""

  // Pinned items data
  property var pinnedItems: []
  property int pinnedRevision: 0

  // Note cards data
  property var noteCards: []
  property int noteCardsRevision: 0

  // Clipboard items from cliphist
  property var items: []
  property bool loading: false
  property var firstSeenById: ({})

  // Image cache (id -> data URL) with LRU eviction
  property var imageCache: ({})
  property var imageCacheOrder: []  // Track insertion order for LRU
  property int imageCacheRevision: 0  // Incremented when cache changes (for reactive bindings)
  readonly property int maxImageCacheSize: 50  // Limit cache to 50 entries

  // Pending pageId for async operations (ToDo integration)
  property int pendingPageId: 0

  // Constants for limits
  readonly property int maxPinnedItems: 20          // Maximum number of pinned items
  readonly property int maxNoteCards: 20      // Maximum number of note cards
  readonly property int maxTodoTextLength: 500      // Maximum text length for ToDo items
  readonly property int maxImageSize: 5 * 1024 * 1024   // 5MB - max image size for pinning
  readonly property int maxTextSize: 1 * 1024 * 1024    // 1MB - max text size for pinning
  readonly property int maxPreviewImageSize: 10 * 1024 * 1024  // 10MB - max image size for preview

  // FileView for pinned.json
  FileView {
    id: pinnedFile
    path: Quickshell.env("HOME") + "/.config/noctalia/plugins/clipper/pinned.json"
    watchChanges: true

    onLoaded: {
      try {
        const data = JSON.parse(text());
        root.pinnedItems = data.items || [];
        root.pinnedRevision++;
      } catch (e) {
        root.pinnedItems = [];
      }
    }
  }

  // NoteCards directory path
  readonly property string noteCardsDir: Quickshell.env("HOME") + "/.config/noctalia/plugins/clipper/notecards"

  // Process to load all notecards from directory
  Process {
    id: loadNoteCardsProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: exitCode => {
                // Never wipe in-memory notes on shell-level error — the files
                // are still on disk and would silently disappear from the UI.
                if (exitCode !== 0) {
                  Logger.w("Clipper", "loadNoteCards: shell exit=" + exitCode + ", keeping in-memory notes");
                  return;
                }

                try {
                  const output = String(stdout.text).trim();
                  if (!output || output === "[]") {
                    // Empty load result. Only clear in-memory state when it
                    // was already empty; otherwise preserve it. This avoids
                    // wiping freshly-created (still-being-saved) notes if the
                    // disk listing raced ahead of the atomic-write rename.
                    if (root.noteCards.length === 0) {
                      root.noteCardsRevision++;
                    }
                    return;
                  }

                  const loadedNotes = JSON.parse(output);
                  if (Array.isArray(loadedNotes)) {
                    root.noteCards = loadedNotes;
                    root.noteCardsRevision++;
                  }
                } catch (e) {
                  Logger.w("Clipper", "loadNoteCards: parse error, keeping in-memory notes: " + e);
                }
              }
  }

  // Function to load all notecards.
  // IMPORTANT: per-file validation — a single malformed or 0-byte .json
  // file must NOT wipe all notes. The previous `jq -s '.' *.json` approach
  // was all-or-nothing: any bad file made jq exit non-zero, the
  // `|| echo '[]'` fallback returned an empty array, and onExited cleared
  // root.noteCards even though every other note was intact on disk.
  function loadNoteCards() {
    // Capture concatenated valid files into a single var, then decide.
    // jq -s reads a stream of JSON values with no required separator, so
    // concatenating is enough — we never feed it empty or malformed input.
    const script = 'cd "$1" 2>/dev/null || { echo "[]"; exit 0; }; ' +
                   'shopt -s nullglob; ' +
                   'out=$(for f in *.json; do ' +
                   '  jq -e . "$f" >/dev/null 2>&1 && cat "$f"; ' +
                   'done); ' +
                   'if [ -z "$out" ]; then echo "[]"; ' +
                   'else printf "%s" "$out" | jq -s "."; fi';
    loadNoteCardsProc.command = ["bash", "-c", script, "loadNoteCards", root.noteCardsDir];
    loadNoteCardsProc.running = true;
  }

  // Helper function to add to image cache with LRU eviction
  function addToImageCache(cliphistId, dataUrl) {
    // Remove from order if already exists (will re-add at end)
    const existingIndex = root.imageCacheOrder.indexOf(cliphistId);
    if (existingIndex !== -1) {
      root.imageCacheOrder = root.imageCacheOrder.filter((_, i) => i !== existingIndex);
    }

    // Evict oldest entries if at capacity
    while (root.imageCacheOrder.length >= maxImageCacheSize) {
      const oldestKey = root.imageCacheOrder[0];
      root.imageCacheOrder = root.imageCacheOrder.slice(1);
      const newCache = Object.assign({}, root.imageCache);
      delete newCache[oldestKey];
      root.imageCache = newCache;
    }

    // Add new entry
    root.imageCache = Object.assign({}, root.imageCache, {
                                      [cliphistId]: dataUrl
                                    });
    root.imageCacheOrder = [...root.imageCacheOrder, cliphistId];
    root.imageCacheRevision++;
  }

  // Clear caches (called on wipe)
  function clearCaches() {
    root.imageCache = {};
    root.imageCacheOrder = [];
    root.imageCacheRevision++;
    root.firstSeenById = {};
  }

  // Shared item type detection (used by Panel and ClipboardCard)
  function getItemType(item) {
    if (!item)
      return "Text";
    if (item.isImage)
      return "Image";

    const preview = item.preview || "";
    const trimmed = preview.trim();

    // Color detection
    if (/^#[A-Fa-f0-9]{6}$/.test(trimmed) || /^#[A-Fa-f0-9]{3}$/.test(trimmed))
      return "Color";
    if (/^[A-Fa-f0-9]{6}$/.test(trimmed))
      return "Color";
    if (/^rgba?\s*\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$/i.test(trimmed))
      return "Color";

    // Link detection
    if (/^https?:\/\//.test(trimmed))
      return "Link";

    // Code detection
    if (preview.includes("function") || preview.includes("import ") || preview.includes("const ") || preview.includes("let ") || preview.includes("var ") || preview.includes("class ") || preview.includes("def ") || preview.includes("return ") || /^[\{\[\(<]/.test(trimmed))
      return "Code";

    // Emoji detection
    if (trimmed.length <= 4 && trimmed.length > 0 && trimmed.charCodeAt(0) > 255)
      return "Emoji";

    // File path detection
    if (/^(\/|~|file:\/\/)/.test(trimmed))
      return "File";

    return "Text";
  }

  // Process to list cliphist items
  Process {
    id: listProc
    stdout: StdioCollector {}

    onExited: exitCode => {
                if (exitCode !== 0) {
                  root.items = [];
                  root.loading = false;
                  return;
                }

                const out = String(stdout.text);
                const lines = out.split('\n').filter(l => l.length > 0);

                const parsed = lines.map(l => {
                                           let id = "";
                                           let preview = "";
                                           const m = l.match(/^(\d+)\s+(.+)$/);
                                           if (m) {
                                             id = m[1];
                                             preview = m[2];
                                           } else {
                                             const tab = l.indexOf('\t');
                                             id = tab > -1 ? l.slice(0, tab) : l;
                                             preview = tab > -1 ? l.slice(tab + 1) : "";
                                           }

                                           const lower = preview.toLowerCase();
                                           const isImage = lower.startsWith("[image]") || lower.includes(" binary data ");

                                           var mime = "text/plain";
                                           if (isImage) {
                                             if (lower.includes(" png"))
                                             mime = "image/png";
                                             else if (lower.includes(" jpg") || lower.includes(" jpeg"))
                                             mime = "image/jpeg";
                                             else if (lower.includes(" webp"))
                                             mime = "image/webp";
                                             else if (lower.includes(" gif"))
                                             mime = "image/gif";
                                             else
                                             mime = "image/*";
                                           }

                                           if (!root.firstSeenById[id]) {
                                             root.firstSeenById[id] = Date.now();
                                           }

                                           return {
                                             "id": id,
                                             "preview": preview,
                                             "isImage": isImage,
                                             "mime": mime
                                           };
                                         });

                root.items = parsed;
                root.loading = false;
              }
  }

  // Function to pin item - use preview from items list
  function pinItem(cliphistId) {
    // Validate cliphistId is numeric only (prevents command injection)
    if (!cliphistId || !/^\d+$/.test(String(cliphistId))) {
      ToastService.showError(pluginApi?.tr("toast.invalid-clipboard-item"));
      return;
    }

    if (root.pinnedItems.length >= maxPinnedItems) {
      ToastService.showWarning(pluginApi?.tr("toast.max-pinned-items").replace("{max}", maxPinnedItems));
      return;
    }

    // Find item in current items list to get preview
    const item = root.items.find(i => i.id === cliphistId);
    if (!item) {
      ToastService.showError(pluginApi?.tr("toast.item-not-found"));
      return;
    }

    const pinnedId = "pinned-" + Date.now() + "-" + cliphistId;

    const newItem = {
      id: pinnedId,
      cliphistId: cliphistId,  // Keep original ID for image decode
      content: "",  // Will be filled for text items
      preview: item.preview,  // Use preview from list
      mime: item.mime || "text/plain",
      isImage: item.isImage || false,
      pinnedAt: Date.now()
    };

    // Decode content (text or image data)
    decodeProc.cliphistId = cliphistId;
    decodeProc.pinnedItem = newItem;

    if (newItem.isImage) {
      // For images, pipe through base64 to avoid binary corruption
      decodeProc.command = ["sh", "-c", `cliphist decode ${cliphistId} | base64 -w 0`];
    } else {
      // For text, direct decode
      decodeProc.command = ["cliphist", "decode", String(cliphistId)];
    }
    decodeProc.running = true;
  }

  // Process to decode content for pinning
  Process {
    id: decodeProc
    property string cliphistId: ""
    property var pinnedItem: null
    stdout: StdioCollector {}

    onExited: exitCode => {
                if (exitCode !== 0) {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-pin"));
                  return;
                }

                if (pinnedItem.isImage) {
                  // For images, stdout.text contains base64-encoded data
                  const base64 = String(stdout.text).trim();
                  if (!base64 || base64.length === 0) {
                    ToastService.showError(pluginApi?.tr("toast.failed-to-pin-image"));
                    return;
                  }

                  // Validate image size (approximate: base64 is ~33% larger)
                  const estimatedSize = (base64.length * 3) / 4;
                  if (estimatedSize > root.maxImageSize) {
                    ToastService.showWarning(pluginApi?.tr("toast.image-too-large"));
                    return;
                  }

                  const dataUrl = "data:" + pinnedItem.mime + ";base64," + base64;
                  pinnedItem.content = dataUrl;
                } else {
                  // For text, validate size (max 1MB)
                  const textContent = String(stdout.text);
                  if (textContent.length > root.maxTextSize) {
                    ToastService.showWarning(pluginApi?.tr("toast.text-too-large"));
                    return;
                  }

                  pinnedItem.content = textContent;
                }

                // Add to array
                root.pinnedItems = [...root.pinnedItems, pinnedItem];

                // Save to file
                root.savePinnedFile();

                // Delete from cliphist
                Quickshell.execDetached(["cliphist", "delete", String(cliphistId)]);

                root.pinnedRevision++;
                ToastService.showNotice(pluginApi?.tr("toast.item-pinned"));
              }
  }

  // Atomic write: payload arrives via stdin, lands in <path>.tmp, then is
  // renamed onto the target. Optional `oldPath` is removed only after the
  // new file is verified non-empty and renamed, so a failed save never wipes
  // existing data. Replaces the previous Quickshell.execDetached + base64
  // pipeline, which silently failed in noctalia-qs 0.0.x (no file ever
  // appeared on disk despite saveNoteCard firing). Process gives us exit
  // codes and stderr; the queue serializes saves because Process is
  // single-instance. Each queue entry: { content, path, oldPath, id }.
  property var _atomicWriteQueue: []
  property var _atomicWriteCurrent: null
  property bool _atomicWriteBusy: false

  Process {
    id: atomicWriteProc
    running: false
    stdinEnabled: true
    stderr: StdioCollector {}

    onExited: (exitCode, exitStatus) => {
                const job = root._atomicWriteCurrent;
                root._atomicWriteCurrent = null;
                root._atomicWriteBusy = false;
                stdinEnabled = true;
                if (exitCode !== 0) {
                  Logger.w("Clipper", "atomicWrite FAIL exit=" + exitCode +
                                      " id=" + (job ? job.id : "?") +
                                      " path=" + (job ? job.path : "?") +
                                      " stderr=" + String(stderr.text).trim());
                }
                root._drainAtomicWriteQueue();
              }
  }

  function _drainAtomicWriteQueue() {
    if (_atomicWriteBusy || _atomicWriteQueue.length === 0)
      return;

    const job = _atomicWriteQueue.shift();
    _atomicWriteCurrent = job;
    _atomicWriteBusy = true;

    const script = 'p="$1"; t="${p}.tmp"; o="$2"; ' +
                   'cat > "$t" && ' +
                   '[ -s "$t" ] && ' +
                   'mv -f "$t" "$p" && ' +
                   '{ [ -z "$o" ] || [ "$o" = "$p" ] || rm -f "$o"; } ' +
                   '|| { rm -f "$t"; exit 1; }';
    atomicWriteProc.command = ["sh", "-c", script, "atomicWrite",
                               job.path, job.oldPath || ""];
    atomicWriteProc.stdinEnabled = true;
    atomicWriteProc.running = true;
    atomicWriteProc.write(job.content);
    atomicWriteProc.stdinEnabled = false;
  }

  // Public entry point. `oldPath` may be empty; if non-empty and different
  // from `path`, it is removed only after the new file is safely on disk.
  function atomicWrite(filePath, content, oldFilePath, id) {
    if (!filePath || typeof filePath !== "string") {
      Logger.w("Clipper", "atomicWrite: missing filePath");
      return;
    }
    if (!content || content.length === 0) {
      Logger.w("Clipper", "atomicWrite: refusing empty write to " + filePath);
      return;
    }
    _atomicWriteQueue.push({
                             content: content,
                             path: filePath,
                             oldPath: oldFilePath || "",
                             id: id || ""
                           });
    _drainAtomicWriteQueue();
  }

  // Function to save pinned items to file
  function savePinnedFile() {
    const data = {
      items: root.pinnedItems
    };
    const json = JSON.stringify(data, null, 2);
    const filePath = Quickshell.env("HOME") + "/.config/noctalia/plugins/clipper/pinned.json";
    atomicWrite(filePath, json, "", "pinned");
  }

  // Function to unpin item
  function unpinItem(pinnedId) {
    root.pinnedItems = root.pinnedItems.filter(item => item.id !== pinnedId);
    root.savePinnedFile();
    root.pinnedRevision++;
    ToastService.showNotice(pluginApi?.tr("toast.item-unpinned"));
  }

  // ==================== SCRATCHPAD FUNCTIONS ====================

  // Function to create a new scratchpad note
  function createNoteCard(initialText) {
    if (root.noteCards.length >= maxNoteCards) {
      ToastService.showWarning(pluginApi?.tr("toast.max-notes").replace("{max}", maxNoteCards));
      return null;
    }

    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    const noteId = "note_" + timestamp + "_" + randomSuffix;

    // Cascade positioning: offset by 30px for each new note
    const cascadeOffset = (root.noteCards.length % 10) * 30;
    const baseX = 20 + cascadeOffset;
    const baseY = 80 + cascadeOffset;

    // Find highest z-index
    let maxZ = 0;
    for (let i = 0; i < root.noteCards.length; i++) {
      if (root.noteCards[i].zIndex > maxZ) {
        maxZ = root.noteCards[i].zIndex;
      }
    }

    const newNote = {
      id: noteId,
      title: "",
      isPrivate: false,
      content: initialText || "",
      x: baseX,
      y: baseY,
      width: 350,
      height: 280,
      zIndex: maxZ + 1,
      color: "yellow",
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString()
    };

    // Immutable array update
    const newNotes = root.noteCards.slice();
    newNotes.push(newNote);
    root.noteCards = newNotes;
    root.noteCardsRevision++;

    // Save to file
    saveNoteCard(newNote);

    ToastService.showNotice(pluginApi?.tr("toast.note-created"));
    return noteId;
  }

  // Function to update a note card
  function updateNoteCard(noteId, updates) {
    const index = root.noteCards.findIndex(n => n.id === noteId);
    if (index === -1) {
      return;
    }

    const oldNote = root.noteCards[index];
    const oldFilename = getNoteFilename(oldNote);

    // Immutable update with Object.assign
    const updatedNote = Object.assign({}, oldNote, updates, {
                                        lastModified: new Date().toISOString()
                                      });

    const newFilename = getNoteFilename(updatedNote);

    // Track the stale filename so saveNoteCard / atomicWrite can delete it
    // only AFTER the new file is successfully on disk. The pre-2.4.3 code
    // fired rm and save in parallel via execDetached, which could reorder
    // so that rm landed after a failed save — wiping both files at once.
    let oldFilePathToReplace = "";
    if (oldFilename !== newFilename && updates.title !== undefined) {
      oldFilePathToReplace = root.noteCardsDir + "/" + oldFilename;
    }

    // Immutable array update
    const newNotes = root.noteCards.slice(0, index);
    newNotes.push(updatedNote);
    const remaining = root.noteCards.slice(index + 1);
    for (let i = 0; i < remaining.length; i++) {
      newNotes.push(remaining[i]);
    }
    root.noteCards = newNotes;
    root.noteCardsRevision++;

    // Save to file (old filename is removed only on successful new save)
    saveNoteCard(updatedNote, oldFilePathToReplace);
  }

  // Function to delete a note card
  function deleteNoteCard(noteId) {
    const note = root.noteCards.find(n => n.id === noteId);
    if (note) {
      const filename = getNoteFilename(note);
      const filePath = root.noteCardsDir + "/" + filename;
      Quickshell.execDetached(["rm", "-f", filePath]);

      // Delete all exported .txt files - validate each filename before deletion
      const safePattern = /^notecard_\d{6}-\d{6}\.txt$/;
      const exportedFiles = note.exportedFiles || [];
      for (let i = 0; i < exportedFiles.length; i++) {
        if (safePattern.test(exportedFiles[i])) {
          const exportedPath = Quickshell.env("HOME") + "/Documents/" + exportedFiles[i];
          Quickshell.execDetached(["rm", "-f", exportedPath]);
        }
      }
    }

    root.noteCards = root.noteCards.filter(n => n.id !== noteId);
    root.noteCardsRevision++;

    ToastService.showNotice(pluginApi?.tr("toast.note-deleted"));
  }

  // Function to clear all note cards and delete files from disk
  function clearAllNoteCards() {
    const safePattern = /^notecard_\d{6}-\d{6}\.txt$/;
    for (let i = 0; i < root.noteCards.length; i++) {
      const note = root.noteCards[i];

      // Delete the .json notecard file from notecards directory
      const filename = getNoteFilename(note);
      const filePath = root.noteCardsDir + "/" + filename;
      Quickshell.execDetached(["rm", "-f", filePath]);

      // Delete any exported .txt files
      const exportedFiles = note.exportedFiles || [];
      for (let j = 0; j < exportedFiles.length; j++) {
        if (safePattern.test(exportedFiles[j])) {
          const exportedPath = Quickshell.env("HOME") + "/Documents/" + exportedFiles[j];
          Quickshell.execDetached(["rm", "-f", exportedPath]);
        }
      }
    }

    root.noteCards = [];
    root.noteCardsRevision++;

    ToastService.showNotice(pluginApi?.tr("toast.notes-cleared"));
  }

  // Function to export scratchpad note to .txt file
  function exportNoteCard(noteId) {
    const note = root.noteCards.find(n => n.id === noteId);
    if (!note) {
      ToastService.showError(pluginApi?.tr("toast.note-not-found"));
      return;
    }

    const now = new Date();
    const timestamp = now.getFullYear().toString().slice(-2) + String(now.getMonth() + 1).padStart(2, '0') + String(now.getDate()).padStart(2, '0') + "-" + String(now.getHours()).padStart(2, '0') + String(now.getMinutes()).padStart(2, '0') + String(now.getSeconds()).padStart(2, '0');
    const fileName = "notecard_" + timestamp + ".txt";
    const filePath = Quickshell.env("HOME") + "/Documents/" + fileName;

    // Force a non-empty payload so the atomicWrite guard never trips for
    // blank notes — a single space exports cleanly as a 1-byte file.
    const exportContent = (note.content && note.content.length > 0) ? note.content : " ";
    atomicWrite(filePath, exportContent, "", "export-" + noteId);

    // Store exported filename - append to list so all exports are tracked
    const existingExports = note.exportedFiles || [];
    root.updateNoteCard(noteId, {
                          exportedFiles: [...existingExports, fileName]
                        });

    ToastService.showNotice(pluginApi?.tr("toast.note-exported").replace("{fileName}", fileName));
  }

  // Helper function to generate safe filename from note title
  function getNoteFilename(note) {
    if (!note) {
      return "untitled.json";
    }

    // Use title field if available, otherwise use id
    let title = (note.title && note.title.trim()) ? note.title.trim() : "";

    if (!title || title.length === 0) {
      title = note.id;
    }

    // Sanitize filename: remove special characters, max 50 chars
    title = title.substring(0, 50);
    title = title.replace(/[^a-zA-Z0-9-_ ]/g, '');
    title = title.replace(/\s+/g, '_');

    if (!title || title.length === 0) {
      title = note.id;
    }

    return title + ".json";
  }

  // Function to save individual notecard to file.
  // oldFilePath (optional) is the previous on-disk filename when the note
  // has been renamed — atomicWrite removes it only after the new file
  // is verified non-empty, so a failed save never wipes the old data.
  function saveNoteCard(note, oldFilePath) {
    if (!note || !note.id) {
      Logger.w("Clipper", "saveNoteCard: refusing to save invalid note");
      return;
    }
    const filename = getNoteFilename(note);
    const filePath = root.noteCardsDir + "/" + filename;
    const json = JSON.stringify(note, null, 2);
    if (!json || json.length < 10) {
      Logger.w("Clipper", "saveNoteCard: refusing suspiciously small JSON for note " + note.id);
      return;
    }
    atomicWrite(filePath, json, oldFilePath, note.id);
  }

  // Function to save all note cards (saves each to individual file)
  function saveNoteCards() {
    for (let i = 0; i < root.noteCards.length; i++) {
      saveNoteCard(root.noteCards[i]);
    }
  }

  // Function to bring note to front (update z-index)
  function bringNoteToFront(noteId) {
    const index = root.noteCards.findIndex(n => n.id === noteId);
    if (index === -1)
      return;

    // Find highest z-index
    let maxZ = 0;
    for (let i = 0; i < root.noteCards.length; i++) {
      if (root.noteCards[i].zIndex > maxZ) {
        maxZ = root.noteCards[i].zIndex;
      }
    }

    // Only update if not already at front
    if (root.noteCards[index].zIndex < maxZ) {
      root.updateNoteCard(noteId, {
                            zIndex: maxZ + 1
                          });
    }
  }

  // Process for copying pinned images to clipboard
  Process {
    id: copyPinnedImageProc
    command: ["wl-copy"]
    running: false
    stdinEnabled: true

    onExited: exitCode => {
                if (exitCode === 0) {
                  ToastService.showNotice(pluginApi?.tr("toast.copied-to-clipboard"));
                } else {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-copy-image"));
                }
                stdinEnabled = true;  // Re-enable for next use
              }
  }

  // Process for copying pinned text to clipboard
  Process {
    id: copyPinnedTextProc
    command: ["wl-copy", "--"]
    running: false
    stdinEnabled: true

    onExited: exitCode => {
                if (exitCode === 0) {
                  ToastService.showNotice(pluginApi?.tr("toast.copied-to-clipboard"));
                } else {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-copy-text"));
                }
                stdinEnabled = true;  // Re-enable for next use
              }
  }

  // Function to copy pinned item to clipboard
  function copyPinnedToClipboard(pinnedId) {
    const item = root.pinnedItems.find(i => i.id === pinnedId);
    if (!item) {
      return;
    }

    if (item.isImage && item.content) {
      // For images, decode base64 and copy binary data
      // Extract base64 from data URL: data:image/png;base64,iVBORw0K...
      const matches = item.content.match(/^data:([^;]+);base64,(.+)$/);
      if (!matches) {
        ToastService.showError(pluginApi?.tr("toast.failed-to-copy-image"));
        return;
      }

      const mimeType = matches[1];
      const base64Data = matches[2];

      // Decode base64 to binary bytes (no shell commands).
      // Qt.atob() with array-like overload returns a Uint8Array directly (non-deprecated form).
      const bytes = new Uint8Array(Qt.atob(base64Data));

      // Copy binary data directly via Process stdin
      copyPinnedImageProc.running = true;
      copyPinnedImageProc.write(bytes);
      copyPinnedImageProc.stdinEnabled = false;  // Close stdin to signal EOF
    } else {
      // For text, copy via Process stdin (no shell interpolation)
      copyPinnedTextProc.running = true;
      copyPinnedTextProc.write(item.content || "");
      copyPinnedTextProc.stdinEnabled = false;  // Close stdin to signal EOF
    }
  }

  // Image handling functions
  function getImageData(cliphistId) {
    return root.imageCache[cliphistId] || "";
  }

  function decodeToDataUrl(cliphistId, mimeType, callback) {
    // Validate cliphistId is numeric only (prevents command injection)
    if (!cliphistId || !/^\d+$/.test(String(cliphistId))) {
      return;
    }

    // Check cache first
    if (root.imageCache[cliphistId]) {
      if (callback)
        callback(root.imageCache[cliphistId]);
      return;
    }

    // Decode and encode to base64 in one shell command (like official ClipboardService)
    imageDecodeProc.cliphistId = cliphistId;
    imageDecodeProc.mimeType = mimeType || "image/png";
    imageDecodeProc.callback = callback;
    // Use shell to pipe: cliphist decode ID | base64 -w 0
    imageDecodeProc.command = ["sh", "-c", `cliphist decode ${cliphistId} | base64 -w 0`];
    imageDecodeProc.running = true;
  }

  // Process to decode image from cliphist and encode to base64
  Process {
    id: imageDecodeProc
    property string cliphistId: ""
    property string mimeType: "image/png"
    property var callback: null
    stdout: StdioCollector {}

    onExited: exitCode => {
                if (exitCode !== 0) {
                  return;
                }

                // Read base64-encoded text output
                const base64 = String(stdout.text).trim();
                if (!base64 || base64.length === 0) {
                  return;
                }

                // Validate size (approximate: base64 is ~33% larger than binary)
                const estimatedSize = (base64.length * 3) / 4;
                if (estimatedSize > maxPreviewImageSize) {
                  return;
                }

                const dataUrl = "data:" + mimeType + ";base64," + base64;

                // Cache it with LRU eviction
                root.addToImageCache(cliphistId, dataUrl);

                if (callback)
                callback(dataUrl);
              }
  }

  // Process to get selected text (primary selection) - for ToDo integration
  Process {
    id: getSelectionProcess
    command: ["wl-paste", "-p", "-n"]
    stdout: StdioCollector {
      id: selectionStdout
    }
    onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                  const selectedText = selectionStdout.text.trim();
                  if (selectedText && selectedText.length > 0) {
                    root.addTodoWithText(selectedText, root.pendingPageId);
                  } else {
                    ToastService.showError(pluginApi?.tr("toast.no-text-selected"));
                  }
                } else {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-get-selection"));
                }
              }
  }

  // Add todo with text to specified page via direct PluginService API
  function addTodoWithText(text, pageId) {
    if (!text || text.length === 0) {
      ToastService.showError(pluginApi?.tr("toast.no-text-to-add"));
      return;
    }

    const todoApi = PluginService.getPluginAPI("todo");
    if (!todoApi) {
      ToastService.showError(pluginApi?.tr("toast.todo-not-available"));
      return;
    }

    // NOTE: Cross-plugin integration - direct settings manipulation is allowed
    // when calling another plugin's API. This is NOT internal IPC (forbidden).
    // We're integrating with ToDo plugin using its data structure.
    const trimmedText = text.substring(0, maxTodoTextLength);
    var todos = todoApi.pluginSettings.todos || [];

    var newTodo = {
      id: Date.now(),
      text: trimmedText,
      completed: false,
      createdAt: new Date().toISOString(),
      pageId: pageId,
      priority: "medium",
      details: ""
    };

    todos.push(newTodo);
    todoApi.pluginSettings.todos = todos;
    todoApi.pluginSettings.count = todos.length;
    todoApi.saveSettings();

    ToastService.showNotice(pluginApi?.tr("toast.added-to-todo"));

    // Also copy to clipboard
    Quickshell.execDetached(["wl-copy", "--", text]);
  }

  // Process for copying to clipboard (direct pipe: cliphist decode | wl-copy)
  Process {
    id: copyToClipboardProc
    property string clipboardId: ""
    stdout: StdioCollector {}

    onExited: exitCode => {
                if (exitCode !== 0) {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-copy"));
                }
              }
  }

  // Clipboard management functions
  function list(maxPreviewWidth) {
    if (listProc.running)
      return;
    root.loading = true;
    const width = maxPreviewWidth || 100;
    listProc.command = ["cliphist", "list", "-preview-width", String(width)];
    listProc.running = true;
  }

  function copyToClipboard(id) {
    // Validate id is numeric only (prevents command injection)
    if (!id || !/^\d+$/.test(String(id))) {
      ToastService.showError(pluginApi?.tr("toast.invalid-clipboard-item"));
      return;
    }

    // Use shell pipe: cliphist decode ID | wl-copy
    // ID is validated to be numeric only, so this is safe from command injection
    copyToClipboardProc.clipboardId = id;
    copyToClipboardProc.command = ["sh", "-c", `cliphist decode ${id} | wl-copy`];
    copyToClipboardProc.running = true;
  }

  function deleteById(id) {
    // Validate id is numeric only (prevents command injection)
    if (!id || !/^\d+$/.test(String(id))) {
      ToastService.showError(pluginApi?.tr("toast.invalid-clipboard-item"));
      return;
    }

    // cliphist delete needs the full line (ID + preview) via stdin
    // ID is validated to be numeric-only, so string interpolation is safe here
    deleteItemProc.command = ["sh", "-c", `cliphist list | grep "^${id}	" | cliphist delete`];
    deleteItemProc.running = true;
  }

  // Process for deleting clipboard item
  Process {
    id: deleteItemProc
    stdout: StdioCollector {}

    onExited: exitCode => {
                // Refresh list immediately after deletion
                root.list();
              }
  }

  function wipeAll() {
    wipeProc.running = true;
  }

  // Process for wiping all clipboard history
  Process {
    id: wipeProc
    command: ["cliphist", "wipe"]

    onExited: exitCode => {
                // Clear caches and refresh list
                root.clearCaches();
                root.list();
              }
  }

  // Add selected text to specific page
  function addSelectedToPage(pageId) {
    if (!pluginApi?.pluginSettings?.enableTodoIntegration) {
      ToastService.showError(pluginApi?.tr("toast.todo-disabled"));
      return;
    }

    root.pendingPageId = pageId;
    getSelectionProcess.running = true;
  }

  IpcHandler {
    target: "plugin:clipper"

    function openPanel() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
                                           root.pluginApi.openPanel(screen);
                                         });
      }
    }

    function closePanel() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
                                           root.pluginApi.closePanel(screen);
                                         });
      }
    }

    function togglePanel() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
                                           root.pluginApi.togglePanel(screen);
                                         });
      }
    }

    // Alias for keybind compatibility
    function toggle() {
      togglePanel();
    }

    // Pinned items IPC handlers
    function pinClipboardItem(cliphistId: string) {
      root.pinItem(cliphistId);
    }

    function unpinItem(pinnedId: string) {
      root.unpinItem(pinnedId);
    }

    function copyPinned(pinnedId: string) {
      root.copyPinnedToClipboard(pinnedId);
    }

    // Show ToDo page selector with current selection
    // Usage: qs -c noctalia-shell ipc call plugin:clipper addSelectionToTodo
    function addSelectionToTodo() {
      if (!pluginApi?.pluginSettings?.enableTodoIntegration) {
        ToastService.showError(pluginApi?.tr("toast.todo-disabled"));
        return;
      }
      // Get selected text first, then show selector
      root.getSelectionAndShowSelector();
    }

    // NoteCards IPC handlers
    // Usage: qs -c noctalia-shell ipc call plugin:clipper addNoteCard "Quick note"
    function addNoteCard(text: string) {
      const initialText = text || "";
      root.createNoteCard(initialText);
    }

    // Usage: qs -c noctalia-shell ipc call plugin:clipper exportNoteCard "note_123_abc"
    function exportNoteCard(noteId: string) {
      root.exportNoteCard(noteId);
    }

    // Add selected text to existing note or create new one
    // Usage: qs -c noctalia-shell ipc call plugin:clipper addSelectionToNoteCard
    function addSelectionToNoteCard() {
      // Get selected text first, then show note selector
      root.getSelectionAndShowNoteSelector();
    }
  }

  // Process to get selected text for ToDo selector
  Process {
    id: getSelectionForSelectorProcess
    command: ["wl-paste", "-p", "-n"]
    stdout: StdioCollector {
      id: selectorSelectionStdout
    }
    onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                  const selectedText = selectorSelectionStdout.text.trim();
                  if (selectedText && selectedText.length > 0) {
                    root.showTodoPageSelector(selectedText);
                  } else {
                    ToastService.showError(pluginApi?.tr("toast.no-text-selected"));
                  }
                } else {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-get-selection"));
                }
              }
  }

  // Get selection and show page selector
  function getSelectionAndShowSelector() {
    getSelectionForSelectorProcess.running = true;
  }

  // Refresh clipboard list when panel opens
  function refreshOnPanelOpen() {
    root.list();
  }

  // Show ToDo page selector at cursor position
  function showTodoPageSelector(text) {
    root.activeSelector = "todo";
    root.activeSelector = "todo";
    root.pendingSelectedText = text;

    // Get pages from ToDo plugin
    const todoApi = PluginService.getPluginAPI("todo");
    let todoPages = [];
    if (todoApi) {
      if (todoApi.mainInstance) {
        todoPages = todoApi.pluginSettings.pages || [];
      } else {}
    } else {}

    // Show selector with pages list
    if (todoPageSelector) {
      todoPageSelector.show(text, todoPages);
    } else {
      ToastService.showError(pluginApi?.tr("toast.could-not-open-todo"));
    }
  }

  // Handle page selection from selector
  function handleTodoPageSelected(pageId, pageName) {
    if (root.pendingSelectedText) {
      root.addTodoWithText(root.pendingSelectedText, pageId);
      root.pendingSelectedText = "";
    }
  }
  // Get selection and show note card selector
  function getSelectionAndShowNoteSelector() {
    getSelectionForNoteSelectorProcess.running = true;
  }
  function showNoteCardSelector(text) {
    root.activeSelector = "notecard";
    root.activeSelector = "notecard";
    root.pendingNoteCardText = text;
    // Load notecards first
    root.loadNoteCards();
    // Wait a bit for notes to load, then show selector
    Qt.callLater(() => {
                   if (noteCardSelector) {
                     noteCardSelector.show(text, root.noteCards);
                   } else {
                     ToastService.showError(pluginApi?.tr("toast.could-not-open-note-selector"));
                   }
                 });
  }

  // Handle note selection from selector
  function handleNoteCardSelected(noteId, noteTitle) {
    if (root.pendingNoteCardText) {
      root.appendTextToNoteCard(noteId, root.pendingNoteCardText);
      root.pendingNoteCardText = "";
    }
  }

  // Handle creating new note from selection
  // Handle creating new ToDo page from selection
  function handleCreateNewTodoPage() {
    if (root.pendingSelectedText) {
      const todoApi = PluginService.getPluginAPI("todo");
      if (todoApi && todoApi.mainInstance) {
        todoApi.mainInstance.addTextToNewPage(root.pendingSelectedText);
        ToastService.showNotice(pluginApi?.tr("toast.todo-page-created"));
      }
      root.pendingSelectedText = "";
    }
  }

  function handleCreateNewNoteFromSelection() {
    if (root.pendingNoteCardText) {
      // Create new note with bullet point
      const bulletText = "- " + root.pendingNoteCardText;
      root.createNoteCard(bulletText);
      root.pendingNoteCardText = "";
    }
  }

  // Append text as bullet point to existing note
  function appendTextToNoteCard(noteId, text) {
    for (let i = 0; i < noteCards.length; i++) {
      if (noteCards[i].id === noteId) {
        const bulletText = "- " + text;
        const currentContent = noteCards[i].content || "";
        const newContent = currentContent ? currentContent + "\n" + bulletText : bulletText;

        noteCards[i].content = newContent;
        noteCardsChanged();
        saveNoteCard(noteCards[i]);

        ToastService.showNotice(pluginApi?.tr("toast.text-added-to-note"));
        return;
      }
    }
    ToastService.showError(pluginApi?.tr("toast.note-not-found"));
  }

  // ToDo page selector (single instance, uses first screen)
  // It's a fullscreen overlay so it works regardless of which screen cursor is on
  // Selection context menu (shared for both note and todo selection)
  property var selectionMenu: null
  property string activeSelector: ""  // "todo" or "notecard"

  Variants {
    model: Quickshell.screens

    delegate: SelectionContextMenu {
      required property var modelData

      screen: modelData
      pluginApi: root.pluginApi

      Component.onCompleted: {
        if (!root.selectionMenu) {
          root.selectionMenu = this;
        }
      }

      onItemSelected: action => {
                        // Route to appropriate handler
                        if (root.activeSelector === "notecard" && root.noteCardSelector) {
                          root.noteCardSelector.handleItemSelected(action);
                        } else if (root.activeSelector === "todo" && root.todoPageSelector) {
                          root.todoPageSelector.handleItemSelected(action);
                        }
                      }

      onCancelled: {
        root.pendingSelectedText = "";
        root.pendingNoteCardText = "";
      }
    }
  }

  // Note card selector (logic only)
  property var noteCardSelector: NoteCardSelector {
    pluginApi: root.pluginApi
    selectionMenu: root.selectionMenu

    onNoteSelected: (noteId, noteTitle) => {
                      root.handleNoteCardSelected(noteId, noteTitle);
                    }

    onCreateNewNote: () => {
                       root.handleCreateNewNoteFromSelection();
                     }
  }

  property string pendingNoteCardText: ""

  // Todo page selector (logic only)
  property var todoPageSelector: TodoPageSelector {
    pluginApi: root.pluginApi
    selectionMenu: root.selectionMenu

    onPageSelected: (pageId, pageName) => {
                      root.handleTodoPageSelected(pageId, pageName);
                    }
  }

  Process {
    id: getSelectionForNoteSelectorProcess
    command: ["wl-paste", "-p", "-n"]
    stdout: StdioCollector {
      id: noteSelectionStdout
    }
    onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                  const selectedText = noteSelectionStdout.text.trim();
                  if (selectedText && selectedText.length > 0) {
                    root.showNoteCardSelector(selectedText);
                  } else {
                    ToastService.showError(pluginApi?.tr("toast.no-text-selected"));
                  }
                } else {
                  ToastService.showError(pluginApi?.tr("toast.failed-to-get-selection"));
                }
              }
  }
  // Check if wtype is available
  Process {
    id: wtypeCheckProc
    command: ["which", "wtype"]
    running: true
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: exitCode => {
      root.wtypeAvailable = (exitCode === 0);
    }
  }

  // Timer for auto-paste delay
  Timer {
    id: autoPasteTimer
    interval: pluginApi?.pluginSettings?.autoPasteDelay ?? 300
    repeat: false
    onTriggered: {
      if (root.wtypeAvailable) {
        autoPasteProc.running = true;
      } else {
        Logger.w("Clipper", "Auto-paste failed: wtype not found. Install with: sudo pacman -S wtype");
      }
    }
  }

  // Process to trigger auto-paste via wtype Ctrl+V
  Process {
    id: autoPasteProc
    command: ["wtype", "-M", "ctrl", "-M", "shift", "v"]
    running: false
    onExited: exitCode => {
      if (exitCode !== 0) {
        Logger.w("Clipper", "wtype auto-paste exited with code: " + exitCode);
      }
    }
  }

  // Public function called from Panel.qml
  function triggerAutoPaste() {
    autoPasteTimer.restart();
  }

  // Initialize pinned.json and notecards.json if they don't exist
  Component.onCompleted: {
    Logger.d("Clipper", "Component.onCompleted - pluginApi initialized");
    if (pluginApi) {
      showCloseButton = pluginApi.pluginSettings?.showCloseButton ?? false;
    }

    // Create empty pinned.json if it doesn't exist
    const pinnedPath = Quickshell.env("HOME") + "/.config/noctalia/plugins/clipper/pinned.json";
    Quickshell.execDetached(["sh", "-c", `[ -f "${pinnedPath}" ] || echo '{"items":[]}' > "${pinnedPath}"`]);

    // Create notecards directory if it doesn't exist
    Quickshell.execDetached(["mkdir", "-p", root.noteCardsDir]);

    // Sweep any stale .tmp files left over from a prior interrupted atomic
    // write (shell killed between tmp-write and rename). These are never
    // meaningful data; leaving them around would confuse the `jq -s '*.json'`
    // loader on next start.
    Quickshell.execDetached(["sh", "-c",
                             'find "$1" -maxdepth 1 -name "*.json.tmp" -type f -delete 2>/dev/null',
                             "cleanTmp", root.noteCardsDir]);

    // Force reload pinned items from file
    pinnedFile.reload();

    // Load clipboard history
    list();
  }

  // Cleanup all running processes on destruction
  Component.onDestruction: {
    if (listProc.running)
      listProc.terminate();
    if (decodeProc.running)
      decodeProc.terminate();
    if (copyPinnedImageProc.running)
      copyPinnedImageProc.terminate();
    if (copyPinnedTextProc.running)
      copyPinnedTextProc.terminate();
    if (imageDecodeProc.running)
      imageDecodeProc.terminate();
    if (getSelectionProcess.running)
      getSelectionProcess.terminate();
    if (getSelectionForSelectorProcess.running)
      getSelectionForSelectorProcess.terminate();
    if (getSelectionForNoteSelectorProcess.running)
      getSelectionForNoteSelectorProcess.terminate();
    if (copyToClipboardProc.running)
      copyToClipboardProc.terminate();
    if (deleteItemProc.running)
      deleteItemProc.terminate();
    if (wipeProc.running)
      wipeProc.terminate();
    if (loadNoteCardsProc.running)
      loadNoteCardsProc.terminate();
    if (atomicWriteProc.running)
      atomicWriteProc.terminate();
    _atomicWriteQueue = [];

    autoPasteTimer.stop();
    if (autoPasteProc.running) autoPasteProc.terminate();
    if (wtypeCheckProc.running) wtypeCheckProc.terminate();

    // Clear data structures
    pinnedItems = [];
    noteCards = [];
    items = [];
    firstSeenById = {};
    imageCache = {};
    imageCacheOrder = [];
  }
}
