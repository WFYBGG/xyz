-- Scarlet Hook Rogueblox Modular Script Hub (LinoriaLib)
-- Tabs: Main (Movement, Visual, Automation)
-- All modules are required and initialized in this file.
-- Make sure LinoriaLib (and its addons) are in your executor's environment or auto-downloading!

-- LinoriaLib loader
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Main Window
local Window = Library:CreateWindow({
    Title = 'Scarlet Hook Rogueblox',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Tabs & Groups
local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Left (Movement), Left (Visual), Right (Automation)
local MovementGroup = Tabs.Main:AddLeftGroupbox('Movement')
local VisualGroup = Tabs.Main:AddLeftGroupbox('Visual')
local AutomationGroup = Tabs.Main:AddRightGroupbox('Automation')

-----------------------------------------------------------------------
-- Movement Modules
-----------------------------------------------------------------------
local MovementSpeed = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local MovementSpeed = {}
    MovementSpeed.__index = MovementSpeed

    MovementSpeed._enabled = false
    MovementSpeed._speed = 100
    MovementSpeed._keybind = Enum.KeyCode.F4
    MovementSpeed._bodyVelocity = nil
    MovementSpeed._charCon = nil
    MovementSpeed._toggleObj = nil
    MovementSpeed._sliderObj = nil
    MovementSpeed._keyObj = nil

    function MovementSpeed:ResetHumanoidState()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.JumpPower = 50
            humanoid.WalkSpeed = 16
            if self._bodyVelocity then
                self._bodyVelocity.Parent = nil
            end
        end
    end

    function MovementSpeed:Enable()
        self._enabled = true
        local char = LocalPlayer.Character
        if not self._bodyVelocity then
            self._bodyVelocity = Instance.new("BodyVelocity")
            self._bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            self._bodyVelocity.Velocity = Vector3.new(0,0,0)
        end
        if char and char:FindFirstChild("HumanoidRootPart") then
            self._bodyVelocity.Parent = char.HumanoidRootPart
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpPower = 0
            end
        end
    end

    function MovementSpeed:Disable()
        self._enabled = false
        self:ResetHumanoidState()
    end

    function MovementSpeed:OnCharacterAdded(char)
        if self._enabled and self._bodyVelocity then
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            local hum = char:WaitForChild("Humanoid", 5)
            if hrp then
                self._bodyVelocity.Parent = hrp
                if hum then
                    hum.JumpPower = 0
                end
            end
        end
    end

    function MovementSpeed:BindKey()
        if self._inputCon then
            self._inputCon:Disconnect()
            self._inputCon = nil
        end
        self._inputCon = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == self._keybind then
                self._toggleObj:SetValue(not self._enabled)
            end
        end)
    end

    function MovementSpeed:Step(delta)
        if not self._enabled then
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum then
            local moveDirection = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + workspace.CurrentCamera.CFrame.RightVector
            end
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
            end
            local maxSpeedPerFrame = 49 / delta
            local vel = moveDirection * math.min(self._speed, maxSpeedPerFrame)
            if self._bodyVelocity then
                self._bodyVelocity.Velocity = vel
            end
            if hum.Health <= 0 then
                self:Disable()
                self._toggleObj:SetValue(false)
            end
        else
            self:Disable()
            self._toggleObj:SetValue(false)
        end
    end

    function MovementSpeed:Init(Groupbox)
        local toggle = Groupbox:AddToggle('MovementSpeedToggle', {
            Text = 'Movement Speed',
            Default = false,
            Tooltip = 'Enable custom movement speed',
        })
        self._toggleObj = toggle

        local slider = Groupbox:AddSlider('MovementSpeedSlider', {
            Text = 'Speed',
            Default = 100,
            Min = 0,
            Max = 200,
            Rounding = 0,
            Compact = false,
            Callback = function(Value)
                self._speed = Value
            end
        })
        self._sliderObj = slider

        local key = Groupbox:AddLabel('Movement Speed Keybind'):AddKeyPicker('MovementSpeedKeybind', {
            Default = 'F4',
            Text = 'Movement Speed Keybind',
            NoUI = false,
            Mode = 'Toggle',
            Callback = function(Value)
                self._toggleObj:SetValue(not self._enabled)
            end,
            ChangedCallback = function(New)
                if typeof(New) == "EnumItem" then
                    self._keybind = New
                    self:BindKey()
                end
            end
        })
        self._keyObj = key

        toggle:OnChanged(function()
            if toggle.Value then
                self:Enable()
            else
                self:Disable()
            end
        end)

        slider:OnChanged(function()
            self._speed = slider.Value
        end)

        if self._charCon then self._charCon:Disconnect() end
        self._charCon = LocalPlayer.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(char)
        end)

        self:BindKey()

        if not self._stepCon then
            self._stepCon = RunService.RenderStepped:Connect(function(dt)
                self:Step(dt)
            end)
        end

        if Library and Library.OnUnload then
            Library:OnUnload(function()
                if self._bodyVelocity then self._bodyVelocity:Destroy() end
                if self._charCon then self._charCon:Disconnect() end
                if self._inputCon then self._inputCon:Disconnect() end
                if self._stepCon then self._stepCon:Disconnect() end
            end)
        end
    end

    return setmetatable(MovementSpeed, MovementSpeed)
end)()

local MovementFly = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local MovementFly = {}
    MovementFly.__index = MovementFly

    MovementFly._enabled = false
    MovementFly._speed = 100
    MovementFly._keybind = Enum.KeyCode.F4
    MovementFly._bodyVelocity = nil
    MovementFly._platform = nil
    MovementFly._charCon = nil
    MovementFly._toggleObj = nil
    MovementFly._sliderObj = nil
    MovementFly._keyObj = nil
    MovementFly._inputCon = nil
    MovementFly._stepCon = nil

    function MovementFly:ResetHumanoidState()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.JumpPower = 50
            humanoid.WalkSpeed = 16
        end
    end

    function MovementFly:Enable()
        self._enabled = true
        _G.Speed = self._speed

        if not self._platform then
            local platform = Instance.new("Part")
            platform.Name = "OldDebris"
            platform.Size = Vector3.new(6, 1, 6)
            platform.Anchored = true
            platform.CanCollide = true
            platform.Transparency = 0.75
            platform.Material = Enum.Material.SmoothPlastic
            platform.BrickColor = BrickColor.new("Bright blue")
            self._platform = platform
        end

        if not self._bodyVelocity then
            self._bodyVelocity = Instance.new("BodyVelocity")
            self._bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            self._bodyVelocity.Velocity = Vector3.new(0,0,0)
        end

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = 0
        end
        if char and char:FindFirstChild("HumanoidRootPart") then
            self._bodyVelocity.Parent = char.HumanoidRootPart
            self._platform.Parent = Workspace
            self._platform.CFrame = char.HumanoidRootPart.CFrame - Vector3.new(0, 3.499, 0)
        end
    end

    function MovementFly:Disable()
        self._enabled = false
        self:ResetHumanoidState()
        if self._platform then
            self._platform.Parent = nil
        end
        if self._bodyVelocity then
            self._bodyVelocity.Parent = nil
        end
    end

    function MovementFly:OnCharacterAdded(char)
        if self._enabled then
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            local hum = char:WaitForChild("Humanoid", 5)
            if hrp then
                self._bodyVelocity.Parent = hrp
                self._platform.Parent = Workspace
                self._platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
            end
            if hum then
                hum.JumpPower = 0
            end
        else
            if self._platform then self._platform.Parent = nil end
            if self._bodyVelocity then self._bodyVelocity.Parent = nil end
        end
    end

    function MovementFly:BindKey()
        if self._inputCon then
            self._inputCon:Disconnect()
            self._inputCon = nil
        end
        self._inputCon = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == self._keybind then
                self._toggleObj:SetValue(not self._enabled)
            end
        end)
    end

    function MovementFly:Step(delta)
        if not self._enabled then return end
        _G.Speed = self._speed

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum then
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Workspace.CurrentCamera.CFrame.RightVector
            end

            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
            end

            local maxSpeedPerFrame = math.min(200, 49 / delta)
            local velocity = Vector3.new(0, self._bodyVelocity and self._bodyVelocity.Velocity.Y or 0, 0)
            if moveDir.Magnitude > 0 then
                velocity = moveDir * math.min(_G.Speed * delta, maxSpeedPerFrame)
            end

            if self._bodyVelocity then
                self._bodyVelocity.Velocity = Vector3.new(velocity.X, self._bodyVelocity.Velocity.Y, velocity.Z)
            end

            hum.JumpPower = 0

            if self._platform then
                self._platform.CFrame = hrp.CFrame - Vector3.new(0, 3.499, 0)
                local flightMove = 49 * delta
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    self._platform.CFrame = self._platform.CFrame + Vector3.new(0, flightMove, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    self._platform.CFrame = self._platform.CFrame - Vector3.new(0, flightMove, 0)
                end
            end

            if hum.Health <= 0 then
                self:ResetHumanoidState()
                self._toggleObj:SetValue(false)
                self._enabled = false
                if self._platform then self._platform.Parent = nil end
                if self._bodyVelocity then self._bodyVelocity.Parent = nil end
            end
        else
            self:ResetHumanoidState()
            self._toggleObj:SetValue(false)
            self._enabled = false
            if self._platform then self._platform.Parent = nil end
            if self._bodyVelocity then self._bodyVelocity.Parent = nil end
        end
    end

    function MovementFly:Init(Groupbox)
        local toggle = Groupbox:AddToggle('MovementFlyToggle', {
            Text = 'Fly',
            Default = false,
            Tooltip = 'Enable flight',
        })
        self._toggleObj = toggle

        local slider = Groupbox:AddSlider('MovementFlySlider', {
            Text = 'Fly Speed',
            Default = 100,
            Min = 0,
            Max = 200,
            Rounding = 0,
            Compact = false,
            Callback = function(Value)
                self._speed = Value
                _G.Speed = Value
            end
        })
        self._sliderObj = slider

        local key = Groupbox:AddLabel('Fly Keybind'):AddKeyPicker('MovementFlyKeybind', {
            Default = 'F4',
            Text = 'Fly Keybind',
            NoUI = false,
            Mode = 'Toggle',
            Callback = function(Value)
                self._toggleObj:SetValue(not self._enabled)
            end,
            ChangedCallback = function(New)
                if typeof(New) == "EnumItem" then
                    self._keybind = New
                    self:BindKey()
                end
            end
        })
        self._keyObj = key

        toggle:OnChanged(function()
            if toggle.Value then
                self:Enable()
            else
                self:Disable()
            end
        end)

        slider:OnChanged(function()
            self._speed = slider.Value
            _G.Speed = slider.Value
        end)

        if self._charCon then self._charCon:Disconnect() end
        self._charCon = LocalPlayer.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(char)
        end)

        self:BindKey()

        if not self._stepCon then
            self._stepCon = RunService.RenderStepped:Connect(function(dt)
                self:Step(dt)
            end)
        end

        if Library and Library.OnUnload then
            Library:OnUnload(function()
                if self._bodyVelocity then self._bodyVelocity:Destroy() end
                if self._platform then self._platform:Destroy() end
                if self._charCon then self._charCon:Disconnect() end
                if self._inputCon then self._inputCon:Disconnect() end
                if self._stepCon then self._stepCon:Disconnect() end
            end)
        end
    end

    return setmetatable(MovementFly, MovementFly)
end)()

local MovementNoclip = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local MovementNoclip = {}
    MovementNoclip.__index = MovementNoclip

    MovementNoclip._enabled = false
    MovementNoclip._keybind = Enum.KeyCode.F5
    MovementNoclip._toggleObj = nil
    MovementNoclip._keyObj = nil
    MovementNoclip._charCon = nil
    MovementNoclip._inputCon = nil
    MovementNoclip._stepCon = nil

    function MovementNoclip:ResetNoClip()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
    end

    function MovementNoclip:Enable()
        self._enabled = true
    end

    function MovementNoclip:Disable()
        self._enabled = false
        self:ResetNoClip()
    end

    function MovementNoclip:OnCharacterAdded(char)
        -- No initial change; handled in RenderStepped
    end

    function MovementNoclip:BindKey()
        if self._inputCon then
            self._inputCon:Disconnect()
            self._inputCon = nil
        end
        self._inputCon = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == self._keybind then
                self._toggleObj:SetValue(not self._enabled)
            end
        end)
    end

    function MovementNoclip:Step()
        pcall(function()
            local char = LocalPlayer.Character
            if self._enabled and char and char:FindFirstChild("HumanoidRootPart") then
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
                self:ResetNoClip()
            end
        end)
    end

    function MovementNoclip:Init(Groupbox)
        local toggle = Groupbox:AddToggle('MovementNoclipToggle', {
            Text = 'Noclip',
            Default = false,
            Tooltip = 'Enable noclip',
        })
        self._toggleObj = toggle

        local key = Groupbox:AddLabel('Noclip Keybind'):AddKeyPicker('MovementNoclipKeybind', {
            Default = 'F5',
            Text = 'Noclip Keybind',
            NoUI = false,
            Mode = 'Toggle',
            Callback = function(Value)
                self._toggleObj:SetValue(not self._enabled)
            end,
            ChangedCallback = function(New)
                if typeof(New) == "EnumItem" then
                    self._keybind = New
                    self:BindKey()
                end
            end
        })
        self._keyObj = key

        toggle:OnChanged(function()
            if toggle.Value then
                self:Enable()
            else
                self:Disable()
            end
        end)

        if self._charCon then self._charCon:Disconnect() end
        self._charCon = LocalPlayer.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(char)
        end)

        self:BindKey()

        if not self._stepCon then
            self._stepCon = RunService.RenderStepped:Connect(function()
                self:Step()
            end)
        end

        if Library and Library.OnUnload then
            Library:OnUnload(function()
                if self._charCon then self._charCon:Disconnect() end
                if self._inputCon then self._inputCon:Disconnect() end
                if self._stepCon then self._stepCon:Disconnect() end
                self:ResetNoClip()
            end)
        end
    end

    return setmetatable(MovementNoclip, MovementNoclip)
end)()

local MovementNoFallDamage = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local MovementNoFallDamage = {}
    MovementNoFallDamage.__index = MovementNoFallDamage

    MovementNoFallDamage._enabled = false
    MovementNoFallDamage._toggleObj = nil
    MovementNoFallDamage._charCon = nil
    MovementNoFallDamage._status = nil
    MovementNoFallDamage._nofallFolder = nil

    function MovementNoFallDamage:GetStatusFolder()
        local ok, living = pcall(function() return Workspace:WaitForChild("Living", 2) end)
        if not ok or not living then return nil end
        local ok2, char = pcall(function() return living:WaitForChild(LocalPlayer.Name, 2) end)
        if not ok2 or not char then return nil end
        local ok3, status = pcall(function() return char:WaitForChild("Status", 2) end)
        if not ok3 or not status then return nil end
        return status
    end

    function MovementNoFallDamage:Enable()
        self._enabled = true
        self._status = self:GetStatusFolder()
        if self._status and not self._status:FindFirstChild("FallDamageCD") then
            self._nofallFolder = Instance.new("Folder")
            self._nofallFolder.Name = "FallDamageCD"
            self._nofallFolder.Archivable = true
            self._nofallFolder.Parent = self._status
        else
            self._nofallFolder = self._status and self._status:FindFirstChild("FallDamageCD")
        end
    end

    function MovementNoFallDamage:Disable()
        self._enabled = false
        if self._nofallFolder and self._nofallFolder.Parent then
            self._nofallFolder:Destroy()
        end
        self._nofallFolder = nil
    end

    function MovementNoFallDamage:OnCharacterAdded()
        self._status = self:GetStatusFolder()
        if self._enabled then
            self:Enable()
        end
    end

    function MovementNoFallDamage:Init(Groupbox)
        local toggle = Groupbox:AddToggle('MovementNoFallDamageToggle', {
            Text = 'No Fall Damage',
            Default = false,
            Tooltip = 'Toggle no fall damage (FallDamageCD in Status folder)',
        })
        self._toggleObj = toggle

        toggle:OnChanged(function()
            if toggle.Value then
                self:Enable()
            else
                self:Disable()
            end
        end)

        if self._charCon then self._charCon:Disconnect() end
        self._charCon = LocalPlayer.CharacterAdded:Connect(function()
            self:OnCharacterAdded()
        end)

        if Library and Library.OnUnload then
            Library:OnUnload(function()
                if self._charCon then self._charCon:Disconnect() end
                self:Disable()
            end)
        end
    end

    return setmetatable(MovementNoFallDamage, MovementNoFallDamage)
end)()

-----------------------------------------------------------------------
-- Visual Modules
-----------------------------------------------------------------------
local VisualESP = (function()
-- Universal ESP Module for Linoria GUI
-- Tab: Main, Group: Visual
-- Features: Toggle (enables/disables ESP for all players)
-- Original script logic is preserved, with robust cleanup and Drawing API usage.
-- HOW TO USE:
--   require this module and call VisualESP:Init(Groupbox)
--   Groupbox should be Tabs.Main:AddLeftGroupbox('Visual')

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    
    local LocalPlayer
    pcall(function() LocalPlayer = Players.LocalPlayer end)
    
    local ESPObjects = {}
    local ESPEnabled = false
    local StepConnection = nil
    
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
    
            local box, nameText, healthText, distText, chamBox
    
            pcall(function()
                box = Drawing.new("Line")
                box.Visible = false
                box.Thickness = 2
                box.Color = Color3.fromRGB(255, 25, 25)
            end)
    
            pcall(function()
                nameText = Drawing.new("Text")
                nameText.Size = 14
                nameText.Center = true
                nameText.Outline = true
                nameText.Color = Color3.fromRGB(255, 255, 255)
                nameText.Visible = false
            end)
    
            pcall(function()
                healthText = Drawing.new("Text")
                healthText.Size = 13
                healthText.Center = true
                healthText.Outline = true
                healthText.Color = Color3.fromRGB(0, 255, 0)
                healthText.Visible = false
            end)
    
            pcall(function()
                distText = Drawing.new("Text")
                distText.Size = 13
                distText.Center = true
                distText.Outline = true
                distText.Color = Color3.fromRGB(200, 200, 200)
                distText.Visible = false
            end)
    
            pcall(function()
                chamBox = Drawing.new("Square")
                chamBox.Visible = false
                chamBox.Color = Color3.fromRGB(255, 0, 0)
                chamBox.Transparency = 0.2
                chamBox.Filled = true
            end)
    
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
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
        ESPObjects[player].Skeleton = skeleton
    end
    
    local function manageESP(enable)
        if enable then
            -- Connect player events
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        createESP(plr)
                    end
                end
            end)
            if not StepConnection then
                StepConnection = RunService.RenderStepped:Connect(function()
                    for player, tbl in pairs(ESPObjects) do
                        pcall(function()
                            local char = getCharacterModel(player)
                            local box, nameText, healthText, distText, chamBox
                            pcall(function()
                                box = tbl.Box
                                nameText = tbl.Name
                                healthText = tbl.Health
                                distText = tbl.Distance
                                chamBox = tbl.ChamBox
                            end)
    
                            if char and safeGet(char, "HumanoidRootPart") then
                                local hrp
                                pcall(function() hrp = char.HumanoidRootPart end)
                                local pos, onScreen, health, maxHealth, extents, topW, onScreen1, botW, onScreen2, height, width
    
                                pcall(function()
                                    pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                                end)
    
                                pcall(function()
                                    health, maxHealth = getHealthInfo(char)
                                end)
    
                                pcall(function()
                                    extents = char:GetExtentsSize()
                                end)
    
                                pcall(function()
                                    topW, onScreen1 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, extents.Y/2, 0))
                                end)
                                pcall(function()
                                    botW, onScreen2 = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, extents.Y/2, 0))
                                end)
                                pcall(function()
                                    height = (botW.Y - topW.Y)
                                    width = height * 0.45
                                end)
    
                                if onScreen and onScreen1 and onScreen2 and health > 0 then
                                    -- Chams box (drawn behind ESP box)
                                    pcall(function()
                                        chamBox.Position = Vector2.new(topW.X - width/2, topW.Y)
                                        chamBox.Size = Vector2.new(width, height)
                                        chamBox.Color = Color3.fromRGB(255, 0, 0)
                                        chamBox.Transparency = 0.15
                                        chamBox.Visible = true
                                    end)
    
                                    -- Draw box (top horizontal line)
                                    pcall(function()
                                        box.From = Vector2.new(topW.X - width/2, topW.Y)
                                        box.To   = Vector2.new(topW.X + width/2, topW.Y)
                                        box.Visible = true
                                    end)
    
                                    -- Draw name
                                    pcall(function()
                                        nameText.Text = player.DisplayName
                                        nameText.Position = Vector2.new(pos.X, topW.Y - 16)
                                        nameText.Visible = true
                                    end)
    
                                    -- Draw health/maxhealth
                                    pcall(function()
                                        healthText.Text = "[" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
                                        healthText.Position = Vector2.new(pos.X, topW.Y - 2)
                                        local r = math.floor(255 - 255 * (health/maxHealth))
                                        local g = math.floor(255 * (health/maxHealth))
                                        healthText.Color = Color3.fromRGB(r, g, 0)
                                        healthText.Visible = true
                                    end)
    
                                    -- Draw distance
                                    pcall(function()
                                        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                        distText.Text = "[" .. math.floor(dist) .. "m]"
                                        distText.Position = Vector2.new(pos.X, botW.Y + 2)
                                        distText.Visible = true
                                    end)
    
                                    -- Draw skeleton
                                    drawSkeleton(player, char, Color3.fromRGB(255,255,255), 2)
                                else
                                    pcall(function() box.Visible = false end)
                                    pcall(function() nameText.Visible = false end)
                                    pcall(function() healthText.Visible = false end)
                                    pcall(function() distText.Visible = false end)
                                    pcall(function() chamBox.Visible = false end)
                                    -- Hide skeleton lines
                                    if tbl.Skeleton then
                                        for _, line in pairs(tbl.Skeleton) do
                                            pcall(function() line.Visible = false end)
                                        end
                                    end
                                end
                            else
                                pcall(function() box.Visible = false end)
                                pcall(function() nameText.Visible = false end)
                                pcall(function() healthText.Visible = false end)
                                pcall(function() distText.Visible = false end)
                                pcall(function() chamBox.Visible = false end)
                                -- Hide skeleton lines
                                if tbl.Skeleton then
                                    for _, line in pairs(tbl.Skeleton) do
                                        pcall(function() line.Visible = false end)
                                    end
                                end
                            end
                        end)
                    end
                    -- Robust cleanup: remove ESP for any player no longer in Players
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
            end
            -- Player join/leave management
            pcall(function()
                if not ESPObjects._PlayerAddedCon then
                    ESPObjects._PlayerAddedCon = Players.PlayerAdded:Connect(function(plr)
                        if plr ~= LocalPlayer then pcall(function() createESP(plr) end) end
                    end)
                end
                if not ESPObjects._PlayerRemovingCon then
                    ESPObjects._PlayerRemovingCon = Players.PlayerRemoving:Connect(function(plr)
                        pcall(function() cleanupESP(plr) end)
                    end)
                end
            end)
        else
            -- Disconnect draw
            if StepConnection then StepConnection:Disconnect() StepConnection = nil end
            -- Disconnect player management
            if ESPObjects._PlayerAddedCon then ESPObjects._PlayerAddedCon:Disconnect() ESPObjects._PlayerAddedCon = nil end
            if ESPObjects._PlayerRemovingCon then ESPObjects._PlayerRemovingCon:Disconnect() ESPObjects._PlayerRemovingCon = nil end
            -- Cleanup all ESP
            for player in pairs(ESPObjects) do
                if player ~= "_PlayerAddedCon" and player ~= "_PlayerRemovingCon" then
                    cleanupESP(player)
                end
            end
        end
    end
    
    local VisualESP = {}
    VisualESP.__index = VisualESP
    
    function VisualESP:Init(Groupbox)
        local toggle = Groupbox:AddToggle('VisualESPToggle', {
            Text = 'Universal ESP',
            Default = false,
            Tooltip = 'Enables ESP, skeleton, 2D chams for all players'
        })
        toggle:OnChanged(function()
            ESPEnabled = toggle.Value
            manageESP(ESPEnabled)
        end)
        -- Clean up on unload
        if Library and Library.OnUnload then
            Library:OnUnload(function()
                manageESP(false)
            end)
        end
    end

return setmetatable(VisualESP, VisualESP)
end)()

-----------------------------------------------------------------------
-- Automation Modules
-----------------------------------------------------------------------
local AutomationAttach = (function()
    -- ...[Attach To Back automation module as posted above, omitted here for brevity, but you would paste the full module code in this spot]...
    -- For the full code, see the previous answer for "modules/automation_attach_to_back.lua"
    -- Attach To Back (Automation) - Linoria Modular Version
    -- Tab: Main, Group: Automation (right side)
    -- Features: Toggle, Dropdown (player selector)
    -- Logic: Fully restores original attach/tween/noclip/nofall system, robust and respawn safe, no legacy GUI
    
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    local AutomationAttach = {}
    AutomationAttach.__index = AutomationAttach
    
    AutomationAttach._isAttached = false
    AutomationAttach._targetPlayer = nil
    AutomationAttach._attachConn = nil
    AutomationAttach._isTweening = false
    AutomationAttach._noclipEnabled = false
    AutomationAttach._nofallEnabled = false
    AutomationAttach._nofallFolder = nil
    AutomationAttach._toggleObj = nil
    AutomationAttach._dropdownObj = nil
    AutomationAttach._charCon = nil
    
    -- Utility: Safe get
    local function safeGet(obj, ...)
        local args = {...}
        for i,v in ipairs(args) do
            local ok,res = pcall(function() return obj[v] end)
            if not ok then return nil end
            obj = res
            if not obj then return nil end
        end
        return obj
    end
    
    -- Nofall logic
    function AutomationAttach:enableNofall()
        if self._nofallEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local status = safeGet(char, "Status")
        if not status then
            status = Instance.new("Folder")
            status.Name = "Status"
            status.Parent = char
        end
        if not status:FindFirstChild("FallDamageCD") then
            self._nofallFolder = Instance.new("Folder")
            self._nofallFolder.Name = "FallDamageCD"
            self._nofallFolder.Parent = status
        else
            self._nofallFolder = status:FindFirstChild("FallDamageCD")
        end
        self._nofallEnabled = true
    end
    
    function AutomationAttach:disableNofall()
        if not self._nofallEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local status = safeGet(char, "Status")
        if status then
            local fd = status:FindFirstChild("FallDamageCD")
            if fd then fd:Destroy() end
        end
        self._nofallEnabled = false
        self._nofallFolder = nil
    end
    
    -- Noclip logic
    function AutomationAttach:enableNoclip()
        if self._noclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        self._noclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
    
    function AutomationAttach:disableNoclip()
        if not self._noclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        self._noclipEnabled = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
    
    -- Tween logic
    local originalSpeed = 150
    function AutomationAttach:tweenToBack(callback)
        if self._isTweening then return end
        self._isTweening = true
        local char = LocalPlayer.Character
        local targetChar = self._targetPlayer and self._targetPlayer.Character
        local hrp = char and safeGet(char, "HumanoidRootPart")
        local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
        if not (hrp and targetHrp) then self._isTweening = false return end
    
        self:enableNoclip()
        self:enableNofall()
    
        local speed = originalSpeed
    
        -- Go up
        local upGoal = hrp.CFrame.Position + Vector3.new(0, 1000 - hrp.CFrame.Position.Y, 0)
        local upTime = (upGoal - hrp.Position).Magnitude / speed
        local upTween = TweenService:Create(hrp, TweenInfo.new(upTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(upGoal)})
        upTween:Play()
        upTween.Completed:Wait()
    
        -- Go horizontally above target
        local targetTop = targetHrp.Position + Vector3.new(0, 1000 - targetHrp.Position.Y, 0)
        local horizTime = (targetTop - hrp.Position).Magnitude / speed
        local horizTween = TweenService:Create(hrp, TweenInfo.new(horizTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetTop)})
        horizTween:Play()
        horizTween.Completed:Wait()
    
        -- Go down to back of target
        local backGoal = targetHrp.CFrame * CFrame.new(0, 0, 2)
        local downTime = (backGoal.Position - hrp.Position).Magnitude / speed
        local downTween = TweenService:Create(hrp, TweenInfo.new(downTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
        downTween:Play()
        downTween.Completed:Wait()
    
        self:disableNoclip()
        self._isTweening = false
        if callback then callback() end
    end
    
    function AutomationAttach:stopAttach()
        self._isAttached = false
        if self._attachConn then self._attachConn:Disconnect() self._attachConn = nil end
        self:disableNofall()
        self:disableNoclip()
    end
    
    function AutomationAttach:startAttach()
        self:stopAttach()
        self._isAttached = true
        self:enableNofall()
        self._attachConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local targetChar = self._targetPlayer and self._targetPlayer.Character
            local hrp = char and safeGet(char, "HumanoidRootPart")
            local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
            if not (hrp and targetHrp) then return end
            pcall(function()
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
            end)
        end)
    end
    
    function AutomationAttach:OnCharacterAdded(char)
        if self._isAttached then
            self:enableNofall()
        end
    end
    
    function AutomationAttach:Init(Groupbox)
        -- Dropdown for player selection
        local dropdown = Groupbox:AddDropdown('AttachPlayerDropdown', {
            Values = {},
            Text = 'Target Player',
            Tooltip = 'Select a player to attach to',
            Callback = function(Value)
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == Value then
                        self._targetPlayer = p
                        break
                    end
                end
            end
        })
        self._dropdownObj = dropdown
    
        -- Toggle for attach
        local toggle = Groupbox:AddToggle('AttachToggle', {
            Text = 'Attach To Back',
            Default = false,
            Tooltip = 'Attach your character to the back of the selected player',
        })
        self._toggleObj = toggle
    
        -- Toggle logic
        toggle:OnChanged(function()
            if self._isTweening then return end
            if toggle.Value then
                if not self._targetPlayer then
                    toggle:SetValue(false)
                    return
                end
                self:tweenToBack(function()
                    if not self._isAttached and self._targetPlayer then
                        self:startAttach()
                    end
                end)
            else
                self:stopAttach()
            end
        end)
    
        -- Populate dropdown, keep up to date
        local function updateDropdown()
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then table.insert(names, p.Name) end
            end
            dropdown.Values = names
            dropdown:SetValues(names)
        end
        updateDropdown()
        Players.PlayerAdded:Connect(updateDropdown)
        Players.PlayerRemoving:Connect(function(player)
            if player == self._targetPlayer then
                self._targetPlayer = nil
                toggle:SetValue(false)
            end
            updateDropdown()
        end)
    
        -- CharacterAdded respawn logic
        if self._charCon then self._charCon:Disconnect() end
        self._charCon = LocalPlayer.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(char)
        end)
    
        -- Clean up on unload
        if Library and Library.OnUnload then
            Library:OnUnload(function()
                if self._charCon then self._charCon:Disconnect() end
                self:stopAttach()
            end)
        end
    end

return setmetatable(AutomationAttach, AutomationAttach)
end)()

-----------------------------------------------------------------------
-- Initialize all modules in GUI
-----------------------------------------------------------------------

-- Movement
MovementSpeed:Init(MovementGroup)
MovementFly:Init(MovementGroup)
MovementNoclip:Init(MovementGroup)
MovementNoFallDamage:Init(MovementGroup)

-- Visual
VisualESP:Init(VisualGroup)

-- Automation (right side)
AutomationAttach:Init(AutomationGroup)

-----------------------------------------------------------------------
-- UI/Config/Theme
-----------------------------------------------------------------------

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

-----------------------------------------------------------------------
-- End of Main Script Hub
-----------------------------------------------------------------------
