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
                        targetPos = part.CFrame.Position
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
    Default = 125,
    Min = 0,
    Max = 250,
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

local MainGroup4 = Tabs.Main:AddLeftGroupbox("Removal")
MainGroup4:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false
})

local MainGroup6 = Tabs.Main:AddLeftGroupbox("Rage")
MainGroup6:AddDropdown('PlayerDropdown', {
    SpecialType = 'Player',
    Text = 'Select Player',
    Tooltip = 'Attach to [Selected Username]',
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
local LocalPlayer = Players.LocalPlayer

-- State Manager for Movement Systems
local MovementStates = {
    Speedhack = false,
    Fly = false,
    Noclip = false,
    NoFall = false,
    TweenActive = false,
    AttachActive = false
}

local function resetCharacterState()
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
        -- Cleanup all movement instances
        if char then
            for _, obj in pairs(char:GetChildren()) do
                if obj.Name == "SpeedhackVelocity" or obj.Name == "OldDebris" then
                    obj:Destroy()
                end
            end
        end
    end)
end

local function cleanupAllStates()
    pcall(function()
        MovementStates.Speedhack = false
        MovementStates.Fly = false
        MovementStates.Noclip = false
        MovementStates.NoFall = false
        MovementStates.TweenActive = false
        MovementStates.AttachActive = false
        resetCharacterState()
        -- Additional cleanup for modules
        _G.StopTween()
        if _G.BodyVelocity then _G.BodyVelocity:Destroy() end
        if _G.Platform then _G.Platform:Destroy() end
        if _G.FallDamageCD then _G.FallDamageCD:Destroy() end
    end)
end

-- Initialize clean state on script load
cleanupAllStates()
LocalPlayer.CharacterAdded:Connect(cleanupAllStates)

-- Standalone Toggle System for Speedhack and Fly
local ToggleManager = {}
ToggleManager.State = { Speedhack = false, Fly = false }
local isUpdating = false -- Prevent recursion

local function updateToggleState(feature, state)
    if isUpdating then return end
    isUpdating = true
    ToggleManager.State[feature] = state
    if feature == "Speedhack" then Toggles.SpeedhackToggle:SetValue(state)
    elseif feature == "Fly" then Toggles.FlightToggle:SetValue(state) end

    if feature == "Speedhack" and not state and ToggleManager.State.Fly then
        Toggles.FlightToggle:SetValue(false)
        task.wait(0.1)
        Toggles.FlightToggle:SetValue(true)
    elseif feature == "Fly" and not state and ToggleManager.State.Speedhack then
        Toggles.SpeedhackToggle:SetValue(false)
        task.wait(0.1)
        Toggles.SpeedhackToggle:SetValue(true)
    end
    isUpdating = false
end

Toggles.SpeedhackToggle:OnChanged(function(state)
    updateToggleState("Speedhack", state)
    MovementStates.Speedhack = state
    if not state then cleanupAllStates() end
end)

Toggles.FlightToggle:OnChanged(function(state)
    updateToggleState("Fly", state)
    MovementStates.Fly = state
    if not state then cleanupAllStates() end
end)

Toggles.NoclipToggle:OnChanged(function(state)
    MovementStates.Noclip = state
    if not state then cleanupAllStates() end
end)

Toggles.NoFallDamage:OnChanged(function(state)
    MovementStates.NoFall = state
    if not state then cleanupAllStates() end
end)

Toggles.AttachtobackToggle:OnChanged(function(state)
    MovementStates.AttachActive = state
    if not state then cleanupAllStates() end
end)

-- Sync with Universal Tween
_G.tweenActive = false
_G.CustomTween = function(target)
    MovementStates.TweenActive = true
    cleanupAllStates()
    MovementStates.Fly = true
    MovementStates.Noclip = true
    Toggles.FlightToggle:SetValue(true)
    Toggles.NoclipToggle:SetValue(true)
end
_G.StopTween = function()
    MovementStates.TweenActive = false
    cleanupAllStates()
end

-- Prevent Interference and Restore State
RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return end

        if MovementStates.TweenActive or MovementStates.AttachActive then
            if MovementStates.Speedhack then updateToggleState("Speedhack", false) end
            if MovementStates.Fly then updateToggleState("Fly", false) end
        end

        if MovementStates.Speedhack and MovementStates.Fly then
            updateToggleState("Speedhack", false)
        end

        if MovementStates.TweenActive and not (MovementStates.Fly or MovementStates.Noclip) then
            MovementStates.Fly = true
            Toggles.FlightToggle:SetValue(true)
            MovementStates.Noclip = true
            Toggles.NoclipToggle:SetValue(true)
        end

        if not MovementStates.TweenActive and not MovementStates.AttachActive then
            if MovementStates.Noclip and not (MovementStates.Fly or MovementStates.Speedhack) then
                Toggles.NoclipToggle:SetValue(false)
                MovementStates.Noclip = false
            end
            if MovementStates.NoFall and not (MovementStates.TweenActive or MovementStates.AttachActive) then
                Toggles.NoFallDamage:SetValue(false)
                MovementStates.NoFall = false
            end
        end

        if not MovementStates.Speedhack and not MovementStates.Fly and not MovementStates.Noclip and
           not MovementStates.NoFall and not MovementStates.TweenActive and not MovementStates.AttachActive then
            resetCharacterState()
        end
    end)
end)

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
            end
            BodyVelocity.Parent = nil
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
            if Toggles.SpeedhackToggle.Value then
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
            end)
        end)
    end)
end)

-- Fly Module
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
            if Toggles.NoclipToggle.Value then
                setCollision(false)
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

-- No Fall Module
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

-- Player ESP Module
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
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
        local living = workspace:FindFirstChild("Living")
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
        local tbl = ESPObjects[player]
        if tbl then
            for _, obj in pairs(tbl) do
                if typeof(obj) == "table" then
                    for _, v in pairs(obj) do
                        pcall(function() if v and v.Remove then v:Remove() end end)
                    end
                else
                    pcall(function() if obj and obj.Remove then obj:Remove() end end)
                end
            end
            ESPObjects[player] = nil
        end
    end

    local function createESP(player)
        if player == LocalPlayer then return end
        pcall(function()
            if ESPObjects[player] then cleanupESP(player) end
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
            ESPObjects[player] = {Box = box, Name = nameText, Health = healthText, Distance = distText, ChamBox = chamBox, Skeleton = {}}
        end)
    end

    local function drawSkeleton(player, char, color, thickness)
        local bones = {
            {"Head", "HumanoidRootPart"}, {"HumanoidRootPart", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"}, {"HumanoidRootPart", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"}, {"HumanoidRootPart", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"}, {"HumanoidRootPart", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"}
        }
        local skeleton = ESPObjects[player].Skeleton or {}
        for i, pair in ipairs(bones) do
            local part1, part2
            pcall(function() part1, part2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2]) end)
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

    Players.PlayerAdded:Connect(function(plr) if plr ~= LocalPlayer then createESP(plr) end end)
    Players.PlayerRemoving:Connect(function(plr) cleanupESP(plr) end)
    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then createESP(plr) end end

    RunService.RenderStepped:Connect(function()
        pcall(function()
            local streamedPlayers = {}
            for player, tbl in pairs(ESPObjects) do
                streamedPlayers[player] = true
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
                        local height, width = (botW.Y - topW.Y), height * 0.45
                        if Toggles.PlayerESP.Value and onScreen and onScreen1 and onScreen2 and health > 0 then
                            chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                            chamBox.Size = Vector2.new(width, height)
                            chamBox.Visible = true
                            box.From = Vector2.new(topW.X - width/2, topW.Y)
                            box.To = Vector2.new(topW.X + width/2, topW.Y)
                            box.Visible = true
                            nameText.Text = player.Name
                            nameText.Position = Vector2.new(pos.X, topW.Y - 16)
                            nameText.Visible = true
                            healthText.Text = "[" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
                            healthText.Position = Vector2.new(pos.X, topW.Y - 2)
                            healthText.Color = Color3.fromRGB(255 - 255 * (health/maxHealth), 255 * (health/maxHealth), 0)
                            healthText.Visible = true
                            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                            distText.Text = "[" .. math.floor(dist) .. "m]"
                            distText.Position = Vector2.new(pos.X, botW.Y + 2)
                            distText.Visible = true
                            drawSkeleton(player, char, Color3.fromRGB(255, 255, 255), 2)
                        else
                            box.Visible = false
                            nameText.Visible = false
                            healthText.Visible = false
                            distText.Visible = false
                            chamBox.Visible = false
                            for _, line in pairs(tbl.Skeleton) do line.Visible = false end
                        end
                    else
                        box.Visible = false
                        nameText.Visible = false
                        healthText.Visible = false
                        distText.Visible = false
                        chamBox.Visible = false
                        for _, line in pairs(tbl.Skeleton) do line.Visible = false end
                    end
                end)
            end
            for playerRef in pairs(ESPObjects) do
                if not streamedPlayers[playerRef] then cleanupESP(playerRef) end
            end
        end)
    end)
end)

-- Universal Tween & Location Module
pcall(function()
    repeat wait() until game:IsLoaded()
    repeat wait() until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local players = game:GetService("Players")
    local rs = game:GetService("RunService")

    _G.originalspeed = 125
    _G.Speed = _G.originalspeed
    local flyEnabled = false
    local flyActive = false
    local lastPosition = nil

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
        repeat wait() until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
        pcall(function()
            if flyEnabled or _G.tweenActive then
                character.Humanoid.JumpPower = 0
                platform.Parent = workspace
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
            else
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
            lastPosition = character.HumanoidRootPart.Position
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
                    lastPosition = character.HumanoidRootPart.Position
                end
            else
                resetHumanoidState()
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
        end)
    end

    local noclipEnabled = false
    local noclipActive = false

    local function resetNoClip()
        pcall(function()
            if players.LocalPlayer.Character then
                for _, part in pairs(players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            for part, canCollide in pairs(originalCollideStates) do
                if part and part.Parent then
                    part.CanCollide = canCollide
                end
            end
            originalCollideStates = {}
        end)
    end

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        repeat wait() until character:FindFirstChild("HumanoidRootPart")
        if noclipEnabled or _G.tweenActive then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)

    local function toggleNoclip(enable)
        pcall(function()
            noclipEnabled = enable
            local character = players.LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = not enable
                    end
                end
            end
            if not enable then
                resetNoClip()
            end
        end)
    end

    local nofallEnabled = false
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
    local tweenNotification = nil
    local teleportCooldown = 0
    local notificationCheck = 0

    rs.RenderStepped:Connect(function(delta)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")

            if flyEnabled and character and humanoid and hrp then
                flyActive = true
                if _G.tweenActive and teleportCooldown <= 0 then
                    if not noclipEnabled then
                        toggleNoclip(true)
                    end
                    local pos = hrp.Position
                    if _G.tweenPhase == 1 then
                        local targetY = _G.highAltitude
                        local distance = targetY - pos.Y
                        if distance > 1 then
                            hrp.CFrame = hrp.CFrame + Vector3.new(0, _G.Speed * delta, 0)
                        else
                            hrp.CFrame = CFrame.new(Vector3.new(pos.X, targetY, pos.Z)) * (hrp.CFrame - hrp.Position)
                            _G.tweenPhase = 2
                        end
                    elseif _G.tweenPhase == 2 then
                        local highTarget = Vector3.new(_G.tweenTarget.X, _G.highAltitude, _G.tweenTarget.Z)
                        local horizontalVec = (highTarget - pos) * Vector3.new(1, 0, 1)
                        if horizontalVec.Magnitude > 5 then
                            local stepDistance = _G.Speed * delta
                            if stepDistance > 10 then stepDistance = 10 end
                            local moveDirection = horizontalVec.Unit * stepDistance
                            if horizontalVec.Magnitude < moveDirection.Magnitude then
                                moveDirection = horizontalVec
                            end
                            hrp.CFrame = hrp.CFrame + moveDirection
                        else
                            hrp.CFrame = CFrame.new(Vector3.new(highTarget.X, _G.highAltitude, highTarget.Z)) * (hrp.CFrame - hrp.Position)
                            _G.tweenPhase = 3
                        end
                    elseif _G.tweenPhase == 3 then
                        local targetY = _G.tweenTarget.Y
                        local distance = pos.Y - targetY
                        if distance > 5 then
                            hrp.CFrame = hrp.CFrame + Vector3.new(0, -_G.Speed * delta, 0)
                        else
                            hrp.CFrame = CFrame.new(Vector3.new(pos.X, targetY, pos.Z)) * (hrp.CFrame - hrp.Position)
                            _G.tweenActive = false
                            _G.tweenPhase = 0
                            toggleFly(false)
                            toggleNoclip(false)
                            toggleNofall(false)
                            if tweenNotification then
                                tweenNotification:Destroy()
                                tweenNotification = nil
                            end
                        end
                    end
                elseif teleportCooldown > 0 then
                    teleportCooldown = teleportCooldown - delta
                end
                humanoid.JumpPower = 0
                platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
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
                    toggleNofall(false)
                    if tweenNotification then
                        tweenNotification:Destroy()
                        tweenNotification = nil
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
                        part.CanCollide = false
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
            toggleNoclip(true)
            toggleNofall(true)
            toggleFly(true)
            _G.tweenTarget = target
            _G.highAltitude = hrp.Position.Y + 500
            _G.tweenPhase = 1
            _G.tweenActive = true
            lastPosition = hrp.Position
            if not tweenNotification then
                tweenNotification = Library:Notify("Tween in progress", { Duration = 9999 })
            end
        end)
    end

    _G.StopTween = function()
        pcall(function()
            _G.tweenActive = false
            _G.tweenPhase = 0
            toggleFly(false)
            toggleNoclip(false)
            toggleNofall(false)
            if tweenNotification then
                tweenNotification:Destroy()
                tweenNotification = nil
            end
            teleportCooldown = 0
            resetNoClip()
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

-- Attach to Back Module [TESTING STILL]
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
local zDistance = -4
local originalSpeed = 150
local messageDebounce = false
local currentTween = nil
local updateCoroutine = nil

local function safeGet(obj, ...)
    local args = {...}
    for _, v in ipairs(args) do
        local ok, res = pcall(function() return obj[v] end)
        if not ok then return nil end
        obj = res
        if not obj then return nil end
    end
    return obj
end

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
    return success and result
end

local function disableFly()
    local success, result = pcall(function()
        if not flyEnabled then return true end
        flyEnabled = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyPlatform then flyPlatform:Destroy() flyPlatform = nil end
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
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
    return success and result
end

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
    return success and result
end

local function enableNoclip()
    local success, result = pcall(function()
        if noclipEnabled then return true end
        local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
        if not char then return false end
        noclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        return true
    end)
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
                part.CanCollide = true
            end
        end
        return true
    end)
    return success and result
end

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
        local backGoal = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
        local tweenTime = distance / originalSpeed
        currentTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
        currentTween:Play()
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

local function stopAttach()
    local success, result = pcall(function()
        isAttached = false
        isLocked = false
        isTweening = false
        if attachConn then attachConn:Disconnect() attachConn = nil end
        if updateCoroutine then coroutine.close(updateCoroutine) updateCoroutine = nil end
        if currentTween then currentTween:Cancel() currentTween = nil end
        disableNofall()
        disableNoclip()
        disableFly()
        return true
    end)
    return success and result
end

local function startAttach()
    local success, result = pcall(function()
        if not targetPlayer then
            if not messageDebounce then
                messageDebounce = true
                messagebox("Please select a player first!", "Error", 0)
                task.delay(2, function() messageDebounce = false end)
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
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
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

local success, result = pcall(function()
    local success, _ = pcall(function()
        disableNofall()
        disableNoclip()
        disableFly()
        return true
    end)
    if not success then warn("Failed to ensure clean initial state") end

    Options.PlayerDropdown:OnChanged(function(value)
        local success, _ = pcall(function()
            targetPlayer = value and Players:FindFirstChild(value) or nil
            if isAttached and not targetPlayer then
                stopAttach()
            end
            return true
        end)
        if not success then warn("Failed to update target player") end
    end)

    Toggles.AttachtobackToggle:OnChanged(function(value)
        local success, _ = pcall(function()
            if value then startAttach() else stopAttach() end
            return true
        end)
        if not success then warn("Failed to toggle attach") end
    end)

    Options.ATBHeight:OnChanged(function(value)
        local success, _ = pcall(function()
            heightOffset = value
            return true
        end)
        if not success then warn("Failed to update height offset") end
    end)

    Options["ATBDistance)"]:OnChanged(function(value)
        local success, _ = pcall(function()
            zDistance = value
            return true
        end)
        if not success then warn("Failed to update distance") end
    end)

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
        if not success then warn("Failed to handle character respawn") end
    end)

    LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local success, _ = pcall(function()
                stopAttach()
                return true
            end)
            if not success then warn("Failed to clean up on leave") end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local success, _ = pcall(function()
            if player == targetPlayer then
                targetPlayer = nil
                stopAttach()
                Options.PlayerDropdown:SetValue(nil)
            end
            return true
        end)
        if not success then warn("Failed to handle player removing") end
    end)

    return true
end)

if not success then warn("Setup failed: " .. tostring(result)) end

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
