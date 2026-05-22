using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class AboutItem {
    var label;
    var value;

    function initialize(label, value) {
        self.label = label;
        self.value = value;
    }
}

class AboutView extends WatchUi.View {

    var items;
    var scrollOffset;
    var itemHeight;
    var headerHeight;
    var viewWidth;
    var viewHeight;

    function initialize() {
        View.initialize();
        items = [];
        scrollOffset = 0;
        itemHeight = 45;
        headerHeight = 45;

        items.add(new AboutItem("Version", "1.2.0"));
        items.add(new AboutItem("Device", "vívoactive 5"));
        items.add(new AboutItem("API", "NVIDIA Chat"));
        items.add(new AboutItem("Models", "8 available"));
        items.add(new AboutItem("Built with", "Monkey C"));
        items.add(new AboutItem("License", "MIT"));
    }

    function onLayout(dc) {
        viewWidth = dc.getWidth();
        viewHeight = dc.getHeight();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 18, Graphics.FONT_MEDIUM, "About AI Chat", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 35, width, 35);

        var listTop = headerHeight;
        var availableHeight = height - listTop - 20;
        var maxVisible = availableHeight / itemHeight;

        dc.setClip(0, listTop, width, availableHeight);

        for (var ii = 0; ii < items.size(); ii++) {
            var item = items[ii];
            if (ii < scrollOffset) { continue; }
            if (ii >= scrollOffset + maxVisible + 1) break;

            var y = listTop + (ii - scrollOffset) * itemHeight;

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y + 14, Graphics.FONT_MEDIUM, item.label, Graphics.TEXT_JUSTIFY_LEFT);

            var value = item.value;
            if (value != null) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, y + 14, Graphics.FONT_MEDIUM, value, Graphics.TEXT_JUSTIFY_RIGHT);
            }

            if (ii < items.size() - 1) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(10, y + itemHeight - 4, width - 10, y + itemHeight - 4);
            }
        }

        dc.clearClip();
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

class AboutInputDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(aboutView) {
        BehaviorDelegate.initialize();
        view = aboutView;
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
