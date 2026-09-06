-- Misc.lua - Handles miscellaneous features
local Misc = {}
Misc.__index = Misc

function Misc.new(shared, ui)
    local self = setmetatable({}, Misc)
    self.Shared = shared
    self.UI = ui
    
    -- Initialize variables
    self.InfiniteJumpEnabled = false
    self.infiniteJumpConnection = nil
    
    return self
end

function Misc:SetupUI()
    local miscTab = self.UI:GetTab("Misc")
    
    miscTab:Toggle({
        Title = "Walk on Water",
        Desc = "Allows walking on water",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            self:ToggleWaterWalk(state)
        end
    })

    miscTab:Toggle({
        Title = "Infinite Jump",
        Desc = "Allows you to jump repeatedly in the air",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            self:ToggleInfiniteJump(state)
        end
    })
end

function Misc:ToggleWaterWalk(state)
    print("Water Walk Toggled: " .. tostring(state))
    
    local worldOrigin = game.Workspace:FindFirstChild("_WorldOrigin")
    if worldOrigin then
        local waterCFrame = worldOrigin:FindFirstChild("WaterCFrame")
        if waterCFrame then
            local foam = waterCFrame:FindFirstChild("Foam;")
            if foam and foam:IsA("BasePart") then
                foam.CanCollide = state
                
                if state then
                    print("✅ Water walk ENABLED")
                else
                    print("❌ Water walk DISABLED")
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

function Misc:ToggleInfiniteJump(enable)
    -- If same state, just return
    if enable == self.InfiniteJumpEnabled then
        return
    end
    
    -- Update state FIRST
    self.InfiniteJumpEnabled = enable
    
    -- Disconnect existing connection if any
    if self.infiniteJumpConnection then
        self.infiniteJumpConnection:Disconnect()
        self.infiniteJumpConnection = nil
    end
    
    -- If enabling, create new connection
    if enable then
        self.infiniteJumpConnection = self.Shared.UserInputService.JumpRequest:Connect(function()
            -- Only jump if enabled
            if self.InfiniteJumpEnabled then
                local player = self.Shared.Players.LocalPlayer
                if player and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
        print("✅ Infinite Jump ENABLED")
    else
        print("❌ Infinite Jump DISABLED")
    end
end

return Misc