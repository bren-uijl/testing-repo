using Toybox.System;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Lang;

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
