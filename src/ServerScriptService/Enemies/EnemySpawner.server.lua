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

local remotes            = Shared:WaitForChild("Remotes")
local banEnemy           = remotes:WaitForChild("BanEnemy")
local enemyCountChanged  = remotes:WaitForChild("EnemyCountChanged")

local map        = workspace:WaitForChild("Map")
local enemyStart = map:WaitForChild("EnemyStart")
local serverZone = map:WaitForChild("ServerZone")

local MUTE_FREEZE_COLOR = Color3.fromRGB(70, 150, 255)  -- Mute Gun first-hit freeze (same blue as old mute)

local activeEnemies      = {}
local lastBroadcastCount = -1
local lastBanTime        = {}  -- [player] = tick of last accepted ban

-- Wave-remaining counter — what the player UI needs. Tracks the *total* number
-- of enemies still to be dealt with this wave (pending spawns + alive enemies +
-- pending Splitter children). Reset on wave start, bumped when a Splitter
-- spawns (since each will produce children when banned), decremented on any
-- enemy death. Differs from #activeEnemies, which flickers between spawn ticks.
local waveRemaining = 0

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

	-- Meme enemies (Day 25). Each has a speechPool — Effects.SpeechBubble fires
	-- with a random phrase on spawn for chat-bubble flavor.
	Karen = {
		speed      = Config.KAREN_SPEED,
		health     = Config.KAREN_HEALTH,
		color      = BrickColor.new("Cool yellow"),  -- Karen-blonde tan
		size       = Vector3.new(3.5, 4.5, 3.5),    -- biggest base enemy
		reward     = Config.COIN_KAREN,
		speechPool = {
			"I WANT TO SPEAK TO THE OWNER",
			"THIS IS RIDICULOUS",
			"BRINGING THIS UP WITH MY LAWYER",
			"DO YOU KNOW WHO I AM",
			"I'm calling corporate",
		},
	},
	Furry = {
		speed      = Config.FURRY_SPEED,
		health     = Config.FURRY_HEALTH,
		color      = BrickColor.new("Hot pink"),
		size       = Vector3.new(1.8, 2.8, 1.8),
		reward     = Config.COIN_FURRY,
		speechPool = {
			"owo what's this",
			"*notices ur server*",
			"uwu",
			"rawr xD",
			"*nuzzles ur firewall*",
		},
	},
	DiscordMod = {
		speed      = Config.DISCORD_MOD_SPEED,
		health     = Config.DISCORD_MOD_HEALTH,
		color      = BrickColor.new("Bright blue"),  -- closest to Discord blurple in BrickColor
		size       = Vector3.new(2.5, 3.5, 2.5),
		reward     = Config.COIN_DISCORD_MOD,
		speechPool = {
			"stop arguing in #general",
			"READ THE RULES",
			"this is your final warning",
			"/timeout @everyone",
			"did you read the pinned message",
		},
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

	-- Splitter parents promise N future children — those count toward wave-remaining
	-- as soon as the parent appears, so the UI reflects what the player has to deal
	-- with. SplitterChild spawns don't bump the count: they were pre-counted here.
	if typeName == "Splitter" then
		waveRemaining = waveRemaining + Config.SPLITTER_CHILD_COUNT
	end

	-- Meme enemies pop a speech bubble on spawn — pure flavor.
	if def.speechPool then
		local phrase = def.speechPool[math.random(1, #def.speechPool)]
		Effects.SpeechBubble(enemy, phrase)
	end

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

-- RoundManager calls this at wave start with the wave's scheduled enemy count.
-- Resetting unconditionally protects against any drift left by prior waves.
-- Broadcasting here (in addition to the heartbeat dedup) closes the 1-frame
-- gap between WaveStarted firing and the heartbeat noticing the new value —
-- without it, wave 1's first render lands with enemyCount=0 on the client.
local setWaveRemainingFunc = Instance.new("BindableFunction")
setWaveRemainingFunc.Name     = "SetWaveRemaining"
setWaveRemainingFunc.Parent   = script
setWaveRemainingFunc.OnInvoke = function(n)
	waveRemaining = n
	if waveRemaining ~= lastBroadcastCount then
		lastBroadcastCount = waveRemaining
		enemyCountChanged:FireAllClients(waveRemaining)
	end
end

-- RoundManager calls this on retry to wipe the board. Destroys all live enemies,
-- resets per-player ban cooldowns (so retry isn't gated by mid-fight cooldown
-- state), and broadcasts a 0-count so the HUD label clears.
local clearAllFunc = Instance.new("BindableFunction")
clearAllFunc.Name     = "ClearAll"
clearAllFunc.Parent   = script
clearAllFunc.OnInvoke = function()
	for _, data in ipairs(activeEnemies) do
		if data.part and data.part.Parent then
			data.part:Destroy()
		end
	end
	activeEnemies      = {}
	waveRemaining      = 0
	lastBroadcastCount = -1
	lastBanTime        = {}
	enemyCountChanged:FireAllClients(0)
	print("[EnemySpawner] ClearAll — wiped board for retry")
end

-- Shared destroy path. Called by the BanEnemy handler below AND by MuteHandler
-- when a Mute Gun second-hit destroys an already-frozen target. Keeps Splitter
-- spawning + combo reward + effects in one place — no duplicate logic between
-- destructive tools.
local destroyEnemyFunc = Instance.new("BindableFunction")
destroyEnemyFunc.Name     = "DestroyEnemy"
destroyEnemyFunc.Parent   = script
destroyEnemyFunc.OnInvoke = function(player, enemyPart)
	if not enemyPart or not enemyPart.Parent or not enemyPart:GetAttribute("IsEnemy") then
		return 0, false
	end

	local banPos        = enemyPart.Position
	local reward, combo = CurrencyManager.RewardForKill(player, enemyPart)

	-- Splitter hook: spawn children at the death position before flashing/destroying.
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

	Effects.HitFlash(enemyPart)
	Effects.BanEffect(banPos, reward)
	return reward, combo
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
			waveRemaining = math.max(0, waveRemaining - 1)
			continue
		end

		-- Kick takes top priority: while KickedUntil > now, BodyVelocity is driven by
		-- KickVelocity and every other per-frame system (freeze/seek/damage) is skipped.
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

		-- Two freeze sources: Timeout Card sets FrozenUntil (yellow), Mute Gun first
		-- hit sets MuteFrozenUntil (blue). Both drop effective speed to 0. Color is
		-- updated only on expiry transitions (handlers set color on apply). When one
		-- expires while the other is still active, color drops to the still-active
		-- effect's color, not OriginalColor.
		local frozenUntil     = enemy:GetAttribute("FrozenUntil")
		local muteFrozenUntil = enemy:GetAttribute("MuteFrozenUntil")

		if frozenUntil and now >= frozenUntil then
			enemy:SetAttribute("FrozenUntil", nil)
			frozenUntil = nil
			if muteFrozenUntil and now < muteFrozenUntil then
				enemy.Color = MUTE_FREEZE_COLOR
			else
				local origColor = enemy:GetAttribute("OriginalColor")
				if origColor then
					enemy.Color = origColor
					enemy:SetAttribute("OriginalColor", nil)
				end
			end
		end

		if muteFrozenUntil and now >= muteFrozenUntil then
			enemy:SetAttribute("MuteFrozenUntil", nil)
			muteFrozenUntil = nil
			if not (frozenUntil and now < frozenUntil) then
				local origColor = enemy:GetAttribute("OriginalColor")
				if origColor then
					enemy.Color = origColor
					enemy:SetAttribute("OriginalColor", nil)
				end
			end
		end

		local effectiveSpeed = data.speed
		if frozenUntil or muteFrozenUntil then
			effectiveSpeed = 0
		end

		-- Teleporters warp toward the zone every TELEPORTER_INTERVAL. Either freeze
		-- blocks the warp; without that, frozen Teleporters would still warp.
		if data.typeName == "Teleporter" and data.nextTeleport and now >= data.nextTeleport then
			if not frozenUntil and not muteFrozenUntil then
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
			-- either freeze should fully pause them, not just stop their walk.
			if not frozenUntil and not muteFrozenUntil then
				data.damageCooldown -= dt
				if data.damageCooldown <= 0 then
					data.damageCooldown = Config.ENEMY_DAMAGE_INTERVAL
					GameManager.TakeDamage(Config.SERVER_DAMAGE)
					enemy:Destroy()
					table.remove(activeEnemies, i)
					waveRemaining = math.max(0, waveRemaining - 1)
				end
			end
		else
			data.velocity.Velocity = diff.Unit * effectiveSpeed
		end
	end

	-- Broadcast wave-remaining once per frame when it changes. Cheaper than firing
	-- on every spawn/destroy, and clients only care about the latest value.
	if waveRemaining ~= lastBroadcastCount then
		lastBroadcastCount = waveRemaining
		enemyCountChanged:FireAllClients(waveRemaining)
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

	local reward, combo = destroyEnemyFunc:Invoke(player, enemyPart)
	print(string.format("[EnemySpawner] %s banned %s (+%d coins%s)",
		player.Name, enemyPart.Name, reward, combo and " — COMBO!" or ""))
end)

Players.PlayerRemoving:Connect(function(player)
	lastBanTime[player] = nil
end)
