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


--Player ESP Module
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    local LocalPlayer
    pcall(function() LocalPlayer = Players.LocalPlayer end)

    local ESPObjects = {}

    local function safeGet(parent, child)
        local result
        pcall(function()
            if parent and child then
                result = parent:FindFirstChild(child)
            end
        end)
        return result
    end

    local function getCharacterModel(player)
        local living
        pcall(function()
            living = workspace:FindFirstChild("Living")
        end)
        if not living then return nil end
        return safeGet(living, player.Name)
    end

    local function getHealthInfo(character)
        local health, maxHealth = 0, 0
        pcall(function()
            local humanoid = safeGet(character, "Humanoid")
            if humanoid then
                health = humanoid.Health
                maxHealth = humanoid.MaxHealth
            end
        end)
        return health, maxHealth
    end

    local function cleanupESP(player)
        local tbl
        pcall(function() tbl = ESPObjects[player] end)
        if tbl then
            for _, obj in pairs(tbl) do
                if typeof(obj) == "table" then
                    for _, v in pairs(obj) do
                        pcall(function() if typeof(v) == "userdata" and v.Remove then v:Remove() end end)
                    end
                else
                    pcall(function() if typeof(obj) == "userdata" and v.Remove then obj:Remove() end end)
                end
            end
            pcall(function() ESPObjects[player] = nil end)
        end
    end

    local function createESP(player)
        if player == LocalPlayer then return end
        pcall(function()
            if ESPObjects[player] then cleanupESP(player) end

            local box, nameText, healthText, distText, chamBox

            pcall(function()
                box = Drawing.new("Line")
                box.Visible = false
                box.Thickness = 2
                box.Color = Color3.fromRGB(255, 25, 25)
            end)

            pcall(function()
                nameText = Drawing.new("Text")
                nameText.Size = 14
                nameText.Center = true
                nameText.Outline = true
                nameText.Color = Color3.fromRGB(255, 255, 255)
                nameText.Visible = false
            end)

            pcall(function()
                healthText = Drawing.new("Text")
                healthText.Size = 13
                healthText.Center = true
                healthText.Outline = true
                healthText.Color = Color3.fromRGB(0, 255, 0)
                healthText.Visible = false
            end)

            pcall(function()
                distText = Drawing.new("Text")
                distText.Size = 13
                distText.Center = true
                distText.Outline = true
                distText.Color = Color3.fromRGB(200, 200, 200)
                distText.Visible = false
            end)

            pcall(function()
                chamBox = Drawing.new("Square")
                chamBox.Visible = false
                chamBox.Color = Color3.fromRGB(255, 0, 0)
                chamBox.Transparency = 0.2
                chamBox.Filled = true
            end)

            ESPObjects[player] = {
                Box = box,
                Name = nameText,
                Health = healthText,
                Distance = distText,
                ChamBox = chamBox,
                Skeleton = {},
            }
        end)
    end

    local function drawSkeleton(player, char, color, thickness)
        local bones = {
            { "Head", "HumanoidRootPart" },
            { "HumanoidRootPart", "LeftUpperLeg" },
            { "LeftUpperLeg", "LeftLowerLeg" },
            { "LeftLowerLeg", "LeftFoot" },
            { "HumanoidRootPart", "RightUpperLeg" },
            { "RightUpperLeg", "RightLowerLeg" },
            { "RightLowerLeg", "RightFoot" },
            { "HumanoidRootPart", "LeftUpperArm" },
            { "LeftUpperArm", "LeftLowerArm" },
            { "LeftLowerArm", "LeftHand" },
            { "HumanoidRootPart", "RightUpperArm" },
            { "RightUpperArm", "RightLowerArm" },
            { "RightLowerArm", "RightHand" },
        }

        if not ESPObjects[player] then ESPObjects[player] = {} end
        local skeleton = ESPObjects[player].Skeleton or {}

        for i, pair in ipairs(bones) do
            local part1, part2
            pcall(function()
                part1 = char:FindFirstChild(pair[1])
                part2 = char:FindFirstChild(pair[2])
            end)
            local line = skeleton[i]
            if not line then
                line = Drawing.new("Line")
                skeleton[i] = line
            end

            if part1 and part2 then
                local pos1, onScr1 = Camera:WorldToViewportPoint(part1.Position)
                local pos2, onScr2 = Camera:WorldToViewportPoint(part2.Position)
                if onScr1 and onScr2 then
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    line.Color = color or Color3.fromRGB(255,255,255)
                    line.Thickness = thickness or 2
                    line.Visible = Toggles.PlayerESP.Value
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
        ESPObjects[player].Skeleton = skeleton
    end

    -- Player join/leave management
    pcall(function()
        Players.PlayerAdded:Connect(function(plr)
            if plr ~= LocalPlayer then pcall(function() createESP(plr) end) end
        end)
    end)
    pcall(function()
        Players.PlayerRemoving:Connect(function(plr)
            pcall(function() cleanupESP(plr) end)
        end)
    end)
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then pcall(function() createESP(plr) end) end
        end
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            local streamedPlayers = {}
            for player, tbl in pairs(ESPObjects) do
                streamedPlayers[player] = true
                pcall(function()
                    local char = getCharacterModel(player)
                    local box, nameText, healthText, distText, chamBox
                    pcall(function()
                        box = tbl.Box
                        nameText = tbl.Name
                        healthText = tbl.Health
                        distText = tbl.Distance
                        chamBox = tbl.ChamBox
                    end)

                    if char and safeGet(char, "HumanoidRootPart") then
                        local hrp
                        pcall(function() hrp = char.HumanoidRootPart end)
                        local pos, onScreen, health, maxHealth, extents, topW, onScreen1, botW, onScreen2, height, width

                        pcall(function()
                            pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        end)

                        pcall(function()
                            health, maxHealth = getHealthInfo(char)
                        end)

                        pcall(function()
                            extents = char:GetExtentsSize()
                        end)

                        pcall(function()
                            topW, onScreen1 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, extents.Y/2, 0))
                        end)
                        pcall(function()
                            botW, onScreen2 = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, extents.Y/2, 0))
                        end)
                        pcall(function()
                            height = (botW.Y - topW.Y)
                            width = height * 0.45
                        end)

                        if Toggles.PlayerESP.Value and onScreen and onScreen1 and onScreen2 and health > 0 then
                            -- Chams box (drawn behind ESP box)
                            pcall(function()
                                chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                                chamBox.Size = Vector2.new(width, height)
                                chamBox.Color = Color3.fromRGB(255, 0, 0)
                                chamBox.Transparency = 0.15
                                chamBox.Visible = true
                            end)

                            -- Draw box (top horizontal line)
                            pcall(function()
                                box.From = Vector2.new(topW.X - width/2, topW.Y)
                                box.To = Vector2.new(topW.X + width/2, topW.Y)
                                box.Visible = true
                            end)

                            -- Draw name
                            pcall(function()
                                nameText.Text = player.DisplayName
                                nameText.Position = Vector2.new(pos.X, topW.Y - 16)
                                nameText.Visible = true
                            end)

                            -- Draw health/maxhealth
                            pcall(function()
                                healthText.Text = "[" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
                                healthText.Position = Vector2.new(pos.X, topW.Y - 2)
                                local r = math.floor(255 - 255 * (health/maxHealth))
                                local g = math.floor(255 * (health/maxHealth))
                                healthText.Color = Color3.fromRGB(r, g, 0)
                                healthText.Visible = true
                            end)

                            -- Draw distance
                            pcall(function()
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                distText.Text = "[" .. math.floor(dist) .. "m]"
                                distText.Position = Vector2.new(pos.X, botW.Y + 2)
                                distText.Visible = true
                            end)

                            -- Draw skeleton
                            drawSkeleton(player, char, Color3.fromRGB(255,255,255), 2)
                        else
                            pcall(function() box.Visible = false end)
                            pcall(function() nameText.Visible = false end)
                            pcall(function() healthText.Visible = false end)
                            pcall(function() distText.Visible = false end)
                            pcall(function() chamBox.Visible = false end)
                            -- Hide skeleton lines
                            if tbl.Skeleton then
                                for _, line in pairs(tbl.Skeleton) do
                                    pcall(function() line.Visible = false end)
                                end
                            end
                        end
                    else
                        pcall(function() box.Visible = false end)
                        pcall(function() nameText.Visible = false end)
                        pcall(function() healthText.Visible = false end)
                        pcall(function() distText.Visible = false end)
                        pcall(function() chamBox.Visible = false end)
                        -- Hide skeleton lines
                        if tbl.Skeleton then
                            for _, line in pairs(tbl.Skeleton) do
                                pcall(function() line.Visible = false end)
                            end
                        end
                    end
                end)
            end
            -- Robust cleanup: remove ESP for any player no longer in Players
            for playerRef in pairs(ESPObjects) do
                local found = false
                pcall(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p == playerRef then
                            found = true
                            break
                        end
                    end
                end)
                if not found then
                    cleanupESP(playerRef)
                end
            end
        end)
    end)

    -- Log script start
    print("[ESP] Script initialized at " .. os.date("%H:%M:%S"))
end, function(err)
    print("[ESP] Initialization error: " .. tostring(err))
end)




--Universal Tween & Location
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer
pcall(function() LocalPlayer = LocalPlayer or Players.LocalPlayer end)

-- State management
local isTweening = false
local priorSettings = {Speedhack = false, Flight = false, Noclip = false, NoFall = false, Speed = 100}
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
local currentTarget = nil

-- Save prior settings
local function savePriorSettings()
    pcall(function()
        priorSettings.Speedhack = Toggles.SpeedhackToggle.Value
        priorSettings.Flight = Toggles.FlightToggle.Value
        priorSettings.Noclip = Toggles.NoclipToggle.Value
        priorSettings.NoFall = Toggles.NoFallDamage.Value
        priorSettings.Speed = Options.SpeedhackSpeed.Value
    end)
end

-- Restore prior settings
local function restoreSettings()
    pcall(function()
        Toggles.SpeedhackToggle:SetValue(priorSettings.Speedhack)
        Toggles.FlightToggle:SetValue(priorSettings.Flight)
        Toggles.NoclipToggle:SetValue(priorSettings.Noclip)
        Toggles.NoFallDamage:SetValue(priorSettings.NoFall)
        Options.SpeedhackSpeed:SetValue(priorSettings.Speed)
    end)
end

-- Prevent toggle changes during tween
local function preventToggleChange(toggleName, value)
    if isTweening and (toggleName == "FlightToggle" or toggleName == "NoclipToggle" or toggleName == "NoFallDamage") and not value then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tween Error",
                Text = "Tween in progress. Stop to disable " .. toggleName:gsub("Toggle", ""),
                Duration = 5
            })
        end)
        return false
    end
    return true
end

-- Toggle handlers
pcall(function()
    Toggles.SpeedhackToggle:OnChanged(function(value)
        if not isTweening or preventToggleChange("SpeedhackToggle", value) then
            pcall(function() Options.SpeedhackSpeed:SetValue(value and Options.SpeedhackSpeed.Value or 100) end)
        end
    end)
end)

pcall(function()
    Toggles.FlightToggle:OnChanged(function(value)
        if preventToggleChange("FlightToggle", value) then
            -- Flight logic (placeholder, assume handled by GUI)
        end
    end)
end)

pcall(function()
    Toggles.NoclipToggle:OnChanged(function(value)
        if preventToggleChange("NoclipToggle", value) then
            -- Noclip logic (placeholder, assume handled by GUI)
        end
    end)
end)

pcall(function()
    Toggles.NoFallDamage:OnChanged(function(value)
        if preventToggleChange("NoFallDamage", value) then
            -- NoFall logic (placeholder, assume handled by GUI)
        end
    end)
end)

-- Disable animations
local function disableAnimations(char)
    pcall(function()
        local humanoid = char and char:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop() end)
            end
        end
    end)
end

-- Get target CFrame
local function getTargetCFrame(targetType, targetName)
    local targetCFrame = nil
    pcall(function()
        if targetType == "Areas" then
            local areaMarkers = game:GetService("ReplicatedStorage"):FindFirstChild("WorldModel") and game:GetService("ReplicatedStorage").WorldModel:FindFirstChild("AreaMarkers")
            if areaMarkers then
                for _, area in pairs(areaMarkers:GetChildren()) do
                    if area.Name == targetName then
                        targetCFrame = area.CFrame
                        break
                    end
                end
            end
        elseif targetType == "NPCs" then
            local npcs = game:GetService("Workspace"):FindFirstChild("NPCs")
            if npcs then
                for _, npc in pairs(npcs:GetChildren()) do
                    if npc.Name == targetName then
                        targetCFrame = npc.CFrame
                        break
                    elseif game:GetService("ReplicatedStorage"):FindFirstChild("TownMarkers") then
                        for _, town in pairs(game:GetService("ReplicatedStorage").TownMarkers:GetChildren()) do
                            if town:FindFirstChild(targetName) then
                                targetCFrame = town[targetName].CFrame
                                targetName = town.Name .. " " .. targetName
                                break
                            end
                        end
                    end
                    if targetCFrame then break end
                end
            end
        end
    end)
    return targetCFrame, targetName
end

-- Update dropdowns
local function updateDropdowns()
    pcall(function()
        local areaValues = {}
        local npcValues = {}
        local areaMarkers = game:GetService("ReplicatedStorage"):FindFirstChild("WorldModel") and game:GetService("ReplicatedStorage").WorldModel:FindFirstChild("AreaMarkers")
        if areaMarkers then
            for _, area in pairs(areaMarkers:GetChildren()) do
                if not table.find(areaValues, area.Name) then
                    table.insert(areaValues, area.Name)
                end
            end
        end
        local npcs = game:GetService("Workspace"):FindFirstChild("NPCs")
        if npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                local npcName = npc.Name
                if game:GetService("ReplicatedStorage"):FindFirstChild("TownMarkers") then
                    for _, town in pairs(game:GetService("ReplicatedStorage").TownMarkers:GetChildren()) do
                        if town:FindFirstChild(npcName) then
                            npcName = town.Name .. " " .. npcName
                            break
                        end
                    end
                end
                if not table.find(npcValues, npcName) then
                    table.insert(npcValues, npcName)
                end
            end
        end
        Options.Areas:SetValues(areaValues)
        Options.NPCs:SetValues(npcValues)
        if #areaValues > 0 and Options.Areas.Value == "" then Options.Areas:SetValue(areaValues[1]) end
        if #npcValues > 0 and Options.NPCs.Value == "" then Options.NPCs:SetValue(npcValues[1]) end
    end)
end

-- Tween execution
local function startTween(targetType, targetName)
    if isTweening then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tween Error",
                Text = "Tween in progress. Stop to switch target.",
                Duration = 5
            })
        end)
        return
    end

    savePriorSettings()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    pcall(function()
        Toggles.SpeedhackToggle:SetValue(false)
        if not Toggles.FlightToggle.Value then Toggles.FlightToggle:SetValue(true) end
        if not Toggles.NoclipToggle.Value then Toggles.NoclipToggle:SetValue(true) end
        if not Toggles.NoFallDamage.Value then Toggles.NoFallDamage:SetValue(true) end
    end)

    isTweening = true
    disableAnimations(char)

    local targetCFrame, adjustedName = getTargetCFrame(targetType, targetName)
    if not targetCFrame then
        isTweening = false
        restoreSettings()
        return
    end

    local speed = Options.UniversalTweenSpeed.Value / 100
    local steps = {
        {pos = hrp.Position + Vector3.new(0, 1000 - hrp.Position.Y, 0), time = (1000 - hrp.Position.Y) / speed},
        {pos = Vector3.new(targetCFrame.X, 1000, targetCFrame.Z), time = ((Vector3.new(targetCFrame.X, 0, targetCFrame.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude) / speed},
        {pos = targetCFrame.Position, time = 1000 / speed}
    }

    for i, step in pairs(steps) do
        if not isTweening then break end
        local tween = TweenService:Create(hrp, TweenInfo.new(step.time, Enum.EasingStyle.Linear), {Position = step.pos})
        pcall(function() tween:Play() end)
        pcall(function() tween.Completed:Wait() end)
    end

    if isTweening then
        restoreSettings()
    end
    isTweening = false
end

local function stopTween()
    if not isTweening then return end
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            for _, tween in pairs(TweenService:GetTweens(hrp)) do
                pcall(function() tween:Cancel() end)
            end
        end
    end)
    restoreSettings()
    isTweening = false
end

-- Button handlers
pcall(function()
    Options.Areas:OnChanged(function(value)
        updateDropdowns()
    end)
end)

pcall(function()
    Options.NPCs:OnChanged(function(value)
        updateDropdowns()
    end)
end)

pcall(function()
    MainGroup3.Buttons["Area Tween Start/Stop"]:SetCallback(function()
        if Options.Areas.Value ~= "" then
            startTween("Areas", Options.Areas.Value)
        end
    end)
end)

pcall(function()
    MainGroup3.Buttons["NPC Tween Start/Stop"]:SetCallback(function()
        if Options.NPCs.Value ~= "" then
            startTween("NPCs", Options.NPCs.Value)
        end
    end)
end)

pcall(function()
    MainGroup3.Buttons["Area Tween Start/Stop"]:AddCallbackOnRight(function()
        stopTween()
    end)
end)

pcall(function()
    MainGroup3.Buttons["NPC Tween Start/Stop"]:AddCallbackOnRight(function()
        stopTween()
    end)
end)

-- Initial update
pcall(updateDropdowns)





--Attach to back Module [TESTING STILL]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Internal state
local targetPlayer = nil
local isAttached = false
local attachConn = nil
local isTweening = false
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)

-- Utility: Safe get
local function safeGet(obj, ...)
    local args = {...}
    for i, v in ipairs(args) do
        local ok, res = pcall(function() return obj[v] end)
        if not ok then return nil end
        obj = res
        if not obj then return nil end
    end
    return obj
end

-- Toggle GUI utilities
local function setToggle(toggleName, value)
    local ok, toggle = pcall(function() return Toggles[toggleName] end)
    if ok and toggle then
        pcall(function() toggle:SetValue(value) end)
    end
end

-- Get tween speed safely
local function getTweenSpeed()
    local ok, value = pcall(function() return Options.UniversalTweenSpeed.Value end)
    return ok and math.max(0, math.min(300, value)) or 150
end

-- Death detection and cleanup
local function checkDeathCleanup()
    local char = LocalPlayer.Character
    local targetChar = targetPlayer and targetPlayer.Character
    local localHumanoid = char and safeGet(char, "Humanoid")
    local targetHumanoid = targetChar and safeGet(targetChar, "Humanoid")
    local isLocalDead = localHumanoid and pcall(function() return localHumanoid.Health <= 0 end)
    local isTargetDead = targetHumanoid and pcall(function() return targetHumanoid.Health <= 0 end)
    if isLocalDead or isTargetDead then
        local hrp = char and safeGet(char, "HumanoidRootPart")
        if hrp and isTweening then
            for _, tween in pairs(TweenService:GetTweens(hrp)) do
                pcall(function() tween:Cancel() end)
            end
        end
        stopAttach()
        isTweening = false
        return true
    end
    return false
end

-- Attach/Detach logic
local function stopAttach()
    isAttached = false
    if attachConn then pcall(function() attachConn:Disconnect() end) attachConn = nil end
    setToggle("FlightToggle", false)
    setToggle("NoclipToggle", false)
    setToggle("NoFallDamage", false)
    isTweening = false
end

local function startAttach()
    stopAttach()
    isAttached = true
    setToggle("NoFallDamage", true)
    attachConn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        local targetChar = targetPlayer and targetPlayer.Character
        local hrp = char and safeGet(char, "HumanoidRootPart")
        local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
        if not (hrp and targetHrp) then return end
        pcall(function()
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
        end)
        checkDeathCleanup()
    end)
end

-- Tween logic with GUI toggles
local function tweenToBack()
    if isTweening or not targetPlayer then return end
    isTweening = true
    local char = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    local hrp = char and safeGet(char, "HumanoidRootPart")
    local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
    if not (hrp and targetHrp) then isTweening = false return end

    -- Enable movement toggles
    setToggle("FlightToggle", true)
    setToggle("NoclipToggle", true)
    setToggle("NoFallDamage", true)

    local speed = getTweenSpeed()
    local steps = {
        { pos = hrp.Position + Vector3.new(0, 1000 - hrp.Position.Y, 0), time = (1000 - hrp.Position.Y) / speed },
        { pos = targetHrp.Position + Vector3.new(0, 1000 - targetHrp.Position.Y, 0), time = (targetHrp.Position - hrp.Position).Magnitude / speed },
        { pos = (targetHrp.CFrame * CFrame.new(0, 0, 2)).Position, time = 1000 / speed }
    }

    for i, step in ipairs(steps) do
        if not Toggles.AttachtobackToggle.Value or checkDeathCleanup() or not targetPlayer then
            local currentTweens = TweenService:GetTweens(hrp)
            for _, tween in pairs(currentTweens) do
                pcall(function() tween:Cancel() end)
            end
            isTweening = false
            setToggle("FlightToggle", false)
            setToggle("NoclipToggle", false)
            return
        end
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(step.pos)})
        pcall(function() tween:Play() end)
        pcall(function() tween.Completed:Wait() end)
    end

    -- Disable movement toggles after tween
    setToggle("FlightToggle", false)
    setToggle("NoclipToggle", false)
    isTweening = false
    if Toggles.AttachtobackToggle.Value and targetPlayer and not checkDeathCleanup() then
        startAttach()
    end
end

-- GUI Integration
pcall(function()
    Options.PlayerDropdown:OnChanged(function(value)
        targetPlayer = value ~= "" and Players:FindFirstChild(value) or nil
        if Toggles.AttachtobackToggle.Value and not isTweening and not isAttached then
            tweenToBack()
        elseif isTweening or isAttached then
            local char = LocalPlayer.Character
            local hrp = char and safeGet(char, "HumanoidRootPart")
            if hrp then
                for _, tween in pairs(TweenService:GetTweens(hrp)) do
                    pcall(function() tween:Cancel() end)
                end
            end
            stopAttach()
            if targetPlayer then
                tweenToBack()
            end
        end
    end)
end)

pcall(function()
    Toggles.AttachtobackToggle:OnChanged(function(value)
        if not value then
            local char = LocalPlayer.Character
            local hrp = char and safeGet(char, "HumanoidRootPart")
            if hrp and isTweening then
                for _, tween in pairs(TweenService:GetTweens(hrp)) do
                    pcall(function() tween:Cancel() end)
                end
            end
            stopAttach()
        elseif value and targetPlayer and not isTweening and not isAttached then
            tweenToBack()
        end
    end)
end)

-- Player join/leave management
pcall(function()
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            local ok, _ = pcall(function() Options.PlayerDropdown:Refresh() end)
        end
    end)
end)

pcall(function()
    Players.PlayerRemoving:Connect(function(player)
        if player == targetPlayer then
            stopAttach()
            targetPlayer = nil
            pcall(function() Options.PlayerDropdown:SetValue("") end)
        end
        pcall(function() Options.PlayerDropdown:Refresh() end)
    end)
end)

-- Character added/respawn handling
pcall(function()
    LocalPlayer.CharacterAdded:Connect(function(char)
        local humanoid = safeGet(char, "Humanoid")
        if humanoid then
            pcall(function()
                humanoid.Died:Connect(function()
                    local hrp = safeGet(char, "HumanoidRootPart")
                    if hrp and isTweening then
                        for _, tween in pairs(TweenService:GetTweens(hrp)) do
                            pcall(function() tween:Cancel() end)
                        end
                    end
                    stopAttach()
                    isTweening = false
                end)
            end)
        end
        stopAttach() -- Reset on respawn
    end)
end)

-- Initial cleanup
stopAttach()


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
