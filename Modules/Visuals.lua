-- Visuals.lua - Handles ESP and visual features
local Visuals = {}
Visuals.__index = Visuals

function Visuals.new(shared, ui)
    local self = setmetatable({}, Visuals)
    self.Shared = shared
    self.UI = ui
    self.Utils = shared.Utils or require(script.Parent.Utils)
    
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
    -- Your ESP enable logic here
    -- (Copy the ToggleIslandESP function from earlier)
end

function Visuals:DisableIslandESP()
    -- Your ESP disable logic here
end

return Visuals