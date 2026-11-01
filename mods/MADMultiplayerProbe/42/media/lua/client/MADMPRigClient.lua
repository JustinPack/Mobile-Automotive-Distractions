require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "MADSteering"
MADMPRigClient={states={},runtime={}}
local C=MADMPRigClient
local speeds={slow=10,medium=25,full=50}
function C.get(v)
    if not v then return nil end
    local entry=C.states[v:getId()]
    if entry then return entry.state end
    local p=v:getPartById("Engine")
    return p and p:getModData().MobileAutomotiveDistractionMP or nil
end
function C.send(player,v,action,value,itemId)
    sendClientCommand(player,"MADMPRig",action,{vehicle=v:getId(),value=value,itemId=itemId})
end
MADMPRigWindow=ISCollapsableWindow:derive("MADMPRigWindow")
function MADMPRigWindow:button(x,y,w,title,key,value)
    local b=ISButton:new(x,y,w,24,title,self,self.onAction)
    b.internal=key; b.value=value; b:initialise(); b:instantiate(); self:addChild(b)
end
function MADMPRigWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self:button(24,154,120,"Engage brake","brake",true); self:button(150,154,120,"Release","release",true)
    self:button(24,282,76,"Slow","speed","slow"); self:button(105,282,76,"Medium","speed","medium"); self:button(186,282,76,"Full","speed","full")
    self:button(24,414,112,"Forward","gear","forward"); self:button(142,414,112,"Reverse","gear","reverse")
    self:button(324,154,110,"Attach rope","restraint","rope"); self:button(440,154,110,"Attach board","restraint","board")
    self:button(324,186,75,"Left","direction","left"); self:button(404,186,75,"Straight","direction","straight"); self:button(484,186,75,"Right","direction","right")
    self:button(324,218,75,"Slow","turnRate","slow"); self:button(404,218,75,"Medium","turnRate","medium"); self:button(484,218,75,"Fast","turnRate","fast")
    self:button(324,354,110,"Rig horn","horn",true); self:button(440,354,110,"Unrig horn","horn",false)
    self:button(24,455,180,"Disarm and recover","disarm",true)
end
function MADMPRigWindow:onAction(b)
    C.send(self.character,self.vehicle,b.internal,b.value)
    self.message="Applying..."
end
function MADMPRigWindow:onMouseUp(x,y)
    if x>=24 and x<=270 and y>=239 and y<=275 and ISMouseDrag.dragging then
        local items=ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        local item=items and items[1]
        if item then C.send(self.character,self.vehicle,"wedge",true,item:getID()); self.message="Applying..." end
    end
    ISCollapsableWindow.onMouseUp(self,x,y)
end
local function card(self,x,y,w,h,title)
    self:drawRectBorder(x,y,w,h,0.75,0.55,0.75,0.78)
    self:drawText(title,x+10,y+7,0.72,0.87,0.88,1,UIFont.Small)
end
function MADMPRigWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local r=C.get(self.vehicle)
    if not r or r.phase~="setup" then self:close(); return end
    self:drawText("Wedge the pedal with the brake off and the vehicle drives away.",16,34,1,1,1,1,UIFont.Small)
    card(self,14,62,272,122,"PARKING BRAKE")
    self:drawRectBorder(28,96,76,30,0.8,0.6,0.8,0.8); self:drawRect(104,109,48,3,0.8,0.6,0.8,0.8)
    self:drawText(r.brake and "ENGAGED" or "OFF",166,101,1,1,1,1,UIFont.Small)
    card(self,14,192,272,152,"ACCELERATOR"); self:drawText("Target: "..r.speed.." (10 / 25 / 50 km/h)",24,213,1,1,1,1,UIFont.Small)
    self:drawRectBorder(24,239,246,36,0.8,0.6,0.8,0.8); self:drawText(r.wedgeName or "Drag stone or wrench here",32,249,1,1,1,1,UIFont.Small)
    card(self,14,352,272,96,"GEAR SELECTOR"); self:drawText("Selected: "..r.gear,24,380,1,1,1,1,UIFont.Small)
    card(self,300,62,282,202,"STEERING WHEEL")
    self:drawRectBorder(316,93,42,42,0.8,0.6,0.8,0.8); self:drawText("Restraint: "..r.restraint,372,93,1,1,1,1,UIFont.Small)
    self:drawText("Steering: "..r.direction.." / "..r.turnRate,372,117,1,1,1,1,UIFont.Small)
    self:drawText("Rope or plank + duct tape",324,136,0.85,0.85,0.85,1,UIFont.Small)
    card(self,300,272,282,119,"HORN"); self:drawText(r.horn and "Rigged" or "Off",324,306,1,1,1,1,UIFont.Small)
    card(self,300,398,282,76,"HORN REQUIREMENTS")
    self:drawText("Screwdriver and level 3",314,419,1,1,1,1,UIFont.Small)
    self:drawText("Electrical or Mechanics",314,438,1,1,1,1,UIFont.Small)
    self:drawText(self.message or "",16,485,1,0.85,0.55,1,UIFont.Small)
end
function MADMPRigWindow:new(player,v)
    local w,h=596,525
    local o=ISCollapsableWindow:new((getCore():getScreenWidth()-w)/2,(getCore():getScreenHeight()-h)/2,w,h)
    setmetatable(o,self); self.__index=self; o:setResizable(false)
    o.title="Rig as distraction"; o.character=player; o.vehicle=v; o.message="Set the brake if you want the vehicle to stay put."
    return o
end
local function open(player,v)
    if C.get(v) then local w=MADMPRigWindow:new(player,v); C.window=w; w:initialise(); w:addToUIManager()
    else C.send(player,v,"start") end
end
local function disarm(player,v) C.send(player,v,"disarm") end
local function menu(playerNum,context,objects,test)
    if test or not isClient() then return end
    local p=getSpecificPlayer(playerNum)
    if not p or p:getVehicle() then return end
    local v=IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(),getMouseYScaled())
    if not v then return end
    local r=C.get(v)
    if r then
        if r.phase=="setup" and r.ownerId==p:getOnlineID() then context:addOption("Configure distraction rig",p,open,v) end
        context:addOption("Disarm distraction rig",p,disarm,v)
    elseif v:isStopped() and v:isEngineRunning() and not v:getDriver() then context:addOption("Rig as distraction",p,open,v) end
end
Events.OnFillWorldObjectContextMenu.Add(menu)
local function reply(module,action,args)
    if module~="MADMPRig" or type(args)~="table" then return end
    local p=getSpecificPlayer(0)
    if action=="message" then
        if C.window then C.window.message=args.text or "Rig action failed." end
        if p then p:Say(args.text or "Rig action failed.") end
        return
    end
    local id=tonumber(args.vehicle); if not id then return end
    if action=="state" then
        C.states[id]={state=args.state}
        if C.window and C.window.vehicle and C.window.vehicle:getId()==id then C.window.message="" end
        if not args.state then C.runtime[id]=nil end
    elseif action=="open" and p then local v=getVehicleById(id); if v and C.get(v) then open(p,v) end end
end
Events.OnServerCommand.Add(reply)
local function step()
    if not isClient() then return end
    local player=getSpecificPlayer(0); if not player then return end
    local now=getTimestampMs()
    for id,entry in pairs(C.states) do
        local r=entry.state
        if r and r.ownerId==player:getOnlineID() and r.phase~="stalled" then
            local v=getVehicleById(id)
            if v then
                local runtime=C.runtime[id] or {samples={}}; C.runtime[id]=runtime
                if not runtime.heartbeat or now-runtime.heartbeat>=1000 then
                    sendClientCommand(player,"MADMPRig","heartbeat",{vehicle=id,distance=runtime.steering and runtime.steering.distance or r.distance or 0})
                    runtime.heartbeat=now
                end
                if r.wedge and v:getNetPlayerId()==player:getOnlineID() and v:isLocalPhysicSim() then
                    if not runtime.steering or runtime.rev~=r.revision then
                        local distance=runtime.steering and runtime.steering.distance or r.distance or 0
                        runtime.steering=MADSteering.new(r.restraint,r.direction,r.turnRate,function() return ZombRand(10000)/10000 end)
                        runtime.steering.distance=distance; runtime.rev=r.revision
                    end
                    local steer=MADSteering.update(runtime.steering,v:getX(),v:getY()) or 0
                    local velocity=math.abs(v:getCurrentSpeedKmHour())
                    while #runtime.samples>0 and now-runtime.samples[1].time>500 do table.remove(runtime.samples,1) end
                    local impact=false
                    if r.phase=="moving" then for i=1,#runtime.samples do if runtime.samples[i].speed>=5 and velocity<=runtime.samples[i].speed*0.1 then impact=true; break end end end
                    runtime.samples[#runtime.samples+1]={time=now,speed=velocity}
                    if impact then
                        MADMPStopClientLeaseTest(v); C.send(player,v,"impact"); r.phase="stalled"
                    elseif MADMPSetRigInput(v,player:getOnlineID(),r.gear=="reverse" and -1 or 1,steer,speeds[r.speed],r.brake) then
                        v:setPhysicsActive(true); v:updatePhysics(); v:updatePhysicsNetwork()
                        if r.brake then v:setEngineSpeed(1700) end
                    end
                end
            end
        end
    end
end
Events.OnTick.Add(step)
require "Vehicles/TimedActions/ISEnterVehicle"
require "Vehicles/TimedActions/ISSwitchVehicleSeat"
local enter=ISEnterVehicle.isValid
function ISEnterVehicle:isValid()
    if self.seat==0 and self.vehicle and C.get(self.vehicle) then self.character:Say("This car is rigged as a distraction"); return false end
    return enter(self)
end
local switch=ISSwitchVehicleSeat.isValid
function ISSwitchVehicleSeat:isValid()
    local v=self.character:getVehicle()
    if self.seatTo==0 and v and C.get(v) then self.character:Say("This car is rigged as a distraction"); return false end
    return switch(self)
end
