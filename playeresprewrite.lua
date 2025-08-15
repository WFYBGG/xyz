pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- Create Drawing utility
    local function createDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    -- ESP storage
    local espData = {}

    -- Highlight functions
    local function addHighlight(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            if not player.Character:FindFirstChild("Player_ESP") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Player_ESP"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.FillColor = Color3.fromRGB(255, 130, 0)
                highlight.Parent = player.Character
            end
        end)
    end

    local function removeHighlight(player)
        pcall(function()
            if player.Character then
                local highlight = player.Character:FindFirstChild("Player_ESP")
                if highlight then highlight:Destroy() end
            end
        end)
    end

    -- Ensure highlight reapplies on respawn
    local function monitorCharacter(player)
        if not player then return end
        player.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then
                addHighlight(player)
            end
        end)
    end

    -- Create ESP drawings
    local function createESP(player)
        if player == LocalPlayer then return end
        if espData[player] then return end

        local healthbarWidth = 50
        local healthbarHeight = 5

        espData[player] = {
            NameText = createDrawing("Text", {Size=14, Center=true, Outline=true, Visible=false}),
            HealthText = createDrawing("Text", {Size=14, Center=true, Outline=true, Visible=false}),
            HealthBarBG = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,0,0), Visible=false}),
            HealthBarFill = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,255,0), Visible=false}),
            HealthBarWidth = healthbarWidth,
            HealthBarHeight = healthbarHeight
        }

        -- Monitor respawn for highlights
        monitorCharacter(player)
    end

    local function removeESP(player)
        if espData[player] then
            for _, obj in pairs(espData[player]) do
                pcall(function() obj:Remove() end)
            end
            espData[player] = nil
        end
    end

    -- RenderStepped: head-anchored ESP with dynamic spacing
    RunService.RenderStepped:Connect(function()
        for player, drawings in pairs(espData) do
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            -- Hide if character missing or dead
            if not char or not head or not humanoid or humanoid.Health <= 0 then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
                continue
            end

            -- Attempt safe projection to screen
            local success, pos2D, onScreen = pcall(function()
                return Camera:WorldToViewportPoint(head.Position)
            end)
            if not success or not onScreen then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
                continue
            end

            -- Dynamic spacing
            local buffer = 4
            local usernameHeight = drawings.NameText.TextBounds.Y
            local healthTextHeight = drawings.HealthText.TextBounds.Y
            local healthbarHeight = drawings.HealthBarHeight
            local healthbarWidth = drawings.HealthBarWidth
            local totalHeight = usernameHeight + buffer + healthbarHeight + buffer + healthTextHeight
            local verticalOffset = 20

            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local dist = (head.Position - Camera.CFrame.Position).Magnitude

            if Toggles.PlayerESPLabels.Value then
                -- Username + Distance (top)
                drawings.NameText.Text = string.format("[%s] [%dm]", player.Name, math.floor(dist))
                drawings.NameText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 - verticalOffset)
                drawings.NameText.Color = Color3.fromRGB(255,255,255)
                drawings.NameText.Visible = true

                -- Health bar (middle)
                drawings.HealthBarBG.Position = Vector2.new(pos2D.X - healthbarWidth/2, pos2D.Y - totalHeight/2 + usernameHeight + buffer - verticalOffset)
                drawings.HealthBarBG.Size = Vector2.new(healthbarWidth, healthbarHeight)
                drawings.HealthBarBG.Visible = true

                drawings.HealthBarFill.Position = drawings.HealthBarBG.Position
                drawings.HealthBarFill.Size = Vector2.new(healthbarWidth * math.clamp(health/maxHealth,0,1), healthbarHeight)
                drawings.HealthBarFill.Color = Color3.fromRGB(
                    math.floor(255 - 255*(health/maxHealth)),
                    math.floor(255*(health/maxHealth)),
                    0
                )
                drawings.HealthBarFill.Visible = true

                -- Health text (bottom)
                drawings.HealthText.Text = string.format("[%d/%d]", math.floor(health), math.floor(maxHealth))
                drawings.HealthText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 + usernameHeight + buffer + healthbarHeight + buffer - verticalOffset)
                drawings.HealthText.Color = Color3.fromRGB(
                    math.floor(255 - 255*(health/maxHealth)),
                    math.floor(255*(health/maxHealth)),
                    0
                )
                drawings.HealthText.Visible = true
            else
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
            end
        end
    end)

    -- Toggle highlight
    Toggles.PlayerESP:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val then addHighlight(p) else removeHighlight(p) end
        end
    end)

    -- Toggle labels/healthbar
    Toggles.PlayerESPLabels:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    -- Player join/leave
    Players.PlayerAdded:Connect(function(plr)
        createESP(plr)
        plr.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then addHighlight(plr) end
        end)
    end)
    Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
        removeHighlight(plr)
    end)

    -- Initialize for existing players
    for _, plr in ipairs(Players:GetPlayers()) do
        createESP(plr)
        if Toggles.PlayerESP.Value then addHighlight(plr) end
    end
end)
