Language = {}

function LAN(name, ...)
	if not name then
		return 'ERR_TRANSLATE_404'
	end
	local lang = Config.SystemSettings and Config.SystemSettings.Language or 'en'
	local table = Language[lang]
	local str = table and table[name]
	if not str then
		return 'ERR_TRANSLATE_' .. name .. '_404'
	end
	if select('#', ...) > 0 then
		return string.format(str, ...)
	end
	return str
end
