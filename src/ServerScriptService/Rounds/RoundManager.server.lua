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

local function runWave(wave)
	local enemyCount = Config.WAVE_ENEMY_BASE + (wave - 1) * Config.WAVE_ENEMY_SCALE
	local speedMult  = Config.WAVE_SPEED_SCALE ^ (wave - 1)

	print(string.format("[RoundManager] Wave %d/%d | %d enemies | %.2fx speed",
		wave, Config.WAVES_TO_WIN, enemyCount, speedMult))
	setWaveRemaining:Invoke(enemyCount)
	waveStarted:FireAllClients(wave, Config.WAVES_TO_WIN)

	for i = 1, enemyCount do
		if GameManager.IsGameOver() then return end
		spawnFunc:Invoke(pickEnemyType(wave), speedMult)
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
