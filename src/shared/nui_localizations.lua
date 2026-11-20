---@diagnostic disable: undefined-global

function GetLocalizationPayload()
	local lang = Config.SystemSettings and Config.SystemSettings.Language or 'en'
	return Language[lang] or Language['en'] or {}
end

function Localization()
	SendNUIMessage({
		action = 'justgroot:vehiclecontrol:localizations',
		data = GetLocalizationPayload(),
	})
end
