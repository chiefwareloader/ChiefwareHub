-- Utils.lua - Shared utility functions
local Utils = {}

-- Find spawn locations from PlayerSpawns
function Utils.GetSpawnLocations()
    local locations = {}
    local playerSpawns = game.Workspace:FindFirstChild("_WorldOrigin")
    if playerSpawns then
        playerSpawns = playerSpawns:FindFirstChild("PlayerSpawns")
        if playerSpawns then
            for _, category in ipairs(playerSpawns:GetChildren()) do
                if category:IsA("Folder") or category:IsA("Model") then
                    for _, mapGroup in ipairs(category:GetChildren()) do
                        if mapGroup:IsA("Folder") or mapGroup:IsA("Model") then
                            local mapName = mapGroup.Name
                            local parts = {}
                            for _, part in ipairs(mapGroup:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    table.insert(parts, part)
                                end
                            end
                            if #parts > 0 then
                                locations[mapName] = {
                                    Parts = parts,
                                    Category = category.Name,
                                    Group = mapGroup
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return locations
end

-- Get all location names
function Utils.GetAllLocationNames(customLocations)
    local names = {}
    local spawnLocations = Utils.GetSpawnLocations()
    
    for name, _ in pairs(spawnLocations) do
        table.insert(names, name)
    end
    
    if customLocations then
        for name, _ in pairs(customLocations) do
            if not table.find(names, name) then
                table.insert(names, name)
            end
        end
    end
    
    return names
end

-- Get teleport position for a location
function Utils.GetTeleportPosition(locationName, customLocations)
    if customLocations and customLocations[locationName] then
        return customLocations[locationName]
    end
    
    local spawnLocations = Utils.GetSpawnLocations()
    if spawnLocations[locationName] then
        local locationData = spawnLocations[locationName]
        if locationData.Parts and #locationData.Parts > 0 then
            local randomPart = locationData.Parts[math.random(1, #locationData.Parts)]
            return randomPart.CFrame + Vector3.new(0, 5, 0)
        end
    end
    
    return nil
end

-- Find island in workspace
function Utils.FindIslandGroups()
    local islands = {}
    
    -- Find the Map folder in workspace
    local mapFolder = game.Workspace:FindFirstChild("Map")
    if not mapFolder then
        warn("Map folder not found in Workspace!")
        return islands
    end
    
    -- Go through each child in Map
    for _, child in ipairs(mapFolder:GetChildren()) do
        -- Only include Models (groups), not Folders or Parts
        if child:IsA("Model") then
            local name = child.Name
            -- Exclude common non-island objects
            if name ~= "Players" and 
               name ~= "Terrain" and 
               name ~= "Camera" and 
               name ~= "Lighting" and 
               name ~= "Sounds" and
               not string.match(name, "^_") and
               not string.match(name, "Spawn") and
               not string.match(name, "Water") then
                table.insert(islands, child)
                print("Found island: " .. name)
            end
        end
    end
    
    print("Found " .. #islands .. " islands in Map")
    return islands
end

-- Get model center position (above highest point)
function Utils.GetModelCenter(model)
    local totalPos = Vector3.new(0, 0, 0)
    local count = 0
    local highestY = -math.huge
    
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            totalPos = totalPos + part.Position
            count = count + 1
            if part.Position.Y > highestY then
                highestY = part.Position.Y
            end
        end
    end
    
    if count == 0 then
        return nil
    end
    
    return Vector3.new(totalPos.X / count, highestY + 15, totalPos.Z / count)
end

-- Format distance for display
function Utils.FormatDistance(distance)
    if distance >= 1000 then
        return string.format("%.1fkm", distance / 1000)
    else
        return string.format("%dm", math.round(distance))
    end
end

return Utils