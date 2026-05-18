using Toybox.Application;
using Toybox.Communications;
using Toybox.System;

class AiChatPhoneApp extends Application.AppBase

    var propertyStore;

    function initialize() {
        AppBase.initialize();
        propertyStore = null;
    }

    function onStart(state) {
        propertyStore = new PhonePropertyStore();
    }

    function onStop(state) {
        if (propertyStore != null) {
            propertyStore.save();
        }
    }

    function getInitialView() {
        return [new PhoneSettingsView(), new PhoneInputDelegate()];
    }

    function getPropertyStore() {
        if (propertyStore == null) {
            propertyStore = new PhonePropertyStore();
        }
        return propertyStore;
    }

    function syncToWatch() {
        if (propertyStore == null) {
            return;
        }

        var data = {
            :apiKey => propertyStore.getApiKey(),
            :model => propertyStore.getModel()
        };

        try {
            Communications.sendToWatchApp(Json.encode(data));
        } catch (e) {
            System.println("Failed to sync to watch: " + e.toString());
        }
    }
end

class PhonePropertyStore

    var store;

    function initialize() {
        store = Application.getApp().getAppProperty("AiChatPhoneStore");
        if (store == null) {
            store = {};
            store.put(:apiKey, "");
            store.put(:model, "nvidia/nemotron-nano-9b-v2");
        }
    }

    function getApiKey() {
        return store.get(:apiKey);
    }

    function setApiKey(key) {
        store.put(:apiKey, key);
        save();
    }

    function getModel() {
        return store.get(:model);
    }

    function setModel(model) {
        store.put(:model, model);
        save();
    }

    function save() {
        Application.getApp().setAppProperty("AiChatPhoneStore", store);
    }
end
