-- ServerScriptService/Systems/GameManager
-- Owns server health and end-of-run state (loss or win).
-- All damage goes through TakeDamage(). All victory transitions go through Win().
-- Fires RemoteEvents to update clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Config  = require(Shared:WaitForChild("Config"))
local remotes = Shared:WaitForChild("Remotes")

local healthChanged = remotes:WaitForChild("HealthChanged")
local gameOver      = remotes:WaitForChild("GameOver")
local gameWon       = remotes:WaitForChild("GameWon")

local serverHealth = Config.SERVER_MAX_HEALTH
local isGameOver   = false
local isGameWon    = false

local GameManager = {}

function GameManager.TakeDamage(amount)
	if isGameOver then return end

	serverHealth = math.max(0, serverHealth - amount)
	print("[GameManager] Server health:", serverHealth)

	healthChanged:FireAllClients(serverHealth, Config.SERVER_MAX_HEALTH)

	if serverHealth <= 0 then
		isGameOver = true
		print("[GameManager] GAME OVER")
		gameOver:FireAllClients()
	end
end

function GameManager.Win()
	if isGameOver then return end
	isGameOver = true
	isGameWon  = true
	print("[GameManager] VICTORY")
	gameWon:FireAllClients()
end

function GameManager.GetHealth()
	return serverHealth
end

function GameManager.IsGameOver()
	return isGameOver
end

function GameManager.IsGameWon()
	return isGameWon
end

return GameManager
