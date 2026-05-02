# MAP-LAYOUT.md

Map polish placement spec for Phase 5 Day 23. Map geometry lives in Studio (Workspace is intentionally NOT in the Rojo tree per `state.md` §2). This doc is the source-of-truth recipe so it can be rebuilt if the place file is ever lost.

**Run ONCE.** The Lua script below is a Studio command-bar one-shot that reads your existing `EnemyStart` and `ServerZone` parts and creates the polish geometry around them. Idempotent — safe to re-run if you tweak the script and want to redo it (it deletes any existing polish parts named with the `MapPolish_` prefix and recreates them).

---

## What gets created

| Element | Position relative to lane | Size | Color | Material |
|---|---|---|---|---|
| `MapPolish_WallLeft` | left side of lane (perpendicular offset 18 studs from midpoint) | (1, 8, laneLen+30) | dark slate `(15,15,15)` | Slate |
| `MapPolish_WallRight` | right side of lane (mirror) | (1, 8, laneLen+30) | dark slate | Slate |
| `MapPolish_WallLeftStrip` | yellow Neon LED strip along top of left wall | (0.4, 0.4, laneLen+30) | brand yellow `(250,204,21)` | Neon |
| `MapPolish_WallRightStrip` | mirror | same | yellow | Neon |
| `MapPolish_ServerTower` | 8 studs behind `ServerZone` along laneDir, raised 8 studs | (8, 16, 8) | dark grey `(25,25,28)` | DiamondPlate |
| `MapPolish_TowerLED1..3 / Back` | 3 horizontal yellow LED strips around the tower at y=-2/+2/+6 | (8.1, 0.4, 0.3) each | yellow | Neon |
| `MapPolish_ModeratorDesk` | 8 studs behind `EnemyStart` (player spawn side) | (6, 3, 3) | wood brown `(50,30,18)` | Wood |
| `MapPolish_MonitorBack` | sits on top of desk, faces toward enemies | (3, 2, 0.2) | dark plastic | SmoothPlastic |
| `MapPolish_MonitorScreen` | thin Neon plate in front of monitor back | (2.8, 1.8, 0.05) | Discord blurple `(88,101,242)` | Neon |

Total: 12 parts. All anchored, parented to `Workspace.Map`.

---

## Steps

1. Open the place in Studio (`File → Open from Roblox` if you have the live version, or `discord-mod-simulator.rbxlx` from the latest `rojo build`).
2. Verify `Workspace.Map.EnemyStart` and `Workspace.Map.ServerZone` exist as anchored Parts (they should — they predate Phase 5).
3. Open the **command bar** (`View → Command Bar` if hidden).
4. Paste the script below. Hit Enter.
5. Check the Output panel — should print `[MapPolish] Created 12 parts around lane (length: NN)`.
6. Walk around in Test → Play to verify enemies still path correctly through the lane and don't get stuck on the new walls.
7. **`File → Publish to Roblox`** to upload the polished place. (Polish parts are server-authoritative geometry — they only affect players who load the published version.)

---

## The script (v2 — fixes Z-fighting + recolors baseplate / spawn / EnemyStart / ServerZone)

```lua
-- DMS map polish — Phase 5 Day 23 (v2)
-- Run from Studio command bar. Safe to re-run (idempotent).
-- Changes from v1: yellow strips lifted ABOVE wall (no more Z-fight flicker),
-- baseplate recolored to themed dark, EnemyStart/ServerZone recolored to brand,
-- default SpawnLocation moved behind the moderator's desk so it's out of the lane.

local Map        = workspace:WaitForChild("Map")
local enemyStart = Map:WaitForChild("EnemyStart")
local serverZone = Map:WaitForChild("ServerZone")

local YELLOW   = Color3.fromRGB(250, 204, 21)
local DARK     = Color3.fromRGB(15, 15, 15)
local FLOOR    = Color3.fromRGB(28, 28, 32)   -- baseplate themed dark
local TOWER    = Color3.fromRGB(25, 25, 28)
local WOOD     = Color3.fromRGB(50, 30, 18)
local PLASTIC  = Color3.fromRGB(15, 15, 18)
local BLURPLE  = Color3.fromRGB(88, 101, 242)
local DANGER   = Color3.fromRGB(180, 40, 40)  -- EnemyStart warning red

local PREFIX = "MapPolish_"

-- Idempotency: clear any prior polish parts so we don't stack duplicates.
for _, child in ipairs(Map:GetChildren()) do
    if child.Name:sub(1, #PREFIX) == PREFIX then
        child:Destroy()
    end
end

local function makePart(name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name       = PREFIX .. name
    p.Size       = size
    p.CFrame     = cframe
    p.Color      = color
    p.Material   = material
    p.Anchored   = true
    p.CanCollide = true
    p.CastShadow = true
    p.Parent     = Map
    return p
end

local startPos = enemyStart.Position
local endPos   = serverZone.Position
local laneVec  = endPos - startPos
local laneLen  = laneVec.Magnitude
local laneDir  = laneVec.Unit
local lanePerp = Vector3.new(-laneDir.Z, 0, laneDir.X)  -- horizontal perpendicular

local wallHeight = 8
local wallLen    = laneLen + 30
local wallOffset = 18
local midpoint   = startPos:Lerp(endPos, 0.5)

-- Boundary walls. CFrame.lookAt orients the part's -Z toward laneDir, so its
-- Z dimension (length) runs along the lane. X is wall thickness, Y is height.
local wallThick = 1
local leftCenter  = midpoint + lanePerp * wallOffset + Vector3.new(0, wallHeight/2, 0)
local rightCenter = midpoint - lanePerp * wallOffset + Vector3.new(0, wallHeight/2, 0)

makePart("WallLeft",  Vector3.new(wallThick, wallHeight, wallLen), CFrame.lookAt(leftCenter,  leftCenter  + laneDir), DARK, Enum.Material.Slate)
makePart("WallRight", Vector3.new(wallThick, wallHeight, wallLen), CFrame.lookAt(rightCenter, rightCenter + laneDir), DARK, Enum.Material.Slate)

-- Yellow Neon coping along the top of each wall. Sits ABOVE the wall (not
-- embedded — that's what caused v1's Z-fight flicker) and slightly wider so
-- it overhangs the wall edges (clean coping look, no coplanar surfaces).
local stripHeight = 0.5
local stripWidth  = wallThick + 0.4  -- 0.2 overhang on each side
local stripY      = wallHeight/2 + stripHeight/2  -- centered ABOVE the wall top
makePart("WallLeftStrip",  Vector3.new(stripWidth, stripHeight, wallLen), CFrame.lookAt(leftCenter  + Vector3.new(0, stripY, 0), leftCenter  + Vector3.new(0, stripY, 0) + laneDir), YELLOW, Enum.Material.Neon)
makePart("WallRightStrip", Vector3.new(stripWidth, stripHeight, wallLen), CFrame.lookAt(rightCenter + Vector3.new(0, stripY, 0), rightCenter + Vector3.new(0, stripY, 0) + laneDir), YELLOW, Enum.Material.Neon)

-- Server tower behind the zone, slightly raised so it reads as a "rack."
local towerCenter = endPos + laneDir * 8 + Vector3.new(0, 8, 0)
makePart("ServerTower", Vector3.new(8, 16, 8), CFrame.lookAt(towerCenter, towerCenter + laneDir), TOWER, Enum.Material.DiamondPlate)

-- 3 LED bands wrapping the tower (front + back), spaced vertically.
for i, yOff in ipairs({-4, 2, 6}) do
    local frontPos = towerCenter + Vector3.new(0, yOff, 0) + (-laneDir * 4)
    local backPos  = towerCenter + Vector3.new(0, yOff, 0) + (laneDir * 4)
    makePart("TowerLED"  .. i .. "F", Vector3.new(8.1, 0.4, 0.3), CFrame.lookAt(frontPos, frontPos + laneDir), YELLOW, Enum.Material.Neon)
    makePart("TowerLED"  .. i .. "B", Vector3.new(8.1, 0.4, 0.3), CFrame.lookAt(backPos,  backPos  + laneDir), YELLOW, Enum.Material.Neon)
end

-- Moderator's desk behind the player spawn side. Faces the enemies.
local deskCenter = startPos - laneDir * 8 + Vector3.new(0, 1.5, 0)
makePart("ModeratorDesk", Vector3.new(6, 3, 3), CFrame.lookAt(deskCenter, deskCenter + laneDir), WOOD, Enum.Material.Wood)

-- Monitor: dark plastic back + Discord-blurple Neon screen, sitting on desk top.
local monitorBackCenter = deskCenter + Vector3.new(0, 1.8, 0)
makePart("MonitorBack",   Vector3.new(3, 2, 0.2),   CFrame.lookAt(monitorBackCenter, monitorBackCenter + laneDir), PLASTIC, Enum.Material.SmoothPlastic)
local screenCenter = monitorBackCenter + laneDir * 0.13
makePart("MonitorScreen", Vector3.new(2.8, 1.8, 0.05), CFrame.lookAt(screenCenter, screenCenter + laneDir), BLURPLE, Enum.Material.Neon)

-- Recolor existing parts (NOT polish-prefixed — these are persistent map parts
-- the user originally placed). Re-running the script reapplies these colors,
-- so if you tweak by hand they'll get clobbered — by design (single source of
-- truth for the themed look).

-- Baseplate: themed dark replaces the default grey.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
    baseplate.Color    = FLOOR
    baseplate.Material = Enum.Material.SmoothPlastic
end

-- EnemyStart: warning red Neon — reads as "danger spawn point."
enemyStart.Color    = DANGER
enemyStart.Material = Enum.Material.Neon
enemyStart.Transparency = 0.4  -- slightly translucent so it doesn't dominate visually

-- ServerZone: Discord blurple Neon — matches the monitor screen, brand-coherent.
serverZone.Color    = BLURPLE
serverZone.Material = Enum.Material.Neon
serverZone.Transparency = 0.3

-- Default SpawnLocation: positioned on the BASE side of the lane (behind the
-- ServerZone), so the player spawns facing the incoming enemies — natural
-- defender position. Y preserved from existing spawn so it stays on whatever
-- floor level the user has.
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
    local target = endPos + laneDir * 4  -- 4 studs behind ServerZone, in lane center
    spawn.Position    = Vector3.new(target.X, spawn.Position.Y, target.Z)
    spawn.Size        = Vector3.new(4, 1, 4)
    spawn.Color       = YELLOW
    spawn.Material    = Enum.Material.Neon
    spawn.Transparency = 0.5
end

print(string.format("[MapPolish] Created 12 parts + recolored baseplate/EnemyStart/ServerZone/SpawnLocation around lane (length: %.1f studs)", laneLen))
```

### What v2 changes vs v1

| Issue | v1 behavior | v2 fix |
|---|---|---|
| Yellow strip flicker | Strip embedded in wall top — coplanar Z-fight | Strip lifted to sit ABOVE wall, slightly wider for overhang look |
| Grey baseplate | Untouched | Recolored to themed dark, SmoothPlastic |
| Green SpawnLocation in middle of lane | Untouched | Moved behind desk, resized small, recolored brand yellow |
| Blue ServerZone | Untouched | Discord blurple Neon (matches monitor) |
| Default-color EnemyStart | Untouched | Warning red Neon, slightly translucent |
| SpawnLocation position | Behind moderator's desk (enemy side) | Behind ServerZone (base side) — player spawns facing enemies |

---

## Verification

After running:

1. **Walls visible** — two long dark walls flanking the lane with yellow Neon strips along the top.
2. **Server tower** — a chunky dark grey "rack" sits behind the `ServerZone` with three glowing yellow LED bands wrapping it.
3. **Desk + monitor** — small wooden desk behind the player spawn area with a Discord-blurple glowing monitor screen facing the enemies.
4. **Enemies still reach the zone** — Play once, watch a Troll walk in. Should travel between the walls, not bump into them.
5. **Player can still move freely** — walls are 18 studs from lane center, well outside the player's normal movement area.

If anything looks off (walls too close, tower clipping into spawn, etc.), tell Claude what's wrong with specifics — I can adjust the offsets in the script.

---

## Lighting recipe

Already documented in `docs/USER-ACTIONS.md` §F. Apply after the map polish for the best visual impact (warm yellow accents pop against the new dark walls).

---

## Re-running the script

If you change something and want to redo: just paste the script again. The `MapPolish_` prefix + the cleanup loop at the top means re-runs are safe (no duplicates).

If you want to wipe ALL polish without recreating: paste this in the command bar:

```lua
for _, c in ipairs(workspace.Map:GetChildren()) do
    if c.Name:sub(1, 10) == "MapPolish_" then c:Destroy() end
end
```
