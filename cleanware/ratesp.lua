--GUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.esp - 100% Made By ChatGPT [Press 'Insert' To Hide]",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})
local Tabs = {
    Visuals = Window:AddTab("Visual"),
    UI = Window:AddTab("UI Settings")
}
VisualsGroup:AddLabel('Name/Distance Color'):AddColorPicker('PlayerESPNameColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Name & Distance',
    Callback = function(Value)
        -- Apply text color immediately
        for _, data in pairs(espData) do
            if data.NameText then
                data.NameText.Color = Value
            end
        end
    end
})
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualsGroup:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false
})
VisualsGroup:AddLabel('Highlight Color'):AddColorPicker('PlayerESPColor', {
    Default = Color3.fromRGB(255, 130, 0),
    Title = 'Player Highlight',
    Callback = function(Value)
        -- Apply highlight color immediately
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Player_ESP") then
                p.Character.Player_ESP.FillColor = Value
            end
        end
    end
})
VisualsGroup:AddToggle("PlayerESPName", {
    Text = "Username & Distance",
    Default = false
})
VisualsGroup:AddLabel('Name/Distance Color'):AddColorPicker('PlayerESPNameColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Name & Distance',
    Callback = function(Value)
        -- Apply text color immediately
        for _, data in pairs(espData) do
            if data.NameText then
                data.NameText.Color = Value
            end
        end
    end
})
VisualsGroup:AddToggle("PlayerESPHealthbar", {
    Text = "Show Health Bar",
    Default = false
})
VisualsGroup:AddToggle("PlayerESPHealthText", {
    Text = "Show Health Text",
    Default = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--Player ESP Module
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local function createDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local espData = {}

    local function addHighlight(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            if not player.Character:FindFirstChild("Player_ESP") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Player_ESP"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.FillColor = Options.PlayerESPColor.Value
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

    local function monitorCharacter(player)
        if not player then return end
        player.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then
                addHighlight(player)
            end
        end)
    end

    local function createESP(player)
        if player == LocalPlayer or espData[player] then return end

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

    RunService.RenderStepped:Connect(function()
        for player, drawings in pairs(espData) do
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not head or not humanoid or humanoid.Health <= 0 then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
                continue
            end

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

            -- Name + Distance
            if Toggles.PlayerESPName.Value then
                drawings.NameText.Text = string.format("[%s] [%dm]", player.Name, math.floor(dist))
                drawings.NameText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 - verticalOffset)
                drawings.NameText.Color = Options.PlayerESPNameColor.Value
                drawings.NameText.Visible = true
            else
                drawings.NameText.Visible = false
            end

            -- Health bar
            if Toggles.PlayerESPHealthbar.Value then
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
            else
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
            end

            -- Health text
            if Toggles.PlayerESPHealthText.Value then
                drawings.HealthText.Text = string.format("[%d/%d]", math.floor(health), math.floor(maxHealth))
                drawings.HealthText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 + usernameHeight + buffer + healthbarHeight + buffer - verticalOffset)
                drawings.HealthText.Color = Color3.fromRGB(
                    math.floor(255 - 255*(health/maxHealth)),
                    math.floor(255*(health/maxHealth)),
                    0
                )
                drawings.HealthText.Visible = true
            else
                drawings.HealthText.Visible = false
            end
        end
    end)

    -- Toggles
    Toggles.PlayerESP:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val then addHighlight(p) else removeHighlight(p) end
        end
    end)

    Toggles.PlayerESPName:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    Toggles.PlayerESPHealthbar:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    Toggles.PlayerESPHealthText:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

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

    for _, plr in ipairs(Players:GetPlayers()) do
        createESP(plr)
        if Toggles.PlayerESP.Value then addHighlight(plr) end
    end
end)

-- UI Settings Tab
local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "Insert",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Ratware")
SaveManager:SetFolder("Ratware/Rogueblox")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:LoadAutoloadConfig()
