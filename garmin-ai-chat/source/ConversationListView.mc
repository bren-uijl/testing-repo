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

    var titleY;
    var warningY;
    var iconRightMargin;
    var iconY;
    var dividerY;
    var newBtnY;
    var btnWidth;
    var btnHeight;
    var promptBtnHeight;
    var promptHPad;
    var promptVPad;
    var promptCols;
    var promptSidePad;
    var promptTopMargin;
    var listHPad;
    var listVPad;

    function initialize() {
        View.initialize();
        conversations = [];
        scrollOffset = 0;
        itemHeight = 50;
        headerHeight = 50;
        titleY = 22;
        warningY = 44;
        iconRightMargin = 35;
        iconY = 22;
        dividerY = 55;
        newBtnY = 68;
        btnWidth = 70;
        btnHeight = 24;
        promptBtnHeight = 22;
        promptHPad = 10;
        promptVPad = 8;
        promptCols = 2;
        promptSidePad = 10;
        promptTopMargin = 12;
        listHPad = 5;
        listVPad = 4;
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
        scrollOffset = 0;
        WatchUi.requestUpdate();
    }

    function loadConversations() {
        conversations = [];
        var ids = storage.getConversationIds();

        for (var idi = 0; idi < ids.size(); idi++) {
            var id = ids[idi];
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
        for (var ci = 0; ci < conversations.size(); ci++) {
            var conv = conversations[ci];
            var added = false;
            var tmp = [];
            for (var ri = 0; ri < sorted.size(); ri++) {
                var r = sorted[ri];
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
        dc.drawText(width / 2, titleY, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.AppName), Graphics.TEXT_JUSTIFY_CENTER);

        if (!storage.isApiKeySet()) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, warningY, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.NoApiKey), Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (deleteMode) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - iconRightMargin, iconY, Graphics.FONT_MEDIUM, "X", Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - iconRightMargin, iconY, Graphics.FONT_MEDIUM, "?", Graphics.TEXT_JUSTIFY_RIGHT);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, dividerY, width, dividerY);

        var btnX = (width - btnWidth) / 2;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(btnX, newBtnY, btnWidth, btnHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, newBtnY + 12, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.NewConversation), Graphics.TEXT_JUSTIFY_CENTER);

        if (showQuickPrompts) {
            var promptY = newBtnY + btnHeight + promptTopMargin;
            var promptBtnWidth = (width - promptSidePad * 3) / 2;
            for (var pi = 0; pi < quickPrompts.size(); pi++) {
                var prompt = quickPrompts[pi];
                var col = pi % promptCols;
                var row = pi / promptCols;
                var px = promptSidePad + col * (promptBtnWidth + promptHPad);
                var py = promptY + row * (promptBtnHeight + promptVPad);

                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRoundedRectangle(px, py, promptBtnWidth, promptBtnHeight, 6);

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(px + promptBtnWidth / 2, py + 11, Graphics.FONT_MEDIUM, prompt.label, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        if (conversations.size() == 0) {
            if (!showQuickPrompts) {
                showQuickPrompts = true;
                WatchUi.requestUpdate();
            }
            return;
        }

        if (deleteMode) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, newBtnY + btnHeight / 2, Graphics.FONT_MEDIUM, "Delete Mode", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var listTop;
        if (showQuickPrompts) {
            var promptRows = (quickPrompts.size() + promptCols - 1) / promptCols;
            listTop = newBtnY + btnHeight + promptTopMargin + promptRows * (promptBtnHeight + promptVPad) + 10;
        } else {
            listTop = newBtnY + btnHeight + 15;
        }
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var ci = 0; ci < conversations.size(); ci++) {
            var conv = conversations[ci];
            if (ci < scrollOffset) { continue; }
            if (ci >= scrollOffset + maxVisible + 1) { break; }

            var y = listTop + (ci - scrollOffset) * itemHeight;

            if (deleteMode && ci == deleteTargetIdx) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                dc.fillRectangle(listHPad, y, width - listHPad * 2, itemHeight - listVPad);
            } else if (ci == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(listHPad, y, width - listHPad * 2, itemHeight - listVPad);
            }

            var titleColor = deleteMode && ci == deleteTargetIdx ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE;
            dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(listHPad + 10, y + 8, Graphics.FONT_MEDIUM, conv.title, Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - listHPad - 10, y + 8, Graphics.FONT_MEDIUM, conv.getDisplayTime(), Graphics.TEXT_JUSTIFY_RIGHT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(listHPad + 10, y + 26, Graphics.FONT_MEDIUM, conv.getPreview(), Graphics.TEXT_JUSTIFY_LEFT);

            if (deleteMode) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - listHPad - 20, y + 24, Graphics.FONT_MEDIUM, "X", Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (ci < conversations.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(listHPad + 5, y + itemHeight - listVPad, width - listHPad - 5, y + itemHeight - listVPad);
            }
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var coords = evt.getCoordinates();
        if (coords == null) {
            return;
        }
        var x = 0;
        var y = 0;
        var isFirst = true;
        for (var ci = 0; ci < coords.size(); ci++) {
            var c = coords[ci];
            if (isFirst) { x = c; isFirst = false; }
            else { y = c; }
        }
        var width = viewWidth;

        var btnX = (width - btnWidth) / 2;

        if (x >= btnX && x <= btnX + btnWidth && y >= newBtnY && y <= newBtnY + btnHeight) {
            if (deleteMode) {
                deleteSelectedConversation();
            } else {
                Application.getApp().showNewConversation();
            }
            return;
        }

        if (showQuickPrompts) {
            var promptY = newBtnY + btnHeight + promptTopMargin;
            var promptBtnWidth = (width - promptSidePad * 3) / 2;

            for (var pi = 0; pi < quickPrompts.size(); pi++) {
                var prompt = quickPrompts[pi];
                var col = pi % promptCols;
                var row = pi / promptCols;
                var px = promptSidePad + col * (promptBtnWidth + promptHPad);
                var py = promptY + row * (promptBtnHeight + promptVPad);

                if (x >= px && x <= px + promptBtnWidth && y >= py && y <= py + promptBtnHeight) {
                    startQuickConversation(prompt.prompt);
                    return;
                }
            }
        }

        if (x > width - iconRightMargin - 5 && y < iconY + 15) {
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
            var promptRows = (quickPrompts.size() + promptCols - 1) / promptCols;
            listTop = newBtnY + btnHeight + promptTopMargin + promptRows * (promptBtnHeight + promptVPad) + 10;
        } else {
            listTop = newBtnY + btnHeight + 15;
        }
        if (y >= listTop) {
            var tappedIdx = scrollOffset + (y - listTop) / itemHeight;
            for (var ci = 0; ci < conversations.size(); ci++) {
                var conv = conversations[ci];
                if (ci == tappedIdx) {
                    if (deleteMode) {
                        deleteTargetIdx = ci;
                        WatchUi.requestUpdate();
                    } else {
                        Application.getApp().showConversation(conv.id);
                    }
                    break;
                }
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
            for (var ci = 0; ci < conversations.size(); ci++) {
                var conv = conversations[ci];
                if (ci == deleteTargetIdx) {
                    conv.delete();
                    conversations.remove(ci);
                    break;
                }
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
