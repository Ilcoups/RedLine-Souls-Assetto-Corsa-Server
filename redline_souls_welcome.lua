-- RedLine Souls Welcome Audio
-- SIMPLIFIED VERSION - ALWAYS LOGS

ac.log("=== RedLine Souls Lua Script LOADED ===")

local hasPlayed = false
local timer = 0

function script.update(dt)
    if hasPlayed then return end
    
    timer = timer + dt
    
    -- Log every 2 seconds to show script is running
    if math.floor(timer) % 2 == 0 and math.floor(timer) > 0 then
        ac.log("RedLine Souls: Script is running, timer = " .. timer)
    end
    
    -- After 5 seconds, try to play audio regardless of server
    if timer >= 5 and not hasPlayed then
        local audioPath = "content/sfx/RedLineSoulsIntro.ogg"
        
        ac.log("=== RedLine Souls: ATTEMPTING TO PLAY AUDIO ===")
        ac.log("Audio path: " .. audioPath)
        
        if io.fileExists(audioPath) then
            ac.log("Audio file EXISTS! Playing now...")
            ui.playSound(audioPath, 1.0)
            ac.log("ui.playSound() called successfully!")
        else
            ac.log("ERROR: Audio file NOT FOUND at " .. audioPath)
        end
        
        hasPlayed = true
    end
end
