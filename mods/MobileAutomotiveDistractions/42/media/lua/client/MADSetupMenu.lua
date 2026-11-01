require "MADSetupPreview"
local function open(player, vehicle)
    local r = MADRig.get(vehicle)
    if not r then
        local ok, reason = MADRig.start(player, vehicle)
        if not ok then player:Say(reason); return end
    end
    local window = MADRigWindow:new(player, vehicle)
    window:initialise(); window:addToUIManager()
end
local function disarm(player, vehicle)
    local ok, reason = MADRig.disarm(player, vehicle)
    player:Say(ok and "Distraction rig removed." or reason)
end
local function menu(playerNum, context, objects, test)
    if test or isClient() or isServer() then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:getVehicle() then return end
    local vehicle = IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(), getMouseYScaled())
    if not vehicle then return end
    local r = MADRig.get(vehicle)
    if r then
        if r.phase == "setup" and vehicle:isStopped() and MADRig.atDriverDoor(player, vehicle) then context:addOption("Configure distraction rig", player, open, vehicle) end
        context:addOption("Disarm distraction rig", player, disarm, vehicle)
    elseif MADRig.atDriverDoor(player, vehicle) and MADRig.isUsable(vehicle) and vehicle:isStopped() and vehicle:isEngineRunning() and not vehicle:getDriver() then
        context:addOption("Rig as distraction", player, open, vehicle)
    end
end
Events.OnFillWorldObjectContextMenu.Add(menu)
