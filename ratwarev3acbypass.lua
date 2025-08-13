if _G.RatwareLoaded then
    Library:Unload()
    return
end
_G.RatwareLoaded = true

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
MainGroup:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false
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

-- Tween control variables
local areaTweenActive = false
local npcTweenActive = false

-- Helper function to get target position
local function getTargetPosition(selection, isNPC)
    local targetPos = nil
    pcall(function()
        if isNPC then
            local npcName, areaName = selection:match("^(.-), (.+)$")
            if npcName and areaName then
                -- Handle TownMarkers NPCs
                local townFolder = game:GetService("ReplicatedStorage").TownMarkers:FindFirstChild(npcName)
                if townFolder then
                    local part = townFolder:FindFirstChild(areaName)
                    if part then
                        targetPos = part.CFrame.Position -- Use partName's CFrame.Position
                    end
                else
                    -- Handle Workspace NPCs
                    local npcs = game:GetService("Workspace").NPCs:GetChildren()
                    for _, npc in pairs(npcs) do
                        if npc.Name == npcName then
                            local closestArea = nil
                            local minDistance = math.huge
                            local npcPos = npc.WorldPivot.Position or npc.CFrame.Position
                            for _, area in pairs(game:GetService("ReplicatedStorage").WorldModel.AreaMarkers:GetChildren()) do
                                local distance = getDistance(npcPos, area.CFrame.Position)
                                if distance < minDistance then
                                    minDistance = distance
                                    closestArea = area.Name
                                end
                            end
                            if closestArea == areaName then
                                targetPos = npcPos
                                break
                            end
                        end
                    end
                end
            else
                -- Single instance NPC
                local npcs = game:GetService("Workspace").NPCs:GetChildren()
                for _, npc in pairs(npcs) do
                    if npc.Name == selection then
                        targetPos = npc.WorldPivot.Position or npc.CFrame.Position
                        break
                    end
                end
            end
        else
            -- Area position
            local areaPart = game:GetService("ReplicatedStorage").WorldModel.AreaMarkers:FindFirstChild(selection)
            if areaPart then
                targetPos = areaPart.CFrame.Position
            end
        end
    end)
    return targetPos
end

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
    Compact = true,
    Callback = function(value)
        pcall(function()
            _G.Speed = value
        end)
    end
})

MainGroup3:AddDropdown("Areas", {
    Text = "Areas",
    Default = "",
    Values = areaList,
    Multi = false
})

MainGroup3:AddButton("Area Tween Start/Stop", function()
    pcall(function()
        if npcTweenActive then
            Library:Notify("NPC tween in progress. Stop NPC tween and try again.", { Duration = 3 })
            return
        end
        if Options.Areas.Value == "" then
            Library:Notify("No area selected.", { Duration = 3 })
            return
        end
        areaTweenActive = not areaTweenActive
        if areaTweenActive then
            local targetPos = getTargetPosition(Options.Areas.Value, false)
            if targetPos then
                _G.CustomTween(targetPos)
            else
                Library:Notify("Failed to get area position.", { Duration = 3 })
                areaTweenActive = false
            end
        else
            _G.StopTween()
        end
    end)
end)

MainGroup3:AddDropdown("NPCs", {
    Text = "NPCs",
    Default = "",
    Values = npcList,
    Multi = false
})

MainGroup3:AddButton("NPC Tween Start/Stop", function()
    pcall(function()
        if areaTweenActive then
            Library:Notify("Area tween in progress. Stop Area tween and try again.", { Duration = 3 })
            return
        end
        if Options.NPCs.Value == "" then
            Library:Notify("No NPC selected.", { Duration = 3 })
            return
        end
        npcTweenActive = not npcTweenActive
        if npcTweenActive then
            local targetPos = getTargetPosition(Options.NPCs.Value, true)
            if targetPos then
                _G.CustomTween(targetPos)
            else
                Library:Notify("Failed to get NPC position.", { Duration = 3 })
                npcTweenActive = false
            end
        else
            _G.StopTween()
        end
    end)
end)

-- Monitor for tween stop to update flags
game:GetService("RunService").Heartbeat:Connect(function()
    if not _G.tweenActive then
        areaTweenActive = false
        npcTweenActive = false
    end
end)

local MainGroup6 = Tabs.Main:AddLeftGroupbox("Rage")
MainGroup6:AddDropdown('PlayerDropdown', {
    SpecialType = 'Player',
    Text = 'Select Player',
    Tooltip = 'Attach to [Selected Username]',
    Callback = function(Value)
        pcall(function()
            targetPlayer = Players:FindFirstChild(Value)
            print('[cb] Player dropdown got changed:', Value)
        end)
    end
})
MainGroup6:AddToggle("AttachtobackToggle", {
    Text = "Attach To Back",
    Default = false,
    Callback = function(Value)
        pcall(function()
            if Value then
                startAttach()
            else
                stopAttach()
            end
        end)
    end
}):AddKeyPicker("Attachtobackbind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.AttachtobackToggle:SetValue(value)
    end
})
MainGroup6:AddSlider("ATBHeight", {
    Text = "Height",
    Default = 0,
    Min = -100,
    Max = 100,
    Rounding = 0,
    Compact = true
})
MainGroup6:AddSlider("ATBDistance", {
    Text = "Distance",
    Default = -3,
    Min = -100,
    Max = 100,
    Rounding = 0,
    Compact = true
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
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Speedhack Module
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
        end)
    end

    local function cleanupSpeed()
        pcall(function()
            resetSpeed()
            BodyVelocity:Destroy()
            print("[Speedhack] Cleaned up at " .. os.date("%H:%M:%S"))
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
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
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
                    local speed = math.min(Options.SpeedhackSpeed.Value, 49 / dt)
                    speed = speed * (0.95 + math.random() * 0.1) -- Randomize speed slightly
                    BodyVelocity.Velocity = dir * speed
                    BodyVelocity.Parent = char.HumanoidRootPart
                    char.Humanoid.JumpPower = 0
                else
                    resetSpeed()
                end
            end)
        end)
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
                end)
            end)
        else
            print("[Speedhack] Warning: Toggles.FlightToggle not found")
        end
    end)
end)

-- Fly/Flight Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer

    local Platform = Instance.new("Part")
    Platform.Size = Vector3.new(6, 1, 6)
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Transparency = 0.75
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
                    local speed = math.min(Options.FlightSpeed.Value, 49 / dt)
                    speed = speed * (0.95 + math.random() * 0.1) -- Randomize speed slightly
                    FlyVelocity.Velocity = moveDir * speed + Vector3.new(0, vert, 0)
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
    pcall(function()
        if Toggles.SpeedhackToggle then
            Toggles.SpeedhackToggle:OnChanged(function(value)
                pcall(function()
                    if not value and Toggles.FlightToggle.Value then
                        Toggles.FlightToggle:SetValue(false)
                        task.wait(0.1)
                        Toggles.FlightToggle:SetValue(true)
                    end
                end)
            end)
        end
    end)
end)

-- Noclip Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

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
        end)
    end

    pcall(function()
        if player.Character and Toggles.NoclipToggle.Value then
            setCollision(false)
            print("[Noclip] Enabled for existing character")
        end
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
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
            end)
        end)
    end)
end)

-- No Fall Damage Module
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
                if fallFolder and fallFolder.Parent then
                    fallFolder:Destroy()
                end
                fallFolder = Instance.new("Folder")
                fallFolder.Name = "FallDamageCD"
                fallFolder.Archivable = true
                fallFolder.Parent = status
            else
                if fallFolder and fallFolder.Parent then
                    fallFolder:Destroy()
                end
                fallFolder = nil
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
                if Toggles.NoFallDamage.Value then
                    setNoFall(true)
                else
                    setNoFall(false)
                end
            end)
        end)
    end)

    game:BindToClose(function()
        pcall(function()
            if fallFolder then
                fallFolder:Destroy()
            end
        end)
    end)
end)

-- Player ESP Module
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
                    pcall(function() if typeof(obj) == "userdata" and obj.Remove then obj:Remove() end end)
                end
            end
            pcall(function() ESPObjects[player] = nil end)
        end
    end

    local function createESP(player)
        if player == LocalPlayer then return end
        pcall(function()
            if ESPObjects[player] then cleanupESP(player) end

            local boxLines = {}
            for i = 1, 4 do
                local line = Drawing.new("Line")
                line.Visible = false
                line.Thickness = 2
                line.Color = Color3.fromRGB(255, 25, 25)
                table.insert(boxLines, line)
            end

            local nameText = Drawing.new("Text")
            nameText.Size = 14
            nameText.Center = true
            nameText.Outline = true
            nameText.Color = Color3.fromRGB(255, 255, 255)
            nameText.Visible = false

            local healthText = Drawing.new("Text")
            healthText.Size = 13
            healthText.Center = true
            healthText.Outline = true
            healthText.Color = Color3.fromRGB(0, 255, 0)
            healthText.Visible = false

            local distText = Drawing.new("Text")
            distText.Size = 13
            distText.Center = true
            distText.Outline = true
            distText.Color = Color3.fromRGB(200, 200, 200)
            distText.Visible = false

            local chamBox = Drawing.new("Square")
            chamBox.Visible = false
            chamBox.Color = Color3.fromRGB(255, 0, 0)
            chamBox.Transparency = 0.2
            chamBox.Filled = true

            ESPObjects[player] = {
                BoxLines = boxLines,
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
                    local boxLines, nameText, healthText, distText, chamBox
                    pcall(function()
                        boxLines = tbl.BoxLines
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
                            pcall(function()
                                chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                                chamBox.Size = Vector2.new(width, height)
                                chamBox.Color = Color3.fromRGB(255, 0, 0)
                                chamBox.Transparency = 0.15
                                chamBox.Visible = true
                            end)

                            local topLeft = Vector2.new(topW.X - width/2, topW.Y)
                            local topRight = Vector2.new(topW.X + width/2, topW.Y)
                            local botLeft = Vector2.new(botW.X - width/2, botW.Y)
                            local botRight = Vector2.new(botW.X + width/2, botW.Y)

                            boxLines[1].From = topLeft
                            boxLines[1].To = topRight
                            boxLines[2].From = topLeft
                            boxLines[2].To = botLeft
                            boxLines[3].From = topRight
                            boxLines[3].To = botRight
                            boxLines[4].From = botLeft
                            boxLines[4].To = botRight

                            for _, line in ipairs(boxLines) do
                                line.Visible = true
                            end

                            pcall(function()
                                nameText.Text = player.Name
                                nameText.Position = Vector2.new(pos.X, topW.Y - 16)
                                nameText.Visible = true
                            end)

                            pcall(function()
                                healthText.Text = "[" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
                                healthText.Position = Vector2.new(pos.X, topW.Y - 2)
                                local r = math.floor(255 - 255 * (health/maxHealth))
                                local g = math.floor(255 * (health/maxHealth))
                                healthText.Color = Color3.fromRGB(r, g, 0)
                                healthText.Visible = true
                            end)

                            pcall(function()
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                distText.Text = "[" .. math.floor(dist) .. "m]"
                                distText.Position = Vector2.new(pos.X, botW.Y + 2)
                                distText.Visible = true
                            end)

                            drawSkeleton(player, char, Color3.fromRGB(255,255,255), 2)
                        else
                            for _, line in ipairs(boxLines or {}) do
                                line.Visible = false
                            end
                            pcall(function() nameText.Visible = false end)
                            pcall(function() healthText.Visible = false end)
                            pcall(function() distText.Visible = false end)
                            pcall(function() chamBox.Visible = false end)
                            if tbl.Skeleton then
                                for _, line in pairs(tbl.Skeleton) do
                                    pcall(function() line.Visible = false end)
                                end
                            end
                        end
                    else
                        for _, line in ipairs(boxLines or {}) do
                            line.Visible = false
                        end
                        pcall(function() nameText.Visible = false end)
                        pcall(function() healthText.Visible = false end)
                        pcall(function() distText.Visible = false end)
                        pcall(function() chamBox.Visible = false end)
                        if tbl.Skeleton then
                            for _, line in pairs(tbl.Skeleton) do
                                pcall(function() line.Visible = false end)
                            end
                        end
                    end
                end)
            end
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

    print("[ESP] Script initialized at " .. os.date("%H:%M:%S"))
end)

-- Universal Tween & Location
pcall(function()
    repeat
        task.wait()
    until game:IsLoaded()
    repeat
        task.wait()
    until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local players = game:GetService("Players")
    local rs = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")

    _G.originalspeed = 150
    _G.Speed = _G.originalspeed
    local flyEnabled = false
    local flyActive = false
    local noclipEnabled = false
    local noclipActive = false
    local nofallEnabled = false
    local originalCollideStates = {}

    local function resetHumanoidState()
        pcall(function()
            if players.LocalPlayer.Character and players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = players.LocalPlayer.Character.Humanoid
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16
            end
        end)
    end

    local platform = Instance.new("Part")
    platform.Name = "OldDebris"
    platform.Size = Vector3.new(10, 1, 10)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.75
    platform.Material = Enum.Material.SmoothPlastic
    platform.BrickColor = BrickColor.new("Bright blue")

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        repeat
            task.wait()
        until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
        pcall(function()
            if flyEnabled or _G.tweenActive then
                character.Humanoid.JumpPower = 0
                platform.Parent = workspace
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
                toggleNoclip(true)
                if Toggles.NoFallDamage.Value then
                    toggleNofall(true)
                end
            else
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
        end)
    end)

    local function toggleFly(enable)
        pcall(function()
            flyEnabled = enable
            if enable then
                local character = players.LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.JumpPower = 0
                end
                platform.Parent = workspace
                if character and character:FindFirstChild("HumanoidRootPart") then
                    platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                    bodyVelocity.Parent = character.HumanoidRootPart
                end
            else
                resetHumanoidState()
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
        end)
    end

    local function resetNoClip()
        pcall(function()
            if players.LocalPlayer.Character then
                for _, part in pairs(players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end
            for part, canCollide in pairs(originalCollideStates) do
                if part and part.Parent then
                    pcall(function() part.CanCollide = canCollide end)
                end
            end
            originalCollideStates = {}
        end)
    end

    local function toggleNoclip(enable)
        pcall(function()
            noclipEnabled = enable
            local character = players.LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = not enable end)
                    end
                end
            end
            if not enable then
                resetNoClip()
            end
        end)
    end

    local fallDamageCD = nil
    local statusFolder = game.Workspace:WaitForChild("Living"):WaitForChild(players.LocalPlayer.Name):WaitForChild("Status")

    local function toggleNofall(enable)
        pcall(function()
            if enable then
                if fallDamageCD and fallDamageCD.Parent then
                    fallDamageCD:Destroy()
                end
                fallDamageCD = Instance.new("Folder")
                fallDamageCD.Name = "FallDamageCD"
                fallDamageCD.Archivable = true
                fallDamageCD.Parent = statusFolder
            else
                if fallDamageCD and fallDamageCD.Parent then
                    fallDamageCD:Destroy()
                end
                fallDamageCD = nil
            end
            nofallEnabled = enable
        end)
    end

    _G.tweenActive = false
    _G.tweenPhase = 0
    _G.highAltitude = 0
    _G.tweenTarget = Vector3.new(0, 0, 0)
    local currentTween = nil

    local function createTween(targetPos, duration)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if currentTween then
                currentTween:Cancel()
            end
            currentTween = TweenService:Create(
                hrp,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(targetPos)}
            )
            currentTween:Play()
        end)
    end

    rs.RenderStepped:Connect(function(delta)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")

            if flyEnabled and character and humanoid and hrp then
                flyActive = true
                local moveDirection = Vector3.zero
                if _G.tweenActive then
                    if _G.tweenPhase == 1 then
                        local targetY = _G.highAltitude
                        local distance = targetY - hrp.Position.Y
                        if distance > 1 then
                            createTween(Vector3.new(hrp.Position.X, targetY, hrp.Position.Z), distance / _G.Speed)
                        else
                            _G.tweenPhase = 2
                        end
                    elseif _G.tweenPhase == 2 then
                        local highTarget = Vector3.new(_G.tweenTarget.X, _G.highAltitude, _G.tweenTarget.Z)
                        local distance = (highTarget - hrp.Position).Magnitude
                        if distance > 5 then
                            createTween(highTarget, distance / _G.Speed)
                        else
                            _G.tweenPhase = 3
                        end
                    elseif _G.tweenPhase == 3 then
                        local targetY = _G.tweenTarget.Y
                        local distance = hrp.Position.Y - targetY
                        if distance > 5 then
                            createTween(Vector3.new(hrp.Position.X, targetY, hrp.Position.Z), distance / _G.Speed)
                        else
                            _G.tweenActive = false
                            _G.tweenPhase = 0
                            toggleFly(false)
                            toggleNoclip(false)
                            if not Toggles.NoFallDamage.Value then
                                toggleNofall(false)
                            end
                        end
                    end
                end
                bodyVelocity.Velocity = moveDirection
                humanoid.JumpPower = 0
                platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
                platform.Parent = workspace
                if humanoid.Health <= 0 then
                    Library:Notify("Character Dead, Please Try Again", { Duration = 3 })
                    resetHumanoidState()
                    _G.tweenActive = false
                    _G.tweenPhase = 0
                    flyEnabled = false
                    flyActive = false
                    platform.Parent = nil
                    bodyVelocity.Parent = nil
                    toggleNoclip(false)
                    if not Toggles.NoFallDamage.Value then
                        toggleNofall(false)
                    end
                end
            else
                if flyActive then
                    resetHumanoidState()
                    flyActive = false
                    platform.Parent = nil
                    bodyVelocity.Parent = nil
                end
            end

            if noclipEnabled and character and hrp then
                noclipActive = true
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = false end)
                    end
                end
                local region = workspace:FindPartsInRegion3(Region3.new(hrp.Position - Vector3.new(20, 20, 20), hrp.Position + Vector3.new(20, 20, 20)))
                for _, part in pairs(region) do
                    if part:IsA("BasePart") and part ~= hrp and part ~= platform then
                        if not originalCollideStates[part] then
                            originalCollideStates[part] = part.CanCollide
                        end
                        pcall(function() part.CanCollide = false end)
                    end
                end
            else
                if noclipActive then
                    resetNoClip()
                    noclipActive = false
                end
            end
        end)
    end)

    _G.CustomTween = function(target)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local distance = (target - hrp.Position).Magnitude
            if distance > 20000 then
                Library:Notify("Target too far away!", { Duration = 3 })
                return
            end
            toggleNoclip(true)
            toggleNofall(true)
            toggleFly(true)
            _G.tweenTarget = target
            _G.highAltitude = hrp.Position.Y + 500
            _G.tweenPhase = 1
            _G.tweenActive = true
        end)
    end

    _G.StopTween = function()
        pcall(function()
            _G.tweenActive = false
            _G.tweenPhase = 0
            toggleFly(false)
            toggleNoclip(false)
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y > 50 and Toggles.NoFallDamage.Value then
                toggleNofall(true) -- Ensure no fall damage if high up and toggle is on
            elseif not Toggles.NoFallDamage.Value then
                toggleNofall(false)
            end
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
        end)
    end

    game:BindToClose(function()
        pcall(function()
            _G.StopTween()
            bodyVelocity:Destroy()
            if fallDamageCD then fallDamageCD:Destroy() end
        end)
    end)
end)

-- Attach to Back Module
pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    _G.targetPlayer = nil
    _G.isAttached = false
    local attachConn = nil
    local isTweening = false
    local isLocked = false
    local originalSpeed = 150

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

    local function tweenToBack()
        if isTweening or isLocked then return false end
        isTweening = true
        local success, result = pcall(function()
            local char = LocalPlayer.Character
            local targetChar = _G.targetPlayer and _G.targetPlayer.Character
            local hrp = char and safeGet(char, "HumanoidRootPart")
            local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
            if not (hrp and targetHrp) then
                Library:Notify("Failed to find player or target character!", { Duration = 3 })
                print("[Attach to Back] Tween failed: Missing HRP or target HRP")
                return false
            end
            local distance = (hrp.Position - targetHrp.Position).Magnitude
            if distance > 20000 then
                Library:Notify("Target too far away!", { Duration = 3 })
                print("[Attach to Back] Tween failed: Target too far (" .. distance .. ")")
                return false
            end
            _G.toggleNoclip(true)
            _G.toggleNofall(true)
            local backGoal = targetHrp.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBDistance.Value)
            local tweenTime = distance / originalSpeed
            local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
            tween:Play()
            tween.Completed:Wait()
            isLocked = true
            isTweening = false
            _G.toggleNoclip(false)
            print("[Attach to Back] Tween completed, locked to target")
            return true
        end)
        if not success then
            warn("[Attach to Back] Tween failed: " .. tostring(result))
            isTweening = false
            _G.toggleNoclip(false)
        end
        return success and result
    end

    _G.stopAttach = function()
        local success, result = pcall(function()
            _G.isAttached = false
            isLocked = false
            isTweening = false
            if attachConn then
                attachConn:Disconnect()
                attachConn = nil
            end
            _G.toggleNofall(false)
            _G.toggleNoclip(false)
            Library:Notify("Attach to Back stopped.", { Duration = 3 })
            print("[Attach to Back] Stopped attach")
            return true
        end)
        if not success then
            warn("[Attach to Back] Failed to stop attach: " .. tostring(result))
        end
        return success and result
    end

    _G.startAttach = function()
        local success, result = pcall(function()
            if not _G.targetPlayer then
                Library:Notify("Please select a player first!", { Duration = 3 })
                Toggles.AttachtobackToggle:SetValue(false)
                print("[Attach to Back] Failed: No target player selected")
                return false
            end
            local targetChar = _G.targetPlayer.Character
            if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
                Library:Notify("Target player has no character!", { Duration = 3 })
                Toggles.AttachtobackToggle:SetValue(false)
                print("[Attach to Back] Failed: Target has no character or HRP")
                return false
            end
            _G.stopAttach()
            _G.isAttached = true
            _G.toggleNofall(true)
            tweenToBack()
            attachConn = RunService.RenderStepped:Connect(function()
                if not _G.isAttached then return end
                local char = LocalPlayer.Character
                local targetChar = _G.targetPlayer and _G.targetPlayer.Character
                local hrp = char and safeGet(char, "HumanoidRootPart")
                local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
                if not (hrp and targetHrp) then
                    _G.stopAttach()
                    Toggles.AttachtobackToggle:SetValue(false)
                    Library:Notify("Target player lost or character missing!", { Duration = 3 })
                    print("[Attach to Back] Stopped: Missing HRP or target HRP")
                    return
                end
                local distance = (hrp.Position - targetHrp.Position).Magnitude
                if distance > 100 then
                    isLocked = false
                    isTweening = false
                    print("[Attach to Back] Distance too large (" .. distance .. "), unlocking")
                    return
                end
                if isLocked then
                    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBDistance.Value)
                elseif not isTweening then
                    tweenToBack()
                end
            end)
            Library:Notify("Attach to Back started for " .. _G.targetPlayer.Name, { Duration = 3 })
            print("[Attach to Back] Started for " .. _G.targetPlayer.Name)
            return true
        end)
        if not success then
            warn("[Attach to Back] Failed to start attach: " .. tostring(result))
            _G.stopAttach()
        end
        return success and result
    end

    -- Initialize PlayerDropdown with current players
    pcall(function()
        local playerList = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(playerList, plr.Name)
            end
        end
        table.sort(playerList, function(a, b) return string.lower(a) < string.lower(b) end)
        Options.PlayerDropdown:SetValues(playerList)
        print("[Attach to Back] PlayerDropdown initialized with:", table.concat(playerList, ", "))
    end)

    -- GUI Integration
    Options.PlayerDropdown:OnChanged(function(value)
        local success, _ = pcall(function()
            _G.targetPlayer = value and Players:FindFirstChild(value) or nil
            if _G.isAttached and not _G.targetPlayer then
                _G.stopAttach()
                Toggles.AttachtobackToggle:SetValue(false)
            end
            print("[Attach to Back] PlayerDropdown changed to:", value or "nil")
            return true
        end)
        if not success then
            warn("[Attach to Back] Failed to update target player")
        end
    end)

    Toggles.AttachtobackToggle:OnChanged(function(value)
        local success, _ = pcall(function()
            if value then
                _G.startAttach()
            else
                _G.stopAttach()
            end
            return true
        end)
        if not success then
            warn("[Attach to Back] Failed to toggle attach")
        end
    end)

    Players.PlayerAdded:Connect(function(plr)
        pcall(function()
            if plr == LocalPlayer then return end
            local playerList = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    table.insert(playerList, p.Name)
                end
            end
            table.sort(playerList, function(a, b) return string.lower(a) < string.lower(b) end)
            Options.PlayerDropdown:SetValues(playerList)
            print("[Attach to Back] Player added (" .. plr.Name .. "), updated dropdown:", table.concat(playerList, ", "))
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        pcall(function()
            if player == _G.targetPlayer then
                _G.targetPlayer = nil
                _G.stopAttach()
                Options.PlayerDropdown:SetValue("")
                Library:Notify("Target player left the game!", { Duration = 3 })
                print("[Attach to Back] Target (" .. player.Name .. ") left, stopped attach")
            end
            local playerList = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    table.insert(playerList, plr.Name)
                end
            end
            table.sort(playerList, function(a, b) return string.lower(a) < string.lower(b) end)
            Options.PlayerDropdown:SetValues(playerList)
            print("[Attach to Back] Player removed (" .. player.Name .. "), updated dropdown:", table.concat(playerList, ", "))
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(char)
        pcall(function()
            repeat task.wait() until char:FindFirstChild("HumanoidRootPart")
            if _G.isAttached then
                _G.toggleNofall(true)
                if not isLocked then
                    _G.toggleNoclip(true)
                end
                print("[Attach to Back] Character respawned, maintaining attach state")
            else
                _G.toggleNofall(false)
                _G.toggleNoclip(false)
            end
        end)
    end)

    game:BindToClose(function()
        pcall(function()
            _G.stopAttach()
        end)
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
