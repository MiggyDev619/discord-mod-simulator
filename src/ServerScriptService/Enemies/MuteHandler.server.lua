-- ServerScriptService/Enemies/MuteHandler
-- Validates client MuteEnemy requests. Two-hit destroy: first hit on a fresh
-- target sets MuteFrozenUntil + freezes the enemy. Second hit on a target with
-- MuteFrozenUntil OR FrozenUntil (Timeout) active calls EnemySpawner.DestroyEnemy
-- and the kill is processed through the same path as Ban (with combo bonus).

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local Effects     = require(Shared:WaitForChild("Effects"))
local remotes     = Shared:WaitForChild("Remotes")
local muteEnemy   = remotes:WaitForChild("MuteEnemy")
local muteShotFx  = remotes:WaitForChild("MuteShotFx")

local spawnerScript = ServerScriptService:WaitForChild("Enemies"):WaitForChild("EnemySpawner")
local destroyEnemy  = spawnerScript:WaitForChild("DestroyEnemy")

local MUTE_FREEZE_COLOR = Color3.fromRGB(70, 150, 255)

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

	-- Already frozen (by Mute Gun or Timeout) → second hit destroys + combo reward.
	local frozenUntil     = enemyPart:GetAttribute("FrozenUntil")
	local muteFrozenUntil = enemyPart:GetAttribute("MuteFrozenUntil")
	local alreadyFrozen   = (frozenUntil and now < frozenUntil) or (muteFrozenUntil and now < muteFrozenUntil)

	if alreadyFrozen then
		local reward, combo = destroyEnemy:Invoke(player, enemyPart)
		print(string.format("[MuteHandler] %s killed %s with second shot (+%d coins%s)",
			player.Name, enemyPart.Name, reward, combo and " — COMBO!" or ""))
		return
	end

	-- First hit → snapshot color, freeze, recolor blue, play freeze effect.
	if not enemyPart:GetAttribute("OriginalColor") then
		enemyPart:SetAttribute("OriginalColor", enemyPart.Color)
	end
	enemyPart:SetAttribute("MuteFrozenUntil", now + Config.MUTE_FREEZE_DURATION)
	enemyPart.Color = MUTE_FREEZE_COLOR

	print(string.format("[MuteHandler] %s froze %s for %.1fs (first shot)",
		player.Name, enemyPart.Name, Config.MUTE_FREEZE_DURATION))
	Effects.MuteEffect(enemyPart.Position)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotTime[player] = nil
end)

-- Multiplayer: bounce shot tracer events to every client so other players see
-- this player's tracers. The shooter's own client already rendered locally;
-- ClientMain skips its own bounce by checking shooter == LocalPlayer.
-- Light validation: muzzle must be near the player's character to discourage
-- spoofed-position spam (no real exploit since it's cosmetic, but cheap to
-- gate against trolls).
muteShotFx.OnServerEvent:Connect(function(player, muzzle, endPoint)
	if typeof(muzzle) ~= "Vector3" or typeof(endPoint) ~= "Vector3" then return end
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (muzzle - root.Position).Magnitude > 8 then return end

	muteShotFx:FireAllClients(player, muzzle, endPoint)
end)
