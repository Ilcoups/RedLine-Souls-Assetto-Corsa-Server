-- RedLine Souls Welcome Audio
-- Client-side Lua script for playing welcome sound when joining the server
-- Installation: Copy to Documents\Assetto Corsa\cfg\lua\online\

local hasPlayed = false
local timer = 0
local checkTimer = 0

function script.update(dt)
    -- Only run once per session
    if hasPlayed then return end
    
    -- Check every 0.5 seconds if we're connected
    checkTimer = checkTimer + dt
    if checkTimer < 0.5 then return end
    checkTimer = 0
    
    -- Try to get server info
    local serverName = ac.getServerName()
    local serverIP = ac.getServerIP()
    
    -- Debug: log what we detect
    if serverName then
        ac.log("RedLine Souls Debug: Server name = " .. tostring(serverName))
    end
    if serverIP then
        ac.log("RedLine Souls Debug: Server IP = " .. tostring(serverIP))
    end
    
    -- Check if we're on RedLine Souls server (by name or IP)
    local isRedLineSouls = false
    
    if serverName and string.find(serverName, "RedLine") then
        isRedLineSouls = true
        ac.log("RedLine Souls: Detected by server name!")
    elseif serverIP and string.find(serverIP, "188.245.183.146") then
        isRedLineSouls = true
        ac.log("RedLine Souls: Detected by server IP!")
    end
    
    if not isRedLineSouls then
        return
    end
    
    -- We're on the right server, start timer
    timer = timer + dt
    
    if timer >= 3 then
        -- Try to play the audio file
        local audioPath = "content/sfx/RedLineSoulsIntro.ogg"
        
        ac.log("RedLine Souls: Attempting to play audio from " .. audioPath)
        
        -- Check if file exists
        if io.fileExists(audioPath) then
            ac.log("RedLine Souls: Audio file found! Playing...")
            ui.playSound(audioPath, 1.0)
            ac.log("RedLine Souls: Welcome audio played!")
        else
            ac.log("RedLine Souls: ERROR - Audio file not found at " .. audioPath)
            ac.log("RedLine Souls: Please run installer from GitHub")
        end
        
        hasPlayed = true
    end
end
