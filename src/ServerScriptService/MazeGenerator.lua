-- ServerScriptService/MazeGenerator (ModuleScript)
-- v2 fix-up #2 — 4-quadrant separated maze. Each gate (N/E/S/W) connects to
-- its OWN 8x8 quadrant. Solid walls between quadrants prevent path
-- convergence. All 4 paths reach the center via independent routes.
--
-- Studio command bar:
--   require(game.ServerScriptService.MazeGenerator).Apply()
--
-- Path-length floor: up to MAX_GEN_ATTEMPTS regenerations until ALL 4 gates
-- have paths >= MIN_WAYPOINTS_PER_GATE waypoints. Filters out unlucky random
-- rolls where one gate ends up with a trivially-short route.

local RunService = game:GetService("RunService")

local MazeGenerator = {}

local YELLOW  = Color3.fromRGB(250, 204, 21)
local DARK    = Color3.fromRGB(15, 15, 15)
local FLOOR   = Color3.fromRGB(28, 28, 32)
local BLURPLE = Color3.fromRGB(88, 101, 242)
local DANGER  = Color3.fromRGB(180, 40, 40)

local PREFIX = "MazeGen_"

-- Grid sizing: 16x16 total, split into 4 quadrants of 8x8.
-- Total maze footprint: 16 * 12 = 192 studs (was 120 for the 10x10 v1 maze).
local CELL_SIZE     = 12
local GRID_N        = 16
local QUAD_N        = GRID_N / 2  -- 8 — each quadrant is 8x8
local WALL_HEIGHT   = 8
local WALL_THICK    = 1
local CENTER_BASE_SIZE = 12  -- 1x1 cell-sized base (small + tense per user pick)

local MIN_WAYPOINTS_PER_GATE = 25  -- path floor — regenerate if any gate falls below
local MAX_GEN_ATTEMPTS       = 5

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

-- Recursive-backtracker maze on a quadrantSize × quadrantSize grid. Returns
-- 2D array of cells. Each cell has N/E/S/W walls (true = wall present).
-- Coordinates are LOCAL to the quadrant (1..quadrantSize in both dims).
local function generateQuadrantMaze(quadrantSize)
	local grid = {}
	for y = 1, quadrantSize do
		grid[y] = {}
		for x = 1, quadrantSize do
			grid[y][x] = { N = true, E = true, S = true, W = true, visited = false }
		end
	end

	local stack = { { x = math.random(1, quadrantSize), y = math.random(1, quadrantSize) } }
	grid[stack[1].y][stack[1].x].visited = true

	local DX = { N = 0,  E = 1,  S = 0,  W = -1 }
	local DY = { N = -1, E = 0,  S = 1,  W = 0  }
	local OPP = { N = "S", S = "N", E = "W", W = "E" }

	while #stack > 0 do
		local cur = stack[#stack]
		local neighbors = {}
		for _, dir in ipairs({ "N", "E", "S", "W" }) do
			local nx, ny = cur.x + DX[dir], cur.y + DY[dir]
			if nx >= 1 and nx <= quadrantSize and ny >= 1 and ny <= quadrantSize and not grid[ny][nx].visited then
				table.insert(neighbors, { x = nx, y = ny, dir = dir })
			end
		end
		if #neighbors == 0 then
			table.remove(stack)
		else
			local choice = neighbors[math.random(1, #neighbors)]
			grid[cur.y][cur.x][choice.dir] = false
			grid[choice.y][choice.x][OPP[choice.dir]] = false
			grid[choice.y][choice.x].visited = true
			table.insert(stack, choice)
		end
	end

	return grid
end

-- Quadrant layout in the 16x16 grid:
-- NW: rows 1..8, cols 1..8 — N gate enters from row 1, exit cell is (8, 8) toward SE
-- NE: rows 1..8, cols 9..16 — E gate enters from col 16, exit cell is (8, 9) toward SW
-- SW: rows 9..16, cols 1..8 — W gate enters from col 1, exit cell is (9, 8) toward NE
-- SE: rows 9..16, cols 9..16 — S gate enters from row 16, exit cell is (9, 9) toward NW

local QUADRANT_LAYOUTS = {
	{ name = "NW", rowOffset = 0,        colOffset = 0,        gateEdge = "N", gateRow = 1,        gateCol = 4,        exitRow = 8,        exitCol = 8        },
	{ name = "NE", rowOffset = 0,        colOffset = QUAD_N,   gateEdge = "E", gateRow = 4,        gateCol = GRID_N,   exitRow = 8,        exitCol = QUAD_N+1 },
	{ name = "SW", rowOffset = QUAD_N,   colOffset = 0,        gateEdge = "W", gateRow = QUAD_N+4, gateCol = 1,        exitRow = QUAD_N+1, exitCol = 8        },
	{ name = "SE", rowOffset = QUAD_N,   colOffset = QUAD_N,   gateEdge = "S", gateRow = GRID_N,   gateCol = QUAD_N+4, exitRow = QUAD_N+1, exitCol = QUAD_N+1 },
}

-- Build the full 16x16 grid by stitching 4 independent quadrants. Walls
-- between quadrants (row 8/9 boundary, col 8/9 boundary) stay as the cells'
-- own outer walls — they're naturally solid because no carving crosses
-- quadrant boundaries. Only INSIDE each quadrant does the algorithm carve.
local function buildFullGrid()
	local grid = {}
	for y = 1, GRID_N do
		grid[y] = {}
		for x = 1, GRID_N do
			grid[y][x] = { N = true, E = true, S = true, W = true }
		end
	end

	for _, q in ipairs(QUADRANT_LAYOUTS) do
		local quadGrid = generateQuadrantMaze(QUAD_N)
		for qy = 1, QUAD_N do
			for qx = 1, QUAD_N do
				local globalY = q.rowOffset + qy
				local globalX = q.colOffset + qx
				local cell = quadGrid[qy][qx]
				-- Copy cell walls but PRESERVE inter-quadrant boundaries
				-- (cells on the inner edges of quadrants must keep walls
				-- toward neighboring quadrants).
				grid[globalY][globalX].N = cell.N
				grid[globalY][globalX].E = cell.E
				grid[globalY][globalX].S = cell.S
				grid[globalY][globalX].W = cell.W
			end
		end
	end

	-- Carve gates: each quadrant has ONE outer-edge entry point.
	-- N gate: row 1, col 4 — open N wall (top of grid)
	-- E gate: row 4, col 16 — open E wall (right of grid)
	-- W gate: row 12, col 1 — open W wall (left of grid)
	-- S gate: row 16, col 12 — open S wall (bottom of grid)
	for _, q in ipairs(QUADRANT_LAYOUTS) do
		grid[q.gateRow][q.gateCol][q.gateEdge] = false
	end

	-- Carve center exits: each quadrant's corner cell (closest to grid center)
	-- opens its INNER walls so enemies can converge on the center base. The
	-- 4 exit cells form a 2x2 open clearing at (8,8)/(8,9)/(9,8)/(9,9) where
	-- enemies arrive from their respective quadrants. The center base part
	-- sits in this clearing.
	-- NW (8,8): open E + S
	grid[QUAD_N][QUAD_N].E = false
	grid[QUAD_N][QUAD_N].S = false
	-- NE (8, QUAD_N+1): open W + S
	grid[QUAD_N][QUAD_N+1].W = false
	grid[QUAD_N][QUAD_N+1].S = false
	-- SW (QUAD_N+1, 8): open E + N
	grid[QUAD_N+1][QUAD_N].E = false
	grid[QUAD_N+1][QUAD_N].N = false
	-- SE (QUAD_N+1, QUAD_N+1): open W + N
	grid[QUAD_N+1][QUAD_N+1].W = false
	grid[QUAD_N+1][QUAD_N+1].N = false

	return grid
end

-- Build the maze geometry parts in workspace.Map from a grid description.
-- Idempotent — caller has already cleaned up MazeGen_-prefixed parts.
local function buildGeometry(Map, grid, mazeOrigin)
	local mazeSize = GRID_N * CELL_SIZE
	local floorY   = mazeOrigin.Y - 0.2

	-- Floor
	makePart(Map, "Floor", Vector3.new(mazeSize + 4, 0.4, mazeSize + 4),
		CFrame.new(mazeOrigin + Vector3.new(0, -0.2, 0)),
		FLOOR, Enum.Material.SmoothPlastic)

	local function cellOrigin(cx, cy)
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
			if y == GRID_N and cell.S then
				makePart(Map, ("WallS_%d_%d"):format(x, y),
					Vector3.new(CELL_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK),
					CFrame.new(origin + Vector3.new(0, WALL_HEIGHT/2, CELL_SIZE/2)),
					DARK, Enum.Material.Slate)
			end
			if x == GRID_N and cell.E then
				makePart(Map, ("WallE_%d_%d"):format(x, y),
					Vector3.new(WALL_THICK, WALL_HEIGHT, CELL_SIZE + WALL_THICK),
					CFrame.new(origin + Vector3.new(CELL_SIZE/2, WALL_HEIGHT/2, 0)),
					DARK, Enum.Material.Slate)
			end
		end
	end

	-- Yellow Neon perimeter strips
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

	-- 1x1 center base — small + tense (per user pick). Sits at geometric
	-- center (corner of all 4 quadrants). CanCollide=false so PathfindingService
	-- doesn't treat the goal as an obstacle.
	local centerBase = makePart(Map, "CenterBase",
		Vector3.new(CENTER_BASE_SIZE, 1, CENTER_BASE_SIZE),
		CFrame.new(mazeOrigin + Vector3.new(0, 0.5, 0)),
		BLURPLE, Enum.Material.Neon, 0.2)
	centerBase.CanCollide = false

	-- Spawn markers — one per gate, on the OUTER edge of each quadrant.
	local spawnPositions = {}
	for _, q in ipairs(QUADRANT_LAYOUTS) do
		local cellPos = cellOrigin(q.gateCol, q.gateRow)
		local edgeOffset = Vector3.new(0, 1, 0)
		if q.gateEdge == "N" then edgeOffset = edgeOffset + Vector3.new(0, 0, -CELL_SIZE/2 + 1)
		elseif q.gateEdge == "S" then edgeOffset = edgeOffset + Vector3.new(0, 0, CELL_SIZE/2 - 1)
		elseif q.gateEdge == "E" then edgeOffset = edgeOffset + Vector3.new(CELL_SIZE/2 - 1, 0, 0)
		elseif q.gateEdge == "W" then edgeOffset = edgeOffset + Vector3.new(-CELL_SIZE/2 + 1, 0, 0)
		end
		table.insert(spawnPositions, { name = "Spawn" .. q.gateEdge, pos = cellPos + edgeOffset })
	end

	for _, sp in ipairs(spawnPositions) do
		local marker = makePart(Map, sp.name,
			Vector3.new(2, 1, 2), CFrame.new(sp.pos),
			DANGER, Enum.Material.Neon, 0.3)
		marker.CanCollide = false
		marker:SetAttribute("MazeSpawn", true)
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

	local laneVec  = serverZone.Position - enemyStart.Position
	local laneDir  = (laneVec.Magnitude > 0) and laneVec.Unit or Vector3.new(1, 0, 0)
	local lanePerp = Vector3.new(-laneDir.Z, 0, laneDir.X)
	local mazeOrigin = enemyStart.Position + lanePerp * 240  -- bumped from 200 to clear the bigger maze

	local MazePathCache = require(script.Parent:WaitForChild("MazePathCache"))

	-- Try up to MAX_GEN_ATTEMPTS to get a maze where every gate's path is
	-- at least MIN_WAYPOINTS_PER_GATE long. Recursive-backtracker is random;
	-- some rolls produce one quadrant with a trivially short route.
	local lastResult
	for attempt = 1, MAX_GEN_ATTEMPTS do
		-- Wipe any prior MazeGen_ parts before each attempt
		for _, child in ipairs(Map:GetChildren()) do
			if child.Name:sub(1, #PREFIX) == PREFIX then
				child:Destroy()
			end
		end

		local grid = buildFullGrid()
		buildGeometry(Map, grid, mazeOrigin)

		-- Compute paths and check the floor
		MazePathCache.Compute()
		local minLen, gateCounts = math.huge, {}
		for _, q in ipairs(QUADRANT_LAYOUTS) do
			local markerName = PREFIX .. "Spawn" .. q.gateEdge
			local wps = MazePathCache.GetWaypoints(markerName)
			local count = wps and #wps or 0
			gateCounts[q.gateEdge] = count
			if count < minLen then minLen = count end
		end

		print(string.format("[MazeGenerator] Attempt %d/%d — gate paths N=%d E=%d S=%d W=%d (min %d, floor %d)",
			attempt, MAX_GEN_ATTEMPTS, gateCounts.N or 0, gateCounts.E or 0, gateCounts.S or 0, gateCounts.W or 0,
			minLen, MIN_WAYPOINTS_PER_GATE))

		lastResult = { minLen = minLen, gateCounts = gateCounts }
		if minLen >= MIN_WAYPOINTS_PER_GATE then
			print(string.format("[MazeGenerator] Generated 16x16 4-quadrant maze (attempt %d) at %s — %d cells, 4 gates, 1x1 center.",
				attempt, tostring(mazeOrigin), GRID_N * GRID_N))
			return
		end
	end

	warn(string.format("[MazeGenerator] Could not satisfy %d-waypoint floor after %d attempts. Shipping last result (min %d).",
		MIN_WAYPOINTS_PER_GATE, MAX_GEN_ATTEMPTS, lastResult and lastResult.minLen or 0))
end

return MazeGenerator
