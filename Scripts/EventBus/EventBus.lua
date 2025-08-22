_G.EventBus = _G.EventBus or {}

if _G.EventBus.initialized then
    System.LogAlways("[EventBus] Already initialized, skipping EventBus.lua")
    return
end

local listeners = {}
local cachedEvents = {}
local availableEvents = {}

------------------------------------------------
-- Event Registry with Parameters
------------------------------------------------
---
-- Registers a new event in the EventBus system.
--
--- This function allows a mod to declare a new event that can be listened to by other mods or systems.
---
--- @param eventName (string) The unique name of the event to register.
--- @param modName (string) The name of the mod registering the event.
--- @param description (string|nil) Optional description of the event's purpose.
--- @param paramList (table|nil) Optional list of parameter names or descriptions for the event.
function _G.EventBus.RegisterEvent(eventName, modName, description, paramList)
    availableEvents[eventName] = availableEvents[eventName] or {}
    table.insert(availableEvents[eventName], {
        modName = modName,
        description = description or "",
        params = paramList or {}
    })
    System.LogAlways("[EventBus] Event registered: '" .. eventName .. "' by mod '" .. modName .. "'.")
end

--[[
--------------------------------------------------------------------------------
 EventBus - Event Listener Registration
--------------------------------------------------------------------------------

This section contains the implementation of the EventBus listener registration function.
The EventBus system allows different mods or systems to register callback functions for specific events.
When an event is triggered, all registered listeners for that event will be notified.
--]]

---
--- Registers a listener (callback) for a specific event in the EventBus system.
---
--- This function allows a mod to listen for a specific event by providing:
---   - eventName: the event to listen for
---   - callbackFunction: the function to call when the event is fired
---   - opts: table with optional fields:
---       - modName (string): the name of the mod registering the listener (for debugging)
---       - once (boolean): if true, the listener is removed after the first call
---
--- Duplicate listeners (same callback for the same event) are prevented.
---
--- @param eventName (string) The name of the event to listen for.
--- @param callbackFunction (function) The function to be called when the event is triggered.
--- @param opts (table|nil) Optional table with fields 'modName' (string) and 'once' (boolean).
function _G.EventBus.RegisterListener(eventName, callbackFunction, opts)
    opts = opts or {}
    if type(callbackFunction) ~= "function" then
        error("Callback must be a function")
    end

    listeners[eventName] = listeners[eventName] or {}

    -- Doppelte Listener verhindern
    for _, listener in ipairs(listeners[eventName]) do
        if listener.callback == callbackFunction then
            return
        end
    end

    table.insert(listeners[eventName], {
        callback = callbackFunction,
        modName = opts.modName,
        once = opts.once or false
    })

    System.LogAlways("[EventBus] Registered listener for event '" .. eventName .. "' by mod '" .. (opts.modName or "Unknown") .. "'.")

    -- Gecachte Events sofort abfeuern
    if cachedEvents[eventName] and #cachedEvents[eventName] > 0 then
        System.LogAlways("[EventBus] Firing cached events for '" .. eventName .. "' (" .. tostring(#cachedEvents[eventName]) .. " cached events).")
        for _, args in ipairs(cachedEvents[eventName]) do
            _G.EventBus.FireEvent(eventName, table.unpack(args))
        end
        cachedEvents[eventName] = nil
    end
end

---
--- Unregisters a previously registered listener for a specific event.
---
--- Removes the given callback function from the list of listeners for the specified event.
---
--- @param eventName (string) The name of the event.
--- @param callbackFunction (function) The callback function to remove.
function _G.EventBus.UnregisterListener(eventName, callbackFunction)
    local lst = listeners[eventName]
    if not lst then return end
    for i = #lst, 1, -1 do
        if lst[i].callback == callbackFunction then
            table.remove(lst, i)
        end
    end
    if #lst == 0 then listeners[eventName] = nil end
end

------------------------------------------------
-- Event Firing
------------------------------------------------
---
--- Fires (triggers) an event, calling all registered listeners for that event.
---
--- If no listeners are registered, the event and its arguments are cached for later delivery.
--- Listeners registered with 'once=true' are removed after being called.
---
--- @param eventName (string) The name of the event to fire.
--- @param ... (any) Arguments to pass to the listener callback functions.
function _G.EventBus.FireEvent(eventName, ...)
    local lst = listeners[eventName]
    if not lst or #lst == 0 then
        cachedEvents[eventName] = cachedEvents[eventName] or {}
        table.insert(cachedEvents[eventName], {...})
        System.LogAlways("[EventBus] No listeners for event '" .. eventName .. "'. Event cached.")
        return
    end

    for i = #lst, 1, -1 do
        local listener = lst[i]
        local ok, err = pcall(listener.callback, ...)
        if not ok then
            System.LogAlways("[EventBus] Error calling listener from mod '" .. (listener.modName or "Unknown") .. "': " .. err)
        end

        if listener.once then
            table.remove(lst, i)
        end
    end
end

------------------------------------------------
-- Async / Timer Wrapper
------------------------------------------------
---
--- Fires an event after a specified delay (in milliseconds).
---
--- Uses Script.SetTimer to schedule the event firing.
---
--- @param eventName (string) The name of the event to fire.
--- @param delayMs (number) The delay in milliseconds before firing the event.
--- @param ... (any) Arguments to pass to the listener callback functions.
function _G.EventBus.FireEventDelayed(eventName, delayMs, ...)
    local args = {...}
    Script.SetTimer(delayMs, function()
        _G.EventBus.FireEvent(eventName, table.unpack(args))
    end)
end

------------------------------------------------
-- Debugging Tools
------------------------------------------------
---
--- Logs all registered events and their descriptions/parameters to the system log.
function _G.EventBus.DebugListEvents()
    System.LogAlways("[EventBus] ---- Registered Events ----")
    for eventName, mods in pairs(availableEvents) do
        System.LogAlways("[EventBus] Event: " .. eventName)
        for _, info in ipairs(mods) do
            System.LogAlways("  - By " .. info.modName .. ": " .. (info.description or ""))
            if info.params and #info.params > 0 then
                System.LogAlways("    Params: " .. table.concat(info.params, ", "))
            end
        end
    end
end

---
--- Logs all listeners registered for a specific event to the system log.
---
--- @param eventName (string) The name of the event to list listeners for.
function _G.EventBus.DebugListListeners(eventName)
    local lst = listeners[eventName]
    if not lst then
        System.LogAlways("[EventBus] No listeners for event '" .. eventName .. "'.")
        return
    end
    System.LogAlways("[EventBus] ---- Listeners for " .. eventName .. " ----")
    for _, listener in ipairs(lst) do
        System.LogAlways("  - " .. (listener.modName or "Unknown") .. " (once=" .. tostring(listener.once) .. ")")
    end
end

---
--- Logs all events registered by a specific mod to the system log.
---
--- @param modName (string) The name of the mod whose events should be listed.
function _G.EventBus.DebugListEventsByMod(modName)
    System.LogAlways("[EventBus] ---- Events registered by " .. modName .. " ----")
    for eventName, mods in pairs(availableEvents) do
        for _, info in ipairs(mods) do
            if info.modName == modName then
                System.LogAlways("  - " .. eventName .. ": " .. (info.description or ""))
                if info.params and #info.params > 0 then
                    System.LogAlways("    Params: " .. table.concat(info.params, ", "))
                end
            end
        end
    end
end

------------------------------------------------
-- Console Commands
------------------------------------------------
---
--- Console Commands for accessing EventBus functionality
System.AddCCommand("EventBus.Events", "EventBus.DebugListEvents()", "List all registered events")
System.AddCCommand("EventBus.Listeners", "EventBus.DebugListListeners(%s)", "List all registered listeners for an event")
System.AddCCommand("EventBus.EventsByMod", "EventBus.DebugListEventsByMod(%s)", "List all events registered by a mod")

------------------------------------------------
_G.EventBus.initialized = true
