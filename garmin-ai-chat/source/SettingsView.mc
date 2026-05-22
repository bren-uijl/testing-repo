using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class SettingsItem {
    var label;
    var value;
    var action;

    function initialize(label, value, action) {
        self.label = label;
        self.value = value;
        self.action = action;
    }
}

class SettingsView extends WatchUi.View {

    var storage;
    var selectedIdx;
    var items;
    var scrollOffset;
    var itemHeight;
    var headerHeight;
    var viewWidth;
    var viewHeight;

    function initialize() {
        View.initialize();
        storage = null;
        selectedIdx = -1;
        items = [];
        scrollOffset = 0;
        itemHeight = 50;
        headerHeight = 45;
    }

    function onLayout(dc) {
        storage = Application.getApp().getPropertyStore();
        buildItems();
        viewWidth = dc.getWidth();
        viewHeight = dc.getHeight();
    }

    function onShow() {
        if (storage == null) {
            storage = Application.getApp().getPropertyStore();
        }
        buildItems();
        WatchUi.requestUpdate();
    }

    function buildItems() {
        items = [];

        var apiKey = storage.getApiKey();
        var keyStatus = "Not set";
        if (apiKey != null && apiKey.length() > 0) {
            var masked = apiKey.substring(0, 4) + "..." + apiKey.substring(apiKey.length() - 4);
            keyStatus = masked;
        }
        items.add(new SettingsItem("API Key", keyStatus, "apiKey"));

        items.add(new SettingsItem("Model", getModelDisplayName(storage.getModel()), "model"));

        var prompt = storage.getSystemPrompt();
        var promptPreview = prompt;
        if (promptPreview != null && promptPreview.length() > 25) {
            promptPreview = promptPreview.substring(0, 22) + "...";
        }
        items.add(new SettingsItem("System Prompt", promptPreview != null ? promptPreview : "Default", "systemPrompt"));

        items.add(new SettingsItem("Clear All Chats", "", "clear"));

        items.add(new SettingsItem("About", "v1.2.0", "about"));
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.Settings), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 35, width, 35);

        var listTop = headerHeight;
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var ci = 0; ci < items.size(); ci++) {
            var item = items[ci];
            if (ci < scrollOffset) { continue; }
            if (ci >= scrollOffset + maxVisible + 1) break;

            var y = listTop + (ci - scrollOffset) * itemHeight;

            if (ci == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 12, Graphics.FONT_MEDIUM, item.label, Graphics.TEXT_JUSTIFY_LEFT);

            var value = item.value;
            if (value != null && value.length() > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                var displayValue = value;
                if (displayValue.length() > 20) {
                    displayValue = displayValue.substring(0, 17) + "...";
                }
                dc.drawText(width - 15, y + 12, Graphics.FONT_MEDIUM, displayValue, Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (ci < items.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + itemHeight - 4, width - 10, y + itemHeight - 4);
            }
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var coords = evt.getCoordinates();
        var x = 0;
        var y = 0;
        var isFirst = true;
        for (var ci = 0; ci < coords.size(); ci++) {
            var c = coords[ci];
            if (isFirst) { x = c; isFirst = false; }
            else { y = c; }
        }

        var listTop = headerHeight;
        if (y >= listTop) {
            var idx = scrollOffset + (y - listTop) / itemHeight;
            if (idx >= 0 && idx < items.size()) {
                handleItemSelect(idx);
            }
        }
    }

    function handleItemSelect(idx) {
        var action = "";
        for (var ci = 0; ci < items.size(); ci++) {
            var item = items[ci];
            if (ci == idx) {
                action = item.action;
                break;
            }
        }

        if (action == "apiKey") {
            Application.getApp().showApiKeyInput();
        } else if (action == "model") {
            cycleModel();
        } else if (action == "systemPrompt") {
            resetSystemPrompt();
        } else if (action == "clear") {
            clearAllConversations();
        } else if (action == "about") {
            Application.getApp().showAbout();
        }
    }

    function resetSystemPrompt() {
        storage.setSystemPrompt("You are a helpful assistant on a Garmin watch. Keep responses concise and under 200 characters.");
        buildItems();
        WatchUi.requestUpdate();
    }

    function cycleModel() {
        var models = [
            "nvidia/nemotron-nano-9b-v2",
            "meta/llama-3.1-8b-instruct",
            "meta/llama-3.1-70b-instruct",
            "mistralai/mistral-7b-instruct-v0.2",
            "google/gemma-2-9b-it",
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b",
            "mistralai/mistral-medium-3.5-128b"
        ];

        var current = storage.getModel();
        var nextIdx = 0;
        for (var mi = 0; mi < models.size(); mi++) {
            var m = models[mi];
            if (m == current) {
                nextIdx = (mi + 1) % models.size();
                break;
            }
        }

        var nextModel = "";
        for (var nmi = 0; nmi < models.size(); nmi++) {
            var m = models[nmi];
            if (nmi == nextIdx) { nextModel = m; break; }
        }
        storage.setModel(nextModel);
        buildItems();
        WatchUi.requestUpdate();
    }

    function clearAllConversations() {
        storage.clearAllConversations();
        buildItems();
        WatchUi.requestUpdate();
    }

    function getModelDisplayName(modelId) {
        if (modelId == null) {
            return "Unknown";
        }

        if (modelId.indexOf("nemotron") >= 0) {
            return "Nemotron Nano 9B";
        } else if (modelId.indexOf("llama-3.1-8b") >= 0) {
            return "Llama 3.1 8B";
        } else if (modelId.indexOf("llama-3.1-70b") >= 0) {
            return "Llama 3.1 70B";
        } else if (modelId.indexOf("mistral-7b") >= 0) {
            return "Mistral 7B";
        } else if (modelId.indexOf("gemma-2-9b") >= 0) {
            return "Gemma 2 9B";
        } else if (modelId.indexOf("gpt-oss-120b") >= 0) {
            return "GPT-OSS 120B";
        } else if (modelId.indexOf("gpt-oss-20b") >= 0) {
            return "GPT-OSS 20B";
        } else if (modelId.indexOf("mistral-medium") >= 0) {
            return "Mistral Med 3.5";
        }

        var slashIdx = modelId.indexOf("/");
        if (slashIdx >= 0) {
            return modelId.substring(slashIdx + 1);
        }
        return modelId;
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_UP) {
            if (scrollOffset + (viewHeight - headerHeight - 20) / itemHeight < items.size()) {
                scrollOffset += 1;
                WatchUi.requestUpdate();
            }
        } else if (direction == WatchUi.SWIPE_DOWN) {
            if (scrollOffset > 0) {
                scrollOffset -= 1;
                WatchUi.requestUpdate();
            }
        }
    }
}

class SettingsInputDelegate extends WatchUi.BehaviorDelegate {

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

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
