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
        return [new ConversationListView()];
    }

    function getPropertyStore() {
        if (propertyStore == null) {
            propertyStore = new PropertyStore();
        }
        return propertyStore;
    }

    function showConversationList() {
        WatchUi.popToDrawableView();
        WatchUi.pushView(new ConversationListView(), new ConversationListInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function showNewConversation() {
        var view = new MessageInputView(null);
        WatchUi.pushView(view, new MessageInputInputDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function showConversation(convId) {
        var view = new ConversationView(convId);
        WatchUi.pushView(view, new ConversationViewInputDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function showSettings() {
        WatchUi.pushView(new SettingsView(), new SettingsInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function showApiKeyInput() {
        WatchUi.pushView(new ApiKeyInputView(), new ApiKeyInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
end
