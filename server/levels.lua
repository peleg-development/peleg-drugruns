local Bridge = lib.require('shared.bridge')

local LevelRewards = {
    [5] = { money = 1000, items = {} },
    [10] = { money = 2500, items = {} },
    [15] = { money = 5000, items = {} },
    [20] = { money = 7500, items = {} },
    [25] = { money = 10000, items = {} },
    [30] = { money = 15000, items = {} },
    [35] = { money = 20000, items = {} },
    [40] = { money = 25000, items = {} },
    [45] = { money = 30000, items = {} },
    [50] = { money = 50000, items = {} }
}

local function GiveLevelRewards(source, level)
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local reward = LevelRewards[level]
    if not reward then return end
    
    if reward.money and reward.money > 0 then
        Bridge.AddMoney(source, 'cash', reward.money)
        Bridge.Notify(source, {
            type = 'success',
            description = string.format('Level %d Reward: $%s', level, reward.money),
            duration = 5000
        })
    end
    
    if reward.items and #reward.items > 0 then
        for _, item in pairs(reward.items) do
            Bridge.AddItem(source, item.name, item.count or 1)
        end
    end
end

local function GetPlayerLevelInfo(source)
    local Player = Bridge.GetPlayer(source)
    if not Player then return nil end
    
    local citizenid = Bridge.GetPlayerIdentifier(source)
    local metadata = Bridge.GetPlayerMetadata(source)
    
    if not metadata.drug_runs then
        return {
            level = 1,
            exp = 0,
            total_packed = 0,
            next_level_xp = GetXPForLevel(1),
            level_name = Config.LevelColors[1] and Config.LevelColors[1].name or 'Rookie'
        }
    end
    
    local levelData = metadata.drug_runs
    local nextLevelXP = GetXPForLevel(levelData.level)
    local levelName = Config.LevelColors[levelData.level] and Config.LevelColors[levelData.level].name or 'Unknown'
    
    return {
        level = levelData.level,
        exp = levelData.exp,
        total_packed = levelData.total_packed,
        next_level_xp = nextLevelXP,
        level_name = levelName
    }
end

local function GetTopPlayers(limit)
    limit = limit or 10
    
    local players = {}
    for _, Player in pairs(Bridge.GetPlayers()) do
        local levelInfo = GetPlayerLevelInfo(Player.PlayerData.source)
        if levelInfo then
            table.insert(players, {
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                level = levelInfo.level,
                exp = levelInfo.exp,
                total_packed = levelInfo.total_packed
            })
        end
    end
    
    table.sort(players, function(a, b)
        if a.level == b.level then
            return a.exp > b.exp
        end
        return a.level > b.level
    end)
    
    return players
end

RegisterNetEvent('peleg-drugrungs:server:GetTopPlayers', function()
    local source = source
    local topPlayers = GetTopPlayers(10)
    
    TriggerClientEvent('peleg-drugrungs:client:ReceiveTopPlayers', source, topPlayers)
end)

RegisterNetEvent('peleg-drugrungs:server:GetPlayerLevelInfo', function()
    local source = source
    local levelInfo = GetPlayerLevelInfo(source)
    
    if levelInfo then
        TriggerClientEvent('peleg-drugrungs:client:ReceivePlayerLevelInfo', source, levelInfo)
    end
end)


exports('GetPlayerLevelInfo', GetPlayerLevelInfo)
exports('GetTopPlayers', GetTopPlayers)
exports('GiveLevelRewards', GiveLevelRewards) 