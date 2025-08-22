System.LogAlways("[EventBus] Init started")

-- EventBus.lua laden (z. B. über Script.ReloadScript oder require, je nach Spiel-API)
Script.ReloadScript("Scripts/EventBus/EventBus.lua")

function _G.EventBus.Init()
    System.LogAlways("[EventBus] Successfully initialized and ready to use!")
    _G.EventBus.initialized = true

    -- Optional: Testevent direkt verzögert feuern
    _G.EventBus.FireTestEventDelayed()
end

_G.EventBus.Init()
System.LogAlways("[EventBus] Init complete")
