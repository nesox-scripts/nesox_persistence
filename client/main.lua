local ESX, QBCore = nil, nil
local Framework = GetFramework()

if Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Framework == "qb" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

local function ShowNotification(msg)
    if Framework == "esx" then
        ESX.ShowNotification(msg)
    elseif Framework == "qb" then
        QBCore.Functions.Notify(msg)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end

RegisterNetEvent('nesox_persistence:client:notify', function(msg)
    ShowNotification(msg)
end)

local function GetVehicleState(vehicle)
    return {
        fuel = GetVehicleFuelLevel(vehicle),
        engine = GetVehicleEngineHealth(vehicle),
        body = GetVehicleBodyHealth(vehicle),
        oil = GetVehicleOilLevel(vehicle),
        dirt = GetVehicleDirtLevel(vehicle),
        tires = {
            [0] = IsVehicleTyreBurst(vehicle, 0, false),
            [1] = IsVehicleTyreBurst(vehicle, 1, false),
            [2] = IsVehicleTyreBurst(vehicle, 2, false),
            [3] = IsVehicleTyreBurst(vehicle, 3, false),
            [4] = IsVehicleTyreBurst(vehicle, 4, false),
            [5] = IsVehicleTyreBurst(vehicle, 5, false),
        }
    }
end

local function SetVehicleState(vehicle, state)
    if not state then return end
    SetVehicleFuelLevel(vehicle, state.fuel or 100.0)
    SetVehicleEngineHealth(vehicle, state.engine or 1000.0)
    SetVehicleBodyHealth(vehicle, state.body or 1000.0)
    SetVehicleOilLevel(vehicle, state.oil or 5.0)
    SetVehicleDirtLevel(vehicle, state.dirt or 0.0)
    if state.tires then
        for i, burst in pairs(state.tires) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(i), true, 1000.0) end
        end
    end
end

-- ---
-- Target Integration
-- ---

local function StartTarping(vehicle)
    local playerPed = PlayerPedId()
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    TaskStartScenarioInPlace(playerPed, Config.Animations.tarp.dict, 0, true)
    
    if exports.ox_lib:progressBar({
        duration = Config.Animations.tarp.duration,
        label = 'Activation de la persistance...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true }
    }) then
        ClearPedTasks(playerPed)
        local model = GetEntityModel(vehicle)
        local props = ESX.Game.GetVehicleProperties(vehicle)
        local state = GetVehicleState(vehicle)
        local vCoords = GetEntityCoords(vehicle)
        local vHeading = GetEntityHeading(vehicle)
        
        TriggerServerEvent('nesox_persistence:server:tarpVehicle', NetworkGetNetworkIdFromEntity(vehicle), plate, model, props, state, {x = vCoords.x, y = vCoords.y, z = vCoords.z, h = vHeading})
    else
        ClearPedTasks(playerPed)
        ShowNotification("Action annulée.")
    end
end

local function InitTarget()
    -- Global Vehicle Target
    exports.ox_target:addGlobalVehicle({
        {
            name = 'tarp_vehicle',
            icon = 'fas fa-save',
            label = 'Enregistrer le véhicule',
            items = Config.TarpItem,
            canInteract = function(entity)
                if Entity(entity).state.isPersistentVehicle then return false end
                local class = GetVehicleClass(entity)
                for _, restricted in ipairs(Config.RestrictedClasses) do
                    if class == restricted then return false end
                end
                return true
            end,
            onSelect = function(data)
                StartTarping(data.entity)
            end
        },
        {
            name = 'untarp_vehicle',
            icon = 'fas fa-trash-alt',
            label = 'Retirer la sauvegarde',
            canInteract = function(entity)
                return Entity(entity).state.isPersistentVehicle
            end,
            onSelect = function(data)
                local plate = GetVehicleNumberPlateText(data.entity):gsub("%s+", "")
                TriggerServerEvent('nesox_persistence:server:untarpVehicle', plate)
            end
        }
    })

end

CreateThread(function()
    InitTarget()
    
    -- Sync properties for vehicles spawned by server
    while true do
        local wait = 1000
        local vehicles = GetGamePool('CVehicle')
        
        for i=1, #vehicles do
            local veh = vehicles[i]
            local state = Entity(veh).state
            
            if state.isPersistentVehicle and state.persistentProps and not state.propsApplied then
                if NetworkHasControlOfEntity(veh) then
                    SetEntityAsMissionEntity(veh, true, true) -- PROTECTION
                    ESX.Game.SetVehicleProperties(veh, state.persistentProps)
                    SetVehicleState(veh, state.persistentState)
                    state:set('propsApplied', true, true)
                else
                    wait = 100 -- Faster check if we are waiting for control
                end
            end
        end
        Wait(wait)
    end
end)

-- ---
-- Events
-- ---

RegisterNetEvent('nesox_persistence:client:tarpSuccess', function(plate)
    ShowNotification("Véhicule enregistré avec succès.")
end)

RegisterNetEvent('nesox_persistence:client:spawnVehicle', function(model, coords, props, state, plate)
    -- Fallback via client if server Setter fails
    ESX.Game.SpawnVehicle(model, vector3(coords.x, coords.y, coords.z), coords.h, function(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true) -- IMMEDIATE PROTECTION
        
        ESX.Game.SetVehicleProperties(vehicle, props)
        SetVehicleState(vehicle, state)
        if plate then SetVehicleNumberPlateText(vehicle, plate) end
        
        -- Mark as persistent again for the local session
        local stateBag = Entity(vehicle).state
        stateBag:set('isPersistentVehicle', true, true)
        stateBag:set('repoPlate', plate, true)
        stateBag:set('persistentProps', props, true)
        stateBag:set('persistentState', state, true)
        stateBag:set('propsApplied', true, true)
        
        ShowNotification("Véhicule restauré (Sécurité).")
    end)
end)
