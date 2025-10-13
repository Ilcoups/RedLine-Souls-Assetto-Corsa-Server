-- Traffic Chat Filter for CSP
-- This script filters out "Traffic X has disconnected" messages from chat
-- Install: Place in Documents/Assetto Corsa/cfg/lua/online/ folder

-- Hook into chat message processing
ac.onChatMessage(function(message, authorCarIndex)
    -- Check if message contains "Traffic" and "disconnected" or "has left"
    local isTrafficMessage = message:find("Traffic %d+") and 
                            (message:find("disconnected") or 
                             message:find("has left") or
                             message:find("has joined"))
    
    -- Return false to hide the message, true to show it
    if isTrafficMessage then
        return false  -- Hide traffic join/leave messages
    end
    
    return true  -- Show all other messages
end)

-- Optional: Log filtered messages to console for debugging
-- ac.log("Traffic message filtered: " .. message)
