require "MADSteering"
MADRig = {}
MADRig.dataKey = "MobileAutomotiveDistraction"
local runtime = {}
local speedTargets = { slow = 10, medium = 25, full = 50 }
local wedgeTypes = { ["Base.Stone2"] = true, ["Base.Wrench"] = true }
-- A sharp speed loss is only a proxy for impact; ignore low-speed jitter.
local impactWindowMs, impactMinimumKmh, impactRemaining = 500, 5, 0.10

local function storage(vehicle)
    local engine = vehicle and vehicle:getPartById("Engine")
    return engine and engine:getModData() or nil
end
function MADRig.get(vehicle)
    local data = storage(vehicle)
    return data and data[MADRig.dataKey] or nil
end
function MADRig.requirements() return SandboxVars.MAD or {} end
function MADRig.isUsable(vehicle)
    return vehicle and vehicle:getScript() and storage(vehicle) and not vehicle:isBurntOrSmashed()
end
function MADRig.atDriverDoor(player, vehicle)
    if not player or not vehicle or player:getVehicle() or player:getZ() ~= vehicle:getZ() then return false end
    local outside = vehicle:getPassengerPosition(0, "outside")
    if not outside then return false end
    local pos = vehicle:getWorldPos(outside:getOffset(), Vector3f.new())
    return player:DistToSquared(pos:x(), pos:y()) <= 2 * 2
end
function MADRig.start(player, vehicle)
    if isClient() or isServer() then return false, "Single-player only." end
    if not MADSetRigControls or not MADClearRigControls or not MADPackItem or not MADUnpackItem or not MADLoadedVehicles then return false, "ZombieBuddy rig patch is not loaded; restart the game." end
    if not MADRig.atDriverDoor(player, vehicle) then return false, "Stand next to the driver's door." end
    if not MADRig.isUsable(vehicle) or not vehicle:isStopped() or vehicle:getDriver() or not vehicle:isEngineRunning() then
        return false, "Vehicle must be stopped, running, and have an empty driver's seat."
    end
    if MADRig.get(vehicle) then return false, "Vehicle already has a rig." end
    storage(vehicle)[MADRig.dataKey] = { version=1, brake=false, wedge=false, gear="forward", speed="slow",
        restraint="none", direction="straight", turnRate="slow", horn=false, distance=0, phase="setup",
        requireSkills=true, requireMaterials=true }
    return true
end
local function take(player, item)
    if not item or not player:getInventory():containsRecursive(item) or item:isEquipped() then return nil, "Unequip the item and keep it in your inventory." end
    local data = MADPackItem(item)
    if not data then return nil, "Unable to safely attach this item." end
    local c = item:getContainer()
    if not c then return nil, "Item is no longer available." end
    c:Remove(item)
    return data
end
local function give(player, data)
    if not data then return true end
    local item = MADUnpackItem(data)
    if not item then return false end
    player:getInventory():AddItem(item)
    return true
end
function MADRig.setBrake(vehicle)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" then return false, "The rig is no longer in setup." end
    if r.brake then return false, "Parking brake already engaged." end
    r.brake = true
    return true
end
function MADRig.attachWedge(player, vehicle, item)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" then return false, "The rig is no longer in setup." end
    if r.wedge then return false, "A wedge is already attached." end
    if not item or not wedgeTypes[item:getFullType()] then return false, "Use a stone or wrench." end
    if not r.brake and (not vehicle:isEngineRunning() or vehicle:getDriver()) then return false, "The engine must be running with the driver's seat empty." end
    local data, reason = take(player, item)
    if not data then return false, reason end
    r.wedgeItem = data
    r.wedge = true
    r.wedgeName = item:getName()
    if not r.brake then r.phase = "moving" end
    return true
end
function MADRig.freeWedge(vehicle)
    return false, "Drag a stone or wrench from your inventory."
end
function MADRig.restraint(player, vehicle, kind)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" then return false, "The rig is no longer in setup." end
    if r.restraint ~= "none" then return false, "Disarm the existing rig to recover its restraint." end
    if kind ~= "rope" and kind ~= "board" then return false, "Choose rope or board." end
    do
        local inventory = player:getInventory()
        local item = inventory:getItemFromTypeRecurse(kind == "rope" and "Base.Rope" or "Base.Plank")
        local tape = kind == "board" and inventory:getItemFromTypeRecurse("Base.DuctTape") or nil
        if not item then return false, "Required restraint is missing." end
        if kind == "board" and (not tape or tape:isEquipped() or not tape:getContainer()) then return false, "Unequipped duct tape is required." end
        local data, reason = take(player, item)
        if not data then return false, reason end
        r.restraintItem = data
        if tape then tape:getContainer():Remove(tape) end
    end
    r.restraint = kind
    r.boardRecoverable = kind ~= "board" or ZombRand(2) == 0
    return true
end
function MADRig.configure(vehicle, key, value)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" then return false, "The rig is no longer in setup." end
    if key == "speed" and speedTargets[value] and r.wedge then r.speed = value
    elseif key == "gear" and (value == "forward" or value == "reverse") then r.gear = value
    elseif key == "direction" and r.restraint ~= "none" and (value == "left" or value == "right" or value == "straight") then r.direction = value; runtime[vehicle] = nil
    elseif key == "turnRate" and r.restraint ~= "none" and r.direction ~= "straight" and (value == "slow" or value == "medium" or value == "fast") then r.turnRate = value; runtime[vehicle] = nil
    else return false, "Attach the appropriate component first." end
    return true
end
function MADRig.horn(player, vehicle, enabled)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" then return false, "The rig is no longer in setup." end
    if enabled then
        if player:getPerkLevel(Perks.Electricity) < 3 and player:getPerkLevel(Perks.Mechanics) < 3 then
            return false, "Requires Electrical or Mechanics level 3."
        end
        if not player:getInventory():getItemFromTypeRecurse("Base.Screwdriver") then return false, "A screwdriver is required." end
        if not vehicle:hasLiveBattery() then return false, "The battery is empty." end
        vehicle:onHornStart()
    else vehicle:onHornStop() end
    r.horn = enabled
    return true
end
function MADRig.release(vehicle)
    local r = MADRig.get(vehicle)
    if not r or r.phase ~= "setup" or not r.brake then return false, "Parking brake is not engaged." end
    if r.wedge and (not vehicle:isEngineRunning() or vehicle:getDriver()) then return false, "The engine must be running with the driver's seat empty." end
    r.brake = false
    if r.wedge then r.phase = "moving" end
    return true
end
function MADRig.disarm(player, vehicle)
    local r = MADRig.get(vehicle)
    if not r then return false, "No distraction rig." end
    if not MADRig.atDriverDoor(player, vehicle) or not vehicle:isStopped() then return false, "Stop and approach the driver's door." end
    if not MADRig.isUsable(vehicle) then storage(vehicle)[MADRig.dataKey] = nil; return false, "The vehicle was destroyed." end
    -- Decode before mutating state, avoiding loss if an item cannot be restored.
    local wedge = r.wedgeItem and MADUnpackItem(r.wedgeItem) or nil
    local restraint = r.restraintItem and (r.restraint ~= "board" or r.boardRecoverable) and MADUnpackItem(r.restraintItem) or nil
    if r.wedgeItem and not wedge then return false, "Unable to recover wedge; rig remains attached." end
    if r.restraintItem and (r.restraint ~= "board" or r.boardRecoverable) and not restraint then return false, "Unable to recover restraint; rig remains attached." end
    if r.horn then vehicle:onHornStop() end
    MADClearRigControls(vehicle)
    if wedge then player:getInventory():AddItem(wedge); r.wedgeItem = nil end
    if restraint then player:getInventory():AddItem(restraint); r.restraintItem = nil end
    storage(vehicle)[MADRig.dataKey] = nil
    runtime[vehicle] = nil
    return true
end
local function policy(vehicle, r)
    local v = runtime[vehicle]
    if not v or v.restraint ~= r.restraint or v.direction ~= r.direction or v.rate ~= r.turnRate then
        v = { restraint=r.restraint, direction=r.direction, rate=r.turnRate,
            steering=MADSteering.new(r.restraint, r.direction, r.turnRate, function() return ZombRand(10000) / 10000 end) }
        v.steering.distance = r.distance or 0
        v.steering.unrestrainedSign = r.unrestrainedSign
        runtime[vehicle] = v
    end
    return v
end
local function wedgeKnockedLoose(vehicle, v, now)
    local speed = math.abs(vehicle:getCurrentSpeedKmHour())
    local samples = v.speedSamples or {}
    v.speedSamples = samples
    while #samples > 0 and (now < samples[1].time or now - samples[1].time > impactWindowMs) do
        table.remove(samples, 1)
    end
    local impact = false
    for i=1,#samples do
        if samples[i].speed >= impactMinimumKmh and speed <= samples[i].speed * impactRemaining then
            impact = true
            break
        end
    end
    samples[#samples + 1] = { time=now, speed=speed }
    return impact
end
local function tickVehicle(vehicle, r, now)
    if not MADRig.isUsable(vehicle) then
        if r.horn then vehicle:onHornStop() end
        MADClearRigControls(vehicle)
        storage(vehicle)[MADRig.dataKey] = nil
        runtime[vehicle] = nil
        return
    end
    local v = policy(vehicle, r)
    if r.horn then
        if vehicle:hasLiveBattery() then
            local hours = getGameTime():getWorldAgeHours()
            if v.lastBatteryHours then
                local elapsed = math.max(0, math.min(hours - v.lastBatteryHours, 0.05))
                local battery = vehicle:getBattery()
                local item = battery and battery:getInventoryItem()
                if item then item:setCurrentUsesFloat(math.max(0, item:getCurrentUsesFloat() - elapsed * 0.05)) end
            end
            v.lastBatteryHours = hours
            if not v.lastHorn or now - v.lastHorn >= 1000 then vehicle:onHornStart(); v.lastHorn = now end
        else vehicle:onHornStop(); v.lastBatteryHours = nil end
    end
    if not r.wedge or not vehicle:isEngineRunning() or vehicle:getDriver() then v.speedSamples = nil; MADClearRigControls(vehicle); return end
    if r.phase == "moving" and not r.brake then
        if wedgeKnockedLoose(vehicle, v, now) then
            r.wedge, r.wedgeKnockedLoose, r.phase = false, true, "stalled"
            v.speedSamples = nil
            MADClearRigControls(vehicle)
            return
        end
    else v.speedSamples = nil end
    local steer = MADSteering.update(v.steering, vehicle:getX(), vehicle:getY()) or 0
    r.distance, r.unrestrainedSign = v.steering.distance, v.steering.unrestrainedSign
    local direction = r.gear == "reverse" and -1 or 1
    if MADSetRigControls(vehicle, direction, steer, speedTargets[r.speed], r.brake) then
        vehicle:setPhysicsActive(true)
        vehicle:updatePhysics()
        if r.brake then vehicle:setEngineSpeed(1700) end
    end
end
function MADRig.tick()
    if isClient() or isServer() or not MADLoadedVehicles or not MADSetRigControls or not MADClearRigControls or not getCell() then return end
    local vehicles = MADLoadedVehicles(getCell())
    if not vehicles then return end
    local now = getTimestampMs()
    local seen = {}
    for i=0,vehicles:size()-1 do
        local vehicle = vehicles:get(i)
        local r = MADRig.get(vehicle)
        if r then
            seen[vehicle] = true
            local ok, err = pcall(tickVehicle, vehicle, r, now)
            if not ok then print("[MAD] Rig update failed: " .. tostring(err)); MADClearRigControls(vehicle) end
        end
    end
    for vehicle in pairs(runtime) do if not seen[vehicle] then MADClearRigControls(vehicle); runtime[vehicle] = nil end end
end
Events.OnTick.Add(MADRig.tick)






