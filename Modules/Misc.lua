-- Misc.lua - Handles miscellaneous features
local Misc = {}
Misc.__index = Misc

function Misc.new(shared, ui)
    local self = setmetatable({}, Misc)
    self.Shared = shared
    self.UI = ui
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

return Misc