---@class ClientBridge
---@field framework string The detected framework (qb, esx, standalone)
---@field inventory string The detected inventory system (qb, ox, esx)
---@field core table The core framework object
local ClientBridge = {}

---@type string
ClientBridge.framework = 'unknown'
---@type string  
ClientBridge.inventory = 'unknown'
---@type table
ClientBridge.core = nil

---Detects the framework and inventory system being used
---@return boolean success Whether detection was successful
local function DetectFramework()
    -- Try QB-Core first
    if GetResourceState('qb-core') == 'started' then
        ClientBridge.framework = 'qb'
        ClientBridge.core = exports['qb-core']:GetCoreObject()
        
        -- Check if ox_inventory is available
        if GetResourceState('ox_inventory') == 'started' then
            ClientBridge.inventory = 'ox'
        else
            ClientBridge.inventory = 'qb'
        end
        
        return true
    end
    
    -- Try ESX
    if GetResourceState('es_extended') == 'started' then
        ClientBridge.framework = 'esx'
        ClientBridge.core = exports['es_extended']:getSharedObject()
        
        -- Check if ox_inventory is available
        if GetResourceState('ox_inventory') == 'started' then
            ClientBridge.inventory = 'ox'
        else
            ClientBridge.inventory = 'esx'
        end
        
        return true
    end
    
    -- Standalone mode (no framework detected)
    ClientBridge.framework = 'standalone'
    ClientBridge.core = {}
    
    -- Check if ox_inventory is available
    if GetResourceState('ox_inventory') == 'started' then
        ClientBridge.inventory = 'ox'
        return true
    end
    
    return false
end

---Gets item count from inventory based on the detected system
---@param item string The item name
---@return number count The item count
function ClientBridge.GetItemCount(item)
    if ClientBridge.inventory == 'ox' then
        return exports.ox_inventory:GetItemCount(item)
    elseif ClientBridge.inventory == 'qb' then
        local Player = ClientBridge.core.Functions.GetPlayerData()
        if not Player or not Player.items then return 0 end
        
        for _, itemData in pairs(Player.items) do
            if itemData.name == item then
                return itemData.amount or 0
            end
        end
        return 0
    elseif ClientBridge.inventory == 'esx' then
        local Player = ClientBridge.core.GetPlayerData()
        if not Player or not Player.inventory then return 0 end
        
        for _, itemData in pairs(Player.inventory) do
            if itemData.name == item then
                return itemData.count or 0
            end
        end
        return 0
    end
    
    return 0
end

---Checks if player has item in inventory based on the detected system
---@param item string The item name
---@param count number The minimum item count required
---@return boolean hasItem Whether the player has the required items
function ClientBridge.HasItem(item, count)
    count = count or 1
    local itemCount = ClientBridge.GetItemCount(item)
    return itemCount >= count
end

---Gets player data based on the detected framework
---@return table|nil playerData The player data
function ClientBridge.GetPlayerData()
    if ClientBridge.framework == 'qb' then
        return ClientBridge.core.Functions.GetPlayerData()
    elseif ClientBridge.framework == 'esx' then
        return ClientBridge.core.GetPlayerData()
    end
    
    return nil
end

---Gets player identifier based on the detected framework
---@return string|nil identifier The player identifier
function ClientBridge.GetPlayerIdentifier()
    local playerData = ClientBridge.GetPlayerData()
    if not playerData then return nil end
    
    if ClientBridge.framework == 'qb' then
        return playerData.citizenid
    elseif ClientBridge.framework == 'esx' then
        return playerData.identifier
    end
    
    return nil
end

---Gets player metadata/character data based on the detected framework
---@return table|nil metadata The player metadata
function ClientBridge.GetPlayerMetadata()
    local playerData = ClientBridge.GetPlayerData()
    if not playerData then return nil end
    
    if ClientBridge.framework == 'qb' then
        return playerData.metadata
    elseif ClientBridge.framework == 'esx' then
        return playerData.character or {}
    end
    
    return {}
end

---Shows notification based on the detected framework
---@param data table The notification data
function ClientBridge.Notify(data)
    if ClientBridge.framework == 'qb' then
        ClientBridge.core.Functions.Notify(data.description, data.type, data.duration or 5000)
    elseif ClientBridge.framework == 'esx' then
        ClientBridge.core.ShowNotification(data.description)
    else
        -- Use ox_lib for standalone or as fallback
        lib.notify(data)
    end
end

---Initializes the client bridge system
---@return boolean success Whether initialization was successful
function ClientBridge.Init()
    local success = DetectFramework()
    
    if success then
        print(string.format('[ClientBridge] Framework detected: %s, Inventory: %s', ClientBridge.framework, ClientBridge.inventory))
    else
        print('[ClientBridge] Warning: No framework detected, running in standalone mode')
    end
    
    return success
end

-- Initialize the bridge
ClientBridge.Init()

return ClientBridge
