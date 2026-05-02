-- ServerScriptService/Enemies/KickHandler
-- Validates client KickEnemies requests and pushes every enemy in the player's forward cone.
-- Sets KickedUntil (number) and KickVelocity (Vector3) on each hit enemy.
-- EnemySpawner's heartbeat reads those attributes and drives BodyVelocity during the window.

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local Effects         = require(Shared:WaitForChild("Effects"))
local CurrencyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("CurrencyManager"))
local remotes         = Shared:WaitForChild("Remotes")
local kickEnemies     = remotes:WaitForChild("KickEnemies")

local lastKickTime = {}  -- [player] = tick of last accepted kick

kickEnemies.OnServerEvent:Connect(function(player, lookDir)
	-- Trust the client's camera-derived direction (server can't read camera state),
	-- but sanity-check it: must be a Vector3 of roughly unit length and horizontal.
	-- A malicious client could only spoof their kick angle, which is harmless in a
	-- casual game with a 1s cooldown and no PvP.
	if typeof(lookDir) ~= "Vector3" then return end
	local mag = lookDir.Magnitude
	if mag < 0.5 or mag > 1.5 then return end
	if math.abs(lookDir.Y) > 0.5 then return end  -- must be roughly horizontal

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local now  = tick()
	local last = lastKickTime[player] or 0
	if now - last < Config.KICK_COOLDOWN then return end
	lastKickTime[player] = now

	local origin    = root.Position
	local forward   = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
	local coneDot   = math.cos(math.rad(Config.KICK_CONE_ANGLE * 0.5))
	local expiresAt = now + Config.KICK_DURATION
	local hitCount  = 0
	local coinTotal = 0

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("IsEnemy") then
			local diff = obj.Position - origin
			local dist = diff.Magnitude
			if dist > 0 and dist <= Config.KICK_RANGE then
				local dir = diff.Unit
				if dir:Dot(forward) >= coneDot then
					-- Push radially away from the player (not just along LookVector) so
					-- off-center enemies in the cone fan out instead of bunching up.
					local pushDir      = Vector3.new(dir.X, 0, dir.Z).Unit
					local kickVelocity = pushDir * Config.KICK_FORCE
					obj:SetAttribute("KickedUntil",  expiresAt)
					obj:SetAttribute("KickVelocity", kickVelocity)
					hitCount += 1

					-- Per-hit coin reward — small base, doubled if the enemy was frozen
					-- (Timeout's FrozenUntil OR Mute Gun's MuteFrozenUntil) at hit time.
					local frozenUntil     = obj:GetAttribute("FrozenUntil")
					local muteFrozenUntil = obj:GetAttribute("MuteFrozenUntil")
					local frozen          = (frozenUntil and now < frozenUntil)
						or (muteFrozenUntil and now < muteFrozenUntil)
					coinTotal = coinTotal + (Config.COIN_KICK_PER_HIT * (frozen and Config.COMBO_MULTIPLIER or 1))
				end
			end
		end
	end

	if hitCount > 0 then
		CurrencyManager.AddCoins(player, coinTotal)
		Effects.KickEffect(origin + forward * 2 + Vector3.new(0, -1, 0))
		print(string.format("[KickHandler] %s kicked %d enemy(ies) (+%d coins)",
			player.Name, hitCount, coinTotal))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastKickTime[player] = nil
end)
