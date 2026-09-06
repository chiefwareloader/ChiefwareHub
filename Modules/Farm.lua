-- Farm.lua - Handles farming features
local Farm = {}
Farm.__index = Farm

function Farm.new(shared, ui)
    local self = setmetatable({}, Farm)
    self.Shared = shared
    self.UI = ui
    
    -- Bring Mobs variables
    self.BringMobsEnabled = false
    self.bringMobsConnection = nil
    self.bringDistance = 10 -- Distance to bring mobs to player
    
    return self
end

function Farm:SetupUI()
    local farmTab = self.UI:GetTab("Farm")
    
    farmTab:Toggle({
        Title = "Bring Mobs",
        Desc = "Brings all nearby mobs to your position",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            self:ToggleBringMobs(state)
        end
    })
end

function Farm:ToggleBringMobs(enable)
    if enable == self.BringMobsEnabled then
        return
    end
    
    self.BringMobsEnabled = enable
    
    if self.bringMobsConnection then
        self.bringMobsConnection:Disconnect()
        self.bringMobsConnection = nil
    end
    
    if enable then
        self.bringMobsConnection = self.Shared.RunService.Heartbeat:Connect(function()
            if not self.BringMobsEnabled then return end
            
            local player = self.Shared.Players.LocalPlayer
            if not player or not player.Character then return end
            
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            
            local playerPos = rootPart.Position
            
            -- Get all enemy groups from Workspace.Enemies
            local enemiesFolder = game.Workspace:FindFirstChild("Enemies")
            if not enemiesFolder then return end
            
            for _, enemyGroup in ipairs(enemiesFolder:GetChildren()) do
                if enemyGroup:IsA("Model") or enemyGroup:IsA("Folder") then
                    -- Find the HumanoidRootPart in this enemy group
                    local enemyRoot = enemyGroup:FindFirstChild("HumanoidRootPart")
                    if not enemyRoot then
                        -- Try to find any BasePart if HumanoidRootPart doesn't exist
                        enemyRoot = enemyGroup:FindFirstChildWhichIsA("BasePart", true)
                    end
                    
                    if enemyRoot and enemyRoot:IsA("BasePart") then
                        -- Check if enemy is alive (has Humanoid with health > 0)
                        local humanoid = enemyGroup:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health <= 0 then
                            continue -- Skip dead enemies
                        end
                        
                        local enemyPos = enemyRoot.Position
                        local distance = (playerPos - enemyPos).Magnitude
                        
                        -- Only bring mobs within a reasonable range (e.g., 500 studs)
                        if distance < 500 and distance > 5 then
                            -- Move enemy towards player in increments
                            local direction = (playerPos - enemyPos).Unit
                            local newPos = enemyPos + (direction * 5) -- Move 5 studs per frame
                            
                            -- Keep the enemy at a minimum distance from player
                            local newDistance = (playerPos - newPos).Magnitude
                            if newDistance < self.bringDistance then
                                newPos = playerPos + (direction * self.bringDistance)
                            end
                            
                            -- Move the enemy
                            enemyRoot.CFrame = CFrame.new(newPos) * (enemyRoot.CFrame - enemyRoot.Position)
                        end
                    end
                end
            end
        end)
        print("✅ Bring Mobs ENABLED")
    else
        print("❌ Bring Mobs DISABLED")
    end
end

return Farm