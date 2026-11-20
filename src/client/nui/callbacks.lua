---@diagnostic disable: undefined-field, lowercase-global, undefined-global

RegisterNUICallback('nuiReady', function(_, cb)
	PushNuiTheme()
	if Localization then Localization() end
	SendSystemSettingsToNui()
	cb({})
end)

RegisterNUICallback('hideFrame', function(data, cb)
	data = type(data) == 'table' and data or {}
	local action = data.action
	if type(action) == 'string' and action ~= '' then
		SendReactMessage(action, false)
	end
	ToggleNuiFrame(false)
	cb({})
end)
