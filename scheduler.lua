local ServerCallbacks <const> = {}

local SECONDS_IN_A_DAY <const> = 60 * 60 * 24

local Tunnel <const> = module("vrp", "lib/Tunnel")
local Proxy <const> = module("vrp", "lib/Proxy")

local vRP <const> = Proxy.getInterface[[vRP]]
local vRPclient <const> = Tunnel.getInterface("vRP","callbackScheduler")
local _env <const> = {_G, vRP, vRPclient, exports}

local function __executeCallback(fnString, varargs)
	local fn = assert(load(fnString, "callbackENV", "bt", _env)())
    fn(table.unpack(varargs))
end


local function getDayDifference (t, t2)
    local firstTime <const> = os.time({year = t.year, month = t.month, day = t.day})
    local secondTime <const> = os.time({year = t2.year, month = t2.month, day = t2.day})
    local diff <const> = math.ceil(os.difftime(secondTime, firstTime) / SECONDS_IN_A_DAY)
    return math.abs(diff)
end

local function isCallbackReady(fnData)

    local time <const> = os.date'*t'
    local currentHour <const>, currentMinute <const> = time.hour, time.min
    local daysPassed <const> = getDayDifference(fnData.date, time)
	
    if daysPassed < fnData.days then return false end

    if daysPassed == fnData.days then 
	
        if currentHour < fnData.hour then return false end 

        if currentHour == fnData.hour and currentMinute < fnData.minute then return false end 
        return true 

    end

    return true 

end

local function lines_from(file)
	local lines <const> = {}
	for line in io.lines(file) do 
	  lines[#lines + 1] = line
	end
	return lines
end

local function removeCallback(search, value)
	cbInfo = json.encode(cbInfo)
	local fileName <const> = ('resources/%s/callbacks.json'):format(GetCurrentResourceName())
  
	local file <const> = io.open(fileName, "a")
	local content <const> = lines_from(fileName)

	if not file then return end 

	local jsonExtracted = ''

	for _, line in pairs(content) do 
		jsonExtracted = jsonExtracted .. line
	end
			
	jsonExtracted = json.decode(jsonExtracted)

	for idx, fnData in pairs(jsonExtracted) do 
		if fnData[search] == value then 
			jsonExtracted[idx] = nil 
	
		end
	end	

	local f <const> = io.open(fileName, "wb")
	f:write(json.encode(jsonExtracted))
	f:close()


end



local function saveCallback(cbInfo) 
		cbInfo = json.encode(cbInfo)
		local fileName <const> = ('resources/%s/callbacks.json'):format(GetCurrentResourceName())
	  
		local file <const> = io.open(fileName, "a")
		local content <const> = lines_from(fileName)

		if not file then return end 
		
		if #content == 0 then 
			cbInfo = '[\n\t' .. cbInfo .. '\n]'
			file:write(cbInfo)
			file:close()
		else
			local jsonExtracted = ''

			for _, line in pairs(content) do 
				jsonExtracted = jsonExtracted .. line
			end
			
			jsonExtracted = json.decode(jsonExtracted)
			
			cbInfo = json.decode(cbInfo)
			table.insert(jsonExtracted, cbInfo)
			local f <const> = io.open(fileName, "wb")
			f:write(json.encode(jsonExtracted))
			f:close()
		end
		
end
	

local function getSavedCallbacks()
	local fileName <const> = ('resources/%s/callbacks.json'):format(GetCurrentResourceName())
	  
	local file <const> = io.open(fileName, "a")
	local content <const> = lines_from(fileName)
	if not file then return end 

	local jsonExtracted = ''

	for _, line in pairs(content) do 
		jsonExtracted = jsonExtracted .. line
	end
	
	
	
	return json.decode(jsonExtracted)
end

local populateServerCallbacks = coroutine.create(function()

    local internalSavedCallbacks <const> = getSavedCallbacks()
    local tData <const> = {}

    for _, fnData in ipairs(internalSavedCallbacks) do 
		
		if fnData.userCallback then goto con end 

        fnData.ready = isCallbackReady(fnData)
		
        if fnData.ready then 
            __executeCallback(fnData.fnString, fnData.varargs)
        end

        rawset(ServerCallbacks, fnData.label, fnData)
		::con::
    end

end)
coroutine.resume(populateServerCallbacks)
--[[
    @time = {days = 3, hour = 15, minute = 30} 
    -> callback will be called after 3 days, at 15:30
]] 

function scheduleUserCallback(user_id, cbInfo)
    cbInfo.userCallback = true 
    cbInfo.user_id = user_id
    saveCallback(cbInfo) 
end

function scheduleServerCallback(cbInfo)
    cbInfo.userCallback = false
    saveCallback(cbInfo) 
end

local playerSpawnedHandler <const> = function(user_id, source, first_spawn)

	if first_spawn then 

		ServerCallbacks[user_id] = {}

		local callbacks <const> = getSavedCallbacks()

		for idx, fnData in pairs(callbacks) do 
			if fnData.userCallback and fnData.user_id == user_id then
				fnData.ready = isCallbackReady(fnData) 
				table.insert(ServerCallbacks[user_id],fnData)	
				if fnData.ready then 
					__executeCallback(fnData.fnString, fnData.varargs or {})
					ServerCallbacks[idx] = nil
					removeCallback('user_id', fnData.user_id)
				end		
			end
		end


	end
end

AddEventHandler('vRP:playerSpawn', playerSpawnedHandler)

local __internalLoop <const> = function()
	while true do 
		Citizen.Wait(1000 * 60)

		for idx, fnData in pairs(ServerCallbacks) do 
			if type(idx) == 'number' then 
				fnData.ready = isCallbackReady(fnData)
				if fnData.ready then 
					__executeCallback(fnData.fnString, fnData.varargs or {})
					ServerCallbacks[idx] = nil 
					
					removeCallback(( fnData.userCallback and 'user_id') or 'label', ( fnData.userCallback and fnData.user_id) or fnData.label)
			
				end
			end
		end

	end	
end

Citizen.CreateThread(__internalLoop)
