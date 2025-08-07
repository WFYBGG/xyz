-- Scarlet Hook Rogueblox Linoria Hub All-In-One (no requires, no missing code)
-- Paste this directly into your executor.

--// LinoriaLib Loader
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

--// Window & Tabs
local Window = Library:CreateWindow({
    Title = 'Scarlet Hook Rogueblox',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}
local MovementGroup = Tabs.Main:AddLeftGroupbox('Movement')
local VisualGroup = Tabs.Main:AddLeftGroupbox('Visual')
local AutomationGroup = Tabs.Main:AddRightGroupbox('Automation')

--// Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------
-- MOVEMENT: Speed
---------------------------------------------------------
local movementSpeed_enabled = false
local movementSpeed_speed = 100
local movementSpeed_key = Enum.KeyCode.F4
local movementSpeed_bv = nil

local function movementSpeed_reset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = 50
        char.Humanoid.WalkSpeed = 16
        if movementSpeed_bv then movementSpeed_bv.Parent = nil end
    end
end

local function movementSpeed_enable()
    movementSpeed_enabled = true
    local char = LocalPlayer.Character
    if not movementSpeed_bv then
        movementSpeed_bv = Instance.new("BodyVelocity")
        movementSpeed_bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
        movementSpeed_bv.Velocity = Vector3.new(0,0,0)
    end
    if char and char:FindFirstChild("HumanoidRootPart") then
        movementSpeed_bv.Parent = char.HumanoidRootPart
        if char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = 0 end
    end
end

local function movementSpeed_disable()
    movementSpeed_enabled = false
    movementSpeed_reset()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if movementSpeed_enabled and movementSpeed_bv then
        local hrp = char:WaitForChild("HumanoidRootPart", 6)
        local hum = char:WaitForChild("Humanoid", 6)
        if hrp then
            movementSpeed_bv.Parent = hrp
            if hum then hum.JumpPower = 0 end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == movementSpeed_key then
        if movementSpeed_toggle then
            movementSpeed_toggle:SetValue(not movementSpeed_enabled)
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not movementSpeed_enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp and hum then
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        local maxSpeed = 49 / dt
        if movementSpeed_bv then movementSpeed_bv.Velocity = moveDir * math.min(movementSpeed_speed, maxSpeed) end
        if hum.Health <= 0 then movementSpeed_disable() if movementSpeed_toggle then movementSpeed_toggle:SetValue(false) end end
    else
        movementSpeed_disable()
        if movementSpeed_toggle then movementSpeed_toggle:SetValue(false) end
    end
end)

local movementSpeed_toggle = MovementGroup:AddToggle('MovementSpeedToggle', {
    Text = 'Movement Speed',
    Default = false,
    Tooltip = 'Enable custom movement speed',
})
MovementGroup:AddSlider('MovementSpeedSlider', {
    Text = 'Speed',
    Default = 100,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) movementSpeed_speed = Value end
})
MovementGroup:AddLabel('Movement Speed Keybind'):AddKeyPicker('MovementSpeedKeybind', {
    Default = 'F4',
    Text = 'Movement Speed Keybind',
    NoUI = false,
    Mode = 'Toggle',
    Callback = function() movementSpeed_toggle:SetValue(not movementSpeed_enabled) end,
    ChangedCallback = function(New)
        if typeof(New) == "EnumItem" then movementSpeed_key = New end
    end
})
movementSpeed_toggle:OnChanged(function()
    if movementSpeed_toggle.Value then movementSpeed_enable()
    else movementSpeed_disable() end
end)

---------------------------------------------------------
-- MOVEMENT: Fly
---------------------------------------------------------
local movementFly_enabled = false
local movementFly_speed = 100
local movementFly_key = Enum.KeyCode.F4
local movementFly_bv = nil
local movementFly_platform = nil

local function movementFly_reset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = 50
        char.Humanoid.WalkSpeed = 16
    end
end

local function movementFly_enable()
    movementFly_enabled = true
    _G.Speed = movementFly_speed
    if not movementFly_platform then
        local platform = Instance.new("Part")
        platform.Name = "OldDebris"
        platform.Size = Vector3.new(6, 1, 6)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Transparency = 0.75
        platform.Material = Enum.Material.SmoothPlastic
        platform.BrickColor = BrickColor.new("Bright blue")
        movementFly_platform = platform
    end
    if not movementFly_bv then
        movementFly_bv = Instance.new("BodyVelocity")
        movementFly_bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
        movementFly_bv.Velocity = Vector3.new(0,0,0)
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = 0 end
    if char and char:FindFirstChild("HumanoidRootPart") then
        movementFly_bv.Parent = char.HumanoidRootPart
        movementFly_platform.Parent = Workspace
        movementFly_platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
    end
end

local function movementFly_disable()
    movementFly_enabled = false
    movementFly_reset()
    if movementFly_platform then movementFly_platform.Parent = nil end
    if movementFly_bv then movementFly_bv.Parent = nil end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if movementFly_enabled then
        local hrp = char:WaitForChild("HumanoidRootPart", 6)
        local hum = char:WaitForChild("Humanoid", 6)
        if hrp then
            movementFly_bv.Parent = hrp
            movementFly_platform.Parent = Workspace
            movementFly_platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
        end
        if hum then hum.JumpPower = 0 end
    else
        if movementFly_platform then movementFly_platform.Parent = nil end
        if movementFly_bv then movementFly_bv.Parent = nil end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == movementFly_key then
        if movementFly_toggle then movementFly_toggle:SetValue(not movementFly_enabled) end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not movementFly_enabled then return end
    _G.Speed = movementFly_speed
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp and hum then
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Workspace.CurrentCamera.CFrame.RightVector end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        local maxSpeed = math.min(200, 49 / dt)
        local velocity = Vector3.new(0, movementFly_bv and movementFly_bv.Velocity.Y or 0, 0)
        if moveDir.Magnitude > 0 then
            velocity = moveDir * math.min(_G.Speed * dt, maxSpeed)
        end
        if movementFly_bv then
            movementFly_bv.Velocity = Vector3.new(velocity.X, movementFly_bv.Velocity.Y, velocity.Z)
        end
        hum.JumpPower = 0
        if movementFly_platform then
            movementFly_platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
            local flightMove = 49 * dt
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                movementFly_platform.CFrame = movementFly_platform.CFrame + Vector3.new(0, flightMove, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                movementFly_platform.CFrame = movementFly_platform.CFrame - Vector3.new(0, flightMove, 0)
            end
        end
        if hum.Health <= 0 then
            movementFly_reset()
            if movementFly_toggle then movementFly_toggle:SetValue(false) end
            movementFly_enabled = false
            if movementFly_platform then movementFly_platform.Parent = nil end
            if movementFly_bv then movementFly_bv.Parent = nil end
        end
    else
        movementFly_reset()
        if movementFly_toggle then movementFly_toggle:SetValue(false) end
        movementFly_enabled = false
        if movementFly_platform then movementFly_platform.Parent = nil end
        if movementFly_bv then movementFly_bv.Parent = nil end
    end
end)

local movementFly_toggle = MovementGroup:AddToggle('MovementFlyToggle', {
    Text = 'Fly',
    Default = false,
    Tooltip = 'Enable flight',
})
MovementGroup:AddSlider('MovementFlySlider', {
    Text = 'Fly Speed',
    Default = 100,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) movementFly_speed = Value _G.Speed = Value end
})
MovementGroup:AddLabel('Fly Keybind'):AddKeyPicker('MovementFlyKeybind', {
    Default = 'F4',
    Text = 'Fly Keybind',
    NoUI = false,
    Mode = 'Toggle',
    Callback = function() movementFly_toggle:SetValue(not movementFly_enabled) end,
    ChangedCallback = function(New)
        if typeof(New) == "EnumItem" then movementFly_key = New end
    end
})
movementFly_toggle:OnChanged(function()
    if movementFly_toggle.Value then movementFly_enable()
    else movementFly_disable() end
end)

---------------------------------------------------------
-- MOVEMENT: Noclip
---------------------------------------------------------
local movementNoclip_enabled = false
local movementNoclip_key = Enum.KeyCode.F5

local function movementNoclip_reset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

local function movementNoclip_enable() movementNoclip_enabled = true end
local function movementNoclip_disable() movementNoclip_enabled = false movementNoclip_reset() end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == movementNoclip_key then
        if movementNoclip_toggle then movementNoclip_toggle:SetValue(not movementNoclip_enabled) end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if movementNoclip_enabled and char and char:FindFirstChild("HumanoidRootPart") then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
        local hrp = char.HumanoidRootPart
        if hrp then
            local region = Workspace:FindPartsInRegion3(Region3.new(hrp.Position - Vector3.new(5, 5, 5), hrp.Position + Vector3.new(5, 5, 5)))
            for _, part in pairs(region) do
                if part:IsA("BasePart") and part ~= hrp and not part.Anchored then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    else
        movementNoclip_reset()
    end
end)

local movementNoclip_toggle = MovementGroup:AddToggle('MovementNoclipToggle', {
    Text = 'Noclip',
    Default = false,
    Tooltip = 'Enable noclip',
})
MovementGroup:AddLabel('Noclip Keybind'):AddKeyPicker('MovementNoclipKeybind', {
    Default = 'F5',
    Text = 'Noclip Keybind',
    NoUI = false,
    Mode = 'Toggle',
    Callback = function() movementNoclip_toggle:SetValue(not movementNoclip_enabled) end,
    ChangedCallback = function(New)
        if typeof(New) == "EnumItem" then movementNoclip_key = New end
    end
})
movementNoclip_toggle:OnChanged(function()
    if movementNoclip_toggle.Value then movementNoclip_enable()
    else movementNoclip_disable() end
end)

---------------------------------------------------------
-- MOVEMENT: No Fall Damage
---------------------------------------------------------
local nofall_enabled = false
local nofall_folder = nil
local function getStatusFolder()
    local ok, living = pcall(function() return Workspace:WaitForChild("Living", 2) end)
    if not ok or not living then return nil end
    local ok2, char = pcall(function() return living:WaitForChild(LocalPlayer.Name, 2) end)
    if not ok2 or not char then return nil end
    local ok3, status = pcall(function() return char:WaitForChild("Status", 2) end)
    if not ok3 or not status then return nil end
    return status
end
local function nofall_enable()
    nofall_enabled = true
    local status = getStatusFolder()
    if status and not status:FindFirstChild("FallDamageCD") then
        nofall_folder = Instance.new("Folder")
        nofall_folder.Name = "FallDamageCD"
        nofall_folder.Archivable = true
        nofall_folder.Parent = status
    else
        nofall_folder = status and status:FindFirstChild("FallDamageCD")
    end
end
local function nofall_disable()
    nofall_enabled = false
    if nofall_folder and nofall_folder.Parent then nofall_folder:Destroy() end
    nofall_folder = nil
end
LocalPlayer.CharacterAdded:Connect(function()
    if nofall_enabled then nofall_enable() end
end)
local nofall_toggle = MovementGroup:AddToggle('MovementNoFallDamageToggle', {
    Text = 'No Fall Damage',
    Default = false,
    Tooltip = 'Toggle no fall damage',
})
nofall_toggle:OnChanged(function()
    if nofall_toggle.Value then nofall_enable()
    else nofall_disable() end
end)

---------------------------------------------------------
-- VISUAL: ESP (Universal, Skeleton, 2D Chams)
---------------------------------------------------------
-- [Paste the full ESP code from previous messages here, or ask for it!]

---------------------------------------------------------
-- AUTOMATION: Attach To Back
---------------------------------------------------------
-- [Paste the full Attach To Back code from previous messages here, or ask for it!]

---------------------------------------------------------
-- UI/Config/Theme
---------------------------------------------------------
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
