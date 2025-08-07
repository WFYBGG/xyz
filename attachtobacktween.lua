local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local isAttached = false
local targetPlayer = nil
local attachmentConnection = nil
local isTweening = false

-- Fly variables
local flyEnabled = false
local flyPlatform = nil
local bodyVelocity = nil
local originalSpeed = 150 -- Set to 150 studs per second for tweening
local flyActive = false

-- Noclip variables
local noclipEnabled = false
local noclipActive = false

-- Nofall variables
local nofallEnabled = false
local nofallFolder = nil
local nofallActive = false

-- Create GUI
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.Name = "AttachToBackGui"

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 250)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Frame.Parent = ScreenGui

    local PlayerList = Instance.new("ScrollingFrame")
    PlayerList.Size = UDim2.new(1, -10, 0.8, -10)
    PlayerList.Position = UDim2.new(0, 5, 0, 5)
    PlayerList.BackgroundTransparency = 1
    PlayerList.Parent = Frame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, -10, 0, 30)
    ToggleButton.Position = UDim2.new(0, 5, 0.85, 0)
    ToggleButton.Text = "Toggle Attach: OFF"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Parent = Frame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = PlayerList
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    return ScreenGui, PlayerList, ToggleButton
end

-- Update player list
local function updatePlayerList(PlayerList)
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local success, result = pcall(function()
                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, -10, 0, 30)
                Button.Text = player.Name
                Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Parent = PlayerList

                Button.MouseButton1Click:Connect(function()
                    targetPlayer = player
                    for _, btn in ipairs(PlayerList:GetChildren()) do
                        if btn:IsA("TextButton") then
                            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                        end
                    end
                    Button.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                end)
                return true
            end)
            if not success then
                warn("Failed to create button for " .. player.Name .. ": " .. tostring(result))
            end
        end
    end
end

-- Fly functions
local function enableFly()
    local success, result = pcall(function()
        if not flyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            flyEnabled = true
            flyActive = true

            -- Create platform
            flyPlatform = Instance.new("Part")
	flyPlatform.Name = "OldDebris"
	flyPlatform.Size = Vector3.new(6, 1, 6)
	flyPlatform.Anchored = true
	flyPlatform.CanCollide = true
	flyPlatform.Transparency = 1
	flyPlatform.Material = Enum.Material.SmoothPlastic
	flyPlatform.BrickColor = BrickColor.new("Bright blue")
	flyPlatform.Parent = workspace
	flyPlatform.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)

            -- Create BodyVelocity
            bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart

            -- Set humanoid properties
            LocalPlayer.Character.Humanoid.JumpPower = 0
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to enable fly: " .. tostring(result))
    end
    return success and result
end

local function disableFly()
    local success, result = pcall(function()
        if flyEnabled then
            flyEnabled = false
            flyActive = false
            if flyPlatform then
                flyPlatform:Destroy()
                flyPlatform = nil
            end
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = 50
                LocalPlayer.Character.Humanoid.WalkSpeed = 16
            end
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to disable fly: " .. tostring(result))
    end
    return success and result
end

-- Noclip functions
local function enableNoclip()
    local success, result = pcall(function()
        if not noclipEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            noclipEnabled = true
            noclipActive = true
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to enable noclip: " .. tostring(result))
    end
    return success and result
end

local function disableNoclip()
    local success, result = pcall(function()
        if noclipEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            noclipEnabled = false
            noclipActive = false
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to disable noclip: " .. tostring(result))
    end
    return success and result
end

-- Nofall functions
local function enableNofall()
    local success, result = pcall(function()
        if not nofallEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Status") then
            nofallEnabled = true
            nofallActive = true
            nofallFolder = Instance.new("Folder")
            nofallFolder.Name = "FallDamageCD"
            nofallFolder.Archivable = true
            nofallFolder.Parent = LocalPlayer.Character.Status
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to enable nofall: " .. tostring(result))
    end
    return success and result
end

local function disableNofall()
    local success, result = pcall(function()
        if nofallEnabled and nofallFolder and nofallFolder.Parent then
            nofallEnabled = false
            nofallActive = false
            nofallFolder:Destroy()
            nofallFolder = nil
            return true
        end
        return false
    end)
    if not success then
        warn("Failed to disable nofall: " .. tostring(result))
    end
    return success and result
end

-- Tween to player
local function tweenToPlayer()
    if isTweening then return false end
    isTweening = true

    local success, result = pcall(function()
        if targetPlayer and LocalPlayer.Character and targetPlayer.Character and
           LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local targetHrp = targetPlayer.Character.HumanoidRootPart
            local speed = 150 -- Studs per second

            -- Enable fly, noclip, and nofall
            enableFly()
            enableNoclip()
            enableNofall()

            -- Tween upwards to 1000 studs
            local upPosition = hrp.Position + Vector3.new(0, 1000 - hrp.Position.Y, 0)
            local upDistance = (upPosition - hrp.Position).Magnitude
            local upTweenInfo = TweenInfo.new(upDistance / speed, Enum.EasingStyle.Linear)
            local upTween = TweenService:Create(hrp, upTweenInfo, {CFrame = CFrame.new(upPosition)})
            upTween:Play()
            upTween.Completed:Wait()

            -- Tween horizontally to above target
            local aboveTarget = targetHrp.Position + Vector3.new(0, 1000 - targetHrp.Position.Y, 0)
            local horizontalDistance = (aboveTarget - hrp.Position).Magnitude
            local horizontalTweenInfo = TweenInfo.new(horizontalDistance / speed, Enum.EasingStyle.Linear)
            local horizontalTween = TweenService:Create(hrp, horizontalTweenInfo, {CFrame = CFrame.new(aboveTarget)})
            horizontalTween:Play()
            horizontalTween.Completed:Wait()

            -- Tween down to target's back (2 studs behind)
            local finalPosition = targetHrp.Position + (targetHrp.CFrame.LookVector * -2)
            local downDistance = (finalPosition - hrp.Position).Magnitude
            local downTweenInfo = TweenInfo.new(downDistance / speed, Enum.EasingStyle.Linear)
            local downTween = TweenService:Create(hrp, downTweenInfo, {CFrame = CFrame.new(finalPosition) * CFrame.Angles(0, targetHrp.CFrame.Rotation.Y, 0)})
            downTween:Play()
            downTween.Completed:Wait()

            -- Disable fly, noclip, and nofall
            disableFly()
            disableNoclip()
            disableNofall()

            isTweening = false
            return true
        end
        isTweening = false
        return false
    end)

    if not success then
        warn("Tween failed: " .. tostring(result))
        disableFly()
        disableNoclip()
        disableNofall()
        isTweening = false
    end
    return success and result
end

-- Attach to player's back
local function attachToPlayer()
    if attachmentConnection then
        attachmentConnection:Disconnect()
        attachmentConnection = nil
    end

    local success, result = pcall(function()
        if targetPlayer and LocalPlayer.Character and targetPlayer.Character and
           LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            attachmentConnection = RunService.RenderStepped:Connect(function()
                local success, _ = pcall(function()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                end)
                if not success or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if attachmentConnection then
                        attachmentConnection:Disconnect()
                        attachmentConnection = nil
                        isAttached = false
                    end
                end
            end)
            return true
        end
        return false
    end)
    return success and result
end

-- Main setup
local success, result = pcall(function()
    local ScreenGui, PlayerList, ToggleButton = createGUI()

    -- Update player list on player join/leave
    Players.PlayerAdded:Connect(function() updatePlayerList(PlayerList) end)
    Players.PlayerRemoving:Connect(function(player)
        if player == targetPlayer then
            targetPlayer = nil
            isAttached = false
            if attachmentConnection then
                attachmentConnection:Disconnect()
                attachmentConnection = nil
            end
        end
        updatePlayerList(PlayerList)
    end)

    -- Initial player list update
    updatePlayerList(PlayerList)

    -- Toggle button functionality
    ToggleButton.MouseButton1Click:Connect(function()
        local success, result = pcall(function()
            if targetPlayer then
                isAttached = not isAttached
                ToggleButton.Text = "Toggle Attach: " .. (isAttached and "ON" or "OFF")
                if isAttached then
                    tweenToPlayer()
                    if not isTweening then
                        attachToPlayer()
                    end
                elseif attachmentConnection then
                    attachmentConnection:Disconnect()
                    attachmentConnection = nil
                end
            else
                messagebox("Please select a player first!", "Error", 0)
            end
        end)
        if not success then
            warn("Toggle button error: " .. tostring(result))
        end
    end)

    -- Cleanup on game exit
    game:BindToClose(function()
        disableFly()
        disableNoclip()
        disableNofall()
        if attachmentConnection then
            attachmentConnection:Disconnect()
        end
    end)

    return true
end)

if not success then
    warn("Setup failed: " .. tostring(result))
end
