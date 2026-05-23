using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;
using Toybox.PersistedContent;

class NviApiClient {

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
        if (cb != null) {
            callback = cb;
        }

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
            "model" => model,
            "messages" => messages,
            "max_tokens" => 1024,
            "temperature" => 0.7,
            "stream" => false
        };

        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
        };
        if (apiKey != null && apiKey.length() > 0) {
            headers.put("Authorization", "Bearer " + apiKey);
        }
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        try {
            Communications.makeWebRequest(baseUrl, requestBody, options, method(:onResponse));
        } catch (e) {
            if (callback != null) {
                callback.onComplete(null, "Network error: " + e.toString());
            }
        }
    }

    function onResponse(responseCode as Number, data as Null or Dictionary or String or Iterator) as Void {
        if (callback == null) {
            return;
        }

        if (responseCode == 200 && data != null) {
            try {
                if (data instanceof Dictionary) {
                    var choices = data["choices"];
                    if (choices == null) {
                        choices = safeDictGet(data, "choices");
                    }
                    if (choices != null && choices instanceof Array && choices.size() > 0) {
                        var firstChoice = safeArrayGet(choices, 0);
                        if (firstChoice != null) {
                            var message = firstChoice["message"];
                            if (message == null) {
                                message = safeDictGet(firstChoice, "message");
                            }
                            if (message != null) {
                                var content = message["content"];
                                if (content == null) {
                                    content = safeDictGet(message, "content");
                                }
                                if (content != null && content.length() > 0) {
                                    callback.onComplete(content, null);
                                    return;
                                }
                            }
                        }
                    }
                    callback.onComplete(null, "Invalid response format");
                } else {
                    callback.onComplete(null, "Unexpected response type");
                }
            } catch (e) {
                callback.onComplete(null, "Parse error: " + e.toString());
            }
        } else {
            var errorMsg = getErrorMessage(responseCode, data);
            callback.onComplete(null, errorMsg);
        }
    }

    function safeDictGet(dict, key) {
        if (dict == null || !(dict instanceof Dictionary)) {
            return null;
        }
        try {
            var keys = dict.keys();
            for (var ki = 0; ki < keys.size(); ki++) {
                try {
                    var k = keys[ki];
                    if (k.toString().equals(key.toString())) {
                        return dict[k];
                    }
                } catch (e) {
                }
            }
        } catch (e) {
        }
        return null;
    }

    function safeArrayGet(arr, index) {
        if (arr == null || !(arr instanceof Array)) {
            return null;
        }
        try {
            if (index >= 0 && index < arr.size()) {
                return arr[index];
            }
        } catch (e) {
        }
        return null;
    }

    function getErrorMessage(responseCode as Number, data as Null or Dictionary or String or Iterator) as String {
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
                if (data instanceof Dictionary) {
                    var error = data["error"];
                    if (error == null) {
                        error = safeDictGet(data, "error");
                    }
                    if (error != null) {
                        var message = error["message"];
                        if (message == null) {
                            message = safeDictGet(error, "message");
                        }
                        if (message != null && message.length() > 0) {
                            if (message.length() > 50) {
                                message = message.substring(0, 47) + "...";
                            }
                            return message;
                        }
                    }
                } else if (data instanceof Lang.String) {
                    var strData = data;
                    if (strData.length() > 50) {
                        strData = strData.substring(0, 47) + "...";
                    }
                    return strData;
                }
            } catch (e) {
            }
        }

        return baseMsg;
    }
}
