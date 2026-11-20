---@diagnostic disable: undefined-global

local MAX_ACTIONS_PER_SECOND = 10

local ACTIONS = {
	engine = 'boolean',
	door = 'boolean',
	window = 'boolean',
	indicators = 'number',
	headlights = 'string',
	interior = 'boolean',
	locks = 'boolean',
	roof = 'boolean',
	siren = 'string',
	searchlight = 'boolean',
}

local HEADLIGHTS = { off = true, on = true, high = true }
local SIREN = { off = true, lights = true, sound = true }

local budgets = {}

local function rateLimited(src)
	local now = GetGameTimer()
	local budget = budgets[src]
	if not budget or now - budget.start >= 1000 then
		budget = { start = now, count = 0 }
		budgets[src] = budget
	end
	budget.count = budget.count + 1
	return budget.count > MAX_ACTIONS_PER_SECOND
end

local function validValue(action, value)
	if type(value) ~= ACTIONS[action] then return false end
	if action == 'indicators' then return value >= 0 and value <= 3 end
	if action == 'headlights' then return HEADLIGHTS[value] == true end
	if action == 'siren' then return SIREN[value] == true end
	return true
end

local function seatOf(veh, ped)
	for seat = -1, 15 do
		if GetPedInVehicleSeat(veh, seat) == ped then return seat end
	end
end

local function canUse(seat, action, index)
	if seat == -1 then return true end
	return (action == 'door' or action == 'window') and index == seat + 1
end

local function setWindow(veh, index, down)
	local state = Entity(veh).state
	local current = type(state.windowsDown) == 'table' and state.windowsDown or {}
	local windows = {}
	for i = 1, 6 do
		local window = math.tointeger(current[i])
		if window and window ~= index then windows[#windows + 1] = window end
	end
	if down then windows[#windows + 1] = index end
	state:set('windowsDown', windows, true)
end

RegisterNetEvent('justgroot:vehiclecontrol:server:action', function(netId, action, value, index)
	local src = source
	if rateLimited(src) then return end

	if action == 'indicators' then value = math.tointeger(value) end
	if type(netId) ~= 'number' or not validValue(action, value) then return end
	index = math.tointeger(index)
	if (action == 'door' or action == 'window') and not (index and index >= 0 and index <= 7) then return end
	if action == 'door' and index > 5 then return end

	local veh = NetworkGetEntityFromNetworkId(netId)
	local seat = veh ~= 0 and seatOf(veh, GetPlayerPed(src))
	if not seat or not canUse(seat, action, index) then return end

	if action == 'locks' then
		return SetVehicleDoorsLocked(veh, value and 2 or 1)
	end
	if action == 'window' then
		return setWindow(veh, index, value)
	end
	if action == 'indicators' then
		return Entity(veh).state:set('indicators', value, true)
	end
	if action == 'headlights' or action == 'siren' then
		Entity(veh).state:set(action, value, true)
	end

	local owner = NetworkGetEntityOwner(veh)
	if owner > 0 then
		TriggerClientEvent('justgroot:vehiclecontrol:client:apply', owner, netId, action, value, index)
	end
end)

AddEventHandler('playerDropped', function()
	budgets[source] = nil
end)

CreateThread(function()
	Wait(1000)
	print(([[
^5--------------------------------------------------------------^7
^2 %s^7 started successfully. Thank you for choosing Groot Development!
^7 Join our Discord community:  ^4https://discord.gg/Nm5FSxK2gv^7
^7 Browse our premium scripts:  ^4https://groot-development.tebex.io/^7
^7 New here? Use gift card ^3WELCOME10^7 on your first purchase!
^5--------------------------------------------------------------^7]]):format(GetCurrentResourceName()))
end)
