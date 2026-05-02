-- ServerScriptService/Systems/ToolGranter (Script)
-- Grants unlocked tools to players on character spawn AND when an unlock is
-- purchased mid-life. Tool templates live in ReplicatedStorage.Tools (out of
-- StarterPack so Roblox doesn't auto-grant them to all players).
-- BanHammer is the only StarterPack tool — always granted, no unlock needed.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local tools  = ReplicatedStorage:WaitForChild("Tools")

local function unlockedAttr(toolKey)
	return toolKey .. "Unlocked"
end

local function grantTool(player, toolName)
	local character = player.Character
	if not character then return end

	local template = tools:FindFirstChild(toolName)
	if not template then
		warn("[ToolGranter] No template for", toolName, "in ReplicatedStorage.Tools")
		return
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	-- Skip if already in backpack OR currently equipped on the character.
	if backpack:FindFirstChild(toolName) then return end
	if character:FindFirstChild(toolName) then return end

	local tool = template:Clone()
	tool.Parent = backpack
end

local function refreshAll(player)
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		if player:GetAttribute(unlockedAttr(ul.key)) then
			grantTool(player, ul.toolName)
		end
	end
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		refreshAll(player)
	end)

	if player.Character then
		refreshAll(player)
	end

	-- Watch each unlock attribute. Flips from false→true happen on (a) load
	-- completion (PersistenceManager applies saved unlocks) and (b) live purchase
	-- (CurrencyManager.TryUnlockTool). Both should grant the tool immediately if
	-- the player is alive.
	for _, ul in ipairs(Config.TOOL_UNLOCKS) do
		player:GetAttributeChangedSignal(unlockedAttr(ul.key)):Connect(function()
			if player:GetAttribute(unlockedAttr(ul.key)) then
				grantTool(player, ul.toolName)
			end
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
