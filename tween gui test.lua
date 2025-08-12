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
            messagebox("NPC tween in progress. Stop NPC tween and try again.", "Tween Error", 0)
            return
        end
        if Options.Areas.Value == "" then
            messagebox("No area selected.", "Tween Error", 0)
            return
        end
        areaTweenActive = not areaTweenActive
        if areaTweenActive then
            local targetPos = getTargetPosition(Options.Areas.Value, false)
            if targetPos then
                _G.CustomTween(targetPos)
            else
                messagebox("Failed to get area position.", "Tween Error", 0)
                areaTweenActive = false
            end
        else
            _G.StopTween()
            areaTweenActive = false
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
            messagebox("Area tween in progress. Stop Area tween and try again.", "Tween Error", 0)
            return
        end
        if Options.NPCs.Value == "" then
            messagebox("No NPC selected.", "Tween Error", 0)
            return
        end
        npcTweenActive = not npcTweenActive
        if npcTweenActive then
            local targetPos = getTargetPosition(Options.NPCs.Value, true)
            if targetPos then
                _G.CustomTween(targetPos)
            else
                messagebox("Failed to get NPC position.", "Tween Error", 0)
                npcTweenActive = false
            end
        else
            _G.StopTween()
            npcTweenActive = false
        end
    end)
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer


-- MODULE START
-- MODULE START
-- MODULE START
-- MODULE START
pcall(function()
    repeat
        wait()
    until game:IsLoaded()
    repeat
        wait()
    until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- Combined script for noclip, nofall with TweenService-based tween system

    local players = game:GetService("Players")
    local tweenService = game:GetService("TweenService")
    local rs = game:GetService("RunService")

    -- Noclip variables
    local noclipEnabled = false
    local noclipActive = false

    local function resetNoClip()
        pcall(function()
            if players.LocalPlayer.Character then
                for _, part in pairs(players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end
        end)
    end

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        repeat
            wait()
        until character:FindFirstChild("HumanoidRootPart")
        if noclipEnabled then
            -- Handled in toggle
        end
    end)

    local function toggleNoclip(enable)
        pcall(function()
            noclipEnabled = enable
            local character = players.LocalPlayer.Character
            if not character then return end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = not enable end)
                end
            end
            if not enable then
                resetNoClip()
            end
        end)
    end

    -- Nofall variables
    local nofallEnabled = false
    local fallDamageCD = nil
    local function getStatusFolder()
        pcall(function()
            local character = players.LocalPlayer.Character
            if character then
                return workspace:WaitForChild("Living"):WaitForChild(players.LocalPlayer.Name):WaitForChild("Status")
            end
        end)
        return nil
    end

    local function toggleNofall(enable)
        pcall(function()
            local statusFolder = getStatusFolder()
            if not statusFolder then return end
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

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        if nofallEnabled then
            toggleNofall(true) -- Re-enable on respawn
        end
    end)

    -- Tween variables
    _G.Speed = 150 -- Default speed
    _G.tweenActive = false

    -- Custom Tween function using TweenService
    _G.CustomTween = function(target)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp or not target then
                _G.tweenActive = false
                toggleNoclip(false)
                toggleNofall(false)
                return
            end

            _G.tweenActive = true
            toggleNoclip(true)
            toggleNofall(true)

            local speed = _G.Speed
            local currentPos = hrp.Position
            local rotation = hrp.CFrame - currentPos  -- Preserve rotation

            -- Phase 1: Tween up to 1000 studs
            local upGoalPos = Vector3.new(currentPos.X, currentPos.Y + 1000, currentPos.Z)
            local upDistance = (upGoalPos - currentPos).Magnitude
            local upTime = upDistance / speed
            local upGoalCFrame = CFrame.new(upGoalPos) * rotation
            local upTweenInfo = TweenInfo.new(upTime, Enum.EasingStyle.Linear)
            local upTween = tweenService:Create(hrp, upTweenInfo, {CFrame = upGoalCFrame})
            upTween:Play()
            upTween.Completed:Wait()

            -- Check if still valid after wait
            character = players.LocalPlayer.Character
            hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                _G.tweenActive = false
                toggleNoclip(false)
                toggleNofall(false)
                return
            end

            -- Phase 2: Tween horizontally at altitude to above target
            currentPos = hrp.Position
            local horizGoalPos = Vector3.new(target.X, currentPos.Y, target.Z)
            local horizDistance = (horizGoalPos - currentPos).Magnitude
            local horizTime = horizDistance / speed
            local horizGoalCFrame = CFrame.new(horizGoalPos) * rotation
            local horizTweenInfo = TweenInfo.new(horizTime, Enum.EasingStyle.Linear)
            local horizTween = tweenService:Create(hrp, horizTweenInfo, {CFrame = horizGoalCFrame})
            horizTween:Play()
            horizTween.Completed:Wait()

            -- Check again
            character = players.LocalPlayer.Character
            hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                _G.tweenActive = false
                toggleNoclip(false)
                toggleNofall(false)
                return
            end

            -- Phase 3: Tween down to target
            currentPos = hrp.Position
            local downGoalPos = target
            local downDistance = (downGoalPos - currentPos).Magnitude
            local downTime = downDistance / speed
            local downGoalCFrame = CFrame.new(downGoalPos) * rotation
            local downTweenInfo = TweenInfo.new(downTime, Enum.EasingStyle.Linear)
            local downTween = tweenService:Create(hrp, downTweenInfo, {CFrame = downGoalCFrame})
            downTween:Play()
            downTween.Completed:Wait()

            _G.tweenActive = false
            toggleNoclip(false)
            toggleNofall(false)
        end)
    end

    _G.StopTween = function()
        pcall(function()
            _G.tweenActive = false
            toggleNoclip(false)
            toggleNofall(false)
            -- Optionally cancel active tweens, but since sequential, not necessary
        end)
    end

    -- Cleanup
    game:BindToClose(function()
        pcall(function()
            toggleNoclip(false)
            toggleNofall(false)
            if fallDamageCD then fallDamageCD:Destroy() end
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
