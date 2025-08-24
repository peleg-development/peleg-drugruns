local Bridge = lib.require('shared.bridge')

local function SendDiscordLog(title, description, color, fields, thumbnail)
    if not Config.Discord.enabled or not Config.Discord.webhook_url or Config.Discord.webhook_url == 'YOUR_DISCORD_WEBHOOK_URL_HERE' then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or Config.Discord.colors.packing,
            ["footer"] = {
                ["text"] = "Drug Runs Logger • " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    if fields then
        embed[1].fields = fields
    end
    
    if thumbnail then
        embed[1].thumbnail = {
            ["url"] = thumbnail
        }
    end
    
    PerformHttpRequest(Config.Discord.webhook_url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Discord.bot_name,
        avatar_url = Config.Discord.bot_avatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function LogDrugPacking(source, drugType, drugConfig)
    if not Config.Discord.log_packing then return end
    
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local citizenid = Bridge.GetPlayerIdentifier(source)
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s\n**CitizenID:** %s", playerName, source, citizenid),
            ["inline"] = true
        },
        {
            ["name"] = "Drug Information",
            ["value"] = string.format("**Type:** %s\n**Packed Item:** %s\n**XP Reward:** +%d", drugConfig.label, drugConfig.packed_item, drugConfig.xp_reward),
            ["inline"] = true
        },
        {
            ["name"] = "Location",
            ["value"] = GetEntityCoords(GetPlayerPed(source)),
            ["inline"] = true
        }
    }
    
    SendDiscordLog(
        "🔶 Drug Packing",
        string.format("**%s** packed %s into %s", playerName, drugConfig.label, drugConfig.packed_item),
        Config.Discord.colors.packing,
        fields
    )
end

function LogDeliveryCompletion(source, totalPackedDrugs, drugsToDeliver, moneyReward, xpReward, deliveryCount)
    if not Config.Discord.log_deliveries then return end
    
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local citizenid = Bridge.GetPlayerIdentifier(source)
    
    local drugsList = ""
    for _, drugData in pairs(drugsToDeliver) do
        drugsList = drugsList .. string.format("• %s (x%d)\n", drugData.item, drugData.amount)
    end
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s\n**CitizenID:** %s", playerName, source, citizenid),
            ["inline"] = true
        },
        {
            ["name"] = "Delivery Details",
            ["value"] = string.format("**Delivery:** %d/10\n**Drugs Delivered:** %d\n**Money Earned:** $%s\n**XP Earned:** +%d", deliveryCount, totalPackedDrugs, moneyReward, xpReward),
            ["inline"] = true
        },
        {
            ["name"] = "Drugs Delivered",
            ["value"] = drugsList ~= "" and drugsList or "No drugs",
            ["inline"] = false
        }
    }
    
    SendDiscordLog(
        "🚚 Drug Delivery",
        string.format("**%s** completed delivery %d/10", playerName, deliveryCount),
        Config.Discord.colors.delivery,
        fields
    )
end

function LogLevelUp(source, oldLevel, newLevel, levelName)
    if not Config.Discord.log_level_ups then return end
    
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local citizenid = Bridge.GetPlayerIdentifier(source)
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s\n**CitizenID:** %s", playerName, source, citizenid),
            ["inline"] = true
        },
        {
            ["name"] = "Level Progress",
            ["value"] = string.format("**Old Level:** %d\n**New Level:** %d\n**Level Name:** %s", oldLevel, newLevel, levelName),
            ["inline"] = true
        }
    }
    
    SendDiscordLog(
        "⭐ Level Up!",
        string.format("**%s** reached level %d (%s)!", playerName, newLevel, levelName),
        Config.Discord.colors.level_up,
        fields
    )
end

function LogAdminAction(adminSource, targetSource, action, details)
    if not Config.Discord.log_admin_actions then return end
    
    local AdminPlayer = Bridge.GetPlayer(adminSource)
    local TargetPlayer = Bridge.GetPlayer(targetSource)
    
    if not AdminPlayer then return end
    
    local adminCharinfo = AdminPlayer.PlayerData.charinfo
    local adminName = adminCharinfo.firstname .. ' ' .. adminCharinfo.lastname
    
    local targetName = "Unknown"
    if TargetPlayer then
        local targetCharinfo = TargetPlayer.PlayerData.charinfo
        targetName = targetCharinfo.firstname .. ' ' .. targetCharinfo.lastname
    end
    
    local fields = {
        {
            ["name"] = "Admin Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s", adminName, adminSource),
            ["inline"] = true
        },
        {
            ["name"] = "Target Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s", targetName, targetSource),
            ["inline"] = true
        },
        {
            ["name"] = "Action Details",
            ["value"] = details or "No additional details",
            ["inline"] = false
        }
    }
    
    SendDiscordLog(
        "🛡️ Admin Action",
        string.format("**%s** performed action: %s", adminName, action),
        Config.Discord.colors.admin,
        fields
    )
end

function LogError(source, error, context)
    if not Config.Discord.log_errors then return end
    
    local playerName = "Unknown"
    local playerId = "Unknown"
    
    if source then
        local Player = Bridge.GetPlayer(source)
        if Player then
            local charinfo = Player.PlayerData.charinfo
            playerName = charinfo.firstname .. ' ' .. charinfo.lastname
            playerId = source
        end
    end
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s", playerName, playerId),
            ["inline"] = true
        },
        {
            ["name"] = "Error Context",
            ["value"] = context or "No context provided",
            ["inline"] = true
        },
        {
            ["name"] = "Error Details",
            ["value"] = error or "Unknown error",
            ["inline"] = false
        }
    }
    
    SendDiscordLog(
        "❌ Error Occurred",
        "An error occurred in the drug runs system",
        Config.Discord.colors.error,
        fields
    )
end

function LogDeliveryRunStart(source)
    if not Config.Discord.log_deliveries then return end
    
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local citizenid = Bridge.GetPlayerIdentifier(source)
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s\n**CitizenID:** %s", playerName, source, citizenid),
            ["inline"] = true
        },
        {
            ["name"] = "Action",
            ["value"] = "Started a new drug delivery run (10 deliveries)",
            ["inline"] = true
        }
    }
    
    SendDiscordLog(
        "🚀 Delivery Run Started",
        string.format("**%s** started a new drug delivery run", playerName),
        Config.Discord.colors.delivery,
        fields
    )
end

function LogDeliveryRunComplete(source, totalDeliveries, totalMoney, totalXP)
    if not Config.Discord.log_deliveries then return end
    
    local Player = Bridge.GetPlayer(source)
    if not Player then return end
    
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local citizenid = Bridge.GetPlayerIdentifier(source)
    
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = string.format("**Name:** %s\n**ID:** %s\n**CitizenID:** %s", playerName, source, citizenid),
            ["inline"] = true
        },
        {
            ["name"] = "Run Summary",
            ["value"] = string.format("**Total Deliveries:** %d/10\n**Total Money:** $%s\n**Total XP:** +%d", totalDeliveries, totalMoney, totalXP),
            ["inline"] = true
        }
    }
    
    SendDiscordLog(
        "🏆 Delivery Run Completed",
        string.format("**%s** completed all 10 deliveries!", playerName),
        Config.Discord.colors.level_up,
        fields
    )
end

exports('LogDrugPacking', LogDrugPacking)
exports('LogDeliveryCompletion', LogDeliveryCompletion)
exports('LogLevelUp', LogLevelUp)
exports('LogAdminAction', LogAdminAction)
exports('LogError', LogError)
exports('LogDeliveryRunStart', LogDeliveryRunStart)
exports('LogDeliveryRunComplete', LogDeliveryRunComplete) 