local MAX_TWEEN_DISTANCE = 50000 -- Configurable max distance for tweens
if _G.RatwareLoaded then
    Library:Unload()
    return
end
_G.RatwareLoaded = true

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
VisualsGroup:AddToggle("PlayerESPName", {
    Text = "Username & Distance",
    Default = false
})
VisualsGroup:AddToggle("PlayerESPHealthbar", {
    Text = "Show Health Bar",
    Default = false
})
VisualsGroup:AddToggle("PlayerESPHealthText", {
    Text = "Show Health Text",
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


-- Fly/Flight Module


-- Noclip Module


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

--Player ESP Module
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local function createDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local espData = {}

    local function addHighlight(player)
        if player == LocalPlayer or not player.Character then return end
        pcall(function()
            if not player.Character:FindFirstChild("Player_ESP") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Player_ESP"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.FillColor = Color3.fromRGB(255, 130, 0)
                highlight.Parent = player.Character
            end
        end)
    end

    local function removeHighlight(player)
        pcall(function()
            if player.Character then
                local highlight = player.Character:FindFirstChild("Player_ESP")
                if highlight then highlight:Destroy() end
            end
        end)
    end

    local function monitorCharacter(player)
        if not player then return end
        player.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then
                addHighlight(player)
            end
        end)
    end

    local function createESP(player)
        if player == LocalPlayer or espData[player] then return end

        local healthbarWidth = 50
        local healthbarHeight = 5

        espData[player] = {
            NameText = createDrawing("Text", {Size=14, Center=true, Outline=true, Visible=false}),
            HealthText = createDrawing("Text", {Size=14, Center=true, Outline=true, Visible=false}),
            HealthBarBG = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,0,0), Visible=false}),
            HealthBarFill = createDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,255,0), Visible=false}),
            HealthBarWidth = healthbarWidth,
            HealthBarHeight = healthbarHeight
        }

        monitorCharacter(player)
    end

    local function removeESP(player)
        if espData[player] then
            for _, obj in pairs(espData[player]) do
                pcall(function() obj:Remove() end)
            end
            espData[player] = nil
        end
    end

    RunService.RenderStepped:Connect(function()
        for player, drawings in pairs(espData) do
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not head or not humanoid or humanoid.Health <= 0 then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
                continue
            end

            local success, pos2D, onScreen = pcall(function()
                return Camera:WorldToViewportPoint(head.Position)
            end)
            if not success or not onScreen then
                drawings.NameText.Visible = false
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
                drawings.HealthText.Visible = false
                continue
            end

            local buffer = 4
            local usernameHeight = drawings.NameText.TextBounds.Y
            local healthTextHeight = drawings.HealthText.TextBounds.Y
            local healthbarHeight = drawings.HealthBarHeight
            local healthbarWidth = drawings.HealthBarWidth
            local totalHeight = usernameHeight + buffer + healthbarHeight + buffer + healthTextHeight
            local verticalOffset = 20

            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local dist = (head.Position - Camera.CFrame.Position).Magnitude

            -- Name + Distance
            if Toggles.PlayerESPName.Value then
                drawings.NameText.Text = string.format("[%s] [%dm]", player.Name, math.floor(dist))
                drawings.NameText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 - verticalOffset)
                drawings.NameText.Color = Color3.fromRGB(255,255,255)
                drawings.NameText.Visible = true
            else
                drawings.NameText.Visible = false
            end

            -- Health bar
            if Toggles.PlayerESPHealthbar.Value then
                drawings.HealthBarBG.Position = Vector2.new(pos2D.X - healthbarWidth/2, pos2D.Y - totalHeight/2 + usernameHeight + buffer - verticalOffset)
                drawings.HealthBarBG.Size = Vector2.new(healthbarWidth, healthbarHeight)
                drawings.HealthBarBG.Visible = true

                drawings.HealthBarFill.Position = drawings.HealthBarBG.Position
                drawings.HealthBarFill.Size = Vector2.new(healthbarWidth * math.clamp(health/maxHealth,0,1), healthbarHeight)
                drawings.HealthBarFill.Color = Color3.fromRGB(
                    math.floor(255 - 255*(health/maxHealth)),
                    math.floor(255*(health/maxHealth)),
                    0
                )
                drawings.HealthBarFill.Visible = true
            else
                drawings.HealthBarBG.Visible = false
                drawings.HealthBarFill.Visible = false
            end

            -- Health text
            if Toggles.PlayerESPHealthText.Value then
                drawings.HealthText.Text = string.format("[%d/%d]", math.floor(health), math.floor(maxHealth))
                drawings.HealthText.Position = Vector2.new(pos2D.X, pos2D.Y - totalHeight/2 + usernameHeight + buffer + healthbarHeight + buffer - verticalOffset)
                drawings.HealthText.Color = Color3.fromRGB(
                    math.floor(255 - 255*(health/maxHealth)),
                    math.floor(255*(health/maxHealth)),
                    0
                )
                drawings.HealthText.Visible = true
            else
                drawings.HealthText.Visible = false
            end
        end
    end)

    -- Toggles
    Toggles.PlayerESP:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val then addHighlight(p) else removeHighlight(p) end
        end
    end)

    Toggles.PlayerESPName:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    Toggles.PlayerESPHealthbar:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    Toggles.PlayerESPHealthText:OnChanged(function(val)
        for _, p in pairs(Players:GetPlayers()) do
            if val and not espData[p] then createESP(p) end
        end
    end)

    Players.PlayerAdded:Connect(function(plr)
        createESP(plr)
        plr.CharacterAdded:Connect(function()
            if Toggles.PlayerESP.Value then addHighlight(plr) end
        end)
    end)
    Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
        removeHighlight(plr)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        createESP(plr)
        if Toggles.PlayerESP.Value then addHighlight(plr) end
    end
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
    platform.Size = Vector3.new(30, 1, 30)
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
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
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
            local character = players.LocalPlayer.Character
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
end)

--Attach to back Module

--Mod Detection Module
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local NotificationGui = nil
    local NotificationLabel = nil
    local IsMonitoring = false
    local MonitorConn = nil
    local UserCache = {} -- Cache: {UserId = {username, roleName}}
    local MonitoredPlayers = {} -- Tracks players with roles in the server

    -- MonitoredUsers as a dictionary for O(1) lookup
    local MonitoredUsers = {
        [116279325] = {username = "MichaelpizzaXD", roleName = "Developers"},
        [101557551] = {username = "MlgArcOfOz", roleName = "Developers"},
        [66885812] = {username = "MiniTomBomb", roleName = "Developers"},
        [151823512] = {username = "KrackenLackin", roleName = "Developers"},
        [7098519935] = {username = "RoguebloxHolder", roleName = "Community Manager"},
        [23898168] = {username = "LordDogeus", roleName = "Community Manager"},
        [508010705] = {username = "bs4b", roleName = "Secret Tester"},
        [2348176237] = {username = "Ropbloxd", roleName = "Secret Tester"},
        [101472496] = {username = "IWish4Food", roleName = "Secret Tester"},
        [137156947] = {username = "clownmesh", roleName = "Secret Tester"},
        [91088194] = {username = "snadwich_man", roleName = "Secret Tester"},
        [5639568198] = {username = "antilocapras", roleName = "Secret Tester"},
        [2739168703] = {username = "MinusEightSilver", roleName = "Secret Tester"},
        [2203438314] = {username = "MoonfullBliss", roleName = "Secret Tester"},
        [83568697] = {username = "xavierqwl123", roleName = "Secret Tester"},
        [886895436] = {username = "FlibbetFlobbet", roleName = "Secret Tester"},
        [454125614] = {username = "DaveCombat", roleName = "Secret Tester"},
        [2253843707] = {username = "Gatemaster159", roleName = "Secret Tester"},
        [400064133] = {username = "FrickTaco", roleName = "Secret Tester"},
        [4467110029] = {username = "MurderMaster02_4", roleName = "Secret Tester"},
        [1584543391] = {username = "DemankIes", roleName = "Secret Tester"},
        [545676359] = {username = "Magno_1725", roleName = "Secret Tester"},
        [1198202820] = {username = "Watersheepgod123", roleName = "Secret Tester"},
        [50531342] = {username = "j_xhnny", roleName = "Secret Tester"},
        [466307225] = {username = "GameAwesome128", roleName = "Secret Tester"},
        [2627739850] = {username = "OneLifeSuper", roleName = "Secret Tester"},
        [8355205283] = {username = "mrGIANTviking", roleName = "Secret Tester"},
        [684490283] = {username = "Falmsas", roleName = "Secret Tester"},
        [96606405] = {username = "xxstarshooterxx1", roleName = "Secret Tester"},
        [537619474] = {username = "fenaerii", roleName = "Secret Tester"},
        [409518603] = {username = "Floof_Fully", roleName = "Secret Tester"},
        [211211867] = {username = "TomelessX", roleName = "Secret Tester"},
        [2311317483] = {username = "Liutzia", roleName = "Secret Tester"},
        [15147688] = {username = "RuneArtifact", roleName = "Secret Tester"},
        [839001197] = {username = "Miraelith", roleName = "Secret Tester"},
        [4025386553] = {username = "SheepInSheepSkinRBX", roleName = "Secret Tester"},
        [920566] = {username = "eld", roleName = "Secret Tester"},
        [9160671302] = {username = "Dinglenutjohnson3rd", roleName = "Secret Tester"},
        [390617393] = {username = "rarex00x", roleName = "Secret Tester"},
        [167343092] = {username = "fastdogekid", roleName = "Secret Tester"},
        [9185362166] = {username = "Dinglenutjohnson4th", roleName = "Secret Tester"},
        [476747151] = {username = "Gorgus_Official", roleName = "Secret Tester"},
        [46354252] = {username = "Ijazezane", roleName = "Senior Moderator"},
        [172863828] = {username = "Valerame3", roleName = "Senior Moderator"},
        [71517753] = {username = "upbeatbidachi", roleName = "Senior Moderator"},
        [56632783] = {username = "Coletrayne", roleName = "The Hydra"},
        [6056339939] = {username = "NotAhmi4", roleName = "Junior Moderator"},
        [475990670] = {username = "blzz4rd", roleName = "Junior Moderator"},
        [1834007574] = {username = "MintyKobold", roleName = "Junior Moderator"},
        [1745860240] = {username = "AstralZix", roleName = "Junior Moderator"},
        [985681917] = {username = "PikaNubby", roleName = "Junior Moderator"},
        [33242043] = {username = "piercingTYB", roleName = "Junior Moderator"},
        [83742361] = {username = "0utcastGhost", roleName = "Junior Moderator"},
        [3761770969] = {username = "MogaApht", roleName = "Moderator"},
        [472265489] = {username = "NicoCTR", roleName = "Moderator"},
        [1443529743] = {username = "RetroFungi", roleName = "Moderator"},
        [132854348] = {username = "Luci_Lucid", roleName = "Moderator"},
        [97857665] = {username = "PacificState", roleName = "Moderator"},
        [178196494] = {username = "iSuikazu", roleName = "Moderator"},
        [1814937056] = {username = "psyych1c", roleName = "Moderator"},
        [98475312] = {username = "mooshoo0629", roleName = "Moderator"},
        [88734055] = {username = "Umbraheim", roleName = "Moderator"},
        [105477497] = {username = "mosquirt04x", roleName = "Moderator"},
        [98823832] = {username = "Tooleria", roleName = "Moderator"},
        [750126545] = {username = "MikeBikiCiki", roleName = "Moderator"},
        [2482521968] = {username = "kronksdonks", roleName = "Moderator"},
        [494876909] = {username = "NightFumi", roleName = "Moderator"},
        [368760757] = {username = "hadarqki", roleName = "Moderator"},
        [1325204143] = {username = "JordyVibing", roleName = "Moderator"},
        [296471697] = {username = "ThugFuny", roleName = "Moderator"},
        [1230105665] = {username = "savefloppa", roleName = "Moderator"},
        [94943072] = {username = "2qrys", roleName = "Co-Owner"},
        [568447733] = {username = "VortexLineZ", roleName = "Tester"},
        [288068260] = {username = "Fruchtriegel", roleName = "Tester"},
        [2067212412] = {username = "2v1mee", roleName = "Tester"},
        [177841301] = {username = "Xdancjoz", roleName = "Tester"},
        [541694484] = {username = "Sayumiko_Inubashiri", roleName = "Tester"},
        [200296369] = {username = "kir_bu", roleName = "Tester"},
        [105642986] = {username = "Spikedaniel1", roleName = "Tester"},
        [118232953] = {username = "Acroze_0", roleName = "Tester"},
        [2272201650] = {username = "gamergodH8", roleName = "Tester"},
        [1391134999] = {username = "Voayn", roleName = "Tester"},
        [591754050] = {username = "Ftwnitro", roleName = "Tester"},
        [94377328] = {username = "Adome1000", roleName = "Tester"},
        [328804443] = {username = "minipixel37", roleName = "Tester"},
        [1721299790] = {username = "AisarRedux", roleName = "Tester"},
        [443301913] = {username = "BaconFlakesFoLife", roleName = "Tester"},
        [1525954431] = {username = "king_req2", roleName = "Tester"},
        [164659205] = {username = "YugoEliatrope", roleName = "Tester"},
        [109880601] = {username = "kazuhirawillow", roleName = "Tester"},
        [1255232483] = {username = "D7X37", roleName = "Tester"},
        [3072563956] = {username = "AMONGOlDS", roleName = "Tester"},
        [60501176] = {username = "A_SpoopyPixel", roleName = "Tester"},
        [1538684653] = {username = "v4mp6vrl", roleName = "Tester"},
        [95115478] = {username = "Apocalytra", roleName = "Tester"},
        [171849433] = {username = "pumpkinmoo06", roleName = "Tester"},
        [238689577] = {username = "XK4nekiX", roleName = "Tester"},
        [3134234164] = {username = "BoubaStep", roleName = "Tester"},
        [64146960] = {username = "Jayden080811", roleName = "Tester"},
        [936850490] = {username = "Arkomis", roleName = "Tester"},
        [75576146] = {username = "RubloxProster", roleName = "Tester"},
        [1301594729] = {username = "AscendingO", roleName = "Tester"},
        [1593663486] = {username = "levvenooo", roleName = "Tester"},
        [1183277097] = {username = "QAZWERTZU", roleName = "Tester"},
        [119813128] = {username = "ASFNIN10DO", roleName = "Tester"},
        [55978613] = {username = "Eir_6", roleName = "Tester"},
        [1810420170] = {username = "YataaMirror", roleName = "Tester"},
        [295400019] = {username = "NordFraey", roleName = "Tester"},
        [50923052] = {username = "FarmerTommi", roleName = "Tester"},
        [1857182681] = {username = "dreamdemonz", roleName = "Tester"},
        [147290047] = {username = "Akuma321123", roleName = "Tester"},
        [1462759064] = {username = "Swusshy", roleName = "Tester"},
        [696449051] = {username = "gamer_lits", roleName = "Tester"},
        [1213458167] = {username = "xXLyr_icalXx", roleName = "Tester"},
        [3309856286] = {username = "Altey_z", roleName = "Tester"},
        [677421053] = {username = "Glarpys", roleName = "Tester"},
        [556687212] = {username = "Zawzeu", roleName = "Tester"},
        [121334527] = {username = "coolsnakez", roleName = "Tester"},
        [136103834] = {username = "david50high", roleName = "Tester"},
        [121138965] = {username = "onajimi", roleName = "Tester"},
        [2029492895] = {username = "AstonishingAdvantage", roleName = "Tester"},
        [84902083] = {username = "EquinoxLeech", roleName = "Tester"},
        [118368051] = {username = "GalaxyDudeNinja1", roleName = "Tester"},
        [1546714877] = {username = "Hollodron04x", roleName = "Tester"},
        [2040850419] = {username = "asuraispog1", roleName = "Tester"},
        [48317343] = {username = "T4ktical", roleName = "Tester"},
        [792994343] = {username = "ptl483", roleName = "Tester"},
        [5905225] = {username = "firestarfeyfire", roleName = "Tester"},
        [113363377] = {username = "a23way", roleName = "Tester"},
        [64827712] = {username = "DatBoiOmon_e", roleName = "Tester"},
        [304468388] = {username = "realityticks", roleName = "Tester"},
        [119948127] = {username = "miasmers", roleName = "Tester"},
        [1258601659] = {username = "Dr_BruhMoment", roleName = "Tester"},
        [2643269] = {username = "meteorshower", roleName = "Tester"},
        [302306519] = {username = "dontay1796", roleName = "Tester"},
        [1279850752] = {username = "xxxBenjidabeastxxx", roleName = "Tester"},
        [2980417565] = {username = "AutoGamezzzzYT", roleName = "Tester"},
        [15400033] = {username = "eliciety", roleName = "Tester"},
        [1209943600] = {username = "rinacavemanoogabooga", roleName = "Tester"},
        [2791735478] = {username = "kajuxas42", roleName = "Tester"},
        [45805731] = {username = "Julsons", roleName = "Tester"},
        [85752191] = {username = "Blaketerraria", roleName = "Tester"},
        [139532477] = {username = "goodteam5", roleName = "Tester"},
        [171068753] = {username = "bucketcube_d", roleName = "Tester"},
        [128562610] = {username = "nongnine2549", roleName = "Tester"},
        [121096035] = {username = "l4zy_b0i", roleName = "Tester"},
        [3234444804] = {username = "Poorabar", roleName = "Tester"},
        [87667744] = {username = "melovesonic", roleName = "Tester"},
        [154551041] = {username = "BrownSun_flower", roleName = "Tester"},
        [2702542109] = {username = "FallionsGurlFriend", roleName = "Tester"},
        [244275943] = {username = "boptodatop", roleName = "Tester"},
        [618526197] = {username = "0charliee", roleName = "Tester"},
        [85696426] = {username = "piknishi", roleName = "Tester"},
        [27243005] = {username = "kal_vo", roleName = "Tester"},
        [259956393] = {username = "synthosize0", roleName = "Tester"},
        [25419739] = {username = "dough_jkl", roleName = "Tester"},
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
        local role = MonitoredUsers[player.UserId]
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

    -- Reference the MonitoredUsers table from ModeratorNotifier
    local MonitoredUsers = _G.MonitoredUsers or {}
    local UserCache = {} -- Cache: {UserId = {username, roleName}}

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
        for _, user in ipairs(MonitoredUsers) do
            if user.userId == player.UserId then
                UserCache[player.UserId] = {username = player.Name, roleName = user.roleName}
                return UserCache[player.UserId]
            end
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
Library.KeybindFrame.Visible = true; 

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Ratware")
SaveManager:SetFolder("Ratware/Rogueblox")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:LoadAutoloadConfig()
