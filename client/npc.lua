local drugBossNPC = nil


CreateThread(function()
    Wait(3000) 
    
    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    drugBossNPC = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityHeading(drugBossNPC, Config.NPC.coords.w)
    FreezeEntityPosition(drugBossNPC, true)
    SetEntityInvincible(drugBossNPC, true)
    SetBlockingOfNonTemporaryEvents(drugBossNPC, true)
    
    if Config.NPC.scenario then
        TaskStartScenarioInPlace(drugBossNPC, Config.NPC.scenario, 0, true)
    end
    
    exports.ox_target:addLocalEntity(drugBossNPC, {
        {
            name = 'drug_boss_interaction',
            icon = 'fas fa-user-tie',
            label = 'Talk to Drug Boss',
            onSelect = function()
                ShowDrugBossMenu()
            end,
            canInteract = function()
                return true
            end
        }
    })
    
    SetModelAsNoLongerNeeded(model)
end)

function ShowDrugBossMenu()
    lib.registerContext({
        id = 'drug_boss_menu',
        title = 'Drug Boss',
        options = {
            {
                title = 'Start Drug Run',
                description = 'Start a drug delivery mission',
                icon = 'fas fa-motorcycle',
                iconColor = '#ff5722',
                onSelect = function()
                    StartDrugDelivery()
                end
            },
            {
                title = 'Pack Drugs',
                description = 'Pack your cured drugs into sellable packages',
                icon = 'fas fa-box',
                iconColor = '#42a5f5',
                onSelect = function()
                    ShowDrugPackingMenu()
                end
            },
            {
                title = 'View Progress',
                description = 'Check your drug running progress',
                icon = 'fas fa-chart-line',
                iconColor = '#2196f3',
                onSelect = function()
                    ShowDrugRunsMenu()
                end
            },
            {
                title = 'Learn the Trade',
                description = 'Get information about drug packing',
                icon = 'fas fa-info-circle',
                iconColor = '#ff9800',
                onSelect = function()
                    ShowDrugInfo()
                end
            }
        }
    })
    
    lib.showContext('drug_boss_menu')
end

function StartDrugRuns()
    lib.registerContext({
        id = 'start_drug_runs_menu',
        title = 'Starting Drug Runs',
        menu = 'drug_boss_menu',
        options = {
            {
                title = 'How It Works',
                description = 'Learn how drug packing works',
                icon = 'fas fa-question-circle',
                iconColor = '#2196f3',
                metadata = {
                    { label = 'Step 1', value = 'Get cured drugs (meth_cured, coke_cured, weed_cured)' },
                    { label = 'Step 2', value = 'Go to a packing location (marked on map)' },
                    { label = 'Step 3', value = 'Use the packing table to pack your drugs' },
                    { label = 'Step 4', value = 'Earn XP and packed drugs for selling' }
                }
            },
            {
                title = 'Packing Locations',
                description = 'Find where to pack your drugs',
                icon = 'fas fa-map-marker-alt',
                iconColor = '#4caf50',
                metadata = {
                    { label = 'Warehouse A', value = 'Located in the industrial area' },
                    { label = 'Abandoned Factory', value = 'Hidden location in the mountains' }
                }
            },
            {
                title = 'Drug Types',
                description = 'Information about different drugs',
                icon = 'fas fa-pills',
                iconColor = '#ff5722',
                metadata = {
                    { label = 'Meth', value = string.format('+%d XP, %d seconds', Config.Drugs.meth_cured.xp_reward, Config.Drugs.meth_cured.packing_time / 1000) },
                    { label = 'Cocaine', value = string.format('+%d XP, %d seconds', Config.Drugs.coke_cured.xp_reward, Config.Drugs.coke_cured.packing_time / 1000) },
                    { label = 'Weed', value = string.format('+%d XP, %d seconds', Config.Drugs.weed_cured.xp_reward, Config.Drugs.weed_cured.packing_time / 1000) }
                }
            },
            {
                title = 'Back',
                description = 'Return to drug boss menu',
                icon = 'fas fa-arrow-left',
                iconColor = '#9e9e9e',
                onSelect = function()
                    ShowDrugBossMenu()
                end
            }
        }
    })
    
    lib.showContext('start_drug_runs_menu')
end

function ShowDrugInfo()
    lib.registerContext({
        id = 'drug_info_menu',
        title = 'Drug Information',
        menu = 'drug_boss_menu',
        options = {
            {
                title = 'Meth Packing',
                description = 'Pack meth_cured into meth_packed',
                icon = 'fas fa-flask',
                iconColor = '#e91e63',
                metadata = {
                    { label = 'Input Item', value = 'meth_cured' },
                    { label = 'Output Item', value = 'meth_packed' },
                    { label = 'XP Reward', value = string.format('+%d XP', Config.Drugs.meth_cured.xp_reward) },
                    { label = 'Packing Time', value = string.format('%d seconds', Config.Drugs.meth_cured.packing_time / 1000) }
                }
            },
            {
                title = 'Cocaine Packing',
                description = 'Pack coke_cured into coke_packed',
                icon = 'fas fa-snowflake',
                iconColor = '#ffffff',
                metadata = {
                    { label = 'Input Item', value = 'coke_cured' },
                    { label = 'Output Item', value = 'coke_packed' },
                    { label = 'XP Reward', value = string.format('+%d XP', Config.Drugs.coke_cured.xp_reward) },
                    { label = 'Packing Time', value = string.format('%d seconds', Config.Drugs.coke_cured.packing_time / 1000) }
                }
            },
            {
                title = 'Weed Packing',
                description = 'Pack weed_cured into weed_packed',
                icon = 'fas fa-leaf',
                iconColor = '#4caf50',
                metadata = {
                    { label = 'Input Item', value = 'weed_cured' },
                    { label = 'Output Item', value = 'weed_packed' },
                    { label = 'XP Reward', value = string.format('+%d XP', Config.Drugs.weed_cured.xp_reward) },
                    { label = 'Packing Time', value = string.format('%d seconds', Config.Drugs.weed_cured.packing_time / 1000) }
                }
            },
            {
                title = 'Level System',
                description = 'How the leveling system works',
                icon = 'fas fa-star',
                iconColor = '#ffd700',
                metadata = {
                    { label = 'Max Level', value = Config.Levels.max_level },
                    { label = 'XP Multiplier', value = string.format('%.1fx', Config.Levels.xp_multiplier) },
                    { label = 'Level Names', value = 'Rookie, Beginner, Amateur, etc.' }
                }
            },
            {
                title = 'Back',
                description = 'Return to drug boss menu',
                icon = 'fas fa-arrow-left',
                iconColor = '#9e9e9e',
                onSelect = function()
                    ShowDrugBossMenu()
                end
            }
        }
    })
    
    lib.showContext('drug_info_menu')
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if drugBossNPC and DoesEntityExist(drugBossNPC) then
        DeleteEntity(drugBossNPC)
    end
end) 