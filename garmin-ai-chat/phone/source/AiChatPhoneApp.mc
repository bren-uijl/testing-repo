using Toybox.Application;
using Toybox.Communications;
using Toybox.System;

class AiChatPhoneApp extends Application.AppBase {

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
        var view = new PhoneSettingsView();
        var delegate = new PhoneInputDelegate(view);
        return [view, delegate];
    }

    function getPropertyStore() {
        if (propertyStore == null) {
            propertyStore = new PhonePropertyStore();
        }
        return propertyStore;
    }

    function syncToWatch() {
        System.println("Sync to watch not supported in SDK 9.1.0");
    }
}

class PhonePropertyStore {

    var store;

    function initialize() {
        store = Application.getApp().getProperty("AiChatPhoneStore");
        if (store == null) {
            store = {};
            store.put("apiKey", "");
            store.put("model", "nvidia/nemotron-nano-9b-v2");
        }
    }

    function getApiKey() {
        return store["apiKey"];
    }

    function setApiKey(key) {
        store.put("apiKey", key);
        save();
    }

    function getModel() {
        return store["model"];
    }

    function setModel(model) {
        store.put("model", model);
        save();
    }

    function save() {
        Application.getApp().setProperty("AiChatPhoneStore", store);
    }
}
