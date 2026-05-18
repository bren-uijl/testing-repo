using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;
using Toybox.Json;

class MessageInputView extends WatchUi.View

    var currentText;
    var isLoading;
    var errorMessage;
    var conversation;
    var cursorVisible;
    var cursorTimer;
    var storage;

    function initialize(existingConv) {
        View.initialize();
        currentText = "";
        isLoading = false;
        errorMessage = null;
        conversation = existingConv;
        cursorVisible = true;
        cursorTimer = null;
        storage = Application.getApp().getPropertyStore();
    }

    function onLayout(dc) {
        startCursorBlink();
    }

    function onExit() {
        if (cursorTimer != null) {
            System.cancelTimer(cursorTimer);
        }
    }

    function startCursorBlink() {
        cursorTimer = System.setTimer(500, method(:toggleCursor), null);
    }

    function toggleCursor(info) {
        cursorVisible = !cursorVisible;
        View.requestUpdate();
        cursorTimer = System.setTimer(500, method(:toggleCursor), null);
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 20, Graphics.FONT_TINY, Rez.Strings.TypeMessage, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(10, 35, width - 10, 35);

        var inputY = 60;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(10, inputY, width - 20, 80, 10);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var displayText = currentText;
        if (cursorVisible && currentText.length() < 100) {
            displayText = displayText + "|";
        }
        dc.drawText(20, inputY + 35, Graphics.FONT_SMALL, displayText, Graphics.TEXT_JUSTIFY_LEFT);

        if (errorMessage != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, inputY + 100, Graphics.FONT_TINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (isLoading) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 60, Graphics.FONT_SMALL, Rez.Strings.Loading, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var sendBtnY = height - 45;
        var sendBtnWidth = 80;
        var sendBtnHeight = 30;
        var sendBtnX = (width - sendBtnWidth) / 2;

        if (currentText.length() > 0 && !isLoading) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRoundedRectangle(sendBtnX, sendBtnY, sendBtnWidth, sendBtnHeight, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, sendBtnY + 15, Graphics.FONT_SMALL, Rez.Strings.Send, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRoundedRectangle(sendBtnX, sendBtnY, sendBtnWidth, sendBtnHeight, 8);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, sendBtnY + 15, Graphics.FONT_SMALL, Rez.Strings.Send, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onTap(evt) {
        var x = evt.getX();
        var y = evt.getY();
        var width = getWidth();
        var height = getHeight();

        var sendBtnY = height - 45;
        var sendBtnWidth = 80;
        var sendBtnHeight = 30;
        var sendBtnX = (width - sendBtnWidth) / 2;

        if (x >= sendBtnX && x <= sendBtnX + sendBtnWidth && y >= sendBtnY && y <= sendBtnY + sendBtnHeight) {
            if (currentText.length() > 0 && !isLoading) {
                sendMessage();
            }
            return;
        }

        var inputY = 60;
        if (y >= inputY && y <= inputY + 80) {
            openTextInput();
            return;
        }
    }

    function openTextInput() {
        var options = {
            :title => Rez.Strings.TypeMessage,
            :maxSize => 500
        };

        WatchUi.invokeTextInput(
            new TextInputDelegate(self),
            options
        );
    }

    function onTextSubmitted(text) {
        if (text != null && text.length() > 0) {
            currentText = text;
            View.requestUpdate();
        }
    }

    function sendMessage() {
        if (currentText.length() == 0 || isLoading) {
            return;
        }

        if (!storage.isApiKeySet()) {
            errorMessage = Rez.Strings.NoApiKey;
            View.requestUpdate();
            return;
        }

        isLoading = true;
        errorMessage = null;
        View.requestUpdate();

        if (conversation == null) {
            conversation = Conversation.create(currentText);
        }

        var userMsg = Message.userMessage(currentText);
        conversation.addMessage(userMsg);

        var loadingMsg = Message.systemMessage(Rez.Strings.Loading);
        conversation.addMessage(loadingMsg);

        var messages = conversation.getApiMessages();

        var client = new NviApiClient();
        client.setApiKey(storage.getApiKey());
        client.setModel(storage.getModel());
        client.setCallback(new SendCallback(self, conversation, loadingMsg));

        client.sendMessage(messages, null);

        currentText = "";
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

    function onSendComplete(response, error) {
        isLoading = false;

        if (error != null) {
            errorMessage = error;
        } else if (response != null) {
            conversation.removeLastMessage();

            var assistantMsg = Message.assistantMessage(response);
            conversation.addMessage(assistantMsg);

            storage.setLastConversationId(conversation.id);

            Application.getApp().showConversation(conversation.id);
            return;
        }

        View.requestUpdate();
    }
end

class SendCallback

    var view;
    var conv;
    var loadingMsg;

    function initialize(msgView, conversation, loadMsg) {
        view = msgView;
        conv = conversation;
        loadingMsg = loadMsg;
    }

    function onComplete(response, error) {
        System.println("SendCallback.onComplete");
        view.onSendComplete(response, error);
    }
end

class TextInputDelegate extends WatchUi.TextConfirmationDelegate

    var view;

    function initialize(msgView) {
        TextConfirmationDelegate.initialize();
        view = msgView;
    }

    function onConfirmed(text) {
        view.onTextSubmitted(text);
    }
end

class MessageInputInputDelegate extends WatchUi.BehaviorDelegate

    var view;

    function initialize(msgView) {
        BehaviorDelegate.initialize();
        view = msgView;
    }

    function onTap(evt) {
        if (view != null) {
            view.onTap(evt);
        }
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
end
