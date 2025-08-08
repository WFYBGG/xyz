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
_G.originalspeed = 100 -- Match GUI default
pcall(function()
    repeat
        wait()
    until game:IsLoaded()
    repeat
        wait()
    until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")

    _G.Speed = _G.originalspeed
    local u1 = false
    local u2 = false
    local u4 = game:GetService("Players")
    local u5 = game:GetService("UserInputService")
    
    -- Create BodyVelocity for movement
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge) -- Control X and Z axes only
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    
    -- Fallback to reset Humanoid state
    local function resetHumanoidState()
        local success, err = pcall(function()
            if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = u4.LocalPlayer.Character.Humanoid
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16 -- Default Roblox walk speed
                bodyVelocity.Parent = nil
            end
        end)
        if not success then
            warn("Reset humanoid state failed: " .. tostring(err))
        end
    end

    -- Handle character respawn
    u4.LocalPlayer.CharacterAdded:Connect(function(character)
        local success, err = pcall(function()
            repeat
                wait()
            until character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")
            if u1 then
                bodyVelocity.Parent = character.HumanoidRootPart
                character.Humanoid.JumpPower = 0
            end
        end)
        if not success then
            warn("CharacterAdded handler failed: " .. tostring(err))
        end
    end)

    -- Connect to GUI toggle
    Toggles.SpeedhackToggle:OnChanged(function(value)
        local success, err = pcall(function()
            u1 = value
            if u1 then
                if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    bodyVelocity.Parent = u4.LocalPlayer.Character.HumanoidRootPart
                    u4.LocalPlayer.Character.Humanoid.JumpPower = 0
                end
            else
                resetHumanoidState()
            end
        end)
        if not success then
            warn("Speedhack toggle failed: " .. tostring(err))
        end
    end)

    -- Connect to GUI slider
    Options.SpeedhackSpeed:OnChanged(function(value)
        local success, err = pcall(function()
            _G.Speed = value
        end)
        if not success then
            warn("Speedhack speed update failed: " .. tostring(err))
        end
    end)

    -- Main movement loop
    game:GetService("RunService").RenderStepped:Connect(function(u9)
        pcall(function()
            if u1 and u4.LocalPlayer.Character and u4.LocalPlayer.Character.HumanoidRootPart and u4.LocalPlayer.Character.Humanoid then
                u2 = true
                local v11 = {
                    Forward = u5:IsKeyDown(Enum.KeyCode.W),
                    Backward = u5:IsKeyDown(Enum.KeyCode.S),
                    Left = u5:IsKeyDown(Enum.KeyCode.A),
                    Right = u5:IsKeyDown(Enum.KeyCode.D)
                }
                
                -- Calculate movement direction
                local moveDirection = Vector3.new(0, 0, 0)
                if v11.Forward then
                    moveDirection = moveDirection + workspace.CurrentCamera.CFrame.LookVector
                elseif v11.Backward then
                    moveDirection = moveDirection - workspace.CurrentCamera.CFrame.LookVector
                elseif v11.Left then
                    moveDirection = moveDirection - workspace.CurrentCamera.CFrame.RightVector
                elseif v11.Right then
                    moveDirection = moveDirection + workspace.CurrentCamera.CFrame.RightVector
                end

                -- Normalize direction to ensure consistent speed
                if moveDirection.Magnitude > 0 then
                    moveDirection = moveDirection.Unit
                end

                -- Apply BodyVelocity with speed capped to avoid teleport detection
                local maxSpeedPerFrame = 49 / u9 -- Ensure movement < 50 studs per frame
                bodyVelocity.Velocity = moveDirection * math.min(_G.Speed, maxSpeedPerFrame)

                -- Monitor Humanoid health to detect kill
                if u4.LocalPlayer.Character.Humanoid.Health <= 0 then
                    resetHumanoidState()
                    u1 = false
                    u2 = false
                end
            else
                if u2 then
                    resetHumanoidState()
                    u2 = false
                end
            end
        end)
    end)

    -- Cleanup on script destruction
    game:BindToClose(function()
        local success, err = pcall(function()
            bodyVelocity:Destroy()
        end)
        if not success then
            warn("Cleanup failed: " .. tostring(err))
        end
    end)
end)


--Fly/Flight Module
_G.originalspeed = 200 -- Match GUI default
pcall(function()
    repeat
        wait()
    until game:IsLoaded()
    repeat
        wait()
    until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    _G.Speed = _G.originalspeed
    local u1 = false
    local u2 = false
    local u4 = game:GetService("Players")
    local u5 = game:GetService("UserInputService")

    local function resetHumanoidState()
        local success, err = pcall(function()
            if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = u4.LocalPlayer.Character.Humanoid
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16 -- Restore defaults
            end
        end)
        if not success then
            warn("Reset humanoid state failed: " .. tostring(err))
        end
    end

    -- Create platform
    local u8 = Instance.new("Part")
    u8.Name = "OldDebris"
    u8.Size = Vector3.new(6, 1, 6)
    u8.Anchored = true
    u8.CanCollide = true
    u8.Transparency = 1.00
    u8.Material = Enum.Material.SmoothPlastic
    u8.BrickColor = BrickColor.new("Bright blue")

    -- Create BodyVelocity for flight
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlightBodyVelocity" -- Unique name to distinguish from speedhack
    bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge) -- Control X and Z axes only
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)

    -- Function to disable speedhack BodyVelocity
    local function disableSpeedhack()
        local success, err = pcall(function()
            if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local speedhackBV = u4.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("bodyVelocity")
                if speedhackBV then
                    speedhackBV.Parent = nil
                end
            end
        end)
        if not success then
            warn("Disable speedhack failed: " .. tostring(err))
        end
    end

    -- Function to restore speedhack BodyVelocity
    local function restoreSpeedhack()
        local success, err = pcall(function()
            if Toggles.SpeedhackToggle and Toggles.SpeedhackToggle.Value then
                if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local speedhackBV = game:GetService("ReplicatedStorage"):FindFirstChild("bodyVelocity") or Instance.new("BodyVelocity")
                    speedhackBV.Name = "bodyVelocity"
                    speedhackBV.MaxForce = Vector3.new(math.huge, 0, math.huge)
                    speedhackBV.Velocity = Vector3.new(0, 0, 0)
                    speedhackBV.Parent = u4.LocalPlayer.Character.HumanoidRootPart
                end
            end
        end)
        if not success then
            warn("Restore speedhack failed: " .. tostring(err))
        end
    end

    -- Handle character respawn
    u4.LocalPlayer.CharacterAdded:Connect(function(character)
        local success, err = pcall(function()
            repeat
                wait()
            until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
            if u1 then
                if character:FindFirstChild("Humanoid") then
                    character.Humanoid.JumpPower = 0
                end
                u8.Parent = workspace
                u8.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
                disableSpeedhack() -- Disable speedhack when flight is active
            else
                u8.Parent = nil
                bodyVelocity.Parent = nil
                restoreSpeedhack() -- Restore speedhack if needed
            end
        end)
        if not success then
            warn("CharacterAdded handler failed: " .. tostring(err))
        end
    end)

    -- Connect to GUI toggle
    Toggles.FlightToggle:OnChanged(function(value)
        local success, err = pcall(function()
            u1 = value
            if u1 then
                if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    u4.LocalPlayer.Character.Humanoid.JumpPower = 0
                end
                u8.Parent = workspace
                if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    u8.CFrame = u4.LocalPlayer.Character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                    bodyVelocity.Parent = u4.LocalPlayer.Character.HumanoidRootPart
                    disableSpeedhack() -- Disable speedhack when flight is enabled
                end
            else
                resetHumanoidState()
                u8.Parent = nil
                bodyVelocity.Parent = nil
                restoreSpeedhack() -- Restore speedhack when flight is disabled
            end
        end)
        if not success then
            warn("Flight toggle failed: " .. tostring(err))
        end
    end)

    -- Connect to GUI slider
    Options.FlightSpeed:OnChanged(function(value)
        local success, err = pcall(function()
            _G.Speed = value
        end)
        if not success then
            warn("Flight speed update failed: " .. tostring(err))
        end
    end)

    -- Main movement loop
    game:GetService("RunService").RenderStepped:Connect(function(u9)
        pcall(function()
            if u1 and u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("Humanoid") and u4.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                u2 = true
                local v11 = {
                    Forward = u5:IsKeyDown(Enum.KeyCode.W),
                    Backward = u5:IsKeyDown(Enum.KeyCode.S),
                    Left = u5:IsKeyDown(Enum.KeyCode.A),
                    Right = u5:IsKeyDown(Enum.KeyCode.D),
                    Up = u5:IsKeyDown(Enum.KeyCode.Space),
                    Down = u5:IsKeyDown(Enum.KeyCode.LeftControl)
                }
                
                local v10 = u4.LocalPlayer.Character.HumanoidRootPart
                local moveDirection = Vector3.new(0, 0, 0)
                if v11.Forward then
                    moveDirection = moveDirection + workspace.CurrentCamera.CFrame.LookVector
                elseif v11.Backward then
                    moveDirection = moveDirection - workspace.CurrentCamera.CFrame.LookVector
                elseif v11.Left then
                    moveDirection = moveDirection - workspace.CurrentCamera.CFrame.RightVector
                elseif v11.Right then
                    moveDirection = moveDirection + workspace.CurrentCamera.CFrame.RightVector
                end

                if moveDirection.Magnitude > 0 then
                    moveDirection = moveDirection.Unit
                end

                -- Apply BodyVelocity with speed capped at 200 studs per frame
                local maxSpeedPerFrame = math.min(200, 49 / u9) -- Cap at 200 but respect 49 per frame limit
                if moveDirection.Magnitude > 0 then
                    bodyVelocity.Velocity = moveDirection * math.min(_G.Speed * u9, maxSpeedPerFrame)
                else
                    bodyVelocity.Velocity = Vector3.new(0, bodyVelocity.Velocity.Y, 0) -- Preserve vertical velocity
                end

                -- Allow JumpPower modification
                if u4.LocalPlayer.Character and u4.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    u4.LocalPlayer.Character.Humanoid.JumpPower = 0 -- Keep grounded
                end

                -- Update platform and flight
                if v10 then
                    u8.CFrame = v10.CFrame - Vector3.new(0, 3.499, 0)
                    local flightMove = 49 * u9 -- Stay under 50 studs per frame
                    if v11.Up then
                        u8.CFrame = u8.CFrame + Vector3.new(0, flightMove, 0)
                    elseif v11.Down then
                        u8.CFrame = u8.CFrame - Vector3.new(0, flightMove, 0)
                    end
                end

                -- Ensure speedhack is disabled
                disableSpeedhack()

                -- Monitor health to detect kill
                if u4.LocalPlayer.Character.Humanoid.Health <= 0 then
                    resetHumanoidState()
                    u1 = false
                    u2 = false
                    u8.Parent = nil
                    bodyVelocity.Parent = nil
                    restoreSpeedhack()
                end
            else
                if u2 then
                    resetHumanoidState()
                    u2 = false
                    u8.Parent = nil
                    bodyVelocity.Parent = nil
                    restoreSpeedhack()
                end
            end
        end)
    end)

    -- Cleanup on script destruction
    game:BindToClose(function()
        local success, err = pcall(function()
            bodyVelocity:Destroy()
            u8:Destroy()
        end)
        if not success then
            warn("Cleanup failed: " .. tostring(err))
        end
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
