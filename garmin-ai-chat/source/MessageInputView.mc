using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

class MessageInputView extends WatchUi.View {

    var currentText;
    var isLoading;
    var errorMessage;
    var conversation;
    var storage;
    var viewWidth;
    var viewHeight;

    function initialize(existingConv) {
        View.initialize();
        currentText = "";
        isLoading = false;
        errorMessage = null;
        conversation = existingConv;
        storage = Application.getApp().getPropertyStore();
    }

    function onLayout(dc) {
        viewWidth = dc.getWidth();
        viewHeight = dc.getHeight();
    }

    function onExit() {
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
        if (currentText.length() < 100) {
            displayText = displayText + "|";
        }
        dc.drawText(20, inputY + 35, Graphics.FONT_SMALL, displayText, Graphics.TEXT_JUSTIFY_LEFT);

        if (currentText.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 15, inputY + 35, Graphics.FONT_TINY, currentText.length().toString() + "/500", Graphics.TEXT_JUSTIFY_RIGHT);
        }

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
        var width = viewWidth;
        var height = viewHeight;

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
        if (WatchUi has :TextPicker) {
            WatchUi.pushView(new WatchUi.TextPicker(currentText), new TextInputDelegate(self), WatchUi.SLIDE_DOWN);
        }
    }

    function onTextSubmitted(text) {
        if (text != null && text.length() > 0) {
            currentText = text;
            WatchUi.requestUpdate();
        }
    }

    function sendMessage() {
        if (currentText.length() == 0 || isLoading) {
            return;
        }

        if (!storage.isApiKeySet()) {
            errorMessage = Rez.Strings.NoApiKey;
            WatchUi.requestUpdate();
            return;
        }

        isLoading = true;
        errorMessage = null;
        WatchUi.requestUpdate();

        if (conversation == null) {
            conversation = Conversation.create(currentText);
        }

        var userMsg = Message.userMessage(currentText);
        conversation.addMessage(userMsg);

        var loadingMsg = Message.systemMessage(Rez.Strings.Loading);
        conversation.addMessage(loadingMsg);

        try {
            
        } catch (e) {
        }

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
        WatchUi.requestUpdate();
    }

    function setError(msg) {
        errorMessage = msg;
        isLoading = false;
        WatchUi.requestUpdate();
    }

    function setInitialText(text) {
        currentText = text;
        WatchUi.requestUpdate();
    }
}

class SendCallback {

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
}

class TextInputDelegate extends WatchUi.TextPickerDelegate {

    var view;

    function initialize(msgView) {
        TextPickerDelegate.initialize();
        view = msgView;
    }

    function onTextEntered(text, changed) {
        view.onTextSubmitted(text);
        return true;
    }

    function onCancel() {
        return true;
    }
}

class MessageInputInputDelegate extends WatchUi.BehaviorDelegate {

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
}
