fx_version 'cerulean'
game 'gta5'

name 'ng_weaponlicense'
author 'NeutronGaming'
description 'Comprehensive weapon license system with application process, exams, and police management'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}