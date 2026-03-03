import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root
  signal requestTabCycleForward
  signal requestTabCycleBackward

  property var pluginApi: null
  property var mainInstance: null

  // State from main instance
  readonly property string translatedText: mainInstance?.translatedText || ""
  readonly property bool isTranslating: mainInstance?.isTranslating || false
  readonly property string translationError: mainInstance?.translationError || ""

  // Settings
  readonly property string backend: pluginApi?.pluginSettings?.translator?.backend || "google"
  property string sourceLanguage: pluginApi?.pluginSettings?.translator?.sourceLanguage || "auto"
  property string targetLanguage: pluginApi?.pluginSettings?.translator?.targetLanguage || "en"
  readonly property bool realTimeTranslation: pluginApi?.pluginSettings?.translator?.realTimeTranslation ?? true

  // Input text
  property string inputText: ""

  // Common languages
  readonly property var languages: [
    {
      "code": "auto",
      "name": pluginApi?.tr("languages.auto") || "Auto Detect"
    },
    {
      "code": "en",
      "name": pluginApi?.tr("languages.en") || "English"
    },
    {
      "code": "es",
      "name": pluginApi?.tr("languages.es") || "Spanish"
    },
    {
      "code": "fr",
      "name": pluginApi?.tr("languages.fr") || "French"
    },
    {
      "code": "de",
      "name": pluginApi?.tr("languages.de") || "German"
    },
    {
      "code": "it",
      "name": pluginApi?.tr("languages.it") || "Italian"
    },
    {
      "code": "pt",
      "name": pluginApi?.tr("languages.pt") || "Portuguese"
    },
    {
      "code": "ru",
      "name": pluginApi?.tr("languages.ru") || "Russian"
    },
    {
      "code": "ja",
      "name": pluginApi?.tr("languages.ja") || "Japanese"
    },
    {
      "code": "ko",
      "name": pluginApi?.tr("languages.ko") || "Korean"
    },
    {
      "code": "zh",
      "name": pluginApi?.tr("languages.zh") || "Chinese"
    },
    {
      "code": "ar",
      "name": pluginApi?.tr("languages.ar") || "Arabic"
    },
    {
      "code": "hi",
      "name": pluginApi?.tr("languages.hi") || "Hindi"
    },
    {
      "code": "nl",
      "name": pluginApi?.tr("languages.nl") || "Dutch"
    },
    {
      "code": "pl",
      "name": pluginApi?.tr("languages.pl") || "Polish"
    },
    {
      "code": "tr",
      "name": pluginApi?.tr("languages.tr") || "Turkish"
    },
    {
      "code": "uk",
      "name": pluginApi?.tr("languages.uk") || "Ukrainian"
    },
    {
      "code": "vi",
      "name": pluginApi?.tr("languages.vi") || "Vietnamese"
    }
  ]

  // Debounce timer for real-time translation
  Timer {
    id: translateTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (inputText.trim() !== "" && mainInstance) {
        mainInstance.translate(inputText, targetLanguage, sourceLanguage);
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NIcon {
        icon: "language"
        color: Color.mPrimary
        pointSize: Style.fontSizeM
        applyUiScale: false
      }

      NText {
        text: pluginApi?.tr("translator.title") || "Translator"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
        applyUiScale: false
        font.weight: Font.Medium
        Layout.fillWidth: true
      }

      NIcon {
        icon: "loader-2"
        visible: isTranslating
        color: Color.mPrimary
        pointSize: Style.fontSizeS
        applyUiScale: false

        RotationAnimation on rotation {
          from: 0
          to: 360
          duration: 1000
          loops: Animation.Infinite
          running: isTranslating
        }
      }

      NText {
        text: backend === "google" ? "Google" : "DeepL"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeXS
        applyUiScale: false
      }
    }

    // Language selectors
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      // Source language
      LanguageSelector {
        Layout.fillWidth: true
        label: pluginApi?.tr("translator.from") || "From"
        languages: root.languages
        currentCode: sourceLanguage
        showAuto: true
        onLanguageSelected: function (code) {
          if (pluginApi) {
            sourceLanguage = code;
            pluginApi.pluginSettings.translator.sourceLanguage = code;
            pluginApi.saveSettings();
            if (inputText.trim() !== "") {
              translateTimer.restart();
            }
          }
        }
      }

      // Swap button
      NIconButton {
        icon: "arrows-exchange"
        colorFg: Color.mOnSurfaceVariant
        tooltipText: pluginApi?.tr("translator.swap") || "Swap languages"
        enabled: sourceLanguage !== "auto"
        opacity: enabled ? 1.0 : 0.5
        onClicked: {
          if (pluginApi && sourceLanguage !== "auto") {
            var temp = sourceLanguage;
            sourceLanguage = targetLanguage;
            targetLanguage = temp;
            pluginApi.pluginSettings.translator.sourceLanguage = sourceLanguage;
            pluginApi.pluginSettings.translator.targetLanguage = targetLanguage;
            pluginApi.saveSettings();
            if (inputText.trim() !== "") {
              translateTimer.restart();
            }
          }
        }
      }

      // Target language
      LanguageSelector {
        Layout.fillWidth: true
        label: pluginApi?.tr("translator.to") || "To"
        languages: root.languages.filter(function (l) {
          return l.code !== "auto";
        })
        currentCode: targetLanguage
        showAuto: false
        onLanguageSelected: function (code) {
          if (pluginApi) {
            targetLanguage = code;
            pluginApi.pluginSettings.translator.targetLanguage = code;
            pluginApi.saveSettings();
            if (inputText.trim() !== "") {
              translateTimer.restart();
            }
          }
        }
      }
    }

    // Input area
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: parent.height * 0.35
      color: Color.mSurface
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginXS

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true

          TextArea {
            id: inputField
            placeholderText: pluginApi?.tr("translator.inputPlaceholder") || "Enter text to translate..."
            placeholderTextColor: Color.mOnSurfaceVariant
            color: Color.mOnSurface
            font.pointSize: Style.fontSizeM
            wrapMode: TextArea.Wrap
            background: null
            selectByMouse: true

            onTextChanged: {
              root.inputText = text;
              if (realTimeTranslation && text.trim() !== "") {
                translateTimer.restart();
              } else if (text.trim() === "") {
                if (mainInstance) {
                  mainInstance.translatedText = "";
                }
              }
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

        // Input actions
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Item {
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "clipboard"
            colorFg: Color.mOnSurfaceVariant
            tooltipText: pluginApi?.tr("translator.paste") || "Paste"
            onClicked: {
              inputField.text = Quickshell.clipboardText;
            }
          }

          NIconButton {
            icon: "x"
            colorFg: Color.mOnSurfaceVariant
            tooltipText: pluginApi?.tr("translator.clear") || "Clear"
            enabled: inputField.text.length > 0
            opacity: enabled ? 1.0 : 0.5
            onClicked: {
              inputField.text = "";
            }
          }

          NButton {
            text: pluginApi?.tr("translator.translate") || "Translate"
            icon: "language"
            enabled: inputField.text.trim() !== "" && !isTranslating
            visible: !realTimeTranslation
            onClicked: {
              if (mainInstance && inputText.trim() !== "") {
                mainInstance.translate(inputText, targetLanguage, sourceLanguage);
              }
            }
          }
        }
      }
    }

    // Divider with arrow
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 24

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.mOutline
      }

      NIcon {
        id: dividerIcon
        icon: "chevron-down"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        applyUiScale: false
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.mOutline
      }
    }

    // Output area
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: parent.height * 0.35
      color: Color.mSurface
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginXS

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true

          TextArea {
            id: outputField
            text: translatedText
            placeholderText: pluginApi?.tr("translator.outputPlaceholder") || "Translation will appear here..."
            placeholderTextColor: Color.mOnSurfaceVariant
            color: Color.mOnSurface
            font.pointSize: Style.fontSizeM
            wrapMode: TextArea.Wrap
            background: null
            readOnly: true
            selectByMouse: true
          }
        }

        // Output actions
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          // Error display
          RowLayout {
            visible: translationError !== ""
            spacing: Style.marginXS

            NIcon {
              icon: "alert-triangle"
              color: Color.mError
              pointSize: Style.fontSizeS
            }

            NText {
              text: translationError
              color: Color.mError
              pointSize: Style.fontSizeXS
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }

          Item {
            Layout.fillWidth: true
            visible: translationError === ""
          }

          NIconButton {
            icon: "copy"
            colorFg: Color.mOnSurfaceVariant
            tooltipText: pluginApi?.tr("translator.copy") || "Copy"
            enabled: translatedText.trim() !== ""
            opacity: enabled ? 1.0 : 0.5
            onClicked: {
              Quickshell.clipboardText = translatedText;
              ToastService.showNotice(pluginApi?.tr("toast.copied") || "Copied to clipboard");
            }
          }

          NIconButton {
            icon: "external-link"
            colorFg: Color.mOnSurfaceVariant
            tooltipText: pluginApi?.tr("translator.search") || "Search"
            enabled: translatedText.trim() !== ""
            opacity: enabled ? 1.0 : 0.5
            onClicked: {
              Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(translatedText));
            }
          }
        }
      }
    }
  }

  // Language selector component
  component LanguageSelector: Rectangle {
    id: selector

    property string label: ""
    property var languages: []
    property string currentCode: ""
    property bool showAuto: false
    property real uiScale: pluginApi?.pluginSettings?.scale ?? pluginApi?.manifest?.metadata?.defaultSettings?.scale ?? 1

    signal languageSelected(string code)

    color: selectorMouse.containsMouse ? Color.mHover : Color.mSurface
    radius: Style.iRadiusS
    implicitHeight: selectorContent.implicitHeight + Style.marginS * 2

    RowLayout {
      id: selectorContent
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginS

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        NText {
          text: selector.label
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeXS
        }

        NText {
          text: {
            for (var i = 0; i < languages.length; i++) {
              if (languages[i].code === currentCode) {
                return languages[i].name;
              }
            }
            return currentCode;
          }
          color: Color.mOnSurface
          pointSize: Style.fontSizeS
          font.weight: Font.Medium
        }
      }

      NIcon {
        icon: "chevron-down"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }
    }

    MouseArea {
      id: selectorMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: languagePopup.open()
    }

    Popup {
      id: languagePopup
      x: 0
      y: parent.height + Style.marginXS
      width: parent.width * selector.uiScale
      height: Math.min(300 * selector.uiScale, langList.contentHeight + Style.marginS * 2)

      background: Rectangle {
        color: Color.mSurface
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: 1
      }

      contentItem: ListView {
        id: langList
        clip: true
        model: selector.languages

        delegate: Rectangle {
          width: langList.width
          height: (langItemContent.implicitHeight * selector.uiScale) + (Style.marginS * 2)
          color: langItemMouse.containsMouse ? Color.mHover : "transparent"
          radius: Style.iRadiusXS

          RowLayout {
            id: langItemContent
            anchors.fill: parent
            anchors.margins: Style.marginS * 0.6
            spacing: Style.marginS * 0.6

            NText {
              text: modelData.name
              color: modelData.code === selector.currentCode ? Color.mPrimary : Color.mOnSurface
              pointSize: Style.fontSizeS * selector.uiScale
              font.weight: modelData.code === selector.currentCode ? Font.Medium : Font.Normal
              Layout.fillWidth: true
            }

            NIcon {
              icon: "check"
              color: Color.mPrimary
              pointSize: Style.fontSizeS * selector.uiScale
              visible: modelData.code === selector.currentCode
            }
          }

          MouseArea {
            id: langItemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              selector.languageSelected(modelData.code);
              languagePopup.close();
            }
          }
        }
      }
    }
  }

  // Safe focusInput method for parent to call
  function focusInput() {
    if (typeof inputField !== 'undefined' && inputField && inputField.forceActiveFocus) {
      inputField.forceActiveFocus();
    }
  }
}
