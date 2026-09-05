-- Settings.lua - Configuration
local Settings = {
    Teleport = {
        TweenSpeed = 50,
        PauseDuration = 0.3,
        PauseInterval = 3,
    },
    Visuals = {
        IslandESP = {
            Enabled = false,
            MaxDistance = 5000,
            UpdateInterval = 0.05,
        }
    },
    Misc = {
        WaterWalk = false,
    },
    UI = {
        Theme = "Dark",
        WindowSize = UDim2.fromOffset(580, 460),
    }
}

return Settings