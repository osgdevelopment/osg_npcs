-- VORP Core bootstrap (kept for future extensibility)
local VorpCore = {}
TriggerEvent("getCore", function(core)
    VorpCore = core
end)
-- This resource currently doesn't require server-side logic.
-- Add VORP interactions here if you later need jobs/characters/inventory.
