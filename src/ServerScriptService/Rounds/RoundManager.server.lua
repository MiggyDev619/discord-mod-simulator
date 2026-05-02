-- ServerScriptService/Rounds/RoundManager
-- Drives the wave sequence. Tells EnemySpawner what to spawn and when.
-- Broadcasts wave/break state to clients and declares victory after the final wave.

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local GameManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("GameManager"))

local remotes     = Shared:WaitForChild("Remotes")
local waveStarted = remotes:WaitForChild("WaveStarted")
local waveBreak   = remotes:WaitForChild("WaveBreak")

local spawnerScript      = ServerScriptService:WaitForChild("Enemies"):WaitForChild("EnemySpawner")
local spawnFunc          = spawnerScript:WaitForChild("Spawn")
local countFunc          = spawnerScript:WaitForChild("GetActiveCount")
local setWaveRemaining   = spawnerScript:WaitForChild("SetWaveRemaining")

local function pickEnemyType(wave)
	if wave >= 4 and math.random() < Config.SPLITTER_CHANCE then
		return "Splitter"
	end
	if wave >= 3 and math.random() < Config.TELEPORTER_CHANCE then
		return "Teleporter"
	end
	if wave >= 2 and math.random() < Config.SPAMMER_CHANCE then
		return "Spammer"
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

local function runBreak(nextWave)
	for secondsLeft = Config.WAVE_BREAK_DURATION, 1, -1 do
		if GameManager.IsGameOver() then return end
		waveBreak:FireAllClients(nextWave, Config.WAVES_TO_WIN, secondsLeft)
		task.wait(1)
	end
end

task.spawn(function()
	-- Wait for at least one player, then give their ClientMain time to mount its
	-- OnClientEvent handlers. Without this, wave 1's WaveStarted/EnemyCountChanged
	-- fire before the client has connected — events are dropped, the label keeps
	-- the model.json default ("Wave 1 / 5") with no "N left" suffix until wave 2.
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end
	task.wait(Config.PRE_WAVE_DELAY)

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
