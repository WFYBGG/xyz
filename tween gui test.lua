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



--START MODULES
--START MODULES
local MainGroup3 = Tabs.Main:AddRightGroupbox("Universal Tween")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- Fly, Noclip, Nofall mechanisms
local flyActive = false
local flyPlatform = Instance.new("Part")
flyPlatform.Name = "FlyPlatform"
flyPlatform.Size = Vector3.new(10, 1, 10) -- Increased size
flyPlatform.Anchored = true
flyPlatform.CanCollide = true
flyPlatform.Transparency = 0.75
flyPlatform.Material = Enum.Material.SmoothPlastic
flyPlatform.BrickColor = BrickColor.new("Bright blue")

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)

local function enableFly()
    local success, result = pcall(function()
        local player = Players.LocalPlayer
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            flyPlatform.Parent = Workspace
            flyPlatform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
            bodyVelocity.Parent = character.HumanoidRootPart
            character.Humanoid.JumpPower = 0
            flyActive = true
            print("Fly enabled")
        end
    end)
    if not success then
        print("Failed to enable fly: " .. tostring(result))
    end
end

local function disableFly()
    local success, result = pcall(function()
        flyPlatform.Parent = nil
        bodyVelocity.Parent = nil
        local character = Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = 50
        end
        flyActive = false
        print("Fly disabled")
    end)
    if not success then
        print("Failed to disable fly: " .. tostring(result))
    end
end

local noclipActive = false
local function enableNoclip()
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            noclipActive = true
            print("Noclip enabled")
        end
    end)
    if not success then
        print("Failed to enable noclip: " .. tostring(result))
    end
end

local function disableNoclip()
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            noclipActive = false
            print("Noclip disabled")
        end
    end)
    if not success then
        print("Failed to disable noclip: " .. tostring(result))
    end
end

local nofallActive = false
local fallDamageCD = Instance.new("Folder")
fallDamageCD.Name = "FallDamageCD"
local function enableNofall()
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        if character and character:FindFirstChild("Status") then
            fallDamageCD.Parent = character.Status
            nofallActive = true
            print("Nofall enabled")
        end
    end)
    if not success then
        print("Failed to enable nofall: " .. tostring(result))
    end
end

local function disableNofall()
    local success, result = pcall(function()
        fallDamageCD.Parent = nil
        nofallActive = false
        print("Nofall disabled")
    end)
    if not success then
        print("Failed to disable nofall: " .. tostring(result))
    end
end

-- Tween system
local areaTweenActive = false
local npcTweenActive = false
local currentTween = nil

local function getPositionFromEntry(entry)
    local position = nil
    local success, result = pcall(function()
        -- Check if entry is an area
        if table.find(areaList, entry) then
            local areaPart = ReplicatedStorage.WorldModel.AreaMarkers[entry]
            if areaPart then
                return areaPart.CFrame.Position
            end
        else
            -- Handle NPC entries
            local npcName, areaName = entry:match("^([^,]+), (.+)$")
            if npcName and areaName then
                -- Handle TownMarkers NPCs (e.g., "Port, Blacksmith")
                if table.find(ignoredNPCs, areaName) then
                    local folder = ReplicatedStorage.TownMarkers[npcName]
                    if folder then
                        local part = folder:FindFirstChild(areaName)
                        if part then
                            return part.CFrame.Position
                        end
                    end
                else
                    -- Handle Workspace.NPCs with area (e.g., "Guard, TownSquare")
                    local npcInstances = {}
                    for _, npc in pairs(Workspace.NPCs:GetChildren()) do
                        if npc.Name == npcName then
                            local posSuccess, pos = pcall(function()
                                return npc.WorldPivot.Position
                            end)
                            if not posSuccess then
                                posSuccess, pos = pcall(function()
                                    return npc.CFrame.Position
                                end)
                            end
                            if posSuccess then
                                local areaPosSuccess, areaPos = pcall(function()
                                    return ReplicatedStorage.WorldModel.AreaMarkers[areaName].CFrame.Position
                                end)
                                if areaPosSuccess then
                                    local distance = (pos - areaPos).Magnitude
                                    table.insert(npcInstances, {instance = npc, position = pos, distance = distance})
                                end
                            end
                        end
                    end
                    -- Find closest NPC to specified area
                    local closestNPC = nil
                    local minDistance = math.huge
                    for _, instanceData in pairs(npcInstances) do
                        if instanceData.distance < minDistance then
                            minDistance = instanceData.distance
                            closestNPC = instanceData
                        end
                    end
                    if closestNPC then
                        return closestNPC.position
                    end
                end
            else
                -- Handle raw NPC names (e.g., "Guard", "Ancient Cavern Gate")
                local npc = Workspace.NPCs:FindFirstChild(entry)
                if npc then
                    local posSuccess, pos = pcall(function()
                        return npc.WorldPivot.Position
                    end)
                    if not posSuccess then
                        posSuccess, pos = pcall(function()
                            return npc.CFrame.Position
                        end)
                    end
                    if posSuccess then
                        return pos
                    end
                end
            end
        end
        return nil
    end)
    if success and result then
        position = result
        print("Position for " .. entry .. ": " .. tostring(position))
    else
        print("Failed to get position for " .. entry .. ": " .. tostring(result))
    end
    return position
end

local function smoothCamera()
    local success, result = pcall(function()
        local camera = Workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable
        local character = Players.LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 5, -10)
        end
    end)
    if not success then
        print("Failed to smooth camera: " .. tostring(result))
    end
end

local function customTween(targetPosition, tweenType)
    local success, result = pcall(function()
        local player = Players.LocalPlayer
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            print("Character or HumanoidRootPart not found")
            return
        end

        local hrp = character.HumanoidRootPart
        local speed = Options.UniversalTweenSpeed.Value
        if speed == 0 then speed = 150 end -- Avoid division by zero
        local duration = 300 / speed -- Map 0-300 to duration (e.g., 2s at 150)

        -- Enable mechanisms
        enableFly()
        enableNoclip()
        enableNofall()

        -- Tween up to 1000 studs
        local upPosition = hrp.CFrame.Position + Vector3.new(0, 1000, 0)
        local upTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local upTween = TweenService:Create(hrp, upTweenInfo, {CFrame = CFrame.new(upPosition)})
        currentTween = upTween
        upTween:Play()
        upTween.Completed:Wait()
        smoothCamera()
        if tweenType == "area" and not areaTweenActive or tweenType == "npc" and not npcTweenActive then
            disableFly()
            disableNoclip()
            disableNofall()
            return
        end

        -- Hold altitude and tween horizontally
        local horizontalPosition = Vector3.new(targetPosition.X, 1000, targetPosition.Z)
        local horizontalTweenInfo = TweenInfo.new(duration * 1.5, Enum.EasingStyle.Linear) -- Longer for horizontal
        local horizontalTween = TweenService:Create(hrp, horizontalTweenInfo, {CFrame = CFrame.new(horizontalPosition)})
        currentTween = horizontalTween
        horizontalTween:Play()
        horizontalTween.Completed:Wait()
        smoothCamera()
        if tweenType == "area" and not areaTweenActive or tweenType == "npc" and not npcTweenActive then
            disableFly()
            disableNoclip()
            disableNofall()
            return
        end

        -- Tween down to target
        local downTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local downTween = TweenService:Create(hrp, downTweenInfo, {CFrame = CFrame.new(targetPosition)})
        currentTween = downTween
        downTween:Play()
        downTween.Completed:Wait()
        smoothCamera()

        -- Disable mechanisms
        disableFly()
        disableNoclip()
        disableNofall()

        -- Reset tween state
        if tweenType == "area" then
            areaTweenActive = false
        elseif tweenType == "npc" then
            npcTweenActive = false
        end
        currentTween = nil
    end)
    if not success then
        print("Tween failed: " .. tostring(result))
        disableFly()
        disableNoclip()
        disableNofall()
        if tweenType == "area" then
            areaTweenActive = false
        elseif tweenType == "npc" then
            npcTweenActive = false
        end
        currentTween = nil
    end
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
        if npcTweenActive then
            Library:Notify("NPC tween in progress. Stop NPC tween and try again.", 5)
            return
        end
        if areaTweenActive then
            areaTweenActive = false
            if currentTween then
                currentTween:Cancel()
                disableFly()
                disableNoclip()
                disableNofall()
                currentTween = nil
            end
            print("Area tween stopped")
            return
        end
        local selectedArea = Options.Areas.Value
        if selectedArea and selectedArea ~= "" then
            local position = getPositionFromEntry(selectedArea)
            if position then
                areaTweenActive = true
                task.spawn(function()
                    customTween(position, "area")
                end)
                print("Area tween started to: " .. selectedArea)
            else
                Library:Notify("No valid position for area: " .. selectedArea, 5)
            end
        else
            Library:Notify("No area selected", 5)
        end
    end)
    if not success then
        print("Area Tween failed: " .. tostring(result))
        areaTweenActive = false
        disableFly()
        disableNoclip()
        disableNofall()
        currentTween = nil
    end
end)

MainGroup3:AddDropdown("NPCs", {
    Text = "NPCs",
    Default = "",
    Values = npcList,
    Multi = false
})
MainGroup3:AddButton("NPC Tween Start/Stop", function()
    local success, result = pcall(function()
        if areaTweenActive then
            Library:Notify("Area tween in progress. Stop Area tween and try again.", 5)
            return
        end
        if npcTweenActive then
            npcTweenActive = false
            if currentTween then
                currentTween:Cancel()
                disableFly()
                disableNoclip()
                disableNofall()
                currentTween = nil
            end
            print("NPC tween stopped")
            return
        end
        local selectedNPC = Options.NPCs.Value
        if selectedNPC and selectedNPC ~= "" then
            local position = getPositionFromEntry(selectedNPC)
            if position then
                npcTweenActive = true
                task.spawn(function()
                    customTween(position, "npc")
                end)
                print("NPC tween started to: " .. selectedNPC)
            else
                Library:Notify("No valid position for NPC: " .. selectedNPC, 5)
            end
        else
            Library:Notify("No NPC selected", 5)
        end
    end)
    if not success then
        print("NPC Tween failed: " .. tostring(result))
        npcTweenActive = false
        disableFly()
        disableNoclip()
        disableNofall()
        currentTween = nil
    end
end)

-- Cleanup on game exit
game:BindToClose(function()
    disableFly()
    disableNoclip()
    disableNofall()
    if currentTween then
        currentTween:Cancel()
    end
end)
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


--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES
--BEGIN MODULES




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
