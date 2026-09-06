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

    -- Create tabs with consistent naming
    local tabConfigs = {
        Farm = { Title = "Farm", Icon = "earth" },
        Teleport = { Title = "Teleport", Icon = "earth" },
        Visuals = { Title = "Visuals", Icon = "eye" },
        Misc = { Title = "Misc", Icon = "badge-plus" },
        Settings = { Title = "Settings", Icon = "settings" }
    }
    
    for name, config in pairs(tabConfigs) do
        self.Tabs[name] = self.Window:Tab({
            Title = config.Title,
            Icon = config.Icon,
            Locked = false,
        })
    end
    
    print("✅ UI Created!")
    return self
end

function UI:GetTab(name)
    return self.Tabs[name]
end

return UI