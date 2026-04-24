-- ServerScriptService/Enemies/TimeoutHandler
-- Validates client TimeoutEnemy requests and freezes the target for Config.TIMEOUT_DURATION.
-- Sets FrozenUntil (number) and OriginalColor (Color3) attributes on the enemy.
-- EnemySpawner's movement loop reads FrozenUntil and drops effective speed to 0.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local Config        = require(Shared:WaitForChild("Config"))
local Effects       = require(Shared:WaitForChild("Effects"))
local remotes       = Shared:WaitForChild("Remotes")
local timeoutEnemy  = remotes:WaitForChild("TimeoutEnemy")

local TIMEOUT_COLOR = Color3.fromRGB(255, 200, 50)

local lastCastTime = {}  -- [player] = tick of last accepted timeout

timeoutEnemy.OnServerEvent:Connect(function(player, enemyPart)
	if not enemyPart
		or not enemyPart.Parent
		or not enemyPart:GetAttribute("IsEnemy")
		or not enemyPart:IsDescendantOf(workspace) then
		return
	end

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if (enemyPart.Position - root.Position).Magnitude > Config.TIMEOUT_RANGE * 1.5 then
		return
	end

	local now  = tick()
	local last = lastCastTime[player] or 0
	if now - last < Config.TIMEOUT_COOLDOWN then return end
	lastCastTime[player] = now

	-- Preserve the enemy's pre-status color so EnemySpawner can restore it on expiry.
	-- Skip if another status already snapshotted it (mute, repeat timeout).
	if not enemyPart:GetAttribute("OriginalColor") then
		enemyPart:SetAttribute("OriginalColor", enemyPart.Color)
	end

	enemyPart:SetAttribute("FrozenUntil", now + Config.TIMEOUT_DURATION)
	enemyPart.Color = TIMEOUT_COLOR

	print(string.format(
		"[TimeoutHandler] %s timed out %s for %.1fs",
		player.Name, enemyPart.Name, Config.TIMEOUT_DURATION
	))
	Effects.TimeoutEffect(enemyPart.Position)
end)

Players.PlayerRemoving:Connect(function(player)
	lastCastTime[player] = nil
end)
