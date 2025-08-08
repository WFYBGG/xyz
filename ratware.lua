--[[
    ⚙️ Unified GUI + Feature Script
    ✔️ Solara-safe
    ✔️ Manual GUI dragging
    ✔️ Keybind toggle
    ✔️ Speed & Fly Sliders
--]]

-- GLOBAL STATE
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local featureToggles = {
    Speed = false,
    Fly = false,
    Noclip = false,
    NoFall = false,
}

local speedValue = 50
local flySpeed = 50
local flyJumpPower = 70
local flyFallSpeed = 70
local guiVisible = true
local guiToggleKey = Enum.KeyCode.RightShift

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "Rogueblox SolaraV3 Compatible"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 8)

-- Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "ratware.exe"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.TextSize = 18
Title.Font = Enum.Font.GothamSemibold

-- Dragging logic
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Utility functions
local function createToggle(name, posY, toggleCallback)
    local button = Instance.new("TextButton", MainFrame)
    button.Size = UDim2.new(0.9, 0, 0, 30)
    button.Position = UDim2.new(0.05, 0, 0, posY)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Text = name .. ": OFF"

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 6)

    button.MouseButton1Click:Connect(function()
        featureToggles[name] = not featureToggles[name]
        button.Text = name .. ": " .. (featureToggles[name] and "ON" or "OFF")
        toggleCallback(featureToggles[name])
    end)
end

local function createSlider(name, posY, min, max, default, callback)
    local label = Instance.new("TextLabel", MainFrame)
    label.Size = UDim2.new(0.9, 0, 0, 20)
    label.Position = UDim2.new(0.05, 0, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name .. ": " .. default

    local sliderBack = Instance.new("Frame", MainFrame)
    sliderBack.Size = UDim2.new(0.9, 0, 0, 10)
    sliderBack.Position = UDim2.new(0.05, 0, 0, posY + 20)
    sliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(0, 4)

    local sliderFill = Instance.new("Frame", sliderBack)
    sliderFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn
            conn = RunService.RenderStepped:Connect(function()
                local rel = (UserInputService:GetMouseLocation().X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X
                rel = math.clamp(rel, 0, 1)
                sliderFill.Size = UDim2.new(rel, 0, 1, 0)
                local value = math.floor(min + (max - min) * rel)
                label.Text = name .. ": " .. value
                callback(value)
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)
end

-- GUI Keybind Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == guiToggleKey then
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end
end)

-- TOGGLES
createToggle("Speed", 40, function() end)
createToggle("Fly", 80, function() end)
createToggle("Noclip", 120, function() end)
createToggle("NoFall", 160, function() end)

-- SLIDERS
createSlider("Speed Value", 200, 0, 200, speedValue, function(v) speedValue = v end)
createSlider("Fly Speed", 240, 0, 200, flySpeed, function(v) flySpeed = v end)

--[[ ========== FEATURE BACKENDS ========== ]]

-- Paste your original backend logic here
pcall(function()
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    -- SPEED
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)

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

    player.CharacterAdded:Connect(function(character)
        repeat task.wait() until character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")
        if featureToggles.Speed then
            BodyVelocity.Parent = character.HumanoidRootPart
            character.Humanoid.JumpPower = 0
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local char = player.Character
            if featureToggles.Speed and char and char:FindFirstChild("HumanoidRootPart") then
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += workspace.CurrentCamera.CFrame.RightVector end
                dir = dir.Magnitude > 0 and dir.Unit or Vector3.zero

                BodyVelocity.Velocity = dir * math.min(speedValue, 49 / dt)
                BodyVelocity.Parent = char.HumanoidRootPart
                char.Humanoid.JumpPower = 0
            else
                resetSpeed()
            end
        end)
    end)

    -- FLY
    local Platform = Instance.new("Part")
    Platform.Size = Vector3.new(6, 1, 6)
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Transparency = 0.75
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

    player.CharacterAdded:Connect(function(char)
        repeat task.wait() until char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
        if featureToggles.Fly then
            FlyVelocity.Parent = char.HumanoidRootPart
            Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
            Platform.Parent = workspace
            char.Humanoid.JumpPower = 0
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local char = player.Character
            if featureToggles.Fly and char and char:FindFirstChild("HumanoidRootPart") then
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
                moveDir = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero

                local vert = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = flyJumpPower end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -flyFallSpeed end

                FlyVelocity.Velocity = moveDir * math.min(flySpeed, 49 / dt) + Vector3.new(0, vert, 0)
                FlyVelocity.Parent = char.HumanoidRootPart

                Platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.5, 0)
                Platform.Parent = workspace
            else
                resetFly()
            end
        end)
    end)

    -- NOCLIP
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

    RunService.RenderStepped:Connect(function()
        pcall(function()
            setCollision(not featureToggles.Noclip)
        end)
    end)

    -- NO FALL
    local Workspace = game:GetService("Workspace")
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
        repeat task.wait() until Workspace:FindFirstChild("Living")
        if featureToggles.NoFall then
            setNoFall(true)
        end
    end)

    RunService.RenderStepped:Connect(function()
        pcall(function()
            setNoFall(featureToggles.NoFall)
        end)
    end)
end)
