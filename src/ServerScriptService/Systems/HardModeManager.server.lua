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

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local lastDamageTime = {}  -- [player] = tick of last damage taken (for i-frames)

Players.PlayerRemoving:Connect(function(player)
	lastDamageTime[player] = nil
end)

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
