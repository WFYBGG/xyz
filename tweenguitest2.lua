--Couple of problems:
--1. Any speed over 65 and my character starts falling through the platform while rising. 
--2. Notification immediately disappears and doesn't persist.
--3. When tweening down to target, character gets stuck when it hits a solid part. 
--4. After tween stops, character cannot climb.

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

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Load tween module
local tweenSystem = require(game:GetService("ReplicatedStorage").TweenSystem) -- Adjust path as needed

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
    local success, result = pcall(function()
        if isNPC then
            local npcName, areaName = selection:match("^(.-), (.+)$")
            if npcName and areaName then
                -- Handle TownMarkers NPCs
                local townFolder = ReplicatedStorage.TownMarkers:FindFirstChild(npcName)
                if townFolder then
                    local part = townFolder:FindFirstChild(areaName)
                    if part then
                        return part.CFrame.Position
                    end
                else
                    -- Handle Workspace NPCs
                    local npcs = Workspace.NPCs:GetChildren()
                    for _, npc in pairs(npcs) do
                        if npc.Name == npcName then
                            local closestArea = nil
                            local minDistance = math.huge
                            local npcPos = npc.WorldPivot.Position or npc.CFrame.Position
                            for _, area in pairs(ReplicatedStorage.WorldModel.AreaMarkers:GetChildren()) do
                                local distance = getDistance(npcPos, area.CFrame.Position)
                                if distance < minDistance then
                                    minDistance = distance
                                    closestArea = area.Name
                                end
                            end
                            if closestArea == areaName then
                                return npcPos
                            end
                        end
                    end
                end
            else
                -- Single instance NPC
                local npcs = Workspace.NPCs:GetChildren()
                for _, npc in pairs(npcs) do
                    if npc.Name == selection then
                        return npc.WorldPivot.Position or npc.CFrame.Position
                    end
                end
            end
        else
            -- Area position
            local areaPart = ReplicatedStorage.WorldModel.AreaMarkers:FindFirstChild(selection)
            if areaPart then
                return areaPart.CFrame.Position
            end
        end
    end)
    if success and result then
        targetPos = result
        print("Position for " .. selection .. ": " .. tostring(targetPos))
    else
        print("Failed to get position for " .. selection .. ": " .. tostring(result))
    end
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
        local success, result = pcall(function()
            _G.Speed = value
        end)
        if not success then
            print("Failed to set speed: " .. tostring(result))
        end
    end
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
        if Options.Areas.Value == "" then
            Library:Notify("No area selected.", 5)
            return
        end
        areaTweenActive = not areaTweenActive
        if areaTweenActive then
            local targetPos = getTargetPosition(Options.Areas.Value, false)
            if targetPos then
                Library:Notify("Tweening to " .. Options.Areas.Value, 0) -- Persist until tween stops
                task.spawn(function()
                    tweenSystem.CustomTween(targetPos, _G.Speed or 125)
                    if areaTweenActive then
                        Library:Notify("Area Tween Stopped", 5)
                        areaTweenActive = false
                    end
                end)
            else
                Library:Notify("Failed to get area position.", 5)
                areaTweenActive = false
            end
        else
            tweenSystem.StopTween()
            Library:Notify("Area Tween Stopped", 5)
        end
    end)
    if not success then
        print("Area Tween failed: " .. tostring(result))
        areaTweenActive = false
        tweenSystem.StopTween()
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
        if Options.NPCs.Value == "" then
            Library:Notify("No NPC selected.", 5)
            return
        }
        npcTweenActive = not npcTweenActive
        if npcTweenActive then
            local targetPos = getTargetPosition(Options.NPCs.Value, true)
            if targetPos then
                Library:Notify("Tweening to " .. Options.NPCs.Value, 0) -- Persist until tween stops
                task.spawn(function()
                    tweenSystem.CustomTween(targetPos, _G.Speed or 125)
                    if npcTweenActive then
                        Library:Notify("NPC Tween Stopped", 5)
                        npcTweenActive = false
                    end
                end)
            else
                Library:Notify("Failed to get NPC position.", 5)
                npcTweenActive = false
            end
        else
            tweenSystem.StopTween()
            Library:Notify("NPC Tween Stopped", 5)
        end
    end)
    if not success then
        print("NPC Tween failed: " .. tostring(result))
        npcTweenActive = false
        tweenSystem.StopTween()
    end
end)

-- Monitor for tween stop to update flags
RunService.Heartbeat:Connect(function()
    local success, result = pcall(function()
        local state = tweenSystem.getTweenState()
        if not state.tweenActive then
            areaTweenActive = false
            npcTweenActive = false
        end
    end)
    if not success then
        print("Heartbeat failed: " .. tostring(result))
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

-- Cleanup on game exit
game:BindToClose(function()
    local success, result = pcall(function()
        tweenSystem.StopTween()
    end)
    if not success then
        print("Cleanup failed: " .. tostring(result))
    end
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Tween variables
local tweenState = {
    tweenActive = false,
    tweenPhase = 0,
    highAltitude = 0,
    tweenTarget = Vector3.new(0, 0, 0),
    flyEnabled = false,
    flyActive = false,
    noclipEnabled = false,
    noclipActive = false,
    nofallEnabled = false,
    nofallActive = false
}

-- Fly setup
local platform = Instance.new("Part")
platform.Name = "FlyPlatform"
platform.Size = Vector3.new(10, 1, 10) -- Increased size
platform.Anchored = true
platform.CanCollide = true
platform.Transparency = 0.75
platform.Material = Enum.Material.SmoothPlastic
platform.BrickColor = BrickColor.new("Bright blue")

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)

-- Nofall setup
local fallDamageCD = Instance.new("Folder")
fallDamageCD.Name = "FallDamageCD"

local function resetHumanoidState()
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character.Humanoid
            local hrp = character.HumanoidRootPart
            humanoid.JumpPower = 50
            humanoid.WalkSpeed = 16
            hrp.Anchored = false
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
    if not success then
        print("Failed to reset humanoid state: " .. tostring(result))
    end
end

local function toggleFly(enable, speed)
    local success, result = pcall(function()
        tweenState.flyEnabled = enable
        if enable then
            local character = Players.LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                character.Humanoid.JumpPower = 0
                platform.Parent = Workspace
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
                tweenState.flyActive = true
                print("Fly enabled")
            end
        else
            platform.Parent = nil
            bodyVelocity.Parent = nil
            tweenState.flyActive = false
            resetHumanoidState()
            print("Fly disabled")
        end
    end)
    if not success then
        print("Failed to toggle fly: " .. tostring(result))
        tweenState.flyEnabled = false
        tweenState.flyActive = false
    end
end

local function toggleNoclip(enable)
    local success, result = pcall(function()
        tweenState.noclipEnabled = enable
        if not enable then
            resetHumanoidState()
            tweenState.noclipActive = false
            print("Noclip disabled")
        end
    end)
    if not success then
        print("Failed to toggle noclip: " .. tostring(result))
        tweenState.noclipEnabled = false
        tweenState.noclipActive = false
    end
end

local function toggleNofall(enable)
    local success, result = pcall(function()
        tweenState.nofallEnabled = enable
        local character = Players.LocalPlayer.Character
        local statusFolder = character and character:FindFirstChild("Status")
        if enable and statusFolder then
            fallDamageCD.Parent = statusFolder
            tweenState.nofallActive = true
            print("Nofall enabled")
        else
            fallDamageCD.Parent = nil
            tweenState.nofallActive = false
            print("Nofall disabled")
        end
    end)
    if not success then
        print("Failed to toggle nofall: " .. tostring(result))
        tweenState.nofallEnabled = false
        tweenState.nofallActive = false
    end
end

-- Custom Tween function
local function customTween(target, speed)
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        toggleNoclip(true)
        toggleNofall(true)
        toggleFly(true, speed)

        tweenState.tweenTarget = target
        tweenState.highAltitude = hrp.Position.Y + 1000
        tweenState.tweenPhase = 1
        tweenState.tweenActive = true
    end)
    if not success then
        print("Failed to start tween: " .. tostring(result))
        tweenState.tweenActive = false
        toggleFly(false)
        toggleNoclip(false)
        toggleNofall(false)
    end
end

-- Stop Tween function
local function stopTween()
    local success, result = pcall(function()
        tweenState.tweenActive = false
        tweenState.tweenPhase = 0
        toggleFly(false)
        toggleNoclip(false)
        toggleNofall(false)
    end)
    if not success then
        print("Failed to stop tween: " .. tostring(result))
    end
end

-- Main RenderStepped loop
RunService.RenderStepped:Connect(function(delta)
    local success, result = pcall(function()
        local character = Players.LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if tweenState.flyEnabled and character and humanoid and hrp then
            tweenState.flyActive = true
            local moveDirection = Vector3.new(0, 0, 0)
            local up = false
            local down = false
            local verticalSpeed = math.min(_G.Speed or 125, 65) -- Cap vertical speed to prevent falling through

            if tweenState.tweenActive then
                local pos = hrp.Position
                if tweenState.tweenPhase == 1 then -- Ascend
                    up = true
                    down = false
                    if pos.Y >= tweenState.highAltitude - 1 then
                        tweenState.tweenPhase = 2
                    end
                elseif tweenState.tweenPhase == 2 then -- Horizontal
                    local highTarget = Vector3.new(tweenState.tweenTarget.X, tweenState.highAltitude, tweenState.tweenTarget.Z)
                    local horizontalVec = (highTarget - pos) * Vector3.new(1, 0, 1)
                    if horizontalVec.Magnitude > 5 then
                        moveDirection = horizontalVec.Unit
                    else
                        moveDirection = Vector3.new(0, 0, 0)
                        tweenState.tweenPhase = 3
                    end
                    up = false
                    down = false
                elseif tweenState.tweenPhase == 3 then -- Descend
                    moveDirection = Vector3.new(0, 0, 0)
                    up = false
                    down = true
                    if pos.Y <= tweenState.tweenTarget.Y + 10 then -- Stop 10 studs above target
                        tweenState.tweenActive = false
                        tweenState.tweenPhase = 0
                        toggleFly(false)
                        toggleNoclip(false)
                        toggleNofall(false)
                    end
                end
            end

            -- Apply BodyVelocity for horizontal movement
            bodyVelocity.Velocity = moveDirection * (_G.Speed or 125)

            -- Update platform position
            platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
            local flightMove = verticalSpeed * delta -- Use capped vertical speed
            if up then
                platform.CFrame = platform.CFrame + Vector3.new(0, flightMove, 0)
            elseif down then
                platform.CFrame = platform.CFrame - Vector3.new(0, flightMove, 0)
            end

            -- Monitor health
            if humanoid and humanoid.Health <= 0 then
                Library:Notify("Character Dead, Please Try Again", 5)
                stopTween()
                resetHumanoidState()
            end
        else
            if tweenState.flyActive then
                resetHumanoidState()
                tweenState.flyActive = false
                platform.Parent = nil
                bodyVelocity.Parent = nil
            end
        end

        -- Enhanced noclip for nearby parts
        if tweenState.noclipEnabled and character and hrp then
            tweenState.noclipActive = true
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            -- Disable collisions for nearby parts, including anchored ones
            local region = Workspace:FindPartsInRegion3(Region3.new(hrp.Position - Vector3.new(10, 10, 10), hrp.Position + Vector3.new(10, 10, 10)))
            for _, part in pairs(region) do
                if part:IsA("BasePart") and part ~= hrp and part ~= platform then
                    part.CanCollide = false
                end
            end
        else
            if tweenState.noclipActive then
                resetHumanoidState()
                tweenState.noclipActive = false
            end
        end
    end)
    if not success then
        print("RenderStepped failed: " .. tostring(result))
        stopTween()
    end
end)

-- Cleanup
game:BindToClose(function()
    local success, result = pcall(function()
        stopTween()
        platform:Destroy()
        bodyVelocity:Destroy()
        fallDamageCD:Destroy()
    end)
    if not success then
        print("Cleanup failed: " .. tostring(result))
    end
end)

return {
    CustomTween = customTween,
    StopTween = stopTween,
    getTweenState = function() return tweenState end
}
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
