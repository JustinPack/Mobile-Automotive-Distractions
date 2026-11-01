function require(name) end
ISCollapsableWindow={derive=function(self,name) return {} end}
ISButton={}; ISInventoryPane={}; ISEnterVehicle={isValid=function() return true end}; ISSwitchVehicleSeat={isValid=function() return true end}
local callbacks={}
Events={OnFillWorldObjectContextMenu={Add=function() end},OnServerCommand={Add=function(f) callbacks.reply=f end},OnTick={Add=function(f) callbacks.tick=f end}}
function isClient() return true end
function ZombRand() return 0 end
local now=10000
function getTimestampMs() return now end
local player={getOnlineID=function() return 7 end}
function getSpecificPlayer() return player end
local speed=0
local v={getId=function() return 1 end,getNetPlayerId=function() return 7 end,isLocalPhysicSim=function() return true end,
 getX=function() return 0 end,getY=function() return 0 end,getCurrentSpeedKmHour=function() return speed end,
 setPhysicsActive=function() end,updatePhysics=function() end,updatePhysicsNetwork=function() end}
function getVehicleById(id) if id==1 then return v end end
local input,impacts,heartbeats,stops=0,0,0,0
function MADMPSetRigInput(vehicle,owner,gear,steer,target,brake)
 assert(vehicle==v and owner==7 and gear==-1 and target==25 and not brake); input=input+1; return true
end
function MADMPStopClientLeaseTest() stops=stops+1 end
function sendClientCommand(player,module,action,args) if action=="heartbeat" then heartbeats=heartbeats+1 elseif action=="impact" then impacts=impacts+1 end end
function runTest()
 local state={phase="moving",ownerId=7,wedge=true,gear="reverse",speed="medium",brake=false,
  restraint="none",direction="straight",turnRate="slow",distance=0,revision=1}
 callbacks.reply("MADMPRig","state",{vehicle=1,state=state})
 speed=20; callbacks.tick(); assert(input==1 and heartbeats==1)
 now=10100; speed=1; callbacks.tick(); assert(impacts==1 and stops==1 and state.phase=="stalled")
 callbacks.tick(); assert(impacts==1)
end
