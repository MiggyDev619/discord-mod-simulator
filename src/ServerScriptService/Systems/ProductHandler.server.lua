-- ServerScriptService/Systems/ProductHandler (Script)
-- Owns MarketplaceService.ProcessReceipt — Roblox calls this when a player
-- buys a developer product. Each product key in Config.DEV_PRODUCTS gets a
-- handler that runs the grant logic; we return PurchaseGranted on success
-- so Roblox commits the R$ charge, NotProcessedYet on failure so it retries.
--
-- Receipts are idempotent at Roblox's layer: ProcessReceipt may be called more
-- than once for the same purchase if our previous return was NotProcessedYet,
-- but Roblox dedupes the R$ side. We don't need our own dedup table.

local MarketplaceService  = game:GetService("MarketplaceService")
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local Systems         = ServerScriptService:WaitForChild("Systems")
local CurrencyManager = require(Systems:WaitForChild("CurrencyManager"))
local GameManager     = require(Systems:WaitForChild("GameManager"))

-- Build a lookup from product id → product config for O(1) dispatch.
local productById = {}
for _, dp in ipairs(Config.DEV_PRODUCTS) do
	if dp.id ~= 0 then  -- skip placeholder ids
		productById[dp.id] = dp
	end
end

-- Per-product grant handlers. Return true on success.
local handlers = {
	InstantRevive = function(player, _dp)
		-- Restore the run mid-fight without clearing enemies. If the run is
		-- already over, this also resets game-over state — same effect as Retry
		-- but the Retry button on the GameOverPanel is the more discoverable path.
		if GameManager.IsGameOver() then
			GameManager.Reset()
		else
			GameManager.Heal(Config.SERVER_MAX_HEALTH)  -- fully refill
		end
		return true
	end,

	CoinPackSmall = function(player, dp)
		CurrencyManager.AddCoins(player, dp.coinAmount)
		return true
	end,

	CoinPackLarge = function(player, dp)
		CurrencyManager.AddCoins(player, dp.coinAmount)
		return true
	end,

	XpBoost = function(player, dp)
		-- Replace any existing boost (don't stack durations — keeps it simple).
		player:SetAttribute("XpBoostUntil", tick() + dp.durationSec)
		return true
	end,
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before we processed; Roblox will retry on their next join.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local dp = productById[receiptInfo.ProductId]
	if not dp then
		warn("[ProductHandler] Unknown product id:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = handlers[dp.key]
	if not handler then
		warn("[ProductHandler] No handler for product key:", dp.key)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, success = pcall(handler, player, dp)
	if ok and success then
		print(string.format("[ProductHandler] Granted %s to %s", dp.key, player.Name))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn(string.format("[ProductHandler] Grant failed for %s / %s: %s", player.Name, dp.key, tostring(success)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end
