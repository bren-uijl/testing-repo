using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class PropertyStore {

    var store;

    static const MAX_CONVERSATIONS = 20;
    static const MAX_MESSAGES_PER_CONVERSATION = 30;
    static const API_KEY_SEGMENT_COUNT = 10;

    function initialize() {
        store = Application.Storage.getValue("AiChatStore");
        if (store == null) {
            store = {};
            store.put("conversations", []);
            store.put("apiKey", "");
            store.put("apiKeyParts", []);
            store.put("model", "nvidia/nemotron-nano-9b-v2");
            store.put("lastConversationId", null);
            store.put("systemPrompt", "You are a helpful assistant on a Garmin watch. Keep responses concise and under 200 characters.");
        }
    }

    function getApiKey() {
        return store["apiKey"];
    }

    function setApiKey(key) {
        store.put("apiKey", key);
        save();
    }

    function getApiKeyParts() {
        var parts = store["apiKeyParts"];
        if (parts == null || parts.size() == 0) {
            parts = [];
            for (var i = 0; i < API_KEY_SEGMENT_COUNT; i++) {
                parts.add("");
            }
            store.put("apiKeyParts", parts);
        }
        return parts;
    }

    function setApiKeyParts(parts) {
        store.put("apiKeyParts", parts);
        rebuildApiKey(parts);
        save();
    }

    function setApiKeyPart(index, value) {
        if (index < 0 || index >= API_KEY_SEGMENT_COUNT) {
            System.println("Invalid API key part index: " + index.toString());
            return;
        }
        var parts = [];
        var keyPartsArray = getApiKeyParts();
        for (var pi = 0; pi < keyPartsArray.size(); pi++) {
            parts.add(pi == index ? value : keyPartsArray[pi]);
        }
        store.put("apiKeyParts", parts);
        rebuildApiKey(parts);
        save();
    }

    function rebuildApiKey(parts) {
        var key = "";
        for (var pi = 0; pi < parts.size(); pi++) {
            key = key + parts[pi];
        }
        store.put("apiKey", key);
    }

    function isApiKeySet() {
        var key = getApiKey();
        return key != null && key.length() > 0;
    }

    function getModel() {
        var model = store["model"];
        if (model == null || model.length() == 0) {
            return "nvidia/nemotron-nano-9b-v2";
        }
        return model;
    }

    function setModel(model) {
        store.put("model", model);
        save();
    }

    function getConversationIds() {
        var ids = store["conversations"];
        if (ids == null) {
            return [];
        }
        return ids;
    }

    function getConversation(id) {
        var key = "conv_" + id;
        return store[key];
    }

    function setConversation(id, data) {
        var key = "conv_" + id;
        store.put(key, data);

        var ids = getConversationIds();
        var found = false;
        for (var ei = 0; ei < ids.size(); ei++) {
            var existingId = ids[ei];
            if (existingId == id) {
                found = true;
                break;
            }
        }
        if (!found) {
            if (ids.size() >= MAX_CONVERSATIONS) {
                evictOldestConversation(ids);
            }
            ids.add(id);
        }
        store.put("conversations", ids);
        save();
    }

    function evictOldestConversation(ids) {
        if (ids.size() == 0) {
            return;
        }

        var oldestId = null;
        var oldestTime = System.getTimer();

        for (var ci = 0; ci < ids.size(); ci++) {
            var convId = ids[ci];
            var data = getConversation(convId);
            if (data != null) {
                var updatedAt = data["updatedAt"];
                if (updatedAt != null && updatedAt < oldestTime) {
                    oldestTime = updatedAt;
                    oldestId = convId;
                }
            }
        }

        if (oldestId == null) {
            if (ids.size() > 0) {
                oldestId = ids[0];
            }
        }

        var key = "conv_" + oldestId;
        store.put(key, null);

        var newIds = [];
        for (var ci = 0; ci < ids.size(); ci++) {
            var convId = ids[ci];
            if (convId != oldestId) {
                newIds.add(convId);
            }
        }
        store.put("conversations", newIds);
    }

    function deleteConversation(id) {
        var key = "conv_" + id;
        store.put(key, null);

        var ids = getConversationIds();
        var newIds = [];
        for (var ei = 0; ei < ids.size(); ei++) {
            var existingId = ids[ei];
            if (existingId != id) {
                newIds.add(existingId);
            }
        }
        store.put("conversations", newIds);
        save();
    }

    function clearAllConversations() {
        var ids = getConversationIds();
        for (var ci = 0; ci < ids.size(); ci++) {
            var convId = ids[ci];
            var key = "conv_" + convId;
            store.put(key, null);
        }
        store.put("conversations", []);
        store.put("lastConversationId", null);
        save();
    }

    function getLastConversationId() {
        return store["lastConversationId"];
    }

    function setLastConversationId(id) {
        store.put("lastConversationId", id);
        save();
    }

    function getMaxMessagesPerConversation() {
        return MAX_MESSAGES_PER_CONVERSATION;
    }

    function getSystemPrompt() {
        var prompt = store["systemPrompt"];
        if (prompt == null || prompt.length() == 0) {
            return "You are a helpful assistant.";
        }
        return prompt;
    }

    function setSystemPrompt(prompt) {
        store.put("systemPrompt", prompt);
        save();
    }

    function save() {
        Application.Storage.setValue("AiChatStore", store);
    }
}
