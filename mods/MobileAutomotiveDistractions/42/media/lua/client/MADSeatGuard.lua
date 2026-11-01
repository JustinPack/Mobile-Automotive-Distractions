require "MADRig"
require "Vehicles/TimedActions/ISEnterVehicle"
require "Vehicles/TimedActions/ISSwitchVehicleSeat"
local previousEnter = ISEnterVehicle.isValid
function ISEnterVehicle:isValid()
    if self.seat == 0 and self.vehicle and MADRig.get(self.vehicle) then
        if not self.madAnnounced then self.character:Say("This car is rigged as a distraction"); self.madAnnounced = true end
        return false
    end
    return previousEnter(self)
end
local previousSwitch = ISSwitchVehicleSeat.isValid
function ISSwitchVehicleSeat:isValid()
    local v = self.character:getVehicle()
    if self.seatTo == 0 and v and MADRig.get(v) then
        if not self.madAnnounced then self.character:Say("This car is rigged as a distraction"); self.madAnnounced = true end
        return false
    end
    return previousSwitch(self)
end

