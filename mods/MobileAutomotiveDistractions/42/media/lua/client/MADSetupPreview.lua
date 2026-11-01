require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "MADRig"

MADRigWindow = ISCollapsableWindow:derive("MADRigWindow")
function MADRigWindow:addControl(x, y, width, title, key, value)
    local b = ISButton:new(x, y, width, 24, title, self, self.onControl)
    b.internal, b.value = key, value
    b:initialise(); b:instantiate(); self:addChild(b)
end
function MADRigWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self:addControl(24, 154, 120, "Engage brake", "brake", true)
    self:addControl(150, 154, 120, "Release", "release", true)
    self:addControl(24, 282, 76, "Slow", "speed", "slow")
    self:addControl(105, 282, 76, "Medium", "speed", "medium")
    self:addControl(186, 282, 76, "Full", "speed", "full")
    self:addControl(24, 414, 112, "Forward", "gear", "forward")
    self:addControl(142, 414, 112, "Reverse", "gear", "reverse")
    self:addControl(324, 154, 110, "Attach rope", "restraint", "rope")
    self:addControl(440, 154, 110, "Attach board", "restraint", "board")
    self:addControl(324, 186, 75, "Left", "direction", "left")
    self:addControl(404, 186, 75, "Straight", "direction", "straight")
    self:addControl(484, 186, 75, "Right", "direction", "right")
    self:addControl(324, 218, 75, "Slow", "turnRate", "slow")
    self:addControl(404, 218, 75, "Medium", "turnRate", "medium")
    self:addControl(484, 218, 75, "Fast", "turnRate", "fast")
    self:addControl(324, 354, 110, "Rig horn", "horn", true)
    self:addControl(440, 354, 110, "Unrig horn", "horn", false)
    self:addControl(24, 455, 180, "Disarm and recover", "disarm", true)
end
function MADRigWindow:onControl(button)
    local r = MADRig.get(self.vehicle)
    if not r or not MADRig.atDriverDoor(self.character, self.vehicle) then self:close(); return end
    local key, value, ok, reason = button.internal, button.value, false, nil
    if key == "disarm" then
        ok, reason = MADRig.disarm(self.character, self.vehicle)
        if ok then self:close() else self.message = reason end
        return
    end
    if key == "brake" then ok, reason = MADRig.setBrake(self.vehicle)
    elseif key == "release" then ok, reason = MADRig.release(self.vehicle)
    elseif key == "restraint" then ok, reason = MADRig.restraint(self.character, self.vehicle, value)
    elseif key == "horn" then ok, reason = MADRig.horn(self.character, self.vehicle, value)
    else ok, reason = MADRig.configure(self.vehicle, key, value) end
    self.message = ok and "Configuration applied." or reason
    if ok and r.phase == "moving" then MADRig.tick(); self:close() end
end
function MADRigWindow:onMouseUp(x, y)
    local launch = false
    if x >= 24 and x <= 270 and y >= 239 and y <= 275 and ISMouseDrag.dragging then
        local items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        local ok, reason = MADRig.attachWedge(self.character, self.vehicle, items and items[1])
        self.message = ok and "Wedge attached." or reason
        local r = MADRig.get(self.vehicle)
        launch = ok and r and r.phase == "moving"
    end
    ISCollapsableWindow.onMouseUp(self, x, y)
    if launch then MADRig.tick(); self:close() end
end
local function card(self, x, y, w, h, title)
    self:drawRectBorder(x, y, w, h, 0.75, 0.55, 0.75, 0.78)
    self:drawText(title, x + 10, y + 7, 0.72, 0.87, 0.88, 1, UIFont.Small)
end
function MADRigWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local r = MADRig.get(self.vehicle)
    if not r or not MADRig.atDriverDoor(self.character, self.vehicle) then self:close(); return end
    self:drawText("Wedge the pedal with the brake off and the vehicle drives away.", 16, 34, 1, 1, 1, 1, UIFont.Small)
    card(self, 14, 62, 272, 122, "PARKING BRAKE")
    self:drawRectBorder(28, 96, 76, 30, 0.8, 0.6, 0.8, 0.8)
    self:drawRect(104, 109, 48, 3, 0.8, 0.6, 0.8, 0.8)
    self:drawText(r.brake and "ENGAGED" or "OFF", 166, 101, 1, 1, 1, 1, UIFont.Small)
    card(self, 14, 192, 272, 152, "ACCELERATOR")
    self:drawText("Target: " .. r.speed .. " (10 / 25 / 50 km/h)", 24, 213, 1, 1, 1, 1, UIFont.Small)
    self:drawRectBorder(24, 239, 246, 36, 0.8, 0.6, 0.8, 0.8)
    self:drawText(r.wedgeName or "Drag stone or wrench here", 32, 249, 1, 1, 1, 1, UIFont.Small)
    card(self, 14, 352, 272, 96, "GEAR SELECTOR")
    self:drawText("Selected: " .. r.gear, 24, 380, 1, 1, 1, 1, UIFont.Small)
    card(self, 300, 62, 282, 202, "STEERING WHEEL")
    self:drawRectBorder(316, 93, 42, 42, 0.8, 0.6, 0.8, 0.8)
    self:drawText("Restraint: " .. r.restraint, 372, 93, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Steering: " .. r.direction .. " / " .. r.turnRate, 372, 117, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Rope or plank + duct tape", 324, 136, 0.85, 0.85, 0.85, 1, UIFont.Small)
    card(self, 300, 272, 282, 119, "HORN")
    self:drawText(r.horn and "Rigged" or "Off", 324, 306, 1, 1, 1, 1, UIFont.Small)
    card(self, 300, 398, 282, 76, "HORN REQUIREMENTS")
    self:drawText("Screwdriver and level 3", 314, 419, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Electrical or Mechanics", 314, 438, 1, 1, 1, 1, UIFont.Small)
    self:drawText(self.message or "", 16, 485, 1, 0.85, 0.55, 1, UIFont.Small)
end
function MADRigWindow:new(player, vehicle)
    local width, height = 596, 525
    local o = ISCollapsableWindow:new((getCore():getScreenWidth()-width)/2, (getCore():getScreenHeight()-height)/2, width, height)
    setmetatable(o, self); self.__index = self
    o:setResizable(false); o.title = "Rig as distraction"; o.character = player; o.vehicle = vehicle
    o.message = "Set the brake if you want the vehicle to stay put."
    return o
end
