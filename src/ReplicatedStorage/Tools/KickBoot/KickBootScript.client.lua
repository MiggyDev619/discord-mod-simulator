-- StarterPack/KickBoot/KickBootScript (LocalScript)
-- On activate: send the camera's flattened forward vector so the kick cone aims
-- where the *camera* is looking, not the character body (which only rotates when
-- the player is moving — standing still + turning camera = body faces stale direction).
-- Local cooldown mirrors the server cooldown to avoid wasted remote traffic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Config       = require(Shared:WaitForChild("Config"))
local remotes      = Shared:WaitForChild("Remotes")
local kickEnemies  = remotes:WaitForChild("KickEnemies")

local tool     = script.Parent
local player   = Players.LocalPlayer
local lastKick = 0

tool.Activated:Connect(function()
	local now = tick()
	local cooldown = player:GetAttribute("KickCooldown") or Config.KICK_COOLDOWN
	if now - lastKick < cooldown then return end
	lastKick = now
	player:SetAttribute("KickReadyAt", now + cooldown)

	local character = player.Character
	if not character then return end
	if not character:FindFirstChild("HumanoidRootPart") then return end

	local camera   = Workspace.CurrentCamera
	local lookVec  = camera.CFrame.LookVector
	local flat     = Vector3.new(lookVec.X, 0, lookVec.Z)
	if flat.Magnitude < 0.01 then return end  -- looking straight up/down — no horizontal aim
	local lookDir  = flat.Unit

	print("[KickBoot] Kicking!")
	kickEnemies:FireServer(lookDir)
end)
