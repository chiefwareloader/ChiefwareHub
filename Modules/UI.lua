-- UI.lua - Handles all UI creation
local UI = {}
UI.__index = UI

function UI.new(shared)
    local self = setmetatable({}, UI)
    self.Shared = shared
    self.Window = nil
    self.Tabs = {}
    return self
end

function UI:CreateWindow()
    local WindUI = self.Shared.WindUI
    
    self.Window = WindUI:CreateWindow({
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
                print("User clicked") 
            end,
        },
    })

     self.Tabs.Farm = self.Window:Tab({
        Title = "Farm",
        Icon = "earth",
        Locked = false,
    })
    
    -- Create tabs
    self.Tabs.Teleport = self.Window:Tab({
        Title = "Teleport",
        Icon = "earth",
        Locked = false,
    })
    
    self.Tabs.Visuals = self.Window:Tab({
        Title = "Visuals",
        Icon = "eye",
        Locked = false,
    })
    
    self.Tabs.Misc = self.Window:Tab({
        Title = "Misc",
        Icon = "badge-plus",
        Locked = false,
    })
    
    self.Tabs.Settings = self.Window:Tab({
        Title = "Settings",
        Icon = "settings",
        Locked = false,
    })
    
    print("✅ UI Created!")
    return self
end

function UI:GetTab(name)
    return self.Tabs[name]
end

return UI