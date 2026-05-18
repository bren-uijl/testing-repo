using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

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
        model = m;
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
            :body => Json.encode(requestBody)
        };

        try {
            Communications.makeJsonRequest(baseUrl, options, new ApiResponseDelegate(self));
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
                var json = Json.decode(data);
                var choices = json.get(:choices);
                if (choices != null && choices.size() > 0) {
                    var choice = choices.get(0);
                    var message = choice.get(:message);
                    if (message != null) {
                        callback.onComplete(message.get(:content), null);
                        return;
                    }
                }
                callback.onComplete(null, "Invalid response format");
            } catch (e) {
                callback.onComplete(null, "Parse error: " + e.toString());
            }
        } else {
            var errorMsg = "HTTP " + responseCode.toString();
            if (data != null) {
                try {
                    var json = Json.decode(data);
                    var error = json.get(:error);
                    if (error != null) {
                        errorMsg = error.get(:message);
                    }
                } catch (e) {
                }
            }
            callback.onComplete(null, errorMsg);
        }
    }

    function onError(error) {
        if (callback != null) {
            callback.onComplete(null, "Request failed: " + error.toString());
        }
    }
end

class ApiResponseDelegate extends Communications.JsonResponseDelegate

    var client;

    function initialize(apiClient) {
        client = apiClient;
    }

    function onResponse(responseCode, data) {
        client.onResponse(responseCode, data);
    }

    function onError(error) {
        client.onError(error);
    }
end
