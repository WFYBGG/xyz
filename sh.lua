local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    UI = Window:AddTab("UI Settings")
}

-- Main Tab
local MainGroup = Tabs.Main:AddLeftGroupbox("Movement")
MainGroup:AddToggle("SpeedhackToggle", {
    Text = "Speedhack",
    Default = false
}):AddKeyPicker("SpeedhackKeybind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.SpeedhackToggle:SetValue(value)
    end
})
MainGroup:AddSlider("SpeedhackSpeed", {
    Text = "Speed",
    Default = 100,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = true
})
MainGroup:AddToggle("FlightToggle", {
    Text = "Fly",
    Default = false
}):AddKeyPicker("FlightKeybind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.FlightToggle:SetValue(value)
    end
})
MainGroup:AddSlider("FlightSpeed", {
    Text = "Flight Speed",
    Default = 200,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = true
})
MainGroup:AddToggle("NoclipToggle", {
    Text = "Noclip",
    Default = false
}):AddKeyPicker("NoclipKeybind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.NoclipToggle:SetValue(value)
    end
})

local MainGroup2 = Tabs.Main:AddRightGroupbox("Automation")
MainGroup2:AddToggle("AutoTrinket", {
    Text = "Auto Trinket Pickup",
    Default = false
})
MainGroup2:AddToggle("AutoIngredient", {
    Text = "Auto Ingredient Pickup",
    Default = false
})
local MainGroup3 = Tabs.Main:AddRightGroupbox("Locations")
MainGroup3:AddDropdown("NPCSelection", {
    Text = "NPC selection",
    Default = "? ??, God's Eye",
    Values = {"? ??, God's Eye"},
    Multi = false
})
MainGroup3:AddSlider("Speed", {
    Text = "Speed",
    Default = 150,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = true
})
MainGroup3:AddButton("Start/Stop", function() print("Start/Stop clicked") end)

local MainGroup4 = Tabs.Main:AddLeftGroupbox("Humanoid")
MainGroup4:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false
})
MainGroup4:AddToggle("NoStun", {
    Text = "No Stun",
    Default = false
})
MainGroup4:AddToggle("NoFire", {
    Text = "No Fire",
    Default = false
})

local MainGroup5 = Tabs.Main:AddLeftGroupbox("World Mods")
MainGroup5:AddToggle("NoLava", {
    Text = "No Lava",
    Default = false
})
MainGroup5:AddToggle("NoKillBricks", {
    Text = "No Kill Bricks",
    Default = false
})

-- Visuals Tab
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualsGroup:AddToggle("PlayerESP", {
    Text = "ESP",
    Default = false
})
local VisualsGroup = Tabs.Visuals:AddRightGroupbox("World Visuals")
VisualsGroup:AddToggle("FullBright", {
    Text = "FullBright",
    Default = false
})
VisualsGroup:AddSlider("FullBrightIntensity", {
    Text = "FullBright intensity",
    Default = 256,
    Min = 0,
    Max = 256,
    Rounding = 0,
    Compact = true
})
VisualsGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false
})
VisualsGroup:AddToggle("NoShadows", {
    Text = "No Shadows",
    Default = false
})


-- UI Settings Tab
local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:LoadAutoloadConfig()

Library:Init()
