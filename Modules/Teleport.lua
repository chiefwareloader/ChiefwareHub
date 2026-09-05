-- Teleport.lua - Handles teleport functionality
local Teleport = {}
Teleport.__index = Teleport

function Teleport.new(shared, ui)
    local self = setmetatable({}, Teleport)
    self.Shared = shared
    self.UI = ui
    self.Utils = shared.Utils or require(script.Parent.Utils)
    
    -- Teleport variables
    self.TweenSpeed = 50
    self.isTeleporting = false
    self.teleportConnection = nil
    self.isPaused = false
    self.pauseDuration = 0.3
    self.pauseInterval = 3
    self.isFirstLoad = true
    self.CustomLocations = {}
    
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
    local targetCFrame = self:GetTeleportPosition(locationName)
    if targetCFrame then
        local character = game.Players.LocalPlayer.Character
        if character then
            self:SmoothTeleportWithPauses(character, targetCFrame.Position)
            print("Teleporting to: " .. locationName)
        end
    end
end

function Teleport:GetTeleportPosition(locationName)
    if self.CustomLocations[locationName] then
        return self.CustomLocations[locationName]
    end
    
    local spawnLocations = self.Utils.GetSpawnLocations()
    if spawnLocations[locationName] then
        local locationData = spawnLocations[locationName]
        if locationData.Parts and #locationData.Parts > 0 then
            local randomPart = locationData.Parts[math.random(1, #locationData.Parts)]
            return randomPart.CFrame + Vector3.new(0, 5, 0)
        end
    end
    
    return nil
end

function Teleport:SmoothTeleportWithPauses(character, targetPos)
    -- Your existing teleport logic here
    -- (Copy the SmoothTeleportWithPauses function)
end

function Teleport:StopTeleport()
    -- Your existing stop teleport logic
end

function Teleport:UpdateSpeed(newSpeed)
    -- Your existing speed update logic
end

return Teleport