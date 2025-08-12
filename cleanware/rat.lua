-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local guiParent = gethui and gethui() or CoreGui

-- Global variables for features
_G.SpeedhackEnabled = false
_G.SpeedhackKey = ""
_G.SpeedhackSpeed = 100

_G.FlightEnabled = false
_G.FlightKey = ""
_G.FlightSpeed = 200

_G.NoclipEnabled = false
_G.NoclipKey = ""

_G.NoFallDamageEnabled = false

_G.UniversalTweenSpeed = 150
_G.SelectedArea = ""
_G.SelectedNPC = ""
_G.AreaTweenActive = false
_G.NPCTweenActive = false

_G.AttachToBackEnabled = false
_G.AttachToBackKey = ""
_G.SelectedPlayer = nil

_G.PlayerESPEnabled = false

_G.MenuKey = "Insert"
_G.GUIVisible = true

-- Tween control variables
_G.tweenActive = false
_G.tweenPhase = 0
_G.highAltitude = 0
_G.tweenTarget = Vector3.new(0, 0, 0)

-- Lists for areas and NPCs
local areaList = {}
local npcList = {}
local TweenFullList = {}
local ignoredNPCs = {
    "Blacksmith", "Doctor", "Merchant", "Collector", "Inn", "Missions",
    "Jail", "Cargo", "Shipwright", "Bazaar", "Bounties", "Banker", "Bank", "Innkeeper", "The Collector"
}
local firstInstanceOnly = {
    "Ancient Cavern Gate", "Ancient Gate", "Celestial Platform", "Frosty", "Prince's Favour", "Prince's Scale"
}

-- Fetch areas and NPCs as in original
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

local function getDistance(pos1, pos2)
    local success, distance = pcall(function()
        local dx = pos1.X - pos2.X
        local dy = pos1.Y - pos2.Y
        local dz = pos1.Z - pos2.Z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end)
    return success and distance or math.huge
end

local successNPCs, npcs = pcall(function()
    return game:GetService("Workspace").NPCs:GetChildren()
end)
if successNPCs then
    local npcInstances = {}
    local seenFirstInstance = {}
    for _, npc in pairs(npcs) do
        local npcNameSuccess, npcName = pcall(function()
            return npc.Name
        end)
        if npcNameSuccess and npcName and not table.find(ignoredNPCs, npcName) then
            if not npcInstances[npcName] then
                npcInstances[npcName] = {}
            end
            local positionSuccess, pos = pcall(function()
                return npc.WorldPivot.Position or npc.CFrame.Position
            end)
            if positionSuccess then
                table.insert(npcInstances[npcName], {instance = npc, position = pos, name = npcName})
            end
        end
    end

    local seenAreaForNPC = {}
    for npcName, instances in pairs(npcInstances) do
        if table.find(firstInstanceOnly, npcName) then
            if #instances > 0 and not seenFirstInstance[npcName] then
                seenFirstInstance[npcName] = true
                table.insert(npcList, npcName)
                table.insert(TweenFullList, npcName)
            end
        elseif #instances == 1 then
            table.insert(npcList, npcName)
            table.insert(TweenFullList, npcName)
        else
            for _, instanceData in pairs(instances) do
                if instanceData.position then
                    local closestArea = nil
                    local minDistance = math.huge
                    for _, areaName in pairs(areaList) do
                        local areaPart = game:GetService("ReplicatedStorage").WorldModel.AreaMarkers[areaName]
                        if areaPart then
                            local areaPos = areaPart.CFrame.Position
                            local distance = getDistance(instanceData.position, areaPos)
                            if distance < minDistance then
                                minDistance = distance
                                closestArea = areaName
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

local successTowns, townFolders = pcall(function()
    return game:GetService("ReplicatedStorage").TownMarkers:GetChildren()
end)
if successTowns then
    local seenTownNPC = {}
    for _, folder in pairs(townFolders) do
        local folderName = folder.Name
        local parts = folder:GetChildren()
        for _, part in pairs(parts) do
            local partName = part.Name
            if table.find(ignoredNPCs, partName) then
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

table.sort(areaList, function(a, b) return string.lower(a) < string.lower(b) end)
table.sort(npcList, function(a, b) return string.lower(a) < string.lower(b) end)
table.sort(TweenFullList, function(a, b) return string.lower(a) < string.lower(b) end)

-- Helper function for target position
local function getTargetPosition(selection, isNPC)
    local targetPos = nil
    pcall(function()
        if isNPC then
            local npcName, areaName = selection:match("^(.-), (.+)$")
            if npcName and areaName then
                local townFolder = game:GetService("ReplicatedStorage").TownMarkers:FindFirstChild(npcName)
                if townFolder then
                    local part = townFolder:FindFirstChild(areaName)
                    if part then
                        targetPos = part.CFrame.Position
                    end
                else
                    local npcs = game:GetService("Workspace").NPCs:GetChildren()
                    for _, npc in pairs(npcs) do
                        if npc.Name == npcName then
                            local npcPos = npc.WorldPivot.Position or npc.CFrame.Position
                            local closestArea = nil
                            local minDistance = math.huge
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
                local npcs = game:GetService("Workspace").NPCs:GetChildren()
                for _, npc in pairs(npcs) do
                    if npc.Name == selection then
                        targetPos = npc.WorldPivot.Position or npc.CFrame.Position
                        break
                    end
                end
            end
        else
            local areaPart = game:GetService("ReplicatedStorage").WorldModel.AreaMarkers:FindFirstChild(selection)
            if areaPart then
                targetPos = areaPart.CFrame.Position
            end
        end
    end)
    return targetPos
end

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "RatwareGUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 600) -- Made taller for more content
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderColor3 = Color3.fromRGB(170, 0, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BorderColor3 = Color3.fromRGB(170, 0, 255)
header.BorderSizePixel = 1
header.Text = "Ratware.exe - 100% By ChatGPT [Press 'Insert' to hide GUI]"
header.Font = Enum.Font.SourceSansBold
header.TextSize = 18
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.TextXAlignment = Enum.TextXAlignment.Center
header.Parent = mainFrame

-- Function to create section label
local function createSectionLabel(text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    lbl.BorderColor3 = Color3.fromRGB(170, 0, 255)
    lbl.BorderSizePixel = 1
    lbl.Font = Enum.Font.SourceSansBold
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame
    return lbl
end

-- Function to create toggle button
local function createToggleButton(text, y, callback, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 25)
    btn.Position = UDim2.new(0.5, 0, 0, y)
    btn.BackgroundColor3 = initial and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    btn.BorderColor3 = Color3.fromRGB(170, 0, 255)
    btn.BorderSizePixel = 1
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSans
    btn.Text = text .. (initial and " ON" or " OFF")
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
    return btn
end

-- Function to create textbox
local function createTextBox(y, default, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 25)
    box.Position = UDim2.new(0.5, 0, 0, y)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.BorderColor3 = Color3.fromRGB(170, 0, 255)
    box.BorderSizePixel = 1
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 14
    box.Font = Enum.Font.SourceSans
    box.Text = tostring(default)
    box.Parent = mainFrame
    box.FocusLost:Connect(function(enter)
        if enter then
            callback(box.Text)
        end
    end)
    return box
end

-- Function to create label
local function createLabel(text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, -10, 0, 25)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame
    return lbl
end

-- Dropdown frames
local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(0, 300, 0, 200)
dropdownFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownFrame.BorderColor3 = Color3.fromRGB(170, 0, 255)
dropdownFrame.BorderSizePixel = 1
dropdownFrame.Visible = false
dropdownFrame.Parent = gui

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, -30)
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.Parent = dropdownFrame

local uilistlayout = Instance.new("UIListLayout")
uilistlayout.SortOrder = Enum.SortOrder.LayoutOrder
uilistlayout.Parent = scrollingFrame

local dropdownTitle = Instance.new("TextLabel")
dropdownTitle.Size = UDim2.new(1, 0, 0, 30)
dropdownTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropdownTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownTitle.Font = Enum.Font.SourceSansBold
dropdownTitle.TextSize = 16
dropdownTitle.Parent = dropdownFrame

local currentDropdownCallback = nil
local currentSearch = ""

local searchBox = createTextBox(40, "", function(value)
    currentSearch = string.lower(value)
    -- Will filter when opening
end)

local function openDropdown(title, list, callback)
    dropdownTitle.Text = title
    currentDropdownCallback = callback
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, item in pairs(list) do
        if string.lower(item):find(currentSearch) or currentSearch == "" then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = item
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Parent = scrollingFrame
            btn.MouseButton1Click:Connect(function()
                callback(item)
                dropdownFrame.Visible = false
            end)
        end
    end
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uilistlayout.AbsoluteContentSize.Y)
    dropdownFrame.Visible = true
end

-- Listening for keybind
local listeningForKey = nil
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if listeningForKey then
        local key = input.KeyCode.Name
        if listeningForKey == "SpeedhackKey" then
            _G.SpeedhackKey = key
            speedhackKeyBox.Text = key
        elseif listeningForKey == "FlightKey" then
            _G.FlightKey = key
            flightKeyBox.Text = key
        elseif listeningForKey == "NoclipKey" then
            _G.NoclipKey = key
            noclipKeyBox.Text = key
        elseif listeningForKey == "AttachToBackKey" then
            _G.AttachToBackKey = key
            attachKeyBox.Text = key
        elseif listeningForKey == "MenuKey" then
            _G.MenuKey = key
            menuKeyBox.Text = key
        end
        listeningForKey = nil
        return
    end
    local keyPressed = input.KeyCode.Name
    if keyPressed == _G.SpeedhackKey then
        _G.SpeedhackEnabled = not _G.SpeedhackEnabled
        speedhackToggle.Text = "Speedhack " .. (_G.SpeedhackEnabled and "ON" or "OFF")
        speedhackToggle.BackgroundColor3 = _G.SpeedhackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    if keyPressed == _G.FlightKey then
        _G.FlightEnabled = not _G.FlightEnabled
        flightToggle.Text = "Fly " .. (_G.FlightEnabled and "ON" or "OFF")
        flightToggle.BackgroundColor3 = _G.FlightEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    if keyPressed == _G.NoclipKey then
        _G.NoclipEnabled = not _G.NoclipEnabled
        noclipToggle.Text = "Noclip " .. (_G.NoclipEnabled and "ON" or "OFF")
        noclipToggle.BackgroundColor3 = _G.NoclipEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    if keyPressed == _G.AttachToBackKey then
        _G.AttachToBackEnabled = not _G.AttachToBackEnabled
        attachToggle.Text = "Attach To Back " .. (_G.AttachToBackEnabled and "ON" or "OFF")
        attachToggle.BackgroundColor3 = _G.AttachToBackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    if keyPressed == _G.MenuKey then
        _G.GUIVisible = not _G.GUIVisible
        gui.Enabled = _G.GUIVisible
    end
end)

-- Movement section
createSectionLabel("Movement", 40)

createLabel("Speedhack", 70)
local speedhackToggle = createToggleButton("Speedhack ", 70, function()
    _G.SpeedhackEnabled = not _G.SpeedhackEnabled
    speedhackToggle.Text = "Speedhack " .. (_G.SpeedhackEnabled and "ON" or "OFF")
    speedhackToggle.BackgroundColor3 = _G.SpeedhackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.SpeedhackEnabled)

createLabel("Speedhack Key:", 100)
local speedhackKeyBox = createTextBox(100, _G.SpeedhackKey, function() end)
local speedhackBindBtn = Instance.new("TextButton")
speedhackBindBtn.Size = UDim2.new(0, 100, 0, 25)
speedhackBindBtn.Position = UDim2.new(0, 10, 0, 130)
speedhackBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedhackBindBtn.Text = "Bind Key"
speedhackBindBtn.Parent = mainFrame
speedhackBindBtn.MouseButton1Click:Connect(function()
    listeningForKey = "SpeedhackKey"
    speedhackBindBtn.Text = "Press Key..."
end)

createLabel("Speedhack Speed:", 160)
local speedhackSpeedBox = createTextBox(160, _G.SpeedhackSpeed, function(value)
    _G.SpeedhackSpeed = tonumber(value) or 100
end)

createLabel("Fly", 190)
local flightToggle = createToggleButton("Fly ", 190, function()
    _G.FlightEnabled = not _G.FlightEnabled
    flightToggle.Text = "Fly " .. (_G.FlightEnabled and "ON" or "OFF")
    flightToggle.BackgroundColor3 = _G.FlightEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.FlightEnabled)

createLabel("Fly Key:", 220)
local flightKeyBox = createTextBox(220, _G.FlightKey, function() end)
local flightBindBtn = Instance.new("TextButton")
flightBindBtn.Size = UDim2.new(0, 100, 0, 25)
flightBindBtn.Position = UDim2.new(0, 10, 0, 250)
flightBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flightBindBtn.Text = "Bind Key"
flightBindBtn.Parent = mainFrame
flightBindBtn.MouseButton1Click:Connect(function()
    listeningForKey = "FlightKey"
    flightBindBtn.Text = "Press Key..."
end)

createLabel("Fly Speed:", 280)
local flightSpeedBox = createTextBox(280, _G.FlightSpeed, function(value)
    _G.FlightSpeed = tonumber(value) or 200
end)

createLabel("Noclip", 310)
local noclipToggle = createToggleButton("Noclip ", 310, function()
    _G.NoclipEnabled = not _G.NoclipEnabled
    noclipToggle.Text = "Noclip " .. (_G.NoclipEnabled and "ON" or "OFF")
    noclipToggle.BackgroundColor3 = _G.NoclipEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.NoclipEnabled)

createLabel("Noclip Key:", 340)
local noclipKeyBox = createTextBox(340, _G.NoclipKey, function() end)
local noclipBindBtn = Instance.new("TextButton")
noclipBindBtn.Size = UDim2.new(0, 100, 0, 25)
noclipBindBtn.Position = UDim2.new(0, 10, 0, 370)
noclipBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
noclipBindBtn.Text = "Bind Key"
noclipBindBtn.Parent = mainFrame
noclipBindBtn.MouseButton1Click:Connect(function()
    listeningForKey = "NoclipKey"
    noclipBindBtn.Text = "Press Key..."
end)

createLabel("No Fall Damage", 400)
local nofallToggle = createToggleButton("No Fall ", 400, function()
    _G.NoFallDamageEnabled = not _G.NoFallDamageEnabled
    nofallToggle.Text = "No Fall " .. (_G.NoFallDamageEnabled and "ON" or "OFF")
    nofallToggle.BackgroundColor3 = _G.NoFallDamageEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.NoFallDamageEnabled)

-- Universal Tween section
createSectionLabel("Universal Tween", 430)

createLabel("Search:", 460)
local tweenSearchBox = createTextBox(460, "", function(value)
    currentSearch = string.lower(value)
end)

createLabel("Tween Speed:", 490)
local tweenSpeedBox = createTextBox(490, _G.UniversalTweenSpeed, function(value)
    _G.UniversalTweenSpeed = tonumber(value) or 150
    _G.Speed = _G.UniversalTweenSpeed
end)

createLabel("Areas:", 520)
local areaSelectBtn = Instance.new("TextButton")
areaSelectBtn.Size = UDim2.new(0, 100, 0, 25)
areaSelectBtn.Position = UDim2.new(0.5, 0, 0, 520)
areaSelectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
areaSelectBtn.Text = "Select Area"
areaSelectBtn.Parent = mainFrame
areaSelectBtn.MouseButton1Click:Connect(function()
    openDropdown("Select Area", areaList, function(value)
        _G.SelectedArea = value
        areaSelectBtn.Text = value
    end)
end)

local areaTweenBtn = createToggleButton("Area Tween ", 550, function()
    _G.AreaTweenActive = not _G.AreaTweenActive
    if _G.AreaTweenActive then
        if _G.NPCTweenActive then return end
        local targetPos = getTargetPosition(_G.SelectedArea, false)
        if targetPos then
            _G.CustomTween(targetPos)
        else
            _G.AreaTweenActive = false
        end
    else
        _G.StopTween()
    end
    areaTweenBtn.Text = "Area Tween " .. (_G.AreaTweenActive and "ON" or "OFF")
    areaTweenBtn.BackgroundColor3 = _G.AreaTweenActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.AreaTweenActive)

createLabel("NPCs:", 580)
local npcSelectBtn = Instance.new("TextButton")
npcSelectBtn.Size = UDim2.new(0, 100, 0, 25)
npcSelectBtn.Position = UDim2.new(0.5, 0, 0, 580)
npcSelectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
npcSelectBtn.Text = "Select NPC"
npcSelectBtn.Parent = mainFrame
npcSelectBtn.MouseButton1Click:Connect(function()
    openDropdown("Select NPC", npcList, function(value)
        _G.SelectedNPC = value
        npcSelectBtn.Text = value
    end)
end)

local npcTweenBtn = createToggleButton("NPC Tween ", 610, function()
    _G.NPCTweenActive = not _G.NPCTweenActive
    if _G.NPCTweenActive then
        if _G.AreaTweenActive then return end
        local targetPos = getTargetPosition(_G.SelectedNPC, true)
        if targetPos then
            _G.CustomTween(targetPos)
        else
            _G.NPCTweenActive = false
        end
    else
        _G.StopTween()
    end
    npcTweenBtn.Text = "NPC Tween " .. (_G.NPCTweenActive and "ON" or "OFF")
    npcTweenBtn.BackgroundColor3 = _G.NPCTweenActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.NPCTweenActive)

-- Tween status
createSectionLabel("Tween Status", 640)
local tweenStatusLabel = Instance.new("TextLabel")
tweenStatusLabel.Size = UDim2.new(1, -20, 0, 25)
tweenStatusLabel.Position = UDim2.new(0, 10, 0, 665)
tweenStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tweenStatusLabel.BorderSizePixel = 0
tweenStatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
tweenStatusLabel.Font = Enum.Font.SourceSansBold
tweenStatusLabel.TextSize = 14
tweenStatusLabel.Text = "Status: Idle"
tweenStatusLabel.Parent = mainFrame

local tweenTargetLabel = Instance.new("TextLabel")
tweenTargetLabel.Size = UDim2.new(1, -20, 0, 20)
tweenTargetLabel.Position = UDim2.new(0, 10, 0, 695)
tweenTargetLabel.BackgroundTransparency = 1
tweenTargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tweenTargetLabel.Font = Enum.Font.SourceSans
tweenTargetLabel.TextSize = 14
tweenTargetLabel.Text = "Target: None"
tweenTargetLabel.Parent = mainFrame

-- Update tween status
RunService.Heartbeat:Connect(function()
    if _G.tweenActive then
        tweenStatusLabel.Text = "Status: Active"
        tweenStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        tweenStatusLabel.Text = "Status: Idle"
        tweenStatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        _G.AreaTweenActive = false
        _G.NPCTweenActive = false
        areaTweenBtn.Text = "Area Tween OFF"
        areaTweenBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        npcTweenBtn.Text = "NPC Tween OFF"
        npcTweenBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Rage section
createSectionLabel("Rage", 725)

createLabel("Select Player:", 750)
local playerSelectBtn = Instance.new("TextButton")
playerSelectBtn.Size = UDim2.new(0, 100, 0, 25)
playerSelectBtn.Position = UDim2.new(0.5, 0, 0, 750)
playerSelectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerSelectBtn.Text = "Select Player"
playerSelectBtn.Parent = mainFrame
playerSelectBtn.MouseButton1Click:Connect(function()
    local playerList = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerList, plr.Name)
        end
    end
    openDropdown("Select Player", playerList, function(value)
        _G.SelectedPlayer = Players:FindFirstChild(value)
        playerSelectBtn.Text = value
    end)
end)

createLabel("Attach To Back", 780)
local attachToggle = createToggleButton("Attach ", 780, function()
    _G.AttachToBackEnabled = not _G.AttachToBackEnabled
    attachToggle.Text = "Attach " .. (_G.AttachToBackEnabled and "ON" or "OFF")
    attachToggle.BackgroundColor3 = _G.AttachToBackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.AttachToBackEnabled)

createLabel("Attach Key:", 810)
local attachKeyBox = createTextBox(810, _G.AttachToBackKey, function() end)
local attachBindBtn = Instance.new("TextButton")
attachBindBtn.Size = UDim2.new(0, 100, 0, 25)
attachBindBtn.Position = UDim2.new(0, 10, 0, 840)
attachBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
attachBindBtn.Text = "Bind Key"
attachBindBtn.Parent = mainFrame
attachBindBtn.MouseButton1Click:Connect(function()
    listeningForKey = "AttachToBackKey"
    attachBindBtn.Text = "Press Key..."
end)

-- Visuals section
createSectionLabel("Visuals", 870)

createLabel("Player ESP", 895)
local espToggle = createToggleButton("ESP ", 895, function()
    _G.PlayerESPEnabled = not _G.PlayerESPEnabled
    espToggle.Text = "ESP " .. (_G.PlayerESPEnabled and "ON" or "OFF")
    espToggle.BackgroundColor3 = _G.PlayerESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end, _G.PlayerESPEnabled)

-- UI Settings section
createSectionLabel("UI Settings", 925)

local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, -20, 0, 30)
unloadBtn.Position = UDim2.new(0, 10, 0, 950)
unloadBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
unloadBtn.BorderColor3 = Color3.fromRGB(170, 0, 255)
unloadBtn.BorderSizePixel = 1
unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadBtn.TextSize = 14
unloadBtn.Font = Enum.Font.SourceSans
unloadBtn.Text = "Unload"
unloadBtn.Parent = mainFrame
unloadBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

createLabel("Menu Key:", 985)
local menuKeyBox = createTextBox(985, _G.MenuKey, function() end)
local menuBindBtn = Instance.new("TextButton")
menuBindBtn.Size = UDim2.new(0, 100, 0, 25)
menuBindBtn.Position = UDim2.new(0, 10, 0, 1015)
menuBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
menuBindBtn.Text = "Bind Key"
menuBindBtn.Parent = mainFrame
menuBindBtn.MouseButton1Click:Connect(function()
    listeningForKey = "MenuKey"
    menuBindBtn.Text = "Press Key..."
end)

-- Modules modified to use _G

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

    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if _G.SpeedhackEnabled then
                local char = player.Character
                BodyVelocity.Parent = char.HumanoidRootPart
                char.Humanoid.JumpPower = 0
            end
        end
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            local timeout = tick() + 5
            while not (character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) and tick() < timeout do
                task.wait()
            end
            if _G.SpeedhackEnabled then
                BodyVelocity.Parent = character.HumanoidRootPart
                character.Humanoid.JumpPower = 0
            end
        end)
    end)

    local renderConnection = RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local char = player.Character
            if _G.SpeedhackEnabled and char and char:FindFirstChild("HumanoidRootPart") then
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += workspace.CurrentCamera.CFrame.RightVector end
                dir = dir.Magnitude > 0 and dir.Unit or Vector3.zero

                BodyVelocity.Velocity = dir * math.min(_G.SpeedhackSpeed, 49 / dt)
                BodyVelocity.Parent = char.HumanoidRootPart
                char.Humanoid.JumpPower = 0
            else
                resetSpeed()
            end
        end)
    end)

    if _G.FlightEnabled then
        if not _G.SpeedhackEnabled and _G.FlightEnabled then
            _G.FlightEnabled = false
            task.wait(0.1)
            _G.FlightEnabled = true
        end
    end
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
            if _G.FlightEnabled then
                FlyVelocity.Parent = char.HumanoidRootPart
                Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                Platform.Parent = workspace
                char.Humanoid.JumpPower = 0
            end
        end)
    end)

    local renderConnection = RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local char = player.Character
            if _G.FlightEnabled and char and char:FindFirstChild("HumanoidRootPart") then
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
                moveDir = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero

                local vert = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = 70 end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -70 end

                FlyVelocity.Velocity = moveDir * math.min(_G.FlightSpeed, 49 / dt) + Vector3.new(0, vert, 0)
                FlyVelocity.Parent = char.HumanoidRootPart

                Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                Platform.Parent = workspace
            else
                resetFly()
            end
        end)
    end)

    if _G.SpeedhackEnabled then
        if not _G.FlightEnabled and _G.SpeedhackEnabled then
            _G.SpeedhackEnabled = false
            task.wait(0.1)
            _G.SpeedhackEnabled = true
        end
    end
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

    pcall(function()
        if player.Character and _G.NoclipEnabled then
            setCollision(false)
        end
    end)

    player.CharacterAdded:Connect(function(character)
        pcall(function()
            local timeout = tick() + 5
            while not character:FindFirstChild("HumanoidRootPart") and tick() < timeout do
                task.wait()
            end
            if _G.NoclipEnabled then
                setCollision(false)
            end
        end)
    end)

    local renderConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            setCollision(not _G.NoclipEnabled)
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
            if _G.NoFallDamageEnabled then
                setNoFall(true)
            end
        end)
    end)

    local renderConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            setNoFall(_G.NoFallDamageEnabled)
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
                    line.Visible = _G.PlayerESPEnabled
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
            for player, tbl in pairs(ESPObjects) do
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

                        if _G.PlayerESPEnabled and onScreen and onScreen1 and onScreen2 and health > 0 then
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
                            local r = math.floor(255 - 255 * (health/maxHealth))
                            local g = math.floor(255 * (health/maxHealth))
                            healthText.Color = Color3.fromRGB(r, g, 0)
                            healthText.Visible = true

                            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                            distText.Text = "[" .. math.floor(dist) .. "m]"
                            distText.Position = Vector2.new(pos.X, botW.Y + 2)
                            distText.Visible = true

                            drawSkeleton(player, char, Color3.fromRGB(255,255,255), 2)
                        else
                            box.Visible = false
                            nameText.Visible = false
                            healthText.Visible = false
                            distText.Visible = false
                            chamBox.Visible = false
                            if tbl.Skeleton then
                                for _, line in pairs(tbl.Skeleton) do
                                    line.Visible = false
                                end
                            end
                        end
                    else
                        box.Visible = false
                        nameText.Visible = false
                        healthText.Visible = false
                        distText.Visible = false
                        chamBox.Visible = false
                        if tbl.Skeleton then
                            for _, line in pairs(tbl.Skeleton) do
                                line.Visible = false
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
        wait()
    until game:IsLoaded()
    repeat
        wait()
    until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local flyEnabled = false
    local flyActive = false
    local players = game:GetService("Players")
    local rs = game:GetService("RunService")

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
    bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)

    players.LocalPlayer.CharacterAdded:Connect(function(character)
        repeat
            wait()
        until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
        pcall(function()
            if flyEnabled then
                character.Humanoid.JumpPower = 0
                platform.Parent = workspace
                platform.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
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
            -- Handled in RenderStepped
        end
    end)

    local function toggleNoclip(enable)
        pcall(function()
            noclipEnabled = enable
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

    rs.RenderStepped:Connect(function(delta)
        pcall(function()
            local character = players.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")

            if flyEnabled and character and humanoid and hrp then
                flyActive = true
                local moveDirection = Vector3.new(0, 0, 0)
                local up = false
                local down = false

                if _G.tweenActive then
                    local pos = hrp.Position
                    if _G.tweenPhase == 1 then
                        moveDirection = Vector3.new(0, 0, 0)
                        up = true
                        down = false
                        if pos.Y >= _G.highAltitude - 1 then
                            _G.tweenPhase = 2
                        end
                    elseif _G.tweenPhase == 2 then
                        local highTarget = Vector3.new(_G.tweenTarget.X, _G.highAltitude, _G.tweenTarget.Z)
                        local horizontalVec = (highTarget - pos) * Vector3.new(1, 0, 1)
                        if horizontalVec.Magnitude > 5 then
                            moveDirection = horizontalVec.Unit
                        else
                            moveDirection = Vector3.new(0, 0, 0)
                            _G.tweenPhase = 3
                        end
                        up = false
                        down = false
                    elseif _G.tweenPhase == 3 then
                        moveDirection = Vector3.new(0, 0, 0)
                        up = false
                        down = true
                        if pos.Y <= _G.tweenTarget.Y + 5 then
                            _G.tweenActive = false
                            _G.tweenPhase = 0
                            toggleFly(false)
                            toggleNoclip(false)
                            toggleNofall(false)
                        end
                    end
                end

                local maxSpeedPerFrame = math.min(_G.Speed, 49 / delta)
                if moveDirection.Magnitude > 0 then
                    bodyVelocity.Velocity = moveDirection * maxSpeedPerFrame
                else
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end

                humanoid.JumpPower = 0

                platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
                local flightMove = math.min(_G.Speed * delta, 49 * delta)
                if up then
                    platform.CFrame = platform.CFrame + Vector3.new(0, flightMove, 0)
                elseif down then
                    platform.CFrame = platform.CFrame - Vector3.new(0, flightMove, 0)
                end

                if humanoid.Health <= 0 then
                    messagebox("Character Dead, Please Try Again", "Error", 0)
                    resetHumanoidState()
                    _G.tweenActive = false
                    _G.tweenPhase = 0
                    flyEnabled = false
                    flyActive = false
                    platform.Parent = nil
                    bodyVelocity.Parent = nil
                    toggleNoclip(false)
                    toggleNofall(false)
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
                local region = workspace:FindPartsInRegion3(Region3.new(hrp.Position - Vector3.new(5, 5, 5), hrp.Position + Vector3.new(5, 5, 5)))
                for _, part in pairs(region) do
                    if part:IsA("BasePart") and part ~= hrp and not part.Anchored then
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

            toggleNoclip(true)
            toggleNofall(true)
            toggleFly(true)

            _G.tweenTarget = target
            _G.highAltitude = hrp.Position.Y + 1000
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
            toggleNofall(false)
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

-- Attach to back Module
pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local targetPlayer = nil
    local isAttached = false
    local attachConn = nil
    local isTweening = false
    local isLocked = false
    local noclipEnabled = false
    local nofallEnabled = false
    local nofallFolder = nil

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

    local function enableNofall()
        if nofallEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
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
    end

    local function disableNofall()
        if not nofallEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local status = safeGet(char, "Status")
        if status then
            local fd = status:FindFirstChild("FallDamageCD")
            if fd then fd:Destroy() end
        end
        nofallEnabled = false
        nofallFolder = nil
    end

    local function enableNoclip()
        if noclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        noclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end

    local function disableNoclip()
        if not noclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        noclipEnabled = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end

    local originalSpeed = 150
    local function tweenToBack()
        if isTweening or isLocked then return end
        isTweening = true
        local char = LocalPlayer.Character
        local targetChar = targetPlayer and targetPlayer.Character
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
        enableNoclip()
        enableNofall()
        local backGoal = targetHrp.CFrame * CFrame.new(0, 0, 2)
        local tweenTime = distance / originalSpeed
        local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
        tween:Play()
        tween.Completed:Wait()
        isLocked = true
        isTweening = false
    end

    local function stopAttach()
        isAttached = false
        isLocked = false
        isTweening = false
        if attachConn then
            attachConn:Disconnect()
            attachConn = nil
        end
        disableNofall()
        disableNoclip()
    end

    local function startAttach()
        stopAttach()
        targetPlayer = _G.SelectedPlayer
        if not targetPlayer then return end
        isAttached = true
        enableNofall()
        tweenToBack()
        attachConn = RunService.RenderStepped:Connect(function()
            if not isAttached then return end
            local char = LocalPlayer.Character
            local targetChar = targetPlayer and targetPlayer.Character
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
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
            elseif not isTweening then
                tweenToBack()
            end
        end)
    end

    RunService.Heartbeat:Connect(function()
        if _G.AttachToBackEnabled then
            if not isAttached then
                startAttach()
            end
        else
            if isAttached then
                stopAttach()
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(char)
        if _G.AttachToBackEnabled then
            enableNofall()
            if not isLocked then
                enableNoclip()
            end
        end
    end)

    game:BindToClose(function()
        stopAttach()
    end)
end)
