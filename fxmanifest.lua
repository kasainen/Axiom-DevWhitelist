fx_version 'cerulean'

game 'gta5'

name 'Axiom Dev Whitelist'
author 'Axiom'
version '1.0.0'
description 'Dev server whitelist via oxmysql (Discord ID based)'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}
