using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class QuickPrompt {
    var label;
    var prompt;

    function initialize(label, prompt) {
        self.label = label;
        self.prompt = prompt;
    }
}

class ConversationListView extends WatchUi.View {

    var conversations;
    var scrollOffset;
    var itemHeight;
    var headerHeight;
    var selectedIdx;
    var storage;
    var deleteMode;
    var deleteTargetIdx;
    var showQuickPrompts;
    var quickPrompts;
    var viewWidth;
    var viewHeight;

    function initialize() {
        View.initialize();
        conversations = [];
        scrollOffset = 0;
        itemHeight = 50;
        headerHeight = 50;
        selectedIdx = -1;
        storage = null;
        deleteMode = false;
        deleteTargetIdx = -1;
        showQuickPrompts = false;
        quickPrompts = [
            new QuickPrompt("Translate", "Translate to English: "),
            new QuickPrompt("Summarize", "Summarize: "),
            new QuickPrompt("Explain", "Explain simply: "),
            new QuickPrompt("Weather", "What's the weather like?"),
            new QuickPrompt("Joke", "Tell me a short joke"),
            new QuickPrompt("Timer", "Set a reminder for ")
        ];
    }

    function onLayout(dc) {
        storage = Application.getApp().getPropertyStore();
        loadConversations();
        viewWidth = dc.getWidth();
        viewHeight = dc.getHeight();
    }

    function onShow() {
        if (storage == null) {
            storage = Application.getApp().getPropertyStore();
        }
        loadConversations();
    }

    function loadConversations() {
        conversations = [];
        var ids = storage.getConversationIds();

        for (var id : ids) {
            if (id == null) {
                continue;
            }
            var data = storage.getConversation(id);
            if (data != null) {
                try {
                    var conv = Conversation.load(id, data);
                    if (conv != null) {
                        conversations.add(conv);
                    }
                } catch (e) {
                    System.println("Failed to load conversation " + id + ": " + e.toString());
                }
            }
        }

        sortConversations();
    }

    function sortConversations() {
        var sorted = [];
        for (var conv : conversations) {
            var added = false;
            var tmp = [];
            for (var r : sorted) {
                if (!added && conv.updatedAt > r.updatedAt) {
                    tmp.add(conv);
                    added = true;
                }
                tmp.add(r);
            }
            if (!added) {
                tmp.add(conv);
            }
            sorted = tmp;
        }
        conversations = sorted;
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.AppName), Graphics.TEXT_JUSTIFY_CENTER);

        if (!storage.isApiKeySet()) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, 30, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.NoApiKey), Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (deleteMode) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 35, 18, Graphics.FONT_MEDIUM, "X", Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 35, 18, Graphics.FONT_MEDIUM, "?", Graphics.TEXT_JUSTIFY_RIGHT);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 38, width, 38);

        var newBtnY = 42;
        var btnWidth = 70;
        var btnHeight = 24;
        var btnX = (width - btnWidth) / 2;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(btnX, newBtnY, btnWidth, btnHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, newBtnY + 12, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.NewConversation), Graphics.TEXT_JUSTIFY_CENTER);

        if (showQuickPrompts) {
            var promptY = newBtnY + btnHeight + 8;
            var promptBtnWidth = (width - 30) / 2;
            var promptBtnHeight = 22;
            var pi = 0;

            for (var prompt : quickPrompts) {
                var col = pi % 2;
                var row = pi / 2;
                var px = 10 + col * (promptBtnWidth + 10);
                var py = promptY + row * (promptBtnHeight + 6);

                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRoundedRectangle(px, py, promptBtnWidth, promptBtnHeight, 6);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(px + promptBtnWidth / 2, py + 11, Graphics.FONT_MEDIUM, prompt.label, Graphics.TEXT_JUSTIFY_CENTER);
                pi++;
            }
        }

        if (conversations.size() == 0 && !showQuickPrompts) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.NoConversations), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (deleteMode) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, newBtnY + 12, Graphics.FONT_MEDIUM, "Delete Mode", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var listTop;
        if (showQuickPrompts) {
            listTop = newBtnY + btnHeight + 8 + 3 * (22 + 6) + 10;
        } else {
            listTop = headerHeight + 30;
        }
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        var ci = 0;
        for (var conv : conversations) {
            if (ci < scrollOffset) { ci++; continue; }
            if (ci >= scrollOffset + maxVisible + 1) break;

            var y = listTop + (ci - scrollOffset) * itemHeight;

            if (deleteMode && ci == deleteTargetIdx) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            } else if (ci == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            }

            var titleColor = deleteMode && ci == deleteTargetIdx ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE;
            dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 8, Graphics.FONT_MEDIUM, conv.title, Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 15, y + 8, Graphics.FONT_MEDIUM, conv.getDisplayTime(), Graphics.TEXT_JUSTIFY_RIGHT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 26, Graphics.FONT_MEDIUM, conv.getPreview(), Graphics.TEXT_JUSTIFY_LEFT);

            if (deleteMode) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 25, y + 24, Graphics.FONT_MEDIUM, "X", Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (ci < conversations.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + itemHeight - 4, width - 10, y + itemHeight - 4);
            }
            ci++;
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var coords = evt.getCoordinates();
        var x = 0;
        var y = 0;
        var isFirst = true;
        for (var c : coords) {
            if (isFirst) { x = c; isFirst = false; }
            else { y = c; }
        }
        var width = viewWidth;

        var newBtnY = 42;
        var btnWidth = 70;
        var btnHeight = 24;
        var btnX = (width - btnWidth) / 2;

        if (x >= btnX && x <= btnX + btnWidth && y >= newBtnY && y <= newBtnY + btnHeight) {
            if (deleteMode) {
                deleteSelectedConversation();
            } else {
                showQuickPrompts = !showQuickPrompts;
                WatchUi.requestUpdate();
            }
            return;
        }

        if (showQuickPrompts) {
            var promptY = newBtnY + btnHeight + 8;
            var promptBtnWidth = (width - 30) / 2;
            var promptBtnHeight = 22;

            var pi = 0;
            for (var prompt : quickPrompts) {
                var col = pi % 2;
                var row = pi / 2;
                var px = 10 + col * (promptBtnWidth + 10);
                var py = promptY + row * (promptBtnHeight + 6);

                if (x >= px && x <= px + promptBtnWidth && y >= py && y <= py + promptBtnHeight) {
                    startQuickConversation(prompt.prompt);
                    return;
                }
                pi++;
            }
        }

        if (x > width - 40 && y < 25) {
            if (deleteMode) {
                deleteMode = false;
                deleteTargetIdx = -1;
                WatchUi.requestUpdate();
            } else {
                Application.getApp().showSettings();
            }
            return;
        }

        var listTop;
        if (showQuickPrompts) {
            listTop = newBtnY + btnHeight + 8 + 3 * (22 + 6) + 10;
        } else {
            listTop = headerHeight + 30;
        }
        if (y >= listTop) {
            var tappedIdx = scrollOffset + (y - listTop) / itemHeight;
            var ci = 0;
            for (var conv : conversations) {
                if (ci == tappedIdx) {
                    if (deleteMode) {
                        deleteTargetIdx = ci;
                        WatchUi.requestUpdate();
                    } else {
                        Application.getApp().showConversation(conv.id);
                    }
                    break;
                }
                ci++;
            }
        }
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_LEFT) {
            if (!deleteMode && conversations.size() > 0) {
                deleteMode = true;
                deleteTargetIdx = -1;
                WatchUi.requestUpdate();
            }
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            if (deleteMode) {
                deleteMode = false;
                deleteTargetIdx = -1;
                WatchUi.requestUpdate();
            }
        } else if (direction == WatchUi.SWIPE_UP) {
            if (scrollOffset + (viewHeight - headerHeight - 50) / itemHeight < conversations.size()) {
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

    function deleteSelectedConversation() {
        if (deleteTargetIdx >= 0) {
            var ci = 0;
            for (var conv : conversations) {
                if (ci == deleteTargetIdx) {
                    conv.delete();
                    conversations.remove(ci);
                    break;
                }
                ci++;
            }
            deleteTargetIdx = -1;
            if (scrollOffset >= conversations.size()) {
                scrollOffset = conversations.size() - 1;
                if (scrollOffset < 0) {
                    scrollOffset = 0;
                }
            }
            WatchUi.requestUpdate();
        }
    }

    function startQuickConversation(prompt) {
        showQuickPrompts = false;
        var view = new MessageInputView(null);
        view.setInitialText(prompt);
        var delegate = new MessageInputInputDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }
}

class ConversationListInputDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(convListView) {
        BehaviorDelegate.initialize();
        view = convListView;
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
}
