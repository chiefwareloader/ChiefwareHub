-- Main.lua - Chiefware Hub Loader
print("Loading chiefware...")

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Shared dependencies
local Shared = {
    WindUI = WindUI,
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
}

-- Load modules
local Modules = {}
local moduleNames = {"Utils", "UI", "Teleport", "Visuals", "Misc"}

for _, name in ipairs(moduleNames) do
    local url = "https://raw.githubusercontent.com/chiefwareloader/ChiefwareHub/main/Modules/" .. name .. ".lua"
    local success, module = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and module then
        Modules[name] = module
        print("✅ Loaded module: " .. name)
    else
        warn("❌ Failed to load module: " .. name)
    end
end

-- Initialize modules
local UI = Modules.UI.new(Shared)
local Teleport = Modules.Teleport.new(Shared, UI)
local Visuals = Modules.Visuals.new(Shared, UI)
local Misc = Modules.Misc.new(Shared, UI)

-- Setup UI
UI:CreateWindow()

-- Setup features
Teleport:SetupUI()
Visuals:SetupUI()
Misc:SetupUI()

print("✅ chiefware loaded successfully!")