-- Utils.lua - Shared utility functions
local Utils = {}

-- Find spawn locations
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

-- Find island groups
function Utils.FindIslandGroups()
    local islands = {}
    local excludeNames = {
        "Players", "Terrain", "_WorldOrigin", "Camera", 
        "Lighting", "Sounds", "Water", "Spawn"
    }
    
    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child:IsA("Model") then
            local name = child.Name
            local shouldExclude = false
            
            for _, exclude in ipairs(excludeNames) do
                if string.match(name, exclude) or string.match(name, "^_") then
                    shouldExclude = true
                    break
                end
            end
            
            if not shouldExclude then
                table.insert(islands, child)
            end
        end
    end
    
    return islands
end

-- Get model center
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

-- Format distance
function Utils.FormatDistance(distance)
    if distance >= 1000 then
        return string.format("%.1fkm", distance / 1000)
    else
        return string.format("%dm", math.round(distance))
    end
end

return Utils