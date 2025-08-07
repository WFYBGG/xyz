-- GUI Control Variables
local showName = true
local showDistance = true
local showHealth = true
local showBox = true
local espDistance = 20000

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESPSettingsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 220)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = ScreenGui

local function createToggle(name, yPos, stateGetter, stateSetter)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, yPos)
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Text = name .. ": " .. (stateGetter() and "On" or "Off")
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        stateSetter(not stateGetter())
        button.Text = name .. ": " .. (stateGetter() and "On" or "Off")
    end)
end

-- Toggle buttons
createToggle("Show Name", 5, function() return showName end, function(v) showName = v end)
createToggle("Show Distance", 40, function() return showDistance end, function(v) showDistance = v end)
createToggle("Show Health", 75, function() return showHealth end, function(v) showHealth = v end)
createToggle("Show Box", 110, function() return showBox end, function(v) showBox = v end)

-- Distance slider label
local distanceLabel = Instance.new("TextLabel")
distanceLabel.Size = UDim2.new(1, -10, 0, 30)
distanceLabel.Position = UDim2.new(0, 5, 0, 145)
distanceLabel.BackgroundTransparency = 1
distanceLabel.TextColor3 = Color3.new(1, 1, 1)
distanceLabel.TextScaled = true
distanceLabel.Text = "ESP Distance: " .. tostring(espDistance)
distanceLabel.Parent = frame

-- Distance slider (uses TextBox for simplicity)
local distanceBox = Instance.new("TextBox")
distanceBox.Size = UDim2.new(1, -10, 0, 30)
distanceBox.Position = UDim2.new(0, 5, 0, 180)
distanceBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
distanceBox.TextColor3 = Color3.new(1, 1, 1)
distanceBox.TextScaled = true
distanceBox.Text = tostring(espDistance)
distanceBox.ClearTextOnFocus = false
distanceBox.Parent = frame

distanceBox.FocusLost:Connect(function()
    local val = tonumber(distanceBox.Text)
    if val and val >= 0 and val <= 20000 then
        espDistance = val
        distanceLabel.Text = "ESP Distance: " .. tostring(espDistance)
    else
        distanceBox.Text = tostring(espDistance)
    end
end)

-- Create ESP for a player
local function createESP(player)
    local success, result = pcall(function()
        if player == LocalPlayer or not Workspace:FindFirstChild("Living") then
            return false
        end

        local playerModel = Workspace.Living:FindFirstChild(player.Name)
        if not playerModel or not playerModel:FindFirstChild("Humanoid") or not playerModel:FindFirstChild("HumanoidRootPart") then
            return false
        end

        local humanoid = playerModel.Humanoid
        local rootPart = playerModel.HumanoidRootPart

        -- Create Drawing objects
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 1
        box.Filled = false

        local text = Drawing.new("Text")
        text.Visible = false
        text.Size = 16
        text.Color = Color3.fromRGB(255, 255, 255)
        text.Center = true
        text.Outline = true

        espObjects[player] = {box = box, text = text, humanoid = humanoid, rootPart = rootPart}

        return true
    end)
    if not success then
        warn("Failed to create ESP for " .. tostring(player.Name) .. ": " .. tostring(result))
    end
    return success and result
end

-- Update ESP
local function updateESP()
    local success, result = pcall(function()
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            for _, data in pairs(espObjects) do
                data.box.Visible = false
                data.text.Visible = false
            end
            return false
        end

        for player, data in pairs(espObjects) do
            local success, _ = pcall(function()
                if player and player.Parent and data.humanoid and data.humanoid.Parent and data.rootPart and data.rootPart.Parent then
                    local humanoid = data.humanoid
                    local rootPart = data.rootPart

                    -- Calculate screen position and distance
                    local camera = Workspace.CurrentCamera
                    local worldPoint = rootPart.Position
                    local vector, onScreen = camera:WorldToViewportPoint(worldPoint)
                    local distance = (localRoot.Position - worldPoint).Magnitude

                    if onScreen and distance <= espDistance then
                        -- Calculate bounding box for HumanoidRootPart
                        local size = rootPart.Size * 1.5
                        local topLeft = camera:WorldToViewportPoint(worldPoint - size / 2)
                        local bottomRight = camera:WorldToViewportPoint(worldPoint + size / 2)
                    
                        -- Update box
                        local boxSize = Vector2.new(bottomRight.X - topLeft.X, bottomRight.Y - topLeft.Y)
                        data.box.Size = boxSize
                        data.box.Position = Vector2.new(topLeft.X, topLeft.Y)
                        data.box.Visible = showBox
                    
                        -- Update text based on toggles
                        local parts = {}
                        if showName then table.insert(parts, '"' .. player.Name .. '"') end
                        if showDistance then table.insert(parts, string.format("Distance: %.1f", distance)) end
                        if showHealth then table.insert(parts, string.format("Health: %d/%d", humanoid.Health, humanoid.MaxHealth)) end
                    
                        data.text.Text = table.concat(parts, " | ")
                        data.text.Position = Vector2.new(topLeft.X + boxSize.X / 2, topLeft.Y - 50)
                        data.text.Visible = (#parts > 0)
                    else
                        data.box.Visible = false
                        data.text.Visible = false
                    end
                else
                    -- Clean up if player or model is gone
                    data.box:Remove()
                    data.text:Remove()
                    espObjects[player] = nil
                end
            end)
            if not success then
                warn("Failed to update ESP for " .. tostring(player.Name))
                if data.box and data.text then
                    data.box:Remove()
                    data.text:Remove()
                    espObjects[player] = nil
                end
            end
        end
        return true
    end)
    if not success then
        warn("ESP update failed: " .. tostring(result))
    end
    return success and result
end

-- Cleanup function
local function cleanupESP()
    local success, result = pcall(function()
        for _, data in pairs(espObjects) do
            local success, _ = pcall(function()
                data.box:Remove()
                data.text:Remove()
                return true
            end)
            if not success then
                warn("Failed to clean up ESP object")
            end
        end
        espObjects = {}
        return true
    end)
    if not success then
        warn("ESP cleanup failed: " .. tostring(result))
    end
end

-- Main setup
local success, result = pcall(function()
    -- Initialize ESP for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end

    -- Handle player added
    Players.PlayerAdded:Connect(function(player)
        createESP(player)
    end)

    -- Handle player removed
    Players.PlayerRemoving:Connect(function(player)
        local success, _ = pcall(function()
            if espObjects[player] then
                espObjects[player].box:Remove()
                espObjects[player].text:Remove()
                espObjects[player] = nil
            end
            return true
        end)
        if not success then
            warn("Failed to clean up ESP for " .. tostring(player.Name))
        end
    end)

    -- Cleanup when local player leaves
    LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupESP()
        end
    end)

    -- Update ESP every frame
    RunService.RenderStepped:Connect(updateESP)

    return true
end)

if not success then
    warn("ESP setup failed: " .. tostring(result))
end
