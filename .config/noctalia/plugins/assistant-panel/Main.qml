import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "ProviderLogic.js" as ProviderLogic
import "Constants.js" as Constants

Item {
  // Internal flag to prevent duplicate error messages
  id: root

  property var pluginApi: null
  property string _responseBuffer: ""

  // AI Chat state
  property var messages: []
  property bool isGenerating: false
  property string currentResponse: ""
  property string errorMessage: ""
  property bool isManuallyStopped: false

  // Translation state
  property string translatedText: ""
  property bool isTranslating: false
  property string translationError: ""

  // Cache directory for state (messages, activeTab) - use global noctalia cache
  readonly property string cacheDir: typeof Settings !== 'undefined' && Settings.cacheDir ? Settings.cacheDir + "plugins/assistant-panel/" : ""
  readonly property string stateCachePath: cacheDir + "state.json"

  property string activeTab: "ai"  // UI state - persisted to cache
  property string chatInputText: "" // Chat input state - persisted to cache
  property int chatInputCursorPosition: 0 // Chat input cursor position - persisted to cache

  // Provider configurations
  readonly property var providers: ({
      [Constants.Providers.GOOGLE]: {
        "name": "Google Gemini",
        "defaultModel": "gemini-2.5-flash",
        "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?key={apiKey}",
        "streamEndpoint": "https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse&key={apiKey}"
      },
      [Constants.Providers.OPENAI_COMPATIBLE]: {
        "name": "OpenAI Compatible",
        "defaultModel": "gpt-4o-mini",
        // Endpoint is dynamic based on settings (openaiBaseUrl)
        "endpoint": ""
      }
    })

  // Settings accessors
  readonly property string provider: pluginApi?.pluginSettings?.ai?.provider || Constants.Providers.GOOGLE
  // Prefer per-provider mapping `ai.models[provider]` (if non-empty), fall back to provider default
  readonly property string model: {
    var saved = pluginApi?.pluginSettings?.ai?.models?.[provider];
    if (saved !== undefined && saved !== "")
      return saved;
    return providers[provider]?.defaultModel || "";
  }

  // Environment variable API keys - priority over settings
  readonly property var envApiKeys: ({
      [Constants.Providers.GOOGLE]: Quickshell.env("NOCTALIA_AP_GOOGLE_API_KEY") || "",
      [Constants.Providers.OPENAI_COMPATIBLE]: Quickshell.env("NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY") || ""
    })

  // API Key Priority: Environment Variable > Local Settings
  readonly property string envApiKey: envApiKeys[provider] || ""
  readonly property string settingsApiKey: (pluginApi?.pluginSettings?.ai?.apiKeys && pluginApi.pluginSettings.ai.apiKeys[provider]) || ""
  readonly property string apiKey: envApiKey !== "" ? envApiKey : settingsApiKey
  readonly property bool apiKeyManagedByEnv: envApiKey !== ""

  // DeepL translator env var support
  readonly property string envDeeplApiKey: Quickshell.env("NOCTALIA_AP_DEEPL_API_KEY") || ""
  readonly property real temperature: pluginApi?.pluginSettings?.ai?.temperature || 0.7
  readonly property string systemPrompt: pluginApi?.pluginSettings?.ai?.systemPrompt || ""

  // OpenAI Compatible Settings
  readonly property bool openaiLocal: pluginApi?.pluginSettings?.ai?.openaiLocal ?? false
  readonly property string openaiBaseUrl: {
    var url = pluginApi?.pluginSettings?.ai?.openaiBaseUrl || "";
    if (url === "")
      return "https://api.openai.com/v1/chat/completions";
    return url;
  }

  Component.onCompleted: {
    Logger.i("AssistantPanel", "Plugin initialized");
    // State loading is handled by FileView onLoaded
    ensureCacheDir();
  }

  // Ensure cache directory exists
  function ensureCacheDir() {
    if (cacheDir) {
      Quickshell.execDetached(["mkdir", "-p", cacheDir]);
    }
  }

  // FileView for state cache (messages, activeTab)
  FileView {
    id: stateCacheFile
    path: root.stateCachePath
    watchChanges: false

    onLoaded: {
      loadStateFromCache();
    }

    onLoadFailed: function (error) {
      if (error === 2) {
        // File doesn't exist, start fresh
        Logger.d("AssistantPanel", "No cache file found, starting fresh");
      } else {
        Logger.e("AssistantPanel", "Failed to load state cache: " + error);
      }
    }
  }

  // Load state from cache file
  function loadStateFromCache() {
    var content = stateCacheFile.text();
    var result = ProviderLogic.processLoadedState(content);

    if (!result) {
      Logger.d("AssistantPanel", "Empty cache file, starting fresh");
      return;
    }

    if (result.error) {
      Logger.e("AssistantPanel", "Failed to parse state cache: " + result.error);
      return;
    }

    root.messages = result.messages;
    root.activeTab = result.activeTab;
    root.chatInputText = result.chatInputText;
    root.chatInputCursorPosition = result.chatInputCursorPosition;
    Logger.d("AssistantPanel", "Loaded " + root.messages.length + " messages from cache");
  }

  // Debounced save timer
  Timer {
    id: saveStateTimer
    interval: 500
    onTriggered: performSaveState()
  }

  property bool saveStateQueued: false

  function saveState() {
    saveStateQueued = true;
    saveStateTimer.restart();
  }

  function performSaveState() {
    if (!saveStateQueued || !cacheDir)
      return;
    saveStateQueued = false;

    try {
      ensureCacheDir();

      var maxHistory = pluginApi?.pluginSettings?.maxHistoryLength || 100;
      var dataStr = ProviderLogic.prepareStateForSave(
        root.messages,
        root.activeTab,
        maxHistory,
        root.chatInputText,
        root.chatInputCursorPosition
      );

      stateCacheFile.setText(dataStr);
    } catch (e) {
      Logger.e("AssistantPanel", "Failed to save state cache: " + e);
    }
  }

  // Add a message to the chat
  function addMessage(role, content) {
    var newMessage = {
      "id": Date.now().toString(),
      "role": role,
      "content": content,
      "timestamp": new Date().toISOString()
    };
    root.messages = [...root.messages, newMessage];
    saveState();
    return newMessage;
  }

  // Clear chat history
  function clearMessages() {
    root.messages = [];
    saveState();
    Logger.i("AssistantPanel", "Chat history cleared");
  }

  // Send a message to the AI
  function sendMessage(userMessage) {
    Logger.i("AssistantPanel", "sendMessage called with: " + userMessage);
    if (!userMessage || userMessage.trim() === "") {
      Logger.i("AssistantPanel", "sendMessage: empty message, abort");
      return;
    }
    if (root.isGenerating) {
      Logger.i("AssistantPanel", "sendMessage: already generating, abort");
      return;
    }

    // Check API key for non-local providers
    // For OpenAI Compatible, check apiKey only if NOT local
    var requiresKey = true;
    if (provider === Constants.Providers.OPENAI_COMPATIBLE && openaiLocal) {
      requiresKey = false;
    }

    if (requiresKey && (!apiKey || apiKey.trim() === "")) {
      root.errorMessage = pluginApi?.tr("errors.noApiKey") || "Please configure your API key in settings";
      Logger.e("AssistantPanel", "sendMessage: missing API key");
      ToastService.showError(root.errorMessage);
      return;
    }

    Logger.i("AssistantPanel", "Adding user message and starting generation");
    addMessage("user", userMessage.trim());

    root.isGenerating = true;
    root.isManuallyStopped = false;
    root.currentResponse = "";
    root.errorMessage = "";

    if (provider === Constants.Providers.GOOGLE) {
      Logger.i("AssistantPanel", "Calling sendGeminiRequest()");
      sendGeminiRequest();
    } else if (provider === Constants.Providers.OPENAI_COMPATIBLE) {
      Logger.i("AssistantPanel", "Calling sendOpenAIRequest() for " + provider);
      sendOpenAIRequest();
    } else {
      Logger.e("AssistantPanel", "Unknown provider: " + provider);
      root.errorMessage = "Unknown provider selected. Please check settings.";
      root.isGenerating = false;
    }
  }

  // Edit a message and regenerate from there
  function editMessage(id, newContent) {
    if (root.isGenerating)
      return;
    if (!newContent || newContent.trim() === "")
      return;
    var index = -1;
    for (var i = 0; i < root.messages.length; i++) {
      if (root.messages[i].id === id) {
        index = i;
        break;
      }
    }

    if (index === -1)
      return;

    // Truncate history to this message (exclusive)
    root.messages = root.messages.slice(0, index);

    // Add the updated message as a new user message
    sendMessage(newContent);
  }

  // Regenerate the last assistant response
  function regenerateLastResponse() {
    if (root.isGenerating)
      return;
    if (root.messages.length < 2)
      return;

    // Find and remove the last assistant message
    var lastIndex = -1;
    for (var i = root.messages.length - 1; i >= 0; i--) {
      if (root.messages[i].role === "assistant") {
        lastIndex = i;
        break;
      }
    }

    if (lastIndex >= 0) {
      root.messages = root.messages.slice(0, lastIndex);
      saveState();

      root.isGenerating = true;
      root.currentResponse = "";
      root.errorMessage = "";

      if (provider === Constants.Providers.GOOGLE) {
        sendGeminiRequest();
      } else if (provider === Constants.Providers.OPENAI_COMPATIBLE) {
        sendOpenAIRequest();
      }
    }
  }

  // Stop generation
  function stopGeneration() {
    if (!root.isGenerating)
      return;
    Logger.i("AssistantPanel", "Stopping generation");

    root.isManuallyStopped = true;
    if (geminiProcess.running)
      geminiProcess.running = false;
    if (openaiProcess.running)
      openaiProcess.running = false;

    root.isGenerating = false;
    // If we have a partial response, add it to chat history
    if (root.currentResponse.trim() !== "") {
      root.addMessage("assistant", root.currentResponse.trim());
    }
    root.currentResponse = "";
  }

  // Build conversation history for API
  function buildConversationHistory() {
    var history = [];
    for (var i = 0; i < root.messages.length; i++) {
      var msg = root.messages[i];
      history.push({
        "role": msg.role,
        "content": msg.content
      });
    }
    return history;
  }

  // =====================
  // Google Gemini API
  // =====================
  Process {
    id: geminiProcess

    property string buffer: ""

    stdout: SplitParser {
      onRead: function (data) {
        geminiProcess.handleStreamData(data);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim() !== "") {
          // Try to parse JSON error from stderr if possible
          try {
            var json = JSON.parse(text);
            if (json.error && json.error.message) {
              root.errorMessage = json.error.message;
            } else {
              Logger.e("AssistantPanel", "Gemini stderr: " + text);
            }
          } catch (e) {
            Logger.e("AssistantPanel", "Gemini stderr: " + text);
          }
        }
      }
    }

    function handleStreamData(data) {
      var result = ProviderLogic.parseGeminiStream(data);
      if (!result)
        return;

      if (result.content) {
        root.currentResponse += result.content;
      } else if (result.error) {
        Logger.e("AssistantPanel", "Gemini stream error: " + result.error);
        if (!result.error.startsWith("Error parsing SSE")) {
          root.errorMessage = result.error;
        }
      } else if (result.raw) {
        geminiProcess.buffer += result.raw;
        try {
          var errorJson = JSON.parse(geminiProcess.buffer);
          if (errorJson.error) {
            root.errorMessage = errorJson.error.message || "API error";
          }
          geminiProcess.buffer = "";
        } catch (e) {
          // Incomplete
        }
      }
    }

    onExited: function (exitCode, exitStatus) {
      if (root.isManuallyStopped) {
        root.isManuallyStopped = false;
        return;
      }

      root.isGenerating = false;
      geminiProcess.buffer = "";

      if (exitCode !== 0 && root.currentResponse === "") {
        if (root.errorMessage === "") {
          root.errorMessage = pluginApi?.tr("errors.requestFailed") || "Request failed";
        }
        return;
      }

      if (root.currentResponse.trim() !== "") {
        root.addMessage("assistant", root.currentResponse.trim());
      }
      root.chatInputText = ""; // Ensure input is cleared after successful generation
      root.chatInputCursorPosition = 0;
      root.saveState();
    }
  }

  function sendGeminiRequest() {
    var history = buildConversationHistory();
    var commandData = ProviderLogic.buildGeminiCommand(
      providers[Constants.Providers.GOOGLE].streamEndpoint,
      model, apiKey, systemPrompt, history, temperature
    );

    Logger.i("AssistantPanel", "sendGeminiRequest: endpoint=" + commandData.url);
    geminiProcess.buffer = "";
    geminiProcess.command = commandData.args;
    Logger.i("AssistantPanel", "sendGeminiRequest: starting process");
    _responseBuffer = "";
    geminiProcess.running = true;
  }

  // =====================
  // OpenAI API
  // =====================
  Process {
    id: openaiProcess

    property string buffer: ""

    stdout: SplitParser {
      onRead: function (data) {
        openaiProcess.handleStreamData(data);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim() !== "") {
          Logger.e("AssistantPanel", "OpenAI stderr: " + text);
        } else {
          Logger.i("AssistantPanel", "OpenAI stderr: (empty)");
        }
      }
    }

    function handleStreamData(data) {
      var result = ProviderLogic.parseOpenAIStream(data);
      if (!result)
        return;

      if (result.content) {
        root.currentResponse += result.content;
      } else if (result.error) {
        Logger.e("AssistantPanel", "OpenAI stream error: " + result.error);
      } else if (result.raw) {
        openaiProcess.buffer += result.raw;
        try {
          var errorJson = JSON.parse(openaiProcess.buffer);
          if (errorJson.error) {
            root.errorMessage = errorJson.error.message || "API error";
          }
          openaiProcess.buffer = "";
        } catch (e) {
          // Incomplete JSON, keep buffering
        }
      }
    }

    onExited: function (exitCode, exitStatus) {
      if (root.isManuallyStopped) {
        root.isManuallyStopped = false;
        return;
      }

      root.isGenerating = false;

      if (exitCode !== 0 && root.currentResponse === "") {
        if (root.errorMessage === "") {
          if (provider === Constants.Providers.OPENAI_COMPATIBLE && openaiLocal) {
            root.errorMessage = pluginApi?.tr("errors.localNotRunning") || "Local inference server is not reachable. Please check your configuration and ensure it is running.";
          } else {
            root.errorMessage = pluginApi?.tr("errors.requestFailed") || "Request failed";
          }
        }
        return;
      }

      if (root.currentResponse.trim() !== "") {
        root.addMessage("assistant", root.currentResponse.trim());
      }
      root.chatInputText = ""; // Ensure input is cleared after successful generation
      root.chatInputCursorPosition = 0;
      root.saveState();

      openaiProcess.buffer = "";
    }
  }

  function sendOpenAIRequest() {
    var history = buildConversationHistory();
    var commandData = ProviderLogic.buildOpenAICommand(openaiBaseUrl, apiKey, model, systemPrompt, history, temperature);

    Logger.i("AssistantPanel", "sendOpenAIRequest: endpoint=" + commandData.url);
    openaiProcess.buffer = "";
    openaiProcess.command = commandData.args;

    Logger.i("AssistantPanel", "sendOpenAIRequest: starting process");
    openaiProcess.running = true;
  }

  // =====================
  // Ollama API (Local)
  // =====================
  // Ollama Process removed (consolidated into OpenAI logic)

  // =====================
  // Translation
  // =====================
  readonly property string translatorBackend: pluginApi?.pluginSettings?.translator?.backend || "google"
  readonly property string sourceLanguage: pluginApi?.pluginSettings?.translator?.sourceLanguage || "auto"
  readonly property string targetLanguage: pluginApi?.pluginSettings?.translator?.targetLanguage || "en"
  readonly property string settingsDeeplApiKey: pluginApi?.pluginSettings?.translator?.deeplApiKey || ""
  readonly property string deeplApiKey: envDeeplApiKey !== "" ? envDeeplApiKey : settingsDeeplApiKey
  readonly property bool deeplApiKeyManagedByEnv: envDeeplApiKey !== ""

  function translate(text, targetLang, sourceLang) {
    if (!text || text.trim() === "") {
      root.translatedText = "";
      return;
    }

    root.isTranslating = true;
    root.translationError = "";

    var target = targetLang || targetLanguage;
    var source = sourceLang || sourceLanguage;

    if (translatorBackend === "google") {
      translateGoogle(text.trim(), target, source);
    } else if (translatorBackend === "deepl") {
      translateDeepL(text.trim(), target);
    }
  }

  Process {
    id: translateProcess

    stdout: StdioCollector {
      onStreamFinished: {
        root.isTranslating = false;
        root.handleTranslationResponse(text);
      }
    }

    stderr: StdioCollector {}

    onExited: function (exitCode, exitStatus) {
      if (exitCode !== 0) {
        root.isTranslating = false;
        root.translationError = pluginApi?.tr("errors.translationFailed") || "Translation failed";
      }
    }
  }

  function translateGoogle(text, targetLang, sourceLang) {
    var commandData = ProviderLogic.buildGoogleTranslateCommand(text, targetLang, sourceLang);
    translateProcess.command = commandData.args;
    translateProcess.running = true;
  }

  function translateDeepL(text, targetLang) {
    var commandData = ProviderLogic.buildDeepLTranslateCommand(text, targetLang, deeplApiKey);

    if (commandData.error) {
      root.isTranslating = false;
      root.translationError = pluginApi?.tr("errors.noDeeplKey") || commandData.error;
      return;
    }

    translateProcess.command = commandData.args;
    translateProcess.running = true;
  }

  function handleTranslationResponse(responseText) {
    var result = ProviderLogic.parseTranslateResponse(translatorBackend, responseText);

    if (result.error) {
      // Map known internal error strings to translated ones if needed, otherwise show as is
      if (result.error === "Empty response")
        root.translationError = pluginApi?.tr("errors.emptyResponse") || "Empty response";
      else if (result.error === "Failed to parse response")
        root.translationError = pluginApi?.tr("errors.parseError") || "Failed to parse response";
      else
        root.translationError = result.error;
    } else if (result.text) {
      root.translatedText = result.text;
    }
  }

  // =====================
  // IPC Handlers
  // =====================
  IpcHandler {
    target: "plugin:assistant-panel"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function (screen) {
          pluginApi.togglePanel(screen);
        });
      }
    }

    function open() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function (screen) {
          pluginApi.openPanel(screen);
        });
      }
    }

    function close() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function (screen) {
          pluginApi.closePanel(screen);
        });
      }
    }

    function send(message: string) {
      if (message && message.trim() !== "") {
        root.sendMessage(message);
        ToastService.showNotice(pluginApi?.tr("toast.messageSent") || "Message sent");
      }
    }

    function clear() {
      root.clearMessages();
      ToastService.showNotice(pluginApi?.tr("toast.historyCleared") || "Chat history cleared");
    }

    function translateText(text: string, targetLang: string) {
      if (text && text.trim() !== "") {
        root.translate(text, targetLang || root.targetLanguage);
      }
    }

    function setProvider(providerName: string) {
      if (pluginApi && root.providers[providerName]) {
        pluginApi.pluginSettings.ai.provider = providerName;
        pluginApi.saveSettings();
        ToastService.showNotice((pluginApi?.tr("toast.providerChanged") || "Provider changed to") + " " + root.providers[providerName].name);
      }
    }

    function setModel(modelName: string) {
      if (pluginApi && modelName) {
        // Save both legacy `model` and per-provider `models[provider]` for compatibility
        if (!pluginApi.pluginSettings.ai)
          pluginApi.pluginSettings.ai = {};
        pluginApi.pluginSettings.ai.model = modelName;
        try {
          var existing = pluginApi.pluginSettings.ai.models || {};
          existing[pluginApi.pluginSettings.ai.provider || provider] = modelName;
          pluginApi.pluginSettings.ai.models = existing;
        } catch (e) {
          pluginApi.pluginSettings.ai.models = {};
        }
        pluginApi.saveSettings();
        ToastService.showNotice((pluginApi?.tr("toast.modelChanged") || "Model changed to") + " " + modelName);
      }
    }
  }
}
