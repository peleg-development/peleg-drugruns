# Peleg Drug Runs Resource

A FiveM drug packing resource with ox_lib integration, level system, and QBox metadata storage.

## Installation

1. **Download** the resource and place it in your server's `resources` folder
2. **Add** `ensure peleg-drugruns` to your `server.cfg`
3. **Configure** the settings in `config.lua` (see Configuration section below)
4. **Restart** your server

## Dependencies

- `ox_lib`
- `ox_target` 
- `ox_inventory`
- `qb-core`

## Configuration

### Required Items Setup

You need to add these items to your `ox_inventory/data/items.lua`:

```lua
-- Cured drugs (input items)
['meth_cured'] = {
    label = 'Cured Meth',
    weight = 100,
    stack = true,
    close = true,
    description = 'Cured meth ready for packing'
},
['coke_cured'] = {
    label = 'Cured Cocaine', 
    weight = 100,
    stack = true,
    close = true,
    description = 'Cured cocaine ready for packing'
},
['weed_cured'] = {
    label = 'Cured Weed',
    weight = 100,
    stack = true,
    close = true,
    description = 'Cured weed ready for packing'
},

-- Packed drugs (output items)
['meth_packed'] = {
    label = 'Packed Meth',
    weight = 200,
    stack = true,
    close = true,
    description = 'Packed meth ready for sale'
},
['coke_packed'] = {
    label = 'Packed Cocaine',
    weight = 200,
    stack = true,
    close = true,
    description = 'Packed cocaine ready for sale'
},
['weed_packed'] = {
    label = 'Packed Weed',
    weight = 200,
    stack = true,
    close = true,
    description = 'Packed weed ready for sale'
}
```

### Location Configuration

#### Packing Locations
Edit `Config.PackingLocations` in `config.lua`:

```lua
Config.PackingLocations = {
    {
        name = 'Warehouse A',
        coords = vec3(782.17, -146.99, 78.49), -- Change these coordinates
        heading = 59.52, -- Change heading
        blip = {
            sprite = 140,
            color = 1,
            scale = 0.8,
            label = 'Drug Packing'
        }
    }
    -- Add more locations as needed
}
```

#### NPC Location
Edit `Config.NPC` in `config.lua`:

```lua
Config.NPC = {
    model = 'g_m_y_lost_01', -- Change NPC model
    coords = vec4(773.9665, -149.8865, 75.6219, 142.1734), -- Change coordinates and heading
    scenario = 'WORLD_HUMAN_SMOKING',
    blip = {
        sprite = 140,
        color = 1,
        scale = 0.8,
        label = 'Drug Boss'
    }
}
```

#### Delivery Locations
Edit `Config.Delivery.delivery_locations` in `config.lua`:

```lua
delivery_locations = {
    {
        name = 'Drug Drop',
        coords = vec4(358.12, -810.13, 29.29, 266.48), -- Change coordinates and heading
        blip = {
            sprite = 140,
            color = 1,
            scale = 1.0,
            label = 'Drug Drop'
        }
    }
    -- Add more delivery locations
}
```

### Drug Configuration

Edit `Config.Drugs` in `config.lua` to customize:

```lua
Config.Drugs = {
    meth_cured = {
        label = 'Meth',
        packed_item = 'meth_packed', -- Must match item name in ox_inventory
        xp_reward = 150,
        packing_time = 8000, -- Time in milliseconds
        prop = 'prop_cs_box_clothes',
        table_prop = 'prop_table_03',
        box_prop = 'prop_cs_box_clothes'
    }
    -- Add more drug types
}
```

### Discord Webhook (Optional)

If you want Discord logging, edit `Config.Discord` in `config.lua`:

```lua
Config.Discord = {
    enabled = true,
    webhook_url = 'YOUR_DISCORD_WEBHOOK_URL_HERE', -- Replace with your webhook
    bot_name = 'Drug Runs Logger'
}
```

### QBCore Metadata Setup

The resource stores player progress in QBCore metadata. Add this to your `qb-core/shared/players.lua` in the `QBConfig.Player` section:

```lua
QBConfig.Player = {
    -- existing config ...

    PlayerData = {
        -- existing defaults...
        metadata = {
            -- existing metadata...
            drug_runs = {
                level = 1,
                exp = 0,
                total_packed = 0
            }
        }
    }
}

```

## Support

Make sure all dependencies are installed and items are properly configured in ox_inventory before starting the resource. 