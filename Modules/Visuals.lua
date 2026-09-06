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

function Visuals:EnableIslandESP()
    -- Clear any existing ESP instances first
    self:ClearESP()
    
    local islands = self.Utils.FindIslandGroups()
    print("Found " .. #islands .. " island groups for ESP")
    
    -- If no islands found in Map, fallback search in Workspace
    if #islands == 0 then
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
    
    -- Create ESP for ALL islands synchronously (NO task.wait inside loop)
    for _, island in ipairs(islands) do
        if not self.isIslandESPEnabled then break end -- Stop if toggled off mid-execution
        
        local espData = self:CreateIslandESP(island)
        if espData then
            self.islandESPObjects[island] = espData
        end
    end
    
    -- Heartbeat loop for distance updates
    if self.islandESPConnections.UpdateConnection then
        self.islandESPConnections.UpdateConnection:Disconnect()
    end
    
    self.islandESPConnections.UpdateConnection = self.Shared.RunService.Heartbeat:Connect(function()
        self:UpdateDistanceLabels()
    end)
    
    print("✅ Island ESP ENABLED for " .. tostring(self:GetTableSize(self.islandESPObjects)) .. " islands")
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
        if child:IsA("BillboardGui") and string.match(child.Name, "^IslandESP_") then
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

function Visuals:CreateIslandESP(island)
    local targetPart = island:IsA("BasePart") and island or island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then
        return nil
    end
    
    -- Remove old Billboard if present
    local existing = island:FindFirstChild("IslandESP_" .. island.Name)
    if existing then existing:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "IslandESP_" .. island.Name
    billboard.Size = UDim2.new(0, 250, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 30, 0)
    billboard.Adornee = targetPart
    billboard.MaxDistance = 100000 -- High distance cap to prevent pop-in hiding
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    billboard.ClipsDescendants = false
    billboard.Parent = island
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(100, 150, 255)
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = island.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.TextFont = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 10, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    distanceLabel.TextSize = 14
    distanceLabel.TextFont = Enum.Font.GothamMedium
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Parent = frame
    
    return {
        Billboard = billboard,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
        Frame = frame
    }
end

function Visuals:UpdateDistanceLabels()
    if not self.isIslandESPEnabled then return end
    
    local player = self.Shared.Players.LocalPlayer
    if not player or not player.Character then return end
    
    local charPart = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
    if not charPart then return end
    
    local characterPos = charPart.Position
    
    for island, data in pairs(self.islandESPObjects) do
        if data.Billboard and data.Billboard.Adornee then
            local targetPos = data.Billboard.Adornee.Position
            local distance = (targetPos - characterPos).Magnitude
            
            if data.DistanceLabel then
                data.DistanceLabel.Text = "📍 " .. self.Utils.FormatDistance(distance)
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