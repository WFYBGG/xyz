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
MainGroup:AddToggle("SwimStatusToggle", {
    Text = "Anti-AA Bypass",
    Default = false
}):AddKeyPicker("SwimStatusBind", {
    Default = "",
    Mode = "Toggle",
    Text = "N/A",
    Callback = function(value)
        Toggles.SwimStatusToggle:SetValue(value)
    end
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
MainGroup1:AddToggle("DisableCharacterTouchToggle", {
    Text = "No Killbricks",
    Default = false
})

-- Moderator Notifier GUI
local NotificationsGroup = Tabs.Main:AddRightGroupbox("Notifications")
NotificationsGroup:AddToggle("ModeratorNotifierToggle", {
    Text = "Moderator Notifier",
    Default = false,
    Tooltip = "Shows a popup when moderators are in the server",
    Callback = function(value)
        pcall(function()
            _G.toggleModeratorNotifier(value)
            print("[Moderator Notifier GUI] Toggle set to: " .. tostring(value))
        end)
    end
})
-- Auto Kick GUI
pcall(function()
    NotificationsGroup:AddToggle("AutoKickToggle", {
        Text = "Auto Kick on Detection",
        Default = false,
        Tooltip = "Kicks you from the game if Developers, Community Managers, Moderators, or The Hydra are detected",
        Callback = function(value)
            pcall(function()
                _G.toggleAutoKick(value)
                print("[Auto Kick GUI] Toggle set to: " .. tostring(value))
            end)
        end
    })
end)

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

    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    BodyVelocity.Name = "SpeedhackVelocity"

    local function resetSpeed()
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = 50
                BodyVelocity.Parent = nil
            end
        end)
    end

    local function cleanupSpeed()
        pcall(function()
            resetSpeed()
            BodyVelocity:Destroy()
        end)
    end

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            local timeout = tick() + 5
            while not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) and tick() < timeout do
                task.wait()
            end
            if not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) then
                return
            end
            resetSpeed() -- Ensure clean state on respawn
            if Toggles.SpeedhackToggle.Value and not (Toggles.AttachtobackToggle.Value or _G.tweenActive) then
                BodyVelocity.Parent = character.HumanoidRootPart
                character.Humanoid.JumpPower = 0
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function(dt)
            pcall(function()
                local char = player.Character
                if Toggles.SpeedhackToggle.Value and char and char:FindFirstChild("HumanoidRootPart") and not (Toggles.AttachtobackToggle.Value or _G.tweenActive) then
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= workspace.CurrentCamera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += workspace.CurrentCamera.CFrame.RightVector end
                    dir = dir.Magnitude > 0 and dir.Unit or Vector3.zero
                    local speed = math.min(Options.SpeedhackSpeed.Value, 49 / dt)
                    speed = speed * (0.95 + math.random() * 0.1)
                    BodyVelocity.Velocity = dir * speed
                    BodyVelocity.Parent = char.HumanoidRootPart
                    char.Humanoid.JumpPower = 0
                else
                    resetSpeed()
                end
            end)
        end)
    end)

    pcall(function()
        Toggles.SpeedhackToggle:OnChanged(function(value)
            pcall(function()
                if value and (Toggles.FlightToggle.Value or Toggles.AttachtobackToggle.Value or _G.tweenActive) then
                    Toggles.SpeedhackToggle:SetValue(false)
                    Library:Notify("Cannot enable Speedhack with Fly, Attach to Back, or Tween active.", { Duration = 3 })
                    return
                end
                if not value then
                    resetSpeed()
                end
            end)
        end)
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
            local timeout = tick() + 5
            while not (char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) and tick() < timeout do
                task.wait()
            end
            resetFly() -- Ensure clean state on respawn
            if Toggles.FlightToggle.Value and not (Toggles.AttachtobackToggle.Value or _G.tweenActive) then
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
                if Toggles.FlightToggle.Value and char and char:FindFirstChild("HumanoidRootPart") and not (Toggles.AttachtobackToggle.Value or _G.tweenActive) then
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
                    speed = speed * (0.95 + math.random() * 0.1)
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

    pcall(function()
        Toggles.FlightToggle:OnChanged(function(value)
            pcall(function()
                if value and (Toggles.SpeedhackToggle.Value or Toggles.AttachtobackToggle.Value or _G.tweenActive) then
                    Toggles.FlightToggle:SetValue(false)
                    Library:Notify("Cannot enable Fly with Speedhack, Attach to Back, or Tween active.", { Duration = 3 })
                    return
                end
                if not value then
                    resetFly()
                end
            end)
        end)
    end)
end)

-- Noclip Module
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local function setCollision(state)
        pcall(function()
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = state
                    end
                end
            end
        end)
    end

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            local timeout = tick() + 5
            while not character:FindFirstChild("HumanoidRootPart") and tick() < timeout do
                task.wait()
            end
            if not character:FindFirstChild("HumanoidRootPart") then
                return
            end
            setCollision(true) -- Ensure collision is enabled on respawn
            if Toggles.NoclipToggle.Value then
                setCollision(false)
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                if Toggles.NoclipToggle.Value then
                    setCollision(false)
                else
                    setCollision(true)
                end
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
            local timeout = tick() + 5
            while not Workspace:FindFirstChild("Living") and tick() < timeout do
                task.wait()
            end
            setNoFall(Toggles.NoFallDamage.Value)
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

-- No Killbricks/Disable Touch Module
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local isEnabled = false
    local affectedParts = {}
    local characterConn = nil

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

    local function disableCharacterTouch()
        pcall(function()
            local char = safeGet(LocalPlayer, "Character")
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if (part:IsA("BasePart") or part:IsA("MeshPart")) and not affectedParts[part] then
                    local success, canTouch = pcall(function() return part.CanTouch end)
                    if success then
                        affectedParts[part] = canTouch
                        part.CanTouch = false
                    end
                end
            end
        end)
    end

    local function restoreCharacterTouch()
        pcall(function()
            for part, originalCanTouch in pairs(affectedParts) do
                if part and part.Parent then
                    part.CanTouch = originalCanTouch
                end
            end
            affectedParts = {}
        end)
    end

    local function enableDisableTouch()
        pcall(function()
            if isEnabled then return end
            isEnabled = true
            disableCharacterTouch()
            if characterConn then
                characterConn:Disconnect()
            end
            characterConn = LocalPlayer.CharacterAdded:Connect(function()
                pcall(function()
                    task.wait(1)
                    if isEnabled then
                        disableCharacterTouch()
                    end
                end)
            end)
        end)
    end

    local function disableDisableTouch()
        pcall(function()
            if not isEnabled then return end
            isEnabled = false
            if characterConn then
                characterConn:Disconnect()
                characterConn = nil
            end
            restoreCharacterTouch()
        end)
    end

    pcall(function()
        Toggles.DisableCharacterTouchToggle:OnChanged(function(value)
            pcall(function()
                if value then
                    enableDisableTouch()
                else
                    disableDisableTouch()
                end
            end)
        end)
    end)
end)

-- Anti-AA Bypass/No Fire/Swim Status Module
pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local isEnabled = false
    local characterConn = nil

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

    local function fireSwimStatus(state)
        pcall(function()
            local remotes = safeGet(ReplicatedStorage, "Remotes")
            local mainRemote = remotes and safeGet(remotes, "Main")
            if mainRemote then
                mainRemote:FireServer("swim", state)
            end
        end)
    end

    local function enableSwimStatus()
        pcall(function()
            if isEnabled then return end
            isEnabled = true
            fireSwimStatus(true)
            if characterConn then
                characterConn:Disconnect()
            end
            characterConn = LocalPlayer.CharacterAdded:Connect(function()
                pcall(function()
                    task.wait(1)
                    if isEnabled then
                        fireSwimStatus(true)
                    end
                end)
            end)
        end)
    end

    local function disableSwimStatus()
        pcall(function()
            if not isEnabled then return end
            isEnabled = false
            fireSwimStatus(false)
            if characterConn then
                characterConn:Disconnect()
                characterConn = nil
            end
        end)
    end

    pcall(function()
        Toggles.SwimStatusToggle:OnChanged(function(value)
            pcall(function()
                if value then
                    enableSwimStatus()
                else
                    disableSwimStatus()
                end
            end)
        end)
    end)
end)

--Player ESP Module
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local ESPObjects = {}

    local function safeGet(parent, child)
        local result
        pcall(function()
            result = parent and child and parent:FindFirstChild(child)
        end)
        return result
    end

    local function getCharacterModel(player)
        local living
        pcall(function()
            living = workspace:FindFirstChild("Living")
        end)
        return living and safeGet(living, player.Name)
    end

    local function getHealthInfo(character)
        local health, maxHealth = 0, 100
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
        pcall(function()
            local tbl = ESPObjects[player]
            if tbl then
                for _, obj in pairs(tbl) do
                    if typeof(obj) == "table" then
                        for _, v in pairs(obj) do
                            pcall(function() if v.Remove then v:Remove() end end)
                        end
                    else
                        pcall(function() if obj.Remove then obj:Remove() end end)
                    end
                end
                ESPObjects[player] = nil
            end
        end)
    end

    local function createESP(player)
        if player == LocalPlayer then return end
        pcall(function()
            cleanupESP(player) -- Ensure clean state
            local box = Drawing.new("Line")
            box.Visible = false
            box.Thickness = 2
            box.Color = Color3.fromRGB(255, 25, 25)

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
                Box = box,
                Name = nameText,
                Health = healthText,
                Distance = distText,
                ChamBox = chamBox,
                Skeleton = {}
            }
        end)
    end

    local function drawSkeleton(player, char, color, thickness)
        local bones = {
            {"Head", "HumanoidRootPart"},
            {"HumanoidRootPart", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"HumanoidRootPart", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"},
            {"HumanoidRootPart", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"HumanoidRootPart", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"}
        }

        local skeleton = ESPObjects[player].Skeleton or {}
        for i, pair in ipairs(bones) do
            local part1, part2
            pcall(function()
                part1 = char:FindFirstChild(pair[1])
                part2 = char:FindFirstChild(pair[2])
            end)
            local line = skeleton[i] or Drawing.new("Line")
            if part1 and part2 then
                local pos1, onScr1 = Camera:WorldToViewportPoint(part1.Position)
                local pos2, onScr2 = Camera:WorldToViewportPoint(part2.Position)
                if onScr1 and onScr2 then
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    line.Color = color or Color3.fromRGB(255, 255, 255)
                    line.Thickness = thickness or 2
                    line.Visible = Toggles.PlayerESP.Value
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
            skeleton[i] = line
        end
        ESPObjects[player].Skeleton = skeleton
    end

    pcall(function()
        Players.PlayerAdded:Connect(function(plr)
            if plr ~= LocalPlayer then
                pcall(function() createESP(plr) end)
            end
        end)
    end)

    pcall(function()
        Players.PlayerRemoving:Connect(function(plr)
            pcall(function() cleanupESP(plr) end)
        end)
    end)

    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                pcall(function() createESP(plr) end)
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            local activePlayers = {}
            for player, tbl in pairs(ESPObjects) do
                activePlayers[player] = true
                pcall(function()
                    local char = getCharacterModel(player)
                    local box, nameText, healthText, distText, chamBox = tbl.Box, tbl.Name, tbl.Health, tbl.Distance, tbl.ChamBox
                    if char and safeGet(char, "HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        local health, maxHealth = getHealthInfo(char)
                        local extents = char:GetExtentsSize()
                        local topW, onScreen1 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, extents.Y/2, 0))
                        local botW, onScreen2 = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, extents.Y/2, 0))
                        local height = (botW.Y - topW.Y)
                        local width = height * 0.45

                        if Toggles.PlayerESP.Value and onScreen and onScreen1 and onScreen2 and health > 0 then
                            pcall(function()
                                chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                                chamBox.Size = Vector2.new(width, height)
                                chamBox.Visible = true
                            end)
                            pcall(function()
                                box.From = Vector2.new(topW.X - width/2, topW.Y)
                                box.To = Vector2.new(topW.X + width/2, topW.Y)
                                box.Visible = true
                            end)
                            pcall(function()
                                nameText.Text = player.Name
                                nameText.Position = Vector2.new(pos.X, topW.Y - 16)
                                nameText.Visible = true
                            end)
                            pcall(function()
                                healthText.Text = "[" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
                                healthText.Position = Vector2.new(pos.X, topW.Y - 2)
                                healthText.Color = Color3.fromRGB(math.floor(255 - 255 * (health/maxHealth)), math.floor(255 * (health/maxHealth)), 0)
                                healthText.Visible = true
                            end)
                            pcall(function()
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                distText.Text = "[" .. math.floor(dist) .. "m]"
                                distText.Position = Vector2.new(pos.X, botW.Y + 2)
                                distText.Visible = true
                            end)
                            drawSkeleton(player, char, Color3.fromRGB(255, 255, 255), 2)
                        else
                            pcall(function()
                                box.Visible = false
                                nameText.Visible = false
                                healthText.Visible = false
                                distText.Visible = false
                                chamBox.Visible = false
                                for _, line in pairs(tbl.Skeleton) do
                                    line.Visible = false
                                end
                            end)
                        end
                    else
                        pcall(function()
                            box.Visible = false
                            nameText.Visible = false
                            healthText.Visible = false
                            distText.Visible = false
                            chamBox.Visible = false
                            for _, line in pairs(tbl.Skeleton) do
                                line.Visible = false
                            end
                        end)
                    end
                end)
            end
            for player in pairs(ESPObjects) do
                if not Players:FindFirstChild(player.Name) then
                    cleanupESP(player)
                end
            end
        end)
    end)
end)

-- Universal Tween & Location
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer

    _G.originalspeed = 150
    _G.Speed = _G.originalspeed
    local flyEnabled = false
    local noclipEnabled = false
    local nofallEnabled = false
    local originalCollideStates = {}

    local platform = Instance.new("Part")
    platform.Name = "OldDebris"
    platform.Size = Vector3.new(6, 1, 6)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1.00
    platform.Material = Enum.Material.SmoothPlastic
    platform.BrickColor = BrickColor.new("Bright blue")

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)

    local function resetHumanoidState()
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpPower = 50
                char.Humanoid.WalkSpeed = 16
            end
        end)
    end

    local function toggleFly(enable)
        pcall(function()
            flyEnabled = enable
            local char = player.Character
            if enable and char and char:FindFirstChild("HumanoidRootPart") then
                char.Humanoid.JumpPower = 0
                platform.Parent = workspace
                platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                bodyVelocity.Parent = char.HumanoidRootPart
            else
                resetHumanoidState()
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
        end)
    end

    local function toggleNoclip(enable)
        pcall(function()
            noclipEnabled = enable
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = not enable
                    end
                end
            end
            if not enable then
                for part, canCollide in pairs(originalCollideStates) do
                    if part and part.Parent then
                        part.CanCollide = canCollide
                    end
                end
                originalCollideStates = {}
            end
        end)
    end

    local fallDamageCD = nil
    local function toggleNofall(enable)
        pcall(function()
            local status = workspace:WaitForChild("Living"):WaitForChild(player.Name):WaitForChild("Status")
            nofallEnabled = enable
            if enable then
                if fallDamageCD and fallDamageCD.Parent then
                    fallDamageCD:Destroy()
                end
                fallDamageCD = Instance.new("Folder")
                fallDamageCD.Name = "FallDamageCD"
                fallDamageCD.Archivable = true
                fallDamageCD.Parent = status
            else
                if fallDamageCD and fallDamageCD.Parent then
                    fallDamageCD:Destroy()
                end
                fallDamageCD = nil
            end
        end)
    end

    player.CharacterAdded:Connect(function(char)
        pcall(function()
            local timeout = tick() + 5
            while not (char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) and tick() < timeout do
                task.wait()
            end
            resetHumanoidState()
            if _G.tweenActive and not Toggles.AttachtobackToggle.Value then
                toggleFly(true)
                toggleNoclip(true)
                toggleNofall(true)
                char.Humanoid.JumpPower = 0
                platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                platform.Parent = workspace
                bodyVelocity.Parent = char.HumanoidRootPart
            else
                toggleFly(false)
                toggleNoclip(false)
                if not Toggles.NoFallDamage.Value then
                    toggleNofall(false)
                end
            end
        end)
    end)

    _G.tweenActive = false
    _G.tweenPhase = 0
    _G.highAltitude = 0
    _G.tweenTarget = Vector3.new(0, 0, 0)
    local currentTween = nil

    local function createTween(targetPos, duration)
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
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

    RunService.RenderStepped:Connect(function(delta)
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")

            if _G.tweenActive and char and humanoid and hrp and not Toggles.AttachtobackToggle.Value then
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
                bodyVelocity.Velocity = Vector3.zero
                humanoid.JumpPower = 0
                platform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0)
                platform.Parent = workspace
                if humanoid.Health <= 0 then
                    _G.tweenActive = false
                    _G.tweenPhase = 0
                    toggleFly(false)
                    toggleNoclip(false)
                    if not Toggles.NoFallDamage.Value then
                        toggleNofall(false)
                    end
                    platform.Parent = nil
                    bodyVelocity.Parent = nil
                end
            else
                if flyEnabled then
                    toggleFly(false)
                end
                if noclipEnabled then
                    toggleNoclip(false)
                end
            end
        end)
    end)

    _G.CustomTween = function(target)
        pcall(function()
            if Toggles.SpeedhackToggle.Value or Toggles.FlightToggle.Value or Toggles.AttachtobackToggle.Value then
                Library:Notify("Cannot start Tween with Speedhack, Fly, or Attach to Back active.", { Duration = 3 })
                return
            end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
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
            if not Toggles.NoFallDamage.Value then
                toggleNofall(false)
            end
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
        end)
    end
end)

--Attach to back Module [TESTING STILL]
pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

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
    local heightOffset = 0
    local zDistance = -3
    local originalSpeed = 150
    local messageDebounce = false
    local currentTween = nil
    local updateCoroutine = nil

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

    local function enableFly()
        pcall(function()
            if flyEnabled then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            if not char or not safeGet(char, "HumanoidRootPart") then return end
            flyEnabled = true
            flyPlatform = Instance.new("Part")
            flyPlatform.Name = "OldDebris"
            flyPlatform.Size = Vector3.new(6, 1, 6)
            flyPlatform.Anchored = true
            flyPlatform.CanCollide = true
            flyPlatform.Transparency = 1.00
            flyPlatform.Material = Enum.Material.SmoothPlastic
            flyPlatform.BrickColor = BrickColor.new("Bright blue")
            flyPlatform.Parent = workspace
            flyPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
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
                    flyPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0)
                end
            end)
        end)
    end

    local function disableFly()
        pcall(function()
            if not flyEnabled then return end
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
        end)
    end

    local function enableNofall()
        pcall(function()
            if nofallEnabled then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            if not char then return end
            local status = safeGet(char, "Status")
            if not status then
                status = Instance.new("Folder")
                status.Name = "Status"
                status.Parent = char
            end
            nofallFolder = status:FindFirstChild("FallDamageCD") or Instance.new("Folder")
            nofallFolder.Name = "FallDamageCD"
            nofallFolder.Parent = status
            nofallEnabled = true
        end)
    end

    local function disableNofall()
        pcall(function()
            if not nofallEnabled then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            if char then
                local status = safeGet(char, "Status")
                if status and status:FindFirstChild("FallDamageCD") then
                    status:FindFirstChild("FallDamageCD"):Destroy()
                end
            end
            nofallEnabled = false
            nofallFolder = nil
        end)
    end

    local function enableNoclip()
        pcall(function()
            if noclipEnabled then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            if not char then return end
            noclipEnabled = true
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function disableNoclip()
        pcall(function()
            if not noclipEnabled then return end
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            if not char then return end
            noclipEnabled = false
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end)
    end

    local function tweenToBack()
        pcall(function()
            if isTweening or isLocked then return end
            isTweening = true
            local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
            local targetChar = targetPlayer and Workspace.Living:FindFirstChild(targetPlayer.Name)
            local hrp = char and safeGet(char, "HumanoidRootPart")
            local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
            if not (hrp and targetHrp) then
                isTweening = false
                return
            end
            local distance = (hrp.Position - targetHrp.Position).Magnitude
            if distance > 20000 then
                isTweening = false
                return
            end
            enableFly()
            enableNofall()
            enableNoclip()
            local function createTween()
                local backGoal = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
                local tweenTime = distance / originalSpeed
                currentTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
                currentTween:Play()
            end
            createTween()
            updateCoroutine = coroutine.create(function()
                while isTweening do
                    task.wait(0.1)
                    if not isTweening then break end
                    targetChar = targetPlayer and Workspace.Living:FindFirstChild(targetPlayer.Name)
                    targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
                    if not targetHrp then
                        isTweening = false
                        break
                    end
                    distance = (hrp.Position - targetHrp.Position).Magnitude
                    createTween()
                end
            end)
            coroutine.resume(updateCoroutine)
            currentTween.Completed:Connect(function()
                isLocked = true
                isTweening = false
                disableFly()
                disableNoclip()
            end)
        end)
    end

    local function stopAttach()
        pcall(function()
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
        end)
    end

    local function startAttach()
        pcall(function()
            if not targetPlayer then
                if not messageDebounce then
                    messageDebounce = true
                    Library:Notify("Please select a player first!", { Duration = 3 })
                    task.delay(2, function() messageDebounce = false end)
                end
                return
            end
            if Toggles.SpeedhackToggle.Value or Toggles.FlightToggle.Value or _G.tweenActive then
                Library:Notify("Cannot enable Attach to Back with Speedhack, Fly, or Tween active.", { Duration = 3 })
                Toggles.AttachtobackToggle:SetValue(false)
                return
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
                    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
                elseif not isTweening then
                    tweenToBack()
                end
            end)
        end)
    end

    pcall(function()
        disableNofall()
        disableNoclip()
        disableFly()

        Options.PlayerDropdown:OnChanged(function(value)
            pcall(function()
                targetPlayer = value and Players:FindFirstChild(value) or nil
                if isAttached and not targetPlayer then
                    stopAttach()
                end
            end)
        end)

        Toggles.AttachtobackToggle:OnChanged(function(value)
            pcall(function()
                if value then
                    startAttach()
                else
                    stopAttach()
                end
            end)
        end)

        Options.ATBHeight:OnChanged(function(value)
            pcall(function()
                heightOffset = value
            end)
        end)

        Options["ATBDistance)"]:OnChanged(function(value)
            pcall(function()
                zDistance = value
            end)
        end)

        LocalPlayer.CharacterAdded:Connect(function(char)
            pcall(function()
                task.wait(1)
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
            end)
        end)

        Players.PlayerRemoving:Connect(function(player)
            pcall(function()
                if player == targetPlayer then
                    targetPlayer = nil
                    stopAttach()
                    Options.PlayerDropdown:SetValue(nil)
                end
            end)
        end)
    end)
end)

-- Moderator Notifier Module
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local MonitoredUsers = {
        -- [Same MonitoredUsers list as original]
    }
    local UserCache = {}
    local NotificationGui = nil
    local NotificationLabel = nil
    local IsMonitoring = false
    local MonitorConn = nil

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

    local function createNotificationGui()
        pcall(function()
            if NotificationGui then
                NotificationGui:Destroy()
            end
            NotificationGui = Instance.new("ScreenGui")
            NotificationGui.Name = "ModeratorNotifierGui"
            NotificationGui.Parent = game:GetService("CoreGui")
            NotificationGui.IgnoreGuiInset = true
            NotificationGui.Enabled = false

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 300, 0, 100)
            frame.Position = UDim2.new(0.5, -150, 0.1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            frame.BackgroundTransparency = 0.3
            frame.BorderSizePixel = 0
            frame.Parent = NotificationGui

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 8)
            uiCorner.Parent = frame

            NotificationLabel = Instance.new("TextLabel")
            NotificationLabel.Size = UDim2.new(1, -20, 1, -20)
            NotificationLabel.Position = UDim2.new(0, 10, 0, 10)
            NotificationLabel.BackgroundTransparency = 1
            NotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NotificationLabel.TextScaled = true
            NotificationLabel.TextWrapped = true
            NotificationLabel.Font = Enum.Font.SourceSans
            NotificationLabel.Text = ""
            NotificationLabel.Parent = frame
        end)
    end

    local function getPlayerRole(player)
        pcall(function()
            if not player then return nil end
            if UserCache[player.UserId] then
                UserCache[player.UserId].username = player.Name
                return UserCache[player.UserId]
            end
            for _, user in ipairs(MonitoredUsers) do
                if user.userId == player.UserId then
                    UserCache[player.UserId] = {username = player.Name, roleName = user.roleName}
                    return UserCache[player.UserId]
                end
            end
            UserCache[player.UserId] = {username = player.Name, roleName = "None"}
            return nil
        end)
    end

    local function updateNotification()
        pcall(function()
            local rolePlayers = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local role = getPlayerRole(player)
                    if role then
                        table.insert(rolePlayers, role.roleName .. " is in server: " .. player.Name)
                    end
                end
            end
            if #rolePlayers > 0 then
                if not NotificationGui then
                    createNotificationGui()
                end
                NotificationGui.Enabled = true
                NotificationLabel.Text = table.concat(rolePlayers, ", ")
            elseif NotificationGui then
                NotificationGui.Enabled = false
                NotificationLabel.Text = ""
            end
        end)
    end

    local function startMonitoring()
        pcall(function()
            if IsMonitoring then return end
            IsMonitoring = true
            updateNotification()
            MonitorConn = Players.PlayerAdded:Connect(function(player)
                pcall(function()
                    if player == LocalPlayer then return end
                    if getPlayerRole(player) then
                        updateNotification()
                    end
                end)
            end)
            Players.PlayerRemoving:Connect(function(player)
                pcall(function()
                    UserCache[player.UserId] = nil
                    updateNotification()
                end)
            end)
        end)
    end

    local function stopMonitoring()
        pcall(function()
            if not IsMonitoring then return end
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
        end)
    end

    _G.toggleModeratorNotifier = function(value)
        pcall(function()
            if value then
                startMonitoring()
            else
                stopMonitoring()
            end
        end)
    end
end)

-- Auto Kick Module
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local IsKickingEnabled = false
    local MonitorConn = nil
    local TargetRoles = {
        "Developers",
        "Community Manager",
        "Senior Moderator",
        "The Hydra",
        "Junior Moderator",
        "Moderator"
    }
    local MonitoredUsers = _G.MonitoredUsers or {}
    local UserCache = {}

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

    local function getPlayerRole(player)
        pcall(function()
            if not player then return nil end
            if UserCache[player.UserId] then
                UserCache[player.UserId].username = player.Name
                return UserCache[player.UserId]
            end
            for _, user in ipairs(MonitoredUsers) do
                if user.userId == player.UserId then
                    UserCache[player.UserId] = {username = player.Name, roleName = user.roleName}
                    return UserCache[player.UserId]
                end
            end
            UserCache[player.UserId] = {username = player.Name, roleName = "None"}
            return nil
        end)
    end

    local function checkAndKick()
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local role = getPlayerRole(player)
                    if role and table.find(TargetRoles, role.roleName) then
                        LocalPlayer:Kick("Detected staff member: " .. role.roleName .. " (" .. player.Name .. ")")
                        return
                    end
                end
            end
        end)
    end

    local function startKicking()
        pcall(function()
            if IsKickingEnabled then return end
            IsKickingEnabled = true
            checkAndKick()
            MonitorConn = Players.PlayerAdded:Connect(function(player)
                pcall(function()
                    if player == LocalPlayer then return end
                    local role = getPlayerRole(player)
                    if role and table.find(TargetRoles, role.roleName) then
                        LocalPlayer:Kick("Detected staff member: " .. role.roleName .. " (" .. player.Name .. ")")
                    end
                end)
            end)
        end)
    end

    local function stopKicking()
        pcall(function()
            if not IsKickingEnabled then return end
            IsKickingEnabled = false
            if MonitorConn then
                MonitorConn:Disconnect()
                MonitorConn = nil
            end
            UserCache = {}
        end)
    end

    _G.toggleAutoKick = function(value)
        pcall(function()
            if value then
                startKicking()
            else
                stopKicking()
            end
        end)
    end
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
