-- ========================
--   Ratware ESP Script (Ultra-Clean + Live Color + Auto-Respawn + Loop Toggle)
-- ========================

-- Tables & Variables
local espData = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Libraries
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

-- GUI
local Window = Library:CreateWindow({
    Title = "Ratware.esp - 100% Made By ChatGPT [Insert to Hide]",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Visuals = Window:AddTab("Visual"),
    UI = Window:AddTab("UI Settings")
}

-- ========================
-- Player ESP UI
-- ========================
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP")

-- Highlight toggle with color picker
VisualsGroup:AddToggle("PlayerESP", { Text = "Highlight", Default = false })
    :AddColorPicker("PlayerESPColor", {
        Default = Color3.fromRGB(255, 130, 0),
        Title = "Highlight Color",
        Transparency = 0.5,
    })

-- Username & Distance toggle with color picker
VisualsGroup:AddToggle("PlayerESPName", { Text = "Username & Distance", Default = false })
    :AddColorPicker("PlayerESPNameColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Name & Distance Color",
    })

-- Health Bar toggle
VisualsGroup:AddToggle("PlayerESPHealthbar", { Text = "Show Health Bar", Default = false })

-- Health Text toggle
VisualsGroup:AddToggle("PlayerESPHealthText", { Text = "Show Health Text", Default = false })

-- ========================
-- ESP Logic
-- ========================
pcall(function()

    local renderConn

    local function anyEspEnabled()
        return (Toggles.PlayerESP.Value
            or Toggles.PlayerESPName.Value
            or Toggles.PlayerESPHealthbar.Value
            or Toggles.PlayerESPHealthText.Value)
    end

    local function createDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do obj[k] = v end
        return obj
    end

    local function addHighlight(player)
        if player == LocalPlayer then return end
        local char = player.Character
        if not char then return end

        local hl = char:FindFirstChild("Player_ESP")
        if not hl then
            pcall(function()
                local highlight = Instance.new("Highlight")
                highlight.Name = "Player_ESP"
                highlight.FillColor = Options.PlayerESPColor.Value
                highlight.FillTransparency = Options.PlayerESPColor.Transparency
                highlight.OutlineTransparency = 0
                highlight.Parent = char
            end)
        else
            pcall(function()
                hl.FillColor = Options.PlayerESPColor.Value
                hl.FillTransparency = Options.PlayerESPColor.Transparency
            end)
        end
    end

    local function removeHighlight(player)
        local char = player and player.Character
        if not char then return end
        local hl = char:FindFirstChild("Player_ESP")
        if hl then pcall(function() hl:Destroy() end) end
    end

    local function createESP(player)
        if player == LocalPlayer or espData[player] then return end
        espData[player] = {
            NameText = createDrawing("Text",   {Size=14, Center=true, Outline=true, Visible=false}),
            HealthText = createDrawing("Text", {Size=14, Center=true, Outline=true, Visible=false}),
            HealthBarBG = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,0,0), Visible=false}),
            HealthBarFill = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,255,0), Visible=false}),
            HealthBarWidth = 50,
            HealthBarHeight = 5
        }
    end

    local function removeESP(player)
        local pack = espData[player]
        if not pack then return end
        for _, obj in pairs(pack) do
            pcall(function()
                if obj and obj.Remove then obj:Remove() end
            end)
        end
        espData[player] = nil
    end

    local function clearAllESP()
        for player in pairs(espData) do
            removeESP(player)
            removeHighlight(player)
        end
        espData = {}
    end

    -- Solara-safe render loop (no goto/continue)
    local function onRenderStep()
        if not (Toggles.PlayerESPName.Value or Toggles.PlayerESPHealthbar.Value or Toggles.PlayerESPHealthText.Value) then
            return
        end

        for player, drawings in pairs(espData) do
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not head or not humanoid or humanoid.Health <= 0 then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
            else
                local ok, pos2D, onScreen = pcall(function()
                    return Camera:WorldToViewportPoint(head.Position)
                end)

                if not ok or not onScreen then
                    drawings.NameText.Visible = false
                    drawings.HealthBarBG.Visible = false
                    drawings.HealthBarFill.Visible = false
                    drawings.HealthText.Visible = false
                else
                    local buffer = 4
                    local usernameHeight = drawings.NameText.TextBounds.Y
                    local healthTextHeight = drawings.HealthText.TextBounds.Y
                    local totalHeight = usernameHeight + buffer + drawings.HealthBarHeight + buffer + healthTextHeight
                    local verticalOffset = 20

                    -- Get health values safely
                    local health = tonumber(humanoid.Health) or 0
                    local maxHealth = tonumber(humanoid.MaxHealth) or 100
                    
                    -- Prevent division errors or blank bars
                    if maxHealth <= 0 then
                        maxHealth = 100
                    end
                    local ratio = math.clamp(health / maxHealth, 0, 1)
                    local dist = (head.Position - Camera.CFrame.Position).Magnitude

                    local ratio = math.clamp(maxHealth > 0 and (health / maxHealth) or 0, 0, 1)
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
                        drawings.HealthBarBG.Position = Vector2.new(pos2D.X - drawings.HealthBarWidth/2, pos2D.Y - totalHeight/2 + usernameHeight + buffer - verticalOffset)
                        drawings.HealthBarBG.Size = Vector2.new(drawings.HealthBarWidth, drawings.HealthBarHeight)
                        drawings.HealthBarBG.Visible = true

                        drawings.HealthBarFill.Position = drawings.HealthBarBG.Position
                        drawings.HealthBarFill.Size = Vector2.new(drawings.HealthBarWidth * ratio, drawings.HealthBarHeight)
                        drawings.HealthBarFill.Color = Color3.fromRGB(
                            math.floor(255 - 255*ratio),
                            math.floor(255*ratio),
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
                        drawings.HealthText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 + usernameHeight + buffer + drawings.HealthBarHeight + buffer - verticalOffset)
                        drawings.HealthText.Color = Color3.fromRGB(
                            math.floor(255 - 255*ratio),
                            math.floor(255*ratio),
                            0
                        )
                        drawings.HealthText.Visible = true
                    else
                        drawings.HealthText.Visible = false
                    end
                end
            end
        end
    end

    local function startRender()
        if renderConn or not anyEspEnabled() then return end
        renderConn = RunService.RenderStepped:Connect(onRenderStep)
    end

    local function stopRender()
        if renderConn then
            renderConn:Disconnect()
            renderConn = nil
        end
    end

    local function checkAllToggles()
        if anyEspEnabled() then
            startRender()
        else
            stopRender()
            clearAllESP()
        end
    end

    Options.PlayerESPColor:OnChanged(function()
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                if char then
                    local hl = char:FindFirstChild("Player_ESP")
                    if hl then
                        hl.FillColor = Options.PlayerESPColor.Value
                        hl.FillTransparency = Options.PlayerESPColor.Transparency
                    end
                end
            end
        end)
    end)

    Toggles.PlayerESP:OnChanged(function(val)
        if val then
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function() addHighlight(p) end)
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function() removeHighlight(p) end)
            end
        end
        checkAllToggles()
    end)

    for _, toggleName in ipairs({"PlayerESPName", "PlayerESPHealthbar", "PlayerESPHealthText"}) do
        Toggles[toggleName]:OnChanged(function(val)
            for _, p in ipairs(Players:GetPlayers()) do
                local data = espData[p]
                if val then
                    if not data then
                        createESP(p)
                        data = espData[p]
                    end
                else
                    if data then
                        if toggleName == "PlayerESPName" then
                            data.NameText.Visible = false
                        elseif toggleName == "PlayerESPHealthbar" then
                            data.HealthBarBG.Visible = false
                            data.HealthBarFill.Visible = false
                        elseif toggleName == "PlayerESPHealthText" then
                            data.HealthText.Visible = false
                        end
                    end
                end
            end
            checkAllToggles()
        end)
    end

    local function monitorCharacter(player)
        player.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then
                pcall(function() addHighlight(player) end)
            end
            if (Toggles.PlayerESPName.Value or Toggles.PlayerESPHealthbar.Value or Toggles.PlayerESPHealthText.Value) then
                pcall(function()
                    if not espData[player] then createESP(player) end
                end)
            end
        end)
    end

    Players.PlayerAdded:Connect(function(plr)
        pcall(function()
            createESP(plr)
            monitorCharacter(plr)
            if Toggles.PlayerESP.Value then addHighlight(plr) end
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        pcall(function()
            removeESP(plr)
            removeHighlight(plr)
        end)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        pcall(function()
            createESP(plr)
            monitorCharacter(plr)
            if Toggles.PlayerESP.Value then addHighlight(plr) end
        end)
    end

    checkAllToggles()
end)

-- ========================
-- UI Settings
-- ========================
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
