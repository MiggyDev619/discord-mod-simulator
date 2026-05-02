-- ReplicatedStorage/Tools/MuteGun/MuteGunScript (LocalScript)
-- Hitscan freeze gun. Mouse-aim raycast — first hit freezes the target, second
-- hit on the same already-frozen target (or a Timeout-frozen one) destroys it.
-- Server validates target + range + cooldown; client spawns the tracer for feel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local Effects     = require(Shared:WaitForChild("Effects"))
local remotes     = Shared:WaitForChild("Remotes")
local muteEnemy   = remotes:WaitForChild("MuteEnemy")
local muteShotFx  = remotes:WaitForChild("MuteShotFx")

local tool     = script.Parent
local player   = Players.LocalPlayer
local mouse    = player:GetMouse()
local lastShot = 0

-- Tracer origin: prefer the actual barrel muzzle when the tool is equipped
-- (the parts are welded into workspace at that point), fall back to the
-- character's chest + forward so we always emit a visible line.
local function muzzlePosition()
	local barrel = tool:FindFirstChild("Barrel")
	if barrel and barrel:IsA("BasePart") then
		return (barrel.CFrame * CFrame.new(0, 0, -barrel.Size.Z / 2)).Position
	end
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			return root.Position + root.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)
		end
	end
	return Vector3.zero
end

tool.Activated:Connect(function()
	local now      = tick()
	local cooldown = player:GetAttribute("MuteCooldown") or Config.MUTE_COOLDOWN
	if now - lastShot < cooldown then return end
	lastShot = now
	player:SetAttribute("MuteReadyAt", now + cooldown)

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Camera-through-cursor ray. Excludes own character so we don't hit ourselves.
	local unitRay   = mouse.UnitRay
	local rayParams = RaycastParams.new()
	rayParams.FilterType                 = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local muzzle   = muzzlePosition()
	local result   = Workspace:Raycast(unitRay.Origin, unitRay.Direction * Config.MUTE_RANGE, rayParams)
	local endPoint = unitRay.Origin + unitRay.Direction * Config.MUTE_RANGE
	local target   = nil

	if result then
		endPoint = result.Position
		if result.Instance and result.Instance:GetAttribute("IsEnemy") then
			-- Server re-checks distance from player; this is just a cheap pre-filter.
			if (result.Instance.Position - root.Position).Magnitude <= Config.MUTE_RANGE then
				target = result.Instance
			end
		end
	end

	-- Always spawn the tracer — hit or miss — so the gun feels alive on every click.
	Effects.MuteTracer(muzzle, endPoint)

	-- Replicate the shot to other players via the server bounce. Local tracer
	-- already rendered above; the bounce fires the same effect on every other
	-- client (multiplayer visibility into who's shooting).
	muteShotFx:FireServer(muzzle, endPoint)

	if target then
		print("[MuteGun] Hit:", target.Name, "dist:", math.floor((target.Position - root.Position).Magnitude))
		muteEnemy:FireServer(target)
	else
		print("[MuteGun] Miss")
	end
end)
