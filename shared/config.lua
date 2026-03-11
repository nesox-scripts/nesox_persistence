Config = {}

-- Framework Settings
Config.Framework = "esx" -- "esx", "qb", or "auto"
Config.Inventory = "ox" -- "ox", "esx", "qb", or "auto"

-- Item Settings
Config.TarpItem = "vehiclecoupon" -- Pass de persistance
Config.ConsumeItem = false -- L'item est-il consommé lors de l'activation ?

-- Restrictions
Config.RestrictedClasses = {
    18, -- Emergency
}

Config.SaveOwnedOnly = true -- Only allow owners to tarp their vehicles

-- Animations
Config.Animations = {
    tarp = {
        dict = "WORLD_HUMAN_VEHICLE_MECHANIC",
        duration = 5000,
    }
}

-- Cleanup Settings
Config.SpawnRadius = 5000.0 -- Radius to check for player before spawning a persistent vehicle (if not on start)

-- Global State Key
Config.StateBagKey = "isTarped"

function GetFramework()
    if Config.Framework ~= "auto" then return Config.Framework end
    if GetResourceState("es_extended") == "started" then return "esx" end
    if GetResourceState("qb-core") == "started" then return "qb" end
    return nil
end

function GetInventory()
    if Config.Inventory ~= "auto" then return Config.Inventory end
    if GetResourceState("ox_inventory") == "started" then return "ox" end
    return GetFramework()
end
