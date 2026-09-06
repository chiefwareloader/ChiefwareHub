-- Teleport.lua - Handles teleport functionality
local Teleport = {}
Teleport.__index = Teleport

function Teleport.new(shared, ui)
    local self = setmetatable({}, Teleport)
    self.Shared = shared
    self.UI = ui
    self.Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/chiefwareloader/ChiefwareHub/main/Modules/Utils.lua"))()
    
    -- Teleport settings
    self.TweenSpeed = 50
    self.isTeleporting = false
    self.teleportConnection = nil
    self.isPaused = false
    self.pauseDuration = 0.3
    self.pauseInterval = 3
    self.isFirstLoad = true
    self.CustomLocations = {}
    
    -- Teleport state
    self.startPosition = nil
    self.targetPosition = nil
    self.startTime = nil
    self.duration = nil
    self.currentRootPart = nil
    
    return self
end

function Teleport:SetupUI()
    local teleportTab = self.UI:GetTab("Teleport")
    local settingsTab = self.UI:GetTab("Settings")
    
    -- Get all locations
    local locationNames = self.Utils.GetAllLocationNames(self.CustomLocations)
    
    -- Location dropdown
    teleportTab:Dropdown({
        Title = "Location Teleport",
        Desc = "Teleports you to a location (pauses every 3s)",
        Values = locationNames,
        Value = locationNames[1] or "No locations found",
        Callback = function(option)
            if self.isFirstLoad then
                self.isFirstLoad = false
                return
            end
            self:TeleportToLocation(option)
        end
    })
    
    -- Stop teleport button
    teleportTab:Button({
        Title = "Stop Teleport",
        Desc = "Stops the current teleport",
        Callback = function()
            self:StopTeleport()
        end
    })

    -- Sea Teleport Buttons

    teleportTab:Button({
    Title = "Teleport to First Sea",
    Desc = "Teleports you to first sea",
    Locked = false,
    Callback = function()
        -- ...
    end
})
    
    -- Speed slider
    settingsTab:Slider({
        Title = "Tween Speed",
        Desc = "Changes the speed of teleport",
        Step = 1,
        Value = {
            Min = 5,
            Max = 200,
            Default = 50,
        },
        Callback = function(value)
            self:UpdateSpeed(value)
        end
    })
end

function Teleport:TeleportToLocation(locationName)
    local targetCFrame = self.Utils.GetTeleportPosition(locationName, self.CustomLocations)
    if targetCFrame then
        local character = self.Shared.Players.LocalPlayer.Character
        if character then
            self:SmoothTeleportWithPauses(character, targetCFrame.Position)
            print("Teleporting to: " .. locationName)
        end
    else
        print("No valid teleport position found for: " .. locationName)
    end
end

function Teleport:SmoothTeleportWithPauses(character, targetPos)
    if not character or not character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = character.Humanoid
    local rootPart = character.HumanoidRootPart
    
    if not rootPart then
        return
    end
    
    self:StopTeleport()
    self.isTeleporting = true
    self.isPaused = false
    self.currentRootPart = rootPart
    
    self.startPosition = rootPart.Position
    self.targetPosition = targetPos
    
    local distance = (self.targetPosition - self.startPosition).Magnitude
    self.duration = math.max(distance / self.TweenSpeed, 0.5)
    self.startTime = tick()
    
    print("Teleport started! Distance: " .. distance .. ", Duration: " .. self.duration .. "s")
    
    rootPart.Anchored = true
    
    self.teleportConnection = self.Shared.RunService.Heartbeat:Connect(function()
        if not self.isTeleporting or not character or not character.Parent then
            self:StopTeleport()
            return
        end
        
        if not rootPart or not rootPart.Parent then
            self:StopTeleport()
            return
        end
        
        if self.isPaused then
            return
        end
        
        local elapsed = tick() - self.startTime
        local alpha = math.min(elapsed / self.duration, 1)
        
        -- Check if it's time to pause
        local movementTime = elapsed
        if movementTime > 0 then
            local timeSinceLastPause = movementTime % self.pauseInterval
            if timeSinceLastPause < 0.05 and movementTime > 0.1 then
                self.isPaused = true
                print("Pausing teleport at: " .. movementTime .. "s")
                
                task.spawn(function()
                    task.wait(self.pauseDuration)
                    if self.isTeleporting then
                        self.isPaused = false
                        self.startPosition = rootPart.Position
                        self.startTime = tick()
                        local remainingDistance = (self.targetPosition - self.startPosition).Magnitude
                        self.duration = math.max(remainingDistance / self.TweenSpeed, 0.5)
                        print("Resuming teleport!")
                    end
                end)
                return
            end
        end
        
        local currentPos = self.startPosition:Lerp(self.targetPosition, alpha)
        rootPart.CFrame = CFrame.new(currentPos) * (rootPart.CFrame - rootPart.Position)
        
        if alpha >= 1 then
            rootPart.CFrame = CFrame.new(self.targetPosition) * (rootPart.CFrame - rootPart.Position)
            self:StopTeleport()
            print("Teleport complete!")
        end
    end)
end

function Teleport:StopTeleport()
    self.isTeleporting = false
    self.isPaused = false
    if self.teleportConnection then
        self.teleportConnection:Disconnect()
        self.teleportConnection = nil
    end
    if self.currentRootPart then
        self.currentRootPart.Anchored = false
        self.currentRootPart = nil
    end
    print("Teleport stopped!")
end

function Teleport:UpdateSpeed(newSpeed)
    self.TweenSpeed = newSpeed
    if self.isTeleporting and self.currentRootPart and self.targetPosition and not self.isPaused then
        local currentPos = self.currentRootPart.Position
        local remainingDistance = (self.targetPosition - currentPos).Magnitude
        self.duration = math.max(remainingDistance / self.TweenSpeed, 0.5)
        self.startTime = tick()
        self.startPosition = currentPos
        print("Speed updated! New duration: " .. self.duration .. "s")
    end
end

return Teleport