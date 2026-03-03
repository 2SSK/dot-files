import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "Constants.js" as Constants

Item {
  id: root
  signal requestTabCycleForward
  signal requestTabCycleBackward

  property var pluginApi: null
  property var mainInstance: null

  // State from main instance
  readonly property var messages: mainInstance?.messages || []
  readonly property bool isGenerating: mainInstance?.isGenerating || false
  readonly property string currentResponse: mainInstance?.currentResponse || ""
  readonly property string errorMessage: mainInstance?.errorMessage || ""
  property string initialInputText: mainInstance?.chatInputText || ""
  property int initialCursorPosition: mainInstance?.chatInputCursorPosition || 0

  // Provider info - use mainInstance for computed model (has per-provider logic)
  readonly property string provider: mainInstance?.provider || Constants.Providers.GOOGLE
  readonly property string model: mainInstance?.model || ""

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

    // Header with model info
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NIcon {
        icon: getProviderIcon()
        color: Color.mPrimary
        pointSize: Style.fontSizeM
        applyUiScale: false
      }

      NText {
        text: model
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        applyUiScale: false
        font.weight: Font.Medium
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      NIcon {
        icon: "loader-2"
        visible: isGenerating
        color: Color.mPrimary
        pointSize: Style.fontSizeS
        applyUiScale: false

        RotationAnimation on rotation {
          from: 0
          to: 360
          duration: 1000
          loops: Animation.Infinite
          running: isGenerating
        }
      }

      // Text-based clear history control matching translator backend text
      NText {
        id: clearHistoryText
        text: pluginApi?.tr("chat.clearHistory") || "Clear history"
        property bool enabledClear: messages.length > 0 && !isGenerating
        property bool hovered: false
        color: clearHistoryText.enabledClear ? (clearHistoryText.hovered ? Color.mOnSurface : Color.mOnSurfaceVariant) : Color.mOnSurfaceVariant
        pointSize: Style.fontSizeXS
        applyUiScale: false
        font.weight: clearHistoryText.hovered ? Font.Medium : Font.Normal
        verticalAlignment: Text.AlignVCenter
        opacity: clearHistoryText.enabledClear ? 1.0 : 0.5
        Layout.alignment: Qt.AlignRight

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: clearHistoryText.enabledClear
          onEntered: clearHistoryText.hovered = true
          onExited: clearHistoryText.hovered = false
          onClicked: {
            if (mainInstance)
              mainInstance.clearMessages();
          }
        }
      }
    }

    // Messages list container
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: Color.mSurface
      radius: Style.radiusM
      clip: true

      // Empty state
      Item {
        anchors.fill: parent
        visible: messages.length === 0 && !isGenerating

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM

          NIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: "sparkles"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXXL * 2
            applyUiScale: false
          }

          NText {
            Layout.alignment: Qt.AlignHCenter
            text: pluginApi?.tr("chat.emptyTitle") || "Start a conversation"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeM
            applyUiScale: false
            font.weight: Font.Medium
          }

          NText {
            Layout.alignment: Qt.AlignHCenter
            text: pluginApi?.tr("chat.emptyHint") || "Type a message below to begin"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            applyUiScale: false
          }
        }
      }

      // Chat messages using Flickable + Column + Repeater pattern
      // This approach is more predictable than ListView for dynamic chat content
      Flickable {
        id: chatFlickable
        anchors.fill: parent
        anchors.margins: Style.marginS
        contentWidth: width
        contentHeight: messageColumn.height
        clip: true
        visible: messages.length > 0 || isGenerating
        boundsBehavior: Flickable.StopAtBounds

        property real wheelScrollMultiplier: 4.0

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: event => {
            const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 8;
            const newY = chatFlickable.contentY - (delta * chatFlickable.wheelScrollMultiplier);
            chatFlickable.contentY = Math.max(0, Math.min(newY, chatFlickable.contentHeight - chatFlickable.height));
            // Update auto-scroll state manually since we are bypassing Flickable movement
            chatFlickable.autoScrollEnabled = chatFlickable.isNearBottom;
            event.accepted = true;
          }
        }

        // Auto-scroll state
        property bool autoScrollEnabled: true

        // Check if we're near the bottom (with threshold)
        readonly property bool isNearBottom: {
          if (contentHeight <= height)
            return true;
          return contentY >= contentHeight - height - 30;
        }

        // Smoothly scroll to bottom
        function scrollToBottom() {
          if (contentHeight > height) {
            contentY = contentHeight - height;
          }
        }

        // Handle content height changes - scroll to bottom if auto-scroll enabled
        onContentHeightChanged: {
          if (autoScrollEnabled && contentHeight > height) {
            scrollToBottom();
          }
        }

        // Detect manual scrolling - disable auto-scroll if user scrolls up
        onMovementEnded: {
          autoScrollEnabled = isNearBottom;
        }

        onFlickEnded: {
          autoScrollEnabled = isNearBottom;
        }

        // Messages column
        Column {
          id: messageColumn
          width: chatFlickable.width
          spacing: Style.marginM

          // Existing messages from history
          Repeater {
            id: messageRepeater
            model: messages

            MessageBubble {
              width: messageColumn.width
              message: modelData
              pluginApi: root.pluginApi

              onRegenerateRequested: {
                if (mainInstance && !isGenerating) {
                  mainInstance.regenerateLastResponse();
                }
              }
              onEditRequested: function (id, newText) {
                if (mainInstance && !isGenerating) {
                  mainInstance.editMessage(id, newText);
                }
              }
              onCopyRequested: function (text) {
                Quickshell.clipboardText = text;
                ToastService.showNotice(pluginApi?.tr("toast.copied") || "Copied to clipboard");
              }
            }
          }

          // Streaming message (shown during generation)
          MessageBubble {
            id: streamingBubble
            width: messageColumn.width
            visible: isGenerating && currentResponse.trim() !== ""
            pluginApi: root.pluginApi
            message: ({
                "id": "streaming",
                "role": "assistant",
                "content": currentResponse,
                "isStreaming": true
              })
          }
        }
      }

      // Scroll to bottom button - only visible when user has scrolled away
      Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.marginM
        width: 32
        height: 32
        radius: width / 2
        color: Color.mPrimary
        visible: !chatFlickable.autoScrollEnabled && messages.length > 0
        opacity: scrollButtonMouse.containsMouse ? 1.0 : 0.8

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationFast
          }
        }

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-down"
          color: Color.mOnPrimary
          pointSize: Style.fontSizeM
          applyUiScale: false
        }

        MouseArea {
          id: scrollButtonMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            chatFlickable.autoScrollEnabled = true;
            chatFlickable.scrollToBottom();
          }
        }
      }
    }

    // Error message
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: errorRow.implicitHeight + Style.marginS * 2
      color: Qt.alpha(Color.mError, 0.2)
      radius: Style.radiusS
      visible: errorMessage !== ""

      RowLayout {
        id: errorRow
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginS

        NIcon {
          icon: "alert-triangle"
          color: Color.mError
          pointSize: Style.fontSizeM
        }

        TextEdit {
          Layout.fillWidth: true
          text: errorMessage
          color: Color.mError
          font.pointSize: Math.max(1, Style.fontSizeS * Settings.data.ui.fontDefaultScale * Style.uiScaleRatio)
          font.family: Settings.data.ui.fontDefault
          wrapMode: TextEdit.Wrap
          readOnly: true
          selectByMouse: true
          textFormat: Text.MarkdownText
          onLinkActivated: link => Qt.openUrlExternally(link)
        }
      }
    }

    // Input area
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: inputLayout.implicitHeight + Style.marginS * 2
      color: Color.mSurface
      radius: Style.radiusM

      RowLayout {
        id: inputLayout
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginS

        ScrollView {
          Layout.fillWidth: true
          Layout.maximumHeight: 100

          TextArea {
            id: inputField
            text: initialInputText
            placeholderText: pluginApi?.tr("chat.placeholder") || "Type a message..."
            placeholderTextColor: Color.mOnSurfaceVariant
            color: Color.mOnSurface
            font.pointSize: Style.fontSizeM
            wrapMode: TextArea.Wrap
            background: null
            selectByMouse: true
            enabled: !isGenerating

            onCursorPositionChanged: {
              if (mainInstance) {
                if (mainInstance.chatInputCursorPosition !== cursorPosition) {
                  mainInstance.chatInputCursorPosition = cursorPosition;
                  // Debounce handled in Main.qml saveState
                  mainInstance.saveState();
                }
              }
            }

            onTextChanged: {
              if (mainInstance) {
                // Only update if changed to avoid loop
                if (mainInstance.chatInputText !== text) {
                  mainInstance.chatInputText = text;
                  mainInstance.saveState();
                }
              }
            }

            Keys.onReturnPressed: function (event) {
              if (event.modifiers & Qt.ShiftModifier) {
                // Insert newline
                inputField.insert(inputField.cursorPosition, "\n");
              } else {
                // Send message
                sendMessage();
              }
              event.accepted = true;
            }
            Keys.onPressed: function (event) {
              if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.requestTabCycleBackward();
                event.accepted = true;
              } else if (event.key === Qt.Key_Tab && !event.modifiers) {
                root.requestTabCycleForward();
                event.accepted = true;
              }
            }
          }
        }

        NIconButton {
          id: sendButton
          icon: isGenerating ? "player-stop" : "send"
          colorFg: isGenerating ? Color.mError : (inputField.text.trim() !== "" ? Color.mPrimary : Color.mOnSurfaceVariant)
          enabled: isGenerating || inputField.text.trim() !== ""
          tooltipText: isGenerating ? (pluginApi?.tr("chat.stop") || "Stop generation") : (pluginApi?.tr("chat.send") || "Send")
          onClicked: {
            if (isGenerating) {
              if (mainInstance)
                mainInstance.stopGeneration();
            } else {
              sendMessage();
            }
          }
        }
      }
    }
  }

  function sendMessage() {
    var text = inputField.text.trim();
    if (text === "" || !mainInstance)
      return;
    mainInstance.sendMessage(text);
    inputField.text = "";
    mainInstance.chatInputText = "";
    mainInstance.chatInputCursorPosition = 0;
    mainInstance.saveState();
    inputField.forceActiveFocus();
  }

  function getProviderIcon() {
    switch (provider) {
    case Constants.Providers.GOOGLE:
      return "brand-google";
    case Constants.Providers.OPENAI_COMPATIBLE:
      return "brand-openai";
    default:
      return "sparkles";
    }
  }

  // Safe focusInput method for parent to call
  function focusInput() {
    if (typeof inputField !== 'undefined' && inputField && inputField.forceActiveFocus) {
      inputField.forceActiveFocus();
      if (initialCursorPosition > 0 && initialCursorPosition <= inputField.text.length) {
        inputField.cursorPosition = initialCursorPosition;
      }
    }
  }
}
