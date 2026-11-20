---@diagnostic disable: undefined-global

local isOpen = false

local function vehicleLabel(model)
	local display = GetDisplayNameFromVehicleModel(model)
	local name = GetLabelText(display)
	local make = GetLabelText(GetMakeNameFromVehicleModel(model))
	if name == 'NULL' then name = display end
	return make ~= 'NULL' and ('%s %s'):format(make, name) or name
end

local WINDOWS = {
	{ 0, 'window_lf' }, { 1, 'window_rf' },
	{ 6, 'window_lm' }, { 7, 'window_rm' },
	{ 2, 'window_lr' }, { 3, 'window_rr' },
}

local ROLLABLE = { [0] = true, [1] = true, [2] = true, [3] = true, [6] = true, [7] = true }

local function windowList(value)
	local list = {}
	if type(value) ~= 'table' then return list end
	for i = 1, #WINDOWS do
		local index = type(value[i]) == 'number' and math.tointeger(value[i])
		if ROLLABLE[index] then list[#list + 1] = index end
	end
	return list
end

local function vehicleWindows(veh)
	local list = {}
	for _, window in ipairs(WINDOWS) do
		if GetEntityBoneIndexByName(veh, window[2]) ~= -1 then list[#list + 1] = window[1] end
	end
	return list
end

local HEADLIGHTS = { off = true, on = true, high = true }

local function headlightMode(veh)
	local mode = Entity(veh).state.headlights
	if HEADLIGHTS[mode] then return mode end
	local _, lightsOn, highBeam = GetVehicleLightsState(veh)
	if highBeam == 1 or highBeam == true then return 'high' end
	return (lightsOn == 1 or lightsOn == true) and 'on' or 'off'
end

local SIREN = { off = true, lights = true, sound = true }

local function sirenMode(veh)
	local mode = Entity(veh).state.siren
	if SIREN[mode] then return mode end
	if not IsVehicleSirenOn(veh) then return 'off' end
	return IsVehicleSirenAudioOn(veh) and 'sound' or 'lights'
end

local function indicatorState(veh)
	local value = Entity(veh).state.indicators
	if type(value) == 'number' and value >= 0 and value <= 3 then return math.tointeger(value) end
	return GetVehicleIndicatorLights(veh)
end

local function bagVehicle(bagName)
	local veh = GetEntityFromStateBagName(bagName)
	for _ = 1, 20 do
		if veh ~= 0 then break end
		Wait(100)
		veh = GetEntityFromStateBagName(bagName)
	end
	return veh
end

local function vehicleState(veh)
	local ped = PlayerPedId()
	local model = GetEntityModel(veh)
	local class = GetVehicleClass(veh)
	local seatCount = GetVehicleModelNumberOfSeats(model)
	local isBike = class == 8 or class == 13
	local isAircraft = class == 15 or class == 16

	local seat, occupiedSeats = -1, {}
	for i = -1, seatCount - 2 do
		local occupant = GetPedInVehicleSeat(veh, i)
		if occupant == ped then
			seat = i
		elseif occupant ~= 0 then
			occupiedSeats[#occupiedSeats + 1] = i
		end
	end

	local doorCount, openDoors = 0, {}
	for i = 0, isBike and -1 or 5 do
		if i < 4 and GetIsDoorValid(veh, i) then doorCount = doorCount + 1 end
		if GetVehicleDoorAngleRatio(veh, i) > 0.0 then openDoors[#openDoors + 1] = i end
	end

	local roof = GetConvertibleRoofState(veh)

	return {
		label = vehicleLabel(model),
		seat = seat,
		seatCount = seatCount,
		occupiedSeats = occupiedSeats,
		doorCount = doorCount,
		hasHood = not isBike and GetIsDoorValid(veh, 4),
		hasTrunk = not isBike and GetIsDoorValid(veh, 5),
		openDoors = openDoors,
		windows = (isBike or isAircraft) and {} or vehicleWindows(veh),
		windowsDown = windowList(Entity(veh).state.windowsDown),
		engine = GetIsVehicleEngineRunning(veh) or IsVehicleEngineStarting(veh),
		indicators = indicatorState(veh),
		headlights = headlightMode(veh),
		interiorLight = IsVehicleInteriorLightOn(veh),
		locked = GetVehicleDoorLockStatus(veh) >= 2,
		roofDown = roof == 1 or roof == 2,
		siren = sirenMode(veh),
		searchlight = IsVehicleSearchlightOn(veh),
		features = {
			interior = not isBike,
			locks = class ~= 13,
			roof = IsVehicleAConvertible(veh, false),
			siren = class == 18,
			signals = not isAircraft and class ~= 14,
			searchlight = DoesVehicleHaveSearchlight(veh),
			lights = not isAircraft,
		},
	}
end

local function open()
	local veh = GetVehiclePedIsIn(PlayerPedId(), false)
	if isOpen or veh == 0 then return end
	isOpen = true

	SendReactMessage('justgroot:vehiclecontrol:state', vehicleState(veh))
	ToggleNuiFrame(true)
	PushNuiTheme()
	Localization()
	SendSystemSettingsToNui()
	SendReactMessage('setVisibleVehicleControl', true)

	CreateThread(function()
		while true do
			Wait(500)
			if not IsNuiFocused() then break end
			veh = GetVehiclePedIsIn(PlayerPedId(), false)
			if veh == 0 then
				SendReactMessage('setVisibleVehicleControl', false)
				break
			end
			SendReactMessage('justgroot:vehiclecontrol:state', vehicleState(veh))
		end
		isOpen = false
	end)
end

RegisterCommand(Config.VehicleControl.Command, open, false)
RegisterKeyMapping(Config.VehicleControl.Command, 'Vehicle control', 'keyboard', Config.VehicleControl.Key)

RegisterNUICallback('justgroot:vehiclecontrol:action', function(data, cb)
	cb({})
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsIn(ped, false)
	if veh == 0 or type(data) ~= 'table' then return end

	if data.action == 'seat' then
		local seat = math.tointeger(data.value)
		if seat and IsVehicleSeatFree(veh, seat) then
			SetPedIntoVehicle(ped, veh, seat)
		end
	else
		TriggerServerEvent('justgroot:vehiclecontrol:server:action', VehToNet(veh), data.action, data.value, data.index)
	end
end)

local apply = {
	engine = function(veh, on)
		SetVehicleEngineOn(veh, on, false, true)
	end,
	door = function(veh, opened, index)
		if opened then
			SetVehicleDoorOpen(veh, index, false, false)
		else
			SetVehicleDoorShut(veh, index, false)
		end
	end,
	headlights = function(veh, mode)
		SetVehicleLights(veh, mode == 'off' and 1 or 2)
		SetVehicleFullbeam(veh, mode == 'high')
	end,
	interior = function(veh, on)
		SetVehicleInteriorlight(veh, on)
	end,
	roof = function(veh, down)
		if down then
			LowerConvertibleRoof(veh, false)
		else
			RaiseConvertibleRoof(veh, false)
		end
	end,
	siren = function(veh, mode)
		SetVehicleSiren(veh, mode ~= 'off')
	end,
	searchlight = function(veh, on)
		SetVehicleSearchlight(veh, on, false)
	end,
}

RegisterNetEvent('justgroot:vehiclecontrol:client:apply', function(netId, action, value, index)
	local veh = NetToVeh(netId)
	if DoesEntityExist(veh) and apply[action] then
		apply[action](veh, value, index)
	end
end)

AddStateBagChangeHandler('windowsDown', nil, function(bagName, _, windows)
	local veh = bagVehicle(bagName)
	if veh == 0 then return end
	local down = {}
	for _, index in ipairs(windowList(windows)) do down[index] = true end
	for index in pairs(ROLLABLE) do
		if down[index] then
			RollDownWindow(veh, index)
		else
			RollUpWindow(veh, index)
		end
	end
end)

AddStateBagChangeHandler('indicators', nil, function(bagName, _, value)
	local veh = bagVehicle(bagName)
	if veh == 0 or type(value) ~= 'number' then return end
	value = math.tointeger(value) or 0
	SetVehicleIndicatorLights(veh, 1, value & 1 ~= 0)
	SetVehicleIndicatorLights(veh, 0, value & 2 ~= 0)
end)

AddStateBagChangeHandler('siren', nil, function(bagName, _, mode)
	local veh = bagVehicle(bagName)
	if veh ~= 0 then SetVehicleHasMutedSirens(veh, mode == 'lights') end
end)

local SOUNDS = {
	nav = 'NAV_UP_DOWN',
	select = 'SELECT',
	back = 'BACK',
	wrong = 'ERROR',
}

RegisterNUICallback('justgroot:vehiclecontrol:sound', function(data, cb)
	cb({})
	local sound = type(data) == 'table' and SOUNDS[data.name]
	if sound then PlaySoundFrontend(-1, sound, 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end
end)
