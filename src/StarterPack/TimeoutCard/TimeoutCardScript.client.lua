-- StarterPack/TimeoutCard/TimeoutCardScript (LocalScript)
-- On activate: find the closest enemy within TIMEOUT_RANGE and fire TimeoutEnemy to server.
-- Server applies the freeze + visual; this script only picks the target and debounces.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local Config        = require(Shared:WaitForChild("Config"))
local remotes       = Shared:WaitForChild("Remotes")
local timeoutEnemy  = remotes:WaitForChild("TimeoutEnemy")

local tool     = script.Parent
local player   = Players.LocalPlayer
local lastCast = 0

tool.Activated:Connect(function()
	local now = tick()
	if now - lastCast < Config.TIMEOUT_COOLDOWN then return end
	lastCast = now
	player:SetAttribute("TimeoutReadyAt", now + Config.TIMEOUT_COOLDOWN)

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local origin      = root.Position
	local closest     = nil
	local closestDist = Config.TIMEOUT_RANGE

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
		print("[TimeoutCard] Timing out:", closest.Name, "dist:", math.floor(closestDist))
		timeoutEnemy:FireServer(closest)
	else
		print("[TimeoutCard] No enemy in range")
	end
end)
