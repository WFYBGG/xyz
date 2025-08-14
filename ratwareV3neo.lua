local MAX_TWEEN_DISTANCE = 50000 -- Configurable max distance for tweens
if _G.RatwareLoaded then
    Library:Unload()
    return
end
_G.RatwareLoaded = true

-- 🌐 Shared movement state manager (noclip + nofall reference counting)
_G.RW_MovementState = _G.RW_MovementState or {
    noclipUsers = {},
    nofallUsers = {},
}

local MovementState = _G.RW_MovementState

function MovementState:Enable(feature, moduleName)
    local list = feature == "noclip" and self.noclipUsers or self.nofallUsers
    list[moduleName] = true
    if feature == "noclip" then
        self:_applyNoclip(true)
    elseif feature == "nofall" then
        self:_applyNofall(true)
    end
end

function MovementState:Disable(feature, moduleName)
    local list = feature == "noclip" and self.noclipUsers or self.nofallUsers
    list[moduleName] = nil
    if feature == "noclip" and not next(self.noclipUsers) then
        self:_applyNoclip(false)
    elseif feature == "nofall" and not next(self.nofallUsers) then
        self:_applyNofall(false)
    end
end

-- Internal: Noclip with original state restore
local originalCollideStates = {}
function MovementState:_applyNoclip(enable)
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if enable then
                if originalCollideStates[part] == nil then
                    originalCollideStates[part] = part.CanCollide
                end
                pcall(function() part.CanCollide = false end)
            else
                if originalCollideStates[part] ~= nil then
                    pcall(function() part.CanCollide = originalCollideStates[part] end)
                end
            end
        end
    end
    if not enable then
        originalCollideStates = {}
    end
end

-- Internal: No-fall using FallDamageCD
local fallFolder = nil
function MovementState:_applyNofall(enable)
    local status
    pcall(function()
        status = workspace:WaitForChild("Living"):WaitForChild(game.Players.LocalPlayer.Name):WaitForChild("Status")
    end)
    if enable then
        if fallFolder and fallFolder.Parent then
            fallFolder:Destroy()
        end
        fallFolder = Instance.new("Folder")
        fallFolder.Name = "FallDamageCD"
        fallFolder.Parent = status
    else
        if fallFolder and fallFolder.Parent then
            fallFolder:Destroy()
        end
        fallFolder = nil
    end
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ratwarexe/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ratware.exe - 100% Made By ChatGPT [Press 'Insert' To Hide]",
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
    Text = "Speedhack",
    NoUI = false,
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
    Text = "Fly",
    NoUI = false,
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
    Text = "Anti-AA Bypass",
    NoUI = false,
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
    Text = "No Clip",
    NoUI = false,
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
                                local distance = getDistance(instanceData.position, areaPosition)
                                if distance < minDistance then
                                    minDistance = distance
                                    closestArea = areaName
                                end
                            end
                        end
                    end
                    if closestArea then
                        local areaKey = npcName .. "," .. closestArea
                        if not seenAreaForNPC[areaKey] then
                            seenAreaForNPC[areaKey] = true
                            table.insert(npcList, npcName .. ", " .. closestArea)
                            table.insert(TweenFullList, npcName .. ", " .. closestArea)
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
    end
})
MainGroup6:AddToggle("AttachtobackToggle", {
    Text = "Attach To Back",
    Default = false
}):AddKeyPicker("Attachtobackbind", {
    Default = "",
    Mode = "Toggle",
    Text = "Attach To Back",
    NoUI = false,
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
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "RW_Speedhack"
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    local originalJumpPower = nil

    local function resetSpeed()
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = originalJumpPower or 50
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

    LocalPlayer.CharacterAdded:Connect(function(character)
        pcall(function()
            local timeout = tick() + 5
            while not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) and tick() < timeout do
                task.wait()
            end
            if not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) then
                return
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
                local char = LocalPlayer.Character
                if Toggles.SpeedhackToggle.Value and char and char:FindFirstChild("HumanoidRootPart") then
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Workspace.CurrentCamera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Workspace.CurrentCamera.CFrame.RightVector end
                    dir = dir.Magnitude > 0 and dir.Unit or Vector3.zero
                    local speed = math.min(Options.SpeedhackSpeed.Value, 49 / dt)
                    speed = speed * (0.95 + math.random() * 0.1)
                    BodyVelocity.Velocity = dir * speed
                    BodyVelocity.Parent = char.HumanoidRootPart
                    if not originalJumpPower then originalJumpPower = char.Humanoid.JumpPower end
                    char.Humanoid.JumpPower = 0
                else
                    resetSpeed()
                end
            end)
        end)
    end)

    Toggles.FlightToggle:OnChanged(function(value)
        pcall(function()
            if not value and Toggles.SpeedhackToggle.Value then
                Toggles.SpeedhackToggle:SetValue(false)
                task.wait(0.1)
                Toggles.SpeedhackToggle:SetValue(true)
            end
        end)
    end)
end)

-- Fly/Flight Module
pcall(function()
    local Platform = Instance.new("Part")
    Platform.Size = Vector3.new(6, 1, 6)
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Transparency = 1.00
    Platform.BrickColor = BrickColor.new("Bright blue")
    Platform.Material = Enum.Material.SmoothPlastic
    Platform.Name = "OldDebris"
    local FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.Name = "RW_Fly"
    FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local originalJumpPower = nil

    local function resetFly()
        pcall(function()
            Platform.Parent = nil
            FlyVelocity.Parent = nil
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = originalJumpPower or 50
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

    LocalPlayer.CharacterAdded:Connect(function(char)
        pcall(function()
            local timeout = tick() + 5
            while not (char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) and tick() < timeout do
                task.wait()
            end
            if Toggles.FlightToggle.Value then
                FlyVelocity.Parent = char.HumanoidRootPart
                Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                Platform.Parent = Workspace
                if not originalJumpPower then originalJumpPower = char.Humanoid.JumpPower end
                char.Humanoid.JumpPower = 0
            end
        end)
    end)

    local renderConnection
    pcall(function()
        renderConnection = RunService.RenderStepped:Connect(function(dt)
            pcall(function()
                local char = LocalPlayer.Character
                if Toggles.FlightToggle.Value and char and char:FindFirstChild("HumanoidRootPart") then
                    local moveDir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Workspace.CurrentCamera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Workspace.CurrentCamera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Workspace.CurrentCamera.CFrame.RightVector end
                    moveDir = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero
                    local vert = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = 70 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -70 end
                    local speed = math.min(Options.FlightSpeed.Value, 49 / dt)
                    speed = speed * (0.95 + math.random() * 0.1)
                    FlyVelocity.Velocity = moveDir * speed + Vector3.new(0, vert, 0)
                    FlyVelocity.Parent = char.HumanoidRootPart
                    Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                    Platform.Parent = Workspace
                else
                    resetFly()
                end
            end)
        end)
    end)

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

-- Noclip Module
pcall(function()
    Toggles.NoclipToggle:OnChanged(function(value)
        if value then
            MovementState:Enable("noclip", "ManualNoclip")
        else
            MovementState:Disable("noclip", "ManualNoclip")
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        if Toggles.NoclipToggle.Value then
            MovementState:Enable("noclip", "ManualNoclip")
        end
    end)
end)

-- No Fall Damage Module
pcall(function()
    local fallFolder = nil

    local function setNoFall(active)
        pcall(function()
            local status = Workspace:WaitForChild("Living"):WaitForChild(LocalPlayer.Name):WaitForChild("Status")
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

    LocalPlayer.CharacterAdded:Connect(function()
        pcall(function()
            local timeout = tick() + 5
            while not Workspace:FindFirstChild("Living") and tick() < timeout do
                task.wait()
            end
            if Toggles.NoFallDamage.Value then
                setNoFall(true)
            end
        end)
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if Toggles.NoFallDamage.Value then
                setNoFall(true)
            else
                setNoFall(false)
            end
        end)
    end)
end)

-- No Killbricks/Disable Touch Module
pcall(function()
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
            local descendants = char:GetDescendants()
            for _, part in ipairs(descendants) do
                if (part:IsA("BasePart") or part:IsA("MeshPart")) and not affectedParts[part] then
                    local canTouch = part.CanTouch
                    affectedParts[part] = canTouch
                    part.CanTouch = false
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
        if isEnabled then return end
        isEnabled = true
        disableCharacterTouch()
        if characterConn then
            characterConn:Disconnect()
        end
        characterConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if isEnabled then
                disableCharacterTouch()
            end
        end)
    end

    local function disableDisableTouch()
        if not isEnabled then return end
        isEnabled = false
        if characterConn then
            characterConn:Disconnect()
            characterConn = nil
        end
        restoreCharacterTouch()
    end

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

-- Anti-AA Bypass/Swim Status Module
pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
        if isEnabled then return end
        isEnabled = true
        fireSwimStatus(true)
        if characterConn then
            characterConn:Disconnect()
        end
        characterConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if isEnabled then
                fireSwimStatus(true)
            end
        end)
    end

    local function disableSwimStatus()
        if not isEnabled then return end
        isEnabled = false
        fireSwimStatus(false)
        if characterConn then
            characterConn:Disconnect()
            characterConn = nil
        end
    end

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

-- Player ESP Module
pcall(function()
    local Camera = Workspace.CurrentCamera
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
            living = Workspace:FindFirstChild("Living")
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

            local box = Drawing.new("Square")
            box.Visible = false
            box.Thickness = 2
            box.Color = Color3.fromRGB(255, 25, 25)
            box.Filled = false

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
            chamBox.Thickness = 1

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

    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then pcall(function() createESP(plr) end) end
    end)
    Players.PlayerRemoving:Connect(function(plr)
        pcall(function() cleanupESP(plr) end)
    end)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then pcall(function() createESP(plr) end) end
    end

    RunService.Heartbeat:Connect(function()
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
                            pcall(function()
                                chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                                chamBox.Size = Vector2.new(width, height)
                                chamBox.Color = Color3.fromRGB(255, 0, 0)
                                chamBox.Transparency = 0.15
                                chamBox.Visible = true
                            end)
                            pcall(function()
                                box.Position = Vector2.new(topW.X - width/2, topW.Y)
                                box.Size = Vector2.new(width, height)
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
                            pcall(function() box.Visible = false end)
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
                        pcall(function() box.Visible = false end)
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
end)

-- Universal Tween Module
pcall(function()
    repeat
        task.wait()
    until game:IsLoaded()
    repeat
        task.wait()
    until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    _G.originalspeed = 150
    _G.Speed = _G.originalspeed
    local flyEnabled = false
    local flyActive = false
    local originalCollideStates = {}
    local currentTween = nil

    local platform = Instance.new("Part")
    platform.Name = "OldDebris"
    platform.Size = Vector3.new(30, 1, 30)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1.00
    platform.Material = Enum.Material.SmoothPlastic
    platform.BrickColor = BrickColor.new("Bright blue")

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "RW_UniversalTween"
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)

    local function resetHumanoidState()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = LocalPlayer.Character.Humanoid
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function(character)
        repeat
            task.wait()
        until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
        pcall(function()
            if flyEnabled or _G.tweenActive then
                character.Humanoid.JumpPower = 0
                platform.Parent = Workspace
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
                MovementState:Enable("noclip", "UniversalTween")
                if Toggles.NoFallDamage.Value then
                    MovementState:Enable("nofall", "UniversalTween")
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
            local character = LocalPlayer.Character
            if enable then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.JumpPower = 0
                end
                platform.Parent = Workspace
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

    local function createTween(targetPos, duration)
        pcall(function()
            local character = LocalPlayer.Character
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

    RunService.RenderStepped:Connect(function(delta)
        pcall(function()
            local character = LocalPlayer.Character
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
                            MovementState:Disable("noclip", "UniversalTween")
                            if not Toggles.NoFallDamage.Value then
                                MovementState:Disable("nofall", "UniversalTween")
                            end
                        end
                    end
                end
                bodyVelocity.Velocity = moveDirection
                humanoid.JumpPower = 0
                platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
                platform.Parent = Workspace
                if humanoid.Health <= 0 then
                    Library:Notify("Character Dead, Please Try Again", { Duration = 3 })
                    resetHumanoidState()
                    _G.tweenActive = false
                    _G.tweenPhase = 0
                    flyEnabled = false
                    flyActive = false
                    platform.Parent = nil
                    bodyVelocity.Parent = nil
                    MovementState:Disable("noclip", "UniversalTween")
                    if not Toggles.NoFallDamage.Value then
                        MovementState:Disable("nofall", "UniversalTween")
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
        end)
    end)

    _G.CustomTween = function(target)
        pcall(function()
            local character = LocalPlayer.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local distance = (target - hrp.Position).Magnitude
            if distance > MAX_TWEEN_DISTANCE then
                Library:Notify("Target too far away!", { Duration = 3 })
                return
            end
            MovementState:Enable("noclip", "UniversalTween")
            MovementState:Enable("nofall", "UniversalTween")
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
            MovementState:Disable("noclip", "UniversalTween")
            if not Toggles.NoFallDamage.Value then
                MovementState:Disable("nofall", "UniversalTween")
            end
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
        end)
    end
end)

-- Attach to Back Module
pcall(function()
    local targetPlayer = nil
    local isAttached = false
    local attachConn = nil
    local isTweening = false
    local isLocked = false
    local flyEnabled = false
    local flyPlatform = nil
    local bodyVelocity = nil
    local flyConn = nil
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
            flyPlatform.Parent = Workspace
            flyPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "RW_AttachToBack"
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
            if distance > MAX_TWEEN_DISTANCE then return false end
            enableFly()
            MovementState:Enable("nofall", "AttachToBack")
            MovementState:Enable("noclip", "AttachToBack")
            local function createTween()
                local backGoal = targetHrp.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBDistance.Value)
                local tweenTime = distance / _G.originalspeed
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
            MovementState:Disable("noclip", "AttachToBack")
            return true
        end)
        if not success then
            isTweening = false
            disableFly()
            MovementState:Disable("noclip", "AttachToBack")
            MovementState:Disable("nofall", "AttachToBack")
        end
        return success and result
    end

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
            MovementState:Disable("nofall", "AttachToBack")
            MovementState:Disable("noclip", "AttachToBack")
            disableFly()
            return true
        end)
        return success and result
    end

    Toggles.AttachtobackToggle:OnChanged(function(value)
        pcall(function()
            if value then
                targetPlayer = Players:FindFirstChild(Options.PlayerDropdown.Value)
                if not targetPlayer then
                    Library:Notify("No player selected or player not found!", { Duration = 3 })
                    Toggles.AttachtobackToggle:SetValue(false)
                    return
                end
                local targetChar = Workspace.Living:FindFirstChild(targetPlayer.Name)
                local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
                if not targetChar or not char then
                    Library:Notify("Target or local character not found!", { Duration = 3 })
                    Toggles.AttachtobackToggle:SetValue(false)
                    return
                end
                isAttached = true
                local success = tweenToBack()
                if not success then
                    Library:Notify("Failed to attach to player!", { Duration = 3 })
                    Toggles.AttachtobackToggle:SetValue(false)
                    return
                end
                attachConn = RunService.RenderStepped:Connect(function()
                    if not isAttached or not targetPlayer then
                        stopAttach()
                        Toggles.AttachtobackToggle:SetValue(false)
                        return
                    end
                    local targetChar = Workspace.Living:FindFirstChild(targetPlayer.Name)
                    local char = Workspace.Living:FindFirstChild(LocalPlayer.Name)
                    local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
                    local hrp = char and safeGet(char, "HumanoidRootPart")
                    local targetHum = targetChar and safeGet(targetChar, "Humanoid")
                    if not targetHrp or not hrp or not targetHum or targetHum.Health <= 0 then
                        if not messageDebounce then
                            messageDebounce = true
                            Library:Notify("Target lost or dead, stopping!", { Duration = 3 })
                            task.spawn(function()
                                task.wait(3)
                                messageDebounce = false
                            end)
                        end
                        stopAttach()
                        Toggles.AttachtobackToggle:SetValue(false)
                        return
                    end
                    if isLocked then
                        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBDistance.Value)
                    end
                end)
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
    Options.ATBDistance:OnChanged(function(value)
        pcall(function()
            zDistance = value
        end)
    end)
end)

-- UI Settings Tab
local ThemeGroup = Tabs.UI:AddLeftGroupbox("Theme")
ThemeGroup:AddDropdown("ThemeDropdown", {
    Text = "Select Theme",
    Default = "Default",
    Values = ThemeManager:GetThemes(),
    Callback = function(value)
        ThemeManager:SetTheme(value)
    end
})

local SaveGroup = Tabs.UI:AddRightGroupbox("Save Manager")
SaveGroup:AddButton("Save Config", function()
    SaveManager:Save()
end)
SaveGroup:AddButton("Load Config", function()
    SaveManager:Load()
end)
