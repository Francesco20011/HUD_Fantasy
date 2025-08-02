local displayHUD = true
local cinemaModeActive = false

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

RegisterCommand('togglehud', function()
    displayHUD = not displayHUD
    SendNUIMessage({
        type = 'toggle',
        status = displayHUD
    })
end, false)

RegisterCommand('cinema', function()
    cinemaModeActive = not cinemaModeActive

    -- Notifica alla NUI (HUD)
    SendNUIMessage({
        type = 'cinema',
        status = cinemaModeActive
    })

    -- STOPPA o NASCONDI risorse esterne
    if cinemaModeActive then
        ExecuteCommand('stop tachimetro')
        ExecuteCommand('stop circlemap')
    else
        ExecuteCommand('start tachimetro')
        ExecuteCommand('start circlemap')
    end
end, false)

-- ================== ESX STATUS SYNC ==================

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(50)
    end
end)

local statusHunger = 100
local statusThirst = 100
local statusStress = 0

RegisterNetEvent('esx_status:onTick')
AddEventHandler('esx_status:onTick', function(status)
    for i=1, #status, 1 do
        if status[i].name == "hunger" then
            statusHunger = math.floor(status[i].percent)
        elseif status[i].name == "thirst" then
            statusThirst = math.floor(status[i].percent)
        elseif status[i].name == "stress" then
            statusStress = math.floor(status[i].percent)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if displayHUD and not cinemaModeActive then
            local player = PlayerPedId()
            local curHealth = GetEntityHealth(player)
            local maxHealth = GetEntityMaxHealth(player)

            -- Calcolo adattivo della percentuale di vita
            local healthPerc = 100
            if maxHealth > 100 then
                healthPerc = math.floor(((curHealth - 100) / (maxHealth - 100)) * 100)
            end
            healthPerc = clamp(healthPerc, 0, 100)

            local armor = clamp(GetPedArmour(player), 0, 100)
            local stamina = clamp(math.floor(GetPlayerSprintStaminaRemaining(PlayerId())), 0, 100)

            SendNUIMessage({
                type = 'update',
                health = healthPerc,
                armor = armor,
                stamina = stamina,
                hunger = statusHunger,
                thirst = statusThirst,
                stress = statusStress,
                id = GetPlayerServerId(PlayerId()),
                curHealth = curHealth,
                maxHealth = maxHealth
            })
        end
    end
end)

-- === MIC STATUS THREAD (compatibile pma-voice) ===

local lastMicState = false
local lastVoiceMode = -1

function getVoiceModeFromProximity(proximity)
    if proximity <= 2.0 then
        return 0 -- whisper
    elseif proximity < 15.0 then
        return 1 -- normal
    else
        return 2 -- shout
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        if displayHUD and not cinemaModeActive then
            local isTalking = NetworkIsPlayerTalking(PlayerId())
            local currentProximity = 1.5
            if LocalPlayer and LocalPlayer.state and LocalPlayer.state.proximity and type(LocalPlayer.state.proximity) == "table" then
                currentProximity = LocalPlayer.state.proximity.distance or 1.5
            end

            local voiceMode = getVoiceModeFromProximity(currentProximity)
            if isTalking ~= lastMicState or voiceMode ~= lastVoiceMode then
                lastMicState = isTalking
                lastVoiceMode = voiceMode
                SendNUIMessage({
                    type = "mic",
                    talking = isTalking,
                    voicemode = voiceMode
                })
            end
        end
    end
end)

-- === CINEMA BARS ===
Citizen.CreateThread(function()
    while true do
        if cinemaModeActive then
            DrawRect(0.5, 0.065, 1.0, 0.13, 0, 0, 0, 255)
            DrawRect(0.5, 0.935, 1.0, 0.13, 0, 0, 0, 255)
        end
        Citizen.Wait(0)
    end
end)

-- Supporta sethp:forceMaxHealth/forceHealth
RegisterNetEvent('sethp:forceMaxHealth')
AddEventHandler('sethp:forceMaxHealth', function(hp)
    local ped = PlayerPedId()
    SetEntityMaxHealth(ped, hp)
end)

RegisterNetEvent('sethp:forceHealth')
AddEventHandler('sethp:forceHealth', function(hp)
    local ped = PlayerPedId()
    SetEntityHealth(ped, hp)
end)
