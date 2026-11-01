function require(name) end
local handlers={}
Events={OnClientCommand={Add=function(f) handlers.command=f end},OnTick={Add=function(f) handlers[#handlers+1]=f end}}
local now=10000
function getTimestampMs() return now end
function getGameTime() return {getWorldAgeHours=function() return now/3600000 end} end
function getCell() return {} end
function ZombRand() return 0 end
Vector3f={new=function() return {} end}; Perks={Electricity=1,Mechanics=2}; SandboxVars={MAD={RequireSkills=false,RequireMaterials=false}}
local moddata={}
local e={getModData=function() return moddata end}
local owner=-1
local v={horn=false,getId=function() return 1 end,getPartById=function(self,id) if id=="Engine" then return e end end,
 getZ=function() return 0 end,getPassengerPosition=function() return {getOffset=function() return {} end} end,
 getWorldPos=function() return {x=function() return 0 end,y=function() return 0 end} end,
 isStopped=function() return true end,isBurntOrSmashed=function() return false end,getDriver=function() return nil end,
 isEngineRunning=function() return true end,getNetPlayerId=function() return owner end,transmitPartModData=function() end,
 hasLiveBattery=function() return true end,onHornStart=function(self) self.horn=true end,onHornStop=function(self) self.horn=false end}
local items={}
local inventory={getItemWithID=function(self,id) return items[id] end,
 getItemFromType=function(self,name) for _,it in pairs(items) do if it.kind==name then return it end end end,
 getItemFromTypeRecurse=function(self,name) return self:getItemFromType(name) end,
 Remove=function(self,item) items[item.id]=nil end,
 AddItem=function(self,item) items[item.id]=item end}
local function addItem(id,kind)
 local item={id=id,kind=kind,getFullType=function(self) return self.kind end,getName=function(self) return self.kind end,
  isEquipped=function() return false end,getContainer=function() return inventory end}
 items[id]=item; return item
end
local skillLevel=0
local player={getVehicle=function() return nil end,getZ=function() return 0 end,DistToSquared=function() return 0 end,
 getOnlineID=function() return 7 end,getPerkLevel=function() return skillLevel end,getInventory=function() return inventory end}
function getOnlinePlayers() return {size=function() return 1 end,get=function() return player end} end
function getVehicleById(id) if id==1 then return v end end
function sendServerCommand() end
function sendRemoveItemFromContainer() end
function sendAddItemToContainer() end
function MADMPSaveItem(item) return item.kind end
function MADMPLoadItem(kind) if kind=="bad" then return nil end; return addItem(100,kind) end
function MADMPGrantClientTest() owner=7; return true end
function MADMPRevokeClientTest() owner=-1; return true end
function MADMPLoadedVehicles() return nil end
function runTest()
 handlers.command("MADMPRig","start",player,{vehicle=1})
 local r=moddata.MobileAutomotiveDistractionMP; assert(r and owner==7 and r.phase=="setup")
 assert(r.requireMaterials and r.requireSkills)
 handlers.command("MADMPRig","materials",player,{vehicle=1}); handlers.command("MADMPRig","skills",player,{vehicle=1})
 assert(r.requireMaterials and r.requireSkills)
 handlers.command("MADMPRig","gear",player,{vehicle=1,value="reverse"}); assert(r.gear=="reverse")
 handlers.command("MADMPRig","horn",player,{vehicle=1,value=true}); assert(not r.horn)
 skillLevel=3; handlers.command("MADMPRig","horn",player,{vehicle=1,value=true}); assert(not r.horn)
 addItem(90,"Base.Screwdriver")
 handlers.command("MADMPRig","horn",player,{vehicle=1,value=true}); assert(r.horn and v.horn)
 handlers.command("MADMPRig","brake",player,{vehicle=1}); assert(r.brake)
 handlers.command("MADMPRig","wedge",player,{vehicle=1}); assert(not r.wedge)
 addItem(1,"Base.Stone2"); handlers.command("MADMPRig","wedge",player,{vehicle=1,itemId=1}); assert(r.wedge and r.phase=="setup" and not items[1])
 handlers.command("MADMPRig","release",player,{vehicle=1}); assert(r.phase=="moving")
 handlers.command("MADMPRig","impact",{}, {vehicle=1}); assert(r.phase=="moving")
 handlers.command("MADMPRig","impact",player,{vehicle=1}); assert(r.phase=="stalled" and r.horn and v.horn and owner==-1)
 handlers.command("MADMPRig","disarm",player,{vehicle=1}); assert(not moddata.MobileAutomotiveDistractionMP and not v.horn)
 handlers.command("MADMPRig","start",player,{vehicle=1}); r=moddata.MobileAutomotiveDistractionMP
 now=16000; handlers[1](); assert(r.phase=="stalled" and owner==-1)
 handlers.command("MADMPRig","disarm",player,{vehicle=1})
 SandboxVars.MAD.RequireMaterials=true
 addItem(10,"Base.Stone2"); handlers.command("MADMPRig","start",player,{vehicle=1}); r=moddata.MobileAutomotiveDistractionMP
 handlers.command("MADMPRig","brake",player,{vehicle=1})
 handlers.command("MADMPRig","wedge",player,{vehicle=1,itemId=10}); assert(not items[10] and r.wedgeItem=="Base.Stone2")
 handlers.command("MADMPRig","disarm",player,{vehicle=1}); assert(items[100] and items[100].kind=="Base.Stone2")
 addItem(11,"Base.Plank"); handlers.command("MADMPRig","start",player,{vehicle=1}); r=moddata.MobileAutomotiveDistractionMP
 handlers.command("MADMPRig","restraint",player,{vehicle=1,value="board"}); assert(items[11] and r.restraint=="none")
 addItem(12,"Base.DuctTape"); handlers.command("MADMPRig","restraint",player,{vehicle=1,value="board"})
 assert(not items[11] and not items[12] and r.restraint=="board" and r.boardRecoverable)
 handlers.command("MADMPRig","disarm",player,{vehicle=1}); assert(items[100] and items[100].kind=="Base.Plank")
 SandboxVars.MAD.RequireSkills=true; skillLevel=0; handlers.command("MADMPRig","start",player,{vehicle=1}); r=moddata.MobileAutomotiveDistractionMP
 handlers.command("MADMPRig","horn",player,{vehicle=1,value=true}); assert(not r.horn and not v.horn)
end
