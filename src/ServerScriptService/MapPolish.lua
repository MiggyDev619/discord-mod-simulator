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

	-- Center lane floor stripe — dim blurple Neon line showing the data path.
	-- Reads as a runway, helps players see the lane before any spawn.
	local floorY        = startPos.Y - 1.4 + 0.05  -- just above floor
	local stripeCenter  = midpoint
	makePart(
		Map, "LaneStripe",
		Vector3.new(0.6, 0.05, laneLen),
		CFrame.lookAt(Vector3.new(stripeCenter.X, floorY, stripeCenter.Z), Vector3.new(stripeCenter.X, floorY, stripeCenter.Z) + laneDir),
		BLURPLE, Enum.Material.Neon
	)
	-- Stripe transparency softens it so it doesn't dominate.
	Map[PREFIX .. "LaneStripe"].Transparency = 0.4

	-- Decorative lane pillars — 4 small dark cylinders along the lane sides.
	-- CanCollide=true so enemies physics-bounce around them; placed off the
	-- lane center (8 studs lateral) so middle-lane traffic flows past unhindered.
	local pillarOffsets = { 8, 14 }  -- studs perpendicular from lane center (left + right)
	for i, t in ipairs({ 0.30, 0.65 }) do  -- positions along the lane (1/3, 2/3)
		local along = startPos:Lerp(endPos, t)
		for side, sign in ipairs({ 1, -1 }) do
			local pillarPos = Vector3.new(along.X, floorY + 3, along.Z) + lanePerp * (pillarOffsets[1] * sign)
			local pillar = makePart(
				Map, "Pillar" .. i .. (side == 1 and "L" or "R"),
				Vector3.new(1.5, 6, 1.5),
				CFrame.new(pillarPos),
				DARK, Enum.Material.Slate
			)
			-- Blurple Neon ring at top of pillar (matches lane stripe)
			local ringY = pillarPos.Y + 3 - 0.25
			makePart(
				Map, "PillarRing" .. i .. (side == 1 and "L" or "R"),
				Vector3.new(1.6, 0.3, 1.6),
				CFrame.new(Vector3.new(pillarPos.X, ringY, pillarPos.Z)),
				BLURPLE, Enum.Material.Neon
			)
		end
	end

	-- Wumpus statue — Discord's mascot near the moderator's desk. Built from
	-- primitives: blurple Ball body + smaller head + white eye + tiny pupil +
	-- small block "beanie" on top. Recognizable to any Discord-using player.
	local wumpusBase   = deskCenter + lanePerp * 6 + Vector3.new(0, -1.5 + 2, 0)  -- on floor + 2 studs up
	local body = makePart(
		Map, "WumpusBody",
		Vector3.new(3.5, 3.5, 3.5),
		CFrame.new(wumpusBase),
		BLURPLE, Enum.Material.Neon
	)
	body.Shape = Enum.PartType.Ball
	body.Transparency = 0.05
	local head = makePart(
		Map, "WumpusHead",
		Vector3.new(2.8, 2.8, 2.8),
		CFrame.new(wumpusBase + Vector3.new(0, 2.8, 0)),
		BLURPLE, Enum.Material.Neon
	)
	head.Shape = Enum.PartType.Ball
	head.Transparency = 0.05
	-- Eye on the front (toward the lane — facing the action)
	local eyePos = wumpusBase + Vector3.new(0, 2.8, 0) + (-laneDir * 1.0)
	local eye = makePart(
		Map, "WumpusEye",
		Vector3.new(0.9, 0.9, 0.9),
		CFrame.new(eyePos),
		Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic
	)
	eye.Shape = Enum.PartType.Ball
	local pupil = makePart(
		Map, "WumpusPupil",
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(eyePos + (-laneDir * 0.3)),
		Color3.fromRGB(15, 15, 18), Enum.Material.SmoothPlastic
	)
	pupil.Shape = Enum.PartType.Ball
	-- Beanie: small block on top of head
	makePart(
		Map, "WumpusBeanie",
		Vector3.new(2.4, 0.8, 2.4),
		CFrame.new(wumpusBase + Vector3.new(0, 4.5, 0)),
		Color3.fromRGB(180, 50, 80), Enum.Material.Fabric
	)

	-- Empty side workstation — abandoned moderator desk on the OPPOSITE side
	-- of the lane from the Wumpus. Implies "your coworkers are off duty" without
	-- needing NPC models. Red "ALERT" screen reads as "down station."
	local sideDeskCenter = deskCenter - lanePerp * 10
	local sideDesk = makePart(
		Map, "SideDesk",
		Vector3.new(5, 2.5, 2.5),
		CFrame.lookAt(sideDeskCenter, sideDeskCenter + laneDir),
		WOOD, Enum.Material.Wood
	)
	-- Chair: cylinder seat + back
	local chairSeat = makePart(
		Map, "SideChairSeat",
		Vector3.new(1.6, 0.4, 1.6),
		CFrame.new(sideDeskCenter + (-laneDir * 2.5) + Vector3.new(0, -0.4, 0)),
		Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic
	)
	chairSeat.Shape = Enum.PartType.Cylinder
	chairSeat.Orientation = Vector3.new(0, 0, 90)  -- flat cylinder for seat
	makePart(
		Map, "SideChairBack",
		Vector3.new(1.6, 2.0, 0.3),
		CFrame.lookAt(sideDeskCenter + (-laneDir * 3.2) + Vector3.new(0, 0.5, 0), sideDeskCenter + (-laneDir * 3.2) + Vector3.new(0, 0.5, 0) + laneDir),
		Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic
	)
	local sideMonitorBackCenter = sideDeskCenter + Vector3.new(0, 1.6, 0)
	makePart(Map, "SideMonitorBack",   Vector3.new(2.5, 1.6, 0.18), CFrame.lookAt(sideMonitorBackCenter, sideMonitorBackCenter + laneDir), PLASTIC, Enum.Material.SmoothPlastic)
	makePart(
		Map, "SideMonitorScreen",
		Vector3.new(2.4, 1.5, 0.05),
		CFrame.lookAt(sideMonitorBackCenter + laneDir * 0.12, sideMonitorBackCenter + laneDir * 2),
		Color3.fromRGB(220, 50, 50), Enum.Material.Neon
	)

	-- Floating data packet particles — emitted upward from the tower base.
	-- ParticleEmitter is self-running, no script needed.
	local packetAnchor = makePart(
		Map, "PacketEmitter",
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(towerCenter - Vector3.new(0, 8, 0)),
		BLURPLE, Enum.Material.Neon
	)
	packetAnchor.Transparency = 1
	packetAnchor.CanCollide = false
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(BLURPLE)
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.6),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1,   0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    0.3),
		NumberSequenceKeypoint.new(0.7,  0.3),
		NumberSequenceKeypoint.new(1,    1),
	})
	emitter.Lifetime      = NumberRange.new(2.5, 4.0)
	emitter.Speed         = NumberRange.new(2, 4)
	emitter.SpreadAngle   = Vector2.new(20, 20)
	emitter.Rate          = 6
	emitter.LightEmission = 0.7
	emitter.Acceleration  = Vector3.new(0, 1.5, 0)  -- slow drift up
	emitter.Parent        = packetAnchor

	-- Animation Script: pulses the tower LED parts via TweenService. Created at
	-- Apply time and parented to Map (workspace child Scripts auto-run in Play).
	-- The Source assignment requires Studio script-edit permissions, which the
	-- command bar context has (this won't work from a runtime script).
	local animator = Instance.new("Script")
	animator.Name = PREFIX .. "TowerAnimator"
	animator.Source = [[
local TweenService = game:GetService("TweenService")
local Map = workspace:WaitForChild("Map")

local PULSE_INFO = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

for _, child in ipairs(Map:GetChildren()) do
	if child.Name:match("^MapPolish_TowerLED") then
		child.Transparency = 0.4
		TweenService:Create(child, PULSE_INFO, { Transparency = 0 }):Play()
	end
end
]]
	animator.Parent = Map

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

	print(string.format("[MapPolish] Applied — polish parts + decor (Wumpus, side desk, pillars, lane stripe, particles, animator) + recolors around lane (length: %.1f studs)", laneLen))
end

return MapPolish
