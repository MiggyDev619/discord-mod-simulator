-- ServerScriptService/MapPolish (ModuleScript)
-- Studio-side map polish tool. Call from command bar:
--   require(game.ServerScriptService.MapPolish).Apply()
--
-- Idempotent — clears any prior MapPolish_-prefixed parts before recreating.
-- Recolors the persistent map parts (Baseplate / EnemyStart / ServerZone) and
-- repositions the default SpawnLocation each call (single source of truth).
--
-- IsStudio guard: refuses to run in production servers. The module is in the
-- runtime DataModel so it could theoretically be required by gameplay code,
-- but Apply() no-ops outside Studio so the live map can never be modified.

local RunService = game:GetService("RunService")

local MapPolish = {}

local YELLOW   = Color3.fromRGB(250, 204, 21)
local DARK     = Color3.fromRGB(15, 15, 15)
local FLOOR    = Color3.fromRGB(28, 28, 32)
local TOWER    = Color3.fromRGB(25, 25, 28)
local WOOD     = Color3.fromRGB(50, 30, 18)
local PLASTIC  = Color3.fromRGB(15, 15, 18)
local BLURPLE  = Color3.fromRGB(88, 101, 242)
local DANGER   = Color3.fromRGB(180, 40, 40)

local PREFIX = "MapPolish_"

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name       = PREFIX .. name
	p.Size       = size
	p.CFrame     = cframe
	p.Color      = color
	p.Material   = material
	p.Anchored   = true
	p.CanCollide = true
	p.CastShadow = true
	p.Parent     = parent
	return p
end

function MapPolish.Apply()
	if not RunService:IsStudio() then
		warn("[MapPolish] Refusing to run outside Studio — Apply() is an edit-mode tool only")
		return
	end

	local Map        = workspace:WaitForChild("Map")
	local enemyStart = Map:WaitForChild("EnemyStart")
	local serverZone = Map:WaitForChild("ServerZone")

	-- Idempotency: clear prior polish parts so we don't stack duplicates.
	for _, child in ipairs(Map:GetChildren()) do
		if child.Name:sub(1, #PREFIX) == PREFIX then
			child:Destroy()
		end
	end

	local startPos = enemyStart.Position
	local endPos   = serverZone.Position
	local laneVec  = endPos - startPos
	local laneLen  = laneVec.Magnitude
	local laneDir  = laneVec.Unit
	local lanePerp = Vector3.new(-laneDir.Z, 0, laneDir.X)

	local wallHeight = 8
	local wallLen    = laneLen + 30
	local wallOffset = 18
	local wallThick  = 1
	local midpoint   = startPos:Lerp(endPos, 0.5)

	local leftCenter  = midpoint + lanePerp * wallOffset + Vector3.new(0, wallHeight/2, 0)
	local rightCenter = midpoint - lanePerp * wallOffset + Vector3.new(0, wallHeight/2, 0)

	makePart(Map, "WallLeft",  Vector3.new(wallThick, wallHeight, wallLen), CFrame.lookAt(leftCenter,  leftCenter  + laneDir), DARK, Enum.Material.Slate)
	makePart(Map, "WallRight", Vector3.new(wallThick, wallHeight, wallLen), CFrame.lookAt(rightCenter, rightCenter + laneDir), DARK, Enum.Material.Slate)

	-- Yellow Neon coping ABOVE the wall (not embedded — avoids Z-fight) and
	-- slightly wider than the wall (overhangs like a real coping).
	local stripHeight = 0.5
	local stripWidth  = wallThick + 0.4
	local stripY      = wallHeight/2 + stripHeight/2
	makePart(Map, "WallLeftStrip",  Vector3.new(stripWidth, stripHeight, wallLen), CFrame.lookAt(leftCenter  + Vector3.new(0, stripY, 0), leftCenter  + Vector3.new(0, stripY, 0) + laneDir), YELLOW, Enum.Material.Neon)
	makePart(Map, "WallRightStrip", Vector3.new(stripWidth, stripHeight, wallLen), CFrame.lookAt(rightCenter + Vector3.new(0, stripY, 0), rightCenter + Vector3.new(0, stripY, 0) + laneDir), YELLOW, Enum.Material.Neon)

	local towerCenter = endPos + laneDir * 8 + Vector3.new(0, 8, 0)
	makePart(Map, "ServerTower", Vector3.new(8, 16, 8), CFrame.lookAt(towerCenter, towerCenter + laneDir), TOWER, Enum.Material.DiamondPlate)

	for i, yOff in ipairs({-4, 2, 6}) do
		local frontPos = towerCenter + Vector3.new(0, yOff, 0) + (-laneDir * 4)
		local backPos  = towerCenter + Vector3.new(0, yOff, 0) + (laneDir * 4)
		makePart(Map, "TowerLED" .. i .. "F", Vector3.new(8.1, 0.4, 0.3), CFrame.lookAt(frontPos, frontPos + laneDir), YELLOW, Enum.Material.Neon)
		makePart(Map, "TowerLED" .. i .. "B", Vector3.new(8.1, 0.4, 0.3), CFrame.lookAt(backPos,  backPos  + laneDir), YELLOW, Enum.Material.Neon)
	end

	local deskCenter = startPos - laneDir * 8 + Vector3.new(0, 1.5, 0)
	makePart(Map, "ModeratorDesk", Vector3.new(6, 3, 3), CFrame.lookAt(deskCenter, deskCenter + laneDir), WOOD, Enum.Material.Wood)

	local monitorBackCenter = deskCenter + Vector3.new(0, 1.8, 0)
	makePart(Map, "MonitorBack", Vector3.new(3, 2, 0.2), CFrame.lookAt(monitorBackCenter, monitorBackCenter + laneDir), PLASTIC, Enum.Material.SmoothPlastic)
	local screenCenter = monitorBackCenter + laneDir * 0.13
	makePart(Map, "MonitorScreen", Vector3.new(2.8, 1.8, 0.05), CFrame.lookAt(screenCenter, screenCenter + laneDir), BLURPLE, Enum.Material.Neon)

	-- Recolor persistent parts (NOT polish-prefixed). Re-running the script
	-- reapplies these — single source of truth for the themed look.
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color    = FLOOR
		baseplate.Material = Enum.Material.SmoothPlastic
	end

	enemyStart.Color        = DANGER
	enemyStart.Material     = Enum.Material.Neon
	enemyStart.Transparency = 0.4

	serverZone.Color        = BLURPLE
	serverZone.Material     = Enum.Material.Neon
	serverZone.Transparency = 0.3

	-- SpawnLocation: base side (behind ServerZone), facing enemies.
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		local target = endPos + laneDir * 4
		spawn.Position    = Vector3.new(target.X, spawn.Position.Y, target.Z)
		spawn.Size        = Vector3.new(4, 1, 4)
		spawn.Color       = YELLOW
		spawn.Material    = Enum.Material.Neon
		spawn.Transparency = 0.5
	end

	print(string.format("[MapPolish] Applied — 12 polish parts + recolors around lane (length: %.1f studs)", laneLen))
end

return MapPolish
