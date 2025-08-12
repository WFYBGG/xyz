--CURRENTLY SPEED/FLY TOGGLE PROBLEM WHEN BOTH ON DUE TO LONG SCRIPT. FIX WITH: Provide a standalone toggle system that: Tracks speedhack and fly states. Implements the toggle-off-and-back-on logic when one is disabled while both are active.

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
    "Jail", "Cargo", "Shipwright", "Bazaar", "Bounties", "Banker", "Bank", "Innkeeper", "The Collector"
}

-- NPCs to only include the first instance of
local firstInstanceOnly = {
    "Ancient Cavern Gate", "Ancient Gate", "Celestial Platform", "Frosty", "Prince's Favour", "Prince's Scale"
}

-- Helper function to calculate Euclidean distance between two Vector3 positions
local function getDistance(pos1, pos2)
    local success, distance = pcall(function()
        local dx = pos1.X - pos2.X
        local dy = pos1.Y - pos2.Y
        local dz = pos1.Z - pos2.Z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end)
    return success and distance or math.huge
end

-- Fetch NPCs from Workspace/NPCs, handling duplicates by proximity to areas
local successNPCs, npcs = pcall(function()
    return game:GetService("Workspace").NPCs:GetChildren()
end)
if successNPCs then
    local npcInstances = {} -- Track NPC instances by name
    local seenFirstInstance = {} -- Track first instance for specific NPCs
    for _, npc in pairs(npcs) do
        local npcNameSuccess, npcName = pcall(function()
            return npc.Name
        end)
        if npcNameSuccess and npcName and not table.find(ignoredNPCs, npcName) then
            if not npcInstances[npcName] then
                npcInstances[npcName] = {}
            end
            local position = nil
            local positionSuccess, pos = pcall(function()
                return npc.WorldPivot.Position
            end)
            if not positionSuccess then
                positionSuccess, pos = pcall(function()
                    return npc.CFrame.Position
                end)
                if positionSuccess then
                    print("Used CFrame.Position for NPC: " .. npcName)
                else
                    print("Failed to get WorldPivot.Position and CFrame.Position for NPC: " .. npcName)
                end
            end
            if positionSuccess then
                position = pos
            end
            table.insert(npcInstances[npcName], {instance = npc, position = position, name = npcName})
        end
    end

    -- Process NPCs, handling duplicates and first-instance-only cases
    local seenAreaForNPC = {} -- Track {npcName, areaName} to avoid duplicate area assignments
    for npcName, instances in pairs(npcInstances) do
        if table.find(firstInstanceOnly, npcName) then
            -- For specific NPCs, only include the first instance
            if #instances > 0 and not seenFirstInstance[npcName] then
                seenFirstInstance[npcName] = true
                table.insert(npcList, npcName)
                table.insert(TweenFullList, npcName)
            end
        elseif #instances == 1 then
            -- Single instance, use raw name
            local instanceData = instances[1]
            print("Single-instance NPC: " .. npcName .. " added with raw name")
            table.insert(npcList, npcName)
            table.insert(TweenFullList, npcName)
        else
            -- Multiple instances, find closest area for each, include only first per area
            for _, instanceData in pairs(instances) do
                if instanceData.position then
                    local closestArea = nil
                    local minDistance = math.huge
                    for _, areaName in pairs(areaList) do
                        local areaSuccess, areaPart = pcall(function()
                            return game:GetService("ReplicatedStorage").WorldModel.AreaMarkers[areaName]
                        end)
                        if areaSuccess and areaPart then
                            local areaPositionSuccess, areaPosition = pcall(function()
                                return areaPart.CFrame.Position
                            end)
                            if areaPositionSuccess and areaPosition then
                                print("Area position accessed for " .. areaName .. ": " .. tostring(areaPosition))
                                local distance = getDistance(instanceData.position, areaPosition)
                                if distance < minDistance then
                                    minDistance = distance
                                    closestArea = areaName
                                end
                            else
                                print("Failed to get CFrame.Position for Area: " .. areaName)
                            end
                        end
                    end
                    if closestArea then
                        local areaKey = npcName .. "," .. closestArea
                        if not seenAreaForNPC[areaKey] then
                            seenAreaForNPC[areaKey] = true
                            table.insert(npcList, npcName .. ", " .. closestArea)
                            table.insert(TweenFullList, npcName .. ", " .. closestArea)
                            print("Added NPC: " .. npcName .. ", " .. closestArea)
                        else
                            print("Skipped duplicate NPC in same area: " .. npcName .. ", " .. closestArea)
                        end
                    else
                        table.insert(npcList, npcName)
                        table.insert(TweenFullList, npcName)
                    end
                else
                    table.insert(npcList, npcName)
                    table.insert(TweenFullList, npcName)
                end
            end
        end
    end
end

-- Fetch specified NPCs from TownMarkers
local successTowns, townFolders = pcall(function()
    return game:GetService("ReplicatedStorage").TownMarkers:GetChildren()
end)
if successTowns then
    local seenTownNPC = {} -- Track {folderName, partName} to avoid duplicate NPCs in same folder
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
                        local townKey = folderName .. "," .. partName
                        if not seenTownNPC[townKey] then
                            seenTownNPC[townKey] = true
                            table.insert(npcList, formattedName)
                            table.insert(TweenFullList, formattedName)
                            print("Added Town NPC: " .. formattedName)
                        else
                            print("Skipped duplicate Town NPC in same folder: " .. formattedName)
                        end
                    end
                end
            end
        end
    end
end

-- Sort lists for consistency (case-insensitive)
table.sort(areaList, function(a, b) return string.lower(a) < string.lower(b) end)
table.sort(npcList, function(a, b) return string.lower(a) < string.lower(b) end)
table.sort(TweenFullList, function(a, b) return string.lower(a) < string.lower(b) end)

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
            filteredValues = TweenFullList
        end

        local areaValues = {}
        local npcValues = {}
        for _, item in pairs(filteredValues) do
            if table.find(areaList, item) then
                table.insert(areaValues, item)
            elseif table.find(npcList, item) then
                table.insert(npcValues, item)
            end
        end

        pcall(function()
            Options.Areas:SetValues(areaValues)
            Options.NPCs:SetValues(npcValues)
        end)

        pcall(function()
            if #areaValues > 0 and (Options.Areas.Value == "" or not table.find(areaValues, Options.Areas.Value)) then
                Options.Areas:SetValue(areaValues[1])
            elseif #areaValues == 0 then
                Options.Areas:SetValue("")
            end
        end)
        pcall(function()
            if #npcValues > 0 and (Options.NPCs.Value == "" or not table.find(npcValues, Options.NPCs.Value)) then
                Options.NPCs:SetValue(npcValues[1])
            elseif #npcValues == 0 then
                Options.NPCs:SetValue("")
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

local MainGroup4 = Tabs.Main:AddLeftGroupbox("Removal")
MainGroup4:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
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
                                nameText.Text = player.Name
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





--Attach to back Module [TESTING STILL]



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
