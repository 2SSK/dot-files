import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property bool valueShowCompleted: pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted
  property bool valueShowBackground: pluginApi?.pluginSettings?.showBackground !== undefined ? pluginApi.pluginSettings.showBackground : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground

  // Priority color properties
  property bool valueUseCustomColors: pluginApi?.pluginSettings?.useCustomColors !== undefined ? pluginApi.pluginSettings.useCustomColors : false
  property color valueHighPriorityColor: (pluginApi?.pluginSettings?.priorityColors?.high) || (pluginApi?.manifest?.metadata?.defaultSettings?.priorityColors?.high) || Color.mError.toString()
  property color valueMediumPriorityColor: (pluginApi?.pluginSettings?.priorityColors?.medium) || (pluginApi?.manifest?.metadata?.defaultSettings?.priorityColors?.medium) || Color.mPrimary.toString()
  property color valueLowPriorityColor: (pluginApi?.pluginSettings?.priorityColors?.low) || (pluginApi?.manifest?.metadata?.defaultSettings?.priorityColors?.low) || Color.mOnSurfaceVariant.toString()

  // Reference to Main.qml instance for centralized data management
  readonly property var mainInstance: pluginApi?.mainInstance

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("Todo", "Settings UI loaded");
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show_completed.label")
    description: pluginApi?.tr("settings.show_completed.description")
    checked: root.valueShowCompleted
    onToggled: function (checked) {
      root.valueShowCompleted = checked;
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.background_color.label")
    description: pluginApi?.tr("settings.background_color.description")
    checked: root.valueShowBackground
    onToggled: function (checked) {
      root.valueShowBackground = checked;
    }
  }

  // Toggle for custom priority colors
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.custom_priority_colors.label")
    description: pluginApi?.tr("settings.custom_priority_colors.description")
    checked: root.valueUseCustomColors
    onToggled: function (checked) {
      root.valueUseCustomColors = checked;
    }
  }

  // Section for priority color settings (only visible when custom colors are enabled)
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    visible: root.valueUseCustomColors

    NText {
      text: pluginApi?.tr("settings.priority_colors.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    GridLayout {
      columns: 2
      rowSpacing: Style.marginS
      columnSpacing: Style.marginM
      Layout.fillWidth: true

      // High priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.high_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerHigh
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueHighPriorityColor
        onColorSelected: function (color) {
          root.valueHighPriorityColor = color;
        }
      }

      // Medium priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.medium_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerMedium
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueMediumPriorityColor
        onColorSelected: function (color) {
          root.valueMediumPriorityColor = color;
        }
      }

      // Low priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.low_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerLow
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueLowPriorityColor
        onColorSelected: function (color) {
          root.valueLowPriorityColor = color;
        }
      }
    }
  }

  // Section for managing pages
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NText {
      text: pluginApi?.tr("settings.pages.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    // Input for adding new pages
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInput {
        id: newPageInput
        placeholderText: pluginApi?.tr("settings.pages.placeholder")
        Layout.fillWidth: true
        Keys.onReturnPressed: addPage()
      }

      NButton {
        text: pluginApi?.tr("settings.pages.add_button")
        onClicked: addPage()
      }
    }

    // List of existing pages with proper scrolling
    Item {
      Layout.fillWidth: true
      height: 200

      Flickable {
        id: pagesListView
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        ScrollBar.vertical: ScrollBar {
          parent: pagesListView
          anchors.top: pagesListView.top
          anchors.right: pagesListView.right
          anchors.bottom: pagesListView.bottom
          policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: pluginApi?.pluginSettings?.pages || []

            delegate: Item {
              width: parent.width
              height: Style.baseWidgetSize

              property bool editing: false
              property string originalName: modelData.name || ""

              // Function to save the renamed page
              function saveRename() {
                var newName = renameInput.text.trim();
                if (newName === "") {
                  editing = false;
                  return;
                }

                if (newName === originalName) {
                  editing = false;
                  return;
                }

                if (!isPageNameUnique(newName, index)) {
                  ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
                  return;
                }

                // Use mainInstance to rename page
                if (mainInstance) {
                  mainInstance.renamePageInternal(modelData.id, newName);
                }

                originalName = newName;
                editing = false;
              }

              // Function to cancel renaming
              function cancelRename() {
                if (renameInput) {
                  renameInput.text = originalName;
                }
                editing = false;
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginS

                // Container for the normal view (when not editing)
                Item {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  visible: !editing

                  RowLayout {
                    anchors.fill: parent
                    spacing: Style.marginS

                    NText {
                      text: modelData.name
                      Layout.fillWidth: true
                      verticalAlignment: Text.AlignVCenter
                    }

                    NIconButton {
                      icon: "pencil"
                      tooltipText: pluginApi?.tr("settings.pages.rename_button_tooltip")
                      onClicked: {
                        // Switch to editing mode and capture the current name
                        originalName = modelData.name;
                        editing = true;
                      }
                    }

                    NIconButton {
                      icon: "trash"
                      tooltipText: pluginApi?.tr("settings.pages.delete_button_tooltip")
                      colorFg: Color.mError
                      enabled: (pluginApi?.pluginSettings?.pages?.length || 0) > 1 && modelData.id !== 0
                      onClicked: {
                        if ((pluginApi?.pluginSettings?.pages?.length || 0) <= 1) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
                          return;
                        }

                        if (modelData.id === 0) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
                          return;
                        }

                        // Show confirmation dialog before deleting
                        root.showDeleteConfirmation(index, modelData.name);
                      }
                    }
                  }
                }

                // Editing UI - only visible when in editing mode
                RowLayout {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  spacing: Style.marginS
                  visible: editing

                  NTextInput {
                    id: renameInput
                    text: originalName
                    Layout.fillWidth: true
                    Layout.preferredWidth: 150
                    focus: editing

                    Keys.onReturnPressed: saveRename()
                    Keys.onEscapePressed: cancelRename()

                    onVisibleChanged: {
                      if (visible && editing) {
                        text = originalName;
                        forceActiveFocus();
                      }
                    }
                  }

                  NButton {
                    text: "✓"
                    fontSize: Style.fontSizeS
                    backgroundColor: Color.mPrimary
                    textColor: Color.mOnPrimary
                    onClicked: saveRename()
                  }

                  NButton {
                    text: "✕"
                    fontSize: Style.fontSizeS
                    backgroundColor: Color.mError
                    textColor: Color.mOnError
                    onClicked: cancelRename()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function isPageNameUnique(name, excludeIndex) {
    var pages = pluginApi?.pluginSettings?.pages || [];
    var lowerName = name.toLowerCase().trim();
    for (var i = 0; i < pages.length; i++) {
      if (i !== excludeIndex && pages[i].name.toLowerCase().trim() === lowerName) {
        return false;
      }
    }
    return true;
  }

  function addPage() {
    var name = newPageInput.text.trim();

    if (name === "") {
      ToastService.showError(pluginApi?.tr("settings.pages.empty_name"));
      return;
    }

    if (!isPageNameUnique(name, -1)) {
      ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
      return;
    }

    // Use mainInstance to create page
    if (mainInstance) {
      mainInstance.createPage(name);
    }

    newPageInput.text = "";
    newPageInput.forceActiveFocus();
  }

  // Confirmation dialog for page deletion
  Popup {
    id: confirmDialog
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 300
    height: 150

    background: Rectangle {
      color: Color.mSurface
      border.color: Color.mOutline
      border.width: 1
      radius: Style.radiusL
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        id: confirmText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Are you sure you want to delete this page?"
        verticalAlignment: Text.AlignVCenter
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Style.marginS

        NButton {
          text: "Cancel"
          onClicked: confirmDialog.close()
        }

        NButton {
          text: "Delete"
          textColor: Color.mOnError
          backgroundColor: Color.mError
          onClicked: {
            performPageDeletion(confirmDialog.pageIndex);
            confirmDialog.close();
          }
        }
      }
    }

    // Property to store the index of the page to delete
    property int pageIndex: -1
  }

  // Function to show the confirmation dialog
  function showDeleteConfirmation(pageIdx, pageName) {
    confirmDialog.pageIndex = pageIdx;
    var confirmMessage = pluginApi?.tr("settings.pages.confirm_delete_message");
    confirmText.text = confirmMessage.replace("{pageName}", pageName);
    confirmDialog.open();
  }

  // Function to perform the actual page deletion
  function performPageDeletion(pageIdx) {
    if (pageIdx < 0)
      return;

    var pages = pluginApi?.pluginSettings?.pages || [];

    // Prevent deleting default page (id: 0)
    if (pages[pageIdx].id === 0) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
      return;
    }

    if (pages.length <= 1) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
      return;
    }

    var pageToDeleteId = pages[pageIdx].id;

    // Use mainInstance to delete page (handles todos migration and current_page_id update)
    if (mainInstance) {
      mainInstance.deletePage(pageToDeleteId);
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Todo", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showCompleted = root.valueShowCompleted;
    pluginApi.pluginSettings.showBackground = root.valueShowBackground;
    pluginApi.pluginSettings.useCustomColors = root.valueUseCustomColors;

    // Only save custom colors if the option is enabled
    if (root.valueUseCustomColors) {
      // Save priority colors
      if (!pluginApi.pluginSettings.priorityColors) {
        pluginApi.pluginSettings.priorityColors = {};
      }
      pluginApi.pluginSettings.priorityColors.high = root.valueHighPriorityColor.toString();
      pluginApi.pluginSettings.priorityColors.medium = root.valueMediumPriorityColor.toString();
      pluginApi.pluginSettings.priorityColors.low = root.valueLowPriorityColor.toString();
    } else {
      // If custom colors are disabled, reset to defaults
      pluginApi.pluginSettings.priorityColors = {
        "high": Color.mError.toString(),
        "medium": Color.mPrimary.toString(),
        "low": Color.mOnSurfaceVariant.toString()
      };
    }

    pluginApi.saveSettings();

    Logger.i("Todo", "Settings saved successfully");
    return;
  }
}
