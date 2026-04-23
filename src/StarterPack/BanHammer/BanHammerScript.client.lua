-- StarterPack/BanHammer/BanHammerScript (LocalScript)
-- On activate: find the closest enemy within range and fire BanEnemy to server.
-- Plays a swing animation (if Config.BAN_SWING_ANIM_ID is set) and shakes the camera on hits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Config    = require(Shared:WaitForChild("Config"))
local remotes   = Shared:WaitForChild("Remotes")
local banEnemy  = remotes:WaitForChild("BanEnemy")

local tool      = script.Parent
local player    = Players.LocalPlayer
local lastSwing = 0

-- Camera shake tuning (feel, not balance — kept local)
local SHAKE_DURATION  = 0.18
local SHAKE_MAGNITUDE = 0.35

local shakeActive = false
local swingTrack  -- AnimationTrack, loaded on Equipped

local function shakeCamera()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if shakeActive then return end
	shakeActive = true

	local startTime = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= SHAKE_DURATION then
			humanoid.CameraOffset = Vector3.zero
			shakeActive = false
			conn:Disconnect()
			return
		end
		local falloff = 1 - (elapsed / SHAKE_DURATION)
		humanoid.CameraOffset = Vector3.new(
			(math.random() - 0.5) * 2 * SHAKE_MAGNITUDE * falloff,
			(math.random() - 0.5) * 2 * SHAKE_MAGNITUDE * falloff,
			(math.random() - 0.5) * 2 * SHAKE_MAGNITUDE * falloff
		)
	end)
end

local function loadSwingAnimation(character)
	if Config.BAN_SWING_ANIM_ID == "" then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = Config.BAN_SWING_ANIM_ID

	swingTrack = animator:LoadAnimation(anim)
	swingTrack.Priority = Enum.AnimationPriority.Action
end

tool.Equipped:Connect(function()
	local character = player.Character
	if not character then return end
	loadSwingAnimation(character)
end)

tool.Unequipped:Connect(function()
	if swingTrack then
		swingTrack:Stop()
		swingTrack:Destroy()
		swingTrack = nil
	end
end)

tool.Activated:Connect(function()
	local now      = tick()
	local cooldown = player:GetAttribute("BanCooldown") or Config.BAN_COOLDOWN
	if now - lastSwing < cooldown then return end
	lastSwing = now

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Play swing regardless of whether a target is in range — the swing itself is feedback.
	if swingTrack then
		swingTrack:Stop()
		swingTrack:Play(0, 1, Config.BAN_SWING_SPEED)
	end

	local origin      = root.Position
	local closest     = nil
	local closestDist = Config.BAN_RANGE

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("IsEnemy") then
			local dist = (obj.Position - origin).Magnitude
			if dist < closestDist then
				closestDist = dist
				closest     = obj
			end
		end
	end

	if closest then
		print("[BanHammer] Firing ban on:", closest.Name, "dist:", math.floor(closestDist))
		banEnemy:FireServer(closest)
		shakeCamera()
	else
		print("[BanHammer] No enemy in range")
	end
end)
