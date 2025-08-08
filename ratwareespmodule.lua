local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer
pcall(function() LocalPlayer = Players.LocalPlayer end)

local ESP_Enabled = false
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

-- Player join/leave management
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
    if not ESP_Enabled then
        -- ESP is off: hide all ESP visuals
        for player, tbl in pairs(ESPObjects) do
            pcall(function()
                if tbl.Box then tbl.Box.Visible = false end
                if tbl.Name then tbl.Name.Visible = false end
                if tbl.Health then tbl.Health.Visible = false end
                if tbl.Distance then tbl.Distance.Visible = false end
                if tbl.ChamBox then tbl.ChamBox.Visible = false end
                if tbl.Skeleton then
                    for _, line in pairs(tbl.Skeleton) do
                        line.Visible = false
                    end
                end
            end)
        end
        return
    end

    local streamedPlayers = {}
    for player, tbl in pairs(ESPObjects) do
        streamedPlayers[player] = true
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

-- Grab the toggle from Linora UI groupbox
local playerESPToggle = VisualsGroup.PlayerESP

-- Hook toggle OnChanged event
if playerESPToggle and playerESPToggle.OnChanged then
    playerESPToggle:OnChanged(function(value)
        ESP_Enabled = value
        if not value then
            ClearESP()
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    pcall(function() createESP(plr) end)
                end
            end
        end
    end)
end


