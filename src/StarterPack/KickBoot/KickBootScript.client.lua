-- StarterPack/KickBoot/KickBootScript (LocalScript)
-- On activate: fire KickEnemies with no payload — server re-derives the cone from
-- the player's HumanoidRootPart.CFrame.LookVector and hits everything inside it.
-- Local cooldown mirrors the server cooldown to avoid wasted remote traffic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared:WaitForChild("Config"))
local remotes      = Shared:WaitForChild("Remotes")
local kickEnemies  = remotes:WaitForChild("KickEnemies")

local tool     = script.Parent
local player   = Players.LocalPlayer
local lastKick = 0

tool.Activated:Connect(function()
	local now = tick()
	if now - lastKick < Config.KICK_COOLDOWN then return end
	lastKick = now

	local character = player.Character
	if not character then return end
	if not character:FindFirstChild("HumanoidRootPart") then return end

	print("[KickBoot] Kicking!")
	kickEnemies:FireServer()
end)
