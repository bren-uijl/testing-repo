using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class SettingsView extends WatchUi.View

    var storage;
    var selectedIdx;
    var items;
    var scrollOffset;
    var itemHeight;
    var headerHeight;

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
    }

    function buildItems() {
        items = [];

        var apiKey = storage.getApiKey();
        var keyStatus = "Not set";
        if (apiKey != null && apiKey.length() > 0) {
            var masked = apiKey.substring(0, 4) + "..." + apiKey.substring(apiKey.length() - 4);
            keyStatus = masked;
        }
        items.add({
            :label => "API Key",
            :value => keyStatus,
            :action => "apiKey"
        });

        items.add({
            :label => "Model",
            :value => storage.getModel(),
            :action => "model"
        });

        var prompt = storage.getSystemPrompt();
        var promptPreview = prompt;
        if (promptPreview != null && promptPreview.length() > 25) {
            promptPreview = promptPreview.substring(0, 22) + "...";
        }
        items.add({
            :label => "System Prompt",
            :value => promptPreview != null ? promptPreview : "Default",
            :action => "systemPrompt"
        });

        items.add({
            :label => "Clear All Chats",
            :value => "",
            :action => "clear"
        });

        items.add({
            :label => "About",
            :value => "v1.2.0",
            :action => "about"
        });
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_TINY, Rez.Strings.Settings, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 35, width, 35);

        var listTop = headerHeight;
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var i = scrollOffset; i < items.size(); i++) {
            if (i >= scrollOffset + maxVisible + 1) {
                break;
            }

            var item = items.get(i);
            var y = listTop + (i - scrollOffset) * itemHeight;

            if (i == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 12, Graphics.FONT_SMALL, item.get(:label), Graphics.TEXT_JUSTIFY_LEFT);

            var value = item.get(:value);
            if (value != null && value.length() > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                var displayValue = value;
                if (displayValue.length() > 20) {
                    displayValue = displayValue.substring(0, 17) + "...";
                }
                dc.drawText(width - 15, y + 12, Graphics.FONT_TINY, displayValue, Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (i < items.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + itemHeight - 4, width - 10, y + itemHeight - 4);
            }
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var x = evt.getX();
        var y = evt.getY();

        var listTop = headerHeight;
        if (y >= listTop) {
            var idx = scrollOffset + (y - listTop) / itemHeight;
            if (idx >= 0 && idx < items.size()) {
                handleItemSelect(idx);
            }
        }
    }

    function handleItemSelect(idx) {
        var item = items.get(idx);
        var action = item.get(:action);

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
        View.requestUpdate();
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
        for (var i = 0; i < models.size(); i++) {
            if (models.get(i) == current) {
                nextIdx = (i + 1) % models.size();
                break;
            }
        }

        storage.setModel(models.get(nextIdx));
        buildItems();
        View.requestUpdate();
    }

    function clearAllConversations() {
        storage.clearAllConversations();
        buildItems();
        View.requestUpdate();
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_DIRECTION_UP) {
            if (scrollOffset + (getHeight() - headerHeight - 20) / itemHeight < items.size()) {
                scrollOffset += 1;
                View.requestUpdate();
            }
        } else if (direction == WatchUi.SWIPE_DIRECTION_DOWN) {
            if (scrollOffset > 0) {
                scrollOffset -= 1;
                View.requestUpdate();
            }
        }
    }
end

class SettingsInputDelegate extends WatchUi.BehaviorDelegate

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
end
