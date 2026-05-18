using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;

class AiChatApp extends Application.AppBase

    var propertyStore;

    function initialize() {
        AppBase.initialize();
        propertyStore = null;
    }

    function onStart(state) {
        propertyStore = new PropertyStore();
    }

    function onStop(state) {
        if (propertyStore != null) {
            propertyStore.save();
        }
    }

    function getInitialView() {
        var view = new ConversationListView();
        var delegate = new ConversationListInputDelegate(view);
        return [view, delegate];
    }

    function getPropertyStore() {
        if (propertyStore == null) {
            propertyStore = new PropertyStore();
        }
        return propertyStore;
    }

    function showConversationList() {
        var view = new ConversationListView();
        var delegate = new ConversationListInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function showNewConversation() {
        var view = new MessageInputView(null);
        var delegate = new MessageInputInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function showConversation(convId) {
        var view = new ConversationView(convId);
        var delegate = new ConversationViewInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function showSettings() {
        var view = new SettingsView();
        var delegate = new SettingsInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function showApiKeyInput() {
        var view = new ApiKeyInputView();
        var delegate = new ApiKeyInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }
end
