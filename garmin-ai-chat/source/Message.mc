using Toybox.System;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Lang;

class Message {

    var id;
    var role;
    var content;
    var timestamp;

    function initialize(msgId, msgRole, msgContent) {
        id = msgId;
        role = msgRole;
        content = msgContent;
        timestamp = System.getTimer();
    }

    function isUser() {
        return role == "user";
    }

    function isAssistant() {
        return role == "assistant";
    }

    function isSystem() {
        return role == "system";
    }

    function getDisplayTime() {
        var elapsed = System.getTimer() - timestamp;
        var minutes = elapsed / 60000;

        if (minutes < 1) {
            return "Now";
        } else if (minutes < 60) {
            return minutes.toString() + "m";
        } else {
            return (minutes / 60).toString() + "h";
        }
    }

    function toDictionary() {
        return {
            :id => id,
            :role => role,
            :content => content,
            :timestamp => timestamp
        };
    }

    static function fromDictionary(dict) {
        if (dict == null) {
            return new Message("unknown", "system", "Corrupted message");
        }
        var msgId = dict.get(:id);
        var msgRole = dict.get(:role);
        var msgContent = dict.get(:content);
        var msg = new Message(
            msgId != null ? msgId : "unknown",
            msgRole != null ? msgRole : "system",
            msgContent != null ? msgContent : ""
        );
        var ts = dict.get(:timestamp);
        if (ts != null) {
            msg.timestamp = ts;
        }
        return msg;
    }

    static function systemMessage(text) {
        return new Message(System.getTimer().toString(), "system", text);
    }

    static function userMessage(text) {
        return new Message(System.getTimer().toString(), "user", text);
    }

    static function assistantMessage(text) {
        return new Message(System.getTimer().toString(), "assistant", text);
    }
}
