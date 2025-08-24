---@class Bridge
---@field framework string The detected framework (qb, esx, standalone)
---@field inventory string The detected inventory system (qb, ox, esx)
---@field core table The core framework object
local Bridge = {}

---@type string
Bridge.framework = 'unknown'
---@type string  
Bridge.inventory = 'unknown'
---@type table
Bridge.core = nil

---Detects the framework and inventory system being used
---@return boolean success Whether detection was successful
local function DetectFramework()
    -- Try QB-Core first
    if GetResourceState('qb-core') == 'started' then
        Bridge.framework = 'qb'
        Bridge.core = exports['qb-core']:GetCoreObject()
        
        -- Check if ox_inventory is available
        if GetResourceState('ox_inventory') == 'started' then
            Bridge.inventory = 'ox'
        else
            Bridge.inventory = 'qb'
        end
        
        return true
    end
    
    -- Try ESX
    if GetResourceState('es_extended') == 'started' then
        Bridge.framework = 'esx'
        Bridge.core = exports['es_extended']:getSharedObject()
        
        -- Check if ox_inventory is available
        if GetResourceState('ox_inventory') == 'started' then
            Bridge.inventory = 'ox'
        else
            Bridge.inventory = 'esx'
        end
        
        return true
    end
    
    -- Standalone mode (no framework detected)
    Bridge.framework = 'standalone'
    Bridge.core = {}
    
    -- Check if ox_inventory is available
    if GetResourceState('ox_inventory') == 'started' then
        Bridge.inventory = 'ox'
        return true
    end
    
    return false
end

---Gets a player object based on the detected framework
---@param source number The player source
---@return table|nil player The player object or nil if not found
function Bridge.GetPlayer(source)
    if Bridge.framework == 'qb' then
        return Bridge.core.Functions.GetPlayer(source)
    elseif Bridge.framework == 'esx' then
        return Bridge.core.GetPlayerFromId(source)
    end
    
    return nil
end

---Gets all players based on the detected framework
---@return table players Table of all players
function Bridge.GetPlayers()
    if Bridge.framework == 'qb' then
        return Bridge.core.Functions.GetQBPlayers()
    elseif Bridge.framework == 'esx' then
        return Bridge.core.GetPlayers()
    end
    
    return {}
end

---Gets player identifier based on the detected framework
---@param source number The player source
---@return string|nil identifier The player identifier
function Bridge.GetPlayerIdentifier(source)
    local player = Bridge.GetPlayer(source)
    if not player then return nil end
    
    if Bridge.framework == 'qb' then
        return player.PlayerData.citizenid
    elseif Bridge.framework == 'esx' then
        return player.identifier
    end
    
    return nil
end

---Gets player metadata/character data based on the detected framework
---@param source number The player source
---@return table|nil metadata The player metadata
function Bridge.GetPlayerMetadata(source)
    local player = Bridge.GetPlayer(source)
    if not player then return nil end
    
    if Bridge.framework == 'qb' then
        return player.PlayerData.metadata
    elseif Bridge.framework == 'esx' then
        return player.get('character') or {}
    end
    
    return {}
end

---Sets player metadata/character data based on the detected framework
---@param source number The player source
---@param key string The metadata key
---@param value any The metadata value
function Bridge.SetPlayerMetadata(source, key, value)
    local player = Bridge.GetPlayer(source)
    if not player then return end
    
    if Bridge.framework == 'qb' then
        player.Functions.SetMetaData(key, value)
    elseif Bridge.framework == 'esx' then
        player.set(key, value)
    end
end

---Adds money to player based on the detected framework
---@param source number The player source
---@param moneyType string The type of money (cash, bank, crypto)
---@param amount number The amount to add
function Bridge.AddMoney(source, moneyType, amount)
    local player = Bridge.GetPlayer(source)
    if not player then return end
    
    if Bridge.framework == 'qb' then
        player.Functions.AddMoney(moneyType, amount)
    elseif Bridge.framework == 'esx' then
        if moneyType == 'cash' then
            player.addMoney(amount)
        elseif moneyType == 'bank' then
            player.addAccountMoney('bank', amount)
        end
    end
end

---Gets item count from inventory based on the detected system
---@param source number The player source
---@param item string The item name
---@return number count The item count
function Bridge.GetItemCount(source, item)
    if Bridge.inventory == 'ox' then
        return exports.ox_inventory:GetItemCount(source, item)
    elseif Bridge.inventory == 'qb' then
        local player = Bridge.GetPlayer(source)
        if not player then return 0 end
        local itemData = player.Functions.GetItemByName(item)
        return itemData and itemData.amount or 0
    elseif Bridge.inventory == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then return 0 end
        local item = player.getInventoryItem(item)
        return item and item.count or 0
    end
    
    return 0
end

---Adds item to inventory based on the detected system
---@param source number The player source
---@param item string The item name
---@param count number The item count
---@param metadata table|nil The item metadata
---@return boolean success Whether the item was added successfully
function Bridge.AddItem(source, item, count, metadata)
    if Bridge.inventory == 'ox' then
        return exports.ox_inventory:AddItem(source, item, count, metadata)
    elseif Bridge.inventory == 'qb' then
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        return player.Functions.AddItem(item, count, false, metadata)
    elseif Bridge.inventory == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        player.addInventoryItem(item, count)
        -- ESX addInventoryItem doesn't return a boolean, so we check if the item was actually added
        local newCount = player.getInventoryItem(item).count
        return newCount > 0
    end
    
    return false
end

---Removes item from inventory based on the detected system
---@param source number The player source
---@param item string The item name
---@param count number The item count
---@return boolean success Whether the item was removed successfully
function Bridge.RemoveItem(source, item, count)
    if Bridge.inventory == 'ox' then
        return exports.ox_inventory:RemoveItem(source, item, count)
    elseif Bridge.inventory == 'qb' then
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveItem(item, count)
    elseif Bridge.inventory == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        player.removeInventoryItem(item, count)
        -- ESX removeInventoryItem doesn't return a boolean, so we assume it worked
        return true
    end
    
    return false
end

---Checks if player has item in inventory based on the detected system
---@param source number The player source
---@param item string The item name
---@param count number The minimum item count required
---@return boolean hasItem Whether the player has the required items
function Bridge.HasItem(source, item, count)
    count = count or 1
    local itemCount = Bridge.GetItemCount(source, item)
    return itemCount >= count
end

---Sends notification to player based on the detected framework
---@param source number The player source
---@param data table The notification data
function Bridge.Notify(source, data)
    if Bridge.framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, data.description, data.type, data.duration or 5000)
    elseif Bridge.framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, data.description)
    else
        -- Use ox_lib for standalone or as fallback
        TriggerClientEvent('ox_lib:notify', source, data)
    end
end

---Initializes the bridge system
---@return boolean success Whether initialization was successful
function Bridge.Init()
    local success = DetectFramework()
    
    if success then
        print(string.format('[Bridge] Framework detected: %s, Inventory: %s', Bridge.framework, Bridge.inventory))
    else
        print('[Bridge] Warning: No framework detected, running in standalone mode')
    end
    
    return success
end

-- Initialize the bridge
Bridge.Init()

return Bridge
