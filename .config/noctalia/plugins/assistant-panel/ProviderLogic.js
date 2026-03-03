.pragma library

// ===================================
// AI Provider Logic
// ===================================

function buildGeminiCommand(endpointUrl, model, apiKey, systemPrompt, history, temperature) {
  var contents = [];

  // Add system prompt as first user message if provided
  if (systemPrompt && systemPrompt.trim() !== "") {
    contents.push({
      "role": "user",
      "parts": [
        {
          "text": "System instruction: " + systemPrompt
        }
      ]
    });
    contents.push({
      "role": "model",
      "parts": [
        {
          "text": "Understood. I will follow these instructions."
        }
      ]
    });
  }

  // Add conversation history
  for (var i = 0; i < history.length; i++) {
    contents.push({
      "role": history[i].role === "assistant" ? "model" : "user",
      "parts": [
        {
          "text": history[i].content
        }
      ]
    });
  }

  var payload = {
    "contents": contents,
    "generationConfig": {
      "temperature": temperature
    }
  };

  var finalUrl = endpointUrl.replace("{model}", model).replace("{apiKey}", apiKey);

  return {
    "url": finalUrl,
    "payload": JSON.stringify(payload),
    "args": ["curl", "-s", "--no-buffer", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify(payload), finalUrl]
  };
}

function parseGeminiStream(data) {
  if (!data)
    return null;
  var line = data.trim();
  if (line === "")
    return null;

  // Standard SSE Stream
  if (line.startsWith("data: ")) {
    var jsonStr = line.substring(6).trim();
    if (jsonStr === "[DONE]")
      return {
        done: true
      };

    try {
      var json = JSON.parse(jsonStr);
      if (json.candidates && json.candidates[0] && json.candidates[0].content) {
        var parts = json.candidates[0].content.parts;
        if (parts && parts[0] && parts[0].text) {
          return {
            content: parts[0].text
          };
        }
      }
    } catch (e) {
      return {
        error: "Error parsing SSE: " + e
      };
    }
  } else
  // Possible raw JSON error
  {
    // Return raw line to be buffered by caller if needed,
    // or try to parse if it looks like a complete JSON object
    if (line.startsWith("{") && line.endsWith("}")) {
      try {
        var json = JSON.parse(line);
        if (json.error) {
          return {
            error: json.error.message || "API error"
          };
        }
      } catch (e) {}
    }
    return {
      raw: line
    };
  }
  return null;
}

function buildOpenAICommand(endpointUrl, apiKey, model, systemPrompt, history, temperature) {
  var messages = [];

  if (systemPrompt && systemPrompt.trim() !== "") {
    messages.push({
      "role": "system",
      "content": systemPrompt
    });
  }

  // Add conversation history
  for (var i = 0; i < history.length; i++) {
    messages.push(history[i]);
  }

  var payload = {
    "model": model,
    "messages": messages,
    "temperature": temperature,
    "stream": true
  };

  var args = ["curl", "-s", "-S", "--no-buffer", "-X", "POST", "-H", "Content-Type: application/json"];

  if (apiKey && apiKey.trim() !== "") {
    args.push("-H", "Authorization: Bearer " + apiKey);
  }

  args.push("-d", JSON.stringify(payload));
  args.push(endpointUrl);

  return {
    "url": endpointUrl,
    "payload": JSON.stringify(payload),
    "args": args
  };
}

function parseOpenAIStream(data) {
  if (!data)
    return null;
  var line = data.trim();
  if (line === "")
    return null;

  if (line.startsWith("data: ")) {
    var jsonStr = line.substring(6).trim();
    if (jsonStr === "[DONE]")
      return {
        done: true
      };

    try {
      var json = JSON.parse(jsonStr);
      if (json.choices && json.choices[0]) {
        if (json.choices[0].delta && json.choices[0].delta.content) {
          return {
            content: json.choices[0].delta.content
          };
        } else if (json.choices[0].message && json.choices[0].message.content) {
          return {
            content: json.choices[0].message.content
          };
        }
      }
    } catch (e) {
      return {
        error: "Error parsing SSE JSON: " + e
      };
    }
  } else {
    return {
      raw: line
    };
  }
  return null;
}

// ===================================
// Translation Logic
// ===================================

function buildGoogleTranslateCommand(text, targetLang, sourceLang) {
  var url = "https://translate.google.com/translate_a/single?client=gtx" + "&sl=" + encodeURIComponent(sourceLang || "auto") + "&tl=" + encodeURIComponent(targetLang) + "&dt=t&q=" + encodeURIComponent(text);

  return {
    "args": ["curl", "-s", url]
  };
}

function buildDeepLTranslateCommand(text, targetLang, apiKey) {
  if (!apiKey || apiKey.trim() === "") {
    return {
      error: "Please configure your DeepL API key"
    };
  }

  var host = apiKey.endsWith(":fx") ? "api-free.deepl.com" : "api.deepl.com";
  var url = "https://" + host + "/v2/translate";

  return {
    "args": ["curl", "-s", "-X", "POST", url, "-H", "Authorization: DeepL-Auth-Key " + apiKey, "-H", "Content-Type: application/x-www-form-urlencoded", "-d", "text=" + encodeURIComponent(text) + "&target_lang=" + targetLang.toUpperCase()]
  };
}

function parseTranslateResponse(backend, responseText) {
  if (!responseText || responseText.trim() === "") {
    return {
      error: "Empty response"
    };
  }

  try {
    if (backend === "google") {
      var response = JSON.parse(responseText);
      var result = "";
      if (response && response[0]) {
        for (var i = 0; i < response[0].length; i++) {
          if (response[0][i] && response[0][i][0]) {
            result += response[0][i][0];
          }
        }
      }
      return {
        text: result
      };
    } else if (backend === "deepl") {
      var deeplResponse = JSON.parse(responseText);
      if (deeplResponse.translations && deeplResponse.translations[0]) {
        return {
          text: deeplResponse.translations[0].text
        };
      } else if (deeplResponse.message) {
        return {
          error: deeplResponse.message
        };
      }
    }
  } catch (e) {
    return {
      error: "Failed to parse response"
    };
  }
  return {
    error: "Unknown backend or format"
  };
}

// ===================================
// State Management
// ===================================

function processLoadedState(content) {
  if (!content || content.trim() === "") {
    return null; // Empty state
  }
  try {
    var cached = JSON.parse(content);
    return {
      messages: cached.messages || [],
      activeTab: cached.activeTab || "ai",
      chatInputText: cached.chatInputText || "",
      chatInputCursorPosition: cached.chatInputCursorPosition || 0
    };
  } catch (e) {
    return {
      error: e.toString()
    };
  }
}

function prepareStateForSave(messages, activeTab, maxHistory, chatInputText, chatInputCursorPosition) {
  var maxLog = maxHistory || 100;
  var toSave = messages.slice(-maxLog);

  return JSON.stringify({
    messages: toSave,
    activeTab: activeTab,
    chatInputText: chatInputText || "",
    chatInputCursorPosition: chatInputCursorPosition || 0,
    timestamp: Math.floor(Date.now() / 1000)
  }, null, 2);
}
