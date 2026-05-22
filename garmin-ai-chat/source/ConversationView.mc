using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class ConversationView extends WatchUi.View {

    var conversation;
    var scrollOffset;
    var isLoading;
    var errorMessage;
    var storage;
    var loadingDots;
    var viewWidth;
    var viewHeight;

    function initialize(convId) {
        View.initialize();
        conversation = null;
        scrollOffset = 0;
        isLoading = false;
        errorMessage = null;
        storage = null;
        loadingDots = "";

        loadData(convId);
    }

    function loadData(convId) {
        storage = Application.getApp().getPropertyStore();
        if (convId == null || convId.length() == 0) {
            conversation = null;
            return;
        }
        var data = storage.getConversation(convId);
        if (data != null) {
            try {
                conversation = Conversation.load(convId, data);
            } catch (e) {
                System.println("Failed to load conversation: " + e.toString());
                conversation = null;
            }
        }
    }

    function onLayout(dc) {
        if (storage == null) {
            storage = Application.getApp().getPropertyStore();
        }
        viewWidth = dc.getWidth();
        viewHeight = dc.getHeight();
    }

    function onShow() {
        if (storage == null) {
            storage = Application.getApp().getPropertyStore();
        }
        if (conversation != null) {
            var convId = conversation.id;
            var data = storage.getConversation(convId);
            if (data != null) {
                try {
                    conversation = Conversation.load(convId, data);
                } catch (e) {
                    System.println("Failed to reload conversation: " + e.toString());
                }
            }
        }
        scrollOffset = 0;
        errorMessage = null;
        WatchUi.requestUpdate();
    }

    function onExit() {
    }

    function startLoadingAnimation() {
        loadingDots = "...";
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (conversation == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_MEDIUM, "Conversation not found", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = conversation.title;
        if (title.length() > 20) {
            title = title.substring(0, 17) + "...";
        }
        dc.drawText(width / 2, 18, Graphics.FONT_MEDIUM, title, Graphics.TEXT_JUSTIFY_CENTER);

        var msgCount = conversation.getMessageCount();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 28, Graphics.FONT_MEDIUM, msgCount.toString() + " msgs", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 30, width, 30);

        var headerHeight = 35;
        var footerHeight = 45;
        var availableHeight = height - headerHeight - footerHeight;

        var messages = conversation.getMessages();
        if (messages.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_MEDIUM, "No messages", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setClip(0, headerHeight, width, availableHeight);

        var y = headerHeight + availableHeight - 10;
        var startIdx = messages.size() - 1;
        if (startIdx - scrollOffset < 0) {
            startIdx = scrollOffset;
        }

        var msgIdx = startIdx;
        while (msgIdx >= 0) {
            var msg = getMessageAt(messages, msgIdx);
            var lineHeight = estimateLineHeight(msg.content, dc);

            if (y - lineHeight < headerHeight) {
                break;
            }

            y = y - lineHeight - 8;

            if (msg.isUser()) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                var textWidth = dc.getTextWidthInPixels(msg.content, Graphics.FONT_MEDIUM);
                var bubbleWidth = textWidth + 20;
                if (bubbleWidth > width - 40) {
                    bubbleWidth = width - 40;
                }
                var bubbleX = width - bubbleWidth - 10;
                dc.fillRoundedRectangle(bubbleX, y, bubbleWidth, lineHeight, 8);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, y + 12, Graphics.FONT_MEDIUM, msg.content, Graphics.TEXT_JUSTIFY_RIGHT);
            } else if (msg.isAssistant()) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                var textWidth = dc.getTextWidthInPixels(msg.content, Graphics.FONT_MEDIUM);
                var bubbleWidth = textWidth + 20;
                if (bubbleWidth > width - 40) {
                    bubbleWidth = width - 40;
                }
                dc.fillRoundedRectangle(10, y, bubbleWidth, lineHeight, 8);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(15, y + 12, Graphics.FONT_MEDIUM, msg.content, Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, y + 12, Graphics.FONT_MEDIUM, msg.content, Graphics.TEXT_JUSTIFY_CENTER);
            }
            msgIdx--;
        }

        dc.clearClip();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, height - footerHeight, width, height - footerHeight);

        var replyBtnY = height - footerHeight + 10;
        var replyBtnWidth = 100;
        var replyBtnHeight = 28;
        var cancelBtnWidth = 60;

        var replyBtnX;
        var cancelBtnX;
        if (isLoading) {
            var pairWidth = replyBtnWidth + 10 + cancelBtnWidth;
            replyBtnX = (width - pairWidth) / 2;
            cancelBtnX = replyBtnX + replyBtnWidth + 10;
        } else {
            replyBtnX = (width - replyBtnWidth) / 2;
            cancelBtnX = 0;
        }

        if (!isLoading) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRoundedRectangle(replyBtnX, replyBtnY, replyBtnWidth, replyBtnHeight, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(replyBtnX + replyBtnWidth / 2, replyBtnY + 14, Graphics.FONT_MEDIUM, "Reply", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRoundedRectangle(replyBtnX, replyBtnY, replyBtnWidth, replyBtnHeight, 8);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(replyBtnX + replyBtnWidth / 2, replyBtnY + 14, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.Loading) + loadingDots, Graphics.TEXT_JUSTIFY_CENTER);

            if (cancelBtnX + cancelBtnWidth <= width) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                dc.fillRoundedRectangle(cancelBtnX, replyBtnY, cancelBtnWidth, replyBtnHeight, 8);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cancelBtnX + cancelBtnWidth / 2, replyBtnY + 14, Graphics.FONT_MEDIUM, "Cancel", Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        if (errorMessage != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 12, Graphics.FONT_MEDIUM, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);

            var retryBtnWidth = 50;
            var retryBtnHeight = 20;
            var retryBtnX = (width - retryBtnWidth) / 2;
            var retryBtnY = height - 30;

            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillRoundedRectangle(retryBtnX, retryBtnY, retryBtnWidth, retryBtnHeight, 6);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, retryBtnY + 10, Graphics.FONT_MEDIUM, "Retry", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function getMessageAt(msgList, idx) {
        var count = 0;
        for (var mi = 0; mi < msgList.size(); mi++) {
            var m = msgList[mi];
            if (count == idx) return m;
            count++;
        }
        return null;
    }

    function estimateLineHeight(text, dc) {
        var width = dc.getWidth() - 60;
        var textWidth = dc.getTextWidthInPixels(text, Graphics.FONT_MEDIUM);
        var lines = (textWidth / width).toFloat().ceil().toNumber();
        if (lines < 1) {
            lines = 1;
        }
        if (lines > 5) {
            lines = 5;
        }
        return lines * 18 + 10;
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
        var width = viewWidth;
        var height = viewHeight;

        if (y < 30 && conversation != null) {
            openRenameInput();
            return;
        }

        if (y >= 28 && y < 35 && conversation != null) {
            clearConversation();
            return;
        }

        var footerHeight = 45;
        var replyBtnY = height - footerHeight + 10;
        var replyBtnWidth = 100;
        var replyBtnHeight = 28;
        var cancelBtnWidth = 60;

        var replyBtnX;
        var cancelBtnX;
        if (isLoading) {
            var pairWidth = replyBtnWidth + 10 + cancelBtnWidth;
            replyBtnX = (width - pairWidth) / 2;
            cancelBtnX = replyBtnX + replyBtnWidth + 10;
        } else {
            replyBtnX = (width - replyBtnWidth) / 2;
            cancelBtnX = 0;
        }

        if (x >= replyBtnX && x <= replyBtnX + replyBtnWidth && y >= replyBtnY && y <= replyBtnY + replyBtnHeight) {
            if (!isLoading) {
                openReplyInput();
            }
            return;
        }

        if (isLoading) {
            if (x >= cancelBtnX && x <= cancelBtnX + cancelBtnWidth && y >= replyBtnY && y <= replyBtnY + replyBtnHeight) {
                onCancelRequest();
                return;
            }
        }

        if (errorMessage != null) {
            var retryBtnWidth = 50;
            var retryBtnHeight = 20;
            var retryBtnX = (width - retryBtnWidth) / 2;
            var retryBtnY = height - 30;

            if (x >= retryBtnX && x <= retryBtnX + retryBtnWidth && y >= retryBtnY && y <= retryBtnY + retryBtnHeight) {
                onRetryRequest();
                return;
            }
        }
    }

    function openRenameInput() {
        if (WatchUi has :TextPicker) {
            WatchUi.pushView(new WatchUi.TextPicker(conversation.title), new RenameTextInputDelegate(self), WatchUi.SLIDE_DOWN);
        }
    }

    function onRenameSubmitted(text) {
        if (text != null && text.length() > 0 && conversation != null) {
            conversation.setTitle(text);
            WatchUi.requestUpdate();
        }
    }

    function clearConversation() {
        if (conversation == null || isLoading) {
            return;
        }

        var messages = conversation.getMessages();
        if (messages.size() == 0) {
            return;
        }

        var title = conversation.title;
        conversation.messages = [];
        conversation.updatedAt = System.getTimer();
        conversation.save();

        scrollOffset = 0;
        errorMessage = null;
        WatchUi.requestUpdate();
    }

    function onCancelRequest() {
        isLoading = false;
        loadingDots = "";
        conversation.removeLastMessage();
        errorMessage = "Request cancelled";
        WatchUi.requestUpdate();
    }

    function onRetryRequest() {
        if (errorMessage == null || conversation == null) {
            return;
        }

        var messages = conversation.getApiMessages();
        if (messages.size() == 0) {
            return;
        }

        errorMessage = null;
        isLoading = true;
        loadingDots = ".";
        startLoadingAnimation();
        WatchUi.requestUpdate();

        var client = new NviApiClient();
        client.setApiKey(storage.getApiKey());
        client.setModel(storage.getModel());
        client.setCallback(new ConversationSendCallback(self, conversation));

        client.sendMessage(messages, null);
    }

    function openReplyInput() {
        var view = new MessageInputView(conversation);
        var delegate = new MessageInputInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();
        var messages = conversation.getMessages();

        if (direction == WatchUi.SWIPE_UP) {
            if (scrollOffset < messages.size() - 3) {
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

    function onSendComplete(response, error) {
        isLoading = false;
        loadingDots = "";

        if (error != null) {
            errorMessage = error;
        } else if (response != null) {
            conversation.removeLastMessage();

            var assistantMsg = Message.assistantMessage(response);
            conversation.addMessage(assistantMsg);

            storage.setLastConversationId(conversation.id);
        }

        WatchUi.requestUpdate();
    }

    function setLoading(loading) {
        isLoading = loading;
        if (loading) {
            loadingDots = "...";
            startLoadingAnimation();
        } else {
            loadingDots = "";
        }
        WatchUi.requestUpdate();
    }

    function setError(msg) {
        errorMessage = msg;
        isLoading = false;
        WatchUi.requestUpdate();
    }
}

class ConversationSendCallback {

    var view;
    var conv;

    function initialize(convView, conversation) {
        view = convView;
        conv = conversation;
    }

    function onComplete(response, error) {
        view.onSendComplete(response, error);
    }
}

class RenameTextInputDelegate extends WatchUi.TextPickerDelegate {

    var view;

    function initialize(convView) {
        TextPickerDelegate.initialize();
        view = convView;
    }

    function onTextEntered(text, changed) {
        view.onRenameSubmitted(text);
        return true;
    }

    function onCancel() {
        return true;
    }
}

class ConversationViewInputDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(convView) {
        BehaviorDelegate.initialize();
        view = convView;
    }

    function onTap(evt) {
        if (view != null) {
            view.onTap(evt);
        }
        return true;
    }

    function onSwipe(evt) {
        if (view != null) {
            view.onSwipe(evt);
        }
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
