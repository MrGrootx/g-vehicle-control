---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'G3DEV - justgroot'
description 'Vehicle control menu'
version '1.0.0'

shared_scripts {
	'locales/locale.lua',
	'locales/translations/*.lua',
	'config/config.lua',
	'config/theme.lua',
	'src/shared/nui_localizations.lua',
}

server_scripts {
	'src/server/nui/*.lua',
}

client_scripts {
	'src/client/utils.lua',
	'src/client/nui/callbacks.lua',
	'src/client/nui/cl_vehicle_control.lua',
}

-- ui_page 'http://localhost:3000/'
ui_page 'web/build/index.html'

files {
	'web/build/index.html',
	'web/build/**/*',
	'src/shared/*.lua',
}

use_experimental_fxv2_oal 'yes'
