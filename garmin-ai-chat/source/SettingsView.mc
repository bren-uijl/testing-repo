using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

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

    function buildItems() {
        items = [];

        var apiKey = storage.getApiKey();
        var keyStatus = "Not set";
        if (apiKey != null && apiKey.length() > 0) {
            var masked = apiKey.substring(0, 4) + "..." + apiKey.substring(apiKey.length() - 4);
            keyStatus = masked;
        }
        items.add({
            "label" => "API Key",
            "value" => keyStatus,
            "action" => "apiKey"
        });

        items.add({
            "label" => "Model",
            "value" => getModelDisplayName(storage.getModel()),
            "action" => "model"
        });

        var prompt = storage.getSystemPrompt();
        var promptPreview = prompt;
        if (promptPreview != null && promptPreview.length() > 25) {
            promptPreview = promptPreview.substring(0, 22) + "...";
        }
        items.add({
            "label" => "System Prompt",
            "value" => promptPreview != null ? promptPreview : "Default",
            "action" => "systemPrompt"
        });

        items.add({
            "label" => "Clear All Chats",
            "value" => "",
            "action" => "clear"
        });

        items.add({
            "label" => "About",
            "value" => "v1.2.0",
            "action" => "about"
        });
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_MEDIUM, Rez.Strings.Settings, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 35, width, 35);

        var listTop = headerHeight;
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        var idx = 0;
        var drawn = 0;
        for (var item : items) {
            if (idx < scrollOffset) { idx++; continue; }
            if (drawn > maxVisible) break;

            var y = listTop + drawn * itemHeight;

            if (idx == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 12, Graphics.FONT_MEDIUM, item["label"], Graphics.TEXT_JUSTIFY_LEFT);

            var value = item["value"];
            if (value != null && value.length() > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                var displayValue = value;
                if (displayValue.length() > 20) {
                    displayValue = displayValue.substring(0, 17) + "...";
                }
                dc.drawText(width - 15, y + 12, Graphics.FONT_MEDIUM, displayValue, Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (drawn > 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y - 4, width - 10, y - 4);
            }

            idx++;
            drawn++;
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var coords = evt.getCoordinates();
        var x = coords[0];
        var y = coords[1];

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
        var ci = 0;
        for (var item : items) {
            if (ci == idx) {
                action = item["action"];
                break;
            }
            ci++;
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
        for (var i = 0; i < models.size(); i++) {
            if (models[i] == current) {
                nextIdx = (i + 1) % models.size();
                break;
            }
        }

        storage.setModel(models[nextIdx]);
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
