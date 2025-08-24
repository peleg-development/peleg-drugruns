local Bridge = lib.require('shared.bridge')

-- Player data storage
local PlayerData = {}

-- Initialize player data
local function InitializePlayerData(source)
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local citizenid = Bridge.GetPlayerIdentifier(source)
    local metadata = Bridge.GetPlayerMetadata(source)
    
    if not metadata.drug_runs then
        metadata.drug_runs = {
            level = 1,
            exp = 0,
            total_packed = 0
        }
        Bridge.SetPlayerMetadata(source, 'drug_runs', metadata.drug_runs)
    end
    
    PlayerData[citizenid] = metadata.drug_runs
end

-- Get player level data
local function GetPlayerLevelData(source)
    local Player = Bridge.GetPlayer(source)
    if not Player then return nil end
    
    local citizenid = Bridge.GetPlayerIdentifier(source)
    if not PlayerData[citizenid] then
        InitializePlayerData(source)
    end
    
    return PlayerData[citizenid]
end

-- Calculate XP needed for next level
local function GetXPForLevel(level)
    if level >= Config.Levels.max_level then
        return 0
    end
    
    return Config.Levels.base_xp_requirements[level] or 100
end

-- Add XP to player
local function AddXP(source, xp)
    local Player = Bridge.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Bridge.GetPlayerIdentifier(source)
    local levelData = GetPlayerLevelData(source)
    
    if not levelData then return false end
    
    levelData.exp = levelData.exp + xp
    print(string.format('[DEBUG] Added %d XP, total XP: %d, current level: %d', xp, levelData.exp, levelData.level))
    
    -- Check for level up
    local currentLevel = levelData.level
    local xpNeeded = GetXPForLevel(currentLevel)
    print(string.format('[DEBUG] XP needed for level %d: %d', currentLevel, xpNeeded))
    
    while levelData.exp >= xpNeeded and currentLevel < Config.Levels.max_level do
        levelData.exp = levelData.exp - xpNeeded
        currentLevel = currentLevel + 1
        levelData.level = currentLevel
        xpNeeded = GetXPForLevel(currentLevel)
        print(string.format('[DEBUG] Level up to %d! Remaining XP: %d, next level needs: %d', currentLevel, levelData.exp, xpNeeded))
        
        -- Notify player of level up
        Bridge.Notify(source, {
            type = 'success',
            description = string.format('Level Up! You are now level %d', currentLevel),
            duration = 5000
        })
        
        -- Log level up
        local levelName = Config.LevelColors[currentLevel] and Config.LevelColors[currentLevel].name or 'Unknown'
        LogLevelUp(source, currentLevel - 1, currentLevel, levelName)
    end
    
    Bridge.SetPlayerMetadata(source, 'drug_runs', levelData)
    PlayerData[citizenid] = levelData
    
    return true
end

RegisterNetEvent('peleg-drugrungs:server:PackDrug', function(drugType)
    local source = source
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local drugConfig = Config.Drugs[drugType]
    if not drugConfig then
        Bridge.Notify(source, {
            type = 'error',
            description = 'Invalid drug type',
            duration = 3000
        })
        return
    end
    
    local hasItem = Bridge.GetItemCount(source, drugType)
    print(string.format('[DEBUG] Player has %s: %d', drugType, hasItem))
    
    if hasItem < 1 then
        Bridge.Notify(source, {
            type = 'error',
            description = string.format('You need %s to pack this', drugConfig.label),
            duration = 3000
        })
        return
    end
    
    local removed = Bridge.RemoveItem(source, drugType, 1)
    if not removed then
        Bridge.Notify(source, {
            type = 'error',
            description = 'Failed to remove item',
            duration = 3000
        })
        return
    end
    
    local added = Bridge.AddItem(source, drugConfig.packed_item, 1)
    print(string.format('[DEBUG] Packing %s -> %s, AddItem returned: %s', drugType, drugConfig.packed_item, tostring(added)))
    
    if not added then
        local giveBack = Bridge.AddItem(source, drugType, 1)
        print(string.format('[DEBUG] Giving back %s, AddItem returned: %s', drugType, tostring(giveBack)))
        Bridge.Notify(source, {
            type = 'error',
            description = 'Failed to add packed item',
            duration = 3000
        })
        return
    end
    
    local levelData = GetPlayerLevelData(source)
    if levelData then
        levelData.total_packed = levelData.total_packed + 1
        Bridge.SetPlayerMetadata(source, 'drug_runs', levelData)
        PlayerData[Bridge.GetPlayerIdentifier(source)] = levelData
    end
    
    AddXP(source, drugConfig.xp_reward)
    
    LogDrugPacking(source, drugType, drugConfig)
    
    Bridge.Notify(source, {
        type = 'success',
        description = string.format('Successfully packed %s! +%d XP', drugConfig.label, drugConfig.xp_reward),
        duration = 5000
    })
end)

RegisterNetEvent('peleg-drugrungs:server:GetPlayerStats', function()
    local source = source
    local levelData = GetPlayerLevelData(source)
    
    if not levelData then
        TriggerClientEvent('peleg-drugrungs:client:ReceivePlayerStats', source, {
            level = 1,
            exp = 0,
            total_packed = 0,
            next_level_xp = GetXPForLevel(1)
        })
        return
    end
    
    local nextLevelXP = GetXPForLevel(levelData.level)
    
    TriggerClientEvent('peleg-drugrungs:client:ReceivePlayerStats', source, {
        level = levelData.level,
        exp = levelData.exp,
        total_packed = levelData.total_packed,
        next_level_xp = nextLevelXP
    })
end)

RegisterNetEvent('peleg-drugrungs:server:CompleteDelivery', function(totalPackedDrugs, drugsToDeliver)
    local source = source
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local moneyReward = math.random(Config.Delivery.delivery_rewards.money.min, Config.Delivery.delivery_rewards.money.max)
    local xpReward = math.random(Config.Delivery.delivery_rewards.xp.min, Config.Delivery.delivery_rewards.xp.max)
    
    for _, drugData in pairs(drugsToDeliver) do
        Bridge.RemoveItem(source, drugData.item, drugData.amount)
    end
    
    Bridge.AddMoney(source, 'cash', moneyReward)
    AddXP(source, xpReward)
    
    local levelData = GetPlayerLevelData(source)
    if levelData then
        levelData.total_delivered = (levelData.total_delivered or 0) + totalPackedDrugs
        Bridge.SetPlayerMetadata(source, 'drug_runs', levelData)
        PlayerData[Bridge.GetPlayerIdentifier(source)] = levelData
    end
    
    LogDeliveryCompletion(source, totalPackedDrugs, drugsToDeliver, moneyReward, xpReward, levelData and levelData.total_delivered or 0)
    
    Bridge.Notify(source, {
        type = 'success',
        description = string.format('Delivery completed! +$%s, +%d XP', moneyReward, xpReward),
        duration = 5000
    })
    
    TriggerClientEvent('peleg-drugrungs:client:ReceivePlayerStats', source, {
        level = levelData and levelData.level or 1,
        exp = levelData and levelData.exp or 0,
        total_packed = levelData and levelData.total_packed or 0,
        next_level_xp = GetXPForLevel(levelData and levelData.level or 1)
    })
end)

RegisterNetEvent('peleg-drugrungs:server:GiveVehicleKeys', function(vehicleNetId)
    local source = source
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    Bridge.AddItem(source, 'vehicle_key', 1, {
        plate = GetVehicleNumberPlateText(NetworkGetEntityFromNetworkId(vehicleNetId)),
        vehicle = Config.Delivery.dirt_bike
    })
    
    Bridge.Notify(source, {
        type = 'success',
        description = 'You received keys to the dirt bike',
        duration = 3000
    })
end)

RegisterNetEvent('peleg-drugrungs:server:LogDeliveryRunStart', function()
    local source = source
    LogDeliveryRunStart(source)
end)

RegisterNetEvent('peleg-drugrungs:server:LogDeliveryRunComplete', function()
    local source = source
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local levelData = GetPlayerLevelData(source)
    local totalDeliveries = levelData and levelData.total_delivered or 0
    local totalMoney = 0
    local totalXP = 0
    
    LogDeliveryRunComplete(source, totalDeliveries, totalMoney, totalXP)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local Player = Bridge.GetPlayer(source)
    if Player then
        PlayerData[Bridge.GetPlayerIdentifier(source)] = nil
    end
end) 