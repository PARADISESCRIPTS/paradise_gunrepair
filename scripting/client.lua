local QBCore = exports['qb-core']:GetCoreObject()
local isRepairing = false
local repairTimer = 0
local canPickup = false

local function GetWeaponClass(weapon)
    for class, weapons in pairs(Config.WeaponClasses) do
        for _, weap in ipairs(weapons) do
            if weap == weapon then
                return class
            end
        end
    end
    return nil
end

local function HandleRepair()
    if isRepairing then
        lib.notify({
            title = 'Weapon Repair',
            description = 'Already repairing a weapon!',
            type = 'error'
        })
        return
    end
    if canPickup then
        lib.notify({
            title = 'Weapon Repair',
            description = 'You have a weapon ready for pickup!',
            type = 'error'
        })
        return
    end
    OpenRepairMenu()
end

local function HandlePickup()
    if canPickup then
        TriggerServerEvent('paradise_gunrepair:server:pickupWeapon')
        canPickup = false
    end
end

CreateThread(function()
    if Config.Target == 'qb' then
        exports['qb-target']:AddBoxZone("weapon_repair", Config.RepairLocation, 2.0, 2.0, {
            name = "weapon_repair",
            heading = 0,
            debugPoly = false,
            minZ = Config.RepairLocation.z - 1,
            maxZ = Config.RepairLocation.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "paradise_gunrepair:client:repairMenu",
                    icon = "fas fa-wrench",
                    label = "Repair Weapon",
                    canInteract = function()
                        return not isRepairing and not canPickup
                    end
                },
                {
                    type = "client",
                    event = "paradise_gunrepair:client:pickupWeapon",
                    icon = "fas fa-hand-paper",
                    label = "Pickup Repaired Weapon",
                    canInteract = function()
                        return canPickup
                    end
                }
            },
            distance = 2.5
        })
    elseif Config.Target == 'ox' then
        exports.ox_target:addSphereZone({
            coords = Config.RepairLocation,
            radius = 2.0,
            options = {
                {
                    name = 'repair_weapon',
                    label = 'Repair Weapon',
                    icon = 'fas fa-wrench',
                    onSelect = HandleRepair,
                    canInteract = function()
                        return not isRepairing and not canPickup
                    end
                },
                {
                    name = 'pickup_weapon',
                    label = 'Pickup Repaired Weapon',
                    icon = 'fas fa-hand-paper',
                    onSelect = HandlePickup,
                    canInteract = function()
                        return canPickup
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('paradise_gunrepair:client:repairMenu', function()
    HandleRepair()
end)

RegisterNetEvent('paradise_gunrepair:client:pickupWeapon', function()
    HandlePickup()
end)

function OpenRepairMenu()
    local weapons = {}
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    for _, item in pairs(PlayerData.items) do
        if item and item.name then
            if string.match(item.name, "WEAPON_") or QBCore.Shared.Weapons[item.name] then
                local quality = 100
                
                if item.metadata then
                    quality = item.metadata.durability or item.metadata.quality or 100
                    quality = tonumber(quality)
                end

                if quality < 100 or item.metadata then
                    local weaponLabel = QBCore.Shared.Weapons[item.name] and QBCore.Shared.Weapons[item.name].label or item.name
                    if Config.Debug then
                        print(string.format("Weapon: %s, Quality: %s, Metadata: %s", 
                            item.name, 
                            tostring(quality),
                            json.encode(item.metadata or {})
                        ))
                    end
                    table.insert(weapons, {
                        title = weaponLabel,
                        description = string.format("Durability: %d%%", math.floor(quality)),
                        metadata = {
                            {label = 'Weapon', value = item.name},
                            {label = 'Durability', value = math.floor(quality) .. '%'}
                        },
                        onSelect = function()
                            RepairWeapon(item)
                        end
                    })
                end
            end
        end
    end

    if #weapons == 0 then
        lib.notify({
            title = 'Weapon Repair',
            description = 'No damaged weapons found!',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'paradise_gunrepair_menu',
        title = 'Weapon Repair Shop',
        options = weapons
    })

    lib.showContext('paradise_gunrepair_menu')
end

function RepairWeapon(item)
    local weaponClass = GetWeaponClass(item.name)
    if not weaponClass then return end

    local repairCost = Config.RepairCosts[weaponClass]
    local repairTime = Config.RepairTimes[weaponClass]
    local requiredItems = Config.RequiredItems[weaponClass]

    local originalMetadata = {}
    if item.metadata then
        for k, v in pairs(item.metadata) do
            originalMetadata[k] = v
        end
    end

    local requiredItemsText = ""
    for _, reqItem in ipairs(requiredItems) do
        requiredItemsText = requiredItemsText .. string.format("\n%dx %s", reqItem.amount, reqItem.item)
    end

    local alert = lib.alertDialog({
        header = 'Confirm Repair',
        content = string.format(
            'Repair cost: $%d\nRequired items:%s\nRepair time: %d seconds\nDo you want to proceed?', 
            repairCost,
            requiredItemsText,
            repairTime
        ),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    if Config.Debug then
        print(string.format("[DEBUG] Attempting repair - Cost: $%d", repairCost))
        for _, reqItem in ipairs(requiredItems) do
            print(string.format("[DEBUG] Required item: %dx %s", reqItem.amount, reqItem.item))
        end
    end

    QBCore.Functions.TriggerCallback('paradise_gunrepair:server:checkMoney', function(hasEnough)
        if hasEnough then
            TriggerServerEvent('paradise_gunrepair:server:startRepair', item.name, originalMetadata)
            isRepairing = true
            repairTimer = repairTime

            CreateThread(function()
                while repairTimer > 0 and isRepairing do
                    lib.showTextUI(string.format('Repairing weapon: %d seconds remaining', repairTimer))
                    Wait(1000)
                    repairTimer = repairTimer - 1
                end

                if repairTimer <= 0 and isRepairing then
                    isRepairing = false
                    canPickup = true
                    lib.hideTextUI()
                    
                    lib.notify({
                        title = 'Weapon Repair',
                        description = 'Your weapon is ready for pickup!',
                        type = 'success'
                    })
                end
            end)
        else
            lib.notify({
                title = 'Weapon Repair',
                description = 'Not enough money or required items!',
                type = 'error'
            })
        end
    end, repairCost)
end

RegisterNetEvent('paradise_gunrepair:client:resetPickupState', function()
    canPickup = false
end) 