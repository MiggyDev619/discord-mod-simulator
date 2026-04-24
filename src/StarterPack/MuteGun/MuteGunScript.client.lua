-- StarterPack/MuteGun/MuteGunScript (LocalScript)
-- On activate: find the closest enemy within MUTE_RANGE and fire MuteEnemy to server.
-- Server applies the slow + visual; this script only picks the target and debounces.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Config    = require(Shared:WaitForChild("Config"))
local remotes   = Shared:WaitForChild("Remotes")
local muteEnemy = remotes:WaitForChild("MuteEnemy")

local tool     = script.Parent
local player   = Players.LocalPlayer
local lastShot = 0

tool.Activated:Connect(function()
	local now = tick()
	if now - lastShot < Config.MUTE_COOLDOWN then return end
	lastShot = now

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local origin      = root.Position
	local closest     = nil
	local closestDist = Config.MUTE_RANGE

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("IsEnemy") then
			local dist = (obj.Position - origin).Magnitude
			if dist < closestDist then
				closestDist = dist
				closest     = obj
			end
		end
	end

	if closest then
		print("[MuteGun] Muting:", closest.Name, "dist:", math.floor(closestDist))
		muteEnemy:FireServer(closest)
	else
		print("[MuteGun] No enemy in range")
	end
end)
