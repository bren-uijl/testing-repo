using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class ApiKeyInputView extends WatchUi.View {

    var storage;
    var keyParts;
    var selectedPart;
    var segmentCount;
    var charsPerSegment;
    var headerHeight;
    var segmentHeight;
    var scrollOffset;

    function initialize() {
        View.initialize();
        storage = null;
        keyParts = [];
        selectedPart = 0;
        segmentCount = 10;
        charsPerSegment = 7;
        headerHeight = 45;
        segmentHeight = 40;
        scrollOffset = 0;
    }

    function onLayout(dc) {
        storage = Application.getApp().getPropertyStore();
        loadKeyParts();
    }

    function loadKeyParts() {
        keyParts = storage.getApiKeyParts();
        if (keyParts.size() == 0) {
            for (var i = 0; i < segmentCount; i++) {
                keyParts.add("");
            }
        }
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_TINY, Rez.Strings.ApiKey, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 35, width, 35);

        var fullKey = getFullKey();
        var keyLen = fullKey.length();
        var statusColor = keyLen == 70 ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY;
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        var statusText = keyLen.toString() + "/70";
        dc.drawText(width / 2, 42, Graphics.FONT_TINY, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        var listTop = headerHeight + 10;
        var availableHeight = height - listTop - 50;
        var maxVisible = availableHeight / segmentHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var i = scrollOffset; i < segmentCount; i++) {
            if (i >= scrollOffset + maxVisible + 1) {
                break;
            }

            var y = listTop + (i - scrollOffset) * segmentHeight;

            if (i == selectedPart) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                dc.fillRectangle(5, y, width - 10, segmentHeight - 4);
            }

            dc.setColor(i == selectedPart ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(10, y + 8, Graphics.FONT_TINY, "Part " + (i + 1) + "/10", Graphics.TEXT_JUSTIFY_LEFT);

            var partValue = keyParts.get(i);
            var displayValue = partValue;
            if (displayValue.length() == 0) {
                displayValue = "Tap to enter";
                dc.setColor(i == selectedPart ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }

            dc.setColor(i == selectedPart ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, y + 24, Graphics.FONT_SMALL, displayValue, Graphics.TEXT_JUSTIFY_CENTER);

            if (i < segmentCount - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + segmentHeight - 4, width - 10, y + segmentHeight - 4);
            }
        }

        dc.clearClip();

        var saveBtnY = height - 40;
        var saveBtnWidth = 80;
        var saveBtnHeight = 28;
        var saveBtnX = (width - saveBtnWidth) / 2;

        if (keyLen > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRoundedRectangle(saveBtnX, saveBtnY, saveBtnWidth, saveBtnHeight, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, saveBtnY + 14, Graphics.FONT_SMALL, "Save", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function getFullKey() {
        var key = "";
        for (var i = 0; i < keyParts.size(); i++) {
            key = key + keyParts.get(i);
        }
        return key;
    }

    function onTap(evt) {
        var x = evt.getX();
        var y = evt.getY();
        var width = getWidth();
        var height = getHeight();

        var saveBtnY = height - 40;
        var saveBtnWidth = 80;
        var saveBtnHeight = 28;
        var saveBtnX = (width - saveBtnWidth) / 2;

        if (x >= saveBtnX && x <= saveBtnX + saveBtnWidth && y >= saveBtnY && y <= saveBtnY + saveBtnHeight) {
            saveKey();
            return;
        }

        var listTop = headerHeight + 10;
        if (y >= listTop) {
            var idx = scrollOffset + (y - listTop) / segmentHeight;
            if (idx >= 0 && idx < segmentCount) {
                selectedPart = idx;
                openSegmentInput(idx);
                View.requestUpdate();
            }
        }
    }

    function openSegmentInput(idx) {
        var options = {
            :title => "Part " + (idx + 1) + "/10 (7 chars)",
            :maxSize => charsPerSegment
        };

        WatchUi.invokeTextInput(
            new ApiKeyTextInputDelegate(self, idx),
            options
        );
    }

    function onSegmentSubmitted(idx, text) {
        if (text != null) {
            keyParts.set(idx, text);
            storage.setApiKeyPart(idx, text);
        }
        View.requestUpdate();
    }

    function saveKey() {
        var fullKey = getFullKey();
        storage.setApiKey(fullKey);
        storage.setApiKeyParts(keyParts);

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_DIRECTION_UP) {
            if (scrollOffset + (getHeight() - headerHeight - 60) / segmentHeight < segmentCount) {
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
}

class ApiKeyTextInputDelegate extends WatchUi.TextConfirmationDelegate {

    var view;
    var segmentIdx;

    function initialize(apiKeyView, idx) {
        TextConfirmationDelegate.initialize();
        view = apiKeyView;
        segmentIdx = idx;
    }

    function onConfirmed(text) {
        view.onSegmentSubmitted(segmentIdx, text);
    }
}

class ApiKeyInputDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(apiKeyView) {
        BehaviorDelegate.initialize();
        view = apiKeyView;
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
