import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root
  showBackground: (pluginApi && pluginApi.pluginSettings ? (pluginApi.pluginSettings.showBackground !== undefined ? pluginApi.pluginSettings.showBackground : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground) : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground)

  property var pluginApi: null
  property bool expanded: false
  property bool showCompleted: false
  property var rawTodos: []
  property int currentPageId: 0
  property ListModel filteredTodosModel: ListModel {}
  readonly property color todoBg: showBackground ? Qt.rgba(0, 0, 0, 0.2) : "transparent"
  readonly property color itemBg: showBackground ? Color.mSurface : "transparent"
  readonly property color completedItemBg: showBackground ? Color.mSurfaceVariant : "transparent"
  // Scaled dimensions
  readonly property int scaledMarginM: Math.round(Style.marginM * widgetScale)
  readonly property int scaledMarginS: Math.round(Style.marginS * widgetScale)
  readonly property int scaledMarginL: Math.round(Style.marginL * widgetScale)
  readonly property int scaledBaseWidgetSize: Math.round(Style.baseWidgetSize * widgetScale)
  readonly property int scaledFontSizeL: Math.round(Style.fontSizeL * widgetScale)
  readonly property int scaledFontSizeM: Math.round(Style.fontSizeM * widgetScale)
  readonly property int scaledFontSizeS: Math.round(Style.fontSizeS * widgetScale)
  readonly property int scaledRadiusM: Math.round(Style.radiusM * widgetScale)
  readonly property int scaledRadiusS: Math.round(Style.radiusS * widgetScale)

  // Reference to Main.qml instance for centralized data management
  readonly property var mainInstance: pluginApi?.mainInstance

  implicitWidth: Math.round(300 * widgetScale)
  implicitHeight: {
    var headerHeight = scaledBaseWidgetSize + scaledMarginL * 2;
    if (!expanded)
      return headerHeight;

    // Add the height of the tab bar when expanded
    var tabBarHeight = scaledBaseWidgetSize * 0.8;
    var todosCount = root.filteredTodosModel.count;
    var contentHeight = (todosCount === 0) ? scaledBaseWidgetSize : (scaledBaseWidgetSize * todosCount + scaledMarginS * (todosCount - 1));
    var totalHeight = contentHeight + headerHeight + tabBarHeight + scaledMarginS + scaledMarginM * 4;

    return Math.min(totalHeight, headerHeight + tabBarHeight + Math.round(400 * widgetScale));
  }

  // Define a function to schedule reloading of todos
  function scheduleReload() {
    Qt.callLater(loadTodos);
  }

  // Bind rawTodos, showCompleted, and currentPageId to plugin settings
  Binding {
    target: root
    property: "rawTodos"
    value: pluginApi?.pluginSettings?.todos || []
  }

  Binding {
    target: root
    property: "showCompleted"
    value: pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false
  }

  Binding {
    target: root
    property: "currentPageId"
    value: pluginApi?.pluginSettings?.current_page_id || 0
  }

  Binding {
    target: root
    property: "expanded"
    value: pluginApi?.pluginSettings?.isExpanded !== undefined ? pluginApi.pluginSettings.isExpanded : pluginApi?.manifest?.metadata?.defaultSettings?.isExpanded || false
  }

  Component.onCompleted: {
    if (pluginApi) {
      Logger.i("Todo", "DesktopWidgets initialized");
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      loadTodos();
    }
  }

  // Listen for changes that affect the todo list display
  onRawTodosChanged: scheduleReload()
  onCurrentPageIdChanged: scheduleReload()
  onShowCompletedChanged: scheduleReload()

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: scaledMarginM
    spacing: scaledMarginS

    Item {
      Layout.fillWidth: true
      height: scaledBaseWidgetSize

      MouseArea {
        anchors.fill: parent
        onClicked: {
          root.expanded = !root.expanded;
          if (pluginApi) {
            pluginApi.pluginSettings.isExpanded = root.expanded;
            pluginApi.saveSettings();
          }
        }
      }

      RowLayout {
        anchors.fill: parent
        spacing: scaledMarginS

        NIcon {
          icon: "clipboard-check"
          pointSize: scaledFontSizeL
        }

        NText {
          text: pluginApi?.tr("desktop_widget.header_title")
          font.pointSize: scaledFontSizeL
          font.weight: Font.Medium
        }

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: {
            var todos = pluginApi?.pluginSettings?.todos || [];
            var activeTodos = todos.filter(function (todo) {
              return !todo.completed;
            }).length;

            var text = pluginApi?.tr("desktop_widget.items_count");
            return text.replace("{active}", activeTodos).replace("{total}", todos.length);
          }
          color: Color.mOnSurfaceVariant
          font.pointSize: scaledFontSizeS
        }

        NIcon {
          icon: root.expanded ? "chevron-up" : "chevron-down"
          pointSize: scaledFontSizeM
          color: Color.mOnSurfaceVariant
        }
      }
    }

    // Page selector using tab components - only visible when expanded
    NTabBar {
      id: tabBar
      Layout.fillWidth: true
      visible: expanded
      Layout.topMargin: scaledMarginS
      Layout.leftMargin: scaledMarginM
      Layout.rightMargin: scaledMarginM
      distributeEvenly: true
      currentIndex: currentPageIndex
      color: "transparent"
      border.width: 0

      // Track current page index
      property int currentPageIndex: {
        var pages = pluginApi?.pluginSettings?.pages || [];
        var currentId = pluginApi?.pluginSettings?.current_page_id || 0;
        for (var i = 0; i < pages.length; i++) {
          if (pages[i].id === currentId) {
            return i;
          }
        }
        return 0;
      }

      // Dynamically create tabs based on pages
      Repeater {
        model: pluginApi?.pluginSettings?.pages || []

        delegate: NTabButton {
          text: modelData.name
          tabIndex: index
          checked: index === tabBar.currentPageIndex

          color: showBackground ? (isHovered ? Color.mHover : (checked ? Color.mPrimary : Color.mOnPrimary)) : (isHovered ? Color.mHover : (checked ? "transparent" : "transparent"))

          border.width: 0

          Component.onCompleted: {
            topLeftRadius = Style.iRadiusM;
            bottomLeftRadius = Style.iRadiusM;
            topRightRadius = Style.iRadiusM;
            bottomRightRadius = Style.iRadiusM;
          }

          // custom underline rectangle when checked and no background
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            color: (showBackground || !checked) ? "transparent" : Color.mPrimary
            visible: !showBackground && checked
          }

          onClicked: {
            pluginApi.pluginSettings.current_page_id = modelData.id;
            pluginApi.saveSettings();
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: expanded

      // Background with border - fills entire available space
      Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: root.todoBg
        radius: scaledRadiusM
        // border.color: showBackground ? Color.mOutline : "transparent"
        // border.width: showBackground ? 1 : 0
      }

      // Inner container that is fully inset from the border area
      Item {
        id: innerContentArea
        anchors.fill: parent
        anchors.margins: showBackground ? (backgroundRect.border.width + 1) : 0

        // Scrollable area for the todo items
        Flickable {
          id: todoFlickable
          anchors.fill: parent

          leftMargin: scaledMarginM
          rightMargin: scaledMarginM
          topMargin: scaledMarginM
          bottomMargin: scaledMarginM

          contentWidth: width
          contentHeight: columnLayout.implicitHeight

          flickableDirection: Flickable.VerticalFlick
          clip: true
          boundsBehavior: Flickable.DragOverBounds
          interactive: true
          pressDelay: 150

          Column {
            id: columnLayout
            width: todoFlickable.width - todoFlickable.leftMargin - todoFlickable.rightMargin
            spacing: scaledMarginS

            Repeater {
              model: root.filteredTodosModel

              delegate: Item {
                width: parent.width
                height: scaledBaseWidgetSize

                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 0
                  color: model.completed ? root.completedItemBg : root.itemBg
                  radius: Style.iRadiusS * widgetScale

                  Item {
                    anchors.fill: parent
                    anchors.margins: scaledMarginM

                    // Custom checkbox implementation with TapHandler
                    Item {
                      id: customCheckboxContainer
                      width: scaledBaseWidgetSize * 0.7
                      height: scaledBaseWidgetSize * 0.7
                      anchors.left: priorityIndicator.right
                      anchors.verticalCenter: parent.verticalCenter

                      Rectangle {
                        id: customCheckbox
                        width: scaledBaseWidgetSize * 0.5
                        height: scaledBaseWidgetSize * 0.5
                        radius: Style.iRadiusXXS
                        color: Color.mSurface
                        opacity: showBackground ? 1.0 : 0.5
                        border.color: Color.mOutline
                        border.width: Style.borderS
                        anchors.centerIn: parent

                        NIcon {
                          visible: model.completed
                          anchors.centerIn: parent
                          anchors.horizontalCenterOffset: 0
                          icon: "check"
                          color: Color.mPrimary
                          pointSize: Math.max(Style.fontSizeXS, width * 0.5)
                        }

                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: false

                          onClicked: {
                            toggleTodo(model.id, model.completed);
                          }
                        }
                      }
                    }

                    // Priority indicator - a colored vertical line
                    Rectangle {
                      id: priorityIndicator
                      width: 3
                      height: parent.height - scaledMarginS
                      anchors.left: parent.left
                      anchors.leftMargin: scaledMarginM
                      anchors.verticalCenter: parent.verticalCenter
                      radius: 1.5

                      // Determine color based on priority using helper function
                      color: {
                        if (pluginApi) {
                          return getPriorityColor(model.priority || "medium");
                        } else {
                          var priority = model.priority || "medium";
                          if (priority === "high") {
                            return Color.mError;
                          } else if (priority === "low") {
                            return Color.mOnSurfaceVariant;
                          } else {
                            return Color.mPrimary;
                          }
                        }
                      }
                    }

                    NText {
                      text: model.text
                      color: model.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                      font.strikeout: model.completed
                      elide: Text.ElideRight
                      anchors.left: customCheckboxContainer.right
                      anchors.leftMargin: scaledMarginS
                      anchors.right: parent.right
                      anchors.rightMargin: scaledMarginM
                      anchors.verticalCenter: parent.verticalCenter
                      font.pointSize: scaledFontSizeS
                    }
                  }
                }
              }
            }
          }
        }

        // Empty state overlay
        Item {
          anchors.fill: parent
          anchors.margins: scaledMarginS
          visible: root.filteredTodosModel.count === 0

          NText {
            anchors.centerIn: parent
            text: pluginApi?.tr("desktop_widget.empty_state")
            color: Color.mOnSurfaceVariant
            font.pointSize: scaledFontSizeM
            font.weight: Font.Normal
          }
        }
      }
    }
  }

  // Internal utility functions
  function updateTodo(todoId, updates) {
    if (!mainInstance)
      return false;
    return mainInstance.updateTodo(todoId, updates);
  }

  // Helper function to toggle todo completion status
  function toggleTodo(todoId, currentCompletedStatus) {
    if (!mainInstance) {
      Logger.e("Todo", "mainInstance is null, cannot toggle todo");
      return false;
    }

    // Use the existing updateTodo function to update only the completion status
    return updateTodo(todoId, {
                        completed: !currentCompletedStatus
                      });
  }

  // Helper function to get priority color
  function getPriorityColor(priority) {
    // Validate priority
    var validPriorities = ["high", "medium", "low"];
    if (!priority || validPriorities.indexOf(priority) === -1) {
      priority = "medium";
    }

    if (!pluginApi) {
      // Fallback to theme colors when pluginApi not available
      return getThemeColor(priority);
    }

    var useCustomColors = pluginApi?.pluginSettings?.useCustomColors;
    if (useCustomColors) {
      var customColors = pluginApi?.pluginSettings?.priorityColors;
      if (customColors && customColors[priority]) {
        return customColors[priority];
      }
    }

    return getThemeColor(priority);
  }

  // Helper function to get theme color
  function getThemeColor(priority) {
    if (priority === "high")
      return Color.mError;
    if (priority === "low")
      return Color.mOnSurfaceVariant;
    return Color.mPrimary;
  }

  function loadTodos() {
    if (!pluginApi)
      return;

    filteredTodosModel.clear();

    var pluginTodos = root.rawTodos;
    var currentShowCompleted = root.showCompleted;
    var currentPageId = root.currentPageId;

    // Process todos in a single pass
    for (var i = 0; i < pluginTodos.length; i++) {
      var todo = pluginTodos[i];

      // Check if todo belongs to current page
      if (todo.pageId === currentPageId) {
        // Check if completed items should be shown
        if (currentShowCompleted || !todo.completed) {
          filteredTodosModel.append({
                                      id: todo.id,
                                      text: todo.text,
                                      completed: todo.completed,
                                      pageId: todo.pageId || 0,
                                      priority: todo.priority,
                                      details: todo.details
                                    });
        }
      }
    }
  }
}
