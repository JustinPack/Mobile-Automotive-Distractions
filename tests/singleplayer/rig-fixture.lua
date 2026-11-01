function require(name) end
Events={ OnTick={Add=function(f) rigTick=f end} }
function isClient() return false end
function isServer() return false end
function ZombRand(n) return 0 end
local now=0
function getTimestampMs() return now end
function getGameTime() return {getWorldAgeHours=function() return now/3600000 end} end
function getCell() return {} end
Perks={Electricity=1,Mechanics=2}
Vector3f={new=function() return {} end}
SandboxVars={MAD={RequireSkills=false,RequireMaterials=false}}
local controllerActive, lastDirection = false, nil
function MADSetRigControls(v,d,s,speed,brake) controllerActive=true; lastDirection=d; return true end
function MADClearRigControls(v) controllerActive=false; return true end
function MADPackItem(i) return i.packed end
function MADUnpackItem(v) if v=="bad" then return nil end; return {packed=v} end
local held={}
local tapeUses=0
local container={ Remove=function(self,item) held[item]=nil end }
local function item(kind,name)
 local a={packed=kind}; held[a]=true
 function a:getFullType() return kind end
 function a:getName() return name end
 function a:isEquipped() return false end
 function a:getContainer() return container end
 function a:Use() tapeUses=tapeUses+1 end
 return a
end
local given=0
local inventory={ containsRecursive=function(self,i) return held[i] == true end,
 AddItem=function(self,i) given=given+1 end,
 getItemFromTypeRecurse=function(self,kind) for i in pairs(held) do if i:getFullType()==kind then return i end end end }
local skillLevel=0
local player={ getVehicle=function() return nil end,getZ=function() return 0 end,
 DistToSquared=function() return 0 end,getInventory=function() return inventory end,
 getPerkLevel=function() return skillLevel end }
local state={}
local engine={getModData=function() return state end}
local batteryItem={charge=1,getCurrentUsesFloat=function(self) return self.charge end,setCurrentUsesFloat=function(self,v) self.charge=v end}
local battery={getInventoryItem=function() return batteryItem end}
local car={updates=0, horn=false,
 speed=0,getCurrentSpeedKmHour=function(self) return self.speed end,
 getPartById=function(self,id) if id=="Engine" then return engine end end,
 getScript=function() return {} end,isBurntOrSmashed=function() return false end,
 getPassengerPosition=function() return {getOffset=function() return {} end} end,
 getWorldPos=function() return {x=function() return 0 end,y=function() return 0 end} end,
 getZ=function() return 0 end,isStopped=function() return true end,getDriver=function() return nil end,
 isEngineRunning=function() return true end,hasLiveBattery=function() return batteryItem.charge>0 end,
 onHornStart=function(self) self.horn=true end,onHornStop=function(self) self.horn=false end,
 getBattery=function() return battery end,getX=function() return 0 end,getY=function() return 0 end,
 setPhysicsActive=function() end,updatePhysics=function(self) self.updates=self.updates+1 end,
 setEngineSpeed=function() end }
function MADLoadedVehicles() return {size=function() return 1 end,get=function() return car end} end
function runRigTests()
 assert(MADRig.start(player,car))
 local rig=MADRig.get(car); assert(rig and not rig.brake)
 assert(rig.requireMaterials and rig.requireSkills)
 assert(not MADRig.freeWedge(car))
 assert(MADRig.configure(car,"gear","reverse"))
 assert(not MADRig.restraint(player,car,"rope"))
 local rope=item("Base.Rope","Rope")
 assert(MADRig.restraint(player,car,"rope"))
 assert(MADRig.configure(car,"direction","left"))
 assert(not MADRig.horn(player,car,true)); skillLevel=3
 assert(not MADRig.horn(player,car,true)); local screwdriver=item("Base.Screwdriver","Screwdriver")
 assert(MADRig.horn(player,car,true) and car.horn)
 assert(MADRig.setBrake(car))
 assert(MADRig.release(car) and not rig.brake and rig.phase=="setup")
 assert(MADRig.setBrake(car))
 local firstStone=item("Base.Stone2","Stone")
 assert(MADRig.attachWedge(player,car,firstStone) and rig.wedge and not held[firstStone])
 assert(MADRig.configure(car,"speed","full"))
 assert(MADRig.release(car) and rig.phase=="moving")
 rigTick(); assert(controllerActive and car.updates==1 and lastDirection == -1)
 now=1000; rigTick(); assert(batteryItem.charge<1)
 assert(MADRig.disarm(player,car)); assert(not controllerActive and not car.horn and MADRig.get(car)==nil)
 assert(given==2)
 SandboxVars.MAD.RequireMaterials=true; SandboxVars.MAD.RequireSkills=true
 assert(MADRig.start(player,car)); assert(MADRig.setBrake(car)); rig=MADRig.get(car)
 assert(not MADRig.freeWedge(car)); skillLevel=0; assert(not MADRig.horn(player,car,true))
 local stone=item("Base.Stone2","Stone")
 assert(MADRig.attachWedge(player,car,stone)); assert(not held[stone] and rig.wedgeItem)
 rig.wedgeItem="bad"; assert(not MADRig.disarm(player,car)); assert(MADRig.get(car)==rig and given==2)
 rig.wedgeItem="Base.Stone2"; assert(MADRig.disarm(player,car)); assert(given==3)
 assert(MADRig.start(player,car)); assert(MADRig.setBrake(car))
 local board=item("Base.Plank","Plank"); assert(not MADRig.restraint(player,car,"board")); assert(held[board])
 local tape=item("Base.DuctTape","Tape"); assert(MADRig.restraint(player,car,"board")); assert(not held[board] and not held[tape])
 assert(MADRig.disarm(player,car)); assert(given==4)
 assert(MADRig.start(player,car)); rig=MADRig.get(car)
 local runawayStone=item("Base.Stone2","Stone")
 assert(MADRig.attachWedge(player,car,runawayStone) and rig.phase=="moving" and not rig.brake)
 assert(not held[runawayStone]); rigTick(); assert(controllerActive)
 assert(MADRig.disarm(player,car)); assert(given==5)
 SandboxVars.MAD.RequireSkills=false
 skillLevel=3
 assert(MADRig.start(player,car)); rig=MADRig.get(car)
 assert(MADRig.horn(player,car,true)); local impactStone=item("Base.Stone2","Stone")
 assert(MADRig.attachWedge(player,car,impactStone))
 car.speed=-20; now=2000; rigTick(); assert(controllerActive)
 car.speed=-10; now=2200; rigTick(); assert(controllerActive and rig.wedge)
 car.speed=-1; now=2250; rigTick()
 assert(not controllerActive and not rig.wedge and rig.wedgeKnockedLoose and rig.phase=="stalled" and car.horn)
 assert(MADRig.disarm(player,car) and given==6 and not car.horn)
 car.speed=0
 print("Rig state tests passed")
end



