using Toybox.System;
using Toybox.Application;

class Conversation {

    var id;
    var title;
    var messages;
    var createdAt;
    var updatedAt;

    function initialize(convId, convTitle) {
        id = convId;
        title = convTitle;
        messages = [];
        createdAt = System.getTimer();
        updatedAt = System.getTimer();
    }

    function addMessage(msg) {
        var storage = Application.getApp().getPropertyStore();
        var maxMessages = storage.getMaxMessagesPerConversation();

        if (messages.size() >= maxMessages) {
            messages.remove(0);
        }

        messages.add(msg);
        updatedAt = System.getTimer();

        if (messages.size() == 1 && msg.isUser()) {
            var preview = msg.content;
            if (preview.length() > 40) {
                preview = preview.substring(0, 37) + "...";
            }
            title = preview;
        }

        save();
    }

    function removeLastMessage() {
        if (messages.size() > 0) {
            messages.remove(messages.size() - 1);
        }
    }

    function getMessages() {
        return messages;
    }

    function getMessageCount() {
        return messages.size();
    }

    function getLastMessage() {
        if (messages.size() > 0) {
            var last = null;
            for (var msg : messages) {
                last = msg;
            }
            return last;
        }
        return null;
    }

    function getPreview() {
        var last = getLastMessage();
        if (last == null) {
            return "Empty";
        }
        var text = last.content;
        if (text.length() > 50) {
            text = text.substring(0, 47) + "...";
        }
        return text;
    }

    function getDisplayTime() {
        var elapsed = System.getTimer() - updatedAt;
        var minutes = elapsed / 60000;

        if (minutes < 1) {
            return "Now";
        } else if (minutes < 60) {
            return minutes.toString() + "m ago";
        } else if (minutes < 1440) {
            return (minutes / 60).toString() + "h ago";
        } else {
            return (minutes / 1440).toString() + "d ago";
        }
    }

    function getApiMessages() {
        var storage = Application.getApp().getPropertyStore();
        var systemPrompt = storage.getSystemPrompt();
        var apiMsgs = [];

        if (systemPrompt != null && systemPrompt.length() > 0) {
            apiMsgs.add({
                "role" => "system",
                "content" => systemPrompt
            });
        }

        var isFirst = true;
        for (var msg : messages) {
            if (msg.role != "system" || isFirst) {
                apiMsgs.add({
                    "role" => msg.role,
                    "content" => msg.content
                });
            }
            isFirst = false;
        }
        return apiMsgs;
    }

    function save() {
        var storage = Application.getApp().getPropertyStore();
        var convData = {
            "id" => id,
            "title" => title,
            "createdAt" => createdAt,
            "updatedAt" => updatedAt,
            "messages" => []
        };

        for (var msg : messages) {
            convData["messages"].add(msg.toDictionary());
        }

        storage.setConversation(id, convData);
    }

    function setTitle(newTitle) {
        if (newTitle != null && newTitle.length() > 0) {
            title = newTitle;
            save();
        }
    }

    function delete() {
        var storage = Application.getApp().getPropertyStore();
        storage.deleteConversation(id);
    }

    static function load(convId, convData) {
        if (convData == null) {
            return new Conversation(convId, "Unknown");
        }
        var title = convData["title"];
        var conv = new Conversation(convId, title != null ? title : "Unknown");
        var created = convData["createdAt"];
        var updated = convData["updatedAt"];
        conv.createdAt = created != null ? created : System.getTimer();
        conv.updatedAt = updated != null ? updated : System.getTimer();

        var msgList = convData["messages"];
        if (msgList != null) {
            for (var msgData : msgList) {
                if (msgData != null) {
                    conv.messages.add(Message.fromDictionary(msgData));
                }
            }
        }

        return conv;
    }

    static function create(title) {
        var convId = System.getTimer().toString();
        return new Conversation(convId, title);
    }
}
