local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Internal state
local targetPlayer = nil
local isAttached = false
local attachConn = nil
local isTweening = false
local isLocked = false -- Tracks if position is locked after reaching target
local noclipEnabled = false
local nofallEnabled = false
local nofallFolder = nil

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

-- Nofall logic
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

-- Noclip logic
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

-- Tween logic: Moves to target if within 100 studs, then locks for attachment
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
    isLocked = true -- Lock position for continuous attachment
    isTweening = false
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AttachToBackDropdownGUI"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
frame.BorderSizePixel = 0
frame.Parent = gui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 24)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.Text = "Select Player:"
label.TextColor3 = Color3.fromRGB(230, 230, 255)
label.Font = Enum.Font.SourceSansSemibold
label.TextSize = 18
label.Parent = frame
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, -20, 0, 28)
dropdownBtn.Position = UDim2.new(0, 10, 0, 38)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Text = "Select..."
dropdownBtn.Font = Enum.Font.SourceSans
dropdownBtn.TextSize = 16
dropdownBtn.Parent = frame
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 28)
toggle.Position = UDim2.new(0, 10, 0, 74)
toggle.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Text = "Attach: OFF"
toggle.Font = Enum.Font.SourceSansSemibold
toggle.TextSize = 18
toggle.Parent = frame
local dropdownList = Instance.new("Frame")
dropdownList.Size = UDim2.new(1, 0, 0, 0)
dropdownList.Position = UDim2.new(0, 10, 0, 66)
dropdownList.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.Parent = frame
dropdownList.ZIndex = 10
dropdownBtn.ZIndex = 11
local uilist = Instance.new("UIListLayout")
uilist.Parent = dropdownList
uilist.SortOrder = Enum.SortOrder.LayoutOrder

-- Dropdown update
local function refreshDropdown()
    for _, child in ipairs(dropdownList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    local visibleCount = math.min(#players, 8)
    dropdownList.Size = UDim2.new(1, 0, 0, visibleCount * 24)
    for _, player in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = player.Name
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.BorderSizePixel = 0
        btn.Parent = dropdownList
        btn.ZIndex = 11
        btn.MouseButton1Click:Connect(function()
            dropdownBtn.Text = player.Name
            dropdownList.Visible = false
            targetPlayer = player
        end)
    end
end

-- Show/hide dropdown
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownList.Visible = not dropdownList.Visible
    refreshDropdown()
end)

-- Attach/Detach logic
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
    toggle.Text = "Attach: OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
end

local function startAttach()
    stopAttach()
    if not targetPlayer then return end
    isAttached = true
    enableNofall()
    toggle.Text = "Attach: ON"
    toggle.BackgroundColor3 = Color3.fromRGB(36, 185, 91)
    tweenToBack() -- Trigger initial tween to target
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
            isLocked = false -- Allow re-tweening if target moves back into range
            isTweening = false
            return
        end
        if isLocked then
            -- Continuously attach to target's back
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
        elseif not isTweening then
            tweenToBack() -- Retry tween if within range and not tweening
        end
    end)
end

toggle.MouseButton1Click:Connect(function()
    if not targetPlayer then
        toggle.Text = "Select a player first!"
        task.wait(1)
        toggle.Text = "Attach: OFF"
        return
    end
    if isAttached then
        stopAttach()
    else
        startAttach()
    end
end)

-- Refresh on join/leave
Players.PlayerAdded:Connect(refreshDropdown)
Players.PlayerRemoving:Connect(function(player)
    if player == targetPlayer then
        targetPlayer = nil
        stopAttach()
        dropdownBtn.Text = "Select..."
    end
    refreshDropdown()
end)

-- Re-apply nofall/noclip on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if isAttached then
        enableNofall()
        if not isLocked then
            enableNoclip()
        end
    end
end)

game:BindToClose(function()
    stopAttach()
    if gui then gui:Destroy() end
end)

refreshDropdown()
stopAttach()
