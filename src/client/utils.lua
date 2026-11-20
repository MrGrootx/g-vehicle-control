---@diagnostic disable: undefined-field, lowercase-global, undefined-global

local THEME_ACTION = 'g-dui-template:theme'

function ThemePayload()
	local themeName = Config.SystemSettings and Config.SystemSettings.theme
	if not themeName or not Config.Theme or not Config.Theme[themeName] then
		return nil
	end
	return {
		theme = themeName,
		[themeName] = Config.Theme[themeName],
		useGta6Style = Config.SystemSettings.useGta6Style == true,
	}
end

---@return table
function SystemSettingsPayload()
	local settings = Config.SystemSettings or {}
	return {
		useGta6Style = settings.useGta6Style == true,
		debug = settings.Debug == true,
	}
end

function SendSystemSettingsToNui()
	SendReactMessage('systemSettings', SystemSettingsPayload())
end

function SendReactMessage(action, data)
	SendNUIMessage({
		action = action,
		data = data,
	})
end

function PushNuiTheme()
	local theme = ThemePayload()
	if theme then
		SendReactMessage(THEME_ACTION, theme)
	end
end

function ToggleNuiFrame(shouldShow)
	SetNuiFocus(shouldShow, shouldShow)
end
