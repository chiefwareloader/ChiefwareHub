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
    
    if enable then
        self:EnableIslandESP()
    else
        self:DisableIslandESP()
    end
end

function Visuals:EnableIslandESP()
    self.isIslandESPEnabled = true
    
    local islands = self.Utils.FindIslandGroups()
    print("Found " .. #islands .. " island groups for ESP")
    
    -- CLEAR existing ESP objects first
    for island, data in pairs(self.islandESPObjects) do
        if data.Billboard and data.Billboard.Parent then
            data.Billboard:Destroy()
        end
    end
    self.islandESPObjects = {}  -- Clear the table
    
    -- Now create ESP for ALL islands
    for _, island in ipairs(islands) do
        -- Remove any old ESP first
        local existingESP = island:FindFirstChild("IslandESP_" .. island.Name)
        if existingESP then
            existingESP:Destroy()
        end
        
        local espData = self:CreateIslandESP(island)
        if espData then
            self.islandESPObjects[island] = espData
            print("ESP created for: " .. island.Name)
        end
    end
    
    if self.islandESPConnections.UpdateConnection then
        self.islandESPConnections.UpdateConnection:Disconnect()
    end
    
    self.islandESPConnections.UpdateConnection = self.Shared.RunService.Heartbeat:Connect(function()
        self:UpdateDistanceLabels()
    end)
    
    print("✅ Island ESP ENABLED for " .. #self.islandESPObjects .. " islands")
end

function Visuals:DisableIslandESP()
    self.isIslandESPEnabled = false
    
    for island, data in pairs(self.islandESPObjects) do
        if data.Billboard and data.Billboard.Parent then
            data.Billboard:Destroy()
        end
    end
    self.islandESPObjects = {}
    
    if self.islandESPConnections.UpdateConnection then
        self.islandESPConnections.UpdateConnection:Disconnect()
        self.islandESPConnections.UpdateConnection = nil
    end
    
    print("❌ Island ESP DISABLED")
end

function Visuals:CreateIslandESP(island)
    local centerPos = self.Utils.GetModelCenter(island)
    if not centerPos then
        return nil
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "IslandESP_" .. island.Name
    billboard.Size = UDim2.new(0, 250, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 30, 0)
    billboard.Adornee = island
    billboard.MaxDistance = 5000
    billboard.AlwaysOnTop = true
    billboard.Enabled = true  -- ADD THIS: Ensure it's enabled
    billboard.ClipsDescendants = false  -- ADD THIS: Prevents clipping
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
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 40, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 30))
    })
    gradient.Parent = frame
    
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowFrame"
    glowFrame.Size = UDim2.new(1.04, 0, 1.08, 0)
    glowFrame.Position = UDim2.new(-0.02, 0, -0.04, 0)
    glowFrame.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    glowFrame.BackgroundTransparency = 0.6
    glowFrame.BorderSizePixel = 0
    glowFrame.Parent = frame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 14)
    glowCorner.Parent = glowFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = island.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 18
    nameLabel.TextFont = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    nameLabel.TextScaled = false  -- ADD THIS: Prevents auto-scaling issues
    nameLabel.Parent = frame
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    distanceLabel.TextSize = 16
    distanceLabel.TextFont = Enum.Font.GothamMedium
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.TextYAlignment = Enum.TextYAlignment.Top
    distanceLabel.TextScaled = false  -- ADD THIS
    distanceLabel.Parent = frame
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 10, 0, 10)
    indicator.Position = UDim2.new(1, -20, 0.5, -5)
    indicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    indicator.BackgroundTransparency = 0.3
    indicator.BorderSizePixel = 0
    indicator.Parent = frame
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    
    -- ADD THIS: Force a render update
    task.wait(0.1)
    billboard.Enabled = true
    
    self.Shared.TweenService:Create(
        indicator,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.7}
    ):Play()
    
    return {
        Billboard = billboard,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
        Indicator = indicator,
        Frame = frame,
        GlowFrame = glowFrame
    }
end

function Visuals:UpdateDistanceLabels()
    if not self.isIslandESPEnabled then
        return
    end
    
    local player = self.Shared.Players.LocalPlayer
    if not player or not player.Character then
        return
    end
    
    local characterPos = player.Character.PrimaryPart and player.Character.PrimaryPart.Position or player.Character.HumanoidRootPart.Position
    
    for island, data in pairs(self.islandESPObjects) do
        if data.Billboard and data.Billboard.Adornee then
            local centerPos = self.Utils.GetModelCenter(island)
            if centerPos then
                local distance = (centerPos - characterPos).Magnitude
                local distanceText = self.Utils.FormatDistance(distance)
                
                if data.DistanceLabel then
                    data.DistanceLabel.Text = "📍 " .. distanceText
                end
                
                if data.Frame then
                    if distance < 500 then
                        data.Frame.BorderColor3 = Color3.fromRGB(0, 255, 100)
                        data.GlowFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                    elseif distance < 1500 then
                        data.Frame.BorderColor3 = Color3.fromRGB(255, 200, 50)
                        data.GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
                    else
                        data.Frame.BorderColor3 = Color3.fromRGB(100, 150, 255)
                        data.GlowFrame.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                    end
                end
            end
        end
    end
end

return Visuals