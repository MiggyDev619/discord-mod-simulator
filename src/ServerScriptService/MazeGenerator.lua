-- ServerScriptService/MazeGenerator (ModuleScript)
-- v2 Week 6 — procedural maze generator. Studio command-bar invocation:
--   require(game.ServerScriptService.MazeGenerator).Apply()
--
-- Generates a simple grid-based maze in workspace.Map: a NxN grid of cells
-- separated by walls, with 4 entrances (one per outer wall midpoint), and a
-- center base where enemies converge. All parts MazeGen_-prefixed for
-- idempotent cleanup on re-run.
--
-- IsStudio guard: refuses to run in production servers — same pattern as
-- MapPolish. Maze geometry should be regenerated only at design time.
--
-- NOTE: enemy AI for the maze (PathfindingService waypoint navigation) is
-- not yet wired into EnemySpawner. Picking Maze Mode in the lobby currently
-- loads Lane Mode movement on the maze geometry — enemies will physics-bounce
-- off walls toward ServerZone. The proper PathfindingService integration is
-- deferred to a focused future sprint that requires real Studio testing on
-- this generated geometry.

local RunService = game:GetService("RunService")

local MazeGenerator = {}

local YELLOW  = Color3.fromRGB(250, 204, 21)
local DARK    = Color3.fromRGB(15, 15, 15)
local FLOOR   = Color3.fromRGB(28, 28, 32)
local BLURPLE = Color3.fromRGB(88, 101, 242)
local DANGER  = Color3.fromRGB(180, 40, 40)

local PREFIX = "MazeGen_"

-- Grid sizing — tunable. cellSize is in studs; gridN is cells per side.
-- Total maze footprint: gridN * cellSize. With defaults: 10 * 12 = 120 studs.
local CELL_SIZE = 12
local GRID_N    = 10
local WALL_HEIGHT = 8
local WALL_THICK  = 1

local function makePart(parent, name, size, cframe, color, material, transparency)
	local p = Instance.new("Part")
	p.Name         = PREFIX .. name
	p.Size         = size
	p.CFrame       = cframe
	p.Color        = color
	p.Material     = material
	p.Transparency = transparency or 0
	p.Anchored     = true
	p.CanCollide   = true
	p.CastShadow   = true
	p.Parent       = parent
	return p
end

-- Recursive backtracker maze algorithm. Returns a 2D array of cells where
-- each cell is { N=bool, E=bool, S=bool, W=bool } indicating walls present.
-- Default: all walls present; algorithm carves passages by removing walls.
local function generateMaze(n)
	local grid = {}
	for y = 1, n do
		grid[y] = {}
		for x = 1, n do
			grid[y][x] = { N = true, E = true, S = true, W = true, visited = false }
		end
	end

	-- Stack-based DFS carve
	local stack = { { x = math.random(1, n), y = math.random(1, n) } }
	grid[stack[1].y][stack[1].x].visited = true

	local DX = { N = 0,  E = 1,  S = 0,  W = -1 }
	local DY = { N = -1, E = 0,  S = 1,  W = 0  }
	local OPP = { N = "S", S = "N", E = "W", W = "E" }

	while #stack > 0 do
		local cur = stack[#stack]
		-- Find unvisited neighbors
		local neighbors = {}
		for _, dir in ipairs({ "N", "E", "S", "W" }) do
			local nx, ny = cur.x + DX[dir], cur.y + DY[dir]
			if nx >= 1 and nx <= n and ny >= 1 and ny <= n and not grid[ny][nx].visited then
				table.insert(neighbors, { x = nx, y = ny, dir = dir })
			end
		end
		if #neighbors == 0 then
			table.remove(stack)
		else
			local choice = neighbors[math.random(1, #neighbors)]
			-- Carve passage: remove wall on cur in choice direction + opposite on neighbor
			grid[cur.y][cur.x][choice.dir] = false
			grid[choice.y][choice.x][OPP[choice.dir]] = false
			grid[choice.y][choice.x].visited = true
			table.insert(stack, choice)
		end
	end

	return grid
end

-- Carve 4 entrances at the midpoints of each outer wall so enemies can enter
-- from N/E/S/W. Carve a center "base zone" by removing inner walls in a 2x2
-- block at the grid center.
local function carveEntrancesAndBase(grid, n)
	local mid = math.floor(n / 2)
	-- Entrances
	grid[1][mid].N      = false
	grid[n][mid].S      = false
	grid[mid][1].W      = false
	grid[mid][n].E      = false
	-- Center 2x2 base (remove all walls between the 4 cells)
	if mid >= 1 and mid + 1 <= n then
		grid[mid][mid].E       = false
		grid[mid][mid + 1].W   = false
		grid[mid][mid].S       = false
		grid[mid + 1][mid].N   = false
		grid[mid][mid + 1].S   = false
		grid[mid + 1][mid + 1].N = false
		grid[mid + 1][mid].E   = false
		grid[mid + 1][mid + 1].W = false
	end
end

function MazeGenerator.Apply()
	if not RunService:IsStudio() then
		warn("[MazeGenerator] Refusing to run outside Studio — Apply() is an edit-mode tool only")
		return
	end

	local Map        = workspace:WaitForChild("Map")
	local enemyStart = Map:FindFirstChild("EnemyStart")
	local serverZone = Map:FindFirstChild("ServerZone")
	if not enemyStart or not serverZone then
		warn("[MazeGenerator] Missing EnemyStart or ServerZone in Workspace.Map")
		return
	end

	-- Idempotency: clear prior maze parts.
	for _, child in ipairs(Map:GetChildren()) do
		if child.Name:sub(1, #PREFIX) == PREFIX then
			child:Destroy()
		end
	end

	-- Anchor maze to a position offset from the existing map so the maze
	-- doesn't collide with the lane geometry. Use an offset 200 studs to one
	-- side along the perpendicular of the lane direction.
	local laneVec = serverZone.Position - enemyStart.Position
	local laneDir = (laneVec.Magnitude > 0) and laneVec.Unit or Vector3.new(1, 0, 0)
	local lanePerp = Vector3.new(-laneDir.Z, 0, laneDir.X)
	local mazeOrigin = enemyStart.Position + lanePerp * 200

	-- Floor for the maze area (single big plate)
	local mazeSize = GRID_N * CELL_SIZE
	makePart(Map, "Floor", Vector3.new(mazeSize + 4, 0.4, mazeSize + 4),
		CFrame.new(mazeOrigin + Vector3.new(0, -0.2, 0)),
		FLOOR, Enum.Material.SmoothPlastic)

	-- Generate the maze cells + carve entrances/base
	local grid = generateMaze(GRID_N)
	carveEntrancesAndBase(grid, GRID_N)

	-- Build walls. For each cell, draw N + W walls (S+E are drawn by the next
	-- cell as their N/W); plus draw the bottom-row S walls and rightmost-col
	-- E walls (no neighbor to draw them from the other side).
	local function cellOrigin(cx, cy)
		-- cx, cy in 1..N. Maze centered around mazeOrigin.
		local offsetX = (cx - 1 - (GRID_N - 1) / 2) * CELL_SIZE
		local offsetZ = (cy - 1 - (GRID_N - 1) / 2) * CELL_SIZE
		return mazeOrigin + Vector3.new(offsetX, 0, offsetZ)
	end

	for y = 1, GRID_N do
		for x = 1, GRID_N do
			local origin = cellOrigin(x, y)
			local cell   = grid[y][x]
			if cell.N then
				makePart(Map, ("WallN_%d_%d"):format(x, y),
					Vector3.new(CELL_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK),
					CFrame.new(origin + Vector3.new(0, WALL_HEIGHT/2, -CELL_SIZE/2)),
					DARK, Enum.Material.Slate)
			end
			if cell.W then
				makePart(Map, ("WallW_%d_%d"):format(x, y),
					Vector3.new(WALL_THICK, WALL_HEIGHT, CELL_SIZE + WALL_THICK),
					CFrame.new(origin + Vector3.new(-CELL_SIZE/2, WALL_HEIGHT/2, 0)),
					DARK, Enum.Material.Slate)
			end
			-- Bottom row S walls
			if y == GRID_N and cell.S then
				makePart(Map, ("WallS_%d_%d"):format(x, y),
					Vector3.new(CELL_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK),
					CFrame.new(origin + Vector3.new(0, WALL_HEIGHT/2, CELL_SIZE/2)),
					DARK, Enum.Material.Slate)
			end
			-- Rightmost column E walls
			if x == GRID_N and cell.E then
				makePart(Map, ("WallE_%d_%d"):format(x, y),
					Vector3.new(WALL_THICK, WALL_HEIGHT, CELL_SIZE + WALL_THICK),
					CFrame.new(origin + Vector3.new(CELL_SIZE/2, WALL_HEIGHT/2, 0)),
					DARK, Enum.Material.Slate)
			end
		end
	end

	-- Yellow Neon strip atop each wall (brand consistency with lane mode)
	-- Drawn as a single big perimeter outline for cheapness — full strip-per-wall
	-- would be 100+ extra parts.
	makePart(Map, "PerimeterStripN", Vector3.new(mazeSize + 2, 0.4, 0.4),
		CFrame.new(mazeOrigin + Vector3.new(0, WALL_HEIGHT + 0.2, -mazeSize/2)),
		YELLOW, Enum.Material.Neon)
	makePart(Map, "PerimeterStripS", Vector3.new(mazeSize + 2, 0.4, 0.4),
		CFrame.new(mazeOrigin + Vector3.new(0, WALL_HEIGHT + 0.2, mazeSize/2)),
		YELLOW, Enum.Material.Neon)
	makePart(Map, "PerimeterStripE", Vector3.new(0.4, 0.4, mazeSize + 2),
		CFrame.new(mazeOrigin + Vector3.new(mazeSize/2, WALL_HEIGHT + 0.2, 0)),
		YELLOW, Enum.Material.Neon)
	makePart(Map, "PerimeterStripW", Vector3.new(0.4, 0.4, mazeSize + 2),
		CFrame.new(mazeOrigin + Vector3.new(-mazeSize/2, WALL_HEIGHT + 0.2, 0)),
		YELLOW, Enum.Material.Neon)

	-- Center base — bright blurple Neon platform marking where enemies converge.
	-- CanCollide=false so PathfindingService doesn't treat it as an obstacle
	-- (otherwise enemies path AROUND the center instead of TO it).
	local centerBase = makePart(Map, "CenterBase", Vector3.new(CELL_SIZE * 2 - 1, 1, CELL_SIZE * 2 - 1),
		CFrame.new(mazeOrigin + Vector3.new(0, 0.5, 0)),
		BLURPLE, Enum.Material.Neon, 0.2)
	centerBase.CanCollide = false

	-- 4 spawn markers (red) at the entrance cells. CanCollide=false for the
	-- same PathfindingService reason — markers are nav-points, not obstacles.
	local mid = math.floor(GRID_N / 2)
	local spawnPositions = {
		{ name = "SpawnN", pos = cellOrigin(mid, 1)       + Vector3.new(0, 1, -CELL_SIZE/2 + 1) },
		{ name = "SpawnS", pos = cellOrigin(mid, GRID_N)  + Vector3.new(0, 1, CELL_SIZE/2 - 1) },
		{ name = "SpawnE", pos = cellOrigin(GRID_N, mid)  + Vector3.new(CELL_SIZE/2 - 1, 1, 0) },
		{ name = "SpawnW", pos = cellOrigin(1, mid)       + Vector3.new(-CELL_SIZE/2 + 1, 1, 0) },
	}
	for _, sp in ipairs(spawnPositions) do
		local marker = makePart(Map, sp.name,
			Vector3.new(2, 1, 2), CFrame.new(sp.pos),
			DANGER, Enum.Material.Neon, 0.3)
		marker.CanCollide = false
		marker:SetAttribute("MazeSpawn", true)  -- tag for EnemySpawner queries
	end

	-- Maze floor: also non-colliding so PathfindingService treats it as
	-- walkable surface. (Walls remain CanCollide=true — they're the actual
	-- obstacles.)
	local floor = Map:FindFirstChild(PREFIX .. "Floor")
	if floor then floor.CanCollide = true end  -- floor IS collidable; agents walk on it

	-- v2 fix-up: pre-compute PathfindingService waypoints from each spawn
	-- marker to CenterBase. Cached in MazePathCache for EnemySpawner to
	-- read on enemy spawn. ComputeAsync yields per call — 4 sequential
	-- yields, ~1-2s total at maze gen time. Trade: ZERO per-enemy compute
	-- at runtime.
	local MazePathCache = require(script.Parent:WaitForChild("MazePathCache"))
	MazePathCache.Compute()

	print(string.format("[MazeGenerator] Generated %dx%d maze at %s — %d cells, 4 spawn markers, center base.",
		GRID_N, GRID_N, tostring(mazeOrigin), GRID_N * GRID_N))
end

return MazeGenerator
