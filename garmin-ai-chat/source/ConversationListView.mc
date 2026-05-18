using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

class ConversationListView extends WatchUi.View

    var conversations;
    var scrollOffset;
    var itemHeight;
    var headerHeight;
    var selectedIdx;
    var storage;

    function initialize() {
        View.initialize();
        conversations = [];
        scrollOffset = 0;
        itemHeight = 50;
        headerHeight = 50;
        selectedIdx = -1;
        storage = null;
    }

    function onLayout(dc) {
        storage = Application.getApp().getPropertyStore();
        loadConversations();
    }

    function loadConversations() {
        conversations = [];
        var ids = storage.getConversationIds();

        for (var i = 0; i < ids.size(); i++) {
            var id = ids.get(i);
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
        for (var i = 0; i < conversations.size() - 1; i++) {
            for (var j = i + 1; j < conversations.size(); j++) {
                var a = conversations.get(i);
                var b = conversations.get(j);
                if (b.updatedAt > a.updatedAt) {
                    conversations.set(i, b);
                    conversations.set(j, a);
                }
            }
        }
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_TINY, Rez.Strings.AppName, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 35, 18, Graphics.FONT_TINY, "?", Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 38, width, 38);

        var newBtnY = 42;
        var btnWidth = 70;
        var btnHeight = 24;
        var btnX = (width - btnWidth) / 2;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(btnX, newBtnY, btnWidth, btnHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, newBtnY + 12, Graphics.FONT_TINY, Rez.Strings.NewConversation, Graphics.TEXT_JUSTIFY_CENTER);

        if (conversations.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, Rez.Strings.NoConversations, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var listTop = headerHeight + 30;
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var i = scrollOffset; i < conversations.size(); i++) {
            if (i >= scrollOffset + maxVisible + 1) {
                break;
            }

            var conv = conversations.get(i);
            var y = listTop + (i - scrollOffset) * itemHeight;

            if (i == selectedIdx) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(5, y, width - 10, itemHeight - 4);
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 8, Graphics.FONT_SMALL, conv.title, Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 15, y + 8, Graphics.FONT_TINY, conv.getDisplayTime(), Graphics.TEXT_JUSTIFY_RIGHT);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 26, Graphics.FONT_TINY, conv.getPreview(), Graphics.TEXT_JUSTIFY_LEFT);

            if (i < conversations.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + itemHeight - 4, width - 10, y + itemHeight - 4);
            }
        }

        dc.clearClip();
    }

    function onTap(evt) {
        var x = evt.getX();
        var y = evt.getY();
        var width = getWidth();

        var newBtnY = 42;
        var btnWidth = 70;
        var btnHeight = 24;
        var btnX = (width - btnWidth) / 2;

        if (x >= btnX && x <= btnX + btnWidth && y >= newBtnY && y <= newBtnY + btnHeight) {
            Application.getApp().showNewConversation();
            return;
        }

        if (x > width - 40 && y < 25) {
            Application.getApp().showSettings();
            return;
        }

        var listTop = headerHeight + 30;
        if (y >= listTop) {
            var idx = scrollOffset + (y - listTop) / itemHeight;
            if (idx >= 0 && idx < conversations.size()) {
                var conv = conversations.get(idx);
                Application.getApp().showConversation(conv.id);
            }
        }
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();

        if (direction == WatchUi.SWIPE_DIRECTION_UP) {
            if (scrollOffset + (getHeight() - headerHeight - 50) / itemHeight < conversations.size()) {
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

class ConversationListInputDelegate extends WatchUi.BehaviorDelegate

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
end
