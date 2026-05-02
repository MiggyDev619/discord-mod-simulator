-- ReplicatedStorage/Tools/MuteGun/MuteGunSetup (Script)
-- Welds Barrel and Sight to the Handle once the tool's parts exist.
-- Mirrors BanHammerSetup pattern. Runs each time the tool is granted/cloned.

local tool   = script.Parent
local handle = tool:WaitForChild("Handle")
local barrel = tool:WaitForChild("Barrel")
local sight  = tool:WaitForChild("Sight")

-- Barrel extends forward from the top of the grip. -Z is the tool's default
-- "forward" direction (away from holder) when held.
barrel.CFrame = handle.CFrame * CFrame.new(0, handle.Size.Y / 2 - 0.1, -(barrel.Size.Z / 2))

-- Sight sits on top of the barrel near the rear (closer to the holder).
sight.CFrame = barrel.CFrame * CFrame.new(
	0,
	barrel.Size.Y / 2 + sight.Size.Y / 2 - 0.02,
	barrel.Size.Z / 2 - 0.3
)

local barrelWeld = Instance.new("WeldConstraint")
barrelWeld.Part0  = handle
barrelWeld.Part1  = barrel
barrelWeld.Parent = handle

local sightWeld = Instance.new("WeldConstraint")
sightWeld.Part0  = barrel
sightWeld.Part1  = sight
sightWeld.Parent = barrel

print("[MuteGun] Barrel + Sight welded to Handle")
