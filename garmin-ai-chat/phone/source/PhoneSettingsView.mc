using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;

class PhoneSettingsView extends WatchUi.View {

    var storage;
    var apiKeyInput;
    var modelSelected;
    var statusMessage;
    var models;

    function initialize() {
        View.initialize();
        storage = null;
        apiKeyInput = "";
        modelSelected = 0;
        statusMessage = "";
        models = [
            "nvidia/nemotron-nano-9b-v2",
            "meta/llama-3.1-8b-instruct",
            "meta/llama-3.1-70b-instruct",
            "mistralai/mistral-7b-instruct-v0.2",
            "google/gemma-2-9b-it",
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b",
            "mistralai/mistral-medium-3.5-128b"
        ];
    }

    function onLayout(dc) {
        storage = Application.getApp().getPropertyStore();
        apiKeyInput = storage.getApiKey();
        var currentModel = storage.getModel();
        for (var i = 0; i < models.size(); i++) {
            if (models[i] == currentModel) {
                modelSelected = i;
                break;
            }
        }
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 30, Graphics.FONT_MEDIUM, "AI Chat Settings", Graphics.TEXT_JUSTIFY_CENTER);

        var y = 80;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, y, Graphics.FONT_MEDIUM, "NVIDIA API Key:", Graphics.TEXT_JUSTIFY_LEFT);

        y += 30;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(20, y, width - 40, 40);

        var displayKey = apiKeyInput;
        if (displayKey.length() > 30) {
            displayKey = displayKey.substring(0, 27) + "...";
        }
        if (displayKey.length() == 0) {
            displayKey = "Tap to enter API key";
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(25, y + 20, Graphics.FONT_MEDIUM, displayKey, Graphics.TEXT_JUSTIFY_LEFT);

        y += 60;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, y, Graphics.FONT_MEDIUM, "Model:", Graphics.TEXT_JUSTIFY_LEFT);

        y += 30;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, y, Graphics.FONT_MEDIUM, models[modelSelected], Graphics.TEXT_JUSTIFY_LEFT);

        y += 50;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(20, y, width - 20, y);

        y += 20;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, "Swipe left/right to change model", Graphics.TEXT_JUSTIFY_CENTER);

        var keyLen = apiKeyInput.length();
        var statusColor = keyLen == 70 ? Graphics.COLOR_GREEN : (keyLen > 0 ? Graphics.COLOR_YELLOW : Graphics.COLOR_RED);
        var statusText = "Key: " + keyLen.toString() + "/70 characters";

        y += 40;
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        if (statusMessage.length() > 0) {
            y += 30;
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onTap(evt) {
        var y = evt.getCoordinates()[1];

        if (y >= 110 && y <= 150) {
            if (WatchUi has :TextPicker) {
                WatchUi.pushView(new WatchUi.TextPicker(apiKeyInput), new PhoneTextInputDelegate(self), WatchUi.SLIDE_DOWN);
            }
        }
    }

    function onApiKeyEntered(text) {
        if (text != null && text.length() > 0) {
            apiKeyInput = text;
            storage.setApiKey(text);
            WatchUi.requestUpdate();
        }
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_LEFT) {
            modelSelected = (modelSelected + 1) % models.size();
            storage.setModel(models[modelSelected]);
            WatchUi.requestUpdate();
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            modelSelected = (modelSelected - 1 + models.size()) % models.size();
            storage.setModel(models[modelSelected]);
            WatchUi.requestUpdate();
        }
    }

    function onMenu() {
        statusMessage = "Sync not available";
        WatchUi.requestUpdate();
        return true;
    }
}

class PhoneTextInputDelegate extends WatchUi.TextPickerDelegate {

    var view;

    function initialize(settingsView) {
        TextPickerDelegate.initialize();
        view = settingsView;
    }

    function onTextEntered(text, changed) {
        view.onApiKeyEntered(text);
        return true;
    }

    function onCancel() {
        return true;
    }
}

class PhoneInputDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(settingsView) {
        BehaviorDelegate.initialize();
        view = settingsView;
    }

    function onTap(evt) {
        if (view != null && view has :onTap) {
            view.onTap(evt);
        }
        return true;
    }

    function onSwipe(evt) {
        if (view != null && view has :onSwipe) {
            view.onSwipe(evt);
        }
        return true;
    }

    function onMenu() {
        if (view != null && view has :onMenu) {
            return view.onMenu();
        }
        return false;
    }
}
