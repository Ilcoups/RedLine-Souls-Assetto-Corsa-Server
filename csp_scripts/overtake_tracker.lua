-- RedLine Souls - Overtake Tracker (Client-side)
-- Automatically detects overtakes and reports to server
-- Place in: Documents/Assetto Corsa/cfg/lua/online/overtake_tracker.lua

-- Configuration
local SERVER_UDP_IP = "188.245.183.146"  -- Your server IP
local SERVER_UDP_PORT = 12002
local MIN_SPEED_KPH = 80  -- Minimum speed to count
local OVERTAKE_DISTANCE = 7  -- Meters ahead to count as overtake
local COOLDOWN_TIME = 3.0  -- Seconds before same car can be overtaken again

-- State tracking
local trackedCars = {}  -- {carIndex: {wasAhead, lastOvertakeTime}}
local myCarIndex = -1
local udpSocket = nil
local mySteamId = nil
local myName = nil

-- Initialize
function script.start()
    ac.log("RedLine Souls Overtake Tracker initialized")
    
    -- Get my car info
    myCarIndex = ac.getSim().focusedCar
    
    -- Get player info
    local player = ac.getCarState(myCarIndex)
    if player then
        mySteamId = ac.getDriverGuid(myCarIndex) or "unknown"
        myName = ac.getDriverName(myCarIndex) or "Unknown"
        ac.log(string.format("Player: %s (SteamID: %s)", myName, mySteamId))
    end
    
    -- Create UDP socket
    udpSocket = ac.DatagramSocket()
    udpSocket:setAddress(SERVER_UDP_IP, SERVER_UDP_PORT)
end

function script.update(dt)
    if myCarIndex < 0 then return end
    
    local myCar = ac.getCarState(myCarIndex)
    if not myCar then return end
    
    -- My position and velocity
    local myPos = myCar.position
    local myVel = myCar.velocity
    local mySpeed = myVel:length() * 3.6  -- Convert m/s to km/h
    
    -- Skip if too slow
    if mySpeed < MIN_SPEED_KPH then
        return
    end
    
    -- Check all other cars
    local carsCount = ac.getSim().carsCount
    for i = 0, carsCount - 1 do
        if i ~= myCarIndex then
            local otherCar = ac.getCarState(i)
            
            if otherCar and not otherCar.isAIControlled then  -- Only track real players
                local otherPos = otherCar.position
                local distance = myPos:distance(otherPos)
                
                -- Only check nearby cars
                if distance < 20 then
                    -- Calculate relative position along velocity vector
                    local toOther = otherPos - myPos
                    local myDirection = myVel:normalize()
                    local alongMyDirection = toOther:dot(myDirection)
                    
                    -- Initialize tracking if needed
                    if not trackedCars[i] then
                        trackedCars[i] = {wasAhead = false, lastOvertakeTime = 0}
                    end
                    
                    local track = trackedCars[i]
                    local now = os.clock()
                    
                    -- Check if car is ahead (positive alongMyDirection)
                    local isAhead = alongMyDirection > 0 and distance < OVERTAKE_DISTANCE
                    
                    -- Detect overtake: was ahead, now behind
                    if track.wasAhead and not isAhead and alongMyDirection < -2 then
                        -- Check cooldown
                        if now - track.lastOvertakeTime > COOLDOWN_TIME then
                            -- OVERTAKE!
                            reportOvertake(mySpeed)
                            track.lastOvertakeTime = now
                            
                            local otherName = ac.getDriverName(i) or "Unknown"
                            ac.log(string.format("Overtook %s @ %.1f km/h", otherName, mySpeed))
                        end
                    end
                    
                    -- Update state
                    track.wasAhead = isAhead
                end
            end
        end
    end
end

function reportOvertake(speedKph)
    if not udpSocket or not mySteamId then return end
    
    -- Build UDP packet: [steam_id_length][steam_id][name_length][name][speed][count]
    local steamIdBytes = mySteamId
    local nameBytes = myName
    
    local packet = string.pack('<I4', #steamIdBytes) .. steamIdBytes ..
                   string.pack('<I4', #nameBytes) .. nameBytes ..
                   string.pack('<f', speedKph) ..
                   string.pack('<I4', 1)  -- Count: 1 overtake
    
    -- Send to server
    udpSocket:send(packet)
end

-- Cleanup
function script.stop()
    if udpSocket then
        udpSocket:close()
    end
    ac.log("Overtake Tracker stopped")
end
