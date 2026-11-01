require "MADMPRigState"
local key="MobileAutomotiveDistractionMP"
local active={}
local wedges={["Base.Stone2"]=true,["Base.Wrench"]=true}
local function engine(vehicle) return vehicle and vehicle:getPartById("Engine") end
local function rig(vehicle) local p=engine(vehicle); return p and p:getModData()[key] end
local function door(player,vehicle)
    if player:getVehicle() or player:getZ()~=vehicle:getZ() then return false end
    local outside=vehicle:getPassengerPosition(0,"outside")
    if not outside then return false end
    local point=vehicle:getWorldPos(outside:getOffset(),Vector3f.new())
    return player:DistToSquared(point:x(),point:y())<=4
end
local function online(player)
    local all=getOnlinePlayers()
    for i=0,all:size()-1 do if all:get(i)==player then return true end end
    return false
end
local function message(player,s) sendServerCommand(player,"MADMPRig","message",{text=s}) end
local function transmit(vehicle)
    local p=engine(vehicle)
    if p then vehicle:transmitPartModData(p) end
    local r=rig(vehicle)
    local public=nil
    if r then
        public={version=r.version,phase=r.phase,brake=r.brake,wedge=r.wedge,wedgeName=r.wedgeName,
            gear=r.gear,speed=r.speed,restraint=r.restraint,direction=r.direction,turnRate=r.turnRate,
            horn=r.horn,requireSkills=r.requireSkills,requireMaterials=r.requireMaterials,
            distance=r.distance,revision=r.revision,ownerId=r.ownerId}
    end
    local all=getOnlinePlayers()
    for i=0,all:size()-1 do sendServerCommand(all:get(i),"MADMPRig","state",{vehicle=vehicle:getId(),state=public}) end
end
local function release(vehicle,session)
    if session and session.player then MADMPRevokeClientTest(vehicle,session.player) end
    active[vehicle:getId()]=nil
end
local function stopRig(vehicle,r,reason)
    local session=active[vehicle:getId()]
    if r and r.phase~="stalled" then r.phase="stalled"; r.revision=(r.revision or 0)+1 end
    release(vehicle,session)
    print("[MAD MP RIG] stopped "..tostring(vehicle:getId()).." "..reason)
    transmit(vehicle)
end
local function removeItem(player,item)
    if not item or item:isEquipped() or item:getContainer()~=player:getInventory() then return nil end
    local snapshot=MADMPSaveItem(item)
    if not snapshot then return nil end
    player:getInventory():Remove(item)
    sendRemoveItemFromContainer(player:getInventory(),item)
    return snapshot
end
local function command(module,action,player,args)
    if module~="MADMPRig" or not player or type(args)~="table" then return end
    local id=tonumber(args.vehicle)
    if not id or id~=math.floor(id) then return end
    local vehicle=getVehicleById(id)
    if not vehicle or not engine(vehicle) then return end
    local r=rig(vehicle)
    local session=active[id]
    if action=="heartbeat" or action=="impact" then
        if not session or session.player~=player or not r then return end
        if action=="heartbeat" then
            session.last=getTimestampMs()
            local distance=tonumber(args.distance)
            if distance and distance==distance and distance>=(r.distance or 0) and distance<=(r.distance or 0)+25 then r.distance=distance end
            return
        end
        if MADMPRigState.impact(r) then stopRig(vehicle,r,"impact") end
        return
    end
    if not door(player,vehicle) or not vehicle:isStopped() then message(player,"Stop and approach the driver's door."); return end
    if vehicle:isBurntOrSmashed() then message(player,"The vehicle was destroyed."); return end
    if action=="start" then
        if r then message(player,"Vehicle already has a rig."); return end
        if vehicle:getDriver() or not vehicle:isEngineRunning() then message(player,"Start the engine and leave the driver's seat empty."); return end
        if not MADMPGrantClientTest or not MADMPGrantClientTest(vehicle,player) then message(player,"Unable to obtain vehicle control."); return end
        local opts=SandboxVars.MAD or {}
        r=MADMPRigState.new(opts.RequireSkills,opts.RequireMaterials)
        r.ownerId=player:getOnlineID()
        engine(vehicle):getModData()[key]=r
        active[id]={player=player,last=getTimestampMs()}
        transmit(vehicle)
        sendServerCommand(player,"MADMPRig","open",{vehicle=id})
        return
    end
    if not r then message(player,"No distraction rig."); return end
    if action=="disarm" then
        local wedge=r.wedgeItem and MADMPLoadItem(r.wedgeItem) or nil
        local restraint=r.restraintItem and (r.restraint~="board" or r.boardRecoverable) and MADMPLoadItem(r.restraintItem) or nil
        if (r.wedgeItem and not wedge) or (r.restraintItem and (r.restraint~="board" or r.boardRecoverable) and not restraint) then message(player,"Unable to recover item safely."); return end
        if r.horn then vehicle:onHornStop() end
        release(vehicle,session)
        if wedge then player:getInventory():AddItem(wedge); sendAddItemToContainer(player:getInventory(),wedge) end
        if restraint then player:getInventory():AddItem(restraint); sendAddItemToContainer(player:getInventory(),restraint) end
        engine(vehicle):getModData()[key]=nil
        transmit(vehicle); message(player,"Distraction rig removed."); return
    end
    if not session or session.player~=player then message(player,"Only the setup player can change this rig."); return end
    if ((action=="wedge" and not r.brake) or (action=="release" and r.wedge))
        and (not vehicle:isEngineRunning() or vehicle:getDriver()) then
        message(player,"The engine must be running with the driver's seat empty."); return
    end
    local value=args.value
    if action=="wedge" then
        local item=player:getInventory():getItemWithID(tonumber(args.itemId) or -1)
        if not item or not wedges[item:getFullType()] then message(player,"Use a stone or wrench from your main inventory."); return end
        if r.wedge or r.phase~="setup" then message(player,"A wedge cannot be attached now."); return end
        local data=removeItem(player,item)
        if not data then message(player,"Unable to attach this item safely."); return end
        r.wedgeItem=data; r.wedgeName=item:getName()
    elseif action=="restraint" then
        if r.restraint~="none" or r.phase~="setup" or (value~="rope" and value~="board") then message(player,"Cannot attach that restraint."); return end
        local inv=player:getInventory()
        local item=inv:getItemFromType(value=="rope" and "Base.Rope" or "Base.Plank")
        local tape=value=="board" and inv:getItemFromType("Base.DuctTape") or nil
        if not item or item:isEquipped() or (value=="board" and (not tape or tape:isEquipped())) then message(player,"Missing restraint or duct tape in main inventory."); return end
        local data=removeItem(player,item)
        if not data then message(player,"Unable to attach restraint safely."); return end
        r.restraintItem=data
        if tape then inv:Remove(tape); sendRemoveItemFromContainer(inv,tape) end
        r.boardRecoverable=value~="board" or ZombRand(2)==0
    elseif action=="horn" and value==true then
        if player:getPerkLevel(Perks.Electricity)<3 and player:getPerkLevel(Perks.Mechanics)<3 then message(player,"Requires Electrical or Mechanics level 3."); return end
        if not player:getInventory():getItemFromTypeRecurse("Base.Screwdriver") then message(player,"A screwdriver is required."); return end
        if not vehicle:hasLiveBattery() then message(player,"The battery is empty."); return end
    end
    local ok,why=MADMPRigState.apply(r,action,value)
    if not ok then message(player,why); return end
    if action=="horn" then if r.horn then vehicle:onHornStart() else vehicle:onHornStop() end end
    transmit(vehicle)
end
Events.OnClientCommand.Add(command)
local function tick()
    local now=getTimestampMs()
    for id,session in pairs(active) do
        local vehicle=getVehicleById(id)
        if not vehicle then active[id]=nil
        else
            local r=rig(vehicle)
            if not r or not online(session.player) or now-session.last>5000 or vehicle:getDriver() or vehicle:getNetPlayerId()~=session.player:getOnlineID() then
                stopRig(vehicle,r,"owner unavailable")
            elseif vehicle:isBurntOrSmashed() then
                if r.horn then vehicle:onHornStop() end
                release(vehicle,session); engine(vehicle):getModData()[key]=nil; transmit(vehicle)
            end
        end
    end
end
Events.OnTick.Add(tick)
local lastScan=0
local hornClock={}
local function maintain()
    local now=getTimestampMs()
    if now-lastScan<1000 or not MADMPLoadedVehicles then return end
    lastScan=now
    local vehicles=MADMPLoadedVehicles(getCell())
    if not vehicles then return end
    local seen={}
    for i=0,vehicles:size()-1 do
        local vehicle=vehicles:get(i)
        local r=rig(vehicle)
        if r then
            local id=vehicle:getId(); seen[id]=true
            if vehicle:isBurntOrSmashed() then
                if r.horn then vehicle:onHornStop() end
                release(vehicle,active[id]); engine(vehicle):getModData()[key]=nil; transmit(vehicle)
            else
                if not active[id] and r.phase~="stalled" then
                    if MADMPRevokeOrphan then MADMPRevokeOrphan(vehicle,r.ownerId or -1) end
                    r.phase="stalled"; r.revision=(r.revision or 0)+1; transmit(vehicle)
                end
                if r.horn and vehicle:hasLiveBattery() then
                    vehicle:onHornStart()
                    local hours=getGameTime():getWorldAgeHours()
                    local previous=hornClock[id]
                    local battery=vehicle:getBattery()
                    local item=battery and battery:getInventoryItem()
                    if item and previous then
                        local delta=math.max(0,math.min(hours-previous,0.05))*0.05
                        item:setCurrentUsesFloat(math.max(0,item:getCurrentUsesFloat()-delta))
                        vehicle:transmitPartUsedDelta(battery)
                    end
                    hornClock[id]=hours
                else
                    if r.horn then vehicle:onHornStop() end
                    hornClock[id]=nil
                end
            end
        end
    end
    for id in pairs(hornClock) do if not seen[id] then hornClock[id]=nil end end
end
Events.OnTick.Add(maintain)
