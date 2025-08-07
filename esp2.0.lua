--[[ 
    Simple ESP (No distance limit)
    - Shows player DisplayName, [Health/MaxHealth], [distance]
    - Uses pcall for all Roblox object/property access (anti-flag)
    - Health/MaxHealth from Workspace.Living[Model.Name==Player.Name].Humanoid
    - NO range/distance limit of any kind
]]

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
                    pcall(function() if type(v) == "userdata" and v.Remove then v:Remove() end end)
                end
            else
                pcall(function() if type(obj) == "userdata" and obj.Remove then obj:Remove() end end)
            end
        end
        pcall(function() ESPObjects[player] = nil end)
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    pcall(function()
        if ESPObjects[player] then cleanupESP(player) end

        local box, nameText, healthText, distText

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

        ESPObjects[player] = {
            Box = box,
            Name = nameText,
            Health = healthText,
            Distance = distText,
        }
    end)
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

-- Per-frame update (NO distance/range check)
RunService.RenderStepped:Connect(function()
    for player, tbl in pairs(ESPObjects) do
        pcall(function()
            local char = getCharacterModel(player)
            local box, nameText, healthText, distText
            pcall(function()
                box = tbl.Box
                nameText = tbl.Name
                healthText = tbl.Health
                distText = tbl.Distance
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
                    -- Draw box: simple vertical
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
                else
                    pcall(function() box.Visible = false end)
                    pcall(function() nameText.Visible = false end)
                    pcall(function() healthText.Visible = false end)
                    pcall(function() distText.Visible = false end)
                end
            else
                pcall(function() box.Visible = false end)
                pcall(function() nameText.Visible = false end)
                pcall(function() healthText.Visible = false end)
                pcall(function() distText.Visible = false end)
            end
        end)
    end
end)
