using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class ConversationView extends WatchUi.View

    var conversation;
    var scrollOffset;
    var isLoading;
    var errorMessage;
    var storage;

    function initialize(convId) {
        View.initialize();
        conversation = null;
        scrollOffset = 0;
        isLoading = false;
        errorMessage = null;
        storage = null;

        loadData(convId);
    }

    function loadData(convId) {
        storage = Application.getApp().getPropertyStore();
        var data = storage.getConversation(convId);
        if (data != null) {
            conversation = Conversation.load(convId, data);
        }
    }

    function onLayout(dc) {
        if (storage == null) {
            storage = Application.getApp().getPropertyStore();
        }
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (conversation == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "Conversation not found", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = conversation.title;
        if (title.length() > 20) {
            title = title.substring(0, 17) + "...";
        }
        dc.drawText(width / 2, 18, Graphics.FONT_TINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 30, width, 30);

        var headerHeight = 35;
        var footerHeight = 45;
        var availableHeight = height - headerHeight - footerHeight;

        var messages = conversation.getMessages();
        if (messages.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "No messages", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setClip(0, headerHeight, width, availableHeight);

        var y = headerHeight + availableHeight - 10;
        var startIdx = messages.size() - 1;
        if (startIdx - scrollOffset < 0) {
            startIdx = scrollOffset;
        }

        for (var i = startIdx; i >= 0; i--) {
            var msg = messages.get(i);
            var lineHeight = estimateLineHeight(msg.content, dc);

            if (y - lineHeight < headerHeight) {
                break;
            }

            y = y - lineHeight - 8;

            if (msg.isUser()) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                var textWidth = dc.getTextWidth(msg.content, Graphics.FONT_SMALL);
                var bubbleWidth = textWidth + 20;
                if (bubbleWidth > width - 40) {
                    bubbleWidth = width - 40;
                }
                var bubbleX = width - bubbleWidth - 10;
                dc.fillRoundedRectangle(bubbleX, y, bubbleWidth, lineHeight, 8);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, y + 12, Graphics.FONT_SMALL, msg.content, Graphics.TEXT_JUSTIFY_RIGHT);
            } else if (msg.isAssistant()) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                var textWidth = dc.getTextWidth(msg.content, Graphics.FONT_SMALL);
                var bubbleWidth = textWidth + 20;
                if (bubbleWidth > width - 40) {
                    bubbleWidth = width - 40;
                }
                dc.fillRoundedRectangle(10, y, bubbleWidth, lineHeight, 8);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(15, y + 12, Graphics.FONT_SMALL, msg.content, Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, y + 12, Graphics.FONT_TINY, msg.content, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        dc.clearClip();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, height - footerHeight, width, height - footerHeight);

        var replyBtnY = height - footerHeight + 10;
        var replyBtnWidth = 100;
        var replyBtnHeight = 28;
        var replyBtnX = (width - replyBtnWidth) / 2;

        if (!isLoading) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRoundedRectangle(replyBtnX, replyBtnY, replyBtnWidth, replyBtnHeight, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, replyBtnY + 14, Graphics.FONT_SMALL, "Reply", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRoundedRectangle(replyBtnX, replyBtnY, replyBtnWidth, replyBtnHeight, 8);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, replyBtnY + 14, Graphics.FONT_SMALL, Lang.format("$1$", [Resources.getString(Resources.Strings.Loading)]), Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (errorMessage != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 12, Graphics.FONT_TINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function estimateLineHeight(text, dc) {
        var width = dc.getWidth() - 60;
        var textWidth = dc.getTextWidth(text, Graphics.FONT_SMALL);
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
        var x = evt.getX();
        var y = evt.getY();
        var width = getWidth();
        var height = getHeight();

        var footerHeight = 45;
        var replyBtnY = height - footerHeight + 10;
        var replyBtnWidth = 100;
        var replyBtnHeight = 28;
        var replyBtnX = (width - replyBtnWidth) / 2;

        if (x >= replyBtnX && x <= replyBtnX + replyBtnWidth && y >= replyBtnY && y <= replyBtnY + replyBtnHeight) {
            if (!isLoading) {
                openReplyInput();
            }
            return;
        }
    }

    function openReplyInput() {
        var view = new MessageInputView(conversation);
        WatchUi.pushView(view, new MessageInputInputDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();
        var messages = conversation.getMessages();

        if (direction == WatchUi.SWIPE_DIRECTION_UP) {
            if (scrollOffset < messages.size() - 3) {
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

    function onSendComplete(response, error) {
        isLoading = false;

        if (error != null) {
            errorMessage = error;
        } else if (response != null) {
            conversation.messages.remove(conversation.messages.size() - 1);

            var assistantMsg = Message.assistantMessage(response);
            conversation.addMessage(assistantMsg);

            storage.setLastConversationId(conversation.id);
        }

        View.requestUpdate();
    }

    function setLoading(loading) {
        isLoading = loading;
        View.requestUpdate();
    }

    function setError(msg) {
        errorMessage = msg;
        isLoading = false;
        View.requestUpdate();
    }
end

class ConversationViewInputDelegate extends WatchUi.BehaviorDelegate

    var view;

    function initialize(convView) {
        BehaviorDelegate.initialize();
        view = convView;
    }

    function onTap(evt) {
        view.onTap(evt);
        return true;
    }

    function onSwipe(evt) {
        view.onSwipe(evt);
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
end
