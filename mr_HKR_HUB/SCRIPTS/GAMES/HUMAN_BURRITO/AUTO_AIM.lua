local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer


local avoidRadius = 15      -- Distance to keep from other players
local detectionRadius = 20   -- Radius to highlight and find targets
local offsetBehind = 3       -- Distance behind the target to teleport during attack

local targeting = false
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = workspace

local function getTool()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:FindFirstChild("Default") or character:WaitForChild("Default", 5)
end

-- Create ScreenGui and Button (mobile-friendly)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AttackGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 180, 0, 60)
button.Position = UDim2.new(1, -200, 1, -100)
button.AnchorPoint = Vector2.new(0, 0)
button.Text = "Auto Attack"
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.SourceSansBold
button.Parent = screenGui

-- Find closest player within detectionRadius
local function findClosestPlayer()
	local myChar = player.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return nil end

	local closest = nil
	local closestDist = detectionRadius

	for _, other in pairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (myHRP.Position - other.Character.HumanoidRootPart.Position).Magnitude
			if dist < closestDist then
				closest = other
				closestDist = dist
			end
		end
	end

	return closest
end

-- Passive avoidance: move away if too close to any player
local function avoidPlayers()
	local myChar = player.Character
	local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, other in pairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local otherHRP = other.Character.HumanoidRootPart
			local dist = (hrp.Position - otherHRP.Position).Magnitude

			if dist < avoidRadius then
				-- Calculate direction away from the player
				local awayVector = (hrp.Position - otherHRP.Position).Unit
				local newPos = hrp.Position + awayVector * (avoidRadius - dist + 1)

				-- Move character safely
				hrp.CFrame = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
				break -- avoid one player at a time to avoid jitter
			end
		end
	end
end

-- Highlight closest player constantly
RunService.RenderStepped:Connect(function()
	local target = findClosestPlayer()
	if target and target.Character then
		highlight.Adornee = target.Character
		highlight.Enabled = true
	else
		highlight.Enabled = false
	end

	-- Passive avoidance only if not targeting
	if not targeting then
		avoidPlayers()
	end
end)

-- Attack: teleport behind and activate tool repeatedly
local function followAndAttack(targetPlayer)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local tool = getTool()

	while targeting and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") do
		local targetHRP = targetPlayer.Character.HumanoidRootPart
		local dist = (hrp.Position - targetHRP.Position).Magnitude
		if dist > detectionRadius then break end

		-- Teleport behind
		local behindPos = targetHRP.Position - (targetHRP.CFrame.LookVector * offsetBehind)
		hrp.CFrame = CFrame.new(behindPos, targetHRP.Position)

		if tool then tool:Activate() end
		task.wait(0.1)
	end

	targeting = false
end

-- Button toggles targeting/attacking
button.MouseButton1Click:Connect(function()
	if targeting then
		targeting = false
	else
		local target = findClosestPlayer()
		if target then
			targeting = true
			task.spawn(function()
				followAndAttack(target)
			end)
		end
	end
end)