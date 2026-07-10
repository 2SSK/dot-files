import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  property var pluginApi: null
  property var rawTodos: []
  property var rawPages: []
  property string currentExportPath: ""

  // Process for exporting todos
  Process {
    id: exportProcess
    running: false
    onExited: function (code) {
      if (code === 0) {
        var displayPath = currentExportPath.replace(Quickshell.env("HOME"), "~");
        ToastService.showNotice(pluginApi.tr("main.exported_todos") + displayPath);
      } else {
        ToastService.showError(pluginApi.tr("main.export_failed"));
      }
    }
  }

  // ============================================
  // Initialization
  // ============================================

  Component.onCompleted: {
    if (pluginApi) {
      // Initialize pages config
      if (!pluginApi.pluginSettings.pages) {
        pluginApi.pluginSettings.pages = [
              {
                id: 0,
                name: "General"
              }
            ];
        pluginApi.pluginSettings.current_page_id = 0;
      }

      // Initialize todo config
      if (!pluginApi.pluginSettings.todos) {
        pluginApi.pluginSettings.todos = [];
        pluginApi.pluginSettings.count = 0;
        pluginApi.pluginSettings.completedCount = 0;
      }

      // Initialize display settings
      if (pluginApi.pluginSettings.isExpanded === undefined)
        pluginApi.pluginSettings.isExpanded = false;
      if (pluginApi.pluginSettings.useCustomColors === undefined)
        pluginApi.pluginSettings.useCustomColors = false;

      // Initialize export path
      if (!pluginApi.pluginSettings.exportPath)
        pluginApi.pluginSettings.exportPath = "~/Documents";

      // Initialize export format
      if (!pluginApi.pluginSettings.exportFormat)
        pluginApi.pluginSettings.exportFormat = "markdown";

      // Initialize export empty sections setting
      if (pluginApi.pluginSettings.exportEmptySections === undefined)
        pluginApi.pluginSettings.exportEmptySections = false;

      // Initialize priority colors
      if (!pluginApi.pluginSettings.priorityColors) {
        pluginApi.pluginSettings.priorityColors = {
          "high": Color.mError,
          "medium": Color.mPrimary,
          "low": Color.mOnSurfaceVariant
        };
      }

      // Always create copies to avoid reference issues
      // Panel.qml may reassign pluginApi.pluginSettings.todos
      rawTodos = pluginApi.pluginSettings.todos.slice();
      rawPages = pluginApi.pluginSettings.pages.slice();

      // Data migration: add missing fields to existing todos
      for (var i = 0; i < rawTodos.length; i++) {
        if (rawTodos[i].pageId === undefined)
          rawTodos[i].pageId = 0;
        if (rawTodos[i].priority === undefined || !["high", "medium", "low"].includes(rawTodos[i].priority)) {
          rawTodos[i].priority = "medium";
        }
        if (rawTodos[i].details === undefined)
          rawTodos[i].details = "";
      }

      pluginApi.saveSettings();
    }
  }

  // ============================================
  // Persistence Functions
  // ============================================

  function saveTodos() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pluginApi.pluginSettings.todos = rawTodos.slice();
    pluginApi.pluginSettings.count = rawTodos.length;
    pluginApi.pluginSettings.completedCount = rawTodos.filter(t => t.completed).length;
    pluginApi.saveSettings();
  }

  function savePages() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pluginApi.pluginSettings.pages = rawPages.slice();
    pluginApi.saveSettings();
  }

  // ============================================
  // IPC Handlers - thin wrappers around core functions
  // ============================================

  IpcHandler {
    target: "plugin:todo"

    // Panel Control
    function togglePanel() {
      if (!pluginApi)
        return;
      pluginApi.withCurrentScreen(screen => {
                                    pluginApi.togglePanel(screen);
                                  });
    }

    // Todo Read Operations
    function getTodos(): string {
      return JSON.stringify(rawTodos);
    }
    function getTodo(id: string): string {
      var todo = findTodo(id);
      return todo ? JSON.stringify(todo) : "";
    }
    function getCount(): string {
      return JSON.stringify({
                              total: rawTodos.length,
                              active: rawTodos.filter(t => !t.completed).length,
                              completed: rawTodos.filter(t => t.completed).length
                            });
    }

    // Todo Create Operations
    function addTodo(text: string, priority: string, pageId: int) {
      if (!text || !text.trim()) {
        ToastService.showError(pluginApi.tr("main.error_text_empty"));
        return;
      }
      if (!["high", "medium", "low"].includes(priority)) {
        ToastService.showError(pluginApi.tr("main.error_invalid_priority"));
        return;
      }
      var targetPageId = (pageId === undefined || pageId === null) ? (pluginApi.pluginSettings.current_page_id ?? 0) : pageId;
      if (!pageExists(targetPageId)) {
        ToastService.showError(pluginApi.tr("main.error_page_not_found"));
        return;
      }

      if (createTodo(text.trim(), priority, targetPageId)) {
        ToastService.showNotice(pluginApi.tr("main.added_new_todo"));
      } else {
        ToastService.showError(pluginApi.tr("main.error_create_failed"));
      }
    }

    function addTodoDefault(text: string) {
      addTodo(text, "medium", pluginApi.pluginSettings.current_page_id);
    }

    // Todo Update Operations
    function setTodoPriority(id: string, priority: string) {
      updateTodo(id, {
                   priority: priority
                 }) ? ToastService.showNotice(pluginApi.tr("main.updated_todo_priority")) : ToastService.showError(pluginApi.tr("main.error_update_failed"));
    }
    function setTodoCompleted(id: string, completed: bool) {
      updateTodo(id, {
                   completed: completed
                 }) ? ToastService.showNotice(pluginApi.tr("main.updated_todo")) : ToastService.showError(pluginApi.tr("main.error_update_failed"));
    }
    function setTodoDetails(id: string, details: string) {
      updateTodo(id, {
                   details: details
                 }) ? ToastService.showNotice(pluginApi.tr("main.updated_todo")) : ToastService.showError(pluginApi.tr("main.error_update_failed"));
    }
    function setTodoText(id: string, text: string) {
      updateTodo(id, {
                   text: text
                 }) ? ToastService.showNotice(pluginApi.tr("main.updated_todo")) : ToastService.showError(pluginApi.tr("main.error_update_failed"));
    }
    function toggleTodo(id: string) {
      var todo = findTodo(id);
      if (!todo) {
        ToastService.showError(pluginApi.tr("main.error_todo_not_found"));
        return;
      }
      var completed = !todo.completed;
      updateTodo(id, {
                   completed: completed
                 });
      var action = completed ? pluginApi.tr("main.todo_completed") : pluginApi.tr("main.todo_marked_incomplete");
      ToastService.showNotice(pluginApi.tr("main.todo_status_changed") + action);
    }

    // Todo Delete Operations
    function removeTodo(id: string) {
      deleteTodo(id) ? ToastService.showNotice(pluginApi.tr("main.removed_todo")) : ToastService.showError(pluginApi.tr("main.error_remove_failed"));
    }
    function clearCompleted() {
      var cleared = clearCompletedTodos();
      ToastService.showNotice(pluginApi.tr("main.cleared_completed_todos") + cleared + pluginApi.tr("main.completed_todos_suffix"));
    }
    function clearAll() {
      clearAllTodos();
      ToastService.showNotice(pluginApi.tr("main.cleared_all_todos"));
    }

    // Page Operations
    function getPages(): string {
      return JSON.stringify(rawPages);
    }
    function addPage(name: string) {
      var trimmedName = name.trim();
      if (!trimmedName) {
        ToastService.showError(pluginApi.tr("settings.pages.empty_name"));
        return;
      }
      if (pageNameExists(trimmedName)) {
        ToastService.showError(pluginApi.tr("settings.pages.name_exists"));
        return;
      }
      if (createPage(trimmedName)) {
        ToastService.showNotice(pluginApi.tr("settings.pages.added_page") + trimmedName);
      } else {
        ToastService.showError(pluginApi.tr("settings.pages.error_creating"));
      }
    }
    function renamePage(pageId: int, newName: string) {
      var trimmedName = newName.trim();
      if (!trimmedName) {
        ToastService.showError(pluginApi.tr("settings.pages.empty_name"));
        return;
      }
      if (!pageExists(pageId)) {
        ToastService.showError(pluginApi.tr("main.error_page_not_found"));
        return;
      }
      if (pageNameExistsExcluding(pageId, trimmedName)) {
        ToastService.showError(pluginApi.tr("settings.pages.name_exists"));
        return;
      }
      if (renamePageInternal(pageId, trimmedName)) {
        ToastService.showNotice(pluginApi.tr("settings.pages.renamed_page"));
      } else {
        ToastService.showError(pluginApi.tr("main.error_rename_failed"));
      }
    }
    function removePage(pageId: int) {
      if (pageId === 0) {
        ToastService.showError(pluginApi.tr("settings.pages.cannot_delete_default"));
        return;
      }
      if (isLastPage()) {
        ToastService.showError(pluginApi.tr("settings.pages.cannot_delete_last"));
        return;
      }
      if (!pageExists(pageId)) {
        ToastService.showError(pluginApi.tr("main.error_page_not_found"));
        return;
      }
      if (deletePage(pageId)) {
        ToastService.showNotice(pluginApi.tr("settings.pages.deleted_page"));
      } else {
        ToastService.showError(pluginApi.tr("main.error_delete_failed"));
      }
    }

    // Export
    function exportTodos() {
      doExportTodos();
    }
  }

  // ============================================
  // Core Business Logic - exposed via mainInstance
  // ============================================

  // Create new todo
  function createTodo(text, priority, pageId) {
    var newTodo = {
      id: Date.now(),
      text: text,
      completed: false,
      createdAt: new Date().toISOString(),
      pageId: pageId,
      priority: priority,
      details: ""
    };

    var insertIndex = rawTodos.length;
    for (var i = 0; i < rawTodos.length; i++) {
      if (rawTodos[i].pageId === pageId) {
        insertIndex = i;
        break;
      }
    }
    rawTodos.splice(insertIndex, 0, newTodo);
    saveTodos();
    return true;
  }

  // Update todo (supports text/completed/priority/details)
  function updateTodo(id, updates) {
    var index = findTodoIndex(id);
    if (index === -1)
      return false;

    var todo = rawTodos[index];
    var oldCompleted = todo.completed;

    if (updates.text !== undefined)
      rawTodos[index].text = updates.text;
    if (updates.completed !== undefined)
      rawTodos[index].completed = updates.completed;
    if (updates.priority !== undefined)
      rawTodos[index].priority = updates.priority;
    if (updates.details !== undefined)
      rawTodos[index].details = updates.details;

    // If completion status changed, reorder todos
    if (updates.completed !== undefined && oldCompleted !== updates.completed) {
      moveTodoToCorrectPosition(id);
    } else {
      saveTodos();
    }

    return true;
  }

  // Delete specific todo
  function deleteTodo(id) {
    var index = findTodoIndex(id);
    if (index === -1)
      return false;
    rawTodos.splice(index, 1);
    saveTodos();
    return true;
  }

  // Clear all completed todos, return count cleared
  function clearCompletedTodos() {
    var active = rawTodos.filter(t => !t.completed);
    var cleared = rawTodos.length - active.length;
    rawTodos.splice(0, rawTodos.length, ...active);
    saveTodos();
    return cleared;
  }

  // Clear all todos
  function clearAllTodos() {
    rawTodos.splice(0, rawTodos.length);
    saveTodos();
  }

  // Create new page
  function createPage(name) {
    var newId = rawPages.length > 0 ? Math.max(...rawPages.map(p => p.id)) + 1 : 0;
    rawPages.push({
                    id: newId,
                    name: name
                  });
    savePages();
    return true;
  }

  // Rename page (internal)
  function renamePageInternal(pageId, newName) {
    for (var i = 0; i < rawPages.length; i++) {
      if (rawPages[i].id === pageId) {
        rawPages[i].name = newName;
        break;
      }
    }
    savePages();
    return true;
  }

  // Delete page (moves associated todos to default page)
  function deletePage(pageId) {
    for (var i = 0; i < rawTodos.length; i++) {
      if (rawTodos[i].pageId === pageId)
        rawTodos[i].pageId = 0;
    }
    rawPages.splice(0, rawPages.length, ...rawPages.filter(p => p.id !== pageId));
    if (pluginApi.pluginSettings.current_page_id === pageId)
      pluginApi.pluginSettings.current_page_id = 0;
    saveTodos();
    savePages();
    return true;
  }

  // Move todo to correct position based on completion status
  // Called when todo completion status changes
  function moveTodoToCorrectPosition(todoId) {
    if (!rawTodos || rawTodos.length === 0)
      return;

    // Find the todo
    var todoIndex = -1;
    for (var i = 0; i < rawTodos.length; i++) {
      if (rawTodos[i].id == todoId) {
        todoIndex = i;
        break;
      }
    }
    if (todoIndex === -1)
      return;

    var movedTodo = rawTodos[todoIndex];
    var todoPageId = movedTodo.pageId;  // Use the todo's own pageId

    // Remove from current position
    rawTodos.splice(todoIndex, 1);

    // Find correct insertion position within the todo's page
    var insertIndex = -1;

    if (movedTodo.completed) {
      // Completed → Place at the END of page's todos
      insertIndex = rawTodos.length;
    } else {
      // Uncompleted → Place BEFORE the first completed todo in that page
      insertIndex = 0;
      for (var i = 0; i < rawTodos.length; i++) {
        if (rawTodos[i].pageId === todoPageId) {
          if (rawTodos[i].completed) {
            insertIndex = i;
            break;
          }
        }
      }
    }

    // Insert at the calculated position
    rawTodos.splice(insertIndex, 0, movedTodo);
    saveTodos();
  }

  // Move todo by index (for drag reorder in Panel)
  function moveTodo(todoId, fromIndex: int, toIndex: int, pageId: int) {
    if (!rawTodos || rawTodos.length === 0)
      return;

    // Find the todo in rawTodos
    var todo = null;
    var fromGlobalIndex = -1;
    for (var i = 0; i < rawTodos.length; i++) {
      if (rawTodos[i].id == todoId) {
        todo = rawTodos[i];
        fromGlobalIndex = i;
        break;
      }
    }
    if (!todo || fromGlobalIndex === -1)
      return;

    // Get todos for the target page
    var pageTodos = rawTodos.filter(function (t) {
      return t.pageId === pageId;
    });

    if (fromIndex < 0 || fromIndex >= pageTodos.length)
      return;
    if (toIndex < 0 || toIndex >= pageTodos.length)
      return false;

    // Remove from current position
    rawTodos.splice(fromGlobalIndex, 1);

    // Find target position in rawTodos
    var toGlobalIndex = -1;
    var count = 0;
    for (var i = 0; i < rawTodos.length; i++) {
      if (rawTodos[i].pageId === pageId) {
        if (count === toIndex) {
          toGlobalIndex = i;
          break;
        }
        count++;
      }
    }

    // If target is at end of page items or page is empty
    if (toGlobalIndex === -1) {
      for (var i = rawTodos.length - 1; i >= 0; i--) {
        if (rawTodos[i].pageId === pageId) {
          toGlobalIndex = i + 1;
          break;
        }
      }
      if (toGlobalIndex === -1) {
        // Insert at end of array
        toGlobalIndex = rawTodos.length;
      }
    }

    // Insert at target position
    rawTodos.splice(toGlobalIndex, 0, todo);
    saveTodos();
  }

  // Move todo by page-relative index (for drag reorder in Panel)
  // Always operates within the current page
  function moveTodoItem(fromIndex: int, toIndex: int) {
    if (!rawTodos || rawTodos.length === 0)
      return;

    var pageId = pluginApi?.pluginSettings?.current_page_id ?? 0;
    var pageTodos = rawTodos.filter(t => t.pageId === pageId);

    if (fromIndex < 0 || fromIndex >= pageTodos.length)
      return;
    if (toIndex < 0 || toIndex >= pageTodos.length)
      return;

    var todoId = pageTodos[fromIndex].id;
    moveTodo(todoId, fromIndex, toIndex, pageId);
  }

  // ============================================
  // Validation Functions
  // ============================================

  // Find todo by ID, return todo object or null
  function findTodo(id) {
    return rawTodos.find(t => t.id == id) || null;
  }
  // Find todo index by ID, return index or -1
  function findTodoIndex(id) {
    return rawTodos.findIndex(t => t.id == id);
  }

  // Check if page exists
  function pageExists(pageId) {
    return rawPages.some(p => p.id === pageId);
  }
  // Check if page name exists (case-insensitive)
  function pageNameExists(name) {
    return rawPages.some(p => p.name.toLowerCase() === name.toLowerCase());
  }
  // Check if page name exists, excluding specific page (for rename validation)
  function pageNameExistsExcluding(excludeId, name) {
    return rawPages.some(p => p.id !== excludeId && p.name.toLowerCase() === name.toLowerCase());
  }
  // Check if it's the last page (prevent deleting last page)
  function isLastPage() {
    return rawPages.length <= 1;
  }

  // Calculate completed count
  function calculateCompletedCount() {
    return rawTodos.filter(t => t.completed).length;
  }

  // Export todos to markdown file
  function doExportTodos() {
    if (!pluginApi) {
      return;
    }
    var format = pluginApi.pluginSettings.exportFormat;
    var content;
    var fileExtension;

    if (format === "json") {
      content = JSON.stringify(rawTodos, null, 2);
      fileExtension = ".json";
    } else {
      content = generateExportMarkdown();
      fileExtension = ".md";
    }

    exportTodosToFile(content, fileExtension);
  }

  // Export todos to file
  function exportTodosToFile(content, fileExtension) {
    try {
      var timestamp = new Date().toISOString().split("T")[0];
      var timeSuffix = new Date().toISOString().replace(/[:.]/g, "-").split("T")[1];
      var fileName = "todo_" + timestamp + "_" + timeSuffix + fileExtension;

      // Get export path from settings, default to ~/Documents
      var exportPath = pluginApi.pluginSettings.exportPath;
      exportPath = exportPath.replace("~", Quickshell.env("HOME"));

      // Ensure path ends without slash
      if (exportPath.endsWith("/")) {
        exportPath = exportPath.slice(0, -1);
      }

      var filePath = exportPath + "/" + fileName;

      // Write file using printf for better handling of long content
      var base64 = Qt.btoa(content);
      currentExportPath = filePath;
      exportProcess.command = ["sh", "-c", `printf '%s' "${base64}" | base64 -d > "${filePath}"`];
      exportProcess.running = true;
    } catch (e) {
      Logger.e("Todo", "Export error: " + e);
      ToastService.showError(pluginApi.tr("main.export_failed"));
    }
  }

  // Generate markdown content from todos
  function generateExportMarkdown() {
    var lines = [];
    var INDENT = "  ";
    var ITEM_PREFIX = "- ";
    var SUB_ITEM_PREFIX = INDENT + "- ";
    var DETAIL_PREFIX = INDENT + INDENT + "- ";
    var showEmptySections = pluginApi.pluginSettings.exportEmptySections;

    // Calculate statistics
    var totalCount = rawTodos.length;
    var activeCount = rawTodos.filter(function (t) {
      return !t.completed;
    }).length;
    var completedCount = totalCount - activeCount;
    var exportDate = new Date().toISOString();

    // Header with YAML front matter
    lines.push("---");
    lines.push("export_date: " + exportDate);
    lines.push("total: " + totalCount);
    lines.push("active: " + activeCount);
    lines.push("completed: " + completedCount);
    lines.push("---");
    lines.push("");
    lines.push("# " + pluginApi.tr("main.export_title"));
    lines.push("");

    // Process each page
    for (var p = 0; p < rawPages.length; p++) {
      var page = rawPages[p];
      var pageId = page.id;
      var pageName = page.name;

      // Get todos for this page
      var pageTodos = rawTodos.filter(function (t) {
        return t.pageId === pageId;
      });
      var activeTodos = pageTodos.filter(function (t) {
        return !t.completed;
      });
      var completedTodos = pageTodos.filter(function (t) {
        return t.completed;
      });

      // Skip page if no todos and not showing empty sections
      if (!showEmptySections && pageTodos.length === 0) {
        continue;
      }

      // Page header
      var pageHeader = pluginApi.tr("main.export_page_header").replace("{pageName}", pageName);
      lines.push("## " + pageHeader);
      lines.push("");

      // Render active todos
      if (activeTodos.length > 0 || showEmptySections) {
        var activeSection = pluginApi.tr("main.export_active_section").replace("{count}", activeTodos.length);
        lines.push("### " + activeSection);
        lines.push("");
        renderTodoList(lines, activeTodos, false, INDENT, ITEM_PREFIX, SUB_ITEM_PREFIX, DETAIL_PREFIX);
      }

      // Render completed todos
      if (completedTodos.length > 0 || showEmptySections) {
        var completedSection = pluginApi.tr("main.export_completed_section").replace("{count}", completedTodos.length);
        lines.push("### " + completedSection);
        lines.push("");
        renderTodoList(lines, completedTodos, true, INDENT, ITEM_PREFIX, SUB_ITEM_PREFIX, DETAIL_PREFIX);
      }

      // Page separator
      lines.push("---");
      lines.push("");
    }

    return lines.join("\n");
  }

  // Render a list of todos
  function renderTodoList(lines, todos, completed, indent, itemPrefix, subItemPrefix, detailPrefix) {
    var checkbox = completed ? "[x]" : "[ ]";

    for (var i = 0; i < todos.length; i++) {
      var todo = todos[i];
      var priorityLabel = getPriorityLabel(todo.priority);

      lines.push(itemPrefix + checkbox + " " + todo.text);
      lines.push(subItemPrefix + pluginApi.tr("main.export_priority") + ": " + priorityLabel);

      // Created date
      if (todo.createdAt) {
        var createdDate = todo.createdAt.split("T")[0];
        lines.push(subItemPrefix + pluginApi.tr("main.export_created") + ": " + createdDate);
      }

      // Details - use list format
      if (todo.details && todo.details.trim()) {
        lines.push(subItemPrefix + pluginApi.tr("main.export_details") + ":");
        var detailsLines = todo.details.trim().split("\n");
        for (var d = 0; d < detailsLines.length; d++) {
          lines.push(detailPrefix + detailsLines[d]);
        }
      }
      lines.push("");
    }
  }

  // Get priority label (text only)
  function getPriorityLabel(priority) {
    switch (priority) {
    case "high":
      return pluginApi.tr("main.priority_high");
    case "medium":
      return pluginApi.tr("main.priority_medium");
    case "low":
      return pluginApi.tr("main.priority_low");
    default:
      return pluginApi.tr("main.priority_medium");
    }
  }
}
