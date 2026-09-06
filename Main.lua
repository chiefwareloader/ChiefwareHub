-- Main.lua - Chiefware Hub Loader
print("Loading Chiefware Hub...")

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

-- Load modules with detailed debugging
local Modules = {}
local moduleNames = {"Utils", "UI", "Teleport", "Visuals", "Misc", "Farm"}

for _, name in ipairs(moduleNames) do
    local url = "https://raw.githubusercontent.com/chiefwareloader/ChiefwareHub/main/Modules/" .. name .. ".lua"
    print("Attempting to load: " .. name .. " from " .. url)
    
    local success, result = pcall(function()
        local content = game:HttpGet(url)
        print("  Got content for: " .. name .. " (" .. string.len(content) .. " bytes)")
        local func = loadstring(content)
        if not func then
            error("loadstring returned nil for: " .. name)
        end
        return func()
    end)
    
    if success and result then
        Modules[name] = result
        print("✅ Loaded module: " .. name)
    else
        warn("❌ Failed to load module: " .. name)
        if not success then
            warn("   Error: " .. tostring(result))
        end
    end
end

-- Print what modules loaded
print("Loaded modules:", table.concat(moduleNames, ", "))

-- Check if UI module loaded
if not Modules.UI then
    error("UI module failed to load! Cannot initialize hub.")
    return
end

-- Initialize modules
local UI = Modules.UI.new(Shared)
local Teleport = Modules.Teleport and Modules.Teleport.new(Shared, UI)
local Visuals = Modules.Visuals and Modules.Visuals.new(Shared, UI)
local Misc = Modules.Misc and Modules.Misc.new(Shared, UI)
local Farm = Modules.Farm and Modules.Farm.new(Shared, UI)

-- Setup UI
UI:CreateWindow()

-- Setup features
if Teleport then Teleport:SetupUI() end
if Visuals then Visuals:SetupUI() end
if Misc then Misc:SetupUI() end
if Farm then Farm:SetupUI() end

print("✅ Chiefware Hub loaded successfully!")