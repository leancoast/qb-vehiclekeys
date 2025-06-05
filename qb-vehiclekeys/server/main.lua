local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory
local lastLockState = {}
local lockCooldown = 1000

RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(receiver, plate)
    local giver = source
    if HasKeys(giver, plate) then
        TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.vgkeys'), 'success')
        if type(receiver) == 'table' then
            for _, r in ipairs(receiver) do
                GiveKeys(r, plate)
            end
        else
            GiveKeys(receiver, plate)
        end
    else
        TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.ydhk'), 'error')
    end
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source
    GiveKeys(src, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not (itemName == 'lockpick' or itemName == 'advancedlockpick') then return end
    if ox_inventory:RemoveItem(source, itemName, 1) then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('notify.lockpick_broken'), 'error')
    end
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(vehNetId, state)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if DoesEntityExist(vehicle) then
        local currentTime = GetGameTimer()
        local lastUpdate = lastLockState[vehNetId] or { time = 0, state = 0 }
        if currentTime - lastUpdate.time < lockCooldown and lastUpdate.state == state then
            return
        end
        SetVehicleDoorsLocked(vehicle, state)
        lastLockState[vehNetId] = { time = currentTime, state = state }
        TriggerClientEvent('qb-vehiclekeys:client:UpdateVehicleLockState', -1, vehNetId, state)
    else
    end
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:GetVehicleKeys', function(source, cb)
    local keysList = {}
    local items = ox_inventory:GetInventoryItems(source)
    for _, item in pairs(items) do
        if item.name == 'vehiclekey' and item.metadata.plate then
            keysList[item.metadata.plate] = true
        end
    end
    cb(keysList)
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:HasKeys', function(source, cb, plate)
    cb(HasKeys(source, plate))
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:checkPlayerOwned', function(source, cb, plate)
    local playerOwned = false
    cb(playerOwned)
end)

function GiveKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end
    if not plate then
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(id), false)
        if vehicle ~= 0 then
            plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle)):upper()
        else
            return
        end
    end
    plate = QBCore.Shared.Trim(plate):upper()
    local success = ox_inventory:AddItem(id, 'vehiclekey', 1, { plate = plate, description = string.format(Lang:t('items.vehiclekey_desc'), plate) })
    if success then
        TriggerClientEvent('QBCore:Notify', id, string.format(Lang:t('notify.vgetkeys'), plate), 'success')
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', id, plate)
        TriggerClientEvent('ox_inventory:refreshInventory', id)
    else
        TriggerClientEvent('QBCore:Notify', id, 'Failed to give vehicle key!', 'error')
    end
end

exports('GiveKeys', GiveKeys)

function RemoveKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end
    plate = QBCore.Shared.Trim(plate):upper()
    local items = ox_inventory:GetInventoryItems(id)
    for _, item in pairs(items) do
        if item.name == 'vehiclekey' and item.metadata.plate == plate then
            ox_inventory:RemoveItem(id, 'vehiclekey', 1, item.metadata)
            TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', id, plate)
            TriggerClientEvent('QBCore:Notify', id, Lang:t('notify.vrkeys'), 'success')
            TriggerClientEvent('ox_inventory:refreshInventory', id)
            break
        end
    end
end

exports('RemoveKeys', RemoveKeys)

function HasKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return false end
    plate = QBCore.Shared.Trim(plate):upper()
    local items = ox_inventory:GetInventoryItems(id)
    for _, item in pairs(items) do
        if item.name == 'vehiclekey' and item.metadata.plate == plate then
            return true
        end
    end
    return false
end

exports('HasKeys', HasKeys)

-- QBCore.Commands.Add('givekeys', Lang:t('addcom.givekeys'), { { name = Lang:t('addcom.givekeys_id'), help = Lang:t('addcom.givekeys_id_help') } }, false, function(source, args)
--     local src = source
--     TriggerClientEvent('qb-vehiclekeys:client:GiveKeys', src, tonumber(args[1]))
-- end)

QBCore.Commands.Add('addkeys', Lang:t('addcom.addkeys'), { { name = Lang:t('addcom.addkeys_id'), help = Lang:t('addcom.addkeys_id_help') }, { name = Lang:t('addcom.addkeys_plate'), help = Lang:t('addcom.addkeys_plate_help') } }, true, function(source, args)
    local src = source
    if not args[1] or not args[2] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
        return
    end
    GiveKeys(tonumber(args[1]), args[2])
end, 'admin')

-- QBCore.Commands.Add('removekeys', Lang:t('addcom.rkeys'), { { name = Lang:t('addcom.rkeys_id'), help = Lang:t('addcom.rkeys_id_help') }, { name = Lang:t('addcom.rkeys_plate'), help = Lang:t('addcom.rkeys_plate_help') } }, true, function(source, args)
--     local src = source
--     if not args[1] or not args[2] then
--         TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
--         return
--     end
--     RemoveKeys(tonumber(args[1]), args[2])
-- end, 'admin')

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:GetVehicles', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return cb({})
    end
    local citizenid = player.PlayerData.citizenid
    exports.oxmysql:execute('SELECT plate FROM player_vehicles WHERE citizenid = ?', { citizenid }, function(result)
        if not result or #result == 0 then
            return cb({})
        end
        local vehicles = {}
        for _, v in ipairs(result) do
            if v.plate then
                vehicles[#vehicles + 1] = { plate = string.upper(v.plate) }
            end
        end
        cb(vehicles)
    end)
end)

RegisterNetEvent('qb-vehiclekeys:server:BuyKey', function(plate)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return
    end
    local citizenid = player.PlayerData.citizenid
    plate = string.upper(plate)
    exports.oxmysql:execute('SELECT COUNT(*) as count FROM player_vehicles WHERE citizenid = ? AND plate = ?', { citizenid, plate }, function(result)
        if not result or result[1].count == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Bu araç sana ait değil!', 'error')
            return
        end
        if ox_inventory:RemoveItem(src, 'money', Config.Locksmith.Cost) then
            exports['qb-vehiclekeys']:GiveKeys(src, plate)
            TriggerClientEvent('QBCore:Notify', src, 'Plakası ' .. plate .. ' olan aracın anahtarını aldın! ($' .. Config.Locksmith.Cost .. ')', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Yeterli paran yok!', 'error')
        end
    end)
end)