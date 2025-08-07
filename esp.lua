-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Globals
local LocalPlayer = Players.LocalPlayer
local espObjects = {}

-- Utility: Safe wait for character model
local function getCharacterModel(player)
    local model = nil
    pcall(function()
        local container = Workspace:FindFirstChild("Living") or Workspace
        model = container:FindFirstChild(player.Name)
    end)
    return model
end

-- Cleanup ESP safely
local function cleanupESP(player)
    local data = espObjects[player]
    if data then
        pcall(function() data.box:Remove() end)
        pcall(function() data.text:Remove() end)
        espObjects[player] = nil
    end
end

-- Create ESP for a single player
local function createESP(player)
    if player == LocalPlayer then return end

    local success, _ = pcall(function()
        -- Initial character reference
        local model = getCharacterModel(player)
        if not model then return end

        local humanoid = model:FindFirstChild("Humanoid")
        local rootPart = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end

        -- Drawing objects
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

        espObjects[player] = {
            box = box,
            text = text,
            humanoid = humanoid,
            rootPart = rootPart
        }

        -- Respawn handler to update Humanoid/RootPart
        player.CharacterAdded:Connect(function()
            task.wait(1)
            local newModel = getCharacterModel(player)
            if newModel then
                local newHumanoid = newModel:FindFirstChild("Humanoid")
                local newRootPart = newModel:FindFirstChild("HumanoidRootPart")
                if newHumanoid and newRootPart then
                    local data = espObjects[player]
                    if data then
                        pcall(function()
                            data.humanoid = newHumanoid
                            data.rootPart = newRootPart
                        end)
                    end
                end
            end
        end)
    end)
end

-- Update ESP per frame
local function updateESP()
    local success, _ = pcall(function()
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            for _, data in pairs(espObjects) do
                data.box.Visible = false
                data.text.Visible = false
            end
            return
        end

        for player, data in pairs(espObjects) do
            pcall(function()
                if player and player.Parent and data.humanoid and data.humanoid.Parent and data.rootPart and data.rootPart.Parent then
                    local camera = Workspace.CurrentCamera
                    local worldPoint = data.rootPart.Position
                    local screenPos, onScreen = camera:WorldToViewportPoint(worldPoint)
                    local distance = (localRoot.Position - worldPoint).Magnitude

                    if onScreen then
                        local size = data.rootPart.Size * 1.5
                        local topLeft = camera:WorldToViewportPoint(worldPoint - size / 2)
                        local bottomRight = camera:WorldToViewportPoint(worldPoint + size / 2)
                        local boxSize = Vector2.new(bottomRight.X - topLeft.X, bottomRight.Y - topLeft.Y)

                        data.box.Size = boxSize
                        data.box.Position = Vector2.new(topLeft.X, topLeft.Y)
                        data.box.Visible = true

                        local hp = data.humanoid.Health
                        local max = data.humanoid.MaxHealth
                        data.text.Text = string.format('"%s" | Distance: %.1f | Health: %d/%d', player.Name, distance, hp, max)
                        data.text.Position = Vector2.new(topLeft.X + boxSize.X / 2, topLeft.Y - 50)
                        data.text.Visible = true
                    else
                        data.box.Visible = false
                        data.text.Visible = false
                    end
                else
                    cleanupESP(player)
                end
            end)
        end
    end)

    if not success then
        warn("ESP update failed.")
    end
end

-- Main ESP setup
local function setupESP()
    local ok, err = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            createESP(player)
        end

        Players.PlayerAdded:Connect(function(player)
            createESP(player)
        end)

        Players.PlayerRemoving:Connect(function(player)
            cleanupESP(player)
        end)

        LocalPlayer.AncestryChanged:Connect(function(_, parent)
            if not parent then
                for player in pairs(espObjects) do
                    cleanupESP(player)
                end
            end
        end)

        RunService.RenderStepped:Connect(updateESP)
    end)

    if not ok then
        warn("ESP setup failed: " .. tostring(err))
    end
end

setupESP()

