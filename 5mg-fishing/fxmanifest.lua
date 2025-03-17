fx_version 'cerulean'
game 'gta5'

author '5MG DEV'
description '5MG Fishing System with Minigame'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}