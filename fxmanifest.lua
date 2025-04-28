fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Paradise'
description 'Weapon Repair Script'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'scripting/client.lua'
}

server_scripts {
    'scripting/sv_config.lua',
    'scripting/server.lua'
}