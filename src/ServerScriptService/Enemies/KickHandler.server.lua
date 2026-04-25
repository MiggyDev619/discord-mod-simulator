-- ServerScriptService/Enemies/KickHandler
-- Validates client KickEnemies requests and pushes every enemy in the player's forward cone.
-- Sets KickedUntil (number) and KickVelocity (Vector3) on each hit enemy.
-- EnemySpawner's heartbeat reads those attributes and drives BodyVelocity during the window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared:WaitForChild("Config"))
local Effects      = require(Shared:WaitForChild("Effects"))
local remotes      = Shared:WaitForChild("Remotes")
local kickEnemies  = remotes:WaitForChild("KickEnemies")

local lastKickTime = {}  -- [player] = tick of last accepted kick

kickEnemies.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local now  = tick()
	local last = lastKickTime[player] or 0
	if now - last < Config.KICK_COOLDOWN then return end
	lastKickTime[player] = now

	local origin      = root.Position
	local forward     = root.CFrame.LookVector
	local coneDot     = math.cos(math.rad(Config.KICK_CONE_ANGLE * 0.5))
	local expiresAt   = now + Config.KICK_DURATION
	local hitCount    = 0

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("IsEnemy") then
			local diff = obj.Position - origin
			local dist = diff.Magnitude
			if dist > 0 and dist <= Config.KICK_RANGE then
				local dir = diff.Unit
				if dir:Dot(forward) >= coneDot then
					-- Push radially away from the player (not just along LookVector) so
					-- off-center enemies in the cone fan out instead of bunching up.
					local pushDir       = Vector3.new(dir.X, 0, dir.Z).Unit
					local kickVelocity  = pushDir * Config.KICK_FORCE
					obj:SetAttribute("KickedUntil", expiresAt)
					obj:SetAttribute("KickVelocity", kickVelocity)
					hitCount += 1
				end
			end
		end
	end

	print(string.format(
		"[KickHandler] %s kicked %d enemy(ies)",
		player.Name, hitCount
	))
	if hitCount > 0 then
		Effects.KickEffect(origin + forward * 2 + Vector3.new(0, -1, 0))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastKickTime[player] = nil
end)
