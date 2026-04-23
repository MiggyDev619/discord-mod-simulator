-- ServerScriptService/Systems/CurrencyManager
-- Tracks per-player coins and upgrade levels via Player attributes.
-- Attributes replicate to clients automatically, so the UI can just listen to them.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local remotes         = Shared:WaitForChild("Remotes")
local purchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local CurrencyManager = {}

local function cooldownForLevel(level)
	local reduced = Config.BAN_COOLDOWN - (Config.UPGRADE_COOLDOWN_REDUCTION * level)
	return math.max(Config.UPGRADE_COOLDOWN_MIN, reduced)
end

local function cooldownUpgradeCost(level)
	return Config.UPGRADE_COOLDOWN_COST * (level + 1)
end

local function initPlayer(player)
	player:SetAttribute("Coins",         0)
	player:SetAttribute("CooldownLevel", 0)
	player:SetAttribute("BanCooldown",   Config.BAN_COOLDOWN)
end

function CurrencyManager.AddCoins(player, amount)
	if not player or not player.Parent then return end
	local coins = (player:GetAttribute("Coins") or 0) + amount
	player:SetAttribute("Coins", coins)
end

function CurrencyManager.TryPurchaseCooldown(player)
	local level = player:GetAttribute("CooldownLevel") or 0
	if level >= Config.UPGRADE_COOLDOWN_MAX_LEVEL then
		print("[CurrencyManager]", player.Name, "already maxed cooldown")
		return
	end

	local cost  = cooldownUpgradeCost(level)
	local coins = player:GetAttribute("Coins") or 0
	if coins < cost then
		print("[CurrencyManager]", player.Name, "can't afford cooldown upgrade (have", coins, "need", cost, ")")
		return
	end

	local newLevel = level + 1
	player:SetAttribute("Coins",         coins - cost)
	player:SetAttribute("CooldownLevel", newLevel)
	player:SetAttribute("BanCooldown",   cooldownForLevel(newLevel))

	print("[CurrencyManager]", player.Name, "upgraded cooldown to level", newLevel, "→", cooldownForLevel(newLevel), "s")
end

for _, p in ipairs(Players:GetPlayers()) do
	initPlayer(p)
end
Players.PlayerAdded:Connect(initPlayer)

purchaseUpgrade.OnServerEvent:Connect(function(player, upgradeName)
	if upgradeName == "Cooldown" then
		CurrencyManager.TryPurchaseCooldown(player)
	end
end)

return CurrencyManager
