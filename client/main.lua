local ClientBridge = lib.require('shared.client_bridge')

-- Local variables
local PlayerStats = {
    level = 1,
    exp = 0,
    total_packed = 0,
    next_level_xp = 100
}

local createdBlips = {}
local createdTables = {}
local createdTargets = {}
local currentDelivery = nil
local deliveryBlip = nil
local deliveryNPC = nil
local deliveryVehicle = nil
local deliveryCount = 0
local maxDeliveries = 10

-- Initialize the resource
CreateThread(function()
    -- Create blips for packing locations
    for i, location in pairs(Config.PackingLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, location.blip.scale)
        SetBlipColour(blip, location.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(location.blip.label)
        EndTextCommandSetBlipName(blip)
        
        table.insert(createdBlips, blip)
    end
    
    -- Create NPC blip
    local npcBlip = AddBlipForCoord(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
    SetBlipSprite(npcBlip, Config.NPC.blip.sprite)
    SetBlipDisplay(npcBlip, 4)
    SetBlipScale(npcBlip, Config.NPC.blip.scale)
    SetBlipColour(npcBlip, Config.NPC.blip.color)
    SetBlipAsShortRange(npcBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.NPC.blip.label)
    EndTextCommandSetBlipName(npcBlip)
    
    table.insert(createdBlips, npcBlip)
    
    -- Request player stats
    TriggerServerEvent('peleg-drugrungs:server:GetPlayerStats')
end)

-- Show drug packing menu
function ShowDrugPackingMenu()
    local options = {}
    
    for drugType, drugConfig in pairs(Config.Drugs) do
        local hasItem = ClientBridge.GetItemCount(drugType)
        
        table.insert(options, {
            title = string.format('Pack %s', drugConfig.label),
            description = string.format('Pack %s into %s (+%d XP)', drugConfig.label, drugConfig.packed_item, drugConfig.xp_reward),
            icon = 'fas fa-box',
            iconColor = hasItem > 0 and '#4caf50' or '#f44336',
            metadata = {
                { label = 'Required Item', value = drugType },
                { label = 'Packed Item', value = drugConfig.packed_item },
                { label = 'XP Reward', value = string.format('+%d XP', drugConfig.xp_reward) },
                { label = 'Packing Time', value = string.format('%d seconds', drugConfig.packing_time / 1000) },
                { label = 'Available', value = hasItem > 0 and string.format('%d available', hasItem) or 'None available' }
            },
            onSelect = function()
                if hasItem > 0 then
                    StartDrugPacking(drugType)
                else
                    ClientBridge.Notify({
                        type = 'error',
                        description = string.format('You need %s to pack this', drugType),
                        duration = 3000
                    })
                end
            end
        })
    end
    
    -- Add back button
    table.insert(options, {
        title = 'Back',
        description = 'Return to main menu',
        icon = 'fas fa-arrow-left',
        iconColor = '#9e9e9e',
        onSelect = function()
            ShowDrugRunsMenu()
        end
    })
    
    lib.registerContext({
        id = 'drug_packing_menu',
        title = 'Drug Packing Station',
        options = options
    })
    
    lib.showContext('drug_packing_menu')
end

-- Start drug packing process
function StartDrugPacking(drugType)
    local drugConfig = Config.Drugs[drugType]
    if not drugConfig then return end
    
    -- Check if player has the item
    local hasItem = ClientBridge.GetItemCount(drugType)
    if hasItem < 1 then
        ClientBridge.Notify({
            type = 'error',
            description = string.format('You need %s to pack this', drugType),
            duration = 3000
        })
        return
    end
    
    -- Start packing animation and progress
    if lib.progressBar({
        duration = drugConfig.packing_time,
        label = string.format('Packing %s...', drugConfig.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = Config.Animations.packing.dict,
            clip = Config.Animations.packing.anim
        }
    }) then
        -- Packing successful
        TriggerServerEvent('peleg-drugrungs:server:PackDrug', drugType)
        
        -- Update stats
        TriggerServerEvent('peleg-drugrungs:server:GetPlayerStats')
    else
        -- Packing cancelled
        lib.notify({
            type = 'error',
            description = 'Packing cancelled',
            duration = 3000
        })
    end
end

-- Show main drug runs menu
function ShowDrugRunsMenu()
    local levelColor = Config.LevelColors[PlayerStats.level] and Config.LevelColors[PlayerStats.level].color or '#ffffff'
    local levelName = Config.LevelColors[PlayerStats.level] and Config.LevelColors[PlayerStats.level].name or 'Unknown'
    
    -- Calculate progress percentage for current level
    local currentThreshold = PlayerStats.level > 1 and GetXPForLevel(PlayerStats.level - 1) or 0
    local nextThreshold = PlayerStats.next_level_xp
    local progress = math.floor(((PlayerStats.exp - currentThreshold) / (nextThreshold - currentThreshold)) * 100)
    
    lib.registerContext({
        id = 'drug_runs_menu',
        title = 'Drug Runs',
        options = {
            {
                title = string.format('Level %d %s', PlayerStats.level, levelName),
                description = string.format('Current Experience: %s XP', PlayerStats.exp),
                icon = 'fas fa-chart-line',
                iconColor = levelColor,
                progress = progress,
                colorScheme = progress <= 25 and 'red' or progress > 25 and progress <= 75 and 'yellow' or progress > 75 and 'green',
                readOnly = true,
                metadata = {
                    { label = 'Next Level', value = PlayerStats.next_level_xp > 0 and string.format('%d XP needed', PlayerStats.next_level_xp - PlayerStats.exp) or 'Max Level' },
                    { label = 'Current Level', value = string.format('%s (%d)', levelName, PlayerStats.level) },
                    { label = 'Total Packed', value = PlayerStats.total_packed }
                }
            },
            {
                title = 'View Statistics',
                description = 'View your drug running statistics',
                icon = 'fas fa-chart-bar',
                iconColor = '#66bb6a',
                onSelect = function()
                    ShowStatisticsMenu()
                end
            },
            {
                title = 'Start Drug Run',
                description = 'Start a drug delivery mission',
                icon = 'fas fa-motorcycle',
                iconColor = '#ff5722',
                onSelect = function()
                    StartDrugDelivery()
                end
            }
        }
    })
    
    lib.showContext('drug_runs_menu')
end

-- Show statistics menu
function ShowStatisticsMenu()
    lib.registerContext({
        id = 'statistics_menu',
        title = 'Drug Running Statistics',
        menu = 'drug_runs_menu',
        options = {
            {
                title = 'General Stats',
                description = 'Your overall performance',
                icon = 'fas fa-info-circle',
                iconColor = '#2196f3',
                metadata = {
                    { label = 'Current Level', value = PlayerStats.level },
                    { label = 'Total Experience', value = PlayerStats.exp },
                    { label = 'Total Drugs Packed', value = PlayerStats.total_packed },
                    { label = 'XP to Next Level', value = PlayerStats.next_level_xp - PlayerStats.exp }
                }
            },
            {
                title = 'Drug Types',
                description = 'Statistics by drug type',
                icon = 'fas fa-pills',
                iconColor = '#ff9800',
                metadata = {
                    { label = 'Meth XP', value = string.format('+%d per pack', Config.Drugs.meth_cured.xp_reward) },
                    { label = 'Cocaine XP', value = string.format('+%d per pack', Config.Drugs.coke_cured.xp_reward) },
                    { label = 'Weed XP', value = string.format('+%d per pack', Config.Drugs.weed_cured.xp_reward) }
                }
            },
            {
                title = 'Back',
                description = 'Return to main menu',
                icon = 'fas fa-arrow-left',
                iconColor = '#9e9e9e',
                onSelect = function()
                    ShowDrugRunsMenu()
                end
            }
        }
    })
    
    lib.showContext('statistics_menu')
end

-- Calculate XP for level (client-side helper)
function GetXPForLevel(level)
    if level >= Config.Levels.max_level then
        return 0
    end
    
    local baseXP = Config.Levels.base_xp_requirements[level] or 100
    return math.floor(baseXP * (Config.Levels.xp_multiplier ^ (level - 1)))
end

-- Receive player stats from server
RegisterNetEvent('peleg-drugrungs:client:ReceivePlayerStats', function(stats)
    PlayerStats = stats
end)

-- Drug Delivery Functions
function StartDrugDelivery()
    -- Check if player has any packed drugs
    local hasPackedDrugs = false
    for drugType, drugConfig in pairs(Config.Drugs) do
        local count = ClientBridge.GetItemCount(drugConfig.packed_item)
        if count > 0 then
            hasPackedDrugs = true
            break
        end
    end
    
    if not hasPackedDrugs then
        ClientBridge.Notify({
            type = 'error',
            description = 'You need packed drugs to start a delivery',
            duration = 3000
        })
        return
    end
    
    -- Reset delivery count if starting fresh
    if deliveryCount == 0 then
        deliveryCount = 1
    end

    
    -- Select random delivery location
    local randomLocation = Config.Delivery.delivery_locations[math.random(#Config.Delivery.delivery_locations)]
    currentDelivery = randomLocation
    
    -- Spawn dirt bike near player
    local playerCoords = GetEntityCoords(PlayerPedId())
    local spawnCoords = vector4(playerCoords.x + 3.0, playerCoords.y + 3.0, playerCoords.z, GetEntityHeading(PlayerPedId()))
    
    local bikeModel = GetHashKey(Config.Delivery.dirt_bike)
    RequestModel(bikeModel)
    while not HasModelLoaded(bikeModel) do
        Wait(1)
    end
    
    -- Find a safe spawn location
    local safeCoords = vec4(758.6, -152.51, 74.4, 53.72)
    
    local deliveryVehicle = CreateVehicle(bikeModel, safeCoords.x, safeCoords.y, safeCoords.z, spawnCoords.w, true, false)
    SetVehicleNumberPlateText(deliveryVehicle, "DEL"..math.random(1000, 9999))
    SetEntityAsMissionEntity(deliveryVehicle, true, true)
    SetVehicleEngineOn(deliveryVehicle, true, true, false)
    
    -- Send to server to give keys
    TaskWarpPedIntoVehicle(PlayerPedId(), deliveryVehicle, -1)
    Wait(500)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', GetVehicleNumberPlateText(deliveryVehicle))

    if not DoesEntityExist(deliveryVehicle) then
        lib.notify({
            type = 'error',
            description = 'Failed to create dirt bike',
            duration = 3000
        })
        return
    end
    
    SetEntityAsMissionEntity(deliveryVehicle, true, true)
    SetVehicleEngineOn(deliveryVehicle, false, true, true)
    
    -- Give player keys to the motorcycle    
    -- Create delivery blip
    deliveryBlip = AddBlipForCoord(currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z)
    SetBlipSprite(deliveryBlip, currentDelivery.blip.sprite)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, currentDelivery.blip.scale)
    SetBlipColour(deliveryBlip, currentDelivery.blip.color)
    SetBlipAsShortRange(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(currentDelivery.blip.label)
    EndTextCommandSetBlipName(deliveryBlip)
    
    -- Set waypoint to delivery location
    SetNewWaypoint(currentDelivery.coords.x, currentDelivery.coords.y)
    
    print("Delivery blip created at: " .. currentDelivery.coords.x .. ", " .. currentDelivery.coords.y .. ", " .. currentDelivery.coords.z)
    print("Blip ID: " .. deliveryBlip)
    
    -- Spawn delivery NPC
    local npcModel = GetHashKey(Config.Delivery.npc_models[math.random(#Config.Delivery.npc_models)])
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(1)
    end
    
    deliveryNPC = CreatePed(4, npcModel, currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z - 1.0, currentDelivery.heading, false, true)
    SetEntityAsMissionEntity(deliveryNPC, true, true)
    FreezeEntityPosition(deliveryNPC, true)
    SetEntityInvincible(deliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    
    -- Add ox_target to NPC
    exports.ox_target:addLocalEntity(deliveryNPC, {
        {
            name = 'delivery_npc_interaction',
            icon = 'fas fa-handshake',
            label = 'Deliver Drugs',
            onSelect = function()
                DeliverDrugs()
            end,
            canInteract = function()
                return true
            end
        }
    })
    
    lib.notify({
        type = 'success',
        description = string.format('Drug delivery %d/%d started! Dirt bike spawned. Go to %s', deliveryCount, maxDeliveries, currentDelivery.name),
        duration = 5000
    })
    
    -- Log delivery run start
    if deliveryCount == 1 then
        TriggerServerEvent('peleg-drugrungs:server:LogDeliveryRunStart')
    end
    
    -- Debug notification
    lib.notify({
        type = 'inform',
        description = 'Dirt bike created and player teleported',
        duration = 3000
    })
    
    -- Show delivery location
    lib.notify({
        type = 'inform',
        description = string.format('Delivery location marked on map: %s', currentDelivery.name),
        duration = 4000
    })
    
    SetModelAsNoLongerNeeded(bikeModel)
    SetModelAsNoLongerNeeded(npcModel)
end

function DeliverDrugs()
    if not currentDelivery or not deliveryNPC then
        lib.notify({
            type = 'error',
            description = 'No active delivery',
            duration = 3000
        })
        return
    end
    
    -- Check if player has packed drugs (only 1 per delivery)
    local totalPackedDrugs = 0
    local drugsToDeliver = {}
    
    for drugType, drugConfig in pairs(Config.Drugs) do
        local count = ClientBridge.GetItemCount(drugConfig.packed_item)
        if count > 0 then
            -- Only take 1 drug per delivery
            table.insert(drugsToDeliver, {
                item = drugConfig.packed_item,
                amount = 1
            })
            totalPackedDrugs = 1
            break -- Only take one type of drug per delivery
        end
    end
    
    if totalPackedDrugs < 1 then
        ClientBridge.Notify({
            type = 'error',
            description = 'You need packed drugs to deliver',
            duration = 3000
        })
        return
    end
    
    -- Start delivery animation
    local ped = PlayerPedId()
    local animDict = Config.Animations.delivery.dict
    local animName = Config.Animations.delivery.anim
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, Config.Animations.delivery.flag, 0, false, false, false)
    TaskPlayAnim(deliveryNPC, animDict, animName, 8.0, -8.0, -1, Config.Animations.delivery.flag, 0, false, false, false)
    
    -- Progress bar for delivery
    if lib.progressBar({
        duration = 3000,
        label = 'Delivering drugs...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Delivery successful
        TriggerServerEvent('peleg-drugrungs:server:CompleteDelivery', totalPackedDrugs, drugsToDeliver)
            if DoesEntityExist(deliveryNPC) then
                DeleteEntity(deliveryNPC)
            end

        
        -- Increment delivery count
        deliveryCount = deliveryCount + 1
        print("Delivery completed. Count: " .. deliveryCount .. "/" .. maxDeliveries)
        
        -- Check if more deliveries available
        if deliveryCount <= maxDeliveries then
            -- Start next delivery immediately
            print("Starting next delivery...")
            SetTimeout(500, function() -- Reduced from 2000ms to 500ms
                StartNextDelivery()
            end)
        else
            -- All deliveries complete
            print("All deliveries completed!")
            ClientBridge.Notify({
                type = 'success',
                description = 'All 10 deliveries completed! Great job!',
                duration = 5000
            })
            
            -- Log delivery run completion
            TriggerServerEvent('peleg-drugrungs:server:LogDeliveryRunComplete')
            
            CleanupDelivery()
        end
    end
    
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
end

function StartNextDelivery()
    -- Check if player still has packed drugs
    local hasPackedDrugs = false
    for drugType, drugConfig in pairs(Config.Drugs) do
        local count = ClientBridge.GetItemCount(drugConfig.packed_item)
        if count > 0 then
            hasPackedDrugs = true
            break
        end
    end
    
    if not hasPackedDrugs then
        lib.notify({
            type = 'error',
            description = 'No more packed drugs! Delivery run ended.',
            duration = 3000
        })
        CleanupDelivery()
        return
    end
    
    -- Remove old blip first
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    -- Select random delivery location
    local randomLocation = Config.Delivery.delivery_locations[math.random(#Config.Delivery.delivery_locations)]
    currentDelivery = randomLocation
    
    -- Create delivery blip
    deliveryBlip = AddBlipForCoord(currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z)
    SetBlipSprite(deliveryBlip, currentDelivery.blip.sprite)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, currentDelivery.blip.scale)
    SetBlipColour(deliveryBlip, currentDelivery.blip.color)
    SetBlipAsShortRange(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(currentDelivery.blip.label)
    EndTextCommandSetBlipName(deliveryBlip)
    
    -- Set waypoint to delivery location
    SetNewWaypoint(currentDelivery.coords.x, currentDelivery.coords.y)
    
    print("New delivery blip created at: " .. currentDelivery.coords.x .. ", " .. currentDelivery.coords.y .. ", " .. currentDelivery.coords.z)
    print("New Blip ID: " .. deliveryBlip)
    
    -- Spawn delivery NPC
    local npcModel = GetHashKey(Config.Delivery.npc_models[math.random(#Config.Delivery.npc_models)])
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(1)
    end
    
    deliveryNPC = CreatePed(4, npcModel, currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z - 1.0, currentDelivery.heading, false, true)
    SetEntityAsMissionEntity(deliveryNPC, true, true)
    FreezeEntityPosition(deliveryNPC, true)
    SetEntityInvincible(deliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    
    -- Add ox_target to NPC
    exports.ox_target:addLocalEntity(deliveryNPC, {
        {
            name = 'delivery_npc_interaction',
            icon = 'fas fa-handshake',
            label = 'Deliver Drugs',
            onSelect = function()
                DeliverDrugs()
            end,
            canInteract = function()
                return true
            end
        }
    })
    
    lib.notify({
        type = 'success',
        description = string.format('Next delivery %d/%d: Go to %s', deliveryCount, maxDeliveries, currentDelivery.name),
        duration = 5000
    })
    
    -- Debug notification
    lib.notify({
        type = 'inform',
        description = 'New delivery location marked on map',
        duration = 3000
    })
    
    SetModelAsNoLongerNeeded(npcModel)
end

function CleanupDelivery()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    if deliveryNPC then
        DeleteEntity(deliveryNPC)
        deliveryNPC = nil
    end
    
    -- Don't delete the vehicle - let player keep it
    deliveryVehicle = nil
    
    currentDelivery = nil
    deliveryCount = 0 -- Reset delivery count
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Remove blips
    for _, blip in pairs(createdBlips) do
        RemoveBlip(blip)
    end
    
    -- Remove props
    for _, prop in pairs(createdTables) do
        DeleteEntity(prop)
    end
    
    -- Remove targets
    for _, target in pairs(createdTargets) do
        exports.ox_target:removeZone(target)
    end
    
    -- Clean up delivery
    CleanupDelivery()
end) 