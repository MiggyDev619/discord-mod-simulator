-- ServerScriptService/Systems/LeaderboardManager (Script)
-- v2 Week 4 — public leaderboard via OrderedDataStore. Top-10 by Coins +
-- Top-10 by Level. Updates on PlayerRemoving + BindToClose (final stats);
-- reads on demand via GetLeaderboard RemoteFunction.
--
-- Throttling: avoid live per-second writes to dodge OrderedDataStore rate
-- limits. Final-stats-on-leave is enough for an "all-time" leaderboard.
-- Future: live "currently playing" board would need a separate in-memory
-- structure server-side.
--
-- Mock-store fallback for unpublished Studio runs (no PlaceId) — same
-- pattern as PersistenceManager. Reads/writes a per-process table when
-- DataStore unavailable.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local remotes         = Shared:WaitForChild("Remotes")
local getLeaderboard  = remotes:WaitForChild("GetLeaderboard")

local STORE_PREFIX = "DMS_Leaderboard_v1" .. (RunService:IsStudio() and "_dev" or "")
local TOP_N        = 10

-- Mock fallback for local-only runs.
local function getOrderedStore(key)
	if RunService:IsStudio() and game.PlaceId == 0 then
		local mock = {}
		return {
			SetAsync = function(_, k, v) mock[k] = v end,
			GetSortedAsync = function(_, ascending, pageSize)
				-- Build a sorted array from mock data
				local entries = {}
				for k, v in pairs(mock) do
					table.insert(entries, { key = k, value = v })
				end
				table.sort(entries, function(a, b)
					if ascending then return a.value < b.value end
					return a.value > b.value
				end)
				-- Mimic the SortedAsync iterator interface
				return {
					GetCurrentPage = function() return entries end,
					IsFinished = function() return true end,
				}
			end,
		}
	end
	return DataStoreService:GetOrderedDataStore(STORE_PREFIX .. "_" .. key)
end

local coinsStore = getOrderedStore("Coins")
local levelStore = getOrderedStore("Level")

local function userKey(player)
	return tostring(player.UserId)
end

local function writeFinalStats(player)
	local coins = player:GetAttribute("Coins") or 0
	local level = player:GetAttribute("Level") or 1
	pcall(function() coinsStore:SetAsync(userKey(player), coins) end)
	pcall(function() levelStore:SetAsync(userKey(player), level) end)
end

Players.PlayerRemoving:Connect(writeFinalStats)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(writeFinalStats, p)
	end
	task.wait(1)
end)

-- Cheap username lookup cache so we don't pay GetNameFromUserIdAsync per row
-- on every read. Falls back to the user id if the lookup fails.
local nameCache = {}
local function nameFor(userId)
	if nameCache[userId] then return nameCache[userId] end
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	if ok and name then
		nameCache[userId] = name
		return name
	end
	return "User " .. tostring(userId)
end

local function fetchTop(store)
	local results = {}
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, TOP_N)
	end)
	if not ok or not page then return results end
	local data = page:GetCurrentPage()
	for _, entry in ipairs(data) do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(results, {
				name  = nameFor(userId),
				value = entry.value,
			})
		end
	end
	return results
end

-- RemoteFunction: client passes "Coins" or "Level"; server returns array of
-- { name, value } entries sorted descending. Returns at most TOP_N.
getLeaderboard.OnServerInvoke = function(_player, board)
	if board == "Coins" then
		return fetchTop(coinsStore)
	elseif board == "Level" then
		return fetchTop(levelStore)
	end
	return {}
end
