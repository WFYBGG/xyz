local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Internal state
local targetPlayer = nil
local isAttached = false
local attachConn = nil
local isTweening = false
local isLocked = false
local noclipEnabled = false
local nofallEnabled = false
local nofallFolder = nil
local heightOffset = 0 -- Matches ATBHeight default
local zDistance = -3 -- Matches ATBDistance default

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
    local success, result = pcall(function()
        if nofallEnabled then return true end
        local char = LocalPlayer.Character
        if not char then return false end
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
        return true
    end)
    if not success then
        warn("Failed to enable nofall: " .. tostring(result))
    end
    return success and result
end

local function disableNofall()
    local success, result = pcall(function()
        if not nofallEnabled then return true end
        local char = LocalPlayer.Character
        if not char then return true end
        local status = safeGet(char, "Status")
        if status then
            local fd = status:FindFirstChild("FallDamageCD")
            if fd then fd:Destroy() end
        end
        nofallEnabled = false
        nofallFolder = nil
        return true
    end)
    if not success then
        warn("Failed to disable nofall: " .. tostring(result))
    end
    return success and result
end

-- Noclip logic
local function enableNoclip()
    local success, result = pcall(function()
        if noclipEnabled then return true end
        local char = LocalPlayer.Character
        if not char then return false end
        noclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
        return true
    end)
    if not success then
        warn("Failed to enable noclip: " .. tostring(result))
    end
    return success and result
end

local function disableNoclip()
    local success, result = pcall(function()
        if not noclipEnabled then return true end
        local char = LocalPlayer.Character
        if not char then return true end
        noclipEnabled = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
        return true
    end)
    if not success then
        warn("Failed to disable noclip: " .. tostring(result))
    end
    return success and result
end

-- Tween logic
local originalSpeed = 150
local function tweenToBack()
    if isTweening or isLocked then return false end
    isTweening = true
    local success, result = pcall(function()
        local char = LocalPlayer.Character
        local targetChar = targetPlayer and targetPlayer.Character
        local hrp = char and safeGet(char, "HumanoidRootPart")
        local targetHrp = targetChar and safeGet(targetChar, "HumanoidRootPart")
        if not (hrp and targetHrp) then return false end
        local distance = (hrp.Position - targetHrp.Position).Magnitude
        if distance > 20000 then return false end
        enableNoclip()
        enableNofall()
        local backGoal = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
        local tweenTime = distance / originalSpeed
        local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = backGoal})
        tween:Play()
        tween.Completed:Wait()
        isLocked = true
        isTweening = false
        return true
    end)
    if not success then
        warn("Tween failed: " .. tostring(result))
        isTweening = false
    end
    return success and result
end

-- Attach/Detach logic
local function stopAttach()
    local success, result = pcall(function()
        isAttached = false
        isLocked = false
        isTweening = false
        if attachConn then
            attachConn:Disconnect()
            attachConn = nil
        end
        disableNofall()
        disableNoclip()
        Toggles.AttachtobackToggle:SetValue(false)
        return true
    end)
    if not success then
        warn("Failed to stop attach: " .. tostring(result))
    end
    return success and result
end

local function startAttach()
    local success, result = pcall(function()
        if not targetPlayer then
            messagebox("Please select a player first!", "Error", 0)
            Toggles.AttachtobackToggle:SetValue(false)
            return false
        end
        stopAttach()
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
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, heightOffset, zDistance)
            elseif not isTweening then
                tweenToBack()
            end
        end)
        return true
    end)
    if not success then
        warn("Failed to start attach: " .. tostring(result))
        stopAttach()
    end
    return success and result
end

-- Linoria GUI integration
local success, result = pcall(function()
    -- Player dropdown
    Options.PlayerDropdown:OnChanged(function(value)
        local success, _ = pcall(function()
            targetPlayer = Players:FindFirstChild(value)
            if isAttached and not targetPlayer then
                stopAttach()
            end
            return true
        end)
        if not success then
            warn("Failed to update target player")
        end
    end)

    -- Toggle and keybind
    Toggles.AttachtobackToggle:OnChanged(function(value)
        local success, _ = pcall(function()
            if value then
                startAttach()
            else
                stopAttach()
            end
            return true
        end)
        if not success then
            warn("Failed to toggle attach")
        end
    end)

    -- Height slider
    Options.ATBHeight:OnChanged(function(value)
        local success, _ = pcall(function()
            heightOffset = value
            return true
        end)
        if not success then
            warn("Failed to update height offset")
        end
    end)

    -- Distance slider
    Options.ATBDistance:OnChanged(function(value)
        local success, _ = pcall(function()
            zDistance = value
            return true
        end)
        if not success then
            warn("Failed to update distance")
        end
    end)

    -- Re-apply nofall/noclip on respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        local success, _ = pcall(function()
            if isAttached then
                enableNofall()
                if not isLocked then
                    enableNoclip()
                end
            end
            return true
        end)
        if not success then
            warn("Failed to handle character respawn")
        end
    end)

    -- Cleanup when local player leaves
    LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local success, _ = pcall(function()
                stopAttach()
                return true
            end)
            if not success then
                warn("Failed to clean up on leave")
            end
        end
    end)

    -- Handle player leave
    Players.PlayerRemoving:Connect(function(player)
        local success, _ = pcall(function()
            if player == targetPlayer then
                targetPlayer = nil
                stopAttach()
                Options.PlayerDropdown:SetValue(nil)
            end
            return true
        end)
        if not success then
            warn("Failed to handle player removing")
        end
    end)

    return true
end)

if not success then
    warn("Setup failed: " .. tostring(result))
end
