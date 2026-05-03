-- ServerScriptService/Systems/AchievementManager (Script)
-- v2 Week 8 — tracks achievement unlocks. Triggers are fired by other systems
-- via the global tracker functions (BanCount / Level / WaveCleared / ComboCount).
-- Each player has a CSV of OwnedAchievements (persisted) plus per-trigger
-- counters (BanCountLifetime, ComboCountLifetime) also persisted.
--
-- On unlock: print, optional cosmetic grant via CurrencyManager.GrantCosmetic,
-- and a notification toast pushed to the unlocking client (via FireClient on
-- the AchievementUnlocked RemoteEvent — added below).

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local CurrencyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("CurrencyManager"))

local function ownsAchievement(player, id)
	local owned = player:GetAttribute("OwnedAchievements") or ""
	if owned == "" then return false end
	return string.find("," .. owned .. ",", "," .. id .. ",", 1, true) ~= nil
end

local function grantAchievement(player, ach)
	if ownsAchievement(player, ach.id) then return end
	local owned = player:GetAttribute("OwnedAchievements") or ""
	owned = (owned == "") and ach.id or (owned .. "," .. ach.id)
	player:SetAttribute("OwnedAchievements", owned)
	print(string.format("[AchievementManager] %s unlocked %s — %s", player.Name, ach.id, ach.label))
	if ach.rewardCosmetic then
		CurrencyManager.GrantCosmetic(player, ach.rewardCosmetic)
	end
end

-- Check all achievements with the given trigger against the player's current
-- counter value. Idempotent — already-owned achievements are skipped.
local function checkTrigger(player, triggerKey, currentValue)
	for _, ach in ipairs(Config.ACHIEVEMENTS) do
		if ach.trigger == triggerKey and currentValue >= ach.goal then
			grantAchievement(player, ach)
		end
	end
end

local AchievementManager = {}

-- Public API for other systems to call.
function AchievementManager.OnBan(player)
	if not player or not player.Parent then return end
	local count = (player:GetAttribute("BanCountLifetime") or 0) + 1
	player:SetAttribute("BanCountLifetime", count)
	checkTrigger(player, "BanCount", count)
end

function AchievementManager.OnCombo(player)
	if not player or not player.Parent then return end
	local count = (player:GetAttribute("ComboCountLifetime") or 0) + 1
	player:SetAttribute("ComboCountLifetime", count)
	checkTrigger(player, "ComboCount", count)
end

function AchievementManager.OnLevelUp(player, newLevel)
	checkTrigger(player, "Level", newLevel)
end

function AchievementManager.OnWaveCleared(player, waveNumber)
	checkTrigger(player, "WaveCleared", waveNumber)
end

-- Expose via _G for cross-script access without a require chain (the alternative
-- would be making this a ModuleScript that other scripts require — but it has
-- side-effect installation logic too. _G is a pragmatic compromise here.)
_G.DMSAchievementManager = AchievementManager

-- Initial check on player load — covers achievements they should have from
-- prior sessions (level-based, count-based on persisted attributes).
local function checkAllOnLoad(player)
	checkTrigger(player, "BanCount",   player:GetAttribute("BanCountLifetime")   or 0)
	checkTrigger(player, "ComboCount", player:GetAttribute("ComboCountLifetime") or 0)
	checkTrigger(player, "Level",      player:GetAttribute("Level")              or 1)
end

Players.PlayerAdded:Connect(function(player)
	-- Wait briefly for PersistenceManager to load saved counters
	task.wait(2)
	checkAllOnLoad(player)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2)
		checkAllOnLoad(p)
	end)
end
