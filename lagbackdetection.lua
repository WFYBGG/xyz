--// Lagback Freeze Script
--// Based on extreme speed spike detection

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local MAX_LOG_ENTRIES = 100
local recentData = {}
local lastPos
local totalDistance = 0

local lagbackSpeedThreshold = 250 -- Speed above this triggers lagback freeze 
local freezeDuration = 1 -- seconds

local function safeInsert(tbl, value)
	pcall(function()
		table.insert(tbl, value)
		if #tbl > MAX_LOG_ENTRIES then
			table.remove(tbl, 1)
		end
	end)
end

local function getMagnitude(v1, v2)
	local success, result = pcall(function()
		return (v1 - v2).Magnitude
	end)
	return success and result or 0
end

local function logData()
	pcall(function()
		warn("=== Lagback Detected! Logging Recent Data ===")
		for i, entry in ipairs(recentData) do
			print(string.format(
				"t=%.2f | speed=%.2f | dist=%.2f",
				entry.time, entry.speed, entry.distance
			))
		end
		warn("=== End of Log ===")
	end)
end

local function freezeMovement(char)
	pcall(function()
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hum and hrp then
			local oldSpeed = hum.WalkSpeed
			local oldJump = hum.JumpPower

			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hrp.Anchored = true

			task.delay(freezeDuration, function()
				pcall(function()
					hum.WalkSpeed = oldSpeed
					hum.JumpPower = oldJump
					hrp.Anchored = false
				end)
			end)
		end
	end)
end

pcall(function()
	RunService.Heartbeat:Connect(function(dt)
		pcall(function()
			local char = LocalPlayer.Character
			if not (char and char:FindFirstChild("HumanoidRootPart")) then return end

			local hrp = char.HumanoidRootPart
			local currentPos = hrp.Position

			if lastPos then
				local stepDist = getMagnitude(currentPos, lastPos)
				totalDistance = totalDistance + stepDist
				local speed = stepDist / math.max(dt, 0.0001)

				safeInsert(recentData, {
					time = tick(),
					speed = speed,
					distance = totalDistance
				})

				-- Detect huge speed spike as lagback
				if speed > lagbackSpeedThreshold then
					logData()
					freezeMovement(char)
					totalDistance = 0
				end
			end

			lastPos = currentPos
		end)
	end)
end)
