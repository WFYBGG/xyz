--GUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe ESP TEST - 100% Made By ChatGPT [Press 'Insert' To Hide]",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})
local Tabs = {
    Visuals = Window:AddTab("Visual"),
    UI = Window:AddTab("UI Settings")
}
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualsGroup:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--Player ESP Module
pcall(function()
    local function addESP(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Name = "Rogueblox Player ESP"
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
