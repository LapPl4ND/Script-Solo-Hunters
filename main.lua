-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "SimpleImGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 200) -- ⬅️ agrandi pour AUTO SKILL
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Toxyo Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)

local function makeButton(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0.9, 0, 0, 35)
	b.Position = UDim2.new(0.05, 0, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	b.BorderSizePixel = 0
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.fromRGB(255,255,255)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local tpButton        = makeButton("TP Mob", 40)
local autoClickButton = makeButton("Auto Kill : OFF", 80)
local autoSkillButton = makeButton("AUTO SKILL (Test) : OFF", 120)

-- ================= UTILS =================
local function pressKey(key)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- ================= AUTO CLICK =================
local autoClick = false
local autoClickConnection

autoClickButton.MouseButton1Click:Connect(function()
	autoClick = not autoClick
	autoClickButton.Text = autoClick and "Auto Kill : ON" or "Auto Kill : OFF"

	if autoClick then
		pressKey(Enum.KeyCode.One)

		autoClickConnection = RunService.RenderStepped:Connect(function()
			VirtualUser:Button1Down(Vector2.zero, workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button1Up(Vector2.zero, workspace.CurrentCamera.CFrame)
		end)
	else
		if autoClickConnection then
			autoClickConnection:Disconnect()
			autoClickConnection = nil
		end
	end
end)

-- ================= AUTO SKILL =================
local autoSkill = false
local autoSkillConn
local SKILL_COOLDOWN = 10 -- secondes
local isCastingSkill = false

local function pressKey(key)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

autoSkillButton.MouseButton1Click:Connect(function()
	autoSkill = not autoSkill
	autoSkillButton.Text = autoSkill and "AUTO SKILL (Test) : ON" or "AUTO SKILL (Test) : OFF"

	if not autoSkill then
		if autoSkillConn then
			autoSkillConn:Disconnect()
			autoSkillConn = nil
		end
		isCastingSkill = false
		return
	end

	autoSkillConn = RunService.Heartbeat:Connect(function()
		if not autoSkill or isCastingSkill then return end
		isCastingSkill = true

		task.spawn(function()
			-- 🔥 combo instant
			pressKey(Enum.KeyCode.Two)
			task.wait(0.1)

			pressKey(Enum.KeyCode.F)
			task.wait(0.1)

			pressKey(Enum.KeyCode.One)

			-- ⏳ cooldown APRÈS le skill
			task.wait(SKILL_COOLDOWN)

			isCastingSkill = false
		end)
	end)
end)


-- ================= FIND CLOSEST MOB =================
local function findClosestMob(fromPos)
	local closest, minDist = nil, math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if not obj:IsA("Model") then continue end
		if Players:GetPlayerFromCharacter(obj) then continue end

		local hum = obj:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end

		local root =
			obj:FindFirstChild("HumanoidRootPart")
			or obj.PrimaryPart
			or obj:FindFirstChildWhichIsA("BasePart", true)

		if not root then continue end
		if root.Anchored and hum.MaxHealth < 500 then continue end

		local dist = (root.Position - fromPos).Magnitude
		if dist < minDist and dist < 600 then
			minDist = dist
			closest = obj
		end
	end

	return closest
end

-- ================= TP / ORBIT =================
local rotating = false
local angle = 0
local connection
local lastSafeCFrame
local noMobTime = 0
local NO_MOB_DELAY = 3

tpButton.MouseButton1Click:Connect(function()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	rotating = not rotating
	if not rotating then
		if connection then connection:Disconnect() end
		lastSafeCFrame = nil
		noMobTime = 0
		return
	end

	local mob = findClosestMob(hrp.Position)
	if not mob then rotating = false return end
	local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")

	angle = 0
	noMobTime = 0

	connection = RunService.RenderStepped:Connect(function(dt)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		if not mob or not mob.Parent or not mobHumanoid or mobHumanoid.Health <= 0 then
			mob = findClosestMob(hrp.Position)

			if not mob then
				noMobTime += dt
				if noMobTime >= NO_MOB_DELAY then
					connection:Disconnect()
					rotating = false
					lastSafeCFrame = nil
				end
				return
			end

			mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
			angle = 0
			noMobTime = 0
			return
		end

		angle += dt * 2
		local cf, size = mob:GetBoundingBox()
		local offset = Vector3.new(
			math.cos(angle) * 6,
			size.Y / 2 + 6,
			math.sin(angle) * 6
		)

		lastSafeCFrame = CFrame.new(cf.Position + offset) * CFrame.Angles(0, angle + math.pi, 0)
		hrp.CFrame = lastSafeCFrame
	end)
end)
