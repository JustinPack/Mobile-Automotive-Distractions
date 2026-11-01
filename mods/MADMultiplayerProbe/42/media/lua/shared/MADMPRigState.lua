-- Pure server-side transitions. Callers must validate proximity, ownership and inventory.
MADMPRigState = {}
local speed={slow=true,medium=true,full=true}
local gear={forward=true,reverse=true}
local direction={left=true,right=true,straight=true}
local rate={slow=true,medium=true,fast=true}
function MADMPRigState.new(skills,materials)
    return {version=1,phase="setup",brake=false,wedge=false,gear="forward",speed="slow",
        restraint="none",direction="straight",turnRate="slow",horn=false,
        requireSkills=true,requireMaterials=true,distance=0,revision=1}
end
function MADMPRigState.apply(r,action,value)
    if not r then return false,"No distraction rig." end
    if r.phase~="setup" then return false,"The rig is no longer in setup." end
    if action=="brake" then
        if r.brake then return false,"Parking brake already engaged." end
        r.brake=true
    elseif action=="release" then
        if not r.brake then return false,"Parking brake is not engaged." end
        r.brake=false
        if r.wedge then r.phase="moving" end
    elseif action=="wedge" then
        if r.wedge then return false,"A wedge is already attached." end
        r.wedge=true
        if not r.brake then r.phase="moving" end
    elseif action=="restraint" then
        if r.restraint~="none" or (value~="rope" and value~="board") then return false,"Choose an available restraint." end
        r.restraint=value
    elseif action=="speed" then
        if not r.wedge or not speed[value] then return false,"Attach the wedge first." end
        r.speed=value
    elseif action=="gear" then
        if not gear[value] then return false,"Invalid gear." end
        r.gear=value
    elseif action=="direction" then
        if r.restraint=="none" or not direction[value] then return false,"Attach a steering restraint first." end
        r.direction=value
    elseif action=="turnRate" then
        if r.restraint=="none" or r.direction=="straight" or not rate[value] then return false,"Choose a turn direction first." end
        r.turnRate=value
    elseif action=="horn" then
        if type(value)~="boolean" then return false,"Invalid horn setting." end
        r.horn=value
    else return false,"Unknown rig action." end
    r.revision=(r.revision or 0)+1
    return true
end
function MADMPRigState.impact(r)
    if not r or r.phase~="moving" or not r.wedge then return false end
    r.wedge=false; r.wedgeKnockedLoose=true; r.phase="stalled"; r.revision=(r.revision or 0)+1
    return true
end
