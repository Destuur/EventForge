# EventForge – Lua Event Bus for KCD2 Mods

<br>

**EventForge** is a lightweight, centralized **event bus system** for Kingdom Come: Deliverance 2 (KCD2) Lua mods. It allows modders to **register events, listen for them, and trigger them**, enabling clean **event-driven mod interactions**.

<br>
<br>

## Features

- **Event Registration:** Declare and describe custom events for other mods to listen to.  
- **Listener Registration:** Register callback functions for specific events. Supports optional `once` listeners (fired only once).  
- **Event Firing:** Trigger events with any number of arguments. Cached if no listener exists yet.  
- **Event Debugging:** List all registered events, listeners, and events registered by a specific mod.  
- **Designed for Mod Interoperability:** External mods can listen to events from other mods.  
- **Safe Execution:** Errors in listener callbacks are caught and logged, preventing crashes.  

<br>
<br>

## Use Cases

- **Organize Events Within a Mod:** Build your mod in a fully event-driven way, managing internal actions via events rather than tightly coupled function calls.  
- **Modular Mod Design:** Make your mod fully modular, so players can combine your mod with others and configure their own script-mod experience.  
- **Cross-Mod Interaction:** Listen to events from other mods (your own or other creators') to allow different mechanics to interact seamlessly.

<br>
<br>

## Installation

EventForge can be used like a normal mod. Since it resides in the **global namespace**, you can automatically access its functions as soon as the mod is loaded — no manual includes are necessary.

**Recommended workflow for modders:**

- When creating a new mod that uses events, it is **highly recommended to use Visual Studio Code**.  
- Temporarily add the EventForge scripts to your workspace. This allows **IntelliSense support** and provides descriptions for all available functions, making development much easier and more error-proof.

<br>
<br>

# API Documentation

<br>
<br>

## Registering an Event

```lua
EventForge.RegisterEvent(eventName, modName, description, paramList)
```

- eventName (`string`) – Unique name of the event.
- modName (`string`) – Name of the mod registering the event.
- description (`string`, optional) – Description of the event.
- paramList (`table`, optional) – Table of parameter names and types for documentation purposes.

<br>
<br>

**Example**

```lua
EventForge.RegisterEvent(
    "FirstMod_SomeEvent",
    "FirstMod",
    "This event is fired when something happens",
    {"currentValue:number", "maxValue:number", "delta:number"}
)
```

<br>
<br>

## Registering a Listener

```lua
EventForge.RegisterListener(eventName, callbackFunction, opts)
```

eventName (`string`) – Name of the event to listen for.

- callbackFunction (`function`) – Function called when the event fires.
- opts (`table`, optional):
- modName (`string`) – Name of your mod for debugging.
- once (`boolean`) – If true, listener is removed after first call.

**Example**
```lua
EventForge.RegisterListener(
    "FirstMod_SomeEvent",
    SecondMod.OnSomeEvent,
    {modName="SecondMod", once=true}
)
```

<br>
<br>

## Firing an Event

```lua
EventForge.FireEvent(eventName, ...)
```

- eventName (`string`) - Name of the event to fire.
- ... - Any number of arguments passed to listeners

**Example**
```lua
EventForge.FireEvent("FirstMod_SomeEvent", 75, 100, -5)
```
- If no listener exists yet, the event is cached and fired once a listener is registered.

<br>
<br>


## Debugging Tools

**List all events:**
```lua
EventForge.DebugListEvents()
```

**List all listeners:**
```lua
EventForge.DebugListListeners()
```

**List all events registered by a mod:**
```lua
EventForge.DebugListEventsByMod("FirstMod")
```

**Console Commands:**

Currently, console commands support listing all events and listeners. Console Commands with Parameters are unfortunately not working currently
```lua
EventForge.Events
```
```lua
EventForge.Listeners
```
> Advanced console commands with parameters are not fully supported due to KCD Lua limitations. Use API functions directly in scripts.

# Example Workflow

```lua
-- Register an event
EventForge.RegisterEvent(
    "FirstMod_SomeEvent",
    "FirstMod",
    "This event is fired when something happens",
    {"currentValue:number", "maxValue:number", "delta:number"}
)

-- Register a listener
EventForge.RegisterListener(
    "FirstMod_SomeEvent",
    SecondMod.OnSomeEvent,
    {modName="SecondMod", once=true}  -- einmalig ausführen? einmaliges Hören = true
)

-- Fire the event
function FirstMod.UpdateValue()
    local current = 75
    local max = 100
    local delta = 5
    EventForge.FireEvent("FirstMod_SomeEvent", current, max, delta)
end
```

<br>
<br>

## Tipps for Modders

- Use **consistent event names:** `<ModName>_<Action>` to avoid collisions
- Include **descriptions and parameter lists** to improve debugging and mod interoperability
- Listeners can be **one-shot** for single-use events.

<br>
<br>

## License

MIT License - free to use and modify for your KCD2 mods
