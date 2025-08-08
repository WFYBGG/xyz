pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local lagbackSpeedThreshold = 300
    local holdTime = 5
    local restoreTime = 2 -- seconds to fully restore control
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    BodyVelocity.Name = "LagbackHoldVelocity"

    local lastPos = nil
    local holding = false
    local holdEndTime = 0
    local restoreStartTime = 0

    local function zeroVelocity()
        pcall(function()
            BodyVelocity.Velocity = Vector3.zero
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                BodyVelocity.Parent = player.Character.HumanoidRootPart
            end
        end)
    end

    local function removeVelocity()
        pcall(function()
            BodyVelocity.Parent = nil
        end)
    end

    RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                lastPos = nil
                return
            end

            local root = char.HumanoidRootPart
            local currentPos = root.Position
            if lastPos then
                local speed = (currentPos - lastPos).Magnitude / dt

                -- Lagback detection
                if not holding and speed >= lagbackSpeedThreshold then
                    holding = true
                    holdEndTime = tick() + holdTime
                    zeroVelocity()
                    print(string.format("[Lagback] Detected at %.1f speed, holding for %ds", speed, holdTime))
                end

                -- Holding phase
                if holding then
                    if tick() < holdEndTime then
                        zeroVelocity()
                    else
                        -- Start restoring
                        holding = false
                        restoreStartTime = tick()
                    end
                else
                    -- Restoration phase
                    local elapsed = tick() - restoreStartTime
                    if elapsed < restoreTime then
                        local factor = elapsed / restoreTime
                        BodyVelocity.Velocity = BodyVelocity.Velocity:Lerp(Vector3.zero, 1 - factor)
                        BodyVelocity.Parent = root
                    else
                        removeVelocity()
                    end
                end
            end
            lastPos = currentPos
        end)
    end)
end)
