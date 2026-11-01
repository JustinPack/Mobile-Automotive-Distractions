-- Pure setup model for the development preview. No game objects or inventory mutations.
MADSetup = {}

function MADSetup.new()
    return { brake = false, wedge = false, speed = "slow", gear = "forward",
        restraint = "none", direction = "straight", turnRate = "slow", horn = false }
end

function MADSetup.change(s, key, value)
    if key == "brake" then
        if value ~= true then return false, "Launching is unavailable in this preview." end
        s.brake = true
        return true
    end
    if not s.brake then return false, "Engage the parking brake first." end
    if key == "wedge" and type(value) == "boolean" then
        s.wedge = value
    elseif key == "speed" and (value == "slow" or value == "medium" or value == "full") then
        if not s.wedge then return false, "Select a wedge first." end
        s.speed = value
    elseif key == "gear" and (value == "forward" or value == "reverse") then
        s.gear = value
    elseif key == "restraint" and (value == "none" or value == "rope" or value == "board") then
        s.restraint = value
        if value == "none" then s.direction = "straight" end
    elseif key == "direction" and (value == "left" or value == "straight" or value == "right") then
        if s.restraint == "none" then return false, "Select a steering restraint first." end
        s.direction = value
    elseif key == "turnRate" and (value == "slow" or value == "medium" or value == "fast") then
        if s.restraint == "none" or s.direction == "straight" then return false, "Select left or right steering first." end
        s.turnRate = value
    elseif key == "horn" and type(value) == "boolean" then
        s.horn = value
    else
        return false, "Invalid control value."
    end
    return true
end
