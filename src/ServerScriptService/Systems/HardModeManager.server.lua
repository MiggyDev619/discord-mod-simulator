-- ServerScriptService/Systems/HardModeManager (Script)
-- v2 Week 7 — opt-in Hard Mode. When workspace.CurrentHardMode is true,
-- enemies damage the player character on proximity (touch). Per-player
-- invincibility-frame timer prevents shred-on-touch from a clustered enemy
-- group. Damage uses Roblox Humanoid:TakeDamage so the standard death/respawn
-- flow handles character respawn — no custom respawn logic needed.
--
-- Coin compensation (2×) is applied in CurrencyManager.AddCoins via the
-- workspace.CurrentHardMode attribute — no plumbing needed here.
--
-- Per-frame cost: O(players × enemies) distance checks. With ~10 enemies
-- and 1-4 players that's <50 cheap Vector3 magnitude calcs per frame —
-- negligible.

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local GameManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("GameManager"))

local lastDamageTime = {}  -- [player] = tick of last damage taken (for i-frames)

Players.PlayerRemoving:Connect(function(player)
	lastDamageTime[player] = nil
end)

-- v2 fix-up: character death triggers FULL game over in two cases:
--   1. Hard Mode (any map) — was already shipped.
--   2. Maze Mode (any sub-mode) — added per user request after fall-off bug.
--      Falling off the maze respawns at lane SpawnLocation by default, which
--      is jarring. Treat death-while-in-maze as run-over so the player gets
--      the GameOverPanel → RETRY → lobby flow.
-- Lane Mode (non-Hard) unaffected — character respawns normally.
local function shouldDeathEndRun()
	return workspace:GetAttribute("CurrentHardMode")
		or workspace:GetAttribute("CurrentMode") == "Maze"
end

local function triggerDeathGameOver(player, reason)
	if GameManager.IsGameOver() then return end
	if not shouldDeathEndRun() then return end
	print(string.format("[HardModeManager] %s %s — triggering game over (mode=%s, hard=%s)",
		player.Name, reason,
		tostring(workspace:GetAttribute("CurrentMode")),
		tostring(workspace:GetAttribute("CurrentHardMode"))))
	GameManager.TakeDamage(99999)
end

local function setupCharacterDeathHook(player, character)
	local hum = character:WaitForChild("Humanoid", 5)
	if not hum then return end
	hum.Died:Connect(function()
		triggerDeathGameOver(player, "died (Humanoid.Died)")
	end)
end

local function setupPlayer(player)
	if player.Character then setupCharacterDeathHook(player, player.Character) end
	player.CharacterAdded:Connect(function(character)
		setupCharacterDeathHook(player, character)
	end)
	-- CharacterRemoving catches the fall-off-map case where Roblox destroys
	-- the character before Humanoid.Died fires. Brief task.delay lets Died
	-- fire first if it's going to (avoids double-fire).
	player.CharacterRemoving:Connect(function()
		task.delay(0.15, function()
			triggerDeathGameOver(player, "character removed (likely fell off map)")
		end)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

-- Per-frame proximity damage. Skips entirely when Hard Mode is off.
RunService.Heartbeat:Connect(function()
	if not workspace:GetAttribute("CurrentHardMode") then return end
	if workspace:GetAttribute("CurrentMode") == nil or workspace:GetAttribute("CurrentMode") == "" then
		return  -- in lobby — no enemies, no damage
	end

	local now = tick()
	-- Cache enemies once per frame (workspace:GetDescendants is the expensive part).
	local enemies = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("IsEnemy") then
			table.insert(enemies, obj)
		end
	end
	if #enemies == 0 then return end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hum = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local last = lastDamageTime[player] or 0
				if (now - last) >= Config.HARD_MODE_INVINCIBILITY_FRAMES then
					for _, enemy in ipairs(enemies) do
						if (enemy.Position - root.Position).Magnitude <= Config.HARD_MODE_TOUCH_RADIUS then
							hum:TakeDamage(Config.HARD_MODE_TOUCH_DAMAGE)
							lastDamageTime[player] = now
							-- Don't deal multiple ticks of damage in the same frame
							break
						end
					end
				end
			end
		end
	end
end)
