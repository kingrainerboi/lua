local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local passiveDodgeEnabled = true
local targeting = false
local dragEnabled = false

local avoidRadius = 20
local detectionRadius = 25
local offsetBehind = 3

-- Setup Highlight
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = workspace

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombatGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create Button Generator
local function createButton(name, position, text)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 120, 0, 40)
	btn.Position = position
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.Font = Enum.Font.SourceSansBold
	btn.Parent = screenGui
	btn.Active = true
	btn.Draggable = false
	return btn
end

-- Buttons
local attackBtn = createButton("AttackBtn", UDim2.new(1, -140, 1, -140), "Auto")
local dodgeBtn = createButton("DodgeBtn", UDim2.new(1, -140, 1, -190), "Dodge")
local lockBtn = createButton("LockBtn", UDim2.new(1, -140, 1, -240), "Unlock")
lockBtn.Draggable = false

-- Label
local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(0, 200, 0, 30)
creditLabel.Position = UDim2.new(0.5, -100, 1, -30)
creditLabel.AnchorPoint = Vector2.new(0.5, 1)
creditLabel.Text = "By: MR_HKM V1"
creditLabel.BackgroundTransparency = 1
creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
creditLabel.TextScaled = true
creditLabel.Font = Enum.Font.SourceSansBold
creditLabel.Parent = screenGui

-- Drag Toggle
lockBtn.MouseButton1Click:Connect(function()
	dragEnabled = not dragEnabled
	lockBtn.Text = dragEnabled and "Lock" or "Unlock"
	for _, btn in pairs(screenGui:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.Draggable = dragEnabled
		end
	end
end)

-- Toggle Dodge
dodgeBtn.MouseButton1Click:Connect(function()
	passiveDodgeEnabled = not passiveDodgeEnabled
	dodgeBtn.Text = passiveDodgeEnabled and "Dodge" or "NoDodge"
end)

-- Get tool
local function getTool()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:FindFirstChild("Default") or character:WaitForChild("Default", 5)
end

-- Find closest enemy
local function findClosestPlayer()
	local myChar = player.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return nil end

	local closest
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

-- Passive dodge using walking
local function avoidPlayers()
	local myChar = player.Character
	local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end

	for _, other in pairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local otherHRP = other.Character.HumanoidRootPart
			local dist = (hrp.Position - otherHRP.Position).Magnitude

			if dist < avoidRadius then
				local awayDir = (hrp.Position - otherHRP.Position).Unit
				local targetPos = hrp.Position + awayDir * (avoidRadius - dist + 3)
				hum:MoveTo(targetPos)
				break
			end
		end
	end
end

-- Attack follow
local function followAndAttack(targetPlayer)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local tool = getTool()

	while targeting and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") do
		local targetHRP = targetPlayer.Character.HumanoidRootPart
		local dist = (hrp.Position - targetHRP.Position).Magnitude
		if dist > detectionRadius then break end

		local behindPos = targetHRP.Position - (targetHRP.CFrame.LookVector * offsetBehind)
		hrp.CFrame = CFrame.new(behindPos, targetHRP.Position)

		if tool then tool:Activate() end
		task.wait(0.1)
	end

	targeting = false
end

-- Button press
attackBtn.MouseButton1Click:Connect(function()
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

-- Reconnect on death
player.CharacterAdded:Connect(function()
	task.wait(1)
	highlight.Parent = workspace
end)

-- Continuous logic
RunService.RenderStepped:Connect(function()
	local target = findClosestPlayer()
	if target and target.Character then
		highlight.Adornee = target.Character
		highlight.Enabled = true
	else
		highlight.Enabled = false
	end

	if passiveDodgeEnabled and not targeting then
		avoidPlayers()
	end
end)