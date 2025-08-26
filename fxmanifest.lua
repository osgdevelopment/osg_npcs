fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'VORP-compatible NPC spawner (fork of rsg-npcs)'
version '2.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua',
    'server/versionchecker.lua'
}

files {
    'sounds/*.ogg',
    'sounds/*.mp3',
    'sounds/*.wav'
}

dependencies {
    'vorp_core',
    'xsound' -- Audio dependency
}

lua54 'yes'

