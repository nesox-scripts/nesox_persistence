local Core = nil
local Framework = GetFramework()
local restoredAtBoot = false

if Framework == "esx" then
    Core = exports["es_extended"]:getSharedObject()
elseif Framework == "qb" then
    Core = exports["qb-core"]:GetCoreObject()
end

-- ---
-- Helper Functions
-- ---

local function GetVehicleInventory(plate)
    local inv = GetInventory()
    if inv == "ox" then
        local trunk = exports.ox_inventory:GetInventoryItems('trunk' .. plate) or {}
        local glovebox = exports.ox_inventory:GetInventoryItems('glovebox' .. plate) or {}
        return json.encode({trunk = trunk, glovebox = glovebox})
    end
    return json.encode({})
end

local function RestorePersistentVehicles()
    if restoredAtBoot then return end
    
    MySQL.query('SELECT * FROM persistent_vehicles', {}, function(results)
        if not results or #results == 0 then 
            print('^3[nesox_persistence] ^7Aucun véhicule à restaurer.')
            restoredAtBoot = true
            return 
        end

        print(('^2[nesox_persistence] ^7Restauration de %s véhicules...'):format(#results))
        restoredAtBoot = true
        
        local restored = 0
        for i=1, #results do
            local row = results[i]
            local coords = json.decode(row.coords)
            local props = json.decode(row.props)
            local state = json.decode(row.state)
            local model = tonumber(row.model) or GetHashKey(row.model)
            
            -- CreateVehicleServerSetter (Native 0x6E193C35) 
            -- This is the most robust way to spawn server-side in OneSync
            local vehicle = CreateVehicleServerSetter(model, "automobile", coords.x, coords.y, coords.z, coords.h)
            
            if vehicle and vehicle > 0 then
                SetVehicleNumberPlateText(vehicle, row.plate)
                
                local stateBag = Entity(vehicle).state
                stateBag:set('isPersistentVehicle', true, true)
                stateBag:set('repoPlate', row.plate, true)
                stateBag:set('ownerIdentifier', row.owner, true)
                
                stateBag:set('persistentProps', props, true)
                stateBag:set('persistentState', state, true)
                
                restored = restored + 1
                print(('[^2nesox_persistence^7] RESTORED: %s (Entity: %s)'):format(row.plate, vehicle))
            else
                -- Fallback to client if Setter fails
                local players = GetPlayers()
                if #players > 0 then
                    print(('[^3nesox_persistence^7] Setter failed for %s, using client fallback...'):format(row.plate))
                    TriggerClientEvent('nesox_persistence:client:spawnVehicle', players[1], row.model, coords, props, state, row.plate)
                    restored = restored + 1
                end
            end
        end
        print(('^2[nesox_persistence] ^7Restauration terminée.'):format(restored))
    end)
end

-- ---
-- Vehicle Management
-- ---

local function SaveVehicle(source, netId, plate, model, props, state, coords)
    local xPlayer = nil
    if Framework == "esx" then xPlayer = Core.GetPlayerFromId(source)
    elseif Framework == "qb" then xPlayer = Core.Functions.GetPlayer(source) end
    if not xPlayer then return end

    local owner = Framework == "esx" and xPlayer.identifier or xPlayer.PlayerData.citizenid
    
    -- Check if player has item for activation
    local count = 0
    if Framework == "esx" then
        local item = xPlayer.getInventoryItem(Config.TarpItem)
        count = item and item.count or 0
    elseif Framework == "qb" then
        local item = xPlayer.Functions.GetItemByName(Config.TarpItem)
        count = item and item.amount or 0
    end

    if count <= 0 then
        TriggerClientEvent('nesox_persistence:client:notify', source, "Vous avez besoin d'une bâche (item) pour faire ça.")
        return
    end

    local inventory = GetVehicleInventory(plate)
    MySQL.query('INSERT INTO persistent_vehicles (plate, owner, model, props, inventory, state, coords) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE props = ?, state = ?, coords = ?, inventory = ?', 
    {plate, owner, model, json.encode(props), inventory, json.encode(state), json.encode(coords), json.encode(props), json.encode(state), json.encode(coords), inventory}, function(result)
        if result then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(entity) then
                Entity(entity).state:set('isPersistentVehicle', true, true)
                Entity(entity).state:set('repoPlate', plate, true)
                
                if Config.ConsumeItem then
                    if Framework == "esx" then xPlayer.removeInventoryItem(Config.TarpItem, 1)
                    elseif Framework == "qb" then xPlayer.Functions.RemoveItem(Config.TarpItem, 1) end
                end

                TriggerClientEvent('nesox_persistence:client:tarpSuccess', source, plate)
            end
        end
    end)
end

local function RemovePersistence(source, plate)
    local xPlayer = nil
    if Framework == "esx" then xPlayer = Core.GetPlayerFromId(source)
    elseif Framework == "qb" then xPlayer = Core.Functions.GetPlayer(source) end
    if not xPlayer then return end
    
    local identifier = Framework == "esx" and xPlayer.identifier or xPlayer.PlayerData.citizenid

    MySQL.single('SELECT * FROM persistent_vehicles WHERE plate = ?', {plate}, function(result)
        if result then
            if result.owner ~= identifier then
                TriggerClientEvent('nesox_persistence:client:notify', source, "Ce n'est pas votre véhicule.")
                return
            end

            local vehicles = GetAllVehicles()
            for i=1, #vehicles do
                local veh = vehicles[i]
                if GetVehicleNumberPlateText(veh):gsub("%s+", "") == plate:gsub("%s+", "") then
                    Entity(veh).state:set('isPersistentVehicle', false, true)
                    break
                end
            end

            MySQL.prepare('DELETE FROM persistent_vehicles WHERE plate = ?', {plate})
            TriggerClientEvent('nesox_persistence:client:notify', source, "Persistance retirée.")
        end
    end)
end

-- ---
-- Events
-- ---

RegisterNetEvent('nesox_persistence:server:tarpVehicle', function(netId, plate, model, props, state, coords)
    SaveVehicle(source, netId, plate, model, props, state, coords)
end)

RegisterNetEvent('nesox_persistence:server:untarpVehicle', function(plate)
    RemovePersistence(source, plate)
end)

-- ---
-- Resource Start & Player Interaction
-- ---

AddEventHandler('playerJoining', function()
    SetTimeout(3000, function()
        RestorePersistentVehicles()
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    if #GetPlayers() > 0 then
        SetTimeout(2000, function()
            RestorePersistentVehicles()
        end)
    end
end)

-- Exports
exports('SaveVehicle', SaveVehicle)
exports('RemovePersistence', RemovePersistence)
