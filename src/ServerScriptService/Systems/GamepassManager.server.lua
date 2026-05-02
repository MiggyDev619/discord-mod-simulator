-- ServerScriptService/Systems/GamepassManager (Script)
-- Checks gamepass ownership on join via MarketplaceService and listens for
-- mid-session purchases. Sets <Pass>Owned attributes on the player; downstream
-- systems (CurrencyManager.AddCoins, CurrencyManager.effectiveCooldownForLevel,
-- the Starter Pack grant below) read those attributes for their effects.
--
-- Ownership of DoubleCoins / FasterCooldowns is queried fresh per join (Roblox
-- is the source of truth). Only StarterPackClaimed is persisted, so the one-
-- time grant doesn't repeat across sessions.

local MarketplaceService  = game:GetService("MarketplaceService")
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local CurrencyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("CurrencyManager"))

local function findPass(key)
	for _, gp in ipairs(Config.GAMEPASSES) do
		if gp.key == key then return gp end
	end
	return nil
end

local function ownsPass(player, passId)
	if passId == 0 then return false end  -- placeholder id, can't query
	local ok, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if not ok then
		warn("[GamepassManager] UserOwnsGamePassAsync failed for", player.Name, passId, "—", owned)
		return false
	end
	return owned
end

-- One-time grant for the Starter Pack: unlock all 3 tools + grant coins.
-- Triggered when StarterPackOwned flips true AND StarterPackClaimed is false.
local function grantStarterPack(player)
	if player:GetAttribute("StarterPackClaimed") then return end

	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		player:SetAttribute(ul.key .. "Unlocked", true)
	end
	CurrencyManager.AddCoins(player, Config.STARTER_PACK_COIN_GRANT)
	player:SetAttribute("StarterPackClaimed", true)

	print("[GamepassManager]", player.Name, "claimed Starter Pack (+", Config.STARTER_PACK_COIN_GRANT, "coins, all tools)")
end

local function applyOwnership(player, gp, owned)
	player:SetAttribute(gp.effectAttr, owned)

	-- Per-pass side effects on flip.
	if gp.key == "FasterCooldowns" then
		-- Recompute all 4 cooldown attrs so the new multiplier (or its absence) takes effect.
		CurrencyManager.RecomputeAllCooldowns(player)
	elseif gp.key == "StarterPack" and owned then
		grantStarterPack(player)
	end
end

local function checkAllPasses(player)
	for _, gp in ipairs(Config.GAMEPASSES) do
		local owned = ownsPass(player, gp.id)
		applyOwnership(player, gp, owned)
		if owned then
			print("[GamepassManager]", player.Name, "owns", gp.key)
		end
	end
end

Players.PlayerAdded:Connect(checkAllPasses)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(checkAllPasses, p)
end

-- Mid-session purchases: Roblox fires this when any prompt finishes (success or
-- cancel). We re-apply the ownership so the effect activates without waiting
-- for a rejoin.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then return end
	for _, gp in ipairs(Config.GAMEPASSES) do
		if gp.id == passId then
			applyOwnership(player, gp, true)
			print("[GamepassManager]", player.Name, "purchased", gp.key, "mid-session")
			break
		end
	end
end)
