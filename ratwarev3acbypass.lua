if _G.RatwareLoaded then
    Library:Unload()
    return
end
_G.RatwareLoaded = true

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe - 100% Made By ChatGPT [Press 'Insert' to hide GUI]",
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
    Text = "No Clip",
    Default = false
}):AddKeyPicker("NoclipKeybind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.NoclipToggle:SetValue(value)
    end
})

local MainGroup1 = Tabs.Main:AddLeftGroupbox("Removal")
MainGroup1:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false
})

-- Moderator Notifier GUI
local ModeratorsGroup = Tabs.Main:AddRightGroupbox("Moderators")
ModeratorsGroup:AddToggle("ModeratorNotifierToggle", {
    Text = "Moderator Notifier",
    Default = true,
    Tooltip = "Shows a popup when moderators are in the server",
    Callback = function(value)
        pcall(function()
            _G.toggleModeratorNotifier(value)
            print("[Moderator Notifier GUI] Toggle set to: " .. tostring(value))
        end)
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
MainGroup6:AddSlider("ATBHeight", {
    Text = "Height",
    Default = 0,
    Min = -100,
    Max = 100,
    Rounding = 0,
    Compact = true
})
MainGroup6:AddSlider("ATBDistance)", {
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
    platform.Size = Vector3.new(30, 5, 30)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1.00
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

--Attach to back Module [TESTING STILL]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Internal state
local targetPlayer = nil
local isAttached = false
local attachConn = nil
local isTweening = false
local isLocked = false
local flyEnabled = false
local flyPlatform = nil
local bodyVelocity = nil
local flyConn = nil
local noclipEnabled = false
local nofallEnabled = false
local nofallFolder = nil
local heightOffset = 0 -- Matches ATBHeight default
local zDistance = -4 -- Updated default
local originalSpeed = 150
local messageDebounce = false
local currentTween = nil
local updateCoroutine = nil

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

-- Fly logic
local function enableFly()
    local success, result = pcall(function()
        if flyEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char or not safeGet(char, "HumanoidRootPart") then return false end
        flyEnabled = true
        flyPlatform = Instance.new("Part")
        flyPlatform.Name = "OldDebris"
        flyPlatform.Size = Vector3.new(6, 1, 6)
        flyPlatform.Anchored = true
        flyPlatform.CanCollide = true
        flyPlatform.Transparency = 0.75
        flyPlatform.Material = Enum.Material.SmoothPlastic
        flyPlatform.BrickColor = BrickColor.new("Bright blue")
        flyPlatform.Parent = workspace
        flyPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = char.HumanoidRootPart
        local humanoid = safeGet(char, "Humanoid")
        if humanoid then
            humanoid.JumpPower = 0
        end
        flyConn = RunService.RenderStepped:Connect(function()
            local hrp = safeGet(char, "HumanoidRootPart")
            if flyPlatform and hrp then
                flyPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
            end
        end)
        return true
    end)
    if not success then
        warn("Failed to enable fly: " .. tostring(result))
    end
    return success and result
end

local function disableFly()
    local success, result = pcall(function()
        if not flyEnabled then return true end
        flyEnabled = false
        if flyConn then
            flyConn:Disconnect()
            flyConn = nil
        end
        if flyPlatform then
            flyPlatform:Destroy()
            flyPlatform = nil
        end
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if char then
            local humanoid = safeGet(char, "Humanoid")
            if humanoid then
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16
            end
        end
        return true
    end)
    if not success then
        warn("Failed to disable fly: " .. tostring(result))
    end
    return success and result
end

-- Nofall logic
local function enableNofall()
    local success, result = pcall(function()
        if nofallEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char then return false end
        local status = safeGet(char, "Status")
        if not status then
            status = Instance.new("Folder")
            status.Name = "Status"
            status.Parent = char
        end
        if not status:FindFirstChild("FallDamageCD") then
            nofallFolder = Instance.new("Folder")
            nofallFolder.Name = "FallDamageCD"
            nofallFolder.Parent = status
        else
            nofallFolder = status:FindFirstChild("FallDamageCD")
        end
        nofallEnabled = true
        return true
    end)
    if not success then
        warn("Failed to enable nofall: " .. tostring(result))
    end
    return success and result
end

local function disableNofall()
    local success, result = pcall(function()
        if not nofallEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char then return true end
        local status = safeGet(char, "Status")
        if status then
            local fd = status:FindFirstChild("FallDamageCD")
            if fd then fd:Destroy() end
        end
        nofallEnabled = false
        nofallFolder = nil
        return true
    end)
    if not success then
        warn("Failed to disable nofall: " .. tostring(result))
    end
    return success and result
end

-- Noclip logic
local function enableNoclip()
    local success, result = pcall(function()
        if noclipEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char then return false end
        noclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
        return true
    end)
    if not success then
        warn("Failed to enable noclip: " .. tostring(result))
    end
    return success and result
end

local function disableNoclip()
    local success, result = pcall(function()
        if not noclipEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char then return true end
        noclipEnabled = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
        return true
    end)
    if not success then
        warn("Failed to disable noclip: " .. tostring(result))
    end
    return success and result
end

-- Tween logic
local function tweenToBack()
    if isTweening or isLocked then return false end
    isTweening = true
    local success, result = pcall(function()
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        local targetChar = targetPlayer and Workspace.Living:FindFirstChild(targetPlayer.Name)
        local hrp = char and safeGet(char, "HumanoidRootPart")
        local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
        if not (hrp and targetHrp) then return false end
        local distance = (hrp.Position - targetHrp.Position).Magnitude
        if distance > 20000 then return false end
        enableFly()
        enableNofall()
        enableNoclip()
        local function createTween()
            local backGoal = targetHrp.CFrame * CFrame.new(0, heightOffset, -zDistance) -- Reversed direction
            local tweenTime = distance / originalSpeed
            currentTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
            currentTween:Play()
        end
        createTween()
        updateCoroutine = coroutine.create(function()
            while isTweening do
                task.wait(1)
                if not isTweening then break end
                if currentTween then
                    currentTween:Cancel()
                end
                targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
                if not targetHrp then break end
                distance = (hrp.Position - targetHrp.Position).Magnitude
                createTween()
            end
        end)
        coroutine.resume(updateCoroutine)
        currentTween.Completed:Wait()
        isLocked = true
        isTweening = false
        disableFly()
        disableNoclip()
        return true
    end)
    if not success then
        warn("Tween failed: " .. tostring(result))
        isTweening = false
        disableFly()
        disableNoclip()
    end
    return success and result
end

-- Attach/Detach logic
local function stopAttach()
    local success, result = pcall(function()
        isAttached = false
        isLocked = false
        isTweening = false
        if attachConn then
            attachConn:Disconnect()
            attachConn = nil
        end
        if updateCoroutine then
            coroutine.close(updateCoroutine)
            updateCoroutine = nil
        end
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        disableNofall()
        disableNoclip()
        disableFly()
        return true
    end)
    if not success then
        warn("Failed to stop attach: " .. tostring(result))
    end
    return success and result
end

local function startAttach()
    local success, result = pcall(function()
        if not targetPlayer then
            if not messageDebounce then
                messageDebounce = true
                messagebox("Please select a player first!", "Error", 0)
                task.delay(2, function()
                    messageDebounce = false
                end)
            end
            return false
        end
        stopAttach()
        isAttached = true
        enableNofall()
        tweenToBack()
        attachConn = RunService.RenderStepped:Connect(function()
            if not isAttached then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            local targetChar = targetPlayer and Workspace.Living:FindFirstChild(targetPlayer.Name)
            local hrp = char and safeGet(char, "HumanoidRootPart")
            local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
            if not (hrp and targetHrp) then
                stopAttach()
                return
            end
            local distance = (hrp.Position - targetHrp.Position).Magnitude
            if distance > 100 then
                isLocked = false
                isTweening = false
                return
            end
            if isLocked then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, heightOffset, -zDistance) -- Reversed direction
            elseif not isTweening then
                tweenToBack()
            end
        end)
        return true
    end)
    if not success then
        warn("Failed to start attach: " .. tostring(result))
        stopAttach()
    end
    return success and result
end

-- Linoria GUI integration
local success, result = pcall(function()
    -- Ensure clean initial state
    local success, _ = pcall(function()
        disableNofall()
        disableNoclip()
        disableFly()
        return true
    end)
    if not success then
        warn("Failed to ensure clean initial state")
    end

    -- Player dropdown
    Options.PlayerDropdown:OnChanged(function(value)
        local success, _ = pcall(function()
            targetPlayer = value and Players:FindFirstChild(value) or nil
            if isAttached and not targetPlayer then
                stopAttach()
            end
            return true
        end)
        if not success then
            warn("Failed to update target player")
        end
    end)

    -- Toggle
    Toggles.AttachtobackToggle:OnChanged(function(value)
        local success, _ = pcall(function()
            if value then
                startAttach()
            else
                stopAttach()
            end
            return true
        end)
        if not success then
            warn("Failed to toggle attach")
        end
    end)

    -- Height slider
    Options.ATBHeight:OnChanged(function(value)
        local success, _ = pcall(function()
            heightOffset = value
            return true
        end)
        if not success then
            warn("Failed to update height offset")
        end
    end)

    -- Distance slider
    Options["ATBDistance)"]:OnChanged(function(value)
        local success, _ = pcall(function()
            zDistance = value
            return true
        end)
        if not success then
            warn("Failed to update distance")
        end
    end)

    -- Re-apply on respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        local success, _ = pcall(function()
            if isAttached then
                enableNofall()
                if not isLocked then
                    enableNoclip()
                    enableFly()
                end
            else
                disableNofall()
                disableNoclip()
                disableFly()
            end
            return true
        end)
        if not success then
            warn("Failed to handle character respawn")
        end
    end)

    -- Cleanup when local player leaves
    LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local success, _ = pcall(function()
                stopAttach()
                return true
            end)
            if not success then
                warn("Failed to clean up on leave")
            end
        end
    end)

    -- Handle player leave
    Players.PlayerRemoving:Connect(function(player)
        local success, _ = pcall(function()
            if player == targetPlayer then
                targetPlayer = nil
                stopAttach()
                Options.PlayerDropdown:SetValue(nil)
            end
            return true
        end)
        if not success then
            warn("Failed to handle player removing")
        end
    end)

    return true
end)

if not success then
    warn("Setup failed: " .. tostring(result))
end

-- Moderator Notifier Module
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local MonitoredUsers = {
        {userId = , username = "", roleName = "Ratware.exe"},
        {userId = 116279325, username = "MichaelpizzaXD", roleName = "Developers"},
        {userId = 101557551, username = "MlgArcOfOz", roleName = "Developers"},
        {userId = 66885812, username = "MiniTomBomb", roleName = "Developers"},
        {userId = 151823512, username = "KrackenLackin", roleName = "Developers"},
        {userId = 7098519935, username = "RoguebloxHolder", roleName = "Community Manager"},
        {userId = 23898168, username = "LordDogeus", roleName = "Community Manager"},
        {userId = 508010705, username = "bs4b", roleName = "Secret Tester"},
        {userId = 2348176237, username = "Ropbloxd", roleName = "Secret Tester"},
        {userId = 101472496, username = "IWish4Food", roleName = "Secret Tester"},
        {userId = 137156947, username = "clownmesh", roleName = "Secret Tester"},
        {userId = 91088194, username = "snadwich_man", roleName = "Secret Tester"},
        {userId = 5639568198, username = "antilocapras", roleName = "Secret Tester"},
        {userId = 2739168703, username = "MinusEightSilver", roleName = "Secret Tester"},
        {userId = 2203438314, username = "MoonfullBliss", roleName = "Secret Tester"},
        {userId = 83568697, username = "xavierqwl123", roleName = "Secret Tester"},
        {userId = 886895436, username = "FlibbetFlobbet", roleName = "Secret Tester"},
        {userId = 454125614, username = "DaveCombat", roleName = "Secret Tester"},
        {userId = 2253843707, username = "Gatemaster159", roleName = "Secret Tester"},
        {userId = 400064133, username = "FrickTaco", roleName = "Secret Tester"},
        {userId = 4467110029, username = "MurderMaster02_4", roleName = "Secret Tester"},
        {userId = 1584543391, username = "DemankIes", roleName = "Secret Tester"},
        {userId = 545676359, username = "Magno_1725", roleName = "Secret Tester"},
        {userId = 1198202820, username = "Watersheepgod123", roleName = "Secret Tester"},
        {userId = 50531342, username = "j_xhnny", roleName = "Secret Tester"},
        {userId = 466307225, username = "GameAwesome128", roleName = "Secret Tester"},
        {userId = 2627739850, username = "OneLifeSuper", roleName = "Secret Tester"},
        {userId = 8355205283, username = "mrGIANTviking", roleName = "Secret Tester"},
        {userId = 684490283, username = "Falmsas", roleName = "Secret Tester"},
        {userId = 96606405, username = "xxstarshooterxx1", roleName = "Secret Tester"},
        {userId = 537619474, username = "fenaerii", roleName = "Secret Tester"},
        {userId = 409518603, username = "Floof_Fully", roleName = "Secret Tester"},
        {userId = 211211867, username = "TomelessX", roleName = "Secret Tester"},
        {userId = 2311317483, username = "Liutzia", roleName = "Secret Tester"},
        {userId = 15147688, username = "RuneArtifact", roleName = "Secret Tester"},
        {userId = 839001197, username = "Miraelith", roleName = "Secret Tester"},
        {userId = 4025386553, username = "SheepInSheepSkinRBX", roleName = "Secret Tester"},
        {userId = 920566, username = "eld", roleName = "Secret Tester"},
        {userId = 9160671302, username = "Dinglenutjohnson3rd", roleName = "Secret Tester"},
        {userId = 390617393, username = "rarex00x", roleName = "Secret Tester"},
        {userId = 167343092, username = "fastdogekid", roleName = "Secret Tester"},
        {userId = 9185362166, username = "Dinglenutjohnson4th", roleName = "Secret Tester"},
        {userId = 476747151, username = "Gorgus_Official", roleName = "Secret Tester"},
        {userId = 46354252, username = "Ijazezane", roleName = "Senior Moderator"},
        {userId = 172863828, username = "Valerame3", roleName = "Senior Moderator"},
        {userId = 71517753, username = "upbeatbidachi", roleName = "Senior Moderator"},
        {userId = 56632783, username = "Coletrayne", roleName = "The Hydra"},
        {userId = 6056339939, username = "NotAhmi4", roleName = "Junior Moderator"},
        {userId = 475990670, username = "blzz4rd", roleName = "Junior Moderator"},
        {userId = 1834007574, username = "MintyKobold", roleName = "Junior Moderator"},
        {userId = 1745860240, username = "AstralZix", roleName = "Junior Moderator"},
        {userId = 985681917, username = "PikaNubby", roleName = "Junior Moderator"},
        {userId = 33242043, username = "piercingTYB", roleName = "Junior Moderator"},
        {userId = 83742361, username = "0utcastGhost", roleName = "Junior Moderator"},
        {userId = 3761770969, username = "MogaApht", roleName = "Moderator"},
        {userId = 472265489, username = "NicoCTR", roleName = "Moderator"},
        {userId = 1443529743, username = "RetroFungi", roleName = "Moderator"},
        {userId = 132854348, username = "Luci_Lucid", roleName = "Moderator"},
        {userId = 97857665, username = "PacificState", roleName = "Moderator"},
        {userId = 178196494, username = "iSuikazu", roleName = "Moderator"},
        {userId = 1814937056, username = "psyych1c", roleName = "Moderator"},
        {userId = 98475312, username = "mooshoo0629", roleName = "Moderator"},
        {userId = 88734055, username = "Umbraheim", roleName = "Moderator"},
        {userId = 105477497, username = "mosquirt04x", roleName = "Moderator"},
        {userId = 98823832, username = "Tooleria", roleName = "Moderator"},
        {userId = 750126545, username = "MikeBikiCiki", roleName = "Moderator"},
        {userId = 2482521968, username = "kronksdonks", roleName = "Moderator"},
        {userId = 494876909, username = "NightFumi", roleName = "Moderator"},
        {userId = 368760757, username = "hadarqki", roleName = "Moderator"},
        {userId = 1325204143, username = "JordyVibing", roleName = "Moderator"},
        {userId = 296471697, username = "ThugFuny", roleName = "Moderator"},
        {userId = 1230105665, username = "savefloppa", roleName = "Moderator"},
        {userId = 94943072, username = "2qrys", roleName = "Co-Owner"},
        {userId = 568447733, username = "VortexLineZ", roleName = "Tester"},
        {userId = 288068260, username = "Fruchtriegel", roleName = "Tester"},
        {userId = 2067212412, username = "2v1mee", roleName = "Tester"},
        {userId = 177841301, username = "Xdancjoz", roleName = "Tester"},
        {userId = 541694484, username = "Sayumiko_Inubashiri", roleName = "Tester"},
        {userId = 200296369, username = "kir_bu", roleName = "Tester"},
        {userId = 105642986, username = "Spikedaniel1", roleName = "Tester"},
        {userId = 118232953, username = "Acroze_0", roleName = "Tester"},
        {userId = 2272201650, username = "gamergodH8", roleName = "Tester"},
        {userId = 1391134999, username = "Voayn", roleName = "Tester"},
        {userId = 591754050, username = "Ftwnitro", roleName = "Tester"},
        {userId = 94377328, username = "Adome1000", roleName = "Tester"},
        {userId = 328804443, username = "minipixel37", roleName = "Tester"},
        {userId = 1721299790, username = "AisarRedux", roleName = "Tester"},
        {userId = 443301913, username = "BaconFlakesFoLife", roleName = "Tester"},
        {userId = 1525954431, username = "king_req2", roleName = "Tester"},
        {userId = 164659205, username = "YugoEliatrope", roleName = "Tester"},
        {userId = 109880601, username = "kazuhirawillow", roleName = "Tester"},
        {userId = 1255232483, username = "D7X37", roleName = "Tester"},
        {userId = 3072563956, username = "AMONGOlDS", roleName = "Tester"},
        {userId = 60501176, username = "A_SpoopyPixel", roleName = "Tester"},
        {userId = 1538684653, username = "v4mp6vrl", roleName = "Tester"},
        {userId = 95115478, username = "Apocalytra", roleName = "Tester"},
        {userId = 171849433, username = "pumpkinmoo06", roleName = "Tester"},
        {userId = 238689577, username = "XK4nekiX", roleName = "Tester"},
        {userId = 3134234164, username = "BoubaStep", roleName = "Tester"},
        {userId = 64146960, username = "Jayden080811", roleName = "Tester"},
        {userId = 936850490, username = "Arkomis", roleName = "Tester"},
        {userId = 75576146, username = "RubloxProster", roleName = "Tester"},
        {userId = 1301594729, username = "AscendingO", roleName = "Tester"},
        {userId = 1593663486, username = "levvenooo", roleName = "Tester"},
        {userId = 1183277097, username = "QAZWERTZU", roleName = "Tester"},
        {userId = 119813128, username = "ASFNIN10DO", roleName = "Tester"},
        {userId = 55978613, username = "Eir_6", roleName = "Tester"},
        {userId = 1810420170, username = "YataaMirror", roleName = "Tester"},
        {userId = 295400019, username = "NordFraey", roleName = "Tester"},
        {userId = 50923052, username = "FarmerTommi", roleName = "Tester"},
        {userId = 1857182681, username = "dreamdemonz", roleName = "Tester"},
        {userId = 147290047, username = "Akuma321123", roleName = "Tester"},
        {userId = 1462759064, username = "Swusshy", roleName = "Tester"},
        {userId = 696449051, username = "gamer_lits", roleName = "Tester"},
        {userId = 1213458167, username = "xXLyr_icalXx", roleName = "Tester"},
        {userId = 3309856286, username = "Altey_z", roleName = "Tester"},
        {userId = 677421053, username = "Glarpys", roleName = "Tester"},
        {userId = 556687212, username = "Zawzeu", roleName = "Tester"},
        {userId = 121334527, username = "coolsnakez", roleName = "Tester"},
        {userId = 136103834, username = "david50high", roleName = "Tester"},
        {userId = 121138965, username = "onajimi", roleName = "Tester"},
        {userId = 2029492895, username = "AstonishingAdvantage", roleName = "Tester"},
        {userId = 84902083, username = "EquinoxLeech", roleName = "Tester"},
        {userId = 118368051, username = "GalaxyDudeNinja1", roleName = "Tester"},
        {userId = 1546714877, username = "Hollodron04x", roleName = "Tester"},
        {userId = 2040850419, username = "asuraispog1", roleName = "Tester"},
        {userId = 48317343, username = "T4ktical", roleName = "Tester"},
        {userId = 792994343, username = "ptl483", roleName = "Tester"},
        {userId = 5905225, username = "firestarfeyfire", roleName = "Tester"},
        {userId = 113363377, username = "a23way", roleName = "Tester"},
        {userId = 64827712, username = "DatBoiOmon_e", roleName = "Tester"},
        {userId = 304468388, username = "realityticks", roleName = "Tester"},
        {userId = 119948127, username = "miasmers", roleName = "Tester"},
        {userId = 1258601659, username = "Dr_BruhMoment", roleName = "Tester"},
        {userId = 2643269, username = "meteorshower", roleName = "Tester"},
        {userId = 302306519, username = "dontay1796", roleName = "Tester"},
        {userId = 1279850752, username = "xxxBenjidabeastxxx", roleName = "Tester"},
        {userId = 2980417565, username = "AutoGamezzzzYT", roleName = "Tester"},
        {userId = 15400033, username = "eliciety", roleName = "Tester"},
        {userId = 1209943600, username = "rinacavemanoogabooga", roleName = "Tester"},
        {userId = 2791735478, username = "kajuxas42", roleName = "Tester"},
        {userId = 45805731, username = "Julsons", roleName = "Tester"},
        {userId = 85752191, username = "Blaketerraria", roleName = "Tester"},
        {userId = 139532477, username = "goodteam5", roleName = "Tester"},
        {userId = 171068753, username = "bucketcube_d", roleName = "Tester"},
        {userId = 128562610, username = "nongnine2549", roleName = "Tester"},
        {userId = 121096035, username = "l4zy_b0i", roleName = "Tester"},
        {userId = 3234444804, username = "Poorabar", roleName = "Tester"},
        {userId = 87667744, username = "melovesonic", roleName = "Tester"},
        {userId = 154551041, username = "BrownSun_flower", roleName = "Tester"},
        {userId = 2702542109, username = "FallionsGurlFriend", roleName = "Tester"},
        {userId = 244275943, username = "boptodatop", roleName = "Tester"},
        {userId = 618526197, username = "0charliee", roleName = "Tester"},
        {userId = 85696426, username = "piknishi", roleName = "Tester"},
        {userId = 27243005, username = "kal_vo", roleName = "Tester"},
        {userId = 259956393, username = "synthosize0", roleName = "Tester"},
        {userId = 25419739, username = "dough_jkl", roleName = "Tester"},
        {userId = 384554889, username = "N1GHT_R", roleName = "Tester"},
        {userId = 521426118, username = "SanctifiedSeraph", roleName = "Tester"},
        {userId = 3217076177, username = "TheMelodicBlu", roleName = "Tester"},
        {userId = 2707242978, username = "BensRogueLineageGaia", roleName = "Tester"},
        {userId = 139151151, username = "NorwoodScale", roleName = "Tester"},
        {userId = 2910654, username = "Ryrasil", roleName = "Tester"},
        {userId = 764944189, username = "joshhuahgamin", roleName = "Tester"},
        {userId = 116102814, username = "XyeurianDemascus", roleName = "Tester"},
        {userId = 217341439, username = "Derekjwd000", roleName = "Tester"},
        {userId = 766793221, username = "m_iini", roleName = "Tester"},
        {userId = 1187943190, username = "U_nknownEA", roleName = "Tester"},
        {userId = 16773526, username = "Tentorian", roleName = "Tester"},
        {userId = 668171947, username = "Inganlovemas1", roleName = "Tester"},
        {userId = 996597352, username = "drewsk_i", roleName = "Tester"},
        {userId = 2794059824, username = "LostalImysanity", roleName = "Tester"},
        {userId = 4536767005, username = "B1lankss", roleName = "Tester"},
        {userId = 383110716, username = "tavavayj", roleName = "Tester"},
        {userId = 1229151960, username = "Shadow_2474", roleName = "Tester"},
        {userId = 156133047, username = "2L15m", roleName = "Tester"},
        {userId = 2957030770, username = "FishNecromancer", roleName = "Tester"},
        {userId = 78138248, username = "awri3785", roleName = "Tester"},
        {userId = 1337469163, username = "Jojoactor626", roleName = "Tester"},
        {userId = 143360462, username = "Prxnce_Tulip", roleName = "Tester"},
        {userId = 530841328, username = "jackthesmith1901", roleName = "Tester"},
        {userId = 41972028, username = "SalmonSmasher", roleName = "Tester"},
        {userId = 187318758, username = "Mikey_2017", roleName = "Tester"},
        {userId = 3079251025, username = "Kitt_ard", roleName = "Tester"},
        {userId = 123065424, username = "deaxfoom", roleName = "Tester"},
        {userId = 1881210431, username = "flxffed", roleName = "Tester"},
        {userId = 79802728, username = "cadas0123a", roleName = "Tester"},
        {userId = 292024748, username = "idskuchiha", roleName = "Tester"},
        {userId = 497491742, username = "Tarzan20070", roleName = "Tester"},
        {userId = 1867852294, username = "iFallens", roleName = "Tester"},
        {userId = 159347179, username = "anchqor", roleName = "Tester"},
        {userId = 1712209259, username = "SeverTheSkylines", roleName = "Tester"},
        {userId = 3540079828, username = "navurns", roleName = "Tester"},
        {userId = 103459910, username = "XmanZogratis", roleName = "Tester"},
        {userId = 534197831, username = "Doritochip46", roleName = "Tester"},
        {userId = 185019792, username = "survivor2111", roleName = "Tester"},
        {userId = 127596422, username = "XionOH", roleName = "Tester"},
        {userId = 1553967784, username = "jamalissostupid", roleName = "Tester"},
        {userId = 304438466, username = "sg0y", roleName = "Tester"},
        {userId = 683752651, username = "InfinityMemez", roleName = "Tester"},
        {userId = 2350139151, username = "lokkqrave", roleName = "Tester"},
        {userId = 31921665, username = "TonyLikesRice", roleName = "Tester"},
        {userId = 126159866, username = "hisbrat", roleName = "Tester"},
        {userId = 36577164, username = "yawa400", roleName = "Tester"},
        {userId = 66378169, username = "MegacraftBuilder", roleName = "Tester"},
        {userId = 55471665, username = "blitz5468", roleName = "Tester"},
        {userId = 77890505, username = "Vae1yx", roleName = "Tester"},
        {userId = 157133351, username = "bIastiin", roleName = "Tester"},
        {userId = 446816519, username = "RokkuZum", roleName = "Tester"},
        {userId = 3441461569, username = "SleepyJingle", roleName = "Tester"},
        {userId = 130175745, username = "lomi26", roleName = "Tester"},
        {userId = 2585457105, username = "Jeusant", roleName = "Tester"},
        {userId = 68831624, username = "LmaoOreoz", roleName = "Tester"},
        {userId = 485468501, username = "rCaptainChaos", roleName = "Tester"},
        {userId = 2879483125, username = "CTB_Akashi", roleName = "Tester"},
        {userId = 163387406, username = "maximilianotony", roleName = "Tester"},
        {userId = 2789875252, username = "Alternate_EEE", roleName = "Tester"},
        {userId = 319436867, username = "Nicholasharry", roleName = "Tester"},
        {userId = 72409843, username = "LuauBread", roleName = "Tester"},
        {userId = 2556168630, username = "bulletproofpickle", roleName = "Tester"},
        {userId = 981026482, username = "BlenderDemon", roleName = "Tester"},
        {userId = 200170674, username = "XElit3Killer42X", roleName = "Tester"},
        {userId = 2978393899, username = "hai250512", roleName = "Tester"},
        {userId = 523307562, username = "BoyNamedElite", roleName = "Tester"},
        {userId = 305108529, username = "Gavin1621", roleName = "Tester"},
        {userId = 122012377, username = "LAA1233", roleName = "Tester"},
        {userId = 43564517, username = "Sagee4", roleName = "Tester"},
        {userId = 167592863, username = "Foxtrot_Burst", roleName = "Tester"},
        {userId = 170516141, username = "o_Oooxy", roleName = "Tester"},
        {userId = 722595047, username = "Paheemala", roleName = "Tester"},
        {userId = 121156347, username = "ShinmonSan", roleName = "Tester"},
        {userId = 2035294938, username = "rentakkj", roleName = "Tester"},
        {userId = 135312065, username = "chunchbunch", roleName = "Tester"},
        {userId = 952327584, username = "Fayelligent", roleName = "Tester"},
        {userId = 908078373, username = "OkamiyourgodYT", roleName = "Tester"},
        {userId = 4742716911, username = "ScrollOfFloresco", roleName = "Tester"},
        {userId = 72585073, username = "Sn_1pz", roleName = "Tester"},
        {userId = 5112604479, username = "singlemother36", roleName = "Tester"},
        {userId = 810330156, username = "Silv3y", roleName = "Tester"},
        {userId = 35014890, username = "OGStr8", roleName = "Tester"},
        {userId = 33143240, username = "d_avidd", roleName = "Tester"},
        {userId = 231640937, username = "halokiller892", roleName = "Tester"},
        {userId = 42379546, username = "AnbuKen", roleName = "Tester"},
        {userId = 1087856074, username = "tdawg5445", roleName = "Tester"},
        {userId = 201726743, username = "FastThunderDragon123", roleName = "Tester"},
        {userId = 104355703, username = "ii_Justice", roleName = "Tester"},
        {userId = 192257017, username = "Dandado", roleName = "Tester"},
        {userId = 3296935891, username = "nickhax123", roleName = "Tester"},
        {userId = 232494686, username = "Guardbabi", roleName = "Tester"},
        {userId = 3248951452, username = "Jacey_pp", roleName = "Tester"},
        {userId = 287218312, username = "christianisthebest9", roleName = "Tester"},
        {userId = 19026337, username = "neogi", roleName = "Tester"},
        {userId = 1520636666, username = "AnbuK3n", roleName = "Tester"},
        {userId = 339253441, username = "hooyadaddddyyy", roleName = "Tester"},
        {userId = 1889658724, username = "AnbuKane", roleName = "Tester"},
        {userId = 275644813, username = "Brytheous", roleName = "Tester"},
        {userId = 1092798493, username = "SkyNiOmni", roleName = "Tester"},
        {userId = 1090317348, username = "rosomig", roleName = "Tester"},
        {userId = 85953824, username = "MrBonkDonk", roleName = "Tester"},
        {userId = 99149580, username = "fireshatter", roleName = "Tester"},
        {userId = 153296461, username = "HardGoldenPolarBear", roleName = "Tester"},
        {userId = 973488825, username = "malusinha_doida", roleName = "Tester"},
        {userId = 149066591, username = "rexepoyt", roleName = "Tester"},
        {userId = 158002164, username = "SkillessDev", roleName = "Tester"},
        {userId = 866972473, username = "blendergod99", roleName = "Tester"},
        {userId = 4155040838, username = "hollywoodcolex", roleName = "Tester"},
        {userId = 516378013, username = "Forg3dx", roleName = "Tester"},
        {userId = 7314301709, username = "MalevolentKaioshin", roleName = "Tester"},
        {userId = 73215632, username = "upperment", roleName = "Tester"},
        {userId = 12452343, username = "thecool19", roleName = "Tester"},
        {userId = 227228547, username = "xxxxbastionxxxx", roleName = "Tester"},
        {userId = 706176524, username = "Eriiku", roleName = "Tester"},
        {userId = 106663853, username = "wizard407", roleName = "Tester"},
        {userId = 1567623135, username = "Altaccount030306", roleName = "Tester"},
        {userId = 286410421, username = "lightempero", roleName = "Tester"},
        {userId = 2271508534, username = "DragonBallGoku_BR493", roleName = "Tester"},
        {userId = 1830547188, username = "AstralFourteen", roleName = "Tester"},
        {userId = 306788398, username = "BriarValkyr", roleName = "Tester"},
        {userId = 553272836, username = "Sylvefied", roleName = "Tester"}
    }
    local UserCache = {} -- Cache: {UserId = {username, roleName}}
    local NotificationGui = nil
    local NotificationLabel = nil
    local IsMonitoring = false
    local MonitorConn = nil

    local function safeGet(obj, ...)
        local args = {...}
        for i, v in ipairs(args) do
            local ok, res = pcall(function() return obj[v] end)
            if not ok then
                print("[Moderator Notifier] safeGet failed for " .. tostring(v) .. ": " .. tostring(res))
                return nil
            end
            obj = res
            if not obj then
                print("[Moderator Notifier] safeGet returned nil for " .. tostring(v))
                return nil
            end
        end
        return obj
    end

    local function createNotificationGui()
        if NotificationGui then
            NotificationGui:Destroy()
        end
        NotificationGui = Instance.new("ScreenGui")
        NotificationGui.Name = "ModeratorNotifierGui"
        NotificationGui.Parent = game:GetService("CoreGui")
        NotificationGui.IgnoreGuiInset = true
        NotificationGui.Enabled = false

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 60) -- Smaller popup size
        frame.Position = UDim2.new(0.5, -100, 0.1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = NotificationGui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = frame

        NotificationLabel = Instance.new("TextLabel")
        NotificationLabel.Size = UDim2.new(1, -10, 1, -10)
        NotificationLabel.Position = UDim2.new(0, 5, 0, 5)
        NotificationLabel.BackgroundTransparency = 1
        NotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Default, will be overridden
        NotificationLabel.TextScaled = true
        NotificationLabel.TextWrapped = true
        NotificationLabel.Font = Enum.Font.SourceSans
        NotificationLabel.Text = ""
        NotificationLabel.Parent = frame
    end

    local function getPlayerRole(player)
        if not player then return nil end
        if UserCache[player.UserId] then
            -- Update username from player object to ensure it's current
            UserCache[player.UserId].username = player.Name
            print("[Moderator Notifier] Using cached role for " .. player.Name .. ": " .. tostring(UserCache[player.UserId].roleName))
            return UserCache[player.UserId]
        end
        for _, user in ipairs(MonitoredUsers) do
            if user.userId == player.UserId then
                UserCache[player.UserId] = {username = player.Name, roleName = user.roleName}
                print("[Moderator Notifier] Found role for " .. player.Name .. ": " .. user.roleName .. " (UserId " .. user.userId .. ")")
                return UserCache[player.UserId]
            end
        end
        UserCache[player.UserId] = {username = player.Name, roleName = "None"}
        return nil
    end

    local function updateNotification()
        local rolePlayers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local role = getPlayerRole(player)
                if role then
                    table.insert(rolePlayers, "Warning, " .. role.roleName .. " Detected: " .. player.Name)
                end
            end
        end
        if #rolePlayers > 0 then
            if not NotificationGui then
                createNotificationGui()
            end
            NotificationGui.Enabled = true
            NotificationLabel.TextColor3 = Color3.fromRGB(255, 20, 20) -- Neon red
            NotificationLabel.Text = table.concat(rolePlayers, "\n")
            print("[Moderator Notifier] Notification shown: " .. NotificationLabel.Text)
        else
            if not NotificationGui then
                createNotificationGui()
            end
            NotificationGui.Enabled = true
            NotificationLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Neon green
            NotificationLabel.Text = "Safe, No Detected Users"
            print("[Moderator Notifier] No moderators, notification set to safe")
        end
    end

    local function startMonitoring()
        if IsMonitoring then
            print("[Moderator Notifier] Monitoring already active")
            return
        end
        IsMonitoring = true
        print("[Moderator Notifier] Starting monitoring")
        updateNotification()
        MonitorConn = Players.PlayerAdded:Connect(function(player)
            pcall(function()
                if player == LocalPlayer then return end
                local role = getPlayerRole(player)
                if role then
                    updateNotification()
                end
                print("[Moderator Notifier] Player added: " .. player.Name)
            end)
        end)
        Players.PlayerRemoving:Connect(function(player)
            pcall(function()
                if player == LocalPlayer then return end
                UserCache[player.UserId] = nil
                if getPlayerRole(player) then
                    updateNotification()
                end
                print("[Moderator Notifier] Player removed: " .. player.Name)
            end)
        end)
    end

    local function stopMonitoring()
        if not IsMonitoring then
            print("[Moderator Notifier] Monitoring not active")
            return
        end
        IsMonitoring = false
        if MonitorConn then
            MonitorConn:Disconnect()
            MonitorConn = nil
        end
        if NotificationGui then
            NotificationGui:Destroy()
            NotificationGui = nil
            NotificationLabel = nil
        end
        UserCache = {}
        print("[Moderator Notifier] Stopped monitoring")
    end

    _G.toggleModeratorNotifier = function(value)
        pcall(function()
            print("[Moderator Notifier] Toggle changed to: " .. tostring(value))
            if value then
                startMonitoring()
            else
                stopMonitoring()
            end
        end)
    end

    game:BindToClose(function()
        pcall(function()
            stopMonitoring()
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
