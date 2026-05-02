-- ServerScriptService/Systems/CurrencyManager
-- Tracks per-player coins, per-tool cooldown upgrade levels, and per-tool unlock
-- state via Player attributes. Attributes replicate to clients automatically.
-- Generic over Config.COOLDOWN_UPGRADES + Config.TOOL_UNLOCKS — adding a new
-- upgrade or tool is one Config entry, no code change here.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local remotes         = Shared:WaitForChild("Remotes")
local purchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local CurrencyManager = {}

local function findCooldownUpgrade(key)
	for _, upg in ipairs(Config.COOLDOWN_UPGRADES) do
		if upg.key == key then return upg end
	end
	return nil
end

local function findToolUnlock(key)
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		if ul.key == key then return ul end
	end
	return nil
end

local function unlockedAttr(toolKey)
	return toolKey .. "Unlocked"
end

local function cooldownForLevel(upg, level)
	return math.max(upg.minValue, upg.base - (upg.reduction * level))
end

local function upgradeCost(upg, level)
	return upg.baseCost * (level + 1)
end

local function initPlayer(player)
	player:SetAttribute("Coins", 0)
	for _, upg in ipairs(Config.COOLDOWN_UPGRADES) do
		player:SetAttribute(upg.levelAttr, 0)
		player:SetAttribute(upg.baseAttr,  upg.base)
	end
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		player:SetAttribute(unlockedAttr(ul.key), false)
	end
end

function CurrencyManager.AddCoins(player, amount)
	if not player or not player.Parent then return end
	local coins = (player:GetAttribute("Coins") or 0) + amount
	player:SetAttribute("Coins", coins)
end

-- Reward a player for destroying an enemy. Applies the combo multiplier when the
-- enemy was frozen (Timeout's FrozenUntil OR Mute Gun's MuteFrozenUntil active
-- at destroy time). Returns the amount actually awarded for callers that want
-- to show it in popups.
function CurrencyManager.RewardForKill(player, enemyPart)
	if not player or not enemyPart then return 0 end
	local base = enemyPart:GetAttribute("Reward") or 0
	if base <= 0 then return 0 end

	local now = tick()
	local frozenUntil     = enemyPart:GetAttribute("FrozenUntil")
	local muteFrozenUntil = enemyPart:GetAttribute("MuteFrozenUntil")
	local combo = (frozenUntil and now < frozenUntil) or (muteFrozenUntil and now < muteFrozenUntil)

	local total = combo and (base * Config.COMBO_MULTIPLIER) or base
	CurrencyManager.AddCoins(player, total)
	return total, combo == true
end

function CurrencyManager.TryPurchaseCooldown(player, upgradeKey)
	local upg = findCooldownUpgrade(upgradeKey)
	if not upg then return end

	local level = player:GetAttribute(upg.levelAttr) or 0
	if level >= upg.maxLevel then
		print("[CurrencyManager]", player.Name, "already maxed", upg.key)
		return
	end

	local cost  = upgradeCost(upg, level)
	local coins = player:GetAttribute("Coins") or 0
	if coins < cost then
		print("[CurrencyManager]", player.Name, "can't afford", upg.key, "(have", coins, "need", cost, ")")
		return
	end

	local newLevel = level + 1
	player:SetAttribute("Coins",       coins - cost)
	player:SetAttribute(upg.levelAttr, newLevel)
	player:SetAttribute(upg.baseAttr,  cooldownForLevel(upg, newLevel))

	print("[CurrencyManager]", player.Name, "upgraded", upg.key, "to level", newLevel, "→", cooldownForLevel(upg, newLevel), "s")
end

function CurrencyManager.TryUnlockTool(player, toolKey)
	local ul = findToolUnlock(toolKey)
	if not ul then return end

	if player:GetAttribute(unlockedAttr(toolKey)) then
		print("[CurrencyManager]", player.Name, "already owns", toolKey)
		return
	end

	local coins = player:GetAttribute("Coins") or 0
	if coins < ul.cost then
		print("[CurrencyManager]", player.Name, "can't afford", toolKey, "(have", coins, "need", ul.cost, ")")
		return
	end

	player:SetAttribute("Coins", coins - ul.cost)
	player:SetAttribute(unlockedAttr(toolKey), true)
	print("[CurrencyManager]", player.Name, "unlocked", toolKey)
end

function CurrencyManager.LoadFromSave(player, data)
	if not player or not player.Parent then return end
	player:SetAttribute("Coins", tonumber(data.coins) or 0)
	for _, upg in ipairs(Config.COOLDOWN_UPGRADES) do
		local level = math.clamp(tonumber(data[upg.levelAttr]) or 0, 0, upg.maxLevel)
		player:SetAttribute(upg.levelAttr, level)
		player:SetAttribute(upg.baseAttr,  cooldownForLevel(upg, level))
	end
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		local attr = unlockedAttr(ul.key)
		player:SetAttribute(attr, data[attr] == true)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	initPlayer(p)
end
Players.PlayerAdded:Connect(initPlayer)

-- One RemoteEvent dispatches both cooldown upgrades and tool unlocks. Client
-- sends the key; server tries cooldown first, falls back to unlock — keys are
-- distinct namespaces so there's no collision.
purchaseUpgrade.OnServerEvent:Connect(function(player, key)
	if findCooldownUpgrade(key) then
		CurrencyManager.TryPurchaseCooldown(player, key)
	elseif findToolUnlock(key) then
		CurrencyManager.TryUnlockTool(player, key)
	else
		warn("[CurrencyManager] Unknown purchase key from", player.Name, ":", key)
	end
end)

return CurrencyManager
