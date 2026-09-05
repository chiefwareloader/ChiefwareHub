local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "chiefware",
    Icon = "rbxassetid://97132262118849",
    IconSize = 40,
    Author = "@v03o",
    Folder = "ChiefwareHub",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.LeftControl,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
})

-- Create tabs
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "earth",
    Locked = false,
})

local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
    Locked = false,
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "badge-plus",
    Locked = false,
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

-- Variables for settings
local TweenSpeed = 50
local isTeleporting = false
local teleportConnection = nil
local startPosition = nil
local targetPosition = nil
local startTime = nil
local duration = nil
local currentRootPart = nil
local isFirstLoad = true
local isPaused = false
local pauseDuration = 0.3
local pauseInterval = 3

-- Custom CFrame overrides for specific locations (these will override spawn locations with the same name)
local CustomLocations = {
}

-- Function to get all spawn locations from PlayerSpawns
local function GetSpawnLocations()
    local locations = {}
    local playerSpawns = game.Workspace:FindFirstChild("_WorldOrigin")
    if playerSpawns then
        playerSpawns = playerSpawns:FindFirstChild("PlayerSpawns")
        if playerSpawns then
            for _, category in ipairs(playerSpawns:GetChildren()) do
                if category:IsA("Folder") or category:IsA("Model") then
                    -- This is a category like "Pirates", "Marines", etc.
                    for _, mapGroup in ipairs(category:GetChildren()) do
                        if mapGroup:IsA("Folder") or mapGroup:IsA("Model") then
                            -- This is a map name (group inside the category)
                            local mapName = mapGroup.Name
                            
                            -- Find all parts in this map group
                            local parts = {}
                            for _, part in ipairs(mapGroup:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    table.insert(parts, part)
                                end
                            end
                            
                            if #parts > 0 then
                                locations[mapName] = {
                                    Parts = parts,
                                    Category = category.Name,
                                    Group = mapGroup
                                }
                                print("Found map: " .. mapName .. " (in " .. category.Name .. ") with " .. #parts .. " parts")
                            end
                        end
                    end
                end
            end
        else
            warn("PlayerSpawns not found in _WorldOrigin!")
        end
    else
        warn("_WorldOrigin not found in Workspace!")
    end
    return locations
end

-- Function to get all location names (spawn locations + custom locations)
local function GetAllLocationNames()
    local names = {}
    local spawnLocations = GetSpawnLocations()
    
    -- Add all spawn location names
    for name, _ in pairs(spawnLocations) do
        table.insert(names, name)
    end
    
    -- Add custom location names (if not already added)
    for name, _ in pairs(CustomLocations) do
        if not table.find(names, name) then
            table.insert(names, name)
        end
    end
    
    return names
end

-- Function to get teleport position for a location
local function GetTeleportPosition(locationName)
    -- Check if it's a custom location first (override)
    if CustomLocations[locationName] then
        print("Using CUSTOM position for: " .. locationName)
        return CustomLocations[locationName]
    end
    
    -- Check if it's a spawn location
    local spawnLocations = GetSpawnLocations()
    if spawnLocations[locationName] then
        local locationData = spawnLocations[locationName]
        if locationData.Parts and #locationData.Parts > 0 then
            -- Pick a random part from this map group
            local randomPart = locationData.Parts[math.random(1, #locationData.Parts)]
            local targetCFrame = randomPart.CFrame + Vector3.new(0, 5, 0)
            print("Using SPAWN location for: " .. locationName .. " (random part from " .. #locationData.Parts .. " parts in " .. locationData.Category .. ")")
            return targetCFrame
        end
    end
    
    return nil
end

-- Function to stop current teleport
local function StopTeleport()
    isTeleporting = false
    isPaused = false
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    if currentRootPart then
        currentRootPart.Anchored = false
        currentRootPart = nil
    end
    print("Teleport stopped!")
end

-- Function to update teleport speed mid-tween
local function UpdateTeleportSpeed(newSpeed)
    TweenSpeed = newSpeed
    if isTeleporting and currentRootPart and targetPosition and not isPaused then
        local currentPos = currentRootPart.Position
        local remainingDistance = (targetPosition - currentPos).Magnitude
        duration = math.max(remainingDistance / TweenSpeed, 0.5)
        startTime = tick()
        startPosition = currentPos
        print("Speed updated! New duration: " .. duration .. "s")
    end
end

-- Function to smoothly teleport character with pauses every 3 seconds
local function SmoothTeleportWithPauses(character, targetPos)
    if not character or not character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = character.Humanoid
    local rootPart = character.HumanoidRootPart
    
    if not rootPart then
        return
    end
    
    -- Stop any existing teleport
    StopTeleport()
    isTeleporting = true
    isPaused = false
    currentRootPart = rootPart
    
    -- Store teleport data
    startPosition = rootPart.Position
    targetPosition = targetPos
    
    -- Calculate duration based on distance and speed
    local distance = (targetPosition - startPosition).Magnitude
    duration = math.max(distance / TweenSpeed, 0.5)
    startTime = tick()
    
    print("Teleport started! Distance: " .. distance .. ", Duration: " .. duration .. "s")
    print("Will pause every " .. pauseInterval .. " seconds for " .. pauseDuration .. "s")
    
    -- Disable physics while teleporting
    rootPart.Anchored = true
    
    -- Create connection for smooth movement with pauses
    teleportConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not isTeleporting or not character or not character.Parent then
            StopTeleport()
            return
        end
        
        if not rootPart or not rootPart.Parent then
            StopTeleport()
            return
        end
        
        -- Check if we're paused
        if isPaused then
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.min(elapsed / duration, 1)
        
        -- Check if it's time to pause (every 3 seconds of movement)
        local movementTime = elapsed
        if movementTime > 0 then
            local timeSinceLastPause = movementTime % pauseInterval
            if timeSinceLastPause < 0.05 and movementTime > 0.1 then
                isPaused = true
                print("Pausing teleport at: " .. movementTime .. "s")
                
                task.spawn(function()
                    task.wait(pauseDuration)
                    if isTeleporting then
                        isPaused = false
                        startPosition = rootPart.Position
                        startTime = tick()
                        local remainingDistance = (targetPosition - startPosition).Magnitude
                        duration = math.max(remainingDistance / TweenSpeed, 0.5)
                        print("Resuming teleport! Remaining: " .. remainingDistance .. "s")
                    end
                end)
                return
            end
        end
        
        -- Linear movement (constant speed)
        local currentPos = startPosition:Lerp(targetPosition, alpha)
        rootPart.CFrame = CFrame.new(currentPos) * (rootPart.CFrame - rootPart.Position)
        
        -- Check if we reached the target
        if alpha >= 1 then
            rootPart.CFrame = CFrame.new(targetPosition) * (rootPart.CFrame - rootPart.Position)
            StopTeleport()
            print("Teleport complete!")
        end
    end)
end

-- Get all location names
local locationNames = GetAllLocationNames()

-- Print all found locations for debugging
print("Found " .. #locationNames .. " locations:")
for _, name in ipairs(locationNames) do
    print("  - " .. name)
end

-- Create dropdown with dynamic values
local Dropdown = TeleportTab:Dropdown({
    Title = "Location Teleport",
    Desc = "Teleports you to a location (pauses every 3s)",
    Values = locationNames,
    Value = locationNames[1] or "No locations found",
    Callback = function(option) 
        if isFirstLoad then
            isFirstLoad = false
            print("Dropdown initialized with: " .. option)
            return
        end
        
        print("Location selected: " .. option)
        
        local targetCFrame = GetTeleportPosition(option)
        
        if targetCFrame then
            local character = game.Players.LocalPlayer.Character
            if character then
                SmoothTeleportWithPauses(character, targetCFrame.Position)
                print("Teleporting to: " .. option)
            end
        else
            print("No valid teleport position found for: " .. option)
        end
    end
})

-- Add Stop Teleport button
TeleportTab:Button({
    Title = "Stop Teleport",
    Desc = "Stops the current teleport",
    Callback = function()
        StopTeleport()
    end
})

VisualsTab:Button({
    Title = "Island ESP",
    Desc = "Location of all the islands",
    Callback = function()
        StopTeleport()
    end
})

-- Settings Tab: Tween Speed Control
SettingsTab:Slider({
    Title = "Tween Speed",
    Desc = "Changes the speed of teleport",
    Step = 1,
    Value = {
        Min = 5,
        Max = 200,
        Default = 50,
    },
    Callback = function(value)
        UpdateTeleportSpeed(value)
        print("Tween speed set to: " .. value .. " studs/second")
    end
})



local WaterWalkToggle = MiscTab:Toggle({
    Title = "Walk on Water",
    Desc = "Allows walking on water",
    Type = "Checkbox",
    Value = false, -- default value
    Callback = function(state) 
        print("Water Walk Toggled: " .. tostring(state))
        
        -- Find the water foam part
        local worldOrigin = game.Workspace:FindFirstChild("_WorldOrigin")
        if worldOrigin then
            local waterCFrame = worldOrigin:FindFirstChild("WaterCFrame")
            if waterCFrame then
                local foam = waterCFrame:FindFirstChild("Foam;")
                if foam and foam:IsA("BasePart") then
                    -- Set CanCollide based on toggle state
                    foam.CanCollide = state
                    
                    if state then
                        print("Water walk ENABLED - Foam CanCollide = true")
                    else
                        print("Water walk DISABLED - Foam CanCollide = false")
                    end
                else
                    warn('"Foam;" not found in WaterCFrame!')
                end
            else
                warn("WaterCFrame not found in _WorldOrigin!")
            end
        else
            warn("_WorldOrigin not found in Workspace!")
        end
    end
})