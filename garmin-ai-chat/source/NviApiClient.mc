using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;
using Toybox.Json;

class NviApiClient

    var baseUrl;
    var apiKey;
    var model;
    var callback;

    function initialize() {
        baseUrl = "https://integrate.api.nvidia.com/v1/chat/completions";
        apiKey = null;
        model = "nvidia/nemotron-nano-9b-v2";
        callback = null;
    }

    function setApiKey(key) {
        apiKey = key;
    }

    function setModel(m) {
        if (m != null && m.length() > 0) {
            model = m;
        }
    }

    function setCallback(cb) {
        callback = cb;
    }

    function sendMessage(messages, cb) {
        callback = cb;

        if (apiKey == null || apiKey.length() == 0) {
            if (callback != null) {
                callback.onComplete(null, "No API key set");
            }
            return;
        }

        if (messages == null || messages.size() == 0) {
            if (callback != null) {
                callback.onComplete(null, "No messages to send");
            }
            return;
        }

        var requestBody = {
            :model => model,
            :messages => messages,
            :max_tokens => 1024,
            :temperature => 0.7,
            :stream => false
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => "application/json",
                "Authorization" => "Bearer " + apiKey
            },
            :body => Json.encode(requestBody),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_STRING
        };

        try {
            Communications.makeWebRequest(baseUrl, options, new ApiResponseDelegate(self));
        } catch (e) {
            if (callback != null) {
                callback.onComplete(null, "Network error: " + e.toString());
            }
        }
    }

    function onResponse(responseCode, data) {
        if (callback == null) {
            return;
        }

        if (responseCode == 200 && data != null) {
            try {
                var jsonData = parseDataToString(data);
                if (jsonData == null || jsonData.length() == 0) {
                    callback.onComplete(null, "Empty response");
                    return;
                }

                var json = Json.decode(jsonData);
                var choices = json.get(:choices);
                if (choices != null && choices.size() > 0) {
                    var choice = choices.get(0);
                    if (choice != null) {
                        var message = choice.get(:message);
                        if (message != null) {
                            var content = message.get(:content);
                            if (content != null && content.length() > 0) {
                                callback.onComplete(content, null);
                                return;
                            }
                        }
                    }
                }
                callback.onComplete(null, "Invalid response format");
            } catch (e) {
                callback.onComplete(null, "Parse error: " + e.toString());
            }
        } else {
            var errorMsg = getErrorMessage(responseCode, data);
            callback.onComplete(null, errorMsg);
        }
    }

    function getErrorMessage(responseCode, data) {
        var baseMsg = "HTTP " + responseCode.toString();

        if (responseCode == 401) {
            baseMsg = "Invalid API key";
        } else if (responseCode == 403) {
            baseMsg = "Access denied";
        } else if (responseCode == 429) {
            baseMsg = "Rate limited, try later";
        } else if (responseCode == 500) {
            baseMsg = "Server error";
        } else if (responseCode == 503) {
            baseMsg = "Service unavailable";
        }

        if (data != null) {
            try {
                var jsonData = parseDataToString(data);
                if (jsonData != null && jsonData.length() > 0) {
                    var json = Json.decode(jsonData);
                    var error = json.get(:error);
                    if (error != null) {
                        var message = error.get(:message);
                        if (message != null && message.length() > 0) {
                            if (message.length() > 50) {
                                message = message.substring(0, 47) + "...";
                            }
                            return message;
                        }
                    }
                }
            } catch (e) {
            }
        }

        return baseMsg;
    }

    function onError(error) {
        if (callback != null) {
            var errorMsg = "Request failed";
            if (error != null) {
                errorMsg = errorMsg + ": " + error.toString();
            }
            callback.onComplete(null, errorMsg);
        }
    }

    function parseDataToString(data) {
        if (data == null) {
            return null;
        }
        if (data instanceof Lang.String) {
            return data;
        }
        if (data instanceof Blob) {
            return data.toString();
        }
        return data.toString();
    }
end

class ApiResponseDelegate extends Communications.WebResponseDelegate

    var client;

    function initialize(apiClient) {
        WebResponseDelegate.initialize();
        client = apiClient;
    }

    function onResponse(responseCode, data) {
        client.onResponse(responseCode, data);
    }

    function onError(error) {
        client.onError(error);
    }
end
