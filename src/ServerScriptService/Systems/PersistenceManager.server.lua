-- ServerScriptService/Systems/PersistenceManager
-- First persistence work in the project. Owns load/save of per-player coins
-- and cooldown level via DataStore. Side-effect installer (no public API) —
-- runs as a Script so nothing else has to require it.
--
-- Schema: { version = 1, coins = N, cooldownLevel = N }
-- Datastore name carries _v1 (hard-reset hammer for schema breaks);
-- in Studio it appends _dev so playtests don't pollute prod data.
-- Load failure kicks the player — the persistent state IS the progression,
-- so a silent default-and-warn would risk overwriting real saves.

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local CurrencyManager = require(script.Parent:WaitForChild("CurrencyManager"))

local SCHEMA_VERSION       = 3
local STORE_NAME           = "DMS_PlayerData_v1" .. (RunService:IsStudio() and "_dev" or "")
local LOAD_RETRY_ATTEMPTS  = 3
local LOAD_RETRY_BACKOFFS  = { 1, 2 } -- waits between attempt 1→2 and 2→3; 3rd attempt has no wait after

-- Mock fallback for local-only Studio runs (no PlaceId → DataStore is unavailable).
-- Persists across Stop→Play within a single Studio session via module-level table;
-- not across full Studio restart. Real DataStore kicks in automatically once the
-- place is published (game.PlaceId becomes nonzero).
local function getStore()
	if RunService:IsStudio() and game.PlaceId == 0 then
		warn("[PersistenceManager] No PlaceId — using in-memory mock store. Persists per Studio session only.")
		local mock = {}
		return {
			GetAsync = function(_, key) return mock[key] end,
			SetAsync = function(_, key, value) mock[key] = value end,
		}
	end
	return DataStoreService:GetDataStore(STORE_NAME)
end

local store = getStore()

local dirty  = {} -- [player] = true when there are unsaved changes
local loaded = {} -- [player] = true once load completes (gates saves so a kicked-pending player never overwrites)

local function keyFor(player)
	return "Player_" .. tostring(player.UserId)
end

local function unlockedAttr(toolKey)
	return toolKey .. "Unlocked"
end

local function snapshot(player)
	local data = {
		version = SCHEMA_VERSION,
		coins   = player:GetAttribute("Coins") or 0,
	}
	for _, upg in ipairs(Config.COOLDOWN_UPGRADES) do
		data[upg.levelAttr] = player:GetAttribute(upg.levelAttr) or 0
	end
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		local attr = unlockedAttr(ul.key)
		data[attr] = player:GetAttribute(attr) == true
	end
	return data
end

-- v1 → v2: v1 saved one upgrade as `cooldownLevel` (Ban only). v2 splits per-tool;
-- the old value migrates to BanCooldownLevel, others default to 0.
-- v2 → v3: tool unlocks added. Grandfather any pre-v3 player with all tools
-- unlocked (they've been playtesting; not making them re-grind).
local function migrate(data)
	if data.version == 1 then
		data.BanCooldownLevel = data.cooldownLevel or 0
		data.cooldownLevel    = nil
		data.version          = 2
	end
	if data.version == 2 then
		for _, ul in ipairs(Config.TOOL_UNLOCKS) do
			data[unlockedAttr(ul.key)] = true
		end
		data.version = 3
	end
	return data
end

local function getWithRetry(player)
	local key = keyFor(player)
	for attempt = 1, LOAD_RETRY_ATTEMPTS do
		local ok, result = pcall(store.GetAsync, store, key)
		if ok then
			return true, result
		end
		warn("[PersistenceManager] GetAsync attempt", attempt, "for", player.Name, "failed:", result)
		local backoff = LOAD_RETRY_BACKOFFS[attempt]
		if backoff then task.wait(backoff) end
	end
	return false, nil
end

local function saveOnce(player)
	if not loaded[player] then return end
	local ok, err = pcall(store.SetAsync, store, keyFor(player), snapshot(player))
	if ok then
		dirty[player] = nil
	else
		warn("[PersistenceManager] SetAsync for", player.Name, "failed:", err)
	end
end

local function loadPlayer(player)
	local ok, data = getWithRetry(player)
	if not player.Parent then return end -- left during load

	if not ok then
		player:Kick("Couldn't load your save data. Please rejoin in a minute.")
		return
	end

	if type(data) == "table" then
		data = migrate(data)
		if data.version == SCHEMA_VERSION then
			CurrencyManager.LoadFromSave(player, data)
		else
			warn("[PersistenceManager] Unrecognized save shape for", player.Name, "(version", data.version, ") — keeping defaults")
		end
	end
	-- nil data = brand new player, defaults from CurrencyManager.initPlayer remain.

	loaded[player] = true

	player:GetAttributeChangedSignal("Coins"):Connect(function() dirty[player] = true end)
	for _, upg in ipairs(Config.COOLDOWN_UPGRADES) do
		player:GetAttributeChangedSignal(upg.levelAttr):Connect(function() dirty[player] = true end)
	end
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		player:GetAttributeChangedSignal(unlockedAttr(ul.key)):Connect(function() dirty[player] = true end)
	end
end

Players.PlayerAdded:Connect(loadPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	if dirty[player] then
		saveOnce(player)
	end
	dirty[player]  = nil
	loaded[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(Config.PERSISTENCE_AUTOSAVE_INTERVAL)
		for player in pairs(dirty) do
			saveOnce(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if dirty[player] then
			task.spawn(saveOnce, player)
		end
	end
	task.wait(2) -- give in-flight SetAsync calls a moment before the server dies
end)
