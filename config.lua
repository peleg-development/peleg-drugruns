Config = {}

-- Drug Types and their properties
Config.Drugs = {
    meth_cured = {
        label = 'Meth',
        packed_item = 'meth_packed',
        xp_reward = 150,
        packing_time = 8000,
        prop = 'prop_cs_box_clothes',
        table_prop = 'prop_table_03',
        box_prop = 'prop_cs_box_clothes'
    },
    coke_cured = {
        label = 'Cocaine',
        packed_item = 'coke_packed',
        xp_reward = 200,
        packing_time = 10000,
        prop = 'prop_cs_box_clothes',
        table_prop = 'prop_table_03',
        box_prop = 'prop_cs_box_clothes'
    },
    weed_cured = {
        label = 'Weed',
        packed_item = 'weed_packed',
        xp_reward = 100,
        packing_time = 6000,
        prop = 'prop_cs_box_clothes',
        table_prop = 'prop_table_03',
        box_prop = 'prop_cs_box_clothes'
    }
}

-- Packing Locations
Config.PackingLocations = {
    {
        name = 'Warehouse A',
        coords = vec3(782.17, -146.99, 78.49),
        heading = 59.52,
        blip = {
            sprite = 140,
            color = 1,
            scale = 0.8,
            label = 'Drug Packing'
        }
    }
}

-- NPC Configuration
Config.NPC = {
    model = 'g_m_y_lost_01',
    coords = vec4(773.9665, -149.8865, 75.6219, 142.1734),
    scenario = 'WORLD_HUMAN_SMOKING',
    blip = {
        sprite = 140,
        color = 1,
        scale = 0.8,
        label = 'Drug Boss'
    }
}

-- Level System Configuration
Config.Levels = {
    max_level = 50,
    xp_multiplier = 1.2,
    base_xp_requirements = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, -- Levels 1-10
        12, 14, 16, 18, 20, 22, 24, 26, 28, 30, -- Levels 11-20
        35, 40, 45, 50, 55, 60, 65, 70, 75, 80, -- Levels 21-30
        90, 100, 110, 120, 130, 140, 150, 160, 170, 180, -- Levels 31-40
        200, 220, 240, 260, 280, 300, 320, 340, 360, 380 -- Levels 41-50
    }
}

-- Level Colors for UI
Config.LevelColors = {
    [1] = { name = 'Rookie', color = '#9e9e9e' },
    [2] = { name = 'Beginner', color = '#4caf50' },
    [3] = { name = 'Amateur', color = '#2196f3' },
    [4] = { name = 'Intermediate', color = '#ff9800' },
    [5] = { name = 'Advanced', color = '#f44336' },
    [6] = { name = 'Expert', color = '#9c27b0' },
    [7] = { name = 'Master', color = '#ff5722' },
    [8] = { name = 'Legend', color = '#e91e63' },
    [9] = { name = 'Elite', color = '#673ab7' },
    [10] = { name = 'God', color = '#ffd700' }
}

-- Animation Configuration
Config.Animations = {
    packing = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
        flag = 49
    },
    delivery = {
        dict = 'mp_common',
        anim = 'givetake1_a',
        flag = 49
    }
}

-- Delivery System Configuration
Config.Delivery = {
    dirt_bike = 'sanchez2',
    delivery_locations = {
        {
            name = 'Drug Drop',
            coords = vec4(358.12, -810.13, 29.29, 266.48),
            heading = 320.0,
            blip = {
                sprite = 140,
                color = 1,
                scale = 1.0,
                label = 'Drug Drop'
            }
        },
        {
            name = 'Drug Drop',
            coords = vec4(295.29, -1007.14, 29.33, 347.08),
            heading = 320.0,
            blip = {
                sprite = 140,
                color = 1,
                scale = 1.0,
                label = 'Drug Drop'
            }
        },
        {
            name = 'Drug Drop',
            coords = vec4(170.49, -758.15, 32.83, 101.57),
            heading = 320.0,
            blip = {
                sprite = 140,
                color = 1,
                scale = 1.0,
                label = 'Drug Drop'
            }
        },
        {
            name = 'Drug Drop',
            coords = vec4(-83.56, -1008.33, 27.85, 174.72),
            heading = 320.0,
            blip = {
                sprite = 140,
                color = 1,
                scale = 1.0,
                label = 'Drug Drop'
            }
        },
      ---
      {
        name = 'Drug Drop',
        coords = vec4(10.13, -1838.74, 24.72, 63.85),
        heading = 320.0,
        blip = {
            sprite = 140,
            color = 1,
            scale = 1.0,
            label = 'Drug Drop'
        }
    },   {
        name = 'Drug Drop',
        coords = vec4(219.97, -1872.11, 26.79, 164.08),
        heading = 320.0,
        blip = {
            sprite = 140,
            color = 1,
            scale = 1.0,
            label = 'Drug Drop'
        }
    },   {
        name = 'Drug Drop',
        coords = vec4(400.71, -1871.8, 26.48, 227.35),
        heading = 320.0,
        blip = {
            sprite = 140,
            color = 1,
            scale = 1.0,
            label = 'Drug Drop'
        }
    },
---
{
    name = 'Drug Drop',
    coords = vec4(435.6, -1314.52, 31.05, 317.29),
    heading = 320.0,
    blip = {
        sprite = 140,
        color = 1,
        scale = 1.0,
        label = 'Drug Drop'
    }
},  {
    name = 'Drug Drop',
    coords = vec4(-287.42, -605.94, 33.56, 167.66),
    heading = 320.0,
    blip = {
        sprite = 140,
        color = 1,
        scale = 1.0,
        label = 'Drug Drop'
    }
},

    
    },
    npc_models = {
        'g_m_y_lost_01',
        'g_m_y_lost_02',
        'g_m_y_lost_03',
        'g_m_y_salvagang_01',
        'g_m_y_salvagang_02'
    },
    delivery_rewards = {
        money = { min = 500, max = 1500 },
        xp = { min = 10, max = 25 }
    }
}

-- Notification Settings
Config.Notifications = {
    success = {
        type = 'success',
        duration = 5000
    },
    error = {
        type = 'error',
        duration = 5000
    },
    info = {
        type = 'inform',
        duration = 3000
    }
}

-- Discord Webhook Configuration
Config.Discord = {
    enabled = true,
    webhook_url = 'Your Webhook URL', -- Replace with your webhook URL
    bot_name = 'Drug Runs Logger',
    bot_avatar = 'https://i.imgur.com/example.png', -- Optional: bot avatar URL
    
    -- Logging settings
    log_packing = true,      -- Log when players pack drugs
    log_deliveries = true,   -- Log delivery completions
    log_level_ups = true,    -- Log when players level up
    log_admin_actions = true, -- Log admin commands
    log_errors = true,       -- Log errors and issues
    
    -- Embed colors
    colors = {
        packing = 0x4CAF50,    -- Green
        delivery = 0x2196F3,   -- Blue
        level_up = 0xFFD700,   -- Gold
        admin = 0xFF5722,      -- Orange
        error = 0xF44336       -- Red
    }
} 