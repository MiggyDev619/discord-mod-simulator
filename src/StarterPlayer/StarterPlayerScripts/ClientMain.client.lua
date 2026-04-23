-- StarterPlayer/StarterPlayerScripts/ClientMain
-- Wires up MainUI: health, currency, wave status, and the upgrade button.
-- Reads currency/cooldown state from Player attributes (replicated by CurrencyManager).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local remotes         = Shared:WaitForChild("Remotes")
local healthChanged   = remotes:WaitForChild("HealthChanged")
local gameOver        = remotes:WaitForChild("GameOver")
local gameWon         = remotes:WaitForChild("GameWon")
local waveStarted     = remotes:WaitForChild("WaveStarted")
local waveBreak       = remotes:WaitForChild("WaveBreak")
local purchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local player        = Players.LocalPlayer
local playerGui     = player:WaitForChild("PlayerGui")
local mainUI        = playerGui:WaitForChild("MainUI")
local healthLabel   = mainUI:WaitForChild("HealthLabel")
local currencyLabel = mainUI:WaitForChild("CurrencyLabel")
local waveLabel     = mainUI:WaitForChild("WaveLabel")
local upgradeButton = mainUI:WaitForChild("UpgradeButton")

local runEnded = false  -- set true once either GameOver or GameWon fires

-- Health
healthChanged.OnClientEvent:Connect(function(current, max)
	if runEnded then return end
	healthLabel.Text = "Server Health: " .. current .. " / " .. max
end)

gameOver.OnClientEvent:Connect(function()
	runEnded = true
	healthLabel.Text = "SERVER DEAD"
	healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	waveLabel.Text = "Run ended"
	waveLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	print("[ClientMain] Game over received")
end)

gameWon.OnClientEvent:Connect(function()
	runEnded = true
	waveLabel.Text = "VICTORY"
	waveLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
	healthLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
	print("[ClientMain] Victory received")
end)

-- Wave + break banner
waveStarted.OnClientEvent:Connect(function(wave, total)
	if runEnded then return end
	waveLabel.Text = string.format("Wave %d / %d", wave, total)
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

waveBreak.OnClientEvent:Connect(function(nextWave, total, secondsLeft)
	if runEnded then return end
	waveLabel.Text = string.format("Wave %d / %d in %ds", nextWave, total, secondsLeft)
	waveLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
end)

-- Currency + upgrade button
local function updateCurrency()
	local coins = player:GetAttribute("Coins") or 0
	currencyLabel.Text = "Coins: " .. coins
end

local function updateUpgradeButton()
	local level = player:GetAttribute("CooldownLevel") or 0
	if level >= Config.UPGRADE_COOLDOWN_MAX_LEVEL then
		upgradeButton.Text        = "Ban Hammer: MAXED"
		upgradeButton.AutoButtonColor = false
	else
		local cost = Config.UPGRADE_COOLDOWN_COST * (level + 1)
		upgradeButton.Text = string.format("Faster Ban Hammer  Lv %d → %d  (%d coins)", level, level + 1, cost)
		upgradeButton.AutoButtonColor = true
	end
end

upgradeButton.MouseButton1Click:Connect(function()
	purchaseUpgrade:FireServer("Cooldown")
end)

player:GetAttributeChangedSignal("Coins"):Connect(updateCurrency)
player:GetAttributeChangedSignal("CooldownLevel"):Connect(updateUpgradeButton)

updateCurrency()
updateUpgradeButton()

print("[ClientMain] UI connected")
