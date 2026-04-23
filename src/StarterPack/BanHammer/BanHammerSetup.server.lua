-- StarterPack/BanHammer/BanHammerSetup (Script)
-- Welds the Head to the top of the Handle once the tool's parts exist.
-- Runs on each player's cloned tool at join/respawn.

local tool   = script.Parent
local handle = tool:WaitForChild("Handle")
local head   = tool:WaitForChild("Head")

-- Position the head centered on top of the handle, with a small overlap so it looks attached.
head.CFrame = handle.CFrame * CFrame.new(0, handle.Size.Y / 2 + head.Size.Y / 2 - 0.2, 0)

local weld = Instance.new("WeldConstraint")
weld.Part0  = handle
weld.Part1  = head
weld.Parent = handle

print("[BanHammer] Head welded to Handle")
