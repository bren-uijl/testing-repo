import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;

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
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
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

    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (callback == null) {
            return;
        }

        if (responseCode == 200 && data != null) {
            try {
                if (data instanceof Dictionary) {
                    var choices = data[:choices];
                    if (choices != null && choices.size() > 0) {
                        var choice = choices[0];
                        if (choice != null) {
                            var message = choice[:message];
                            if (message != null) {
                                var content = message[:content];
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
                if (data instanceof Dictionary) {
                    var error = data[:error];
                    if (error != null) {
                        var message = error[:message];
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
