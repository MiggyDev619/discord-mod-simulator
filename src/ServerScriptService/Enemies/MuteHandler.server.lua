-- ServerScriptService/Enemies/MuteHandler
-- Validates client MuteEnemy requests and applies a time-limited slow to the target.
-- Sets MutedUntil (number) and OriginalColor (Color3) attributes on the enemy.
-- EnemySpawner's movement loop reads MutedUntil and applies Config.MUTE_SLOW_FACTOR.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Config    = require(Shared:WaitForChild("Config"))
local Effects   = require(Shared:WaitForChild("Effects"))
local remotes   = Shared:WaitForChild("Remotes")
local muteEnemy = remotes:WaitForChild("MuteEnemy")

local MUTE_COLOR = Color3.fromRGB(70, 150, 255)

local lastShotTime = {}  -- [player] = tick of last accepted mute

muteEnemy.OnServerEvent:Connect(function(player, enemyPart)
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

	if (enemyPart.Position - root.Position).Magnitude > Config.MUTE_RANGE * 1.5 then
		return
	end

	local now  = tick()
	local last = lastShotTime[player] or 0
	if now - last < Config.MUTE_COOLDOWN then return end
	lastShotTime[player] = now

	-- Preserve the enemy's pre-mute color so we can restore it on expiry.
	-- Skip if already muted (a second mute shouldn't snapshot the blue).
	if not enemyPart:GetAttribute("OriginalColor") then
		enemyPart:SetAttribute("OriginalColor", enemyPart.Color)
	end

	enemyPart:SetAttribute("MutedUntil", now + Config.MUTE_DURATION)
	enemyPart.Color = MUTE_COLOR

	print(string.format(
		"[MuteHandler] %s muted %s for %.1fs",
		player.Name, enemyPart.Name, Config.MUTE_DURATION
	))
	Effects.MuteEffect(enemyPart.Position)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotTime[player] = nil
end)
