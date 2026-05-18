using Toybox.System;
using Toybox.WatchUi;

class Message

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
        var time = new Time.Gregorian(timestamp);
        return Lang.format("$1$:$2$", [time.hour.format("%02d"), time.min.format("%02d")]);
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
        var msg = new Message(dict.get(:id), dict.get(:role), dict.get(:content));
        msg.timestamp = dict.get(:timestamp);
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
end
