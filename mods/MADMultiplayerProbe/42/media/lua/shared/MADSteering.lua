-- Pure steering policy. Distances assume one world tile is approximately one metre.
-- Input magnitudes are experimental and require calibration against real vehicles.
MADSteering = {}
local rates = { slow = 0.2, medium = 0.45, fast = 0.75 }
local function randomSign(random)
    return random() < 0.5 and -1 or 1
end
function MADSteering.new(restraint, direction, rate, random)
    if restraint ~= "none" and restraint ~= "rope" and restraint ~= "board" then return nil end
    if direction ~= "left" and direction ~= "straight" and direction ~= "right" then return nil end
    if not rates[rate] or type(random) ~= "function" then return nil end
    return { restraint = restraint, direction = direction, rate = rate, random = random,
        distance = 0, lastX = nil, lastY = nil, unrestrainedSign = nil,
        driftSign = 0, nextDriftAt = 200 }
end
function MADSteering.update(s, x, y)
    if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y then return nil end
    if s.lastX ~= nil then
        local dx, dy = x - s.lastX, y - s.lastY
        s.distance = s.distance + math.sqrt(dx * dx + dy * dy)
    end
    s.lastX, s.lastY = x, y
    if s.restraint == "none" then
        if s.distance < 20 then return 0 end
        if not s.unrestrainedSign then s.unrestrainedSign = randomSign(s.random) end
        local ramp = math.min(1, math.max(0, (s.distance - 20) / 40))
        return s.unrestrainedSign * rates.slow * ramp
    end
    if s.direction == "left" then return -rates[s.rate] end
    if s.direction == "right" then return rates[s.rate] end
    if s.distance < 200 then return 0 end
    if s.distance >= s.nextDriftAt then
        s.driftSign = randomSign(s.random)
        s.nextDriftAt = s.distance + 25
    end
    return s.driftSign * 0.02
end

