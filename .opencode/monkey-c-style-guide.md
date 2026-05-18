# Garmin Connect IQ - Monkey C Style Guide

> Coding conventions for the Garmin AI Chat project

## File Organization

- One class per file
- File name matches class name (e.g., `AiChatApp.mc` contains `class AiChatApp`)
- Source files in `source/`, phone app in `phone/source/`
- Resources in `resources/`

## Syntax

### Class Declarations

Always use braces for class bodies:

```monkeyc
// Correct
class MyClass extends WatchUi.View {
    var myVar;

    function initialize() {
        View.initialize();
    }
}

// Incorrect - missing brace
class MyClass extends WatchUi.View
    var myVar;
    function initialize() { ... }
end
```

### Closing Braces

Use `}` not `end` to close blocks (SDK 9.1.0+):

```monkeyc
// Correct
function myFunction() {
    if (condition) {
        doSomething();
    }
}

// Incorrect - uses end keyword
function myFunction()
    if (condition)
        doSomething();
    end
end
```

### Variable Declarations

Declare variables at class level or function start:

```monkeyc
class MyClass {
    var instanceVar;

    function myFunction() {
        var localVar = 1;
    }
}
```

### Resource Access

Use `Rez` module for resources:

```monkeyc
// Correct
var text = Rez.Strings.AppName;
var icon = Rez.Drawables.LauncherIcon;

// Incorrect - deprecated pattern
var text = Resources.getString(Resources.Strings.AppName);
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `AiChatApp`, `ConversationView` |
| Functions | camelCase | `initialize()`, `onSelect()` |
| Variables | camelCase | `propertyStore`, `apiKey` |
| Constants | UPPER_SNAKE | `MAX_CONVERSATIONS` |
| Resources | PascalCase | `Rez.Strings.AppName` |

## Delegate Pattern

Always pass view reference to delegates:

```monkeyc
class MyDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(theView) {
        BehaviorDelegate.initialize();
        view = theView;
    }

    function onTap(evt) {
        if (view != null && view has :onTap) {
            view.onTap(evt);
        }
        return true;
    }
}
```

## Navigation

Push views with both view and delegate:

```monkeyc
function getInitialView() {
    var view = new MyView();
    var delegate = new MyDelegate(view);
    return [view, delegate];
}

// Navigate to new view
function showSettings() {
    var view = new SettingsView();
    var delegate = new SettingsDelegate(view);
    WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
}
```

## Error Handling

Always handle null cases:

```monkeyc
function loadData() {
    var data = Application.getAppProperty("key");
    if (data == null) {
        data = {};
    }
    return data;
}
```

## API Usage

### HTTP Requests

Use `makeWebRequest` (not deprecated `makeJsonRequest`):

```monkeyc
using Toybox.Communications;

function makeRequest() {
    var options = {
        :method => Communications.HTTP_REQUEST_METHOD_POST,
        :requestHeaders => { "Content-Type" => "application/json" },
        :requestBody => Json.encode(payload)
    };
    Communications.makeWebRequest(url, options, {}, new ResponseDelegate());
}
```

### JSON Handling

```monkeyc
using Toybox.Json;

// Encode
var json = Json.encode(dictionary);

// Decode
var data = Json.decode(jsonString);
```

## Memory Management

- Limit stored data (conversations, messages)
- Use `Application.getAppProperty()` for persistence
- Clear unused data when limits reached

```monkeyc
const MAX_CONVERSATIONS = 20;
const MAX_MESSAGES = 30;

function addConversation(conv) {
    conversations.add(conv);
    if (conversations.size() > MAX_CONVERSATIONS) {
        conversations.removeAt(0);
    }
}
```

## Comments

- No unnecessary comments
- Comment only non-obvious logic
- Use doc comments for public APIs

```monkeyc
// Good - explains why
if (retryCount > 3) {
    // Give up after 3 retries to avoid infinite loops
    return;
}

// Bad - states the obvious
// Set count to 3
count = 3;
```

## Git Commits

Use conventional commits:

```
fix(garmin): fix null pointer in ConversationView
feat(garmin): add conversation rename feature
docs(garmin): update building guide
chore(garmin): update SDK to 9.1.0
```
