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
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Movement priority logic
local priority = {tween = 4, attach = 3, fly = 2, speedhack = 1}
local activeMode = nil

local function setActiveMode(newMode)
    if activeMode and priority[newMode] < priority[activeMode] then
        return false
    end
    if activeMode then
        if activeMode == "speedhack" then
            pcall(function() Toggles.SpeedhackToggle:SetValue(false) end)
        elseif activeMode == "fly" then
            pcall(function() Toggles.FlightToggle:SetValue(false) end)
        elseif activeMode == "attach" then
            pcall(function() Toggles.AttachtobackToggle:SetValue(false) end)
        elseif activeMode == "tween" then
            pcall(function() _G.StopTween() end)
        end
    end
    activeMode = newMode
    return true
end

local function clearActiveMode(mode)
    if activeMode == mode then
        activeMode = nil
    end
end

-- ✅ Noclip Toggle (Persists after death/reset)
pcall(function()
    local player = Players.LocalPlayer
    if not Toggles or not Toggles.NoclipToggle then return end

    local function applyNoclipState()
        if Toggles.NoclipToggle.Value then
            MovementState:Enable("noclip", "ManualNoclip")
        else
            MovementState:Disable("noclip", "ManualNoclip")
        end
    end

    Toggles.NoclipToggle:OnChanged(function(value)
        applyNoclipState()
    end)

    player.CharacterAdded:Connect(function()
        applyNoclipState()
    end)

    -- Initial check
    applyNoclipState()
end)

-- ✅ Speedhack (Fixed with unique BodyVelocity)
pcall(function()
    local player = Players.LocalPlayer
    local speedhackBV = nil
    local speedActive = false
    local originalWalkSpeed = 16
    local originalJumpPower = 50

    local function createSpeedhackBV()
        if speedhackBV then
            speedhackBV:Destroy()
        end
        speedhackBV = Instance.new("BodyVelocity")
        speedhackBV.Name = "RW_SpeedhackBV"
        speedhackBV.MaxForce = Vector3.new(math.huge, 0, math.huge)
        speedhackBV.Velocity = Vector3.zero
        return speedhackBV
    end

    local function resetSpeed()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
            end
            if speedhackBV then
                speedhackBV:Destroy()
                speedhackBV = nil
            end
            MovementState:Disable("noclip", "Speedhack")
            speedActive = false
        end)
    end

    Toggles.SpeedhackToggle:OnChanged(function(value)
        pcall(function()
            if value then
                if not setActiveMode("speedhack") then
                    Toggles.SpeedhackToggle:SetValue(false)
                    Library:Notify("Higher priority mode active", {Duration = 3})
                    return
                end
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                    local humanoid = char.Humanoid
                    originalWalkSpeed = humanoid.WalkSpeed
                    originalJumpPower = humanoid.JumpPower
                    humanoid.WalkSpeed = Options.SpeedhackSpeed.Value
                    humanoid.JumpPower = 0
                    createSpeedhackBV()
                    speedhackBV.Parent = char.HumanoidRootPart
                    MovementState:Enable("noclip", "Speedhack")
                    speedActive = true
                else
                    Toggles.SpeedhackToggle:SetValue(false)
                    Library:Notify("Character not ready", {Duration = 3})
                end
            else
                resetSpeed()
                clearActiveMode("speedhack")
            end
        end)
    end)

    player.CharacterAdded:Connect(function(char)
        pcall(function()
            if speedActive then
                char:WaitForChild("HumanoidRootPart")
                char:WaitForChild("Humanoid")
                local humanoid = char.Humanoid
                humanoid.WalkSpeed = Options.SpeedhackSpeed.Value
                humanoid.JumpPower = 0
                createSpeedhackBV()
                speedhackBV.Parent = char.HumanoidRootPart
                MovementState:Enable("noclip", "Speedhack")
            end
        end)
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if speedActive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = player.Character.Humanoid
                local moveDirection = humanoid.MoveDirection
                if moveDirection.Magnitude > 0 then
                    speedhackBV.Velocity = moveDirection * Options.SpeedhackSpeed.Value
                else
                    speedhackBV.Velocity = Vector3.zero
                end
            end
        end)
    end)
end)

-- ✅ Fly (Fixed with unique BodyVelocity and UserInputService)
pcall(function()
    local player = Players.LocalPlayer
    local flyBV = nil
    local flyPlatform = Instance.new("Part")
    flyPlatform.Name = "RW_FlyPlatform"
    flyPlatform.Size = Vector3.new(30, 1, 30)
    flyPlatform.Anchored = true
    flyPlatform.CanCollide = true
    flyPlatform.Transparency = 1
    flyPlatform.Material = Enum.Material.SmoothPlastic
    flyPlatform.BrickColor = BrickColor.new("Bright blue")
    local flyActive = false
    local originalJumpPower = 50

    local function createFlyBV()
        if flyBV then
            flyBV:Destroy()
        end
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "RW_FlyBV"
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        return flyBV
    end

    local function resetFly()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.JumpPower = originalJumpPower
            end
            flyPlatform.Parent = nil
            if flyBV then
                flyBV:Destroy()
                flyBV = nil
            end
            MovementState:Disable("noclip", "Fly")
            MovementState:Disable("nofall", "Fly")
            flyActive = false
        end)
    end

    Toggles.FlightToggle:OnChanged(function(value)
        pcall(function()
            if value then
                if not setActiveMode("fly") then
                    Toggles.FlightToggle:SetValue(false)
                    Library:Notify("Higher priority mode active", {Duration = 3})
                    return
                end
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                    originalJumpPower = char.Humanoid.JumpPower
                    char.Humanoid.JumpPower = 0
                    flyPlatform.Parent = workspace
                    flyPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                    createFlyBV()
                    flyBV.Parent = char.HumanoidRootPart
                    MovementState:Enable("noclip", "Fly")
                    MovementState:Enable("nofall", "Fly")
                    flyActive = true
                else
                    Toggles.FlightToggle:SetValue(false)
                    Library:Notify("Character not ready", {Duration = 3})
                end
            else
                resetFly()
                clearActiveMode("fly")
            end
        end)
    end)

    player.CharacterAdded:Connect(function(char)
        pcall(function()
            if flyActive then
                char:WaitForChild("HumanoidRootPart")
                char:WaitForChild("Humanoid")
                char.Humanoid.JumpPower = 0
                flyPlatform.Parent = workspace
                flyPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                createFlyBV()
                flyBV.Parent = char.HumanoidRootPart
                MovementState:Enable("noclip", "Fly")
                MovementState:Enable("nofall", "Fly")
            end
        end)
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if flyActive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local camera = workspace.CurrentCamera
                local moveDirection = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                if moveDirection.Magnitude > 0 then
                    moveDirection = moveDirection.Unit * Options.FlightSpeed.Value
                end
                flyBV.Velocity = moveDirection
                flyPlatform.CFrame = player.Character.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
            end
        end)
    end)
end)

-- ✅ Universal Tween (Preserves Noclip/Nofall state)
pcall(function()
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until game.Players.LocalPlayer.Character 
        and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") 
        and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local players = game:GetService("Players")
    local rs = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")

    _G.originalspeed = 150
    _G.Speed = _G.originalspeed
    local tweenPlatform = Instance.new("Part")
    tweenPlatform.Name = "RW_TweenPlatform"
    tweenPlatform.Size = Vector3.new(30, 1, 30)
    tweenPlatform.Anchored = true
    tweenPlatform.CanCollide = true
    tweenPlatform.Transparency = 1
    tweenPlatform.Material = Enum.Material.SmoothPlastic
    tweenPlatform.BrickColor = BrickColor.new("Bright blue")

    local tweenBV = nil
    local tweenActive = false
    local prevNoclipState = false
    local prevNofallState = false

    local function createTweenBV()
        if tweenBV then
            tweenBV:Destroy()
        end
        tweenBV = Instance.new("BodyVelocity")
        tweenBV.Name = "RW_TweenBV"
        tweenBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        tweenBV.Velocity = Vector3.zero
        return tweenBV
    end

    local function resetTween()
        pcall(function()
            if players.LocalPlayer.Character and players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = players.LocalPlayer.Character.Humanoid
                humanoid.JumpPower = 50
                humanoid.WalkSpeed = 16
            end
            tweenPlatform.Parent = nil
            if tweenBV then
                tweenBV:Destroy()
                tweenBV = nil
            end
            if not prevNoclipState then
                MovementState:Disable("noclip", "UniversalTween")
            end
            if not prevNofallState then
                MovementState:Disable("nofall", "UniversalTween")
            end
            tweenActive = false
        end)
    end

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        pcall(function()
            if tweenActive then
                character:WaitForChild("Humanoid")
                character:WaitForChild("HumanoidRootPart")
                character.Humanoid.JumpPower = 0
                tweenPlatform.Parent = workspace
                tweenPlatform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                createTweenBV()
                tweenBV.Parent = character.HumanoidRootPart
                MovementState:Enable("noclip", "UniversalTween")
                MovementState:Enable("nofall", "UniversalTween")
            end
        end)
    end)

    local function createTween(targetPos, duration)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if _G.currentTween then
                _G.currentTween:Cancel()
            end
            _G.currentTween = TweenService:Create(
                hrp,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(targetPos)}
            )
            _G.currentTween:Play()
        end)
    end

    rs.RenderStepped:Connect(function()
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")

            if tweenActive and character and humanoid and hrp then
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
                        resetTween()
                        clearActiveMode("tween")
                    end
                end
                tweenBV.Velocity = Vector3.zero
                humanoid.JumpPower = 0
                tweenPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0)
                tweenPlatform.Parent = workspace
                if humanoid.Health <= 0 then
                    Library:Notify("Character Dead, Please Try Again", { Duration = 3 })
                    resetTween()
                    clearActiveMode("tween")
                end
            end
        end)
    end)

    _G.CustomTween = function(target)
        pcall(function()
            if not setActiveMode("tween") then
                Library:Notify("Higher priority mode active", {Duration = 3})
                return
            end
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                Library:Notify("Character not ready", {Duration = 3})
                return
            end
            local distance = (target - hrp.Position).Magnitude
            if distance > MAX_TWEEN_DISTANCE then
                Library:Notify("Target too far away!", { Duration = 3 })
                return
            end
            prevNoclipState = Toggles.NoclipToggle.Value
            prevNofallState = Toggles.NoFallDamage.Value
            MovementState:Enable("noclip", "UniversalTween")
            MovementState:Enable("nofall", "UniversalTween")
            character.Humanoid.JumpPower = 0
            tweenPlatform.Parent = workspace
            tweenPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0)
            createTweenBV()
            tweenBV.Parent = hrp
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
            resetTween()
            clearActiveMode("tween")
        end)
    end
end)

-- ✅ Attach-to-back (Fixed sliders, no persist after death)
pcall(function()
    local player = Players.LocalPlayer
    local attachBV = nil
    local attachPlatform = Instance.new("Part")
    attachPlatform.Name = "RW_AttachPlatform"
    attachPlatform.Size = Vector3.new(30, 1, 30)
    attachPlatform.Anchored = true
    attachPlatform.CanCollide = true
    attachPlatform.Transparency = 1
    attachPlatform.Material = Enum.Material.SmoothPlastic
    attachPlatform.BrickColor = BrickColor.new("Bright blue")
    local attachActive = false
    local targetPlayer = nil
    local originalJumpPower = 50
    local originalWalkSpeed = 16

    local function createAttachBV()
        if attachBV then
            attachBV:Destroy()
        end
        attachBV = Instance.new("BodyVelocity")
        attachBV.Name = "RW_AttachBV"
        attachBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        attachBV.Velocity = Vector3.zero
        return attachBV
    end

    local function resetAttach()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                humanoid.JumpPower = originalJumpPower
                humanoid.WalkSpeed = originalWalkSpeed
            end
            attachPlatform.Parent = nil
            if attachBV then
                attachBV:Destroy()
                attachBV = nil
            end
            MovementState:Disable("noclip", "AttachToBack")
            MovementState:Disable("nofall", "AttachToBack")
            attachActive = false
            targetPlayer = nil
        end)
    end

    Toggles.AttachtobackToggle:OnChanged(function(value)
        pcall(function()
            if value then
                if not setActiveMode("attach") then
                    Toggles.AttachtobackToggle:SetValue(false)
                    Library:Notify("Higher priority mode active", {Duration = 3})
                    return
                end
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
                    Toggles.AttachtobackToggle:SetValue(false)
                    Library:Notify("Character not ready", {Duration = 3})
                    return
                end
                targetPlayer = Players:FindFirstChild(Options.PlayerDropdown.Value)
                if not targetPlayer or targetPlayer == player or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Toggles.AttachtobackToggle:SetValue(false)
                    Library:Notify("Invalid or no target player selected", {Duration = 3})
                    return
                end
                originalJumpPower = char.Humanoid.JumpPower
                originalWalkSpeed = char.Humanoid.WalkSpeed
                char.Humanoid.JumpPower = 0
                char.Humanoid.WalkSpeed = 0
                attachPlatform.Parent = workspace
                attachPlatform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                createAttachBV()
                attachBV.Parent = char.HumanoidRootPart
                MovementState:Enable("noclip", "AttachToBack")
                MovementState:Enable("nofall", "AttachToBack")
                attachActive = true
            else
                resetAttach()
                clearActiveMode("attach")
            end
        end)
    end)

    player.CharacterAdded:Connect(function()
        pcall(function()
            if attachActive then
                Toggles.AttachtobackToggle:SetValue(false)
            end
        end)
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if attachActive and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myChar = player.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local targetPos = targetPlayer.Character.HumanoidRootPart.Position
                    local distance = Options.ATBDistance.Value
                    local height = Options.ATBHeight.Value
                    local behindPos = targetPos - (targetPlayer.Character.HumanoidRootPart.CFrame.LookVector * distance) + Vector3.new(0, height, 0)
                    myChar.HumanoidRootPart.CFrame = CFrame.new(behindPos, targetPos)
                    attachPlatform.CFrame = myChar.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                    attachBV.Velocity = Vector3.zero
                end
            end
        end)
    end)
end)

-- ✅ No Fall Damage (Persists after death/reset)
pcall(function()
    if not Toggles or not Toggles.NoFallDamage then return end

    local function applyNofallState()
        if Toggles.NoFallDamage.Value then
            MovementState:Enable("nofall", "NoFallDamage")
        else
            MovementState:Disable("nofall", "NoFallDamage")
        end
    end

    Toggles.NoFallDamage:OnChanged(function(value)
        applyNofallState()
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        applyNofallState()
    end)

    -- Initial check
    applyNofallState()
end)

-- ✅ No Killbricks
pcall(function()
    if not Toggles or not Toggles.DisableCharacterTouchToggle then return end

    local function disableTouch(character)
        pcall(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.CanTouch = false
                end
            end
        end)
    end

    Toggles.DisableCharacterTouchToggle:OnChanged(function(value)
        pcall(function()
            if value and LocalPlayer.Character then
                disableTouch(LocalPlayer.Character)
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        if Toggles.DisableCharacterTouchToggle.Value then
            disableTouch(character)
        end
    end)
end)

-- ✅ Anti-AA Bypass
pcall(function()
    if not Toggles or not Toggles.SwimStatusToggle then return end

    local function setSwimStatus(value)
        pcall(function()
            local status = workspace:WaitForChild("Living"):WaitForChild(LocalPlayer.Name):WaitForChild("Status")
            if value then
                local swimFolder = Instance.new("Folder")
                swimFolder.Name = "SwimStatus"
                swimFolder.Parent = status
            else
                local swimFolder = status:FindFirstChild("SwimStatus")
                if swimFolder then
                    swimFolder:Destroy()
                end
            end
        end)
    end

    Toggles.SwimStatusToggle:OnChanged(function(value)
        setSwimStatus(value)
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        if Toggles.SwimStatusToggle.Value then
            setSwimStatus(true)
        end
    end)
end)

-- ✅ Player ESP
pcall(function()
    local function addESP(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Name = "RW_ESP"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.Parent = player.Character
        end)
    end

    local function removeESP(player)
        pcall(function()
            if player.Character then
                local highlight = player.Character:FindFirstChild("RW_ESP")
                if highlight then
                    highlight:Destroy()
                end
            end
        end)
    end

    Toggles.PlayerESP:OnChanged(function(value)
        pcall(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if value then
                    addESP(plr)
                else
                    removeESP(plr)
                end
            end
        end)
    end)

    Players.PlayerAdded:Connect(function(player)
        if Toggles.PlayerESP.Value then
            player.CharacterAdded:Connect(function()
                addESP(player)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)
end)

-- ✅ Moderator Notifier
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local NotificationGui = nil
    local NotificationLabel = nil
    local IsMonitoring = false
    local MonitorConn = nil
    local MonitoredPlayers = {}
    local UserCache = {}

    _G.MonitoredUsers = {
        [15877374] = {username = "Arch_Mage", roleName = "Developers"},
        [25825868] = {username = "RagDollMoment", roleName = "Developers"},
        [107177201] = {username = "Lunarchs", roleName = "Developers"},
        [1222525363] = {username = "itsprettybad", roleName = "Developers"},
        [15877374] = {username = "Arch_Mage", roleName = "The Hydra"},
        [25825868] = {username = "RagDollMoment", roleName = "The Hydra"},
        [107177201] = {username = "Lunarchs", roleName = "The Hydra"},
        [1222525363] = {username = "itsprettybad", roleName = "The Hydra"},
        [113208] = {username = "Vespei", roleName = "Community Manager"},
        [196241377] = {username = "AstralK0", roleName = "Senior Moderator"},
        [150169332] = {username = "NotAn_Alt", roleName = "Moderator"},
        [162562661] = {username = "Xarionette", roleName = "Moderator"},
        [138806257] = {username = "Noxturnal", roleName = "Moderator"},
        [156133047] = {username = "2L15m", roleName = "Moderator"},
        [159347179] = {username = "anchqor", roleName = "Moderator"},
        [173478108] = {username = "Sevred", roleName = "Moderator"},
        [1745313990] = {username = "SkyesDev", roleName = "Moderator"},
        [2494039335] = {username = "iAstraI", roleName = "Moderator"},
        [384554889] = {username = "N1GHT_R", roleName = "Tester"},
        [521426118] = {username = "SanctifiedSeraph", roleName = "Tester"},
        [3217076177] = {username = "TheMelodicBlu", roleName = "Tester"},
        [2707242978] = {username = "BensRogueLineageGaia", roleName = "Tester"},
        [139151151] = {username = "NorwoodScale", roleName = "Tester"},
        [2910654] = {username = "Ryrasil", roleName = "Tester"},
        [764944189] = {username = "joshhuahgamin", roleName = "Tester"},
        [116102814] = {username = "XyeurianDemascus", roleName = "Tester"},
        [217341439] = {username = "Derekjwd000", roleName = "Tester"},
        [766793221] = {username = "m_iini", roleName = "Tester"},
        [1187943190] = {username = "U_nknownEA", roleName = "Tester"},
        [16773526] = {username = "Tentorian", roleName = "Tester"},
        [668171947] = {username = "Inganlovemas1", roleName = "Tester"},
        [996597352] = {username = "drewsk_i", roleName = "Tester"},
        [2794059824] = {username = "LostalImysanity", roleName = "Tester"},
        [4536767005] = {username = "B1lankss", roleName = "Tester"},
        [383110716] = {username = "tavavayj", roleName = "Tester"},
        [1229151960] = {username = "Shadow_2474", roleName = "Tester"},
        [156133047] = {username = "2L15m", roleName = "Tester"},
        [2957030770] = {username = "FishNecromancer", roleName = "Tester"},
        [78138248] = {username = "awri3785", roleName = "Tester"},
        [1337469163] = {username = "Jojoactor626", roleName = "Tester"},
        [143360462] = {username = "Prxnce_Tulip", roleName = "Tester"},
        [530841328] = {username = "jackthesmith1901", roleName = "Tester"},
        [41972028] = {username = "SalmonSmasher", roleName = "Tester"},
        [187318758] = {username = "Mikey_2017", roleName = "Tester"},
        [3079251025] = {username = "Kitt_ard", roleName = "Tester"},
        [123065424] = {username = "deaxfoom", roleName = "Tester"},
        [1881210431] = {username = "flxffed", roleName = "Tester"},
        [79802728] = {username = "cadas0123a", roleName = "Tester"},
        [292024748] = {username = "idskuchiha", roleName = "Tester"},
        [497491742] = {username = "Tarzan20070", roleName = "Tester"},
        [1867852294] = {username = "iFallens", roleName = "Tester"},
        [159347179] = {username = "anchqor", roleName = "Tester"},
        [1712209259] = {username = "SeverTheSkylines", roleName = "Tester"},
        [3540079828] = {username = "navurns", roleName = "Tester"},
        [103459910] = {username = "XmanZogratis", roleName = "Tester"},
        [534197831] = {username = "Doritochip46", roleName = "Tester"},
        [185019792] = {username = "survivor2111", roleName = "Tester"},
        [127596422] = {username = "XionOH", roleName = "Tester"},
        [1553967784] = {username = "jamalissostupid", roleName = "Tester"},
        [304438466] = {username = "sg0y", roleName = "Tester"},
        [683752651] = {username = "InfinityMemez", roleName = "Tester"},
        [2350139151] = {username = "lokkqrave", roleName = "Tester"},
        [31921665] = {username = "TonyLikesRice", roleName = "Tester"},
        [126159866] = {username = "hisbrat", roleName = "Tester"},
        [36577164] = {username = "yawa400", roleName = "Tester"},
        [66378169] = {username = "MegacraftBuilder", roleName = "Tester"},
        [55471665] = {username = "blitz5468", roleName = "Tester"},
        [77890505] = {username = "Vae1yx", roleName = "Tester"},
        [157133351] = {username = "bIastiin", roleName = "Tester"},
        [446816519] = {username = "RokkuZum", roleName = "Tester"},
        [3441461569] = {username = "SleepyJingle", roleName = "Tester"},
        [130175745] = {username = "lomi26", roleName = "Tester"},
        [2585457105] = {username = "Jeusant", roleName = "Tester"},
        [68831624] = {username = "LmaoOreoz", roleName = "Tester"},
        [485468501] = {username = "rCaptainChaos", roleName = "Tester"},
        [2879483125] = {username = "CTB_Akashi", roleName = "Tester"},
        [163387406] = {username = "maximilianotony", roleName = "Tester"},
        [2789875252] = {username = "Alternate_EEE", roleName = "Tester"},
        [319436867] = {username = "Nicholasharry", roleName = "Tester"},
        [72409843] = {username = "LuauBread", roleName = "Tester"},
        [2556168630] = {username = "bulletproofpickle", roleName = "Tester"},
        [981026482] = {username = "BlenderDemon", roleName = "Tester"},
        [200170674] = {username = "XElit3Killer42X", roleName = "Tester"},
        [2978393899] = {username = "hai250512", roleName = "Tester"},
        [523307562] = {username = "BoyNamedElite", roleName = "Tester"},
        [305108529] = {username = "Gavin1621", roleName = "Tester"},
        [122012377] = {username = "LAA1233", roleName = "Tester"},
        [43564517] = {username = "Sagee4", roleName = "Tester"},
        [167592863] = {username = "Foxtrot_Burst", roleName = "Tester"},
        [170516141] = {username = "o_Oooxy", roleName = "Tester"},
        [722595047] = {username = "Paheemala", roleName = "Tester"},
        [121156347] = {username = "ShinmonSan", roleName = "Tester"},
        [2035294938] = {username = "rentakkj", roleName = "Tester"},
        [135312065] = {username = "chunchbunch", roleName = "Tester"},
        [952327584] = {username = "Fayelligent", roleName = "Tester"},
        [908078373] = {username = "OkamiyourgodYT", roleName = "Tester"},
        [4742716911] = {username = "ScrollOfFloresco", roleName = "Tester"},
        [72585073] = {username = "Sn_1pz", roleName = "Tester"},
        [511378013] = {username = "singlemother36", roleName = "Tester"},
        [810330156] = {username = "Silv3y", roleName = "Tester"},
        [35014890] = {username = "OGStr8", roleName = "Tester"},
        [33143240] = {username = "d_avidd", roleName = "Tester"},
        [231640937] = {username = "halokiller892", roleName = "Tester"},
        [42379546] = {username = "AnbuKen", roleName = "Tester"},
        [1087856074] = {username = "tdawg5445", roleName = "Tester"},
        [201726743] = {username = "FastThunderDragon123", roleName = "Tester"},
        [104355703] = {username = "ii_Justice", roleName = "Tester"},
        [192257017] = {username = "Dandado", roleName = "Tester"},
        [3296935891] = {username = "nickhax123", roleName = "Tester"},
        [232494686] = {username = "Guardbabi", roleName = "Tester"},
        [3248951452] = {username = "Jacey_pp", roleName = "Tester"},
        [287218312] = {username = "christianisthebest9", roleName = "Tester"},
        [19026337] = {username = "neogi", roleName = "Tester"},
        [1520636666] = {username = "AnbuK3n", roleName = "Tester"},
        [339253441] = {username = "hooyadaddddyyy", roleName = "Tester"},
        [1889658724] = {username = "AnbuKane", roleName = "Tester"},
        [275644813] = {username = "Brytheous", roleName = "Tester"},
        [1092798493] = {username = "SkyNiOmni", roleName = "Tester"},
        [1090317348] = {username = "rosomig", roleName = "Tester"},
        [85953824] = {username = "MrBonkDonk", roleName = "Tester"},
        [99149580] = {username = "fireshatter", roleName = "Tester"},
        [153296461] = {username = "HardGoldenPolarBear", roleName = "Tester"},
        [973488825] = {username = "malusinha_doida", roleName = "Tester"},
        [149066591] = {username = "rexepoyt", roleName = "Tester"},
        [158002164] = {username = "SkillessDev", roleName = "Tester"},
        [866972473] = {username = "blendergod99", roleName = "Tester"},
        [4155040838] = {username = "hollywoodcolex", roleName = "Tester"},
        [516378013] = {username = "Forg3dx", roleName = "Tester"},
        [7314301709] = {username = "MalevolentKaioshin", roleName = "Tester"},
        [73215632] = {username = "upperment", roleName = "Tester"},
        [12452343] = {username = "thecool19", roleName = "Tester"},
        [227228547] = {username = "xxxxbastionxxxx", roleName = "Tester"},
        [706176524] = {username = "Eriiku", roleName = "Tester"},
        [106663853] = {username = "wizard407", roleName = "Tester"},
        [1567623135] = {username = "Altaccount030306", roleName = "Tester"},
        [286410421] = {username = "lightempero", roleName = "Tester"},
        [2271508534] = {username = "DragonBallGoku_BR493", roleName = "Tester"},
        [1830547188] = {username = "AstralFourteen", roleName = "Tester"},
        [306788398] = {username = "BriarValkyr", roleName = "Tester"},
        [553272836] = {username = "Sylvefied", roleName = "Tester"}
    }

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
    end

    local function getPlayerRole(player)
        if not player then return nil end
        if UserCache[player.UserId] then
            UserCache[player.UserId].username = player.Name
            return UserCache[player.UserId]
        end
        local role = _G.MonitoredUsers[player.UserId]
        if role then
            UserCache[player.UserId] = {username = player.Name, roleName = role.roleName}
            return UserCache[player.UserId]
        end
        UserCache[player.UserId] = {username = player.Name, roleName = "None"}
        return nil
    end

    local function updateNotification()
        local rolePlayers = {}
        for player, role in pairs(MonitoredPlayers) do
            table.insert(rolePlayers, role.roleName .. " is in server: " .. player.Name)
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
    end

    local function scanPlayers()
        coroutine.wrap(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local role = getPlayerRole(player)
                    if role then
                        MonitoredPlayers[player] = role
                    end
                end
                task.wait() -- Yield to prevent freezing
            end
            updateNotification()
        end)()
    end

    local function startMonitoring()
        if IsMonitoring then return end
        IsMonitoring = true
        scanPlayers()
        MonitorConn = Players.PlayerAdded:Connect(function(player)
            pcall(function()
                if player == LocalPlayer then return end
                local role = getPlayerRole(player)
                if role then
                    MonitoredPlayers[player] = role
                    updateNotification()
                end
            end)
        end)
        Players.PlayerRemoving:Connect(function(player)
            pcall(function()
                if player == LocalPlayer then return end
                if MonitoredPlayers[player] then
                    MonitoredPlayers[player] = nil
                    UserCache[player.UserId] = nil
                    updateNotification()
                end
            end)
        end)
    end

    local function stopMonitoring()
        if not IsMonitoring then return end
        IsMonitoring = false
        if MonitorConn then
            MonitorConn:Disconnect()
            MonitorConn = nil
        end
        MonitoredPlayers = {}
        if NotificationGui then
            NotificationGui:Destroy()
            NotificationGui = nil
            NotificationLabel = nil
        end
        UserCache = {}
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

-- ✅ Auto Kick
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

    local UserCache = {}

    local function safeGet(obj, ...)
        local args = {...}
        for i, v in ipairs(args) do
            local ok, res = pcall(function() return obj[v] end)
            if not ok then
                return nil
            end
            obj = res
            if not obj then
                return nil
            end
        end
        return obj
    end

    local function getPlayerRole(player)
        if not player then return nil end
        if UserCache[player.UserId] then
            UserCache[player.UserId].username = player.Name
            return UserCache[player.UserId]
        end
        local role = _G.MonitoredUsers[player.UserId]
        if role then
            UserCache[player.UserId] = {username = player.Name, roleName = role.roleName}
            return UserCache[player.UserId]
        end
        UserCache[player.UserId] = {username = player.Name, roleName = "None"}
        return nil
    end

    local function checkAndKick()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local role = getPlayerRole(player)
                if role and table.find(TargetRoles, role.roleName) then
                    LocalPlayer:Kick("Detected staff member: " .. role.roleName .. " (" .. player.Name .. ")")
                    return
                end
            end
        end
    end

    local function startKicking()
        if IsKickingEnabled then
            return
        end
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
    end

    local function stopKicking()
        if not IsKickingEnabled then
            return
        end
        IsKickingEnabled = false
        if MonitorConn then
            MonitorConn:Disconnect()
            MonitorConn = nil
        end
        UserCache = {}
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
Library.KeybindFrame.Visible = true

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Ratware")
SaveManager:SetFolder("Ratware/Rogueblox")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:LoadAutoloadConfig()
