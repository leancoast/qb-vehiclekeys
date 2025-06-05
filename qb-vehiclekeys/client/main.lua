local QBCore = exports['qb-core']:GetCoreObject()
local KeysList = {}
local isTakingKeys = false
local isCarjacking = false
local canCarjack = true
local AlertSend = false
local lastPickedVehicle = nil
local IsHotwiring = false
local trunkclose = true
local looped = false
local isToggling = false

local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    if GetConvar('qb_locale', 'en') == 'en' then
        SetTextFont(4)
    else
        SetTextFont(1)
    end
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function isBlacklistedVehicle(vehicle)
    local isBlacklisted = false
    for _, v in ipairs(Config.NoLockVehicles or {}) do
        if joaat(v) == GetEntityModel(vehicle) then
            isBlacklisted = true
            break
        end
    end
    if Entity(vehicle).state.ignoreLocks or GetVehicleClass(vehicle) == 13 then isBlacklisted = true end
    return isBlacklisted
end

function addNoLockVehicles(model)
    Config.NoLockVehicles = Config.NoLockVehicles or {}
    Config.NoLockVehicles[#Config.NoLockVehicles + 1] = model
end

exports('addNoLockVehicles', addNoLockVehicles)

function removeNoLockVehicles(model)
    Config.NoLockVehicles = Config.NoLockVehicles or {}
    for k, v in pairs(Config.NoLockVehicles) do
        if v == model then
            Config.NoLockVehicles[k] = nil
        end
    end
end

exports('removeNoLockVehicles', removeNoLockVehicles)

function AreKeysJobShared(veh)
    local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local vehPlate = QBCore.Functions.GetPlate(veh)
    local jobName = QBCore.Functions.GetPlayerData().job.name
    local onDuty = QBCore.Functions.GetPlayerData().job.onduty
    for job, v in pairs(Config.SharedKeys or {}) do
        if job == jobName then
            if Config.SharedKeys[job].requireOnduty and not onDuty then return false end
            for _, vehicle in pairs(v.vehicles) do
                if string.upper(vehicle) == string.upper(vehName) then
                    if not HasKeys(vehPlate) then
                        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', vehPlate)
                    end
                    return true
                end
            end
        end
    end
    return false
end

function MakePedFlee(ped)
    SetPedFleeAttributes(ped, 0, 0)
    TaskReactAndFleePed(ped, PlayerPedId())
end

function IsBlacklistedWeapon()
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon then
        for _, v in pairs(Config.NoCarjackWeapons or {}) do
            if weapon == joaat(v) then
                return true
            end
        end
    end
    return false
end

function GetKeys()
    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:GetVehicleKeys', function(keysList)
        KeysList = keysList or {}
    end)
end

function HasKeys(plate, cb)
    if not cb then
        return false
    end
    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:HasKeys', function(hasKey)
        cb(hasKey)
    end, plate)
end

exports('HasKeys', function(plate, cb)
    HasKeys(plate, cb or function() end)
end)

function ToggleVehicleLockswithoutnui(veh)
    if not veh or not DoesEntityExist(veh) then
        QBCore.Functions.Notify('Yakınında araç yok!', 'error')
        return
    end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    local plate = QBCore.Functions.GetPlate(veh)
    HasKeys(plate, function(hasKeys)
        if hasKeys or AreKeysJobShared(veh) then
            if isToggling then
                return
            end
            isToggling = true

            local ped = PlayerPedId()
            local vehLockStatus = GetVehicleDoorLockStatus(veh)
            local curVeh = GetVehiclePedIsIn(ped, false)
            local object = 0


            if curVeh == 0 and Config.LockToggleAnimation then
                object = CreateObject(joaat(Config.LockToggleAnimation.Prop or 'prop_cs_keys_01'), 0, 0, 0, true, true, true)
                while not DoesEntityExist(object) do Wait(1) end
                AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, Config.LockToggleAnimation.PropBone or 57005),
                    0.1, 0.025, 0.0, 0.0, 0.0, -90.0, true, true, false, true, 1, true)
            end

            loadAnimDict('anim@mp_player_intmenu@key_fob@')
            TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5.0, Config.LockToggleAnimation and Config.LockToggleAnimation.AnimSound or 'lock', 0.3)

            NetworkRequestControlOfEntity(veh)
            local attempts = 0
            while not NetworkHasControlOfEntity(veh) and attempts < 10 do
                NetworkRequestControlOfEntity(veh)
                attempts = attempts + 1
                Wait(100)
            end
            if not NetworkHasControlOfEntity(veh) then
                QBCore.Functions.Notify('Araç kontrolü alınamadı!', 'error')
                isToggling = false
                if object ~= 0 and DoesEntityExist(object) then DeleteObject(object) end
                ClearPedTasks(ped)
                return
            end

            if vehLockStatus == 1 then
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 2)
                QBCore.Functions.Notify(Lang:t('notify.vlock'), 'primary')
            else
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
                QBCore.Functions.Notify(Lang:t('notify.vunlock'), 'success')
            end

            SetVehicleLights(veh, 2)
            Wait(250)
            SetVehicleLights(veh, 1)
            Wait(200)
            SetVehicleLights(veh, 0)

            if curVeh == 0 then
                Citizen.CreateThread(function()
                    Wait(Config.LockToggleAnimation and Config.LockToggleAnimation.WaitTime or 1000)
                    if IsEntityPlayingAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3) then
                        StopAnimTask(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 1.0)
                    end
                    if object ~= 0 and DoesEntityExist(object) then
                        DeleteObject(object)
                    end
                    isToggling = false
                end)
            else
                isToggling = false
            end

            ClearPedTasks(ped)
        else
            QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
            isToggling = false
        end
    end)
end

function ToggleVehicleLocks(veh)
    if not veh or not DoesEntityExist(veh) then return end
    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    local plate = QBCore.Functions.GetPlate(veh)
    HasKeys(plate, function(hasKeys)
        if hasKeys or AreKeysJobShared(veh) then
            local ped = PlayerPedId()
            local vehLockStatus = GetVehicleDoorLockStatus(veh)
            if vehLockStatus == 1 then
                loadAnimDict('anim@mp_player_intmenu@key_fob@')
                TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
                TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
                NetworkRequestControlOfEntity(veh)
                while not NetworkHasControlOfEntity(veh) do
                    NetworkRequestControlOfEntity(veh)
                    Wait(0)
                end
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 2)
                QBCore.Functions.Notify(Lang:t('notify.vlock'), 'primary')
                SetVehicleLights(veh, 2)
                Wait(250)
                SetVehicleLights(veh, 1)
                Wait(200)
                SetVehicleLights(veh, 0)
                Wait(300)
                ClearPedTasks(ped)
            else
                QBCore.Functions.Notify(Lang:t('notify.already_locked'), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        end
    end)
end

function ToggleVehicleunLocks(veh)
    if not veh or not DoesEntityExist(veh) then return end
    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    local plate = QBCore.Functions.GetPlate(veh)
    HasKeys(plate, function(hasKeys)
        if hasKeys or AreKeysJobShared(veh) then
            local ped = PlayerPedId()
            local vehLockStatus = GetVehicleDoorLockStatus(veh)
            if vehLockStatus == 2 then
                loadAnimDict('anim@mp_player_intmenu@key_fob@')
                TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
                TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
                NetworkRequestControlOfEntity(veh)
                while not NetworkHasControlOfEntity(veh) do
                    NetworkRequestControlOfEntity(veh)
                    Wait(0)
                end
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
                QBCore.Functions.Notify(Lang:t('notify.vunlock'), 'success')
                SetVehicleLights(veh, 2)
                Wait(250)
                SetVehicleLights(veh, 1)
                Wait(200)
                SetVehicleLights(veh, 0)
                Wait(300)
                ClearPedTasks(ped)
            else
                QBCore.Functions.Notify(Lang:t('notify.already_unlocked'), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        end
    end)
end

function ToggleVehicleTrunk(veh)
    if not veh or not DoesEntityExist(veh) then return end
    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    local plate = QBCore.Functions.GetPlate(veh)
    HasKeys(plate, function(hasKeys)
        if hasKeys or AreKeysJobShared(veh) then
            local ped = PlayerPedId()
            local boot = GetEntityBoneIndexByName(veh, 'boot')
            loadAnimDict('anim@mp_player_intmenu@key_fob@')
            TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
            NetworkRequestControlOfEntity(veh)
            if boot ~= -1 or DoesEntityExist(veh) then
                if trunkclose then
                    SetVehicleLights(veh, 2)
                    Wait(150)
                    SetVehicleLights(veh, 0)
                    Wait(150)
                    SetVehicleLights(veh, 2)
                    Wait(150)
                    SetVehicleLights(veh, 0)
                    Wait(150)
                    SetVehicleDoorOpen(veh, 5, false, false)
                    trunkclose = false
                    ClearPedTasks(ped)
                else
                    SetVehicleLights(veh, 2)
                    Wait(150)
                    SetVehicleLights(veh, 0)
                    Wait(150)
                    SetVehicleLights(veh, 2)
                    Wait(150)
                    SetVehicleLights(veh, 0)
                    Wait(150)
                    SetVehicleDoorShut(veh, 5, false)
                    trunkclose = true
                    ClearPedTasks(ped)
                end
            end
        else
            QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        end
    end)
end

function ToggleEngine(veh)
    if not veh or not DoesEntityExist(veh) then return end
    local plate = QBCore.Functions.GetPlate(veh)
    HasKeys(plate, function(hasKeys)
        if not isBlacklistedVehicle(veh) then
            if hasKeys or AreKeysJobShared(veh) then
                local EngineOn = GetIsVehicleEngineRunning(veh)
                if EngineOn then
                    SetVehicleEngineOn(veh, false, false, true)
                    QBCore.Functions.Notify(Lang:t('notify.engine_off'), 'primary')
                else
                    SetVehicleEngineOn(veh, true, true, true)
                    QBCore.Functions.Notify(Lang:t('notify.engine_on'), 'success')
                end
            else
                QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
            end
        end
    end)
end

function Hotwire(vehicle, plate)
    local hotwireTime = math.random(Config.minHotwireTime or 10000, Config.maxHotwireTime or 20000)
    local ped = PlayerPedId()
    IsHotwiring = true

    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, hotwireTime)
    QBCore.Functions.Progressbar('hotwire_vehicle', Lang:t('progress.hskeys'), hotwireTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flags = 16
    }, {}, {}, function()
        StopAnimTask(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        if math.random() <= (Config.HotwireChance or 0.5) then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
            QBCore.Functions.Notify(Lang:t('notify.s_hotwire'), 'success')
        else
            QBCore.Functions.Notify(Lang:t('notify.fvlockpick'), 'error')
        end
        Wait(Config.TimeBetweenHotwires or 30000)
        IsHotwiring = false
    end, function()
        StopAnimTask(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        IsHotwiring = false
    end)
    SetTimeout(10000, function()
        AttemptPoliceAlert('steal')
    end)
end

function CarjackVehicle(target)
    if not Config.CarJackEnable then return end
    isCarjacking = true
    canCarjack = false
    loadAnimDict('mp_am_hold_up')
    local vehicle = GetVehiclePedIsUsing(target)
    local occupants = GetPedsInVehicle(vehicle)
    for p = 1, #occupants do
        local ped = occupants[p]
        CreateThread(function()
            TaskPlayAnim(ped, 'mp_am_hold_up', 'holdup_victim_20s', 8.0, -8.0, -1, 49, 0, false, false, false)
            PlayPain(ped, 6, 0)
            FreezeEntityPosition(vehicle, true)
            SetVehicleUndriveable(vehicle, true)
        end)
        Wait(math.random(200, 500))
    end
    CreateThread(function()
        while isCarjacking do
            local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(target))
            if IsPedDeadOrDying(target) or distance > 7.5 then
                TriggerEvent('progressbar:client:cancel')
                FreezeEntityPosition(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
            end
            Wait(100)
        end
    end)
    QBCore.Functions.Progressbar('rob_keys', Lang:t('progress.acjack'), Config.CarjackingTime or 7000, false, true, {}, {}, {}, {}, function()
        local hasWeapon, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
        if hasWeapon and isCarjacking then
            local carjackChance = Config.CarjackChance and Config.CarjackChance[tostring(GetWeapontypeGroup(weaponHash))] or 0.5
            if math.random() <= carjackChance then
                local plate = QBCore.Functions.GetPlate(vehicle)
                for p = 1, #occupants do
                    local ped = occupants[p]
                    CreateThread(function()
                        FreezeEntityPosition(vehicle, false)
                        SetVehicleUndriveable(vehicle, false)
                        TaskLeaveVehicle(ped, vehicle, 0)
                        PlayPain(ped, 6, 0)
                        Wait(1250)
                        ClearPedTasksImmediately(ped)
                        PlayPain(ped, math.random(7, 8), 0)
                        MakePedFlee(ped)
                    end)
                end
                TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
                TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
                QBCore.Functions.Notify(Lang:t('notify.s_carjack'), 'success')
            else
                QBCore.Functions.Notify(Lang:t('notify.cjackfail'), 'error')
                FreezeEntityPosition(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
                MakePedFlee(target)
                TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
            end
            isCarjacking = false
            Wait(2000)
            AttemptPoliceAlert('carjack')
            Wait(Config.DelayBetweenCarjackings or 30000)
            canCarjack = true
        end
    end, function()
        MakePedFlee(target)
        isCarjacking = false
        Wait(Config.DelayBetweenCarjackings or 30000)
        canCarjack = true
    end)
end

function AttemptPoliceAlert(type)
    if not AlertSend then
        local chance = Config.PoliceAlertChance or 0.5
        if GetClockHours() >= 1 and GetClockHours() <= 6 then
            chance = Config.PoliceNightAlertChance or 0.25
        end
        if math.random() <= chance then
            TriggerServerEvent('police:server:policeAlert', Lang:t('info.palert') .. type)
        end
        AlertSend = true
        SetTimeout(Config.AlertCooldown or 30000, function()
            AlertSend = false
        end)
    end
end

function GetVehicle()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = QBCore.Functions.GetClosestVehicle()
        if not vehicle or #(pos - GetEntityCoords(vehicle)) > (Config.LockToggleDist or 5.0) then
            return nil
        end
    end
    if not IsEntityAVehicle(vehicle) then
        return nil
    end
    return vehicle
end

function GetOtherPlayersInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if IsPedAPlayer(pedInSeat) and pedInSeat ~= PlayerPedId() then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function GetPedsInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if not IsPedAPlayer(pedInSeat) and pedInSeat ~= 0 then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function robKeyLoop()
    if looped then return end
    looped = true
    local textActive = false
    local currentVehicle = nil
    local currentPlate = nil

    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            sleep = 100
            local ped = PlayerPedId()
            local entering = GetVehiclePedIsTryingToEnter(ped)
            local carIsImmune = false

            if entering ~= 0 and not isBlacklistedVehicle(entering) then
                sleep = 2000
                local plate = QBCore.Functions.GetPlate(entering)
                local vehLockStatus = GetVehicleDoorLockStatus(entering)

                local driver = GetPedInVehicleSeat(entering, -1)
                for _, veh in ipairs(Config.ImmuneVehicles or {}) do
                    if GetEntityModel(entering) == joaat(veh) then
                        carIsImmune = true
                    end
                end
                if driver ~= 0 and not IsPedAPlayer(driver) and not carIsImmune then
                    HasKeys(plate, function(hasKeys)
                        if hasKeys then
                            return
                        end
                        if IsEntityDead(driver) then
                            if not isTakingKeys then
                                isTakingKeys = true
                                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                                QBCore.Functions.Progressbar('steal_keys', Lang:t('progress.takekeys'), 2500, false, false, {
                                    disableMovement = false,
                                    disableCarMovement = true,
                                    disableMouse = false,
                                    disableCombat = true
                                }, {}, {}, {}, function()
                                    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
                                    isTakingKeys = false
                                end, function()
                                    isTakingKeys = false
                                end)
                            end
                        elseif Config.LockNPCDrivingCars then
                            if vehLockStatus ~= 2 then
                                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
                            end
                        else
                            if vehLockStatus ~= 1 then
                                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                                TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
                                local pedsInVehicle = GetPedsInVehicle(entering)
                                for _, pedInVehicle in pairs(pedsInVehicle) do
                                    if pedInVehicle ~= GetPedInVehicleSeat(entering, -1) then
                                        MakePedFlee(pedInVehicle)
                                    end
                                end
                            end
                        end
                    end)
                elseif driver == 0 and entering ~= lastPickedVehicle and not isTakingKeys then
                    HasKeys(plate, function(hasKeys)
                        if hasKeys then
                            return
                        end
                        QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:checkPlayerOwned', function(playerOwned)
                            if not playerOwned then
                                if Config.LockNPCParkedCars then
                                    if vehLockStatus ~= 2 then
                                        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
                                    end
                                else
                                    if vehLockStatus ~= 1 then
                                        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                                    end
                                end
                            end
                        end, plate)
                    end)
                end
            end

            if IsPedInAnyVehicle(ped, false) and not IsHotwiring then
                sleep = 100
                local vehicle = GetVehiclePedIsIn(ped)
                local plate = QBCore.Functions.GetPlate(vehicle)
                if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() and not isBlacklistedVehicle(vehicle) then
                    HasKeys(plate, function(hasKeys)
                        if not hasKeys and not AreKeysJobShared(vehicle) then
                            currentVehicle = vehicle
                            currentPlate = plate
                            if not textActive then
                                textActive = true
                                Citizen.CreateThread(function()
                                    while textActive and IsPedInAnyVehicle(ped, false) and not hasKeys and not IsHotwiring do
                                        local vehiclePos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.0, 0.5)
                                        DrawText3D(vehiclePos.x, vehiclePos.y, vehiclePos.z, Lang:t('info.skeys') .. ' [H] Anahtar Ara')
                                        if IsControlJustPressed(0, 74) then
                                            textActive = false
                                            SearchKeys(vehicle, plate)
                                        end
                                        Wait(0)
                                    end
                                    textActive = false
                                end)
                            end
                            SetVehicleEngineOn(vehicle, false, true, true)
                        else
                            textActive = false
                        end
                    end)
                else
                    textActive = false
                end
            else
                textActive = false
                currentVehicle = nil
                currentPlate = nil
            end

            if Config.CarJackEnable and canCarjack then
                local playerid = PlayerId()
                local aiming, target = GetEntityPlayerIsFreeAimingAt(playerid)
                if aiming and target and DoesEntityExist(target) and IsPedInAnyVehicle(target, false) and not IsEntityDead(target) and not IsPedAPlayer(target) then
                    local targetveh = GetVehiclePedIsIn(target)
                    for _, veh in ipairs(Config.ImmuneVehicles or {}) do
                        if GetEntityModel(targetveh) == joaat(veh) then
                            carIsImmune = true
                        end
                    end
                    if GetPedInVehicleSeat(targetveh, -1) == target and not IsBlacklistedWeapon() then
                        local pos = GetEntityCoords(ped, true)
                        local targetpos = GetEntityCoords(target, true)
                        if #(pos - targetpos) < 5.0 and not carIsImmune then
                            CarjackVehicle(target)
                        end
                    end
                end
            end

            if entering == 0 and not IsPedInAnyVehicle(ped, false) and GetSelectedPedWeapon(ped) == `WEAPON_UNARMED` then
                looped = false
                textActive = false
                break
            end
        end
        Wait(sleep)
    end
end

function SearchKeys(vehicle, plate)
    local searchTime = math.random(5000, 10000)
    local ped = PlayerPedId()
    IsHotwiring = true

    loadAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 16, 0, false, false, false)

    local success = lib.progressBar({
        duration = searchTime,
        label = 'Anahtar aranıyor...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flag = 16,
        }
    })

    StopAnimTask(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)

    if success then
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        local chance = math.random()
        local successChance = Config.SearchKeyChance or 0.3
        if chance <= successChance then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
            QBCore.Functions.Notify('Anahtar bulundu!', 'success')
        else
            QBCore.Functions.Notify('Anahtar bulunamadı!', 'error')
        end
    else
        QBCore.Functions.Notify('Anahtar arama iptal edildi!', 'error')
    end
    IsHotwiring = false
end

RegisterKeyMapping('togglelocks', Lang:t('info.tlock'), 'keyboard', 'L')
RegisterCommand('togglelocks', function()
    local ped = PlayerPedId()
    local vehicle = GetVehicle()
    if not vehicle then
        QBCore.Functions.Notify(Lang:t('notify.pntf'), 'error')
        return
    end
    if IsPedInAnyVehicle(ped, false) then
        ToggleVehicleLockswithoutnui(vehicle)
    else
        if Config.UseKeyfob then
            openmenu()
        else
            ToggleVehicleLockswithoutnui(vehicle)
        end
    end
end, false)

RegisterKeyMapping('engine', Lang:t('info.engine'), 'keyboard', 'G')
RegisterCommand('engine', function()
    local vehicle = GetVehicle()
    if vehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
        ToggleEngine(vehicle)
    end
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() and QBCore.Functions.GetPlayerData() ~= {} then
        GetKeys()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    GetKeys()
    Citizen.CreateThread(robKeyLoop)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    KeysList = {}
end)

RegisterNetEvent('qb-vehiclekeys:client:AddKeys', function(plate)
    KeysList[plate] = true
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped)
        local vehiclePlate = QBCore.Functions.GetPlate(vehicle)
        if plate == vehiclePlate then
            SetVehicleEngineOn(vehicle, false, false, false)
        end
    end
end)

RegisterNetEvent('qb-vehiclekeys:client:RemoveKeys', function(plate)
    KeysList[plate] = nil
end)

RegisterNetEvent('qb-vehiclekeys:client:ToggleEngine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        local plate = QBCore.Functions.GetPlate(vehicle)
        HasKeys(plate, function(hasKeys)
            if hasKeys then
                local EngineOn = GetIsVehicleEngineRunning(vehicle)
                if EngineOn then
                    SetVehicleEngineOn(vehicle, false, false, true)
                    QBCore.Functions.Notify(Lang:t('notify.engine_off'), 'primary')
                else
                    SetVehicleEngineOn(vehicle, true, false, true)
                    QBCore.Functions.Notify(Lang:t('notify.engine_on'), 'success')
                end
            end
        end)
    end
end)

RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', function(id)
    local targetVehicle = GetVehicle()
    if not targetVehicle then
        QBCore.Functions.Notify(Lang:t('notify.pntf'), 'error')
        return
    end
    local targetPlate = QBCore.Functions.GetPlate(targetVehicle)
    HasKeys(targetPlate, function(hasKeys)
        if hasKeys then
            if id and type(id) == 'number' then
                TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', id, targetPlate)
            else
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    local otherOccupants = GetOtherPlayersInVehicle(targetVehicle)
                    for p = 1, #otherOccupants do
                        TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', GetPlayerServerId(NetworkGetPlayerIndexFromPed(otherOccupants[p])), targetPlate)
                    end
                else
                    local closestPlayer = QBCore.Functions.GetClosestPlayer()
                    if closestPlayer ~= -1 then
                        TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', GetPlayerServerId(closestPlayer), targetPlate)
                    else
                        QBCore.Functions.Notify(Lang:t('notify.nonear'), 'error')
                    end
                end
            end
        else
            QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        end
    end)
end)

RegisterNetEvent('QBCore:Client:VehicleInfo', function(data)
    if data.event == 'Entering' then
        robKeyLoop()
    end
end)

RegisterNetEvent('qb-weapons:client:DrawWeapon', function()
    Wait(2000)
    robKeyLoop()
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle()

    if vehicle == nil or vehicle == 0 then return end
    local plate = QBCore.Functions.GetPlate(vehicle)
    HasKeys(plate, function(hasKeys)
        if hasKeys then return end
        if #(pos - GetEntityCoords(vehicle)) > 2.5 then return end
        if GetVehicleDoorLockStatus(vehicle) <= 0 then return end

        local difficulty = isAdvanced and 'easy' or 'medium'
        local success = exports['qb-minigames']:Skillbar(difficulty)

        local chance = math.random()
        if success then
            TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
            lastPickedVehicle = vehicle
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
            else
                QBCore.Functions.Notify(Lang:t('notify.vlockpick'), 'success')
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 1)
            end
        else
            TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
            AttemptPoliceAlert('steal')
        end

        if isAdvanced then
            if chance <= (Config.RemoveLockpickAdvanced or 0.3) then
                TriggerServerEvent('qb-vehiclekeys:server:breakLockpick', 'advancedlockpick')
            end
        else
            if chance <= (Config.RemoveLockpickNormal or 0.5) then
                TriggerServerEvent('qb-vehiclekeys:server:breakLockpick', 'lockpick')
            end
        end
    end)
end)

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end)

RegisterNetEvent('qb-vehiclekeys:client:UpdateVehicleLockState', function(vehNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, state)
    else
    end
end)

function openmenu()
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'key', 0.3)
    SendNUIMessage({ casemenue = 'open' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('closui', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('unlock', function()
    ToggleVehicleunLocks(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('lock', function()
    ToggleVehicleLocks(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('trunk', function()
    ToggleVehicleTrunk(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('engine', function()
    ToggleEngine(GetVehicle())
    SetNuiFocus(false, false)
end)

exports('useKey', function(data, slot)
    local plate = data.metadata.plate
    local vehicle = GetVehicle()
    if vehicle then
        local vehiclePlate = QBCore.Functions.GetPlate(vehicle)
        if vehiclePlate == plate then
            ToggleVehicleLockswithoutnui(vehicle)
        else
            QBCore.Functions.Notify('Bu anahtar bu araca ait değil!', 'error')
        end
    else
        QBCore.Functions.Notify('Yakınında araç yok!', 'error')
    end
end)

local peds = {}

local function openLocksmithMenu(vehicles)
    local menu = {
        {
            header = "Çilingir",
            isMenuHeader = true
        }
    }
    if not vehicles or #vehicles == 0 then
        menu[#menu + 1] = {
            header = "Araç Bulunamadı!",
            disabled = true
        }
    else
        for _, vehicle in ipairs(vehicles) do
            menu[#menu + 1] = {
                header = "Plaka: " .. vehicle.plate,
                txt = "Ücret: $" .. Config.Locksmith.Cost,
                params = {
                    event = "qb-vehiclekeys:client:BuyKey",
                    args = vehicle.plate
                }
            }
        end
    end
    menu[#menu + 1] = {
        header = "Kapat",
        params = {
            event = "qb-menu:closeMenu"
        }
    }
    exports['qb-menu']:openMenu(menu)
end
Citizen.CreateThread(function()
    for i, location in ipairs(Config.Locksmith.Locations) do
        local ped = CreatePed(4, GetHashKey(Config.Locksmith.NPCModel), location.coords.x, location.coords.y, location.coords.z - 1.0, location.heading, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        peds[#peds + 1] = ped

        if location.blip.enabled then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, location.blip.sprite)
            SetBlipColour(blip, location.blip.color)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(location.blip.name)
            EndTextCommandSetBlipName(blip)
        end

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'talk_to_locksmith_' .. i,
                label = 'Çilingir ile Konuş',
                icon = 'fas fa-key',
                distance = 2.0,
                canInteract = function(entity, distance, coords, name)
                    return not IsPedInAnyVehicle(PlayerPedId(), false)
                end,
                onSelect = function(data)
                    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:GetVehicles', function(vehicles)
                        openLocksmithMenu(vehicles)
                    end)
                end
            }
        })
    end
end)

RegisterNetEvent('qb-vehiclekeys:client:BuyKey', function(plate)
    TriggerServerEvent('qb-vehiclekeys:server:BuyKey', plate)
end)

