fx_version 'cerulean'

shared_script "@SecureServe/src/module/module.lua"
shared_script "@SecureServe/src/module/module.js"
file "@SecureServe/secureserve.key"

game 'gta5'

author 'Your Name'
description 'Drug Runs Resource with ox_lib integration'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/bridge.lua',
    'config.lua'
}

client_scripts {
    'shared/client_bridge.lua',
    'client/main.lua',
    'client/packing.lua',
    'client/npc.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/levels.lua',
    'server/logs.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
}

lua54 'yes' 