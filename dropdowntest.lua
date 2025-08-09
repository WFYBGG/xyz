local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe - 100% By ChatGPT [Press 'Insert' to hide GUI]",
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

--local MainGroup2 = Tabs.Main:AddRightGroupbox("Automation")
--MainGroup2:AddToggle("AutoTrinket", {
--    Text = "Auto Trinket Pickup",
--    Default = false
--})
--MainGroup2:AddToggle("AutoIngredient", {
--    Text = "Auto Ingredient Pickup",
--    Default = false
--})
local MainGroup3 = Tabs.Main:AddRightGroupbox("Universal Tween")

-- Initialize lists for Areas and NPCs
local areaList = {}
local npcList = {}
local TweenFullList = {}

-- Safely fetch AreaMarkers using pcall
local success, areaMarkers = pcall(function()
    return game:GetService("ReplicatedStorage").WorldModel.AreaMarkers:GetChildren()
end)
if success then
    -- Remove duplicates by tracking seen names
    local seenAreas = {}
    for _, area in pairs(areaMarkers) do
        local areaNameSuccess, areaName = pcall(function()
            return area.Name
        end)
        if areaNameSuccess and areaName and not seenAreas[areaName] then
            seenAreas[areaName] = true
            table.insert(areaList, areaName)
            table.insert(TweenFullList, areaName)
        end
    end
end

-- Safely fetch NPCs from Workspace and TownMarkers
local ignoredNPCs = {
    "Blacksmith", "Doctor", "Merchant", "Collector", "Inn", "Missions",
    "Jail", "Cargo", "Shipwright", "Bazaar", "Bounties"
}

-- Fetch NPCs from Workspace/NPCs
local successNPCs, npcs = pcall(function()
    return game:GetService("Workspace").NPCs:GetChildren()
end)
if successNPCs then
    for _, npc in pairs(npcs) do
        local npcNameSuccess, npcName = pcall(function()
            return npc.Name
        end)
        if npcNameSuccess and npcName and not table.find(ignoredNPCs, npcName) then
            table.insert(npcList, npcName)
            table.insert(TweenFullList, npcName)
        end
    end
end

-- Fetch specified NPCs from TownMarkers
local successTowns, townFolders = pcall(function()
    return game:GetService("ReplicatedStorage").TownMarkers:GetChildren()
end)
if successTowns then
    for _, folder in pairs(townFolders) do
        local folderNameSuccess, folderName = pcall(function()
            return folder.Name
        end)
        if folderNameSuccess and folderName then
            local successParts, parts = pcall(function()
                return folder:GetChildren()
            end)
            if successParts then
                for _, part in pairs(parts) do
                    local partNameSuccess, partName = pcall(function()
                        return part.Name
                    end)
                    if partNameSuccess and partName and table.find(ignoredNPCs, partName) then
                        local formattedName = folderName .. ", " .. partName
                        table.insert(npcList, formattedName)
                        table.insert(TweenFullList, formattedName)
                    end
                end
            end
        end
    end
end

-- Sort lists for consistency
table.sort(areaList)
table.sort(npcList)
table.sort(TweenFullList)

-- Search bar with filtering logic
MainGroup3:AddInput("Search", {
    Text = "Search",
    Default = "",
    Placeholder = "Search or select below...",
    Callback = function(value)
        local success, filteredValues = pcall(function()
            local results = {}
            for _, item in pairs(TweenFullList) do
                if string.lower(item):find(string.lower(value)) or value == "" then
                    table.insert(results, item)
                end
            end
            return results
        end)
        if not success then
            filteredValues = TweenFullList -- Fallback to full list if filtering fails
        end

        -- Separate filtered values into area and NPC lists
        local areaValues = {}
        local npcValues = {}
        for _, item in pairs(filteredValues) do
            if table.find(areaList, item) then
                table.insert(areaValues, item)
            elseif table.find(npcList, item) then
                table.insert(npcValues, item)
            end
        end

        -- Safely update dropdowns
        pcall(function()
            Options.Areas:SetValues(areaValues)
            Options.NPCs:SetValues(npcValues)
        end)

        -- Set default values for dropdowns
        pcall(function()
            if #areaValues > 0 and (Options.Areas.Value == "" or not table.find(areaValues, Options.Areas.Value)) then
                Options.Areas:SetValue(areaValues[1]) -- Set first area match
            elseif #areaValues == 0 then
                Options.Areas:SetValue("") -- Clear if no area match
            end
        end)
        pcall(function()
            if #npcValues > 0 and (Options.NPCs.Value == "" or not table.find(npcValues, Options.NPCs.Value)) then
                Options.NPCs:SetValue(npcValues[1]) -- Set first NPC match
            elseif #npcValues == 0 then
                Options.NPCs:SetValue("") -- Clear if no NPC match
            end
        end)
    end
})

MainGroup3:AddSlider("UniversalTweenSpeed", {
    Text = "Universal Tween Speed",
    Default = 150,
    Min = 0,
    Max = 300,
    Rounding = 0,
    Compact = true
})

MainGroup3:AddDropdown("Areas", {
    Text = "Areas",
    Default = "",
    Values = areaList,
    Multi = false
})
MainGroup3:AddButton("Area Tween Start/Stop", function()
    local success, result = pcall(function()
        print("Area Tween Start/Stop clicked")
    end)
end)

MainGroup3:AddDropdown("NPCs", {
    Text = "NPCs",
    Default = "",
    Values = npcList,
    Multi = false
})
MainGroup3:AddButton("NPC Tween Start/Stop", function()
    local success, result = pcall(function()
        print("NPC Tween Start/Stop clicked")
    end)
end)

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

local MainGroup5 = Tabs.Main:AddLeftGroupbox("World")
MainGroup5:AddToggle("NoKillBricks", {
    Text = "No Kill Bricks",
    Default = false
})
MainGroup5:AddToggle("NoLava", {
    Text = "No Lava",
    Default = false
})

local MainGroup6 = Tabs.Main:AddLeftGroupbox("Rage")
MainGroup6:AddDropdown('PlayerDropdown', {
    SpecialType = 'Player',
    Text = 'Select Player',
    Tooltip = 'Attach to [Selected Username]', -- Information shown when you hover over the dropdown

    Callback = function(Value)
        print('[cb] Player dropdown got changed:', Value)
    end
})
MainGroup6:AddToggle("AttachtobackToggle", {
    Text = "Attach To Back",
    Default = false
}):AddKeyPicker("Attachtobackbind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.AttachtobackToggle:SetValue(value)
    end
})


-- Visuals Tab
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualsGroup:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false
})
local VisualsGroup2 = Tabs.Visuals:AddRightGroupbox("World Visuals")
VisualsGroup2:AddToggle("FullBright", {
    Text = "FullBright",
    Default = false
})
VisualsGroup2:AddSlider("FullBrightIntensity", {
    Text = "FullBright intensity",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true
})
VisualsGroup2:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false
})
VisualsGroup2:AddToggle("NoShadows", {
    Text = "No Shadows",
    Default = false
})


-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer


--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES



--END MODULES
--END MODULES
--END MODULES
--END MODULES


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

Library:Init()
