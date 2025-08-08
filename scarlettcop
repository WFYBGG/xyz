local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Scarlet Hook Rogueblox",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Misc = Window:AddTab("Misc"),
    UI = Window:AddTab("UI Settings")
}

-- Main Tab
local MainGroup = Tabs.Main:AddLeftGroupbox("Movement")
MainGroup:AddToggle("FlightToggle", {
    Text = "Flight",
    Default = false
})
MainGroup:AddSlider("FlightSpeed", {
    Text = "Flight Speed",
    Default = 200,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = true
})
MainGroup:AddToggle("AABypass", {
    Text = "AA bypass",
    Default = false
})
MainGroup:AddToggle("AutoFall", {
    Text = "Auto fall",
    Default = false
})
MainGroup:AddSlider("AutoFallSpeed", {
    Text = "Auto Fall Speed",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Compact = true
})
MainGroup:AddToggle("NoClip", {
    Text = "NoClip",
    Default = false
})
MainGroup:AddToggle("TpToGround", {
    Text = "Tp to ground",
    Default = false
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
    Default = 130,
    Min = 0,
    Max = 400,
    Rounding = 0,
    Compact = true
})
MainGroup3:AddButton("Start/Stop", function() print("Start/Stop clicked") end)

local MainGroup4 = Tabs.Main:AddLeftGroupbox("Main")
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

local MainGroup5 = Tabs.Main:AddLeftGroupbox("World")
MainGroup5:AddToggle("NoQuickSand", {
    Text = "No Quick Sand",
    Default = false
})
MainGroup5:AddToggle("NoLava", {
    Text = "No Lava",
    Default = false
})
MainGroup5:AddToggle("NoKillBricks", {
    Text = "No Kill Bricks",
    Default = false
})

-- Visuals Tab
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("World Visuals")
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
