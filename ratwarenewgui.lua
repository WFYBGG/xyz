local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe [Press 'Insert' to hide GUI]",
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
local TweenFullList = {"WIP", "Area1", "Area2", "Area3", "Area4", "? ??, God's Eye", "NPC1", "NPC2", "NPC3", "NPC4"} -- Combined list for areas and NPCs
MainGroup3:AddInput("Search", {
    Text = "Search",
    Default = "",
    Placeholder = "Search or select below...",
    Callback = function(value)
        local filteredValues = {}
        for _, item in pairs(TweenFullList) do
            if string.lower(item):find(string.lower(value)) or value == "" then
                table.insert(filteredValues, item)
            end
        end
        -- Update both dropdowns with filtered values
        local areaValues = {}
        local npcValues = {}
        for _, item in pairs(filteredValues) do
            if table.find({"WIP", "Area1", "Area2", "Area3", "Area4"}, item) then
                table.insert(areaValues, item)
            elseif table.find({"? ??, God's Eye", "NPC1", "NPC2", "NPC3", "NPC4"}, item) then
                table.insert(npcValues, item)
            end
        end
        Options.Areas:SetValues(areaValues)
        Options.NPCs:SetValues(npcValues)
        if #areaValues > 0 and (Options.Areas.Value == "" or not table.find(areaValues, Options.Areas.Value)) then
            Options.Areas:SetValue(areaValues[1]) -- Set first area match
        elseif #areaValues == 0 then
            Options.Areas:SetValue("") -- Clear if no area match
        end
        if #npcValues > 0 and (Options.NPCs.Value == "" or not table.find(npcValues, Options.NPCs.Value)) then
            Options.NPCs:SetValue(npcValues[1]) -- Set first NPC match
        elseif #npcValues == 0 then
            Options.NPCs:SetValue("") -- Clear if no NPC match
        end
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
    Default = "WIP",
    Values = {"WIP", "Area1", "Area2", "Area3", "Area4"},
    Multi = false
})
MainGroup3:AddButton("Area Tween Start/Stop", function() print("Area Tween Start/Stop clicked") end)

MainGroup3:AddDropdown("NPCs", {
    Text = "NPCs",
    Default = "? ??, God's Eye",
    Values = {"? ??, God's Eye", "NPC1", "NPC2", "NPC3", "NPC4"},
    Multi = false
})
MainGroup3:AddButton("NPC Tween Start/Stop", function() print("NPC Tween Start/Stop clicked") end)

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




--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES


-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer


--Speedhack Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer

    -- Wait for GUI initialization with timeout
    local timeout = tick() + 10
    while not (Toggles and Toggles.SpeedhackToggle and Options and Options.SpeedhackSpeed) and tick() < timeout do
        print("[Speedhack] Waiting for GUI initialization...")
        task.wait(0.1)
    end
    if not Toggles or not Toggles.SpeedhackToggle or not Options or not Options.SpeedhackSpeed then
        print("[Speedhack] Error: GUI Toggles or Options not initialized after timeout")
        return
    end

    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    BodyVelocity.Name = "SpeedhackVelocity"

    local function resetSpeed()
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = 50
            end
            BodyVelocity.Parent = nil
        end, function(err)
            print("[Speedhack] resetSpeed error: " .. tostring(err))
        end)
    end

    local function cleanupSpeed()
        pcall(function()
            resetSpeed()
            BodyVelocity:Destroy()
            print("[Speedhack] Cleaned up at " .. os.date("%H:%M:%S"))
        end, function(err)
            print("[Speedhack] cleanupSpeed error: " .. tostring(err))
        end)
    end

    -- Initialize for existing character
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if Toggles.SpeedhackToggle.Value then
                local char = player.Character
                BodyVelocity.Parent = char.HumanoidRootPart
                char.Humanoid.JumpPower = 0
                print("[Speedhack] Initialized for existing character")
            end
        else
            print("[Speedhack] Warning: No character or components found on startup")
        end
    end, function(err)
        print("[Speedhack] Initial character check error: " .. tostring(err))
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            -- Wait for HumanoidRootPart and Humanoid
            local timeout = tick() + 5
            while not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) and tick() < timeout do
                task.wait()
            end
            if not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) then
                print("[Speedhack] Error: Character initialization failed")
                return
            end
            if Toggles.SpeedhackToggle.Value then
                BodyVelocity.Parent = character.HumanoidRootPart
                character.Humanoid.JumpPower = 0
                print("[Speedhack] Enabled for new character")
            end
        end, function(err)
            print("[Speedhack] CharacterAdded error: " .. tostring(err))
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function(dt)
            pcall(function()
                local char = player.Character
                if Toggles.SpeedhackToggle.Value and char and char:FindFirstChild("HumanoidRootPart") then
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= workspace.CurrentCamera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += workspace.CurrentCamera.CFrame.RightVector end
                    dir = dir.Magnitude > 0 and dir.Unit or Vector3.zero

                    BodyVelocity.Velocity = dir * math.min(Options.SpeedhackSpeed.Value, 49 / dt)
                    BodyVelocity.Parent = char.HumanoidRootPart
                    char.Humanoid.JumpPower = 0
                else
                    resetSpeed()
                end
            end, function(err)
                print("[Speedhack] RenderStepped error: " .. tostring(err))
            end)
        end)
    end, function(err)
        print("[Speedhack] Error connecting RenderStepped: " .. tostring(err))
    end)

    -- Handle Flight toggle-off when both are active
    pcall(function()
        if Toggles.FlightToggle then
            Toggles.FlightToggle:OnChanged(function(value)
                pcall(function()
                    if not value and Toggles.SpeedhackToggle.Value then
                        Toggles.SpeedhackToggle:SetValue(false)
                        task.wait(0.1)
                        Toggles.SpeedhackToggle:SetValue(true)
                        print("[Speedhack] Re-enabled after Flight toggle-off")
                    end
                end, function(err)
                    print("[Speedhack] FlightToggle OnChanged error: " .. tostring(err))
                end)
            end)
        else
            print("[Speedhack] Warning: Toggles.FlightToggle not found")
        end
    end, function(err)
        print("[Speedhack] Error setting up FlightToggle: " .. tostring(err))
    end)
end)


--Fly/Flight Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer

    local Platform = Instance.new("Part")
    Platform.Size = Vector3.new(6, 1, 6)
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Transparency = 1.00
    Platform.BrickColor = BrickColor.new("Bright blue")
    Platform.Material = Enum.Material.SmoothPlastic
    Platform.Name = "OldDebris"

    local FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

    local function resetFly()
        pcall(function()
            Platform.Parent = nil
            FlyVelocity.Parent = nil
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = 50
            end
        end)
    end

    local function cleanupFly()
        pcall(function()
            resetFly()
            Platform:Destroy()
            FlyVelocity:Destroy()
        end)
    end

    player.CharacterAdded:Connect(function(char)
        pcall(function()
            repeat task.wait() until char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
            if Toggles.FlightToggle.Value then
                FlyVelocity.Parent = char.HumanoidRootPart
                Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                Platform.Parent = workspace
                char.Humanoid.JumpPower = 0
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function(dt)
            pcall(function()
                local char = player.Character
                if Toggles.FlightToggle.Value and char and char:FindFirstChild("HumanoidRootPart") then
                    local moveDir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
                    moveDir = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero

                    local vert = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = 70 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -70 end

                    FlyVelocity.Velocity = moveDir * math.min(Options.FlightSpeed.Value, 49 / dt) + Vector3.new(0, vert, 0)
                    FlyVelocity.Parent = char.HumanoidRootPart

                    Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                    Platform.Parent = workspace
                else
                    resetFly()
                end
            end)
        end)
    end)

    -- Handle Speedhack toggle-off when both are active
    Toggles.SpeedhackToggle:OnChanged(function(value)
        pcall(function()
            if not value and Toggles.FlightToggle.Value then
                Toggles.FlightToggle:SetValue(false)
                task.wait(0.1)
                Toggles.FlightToggle:SetValue(true)
            end
        end)
    end)
end)


--Noclip Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Check if GUI is initialized
    if not Toggles or not Toggles.NoclipToggle then
        print("[Noclip] Error: GUI toggles not initialized")
        return
    end

    local function setCollision(state)
        pcall(function()
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = state
                    end
                end
            else
                print("[Noclip] Warning: No character found for setCollision")
            end
        end, function(err)
            print("[Noclip] setCollision error: " .. tostring(err))
        end)
    end

    -- Check if character exists on script start
    pcall(function()
        if player.Character and Toggles.NoclipToggle.Value then
            setCollision(false)
            print("[Noclip] Enabled for existing character")
        end
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            -- Wait for character parts with timeout
            local timeout = tick() + 5
            while not character:FindFirstChild("HumanoidRootPart") and tick() < timeout do
                task.wait()
            end
            if not character:FindFirstChild("HumanoidRootPart") then
                print("[Noclip] Error: Character initialization failed")
                return
            end
            if Toggles.NoclipToggle.Value then
                setCollision(false)
                print("[Noclip] Enabled for new character")
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                setCollision(not Toggles.NoclipToggle.Value)
            end, function(err)
                print("[Noclip] RenderStepped error: " .. tostring(err))
            end)
        end)
    end, function(err)
        print("[Noclip] Error connecting RenderStepped: " .. tostring(err))
    end)
end)


--No fall module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local fallFolder = nil

    local function setNoFall(active)
        pcall(function()
            local status = Workspace:WaitForChild("Living"):WaitForChild(player.Name):WaitForChild("Status")
            if active then
                if fallFolder then fallFolder:Destroy() end
                fallFolder = Instance.new("Folder")
                fallFolder.Name = "FallDamageCD"
                fallFolder.Parent = status
            else
                if fallFolder then fallFolder:Destroy() end
            end
        end)
    end

    player.CharacterAdded:Connect(function()
        pcall(function()
            repeat task.wait() until Workspace:FindFirstChild("Living")
            if Toggles.NoFallDamage.Value then
                setNoFall(true)
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                setNoFall(Toggles.NoFallDamage.Value)
            end)
        end)
    end)
end)


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
