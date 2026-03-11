fx_version 'cerulean'
game 'gta5'

author 'Nesox'
description 'Vehicle Persistence with tarp'
version '1.3.0'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

lua54 'yes'
