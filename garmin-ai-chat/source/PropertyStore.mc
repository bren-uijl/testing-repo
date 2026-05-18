using Toybox.Application;
using Toybox.Lang;

class PropertyStore

    var store;

    function initialize() {
        store = Application.getApp().getAppProperty("AiChatStore");
        if (store == null) {
            store = {};
            store.put(:conversations, []);
            store.put(:apiKey, "");
            store.put(:apiKeyParts, []);
            store.put(:model, "nvidia/nemotron-nano-9b-v2");
            store.put(:lastConversationId, null);
        }
    }

    function getApiKey() {
        return store.get(:apiKey);
    }

    function setApiKey(key) {
        store.put(:apiKey, key);
        save();
    }

    function getApiKeyParts() {
        var parts = store.get(:apiKeyParts);
        if (parts == null || parts.size() == 0) {
            parts = [];
            for (var i = 0; i < 10; i++) {
                parts.add("");
            }
            store.put(:apiKeyParts, parts);
        }
        return parts;
    }

    function setApiKeyParts(parts) {
        store.put(:apiKeyParts, parts);
        rebuildApiKey(parts);
        save();
    }

    function setApiKeyPart(index, value) {
        var parts = getApiKeyParts();
        parts.set(index, value);
        store.put(:apiKeyParts, parts);
        rebuildApiKey(parts);
        save();
    }

    function rebuildApiKey(parts) {
        var key = "";
        for (var i = 0; i < parts.size(); i++) {
            key = key + parts.get(i);
        }
        store.put(:apiKey, key);
    }

    function isApiKeySet() {
        var key = getApiKey();
        return key != null && key.length() > 0;
    }

    function getModel() {
        var model = store.get(:model);
        if (model == null || model.length() == 0) {
            return "nvidia/nemotron-nano-9b-v2";
        }
        return model;
    }

    function setModel(model) {
        store.put(:model, model);
        save();
    }

    function getConversationIds() {
        var ids = store.get(:conversations);
        if (ids == null) {
            return [];
        }
        return ids;
    }

    function getConversation(id) {
        var key = "conv_" + id;
        return store.get(key);
    }

    function setConversation(id, data) {
        var key = "conv_" + id;
        store.put(key, data);

        var ids = getConversationIds();
        var found = false;
        for (var i = 0; i < ids.size(); i++) {
            if (ids.get(i) == id) {
                found = true;
                break;
            }
        }
        if (!found) {
            ids.add(id);
        }
        store.put(:conversations, ids);
        save();
    }

    function deleteConversation(id) {
        var key = "conv_" + id;
        store.put(key, null);

        var ids = getConversationIds();
        var newIds = [];
        for (var i = 0; i < ids.size(); i++) {
            if (ids.get(i) != id) {
                newIds.add(ids.get(i));
            }
        }
        store.put(:conversations, newIds);
        save();
    }

    function clearAllConversations() {
        var ids = getConversationIds();
        for (var i = 0; i < ids.size(); i++) {
            var key = "conv_" + ids.get(i);
            store.put(key, null);
        }
        store.put(:conversations, []);
        store.put(:lastConversationId, null);
        save();
    }

    function getLastConversationId() {
        return store.get(:lastConversationId);
    }

    function setLastConversationId(id) {
        store.put(:lastConversationId, id);
        save();
    }

    function save() {
        Application.getApp().setAppProperty("AiChatStore", store);
    }
end
