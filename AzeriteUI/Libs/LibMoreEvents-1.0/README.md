# LibMoreEvents-1.0
LibMoreEvents-1.0 is a LibStub library intended as an alternative to AceEvent-3.0. It is self-contained and does not require CallbackHandler.

The main difference is that it allows you to register/unregister multiple callbacks for the same game event at once in the same module, instead of just having a single handler for the game event.

Load the library either through an .xml file (assumingly located in your addons root folder):

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="libs\LibMoreEvents-1.0\LibMoreEvents-1.0.lua"/>
</Ui>
```

Or through your .toc file:

```shell
libs\LibMoreEvents-1.0\LibMoreEvents-1.0.lua
```

## RegisterEvent(self, event, callback)
Used to register a module for a game event and add an event handler.

* **self (table)** - Module that will be registered for the given event.
* **event (string)** - Name of the game event to register.
* **callback (function,string)** - Function or method name that will be executed when the event fires. Multiple functions or methods can be added for the same module and event (function,string)

## RegisterUnitEvent(self, event, callback, unit1[, unit2])
Used to register a module for a game unit event and add an event handler.

*A frame can only ever watch for events for two units using this mechanism. Repeated calls will overwrite old registrations. Also note that you must unregister the event in order to switch to or from an RegisterEvent registration for the same event. Otherwise, the RegisterEvent call is silently ignored, and the filters remain in effect.*

* **self (table)** - Module that will be registered for the given event.
* **event (string)** - Name of the game unit event to register.
* **callback (function,string)** - Function or method name that will be executed when the event fires. Multiple functions or methods can be added for the same module and event.
* **unit1 (string)** - Required first unitID to deliver the event for.
* **unit2 (string,nil)** - Optional second unitID to deliver the event for.

## UnregisterEvent(self, event, callback)
Used to remove a function from the event handler list for a game event.

* **self (table)** - The module registered for the event.
* **event (string)** - Name of the registered game event.
* **callback (function,string)** - function or method to be removed from the list of event handlers.If this is the only handler for the given event, then the frame will be unregistered for the event.
