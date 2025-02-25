PowerManager = {}

local PowerManager_mt = Class(PowerManager)

function PowerManager.new()
    local self = setmetatable({}, PowerManager_mt)
    
    -- Configuration parameters
    self.maxSpeedIncrease = 1.5 -- Maximum 50% speed increase
    self.minSpeedMultiplier = 0.8 -- Slow down if underpowered
    self.minPowerRatio = 0.7 -- Minimum power requirement (70%)
    
    -- Store vehicle-implement associations
    self.vehicleImplements = {}
    
    return self
end

function PowerManager:loadMap(name)
    -- Subscribe to attachment/detachment events
    g_messageCenter:subscribe(MessageType.VEHICLE_ATTACHED, self.onVehicleAttached, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_DETACHED, self.onVehicleDetached, self)
end

function PowerManager:onVehicleAttached(vehicle, implement)
    if vehicle == nil or implement == nil then return end
    
    -- Initialize vehicle entry if needed
    if self.vehicleImplements[vehicle] == nil then
        self.vehicleImplements[vehicle] = {}
    end
    
    -- Add implement to vehicle's list
    table.insert(self.vehicleImplements[vehicle], implement)
    
    -- Check total power requirements first
    if not self:checkTotalPower(vehicle) then
        return -- Exit if total power check failed
    end
    
    -- If total power is okay, handle individual implement speed
    self:adjustImplementSpeed(vehicle, implement)
end

function PowerManager:onVehicleDetached(vehicle, implement)
    if vehicle == nil or implement == nil then return end
    
    -- Reset implement speed to original
    if implement.originalSpeedLimit then
        implement.speedLimit = implement.originalSpeedLimit
        implement.originalSpeedLimit = nil
    end
    
    -- Remove implement from vehicle's list
    if self.vehicleImplements[vehicle] then
        for i, imp in ipairs(self.vehicleImplements[vehicle]) do
            if imp == implement then
                table.remove(self.vehicleImplements[vehicle], i)
                break
            end
        end
    end
end

function PowerManager:checkTotalPower(vehicle)
    if not vehicle.spec_motorized or not vehicle.spec_motorized.motor then return false end
    
    -- Get vehicle power
    local vehiclePower = vehicle.spec_motorized.motor:getMaxPower()
    
    -- Calculate total power requirements
    local totalRequiredPower = 0
    local implements = self.vehicleImplements[vehicle] or {}
    
    for _, implement in ipairs(implements) do
        if implement.spec_powerConsumer then
            local config = implement.spec_powerConsumer.currentConfiguration
            if config then
                totalRequiredPower = totalRequiredPower + config.neededPower
            end
        end
    end
    
    -- Check if total power requirement exceeds vehicle power
    if totalRequiredPower > 0 then
        local powerRatio = vehiclePower / totalRequiredPower
        
        -- If vehicle is too underpowered
        if powerRatio < self.minPowerRatio then
            -- Detach the last implement
            local lastImplement = implements[#implements]
            vehicle:detachImplement(lastImplement)
            
            -- Notify player
            if g_currentMission:getIsClient() then
                local text = string.format(
                    "Total power requirement (%.0f kW) exceeds vehicle capacity! Maximum total implements need: %.0f kW", 
                    totalRequiredPower, 
                    vehiclePower / self.minPowerRatio
                )
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_ERROR, text)
            end
            return false
        else
            -- Notify player of current power usage
            if g_currentMission:getIsClient() then
                local text = string.format(
                    "Total power usage: %.0f/%.0f kW (%.0f%%)", 
                    totalRequiredPower, 
                    vehiclePower,
                    powerRatio * 100
                )
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, text)
            end
        end
    end
    
    return true
end

function PowerManager:adjustImplementSpeed(vehicle, implement)
    -- Get vehicle power
    local vehiclePower = vehicle.spec_motorized.motor:getMaxPower()
    
    -- Get implement required power
    local implementPower = 0
    if implement.spec_powerConsumer then
        local config = implement.spec_powerConsumer.currentConfiguration
        if config then
            implementPower = config.neededPower
        end
    end
    
    if implementPower > 0 and vehiclePower > 0 then
        -- Calculate power ratio
        local powerRatio = vehiclePower / implementPower
        
        -- Check if vehicle is too underpowered
        if powerRatio < self.minPowerRatio then
            -- This shouldn't happen due to total power check, but just in case
            vehicle:detachImplement(implement)
            if g_currentMission:getIsClient() then
                local text = string.format("Vehicle too underpowered! Needs at least %.0f kW", implementPower * self.minPowerRatio)
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_ERROR, text)
            end
            return
        end
        
        -- Calculate speed multiplier
        local speedMultiplier = math.max(self.minSpeedMultiplier, 
            math.min(self.maxSpeedIncrease, powerRatio))
        
        -- Store original speed if not already stored
        if not implement.originalSpeedLimit then
            implement.originalSpeedLimit = implement.speedLimit
        end
        
        -- Apply new speed limit
        if implement.speedLimit then
            implement.speedLimit = implement.originalSpeedLimit * speedMultiplier
        end
        
        -- Notify player
        if g_currentMission:getIsClient() then
            local text = string.format("Implement speed adjusted (Power ratio: %.1f, Speed: %.1f%%)", 
                powerRatio, speedMultiplier * 100)
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, text)
        end
    end
end

addModEventListener(PowerManager.new()) 