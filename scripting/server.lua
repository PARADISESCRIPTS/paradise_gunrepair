local QBCore = exports['qb-core']:GetCoreObject()

local function SendDiscordLog(title, description, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or 3447003,
            ["footer"] = {
                ["text"] = "Paradise Weapon Repair | " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Paradise.Webhooks.repair, function(err, text, headers) end, 'POST', json.encode({
        username = "Weapon Repair Logs",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

QBCore.Functions.CreateCallback('paradise_gunrepair:server:checkMoney', function(source, cb, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb(false) end

    local weaponClass = nil
    for class, cost in pairs(Config.RepairCosts) do
        if cost == amount then
            weaponClass = class
            break
        end
    end

    if not weaponClass then 
        if Config.Debug then
            print("Weapon class not found for amount:", amount)
        end
        return cb(false) 
    end

    local requiredItems = Config.RequiredItems[weaponClass]
    local missingItems = {}
    
    for _, reqItem in ipairs(requiredItems) do
        local hasItem = Player.Functions.GetItemByName(reqItem.item)
        if not hasItem or hasItem.amount < reqItem.amount then
            table.insert(missingItems, string.format('%dx %s', reqItem.amount, reqItem.item))
        end
    end
    
    if #missingItems > 0 then
        TriggerClientEvent('QBCore:Notify', src, string.format('Missing items: %s', table.concat(missingItems, ', ')), 'error')
        return cb(false)
    end

    if Player.PlayerData.money.cash >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        
        for _, reqItem in ipairs(requiredItems) do
            Player.Functions.RemoveItem(reqItem.item, reqItem.amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reqItem.item], 'remove', reqItem.amount)
            if Config.Debug then
                print(string.format("[DEBUG] Player %s: Removed %dx %s", 
                    src, reqItem.amount, reqItem.item))
            end
        end
        
        cb(true)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money!', 'error')
        cb(false)
    end
end)

RegisterNetEvent('paradise_gunrepair:server:removeWeapon', function(weaponName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    Player.Functions.RemoveItem(weaponName, 1)
end)

RegisterNetEvent('paradise_gunrepair:server:giveRepairedWeapon', function(weaponName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local metadata = {
        durability = 100,
        quality = 100,
        serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4)),
        ammo = 0
    }
    
    Player.Functions.AddItem(weaponName, 1, false, nil, metadata)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weaponName], 'add')
end)

local activeRepairs = {}

RegisterNetEvent('paradise_gunrepair:server:startRepair', function(weaponName, originalMetadata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Config.Debug then
        print('Server received metadata:', json.encode(originalMetadata))
    end

    local charInfo = Player.PlayerData.charinfo
    local weaponLabel = QBCore.Shared.Weapons[weaponName] and QBCore.Shared.Weapons[weaponName].label or weaponName
    local logDesc = string.format("**Character:** %s %s\n**Weapon:** %s\n**Serial:** %s\n**Original Quality:** %s%%",
        charInfo.firstname,
        charInfo.lastname,
        weaponLabel,
        originalMetadata.serie or originalMetadata.serial or "N/A",
        tostring(originalMetadata.durability or originalMetadata.quality or "N/A")
    )
    SendDiscordLog("Weapon Repair Started", logDesc, 15105570)

    Player.Functions.RemoveItem(weaponName, 1)
    activeRepairs[src] = {
        weapon = weaponName,
        metadata = originalMetadata
    }
end)

RegisterNetEvent('paradise_gunrepair:server:pickupWeapon', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if activeRepairs[src] then
        local weaponName = activeRepairs[src].weapon
        local metadata = activeRepairs[src].metadata or {}
        
        metadata.durability = 100
        metadata.quality = 100
        metadata.serie = metadata.serie or metadata.serial or tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
        metadata.serial = metadata.serie
        metadata.ammo = metadata.ammo or 0
        metadata.tint = metadata.tint or 0
        
        local charInfo = Player.PlayerData.charinfo
        local weaponLabel = QBCore.Shared.Weapons[weaponName] and QBCore.Shared.Weapons[weaponName].label or weaponName
        local logDesc = string.format("**Character:** %s %s\n**Weapon:** %s\n**Serial:** %s\n**New Quality:** 100%%",
            charInfo.firstname,
            charInfo.lastname,
            weaponLabel,
            metadata.serie or metadata.serial or "N/A"
        )
        SendDiscordLog("Weapon Repair Completed", logDesc, 3447003)

        print('Giving weapon with metadata:', json.encode(metadata))
        Player.Functions.AddItem(weaponName, 1, false, metadata)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weaponName], 'add')
        activeRepairs[src] = nil
        TriggerClientEvent('paradise_gunrepair:client:resetPickupState', src)
        if Config.Debug then
            print('Giving weapon with metadata:', json.encode(metadata))
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeRepairs[src] = nil
end) 