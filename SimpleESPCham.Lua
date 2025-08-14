pcall(function()
    local function addESP(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Name = "RW_ESP"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.Parent = player.Character
        end)
    end

    local function removeESP(player)
        pcall(function()
            if player.Character then
                local highlight = player.Character:FindFirstChild("RW_ESP")
                if highlight then
                    highlight:Destroy()
                end
            end
        end)
    end

    Toggles.PlayerESP:OnChanged(function(value)
        pcall(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if value then
                    addESP(plr)
                else
                    removeESP(plr)
                end
            end
        end)
    end)

    Players.PlayerAdded:Connect(function(player)
        if Toggles.PlayerESP.Value then
            player.CharacterAdded:Connect(function()
                addESP(player)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)
end)
