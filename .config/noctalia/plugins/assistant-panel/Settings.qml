import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "Constants.js" as Constants

ColumnLayout {
  id: root

  property var pluginApi: null

  // AI Settings - Local state
  property string editProvider: pluginApi?.pluginSettings?.ai?.provider || pluginApi?.manifest?.metadata?.defaultSettings?.ai?.provider || Constants.Providers.GOOGLE
  property var editModels: pluginApi?.pluginSettings?.ai?.models || {}
  property var editApiKeys: pluginApi?.pluginSettings?.ai?.apiKeys || {}
  // Use per-provider model if configured (and non-empty), else return empty to show placeholder
  property string editModel: {
    var saved = editModels[editProvider];
    if (saved !== undefined && saved !== "")
      return saved;
    return "";  // Empty = use default (shown in placeholder)
  }

  property string editApiKey: editApiKeys[editProvider] !== undefined ? editApiKeys[editProvider] : pluginApi?.manifest?.metadata?.defaultSettings?.ai?.apiKey || ""
  property real editTemperature: pluginApi?.pluginSettings?.ai?.temperature || pluginApi?.manifest?.metadata?.defaultSettings?.ai?.temperature || 0.7
  property string editSystemPrompt: pluginApi?.pluginSettings?.ai?.systemPrompt || pluginApi?.manifest?.metadata?.defaultSettings?.ai?.systemPrompt || ""

  // Translator Settings - Local state
  property string editTranslatorBackend: pluginApi?.pluginSettings?.translator?.backend || pluginApi?.manifest?.metadata?.defaultSettings?.translator?.backend || "google"
  property bool editRealTimeTranslation: pluginApi?.pluginSettings?.translator?.realTimeTranslation ?? pluginApi?.manifest?.metadata?.defaultSettings?.translator?.realTimeTranslation ?? true
  property string editDeeplApiKey: pluginApi?.pluginSettings?.translator?.deeplApiKey || pluginApi?.manifest?.metadata?.defaultSettings?.translator?.deeplApiKey || ""

  // General Settings
  property int editMaxHistoryLength: pluginApi?.pluginSettings?.maxHistoryLength || pluginApi?.manifest?.metadata?.defaultSettings?.maxHistoryLength || 100

  // Panel Settings (detached, position, height, offset, width)
  property bool editPanelDetached: pluginApi?.pluginSettings?.panelDetached ?? pluginApi?.manifest?.metadata?.panel?.detached ?? true
  property string editPanelPosition: pluginApi?.pluginSettings?.panelPosition || pluginApi?.manifest?.metadata?.panel?.defaultPosition || "right"
  property real editPanelHeightRatio: pluginApi?.pluginSettings?.panelHeightRatio || pluginApi?.manifest?.metadata?.panel?.defaultHeightRatio || 0.85
  property int editPanelWidth: pluginApi?.pluginSettings?.panelWidth ?? 520
  property string editAttachmentStyle: pluginApi?.pluginSettings?.attachmentStyle || "connected"
  property real editScale: pluginApi?.pluginSettings?.scale || pluginApi?.manifest?.metadata?.defaultSettings?.scale || 1

  // OpenAI Compatible specific settings
  property bool editOpenAiLocal: pluginApi?.pluginSettings?.ai?.openaiLocal ?? false
  property string editOpenAiBaseUrl: pluginApi?.pluginSettings?.ai?.openaiBaseUrl || "https://api.openai.com/v1/chat/completions"

  // Environment variable API keys - check if managed by env
  readonly property var envApiKeys: ({
      [Constants.Providers.GOOGLE]: Quickshell.env("NOCTALIA_AP_GOOGLE_API_KEY") || "",
      [Constants.Providers.OPENAI_COMPATIBLE]: Quickshell.env("NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY") || ""
    })
  readonly property bool apiKeyManagedByEnv: (envApiKeys[editProvider] || "") !== ""
  readonly property string envDeeplApiKey: Quickshell.env("NOCTALIA_AP_DEEPL_API_KEY") || ""
  readonly property bool deeplApiKeyManagedByEnv: envDeeplApiKey !== ""
  // ==================
  // Panel Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.panelSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: Color.mOnSurface
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.panelDetached")
    description: pluginApi?.tr("settings.panelDetachedDesc")
    checked: root.editPanelDetached
    onToggled: function (checked) {
      root.editPanelDetached = checked;
      // Reset position if invalid for new mode
      if (checked) {
        // Switching to Detached: "top" and "bottom" become invalid -> default to "right"
        if (root.editPanelPosition === "top" || root.editPanelPosition === "bottom") {
          root.editPanelPosition = "right";
        }
      } else {
        // Switching to Attached: "center" becomes invalid -> default to "right"
        if (root.editPanelPosition === "center") {
          root.editPanelPosition = "right";
        }
      }
    }
    defaultValue: true
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.panelPosition")
    description: pluginApi?.tr("settings.panelPositionDesc")
    model: root.editPanelDetached ? [
      {
        "key": "left",
        "name": pluginApi?.tr("settings.panelPositionLeft")
      },
      {
        "key": "center",
        "name": pluginApi?.tr("settings.panelPositionCenter")
      },
      {
        "key": "right",
        "name": pluginApi?.tr("settings.panelPositionRight")
      }
    ] : [
      {
        "key": "left",
        "name": pluginApi?.tr("settings.panelPositionLeft")
      },
      {
        "key": "top",
        "name": pluginApi?.tr("settings.panelPositionTop")
      },
      {
        "key": "bottom",
        "name": pluginApi?.tr("settings.panelPositionBottom")
      },
      {
        "key": "right",
        "name": pluginApi?.tr("settings.panelPositionRight")
      }
    ]
    currentKey: root.editPanelPosition
    onSelected: function (key) {
      root.editPanelPosition = key;
    }
    defaultValue: "right"
  }

  NComboBox {
    Layout.fillWidth: true
    visible: !root.editPanelDetached
    label: pluginApi?.tr("settings.attachmentStyle")
    description: pluginApi?.tr("settings.attachmentStyleDesc")
    model: [
      {
        "key": "connected",
        "name": pluginApi?.tr("settings.attachConnected")
      },
      {
        "key": "floating",
        "name": pluginApi?.tr("settings.attachFloating")
      }
    ]
    currentKey: root.editAttachmentStyle
    onSelected: function (key) {
      root.editAttachmentStyle = key;
    }
    defaultValue: "connected"
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    NLabel {
      label: pluginApi?.tr("settings.panelHeightRatio") + ": " + (root.editPanelHeightRatio * 100).toFixed(0) + "%"
      description: pluginApi?.tr("settings.panelHeightRatioDesc")
    }
    NSlider {
      Layout.fillWidth: true
      from: 0.3
      to: 1.0
      stepSize: 0.01
      value: root.editPanelHeightRatio
      onValueChanged: root.editPanelHeightRatio = value
    }
    NLabel {
      label: pluginApi?.tr("settings.panelWidth") + ": " + root.editPanelWidth + "px"
      description: pluginApi?.tr("settings.panelWidthDesc")
    }
    NSlider {
      Layout.fillWidth: true
      from: 320
      to: 1200
      stepSize: 1
      value: root.editPanelWidth
      onValueChanged: root.editPanelWidth = value
    }
    NLabel {
      label: pluginApi?.tr("settings.uiScale") + ": " + (root.editScale * 100).toFixed(0) + "%"
      description: pluginApi?.tr("settings.uiScaleDesc")
    }
    NSlider {
      Layout.fillWidth: true
      from: 0.5
      to: 2.0
      stepSize: 0.01
      value: root.editScale
      onValueChanged: root.editScale = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // Provider configurations
  readonly property var providers: ({
      [Constants.Providers.GOOGLE]: {
        "name": "Google Gemini",
        "defaultModel": "gemini-2.5-flash",
        "requiresKey": true,
        "keyUrl": "https://aistudio.google.com/app/apikey"
      },
      [Constants.Providers.OPENAI_COMPATIBLE]: {
        "name": "OpenAI Compatible",
        // Default to GPT-4o-mini but this is purely a placeholder as it depends on the actual backend
        "defaultModel": "gpt-4o-mini",
        // requiresKey is dynamic based on "Local" toggle, handled in logic below
        "requiresKey": true,
        "keyUrl": ""
      }
    })

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("AssistantPanel", "Settings UI loaded");
  }

  // ==================
  // AI Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.aiSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: Color.mOnSurface
  }

  // Provider selection
  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.provider")
    description: pluginApi?.tr("settings.providerDesc")
    model: [
      {
        "key": Constants.Providers.GOOGLE,
        "name": "Google Gemini"
      },
      {
        "key": Constants.Providers.OPENAI_COMPATIBLE,
        "name": "OpenAI Compatible"
      }
    ]
    currentKey: root.editProvider
    onSelected: function (key) {
      root.editProvider = key;
    }
    defaultValue: Constants.Providers.GOOGLE
  }

  // OpenAI Compatible Extras
  ColumnLayout {
    Layout.fillWidth: true
    visible: root.editProvider === Constants.Providers.OPENAI_COMPATIBLE
    spacing: Style.marginS

    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.local")
      description: pluginApi?.tr("settings.localDesc")
      checked: root.editOpenAiLocal
      onToggled: function (checked) {
        root.editOpenAiLocal = checked;
      }
      defaultValue: false
    }

    NTextInput {
      Layout.fillWidth: true
      visible: true
      label: pluginApi?.tr("settings.baseUrl")
      description: pluginApi?.tr("settings.baseUrlDesc")
      text: root.editOpenAiBaseUrl
      placeholderText: "https://api.openai.com/v1/chat/completions"
      onTextChanged: root.editOpenAiBaseUrl = text
    }

    // Note about Base URL and response API
    NText {
      Layout.fillWidth: true
      visible: true
      text: pluginApi?.tr("settings.baseUrlNote") + "https://platform.openai.com/docs/api-reference/chat/create" + pluginApi?.tr("settings.moreInfo")
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeXS
      wrapMode: Text.Wrap
      onLinkActivated: link => Qt.openUrlExternally(link)
    }
  }

  // Model selection
  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.model")
    description: pluginApi?.tr("settings.modelDesc")
    text: root.editModel
    onTextChanged: {
      var modelText = (text || "").trim();
      var defaultModel = providers[root.editProvider]?.defaultModel || "";
      // Only save custom values, not empty or default
      if (modelText !== "" && modelText !== defaultModel) {
        root.editModels = Object.assign({}, root.editModels, {
          [root.editProvider]: modelText
        });
      } else {
        // Clear the entry so it falls back to default
        var updated = Object.assign({}, root.editModels);
        delete updated[root.editProvider];
        root.editModels = updated;
      }
    }
    placeholderText: providers[root.editProvider]?.defaultModel || ""
  }

  // API Key input (hidden for Ollama/Local)
  NTextInput {
    Layout.fillWidth: true
    visible: {
      if (root.editProvider === Constants.Providers.OPENAI_COMPATIBLE && root.editOpenAiLocal)
        return false;
      return providers[root.editProvider]?.requiresKey ?? true;
    }
    label: pluginApi?.tr("settings.apiKey")
    description: {
      if (root.apiKeyManagedByEnv) {
        return pluginApi?.tr("settings.apiKeyManagedByEnv");
      }
      var provider = providers[root.editProvider];
      if (provider && provider.keyUrl) {
        return (pluginApi?.tr("settings.apiKeyDesc")) + ": " + provider.keyUrl;
      }
      return "";
    }
    placeholderText: root.apiKeyManagedByEnv ? pluginApi?.tr("settings.apiKeyEnvPlaceholder") : pluginApi?.tr("settings.apiKeyPlaceholder")
    text: root.apiKeyManagedByEnv ? "" : root.editApiKey
    enabled: !root.apiKeyManagedByEnv
    inputMethodHints: Qt.ImhHiddenText
    onTextChanged: {
      if (!root.apiKeyManagedByEnv) {
        root.editApiKeys = Object.assign({}, root.editApiKeys, {
          [root.editProvider]: text
        });
      }
    }
  }

  // Temperature slider
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.temperature") + ": " + root.editTemperature.toFixed(1)
      description: pluginApi?.tr("settings.temperatureDesc")
    }

    NSlider {
      Layout.fillWidth: true
      from: 0
      to: 2
      stepSize: 0.1
      value: root.editTemperature
      onValueChanged: root.editTemperature = value
    }
  }

  // System prompt
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.systemPrompt")
      description: pluginApi?.tr("settings.systemPromptDesc")
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 80
      color: Color.mSurface
      radius: Style.radiusS
      border.color: Color.mOutline
      border.width: 1

      TextArea {
        anchors.fill: parent
        anchors.margins: Style.marginS
        text: root.editSystemPrompt
        placeholderText: pluginApi?.tr("settings.systemPromptPlaceholder")
        placeholderTextColor: Color.mOnSurfaceVariant
        color: Color.mOnSurface
        font.pointSize: Style.fontSizeS
        wrapMode: TextArea.Wrap
        background: null
        onTextChanged: root.editSystemPrompt = text
      }
    }
  }

  // Max history length
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: (pluginApi?.tr("settings.maxHistory")) + ": " + root.editMaxHistoryLength
      description: pluginApi?.tr("settings.maxHistoryDesc")
    }

    NSlider {
      Layout.fillWidth: true
      from: 10
      to: 500
      stepSize: 10
      value: root.editMaxHistoryLength
      onValueChanged: root.editMaxHistoryLength = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ==================
  // Translator Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.translatorSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: Color.mOnSurface
  }

  // Translator backend
  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.translatorBackend")
    description: pluginApi?.tr("settings.translatorBackendDesc")
    model: [
      {
        "key": "google",
        "name": "Google Translate"
      },
      {
        "key": "deepl",
        "name": "DeepL"
      }
    ]
    currentKey: root.editTranslatorBackend
    onSelected: function (key) {
      root.editTranslatorBackend = key;
    }
    defaultValue: "google"
  }

  // DeepL API key (only for DeepL)
  NTextInput {
    Layout.fillWidth: true
    visible: root.editTranslatorBackend === "deepl"
    label: pluginApi?.tr("settings.deeplApiKey")
    description: root.deeplApiKeyManagedByEnv ? (pluginApi?.tr("settings.apiKeyManagedByEnv")) : (pluginApi?.tr("settings.deeplApiKeyDesc"))
    placeholderText: root.deeplApiKeyManagedByEnv ? (pluginApi?.tr("settings.apiKeyEnvPlaceholder")) : (pluginApi?.tr("settings.apiKeyPlaceholder"))
    text: root.deeplApiKeyManagedByEnv ? "" : root.editDeeplApiKey
    enabled: !root.deeplApiKeyManagedByEnv
    inputMethodHints: Qt.ImhHiddenText
    onTextChanged: {
      if (!root.deeplApiKeyManagedByEnv) {
        root.editDeeplApiKey = text;
      }
    }
  }

  // Real-time translation toggle
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.realTimeTranslation")
    description: pluginApi?.tr("settings.realTimeTranslationDesc")
    checked: root.editRealTimeTranslation
    onToggled: function (checked) {
      root.editRealTimeTranslation = checked;
    }
    defaultValue: true
  }

  // Save function called by the settings dialog
  function saveSettings() {
    // Sync model for current provider before saving
    var modelInput = root.children.find(child => child && child.label === (pluginApi?.tr("settings.model")));
    if (modelInput && modelInput.text !== undefined) {
      var modelText = (modelInput.text || "").trim();
      var defaultModel = providers[root.editProvider]?.defaultModel || "";
      // Only save if non-empty and different from provider's default
      if (modelText !== "" && modelText !== defaultModel) {
        root.editModels = Object.assign({}, root.editModels, {
          [root.editProvider]: modelText
        });
      } else {
        // Clear the entry to use default
        var updated = Object.assign({}, root.editModels);
        delete updated[root.editProvider];
        root.editModels = updated;
      }
    }
    // Sync API key for current provider
    var apiKeyInput = root.children.find(child => child && child.label === (pluginApi?.tr("settings.apiKey")));
    if (apiKeyInput && apiKeyInput.text !== undefined && !root.apiKeyManagedByEnv) {
      root.editApiKeys = Object.assign({}, root.editApiKeys, {
        [root.editProvider]: apiKeyInput.text
      });
    }
    if (!pluginApi) {
      Logger.e("AssistantPanel", "Cannot save settings: pluginApi is null");
      return;
    }

    // Initialize nested objects if needed
    if (!pluginApi.pluginSettings.ai) {
      pluginApi.pluginSettings.ai = {};
    }
    if (!pluginApi.pluginSettings.translator) {
      pluginApi.pluginSettings.translator = {};
    }

    // Save AI settings
    pluginApi.pluginSettings.ai.provider = root.editProvider;
    pluginApi.pluginSettings.ai.models = root.editModels;
    pluginApi.pluginSettings.ai.apiKeys = root.editApiKeys;
    pluginApi.pluginSettings.ai.temperature = root.editTemperature;
    pluginApi.pluginSettings.ai.systemPrompt = root.editSystemPrompt;

    // Save OpenAI Compatible specific settings
    pluginApi.pluginSettings.ai.openaiLocal = root.editOpenAiLocal;
    pluginApi.pluginSettings.ai.openaiBaseUrl = root.editOpenAiBaseUrl;
    // Also store legacy single-model value for compatibility
    try {
      pluginApi.pluginSettings.ai.model = root.editModels[root.editProvider] || pluginApi.pluginSettings.ai.model || "";
    } catch (e) {
      pluginApi.pluginSettings.ai.model = pluginApi.pluginSettings.ai.model || "";
    }

    // Save translator settings
    pluginApi.pluginSettings.translator.backend = root.editTranslatorBackend;
    pluginApi.pluginSettings.translator.deeplApiKey = root.editDeeplApiKey;
    pluginApi.pluginSettings.translator.realTimeTranslation = root.editRealTimeTranslation;

    // Save general settings
    pluginApi.pluginSettings.maxHistoryLength = root.editMaxHistoryLength;

    // Save panel settings
    pluginApi.pluginSettings.panelDetached = root.editPanelDetached;
    pluginApi.pluginSettings.panelPosition = root.editPanelPosition;
    pluginApi.pluginSettings.panelHeightRatio = root.editPanelHeightRatio;
    pluginApi.pluginSettings.panelWidth = root.editPanelWidth;
    pluginApi.pluginSettings.attachmentStyle = root.editAttachmentStyle;
    pluginApi.pluginSettings.scale = root.editScale;

    pluginApi.saveSettings();

    Logger.i("AssistantPanel", "Settings saved successfully");
  }
}
