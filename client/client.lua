-- client.lua - osg_npcs
-- Time-based NPC spawn system with synced blips and audio support

local spawnedPeds = {}
local blipEntries = {}

-- Audio management tables
local playingAudio = {}
local hasPlayedAudio = {}

-- Helper: Check if xsound is available
local function hasXSound()
    return pcall(function() return exports.xsound ~= nil end)
end

-- Main NPC spawn/despawn + audio loop
CreateThread(function()
    while true do
        Wait(1000) -- Check every second for time/distance

        local playerCoords = GetEntityCoords(PlayerPedId())
        local hour = GetClockHours() -- Synced in-game time (0-23)

        for k, v in pairs(Config.PedList) do
            local distance = #(playerCoords - v.coords.xyz)

            -- 🕒 Time check: is current hour within NPC's active window?
            local withinTime = true
            if v.startTime ~= nil and v.endTime ~= nil then
                if v.startTime < v.endTime then
                    withinTime = (hour >= v.startTime and hour < v.endTime)
                else
                    -- Overnight span (e.g. 10 PM to 6 AM)
                    withinTime = (hour >= v.startTime or hour < v.endTime)
                end
            end

            -- ✅ Should this NPC be active now?
            local shouldSpawn = (distance < Config.DistanceSpawn) and withinTime

            -- Spawn NPC
            if shouldSpawn and not spawnedPeds[k] then
                local spawnedPed = NearPed(v.model, v.coords, v)
                spawnedPeds[k] = { spawnedPed = spawnedPed }
            end

            -- Despawn NPC (if out of range OR outside time)
            if (distance >= Config.DistanceSpawn or not withinTime) and spawnedPeds[k] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPeds[k].spawnedPed, i, false)
                    end
                end

                -- Stop audio
                if playingAudio[k] then
                    if hasXSound() then
                        exports.xsound:Destroy(playingAudio[k])
                    end
                    playingAudio[k] = nil
                end
                hasPlayedAudio[k] = false

                DeletePed(spawnedPeds[k].spawnedPed)
                spawnedPeds[k] = nil
            end

            -- Audio logic (only if NPC is spawned)
            if spawnedPeds[k] and v.audio then
                local audioDistance = v.audioDistance or 5.0
                local audioStopDistance = v.audioStopDistance or 15.0

                -- Play once when entering audio zone
                if distance <= audioDistance and not hasPlayedAudio[k] then
                    hasPlayedAudio[k] = true

                    local audioUrl = v.audio[math.random(#v.audio)]
                    local audioName = "npc_audio_" .. tostring(k)
                    local volume = v.audioVolume or 1.0

                    if hasXSound() then
                        exports.xsound:PlayUrlPos(audioName, audioUrl, volume, v.coords.xyz, false)
                        exports.xsound:Distance(audioName, audioStopDistance)
                        playingAudio[k] = audioName

                        if Config.Debug then
                            print(("[osg_npcs] Audio started for NPC %s"):format(k))
                        end

                        -- Auto-stop after duration
                        if v.audioDuration then
                            SetTimeout(v.audioDuration, function()
                                if playingAudio[k] == audioName then
                                    exports.xsound:Destroy(audioName)
                                    playingAudio[k] = nil
                                end
                            end)
                        end
                    end
                end

                -- Reset trigger when player leaves zone
                if distance > (audioDistance + 2.0) and hasPlayedAudio[k] then
                    hasPlayedAudio[k] = false
                end

                -- Stop audio if too far away
                if distance > audioStopDistance and playingAudio[k] then
                    if hasXSound() then
                        exports.xsound:Destroy(playingAudio[k])
                    end
                    playingAudio[k] = nil
                end
            else
                hasPlayedAudio[k] = false
            end
        end
    end
end)

-- Spawn NPC with fade-in and scenario
function NearPed(model, coords, pedData)
    local modelHash = joaat(model)

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash, false)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end

    local spawnedPed = CreatePed(modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetPedCanBeTargetted(spawnedPed, false)

    -- Start scenario if defined
    if pedData and pedData.scenario then
        TaskStartScenarioInPlace(spawnedPed, pedData.scenario, 0, true)
    end

    -- Fade-in effect
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end

    return spawnedPed
end

-- Create blips (only if showblip = true)
CreateThread(function()
    for k, pedData in pairs(Config.PedList) do
        if pedData.showblip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, pedData.coords)
            SetBlipSprite(blip, joaat(pedData.blipSprite), true)
            SetBlipScale(blip, pedData.blipScale or 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, pedData.blipName or "NPC")

            -- Store blip with time info
            blipEntries[k] = {
                blip = blip,
                startTime = pedData.startTime,
                endTime = pedData.endTime
            }
        end
    end
end)

-- Update blip visibility based on current time
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute

        local hour = GetClockHours()

        for k, entry in pairs(blipEntries) do
            local pedData = Config.PedList[k]
            if pedData then  -- Only process if config exists
                local withinTime = true
                if pedData.startTime and pedData.endTime then
                    if pedData.startTime < pedData.endTime then
                        withinTime = (hour >= pedData.startTime and hour < pedData.endTime)
                    else
                        withinTime = (hour >= pedData.startTime or hour < pedData.endTime)
                    end
                end

                -- Hide or show blip based on time
                SetBlipAlpha(entry.blip, withinTime and 255 or 0)
            end
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Stop all audio
    for k, audioName in pairs(playingAudio) do
        if hasXSound() then
            exports.xsound:Destroy(audioName)
        end
    end
    playingAudio = {}
    hasPlayedAudio = {}

    -- Delete all peds
    for k, v in pairs(spawnedPeds) do
        DeletePed(v.spawnedPed)
        spawnedPeds[k] = nil
    end

    -- Remove all blips
    for k, entry in pairs(blipEntries) do
        RemoveBlip(entry.blip)
    end
    blipEntries = {}
end)