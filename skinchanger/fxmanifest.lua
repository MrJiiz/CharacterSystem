fx_version 'adamant'
game 'gta5'

description 'Skin Changer'

version '1.0.1'

server_script "@sr_main/server/def.lua"
client_script "@sr_main/client/def.lua"

client_scripts {
  'locale.lua',
  'locales/en.lua',
  'config.lua',
  'client/main.lua'
}

