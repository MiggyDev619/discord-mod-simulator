-- ServerScriptService/Rounds/RoundManager
-- Drives the wave sequence. Tells EnemySpawner what to spawn and when.
-- Broadcasts wave/break state to clients and declares victory after the final wave.

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local Shared           = ReplicatedStorage:WaitForChild("Shared")
local Config           = require(Shared:WaitForChild("Config"))
local Systems          = ServerScriptService:WaitForChild("Systems")
local GameManager      = require(Systems:WaitForChild("GameManager"))
local CurrencyManager  = require(Systems:WaitForChild("CurrencyManager"))

local remotes     = Shared:WaitForChild("Remotes")
local waveStarted = remotes:WaitForChild("WaveStarted")
local waveBreak   = remotes:WaitForChild("WaveBreak")
local retryRun    = remotes:WaitForChild("RetryRun")

local spawnerScript      = ServerScriptService:WaitForChild("Enemies"):WaitForChild("EnemySpawner")
local spawnFunc          = spawnerScript:WaitForChild("Spawn")
local countFunc          = spawnerScript:WaitForChild("GetActiveCount")
local setWaveRemaining   = spawnerScript:WaitForChild("SetWaveRemaining")
local clearAll           = spawnerScript:WaitForChild("ClearAll")

-- Table-driven type picker. Iterates in order; first roll under chance wins.
-- Higher-tier enemies listed first so they get first shot at the slot
-- (matches the "highest-tier-eligible enemy gets first claim" rule from
-- 2026-04-25 Day 9 devlog). Defaults to Troll if nothing rolls.
local ENEMY_PICK_TABLE = {
	{ type = "Splitter",   minWave = 4, chance = Config.SPLITTER_CHANCE },
	{ type = "DiscordMod", minWave = 4, chance = Config.DISCORD_MOD_CHANCE },
	{ type = "Furry",      minWave = 3, chance = Config.FURRY_CHANCE },
	{ type = "Teleporter", minWave = 3, chance = Config.TELEPORTER_CHANCE },
	{ type = "Karen",      minWave = 2, chance = Config.KAREN_CHANCE },
	{ type = "Spammer",    minWave = 2, chance = Config.SPAMMER_CHANCE },
}

local function pickEnemyType(wave)
	for _, e in ipairs(ENEMY_PICK_TABLE) do
		if wave >= e.minWave and math.random() < e.chance then
			return e.type
		end
	end
	return "Troll"
end

-- Roll a modifier (or nil) for a wave. Modifiers are gated by their `minWave`;
-- a wave can only get one modifier (chosen uniformly from those eligible).
local function rollModifier(wave)
	if math.random() >= Config.MODIFIER_CHANCE then return nil end
	local eligible = {}
	for _, m in ipairs(Config.WAVE_MODIFIERS) do
		if wave >= m.minWave then
			table.insert(eligible, m)
		end
	end
	if #eligible == 0 then return nil end
	return eligible[math.random(1, #eligible)]
end

local function runWave(wave)
	local modifier = rollModifier(wave)

	local baseCount  = Config.WAVE_ENEMY_BASE + (wave - 1) * Config.WAVE_ENEMY_SCALE
	local enemyCount = math.ceil(baseCount * (modifier and modifier.enemyCountMult or 1))
	local speedMult  = (Config.WAVE_SPEED_SCALE ^ (wave - 1)) * (modifier and modifier.speedMult or 1)

	-- forceType overrides the normal type picker for the whole wave.
	local pickForThisWave = function() return pickEnemyType(wave) end
	if modifier and modifier.forceType then
		pickForThisWave = function() return modifier.forceType end
	end

	if modifier then
		print(string.format("[RoundManager] Wave %d/%d | %d enemies | %.2fx speed | MODIFIER: %s",
			wave, Config.WAVES_TO_WIN, enemyCount, speedMult, modifier.label))
	else
		print(string.format("[RoundManager] Wave %d/%d | %d enemies | %.2fx speed",
			wave, Config.WAVES_TO_WIN, enemyCount, speedMult))
	end
	setWaveRemaining:Invoke(enemyCount)
	waveStarted:FireAllClients(wave, Config.WAVES_TO_WIN, modifier and modifier.label or nil)

	for i = 1, enemyCount do
		if GameManager.IsGameOver() then return end
		spawnFunc:Invoke(pickForThisWave(), speedMult)
		task.wait(Config.SPAWN_INTERVAL)
	end

	while not GameManager.IsGameOver() and countFunc:Invoke() > 0 do
		task.wait(1)
	end

	if not GameManager.IsGameOver() then
		print("[RoundManager] Wave", wave, "cleared!")
	end
end

-- Tick a countdown via the WaveBreak RemoteEvent. Default duration is the
-- between-wave break; the start-of-game countdown passes a shorter value.
-- Client renders each tick as "Wave N / total in Xs" in the wave label.
local function runBreak(nextWave, durationSec)
	durationSec = durationSec or Config.WAVE_BREAK_DURATION
	for secondsLeft = durationSec, 1, -1 do
		if GameManager.IsGameOver() then return end
		waveBreak:FireAllClients(nextWave, Config.WAVES_TO_WIN, secondsLeft)
		task.wait(1)
	end
end

-- Per-run wave loop. Re-invokable on retry; the previous loop has already
-- exited by then because IsGameOver was true (it's how the loop ends), and
-- only after the player clicks Retry does GameManager.Reset clear the flag.
local function startRun()
	task.spawn(function()
		-- Tiny silent buffer so the first countdown fire isn't dropped on cold
		-- client boot, then a visible START_COUNTDOWN_SECONDS-second countdown
		-- before wave 1 (gives players time to check the shop / get oriented).
		task.wait(Config.PRE_WAVE_DELAY)
		print(string.format("[RoundManager] Start countdown — wave 1 in %ds", Config.START_COUNTDOWN_SECONDS))
		runBreak(1, Config.START_COUNTDOWN_SECONDS)

		local wave = 0
		while not GameManager.IsGameOver() and wave < Config.WAVES_TO_WIN do
			wave += 1

			if wave > 1 then
				print(string.format("[RoundManager] Break — wave %d in %ds", wave, Config.WAVE_BREAK_DURATION))
				runBreak(wave)
			end

			if GameManager.IsGameOver() then break end
			runWave(wave)
		end

		if not GameManager.IsGameOver() then
			GameManager.Win()
		end

		print("[RoundManager] Stopped at wave", wave)
	end)
end

task.spawn(function()
	-- Wait for at least one player, then give their ClientMain time to mount its
	-- OnClientEvent handlers. Without this, wave 1's WaveStarted/EnemyCountChanged
	-- fire before the client has connected — events are dropped, the label keeps
	-- the model.json default ("Wave 1 / 5") with no "N left" suffix until wave 2.
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end
	startRun()
end)

retryRun.OnServerEvent:Connect(function(player)
	if not GameManager.IsGameOver() then
		print("[RoundManager] Retry rejected from", player.Name, "— run still in progress")
		return
	end

	print("[RoundManager] Retry from", player.Name, "— resetting state and restarting run")
	clearAll:Invoke()
	GameManager.Reset()
	CurrencyManager.ResetRun(player)
	startRun()
end)
