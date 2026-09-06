-- Visuals.lua - Handles ESP and visual features
local Visuals = {}
Visuals.__index = Visuals

function Visuals.new(shared, ui)
    local self = setmetatable({}, Visuals)
    self.Shared = shared
    self.UI = ui
    self.Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/chiefwareloader/ChiefwareHub/main/Modules/Utils.lua"))()
    
    self.isIslandESPEnabled = false
    self.islandESPObjects = {}
    self.islandESPConnections = {}
    self.updateCooldown = 0
    
    return self
end

function Visuals:SetupUI()
    local visualsTab = self.UI:GetTab("Visuals")
    if not visualsTab then return end
    
    visualsTab:Toggle({
        Title = "Island ESP",
        Desc = "Shows location of all islands with distance",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            self:ToggleIslandESP(state)
        end
    })
end

function Visuals:ToggleIslandESP(enable)
    if enable == self.isIslandESPEnabled then
        return
    end
    
    self.isIslandESPEnabled = enable
    
    if enable then
        self:EnableIslandESP()
    else
        self:DisableIslandESP()
    end
end

-- Get all island groups from _WorldOrigin.PlayerSpawns
function Visuals:GetAllIslands()
    local islands = {}
    local worldOrigin = game.Workspace:FindFirstChild("_WorldOrigin")
    if not worldOrigin then
        warn("_WorldOrigin not found in Workspace!")
        return islands
    end
    
    local playerSpawns = worldOrigin:FindFirstChild("PlayerSpawns")
    if not playerSpawns then
        warn("PlayerSpawns not found inside _WorldOrigin!")
        return islands
    end
    
    local pirates = playerSpawns:FindFirstChild("Pirates")
    if not pirates then
        warn("Pirates not found inside PlayerSpawns!")
        return islands
    end
    
    for _, islandGroup in ipairs(pirates:GetChildren()) do
        if islandGroup:IsA("Model") or islandGroup:IsA("Folder") or islandGroup:IsA("BasePart") then
            table.insert(islands, islandGroup)
        end
    end
    
    return islands
end

-- Find one valid BasePart inside the island group to anchor the ESP
function Visuals:GetIslandPart(islandGroup)
    if islandGroup:IsA("BasePart") then
        return islandGroup
    end
    
    return islandGroup:FindFirstChildWhichIsA("BasePart", true)
end

-- Create ESP for an island group
function Visuals:CreateIslandESP(islandGroup)
    local targetPart = self:GetIslandPart(islandGroup)
    if not targetPart then
        return nil
    end

    -- Clear existing ESP on this group if re-enabling
    local old = islandGroup:FindFirstChild("ESP_" .. islandGroup.Name)
    if old then old:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. islandGroup.Name
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 30, 0)
    billboard.Adornee = targetPart
    billboard.MaxDistance = math.huge
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    billboard.Parent = islandGroup
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(100, 200, 255)
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = islandGroup.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = frame
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Calculating..."
    distLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    distLabel.TextSize = 13
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.Parent = frame
    
    return {
        Billboard = billboard,
        Frame = frame,
        NameLabel = nameLabel,
        DistLabel = distLabel,
        TargetPart = targetPart
    }
end

function Visuals:EnableIslandESP()
    -- Clear any existing ESP instances first
    self:ClearESP()
    
    local islands = self:GetAllIslands()
    print("Found " .. #islands .. " island groups for ESP")
    
    if #islands == 0 then
        warn("No islands found in PlayerSpawns! Falling back to workspace search...")
        -- Fallback: search in Workspace
        for _, child in ipairs(game.Workspace:GetChildren()) do
            if child:IsA("Model") then
                local name = child.Name
                if name ~= "Players" and 
                   name ~= "Terrain" and 
                   name ~= "Camera" and 
                   name ~= "Lighting" and
                   not string.match(name, "^_") then
                    table.insert(islands, child)
                end
            end
        end
    end
    
    -- Create ESP for ALL islands
    local created = 0
    for _, islandGroup in ipairs(islands) do
        if not self.isIslandESPEnabled then break end
        
        local espData = self:CreateIslandESP(islandGroup)
        if espData then
            self.islandESPObjects[islandGroup] = espData
            created = created + 1
        end
    end
    
    -- Update distances once immediately
    self:UpdateDistanceLabels()
    
    -- Heartbeat loop for distance updates
    if self.islandESPConnections.UpdateConnection then
        self.islandESPConnections.UpdateConnection:Disconnect()
    end
    
    self.islandESPConnections.UpdateConnection = self.Shared.RunService.Heartbeat:Connect(function(dt)
        if not self.isIslandESPEnabled then return end
        self.updateCooldown = self.updateCooldown + dt
        if self.updateCooldown >= 0.1 then
            self.updateCooldown = 0
            self:UpdateDistanceLabels()
        end
    end)
    
    print("✅ Island ESP ENABLED for " .. tostring(created) .. " islands")
end

function Visuals:ClearESP()
    for island, data in pairs(self.islandESPObjects) do
        if data and data.Billboard then
            data.Billboard:Destroy()
        end
    end
    self.islandESPObjects = {}
    
    -- Cleanup orphaned billboards
    for _, child in ipairs(game.Workspace:GetDescendants()) do
        if child:IsA("BillboardGui") and string.match(child.Name, "^ESP_") then
            child:Destroy()
        end
    end
end

function Visuals:DisableIslandESP()
    self.isIslandESPEnabled = false
    
    self:ClearESP()
    
    if self.islandESPConnections.UpdateConnection then
        self.islandESPConnections.UpdateConnection:Disconnect()
        self.islandESPConnections.UpdateConnection = nil
    end
    
    print("❌ Island ESP DISABLED")
end

function Visuals:UpdateDistanceLabels()
    if not self.isIslandESPEnabled then return end
    
    local player = self.Shared.Players.LocalPlayer
    if not player or not player.Character then return end
    
    local charPart = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
    if not charPart then return end
    
    local characterPos = charPart.Position
    
    for islandGroup, data in pairs(self.islandESPObjects) do
        if data and data.DistLabel and data.TargetPart and data.TargetPart.Parent then
            local dist = (data.TargetPart.Position - characterPos).Magnitude
            
            -- Format distance
            local text = dist >= 1000 and string.format("%.1f km", dist / 1000) or math.floor(dist) .. " m"
            data.DistLabel.Text = text
            
            -- Color code based on distance
            if data.Frame then
                if dist < 500 then
                    data.Frame.BorderColor3 = Color3.fromRGB(0, 255, 100)
                elseif dist < 1500 then
                    data.Frame.BorderColor3 = Color3.fromRGB(255, 200, 50)
                elseif dist < 5000 then
                    data.Frame.BorderColor3 = Color3.fromRGB(255, 150, 50)
                else
                    data.Frame.BorderColor3 = Color3.fromRGB(100, 150, 255)
                end
            end
        end
    end
end

function Visuals:GetTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

return Visuals