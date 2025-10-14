-- RedLine Souls Welcome Audio
-- Client-side Lua script for playing welcome sound when joining the server
-- Installation: Copy to Documents\Assetto Corsa\cfg\lua\online\

local hasPlayed = false
local timer = 0
local serverIP = "188.245.183.146"

function script.update(dt)
    -- Only run once per session
    if hasPlayed then return end
    
    -- Check if we're connected to RedLine Souls server
    local currentServer = ac.getServerIP()
    if not currentServer then return end
    
    -- Check if this is the RedLine Souls server
    if not string.find(currentServer, serverIP) then
        return
    end
    
    -- Wait 3 seconds after joining before playing
    timer = timer + dt
    if timer >= 3 then
        -- Try to play the audio file
        local audioPath = "content/sfx/RedLineSoulsIntro.ogg"
        
        -- Check if file exists
        if io.fileExists(audioPath) then
            ui.playSound(audioPath, 1.0)
            ac.log("RedLine Souls: Welcome audio played!")
        else
            ac.log("RedLine Souls: Audio file not found at " .. audioPath)
            ac.log("Please run the installer: https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server")
        end
        
        hasPlayed = true
    end
end

