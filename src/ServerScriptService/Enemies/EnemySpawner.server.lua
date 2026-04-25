-- ServerScriptService/Enemies/EnemySpawner
-- Spawns enemies on demand from RoundManager via BindableFunctions.
-- Handles per-frame movement and server-side ban validation (cooldown + range + coin reward).

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")
local Players             = game:GetService("Players")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local Effects         = require(Shared:WaitForChild("Effects"))
local Systems         = ServerScriptService:WaitForChild("Systems")
local GameManager     = require(Systems:WaitForChild("GameManager"))
local CurrencyManager = require(Systems:WaitForChild("CurrencyManager"))

local remotes  = Shared:WaitForChild("Remotes")
local banEnemy = remotes:WaitForChild("BanEnemy")

local map        = workspace:WaitForChild("Map")
local enemyStart = map:WaitForChild("EnemyStart")
local serverZone = map:WaitForChild("ServerZone")

local MUTE_COLOR = Color3.fromRGB(70, 150, 255)

local activeEnemies = {}
local lastBanTime   = {}  -- [player] = tick of last accepted ban

local ENEMY_TYPES = {
	Troll = {
		speed  = Config.ENEMY_SPEED,
		health = Config.ENEMY_HEALTH,
		color  = BrickColor.new("Bright red"),
		size   = Vector3.new(3, 4, 3),
		reward = Config.COIN_TROLL,
	},
	Spammer = {
		speed  = Config.SPAMMER_SPEED,
		health = Config.SPAMMER_HEALTH,
		color  = BrickColor.new("Bright orange"),
		size   = Vector3.new(2, 3, 2),
		reward = Config.COIN_SPAMMER,
	},
	Teleporter = {
		speed  = Config.TELEPORTER_SPEED,
		health = Config.TELEPORTER_HEALTH,
		color  = BrickColor.new("Bright violet"),
		size   = Vector3.new(2.5, 3.5, 2.5),
		reward = Config.COIN_TELEPORTER,
	},
	Splitter = {
		speed  = Config.SPLITTER_SPEED,
		health = Config.SPLITTER_HEALTH,
		color  = BrickColor.new("Hot pink"),
		size   = Vector3.new(3.2, 4.2, 3.2),  -- slightly bigger than Troll, reads as "parent"
		reward = Config.COIN_SPLITTER,
	},
	-- Spawned only as children of a banned Splitter (not picked by RoundManager).
	-- Size and speed are derived per-spawn from the parent — definition values are fallbacks.
	SplitterChild = {
		speed  = Config.SPLITTER_SPEED,
		health = Config.SPLITTER_HEALTH,
		color  = BrickColor.new("Carnation pink"),
		size   = Vector3.new(2, 2.6, 2),
		reward = Config.COIN_SPLITTER_CHILD,
	},
}

-- spawnPos / sizeOverride / speedOverride are used by the Splitter ban hook to
-- spawn children at the parent's death position with derived stats. RoundManager
-- only ever calls with (typeName, speedMultiplier).
local function spawnEnemy(typeName, speedMultiplier, spawnPos, sizeOverride, speedOverride)
	if GameManager.IsGameOver() then return end

	local def = ENEMY_TYPES[typeName] or ENEMY_TYPES.Troll

	local enemy = Instance.new("Part")
	enemy.Name       = typeName
	enemy.Size       = sizeOverride or def.size
	enemy.BrickColor = def.color
	enemy.Anchored   = false
	enemy.CanCollide = true
	enemy.CastShadow = false
	enemy:SetAttribute("IsEnemy", true)
	enemy:SetAttribute("Reward",  def.reward)

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Velocity = Vector3.new(0, 0, 0)
	velocity.Parent   = enemy

	if spawnPos then
		enemy.Position = spawnPos
	else
		enemy.Position = enemyStart.Position + Vector3.new(
			math.random(-4, 4), 2, math.random(-4, 4)
		)
	end
	enemy.Parent = workspace

	local speed = speedOverride or (def.speed * (speedMultiplier or 1))
	local nextTeleport = nil
	if typeName == "Teleporter" then
		nextTeleport = tick() + Config.TELEPORTER_INTERVAL
	end
	table.insert(activeEnemies, {
		part           = enemy,
		velocity       = velocity,
		speed          = speed,
		damageCooldown = 0,
		typeName       = typeName,
		nextTeleport   = nextTeleport,
	})

	print("[EnemySpawner] Spawned", typeName, "| speed:", speed, "| active:", #activeEnemies)
end

local spawnFunc = Instance.new("BindableFunction")
spawnFunc.Name     = "Spawn"
spawnFunc.Parent   = script
spawnFunc.OnInvoke = function(typeName, speedMultiplier)
	spawnEnemy(typeName, speedMultiplier)
end

local countFunc = Instance.new("BindableFunction")
countFunc.Name     = "GetActiveCount"
countFunc.Parent   = script
countFunc.OnInvoke = function()
	return #activeEnemies
end

RunService.Heartbeat:Connect(function(dt)
	if GameManager.IsGameOver() then return end

	local zonePos = serverZone.Position
	local now     = tick()

	for i = #activeEnemies, 1, -1 do
		local data  = activeEnemies[i]
		local enemy = data.part

		if not enemy or not enemy.Parent then
			table.remove(activeEnemies, i)
			continue
		end

		-- Kick takes top priority: while KickedUntil > now, BodyVelocity is driven by
		-- KickVelocity and every other per-frame system (mute/freeze/seek/damage) is skipped.
		-- When the kick window expires, attributes are cleared and normal movement resumes.
		local kickedUntil = enemy:GetAttribute("KickedUntil")
		if kickedUntil then
			if now < kickedUntil then
				local kv = enemy:GetAttribute("KickVelocity")
				if kv then
					data.velocity.Velocity = kv
				end
				continue
			else
				enemy:SetAttribute("KickedUntil", nil)
				enemy:SetAttribute("KickVelocity", nil)
			end
		end

		-- Status effects: Timeout (freeze) overrides Mute (slow). Both timers can stack;
		-- when the stronger one expires, color drops back to the weaker active effect,
		-- and finally to OriginalColor once nothing is active.
		local frozenUntil = enemy:GetAttribute("FrozenUntil")
		local mutedUntil  = enemy:GetAttribute("MutedUntil")

		if frozenUntil and now >= frozenUntil then
			enemy:SetAttribute("FrozenUntil", nil)
			frozenUntil = nil
			if mutedUntil and now < mutedUntil then
				enemy.Color = MUTE_COLOR
			else
				local origColor = enemy:GetAttribute("OriginalColor")
				if origColor then
					enemy.Color = origColor
					enemy:SetAttribute("OriginalColor", nil)
				end
			end
		end

		if mutedUntil and now >= mutedUntil then
			enemy:SetAttribute("MutedUntil", nil)
			mutedUntil = nil
			if not enemy:GetAttribute("FrozenUntil") then
				local origColor = enemy:GetAttribute("OriginalColor")
				if origColor then
					enemy.Color = origColor
					enemy:SetAttribute("OriginalColor", nil)
				end
			end
		end

		local effectiveSpeed = data.speed
		if frozenUntil then
			effectiveSpeed = 0
		elseif mutedUntil then
			effectiveSpeed = data.speed * Config.MUTE_SLOW_FACTOR
		end

		-- Teleporters warp toward the zone every TELEPORTER_INTERVAL. Frozen blocks
		-- the warp (Timeout fully pauses the enemy); Mute does NOT — a muted user can
		-- still ghost-ping. So Mute is intentionally weaker against this enemy type.
		if data.typeName == "Teleporter" and data.nextTeleport and now >= data.nextTeleport then
			if not frozenUntil then
				local toZone = zonePos - enemy.Position
				if toZone.Magnitude > 0 then
					local jump   = toZone.Unit * Config.TELEPORTER_DISTANCE
					local oldPos = enemy.Position
					local newPos = oldPos + Vector3.new(jump.X, 0, jump.Z)
					enemy.Position = newPos
					Effects.TeleportEffect(oldPos, newPos)
				end
				data.nextTeleport = now + Config.TELEPORTER_INTERVAL
			else
				data.nextTeleport = now + 0.5  -- check again shortly after freeze ends
			end
		end

		local diff     = zonePos - enemy.Position
		local distance = diff.Magnitude

		if distance < 5 then
			data.velocity.Velocity = Vector3.new(0, 0, 0)

			-- Frozen enemies stall at the zone instead of ticking damage —
			-- Timeout should fully pause them, not just stop their walk.
			if not frozenUntil then
				data.damageCooldown -= dt
				if data.damageCooldown <= 0 then
					data.damageCooldown = Config.ENEMY_DAMAGE_INTERVAL
					GameManager.TakeDamage(Config.SERVER_DAMAGE)
					enemy:Destroy()
					table.remove(activeEnemies, i)
				end
			end
		else
			data.velocity.Velocity = diff.Unit * effectiveSpeed
		end
	end
end)

banEnemy.OnServerEvent:Connect(function(player, enemyPart)
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

	if (enemyPart.Position - root.Position).Magnitude > Config.BAN_RANGE * 1.5 then
		print("[EnemySpawner] Ban rejected — too far:", player.Name)
		return
	end

	-- Server-authoritative cooldown (respects per-player upgrade level)
	local now      = tick()
	local last     = lastBanTime[player] or 0
	local cooldown = player:GetAttribute("BanCooldown") or Config.BAN_COOLDOWN
	if now - last < cooldown then
		return
	end
	lastBanTime[player] = now

	local reward  = enemyPart:GetAttribute("Reward") or Config.COIN_TROLL
	local banPos  = enemyPart.Position
	CurrencyManager.AddCoins(player, reward)

	-- Splitter hook: before the parent is flashed/destroyed, spawn its children
	-- at the ban position with sizes/speeds derived from the parent. Children are
	-- SplitterChild type, which RoundManager never rolls — they never recurse.
	if enemyPart.Name == "Splitter" then
		local parentData
		for _, d in ipairs(activeEnemies) do
			if d.part == enemyPart then
				parentData = d
				break
			end
		end
		local parentSpeed = parentData and parentData.speed or Config.SPLITTER_SPEED
		local childSpeed  = parentSpeed * Config.SPLITTER_CHILD_SPEED_RATIO
		local childSize   = enemyPart.Size * Config.SPLITTER_CHILD_SIZE_RATIO
		for j = 1, Config.SPLITTER_CHILD_COUNT do
			local angle  = (j - 1) * (2 * math.pi / Config.SPLITTER_CHILD_COUNT)
			local offset = Vector3.new(
				math.cos(angle) * Config.SPLITTER_CHILD_OFFSET,
				0,
				math.sin(angle) * Config.SPLITTER_CHILD_OFFSET
			)
			spawnEnemy("SplitterChild", nil, banPos + offset, childSize, childSpeed)
		end
		Effects.SplitEffect(banPos)
	end

	print(string.format("[EnemySpawner] %s banned %s (+%d coins)", player.Name, enemyPart.Name, reward))
	Effects.HitFlash(enemyPart)
	Effects.BanEffect(banPos, reward)
end)

Players.PlayerRemoving:Connect(function(player)
	lastBanTime[player] = nil
end)
