local ClientBridge = lib.require('shared.client_bridge')

local packingProps = {}
local currentPackingLocation = nil

function StartVisualPacking(drugType, location)
    local drugConfig = Config.Drugs[drugType]
    if not drugConfig then return end
    
    currentPackingLocation = location
    
    local boxModel = GetHashKey(drugConfig.box_prop)
    RequestModel(boxModel)
    while not HasModelLoaded(boxModel) do
        Wait(1)
    end
    
    local boxProp = CreateObject(boxModel, location.coords.x, location.coords.y, location.coords.z + 0.5, false, false, false)
    SetEntityHeading(boxProp, location.heading)
    FreezeEntityPosition(boxProp, true)
    SetEntityAsMissionEntity(boxProp, true, true)
    
    table.insert(packingProps, boxProp)
    
    local ped = PlayerPedId()
    local animDict = Config.Animations.packing.dict
    local animName = Config.Animations.packing.anim
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, Config.Animations.packing.flag, 0, false, false, false)
    
    if lib.progressBar({
        duration = drugConfig.packing_time,
        label = string.format('Packing %s...', drugConfig.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        TriggerServerEvent('peleg-drugrungs:server:PackDrug', drugType)
        
        ClientBridge.Notify({
            type = 'success',
            description = string.format('Successfully packed %s! +%d XP', drugConfig.label, drugConfig.xp_reward),
            duration = 5000
        })
        
        TriggerServerEvent('peleg-drugrungs:server:GetPlayerStats')
    else
        ClientBridge.Notify({
            type = 'error',
            description = 'Packing cancelled',
            duration = 3000
        })
    end
    
    -- Clean up
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(boxModel)
    
    -- Remove box prop after a short delay
    SetTimeout(2000, function()
        if DoesEntityExist(boxProp) then
            DeleteEntity(boxProp)
            for i, prop in ipairs(packingProps) do
                if prop == boxProp then
                    table.remove(packingProps, i)
                    break
                end
            end
        end
    end)
end

function EnhancedDrugPacking(drugType)
    local drugConfig = Config.Drugs[drugType]
    if not drugConfig then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestLocation = nil
    local nearestDistance = math.huge
    
    for _, location in pairs(Config.PackingLocations) do
        local distance = #(playerCoords - location.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestLocation = location
        end
    end
    
    if not nearestLocation or nearestDistance > 5.0 then
        ClientBridge.Notify({
            type = 'error',
            description = 'You need to be at a packing location',
            duration = 3000
        })
        return
    end
    
    local hasItem = ClientBridge.GetItemCount(drugType)
    if hasItem < 1 then
        ClientBridge.Notify({
            type = 'error',
            description = string.format('You need %s to pack this', drugType),
            duration = 3000
        })
        return
    end
    
    StartVisualPacking(drugType, nearestLocation)
end

function CleanupPackingProps()
    for _, prop in pairs(packingProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    packingProps = {}
end

exports('StartDrugPacking', EnhancedDrugPacking)
exports('CleanupPackingProps', CleanupPackingProps)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    CleanupPackingProps()
end) 